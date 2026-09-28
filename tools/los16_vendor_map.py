#!/usr/bin/env python3
"""Map stock HAL dependencies to local LOS16 module candidates or own-stock files.

Candidate module definitions are not proof that a given architecture is built
or exports the required ABI. This tool deliberately never copies blobs or
labels an entire stock /system library set as a vendor tree.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

from los16_stock_inputs import elf_needs

PLATFORM_ROOTS = ("bionic", "frameworks", "system", "external", "libcore", "libnativehelper", "hardware", "packages")


def platform_modules(platform):
    roots = [str(platform / root) for root in PLATFORM_ROOTS if (platform / root).is_dir()]
    pattern = r'(^[ \t]*LOCAL_MODULE[ \t]*:?=[ \t]*[A-Za-z0-9_.+-]+|^[ \t]*name[ \t]*:[ \t]*"[A-Za-z0-9_.+-]+")'
    command = ["rg", "--no-heading", "--with-filename", "--line-number", "--glob", "Android.mk", "--glob", "Android.bp", pattern, *roots]
    result = subprocess.run(command, capture_output=True, text=True)
    if result.returncode not in (0, 1):
        raise ValueError(result.stderr.strip())
    modules = {}
    for line in result.stdout.splitlines():
        filename, number, content = line.split(":", 2)
        match = re.search(r'LOCAL_MODULE\s*:?=\s*([A-Za-z0-9_.+-]+)(?:\s|$)|name\s*:\s*"([A-Za-z0-9_.+-]+)"', content)
        if match:
            name = match.group(1) or match.group(2)
            modules.setdefault(name, []).append({"path": Path(filename).relative_to(platform).as_posix(), "line": int(number)})
    return modules


def map_vendor(report, private_root, modules, platform):
    inventory = json.loads((private_root / "inventory.json").read_text())
    if inventory["boot_sha256"] != report["boot"]["sha256"]:
        raise ValueError("full extract does not belong to the pinned board")
    full_files = {row["path"]: row for row in inventory["files"] if "sha256" in row}
    root = private_root / "system"
    seeds = []
    for row in report["blobs"]:
        if "elf_class" in row:
            candidate = full_files.get(row["path"])
            if not candidate or candidate["sha256"] != row["sha256"]:
                raise ValueError(f"curated/full stock mismatch: {row['path']}")
            seeds.append(row["path"])
    todo, seen, nodes, definitions = list(seeds), set(), [], {}
    while todo:
        relative = todo.pop(0)
        if relative in seen:
            continue
        seen.add(relative)
        actual_sha256 = hashlib.sha256((root / relative).read_bytes()).hexdigest()
        if actual_sha256 != full_files[relative]["sha256"]:
            raise ValueError(f"stock native file changed since extraction: {relative}")
        details = elf_needs(root / relative)
        if not details:
            raise ValueError(f"native dependency is not ELF: {relative}")
        library_dir = "lib64" if details["elf_class"] == 64 else "lib"
        edges = []
        for needed in details["needed"]:
            module = needed[:-3] if needed.endswith(".so") else needed
            providers = modules.get(module, [])
            candidates = [path for path in (f"{library_dir}/{needed}", f"vendor/{library_dir}/{needed}") if path in full_files]
            if providers:
                kind = "platform-source-candidate"
                for entry in providers:
                    filename = entry["path"]
                    if filename not in definitions:
                        definitions[filename] = hashlib.sha256((platform / filename).read_bytes()).hexdigest()
            elif candidates:
                kind = "own-stock-only-candidate"
                # Both search locations are reviewed if a basename is ambiguous.
                todo.extend(candidates)
            else:
                kind = "unresolved"
            edges.append({"needed": needed, "classification": kind,
                          "platform_modules": providers, "stock_candidates": candidates})
        nodes.append({"path": relative, "sha256": full_files[relative]["sha256"],
                      "elf_class": details["elf_class"], "dependencies": edges})
    counts = {}
    unique = {}
    for node in nodes:
        for edge in node["dependencies"]:
            key = f"{node['elf_class']}:{edge['needed']}"
            unique[key] = edge["classification"]
    for classification in unique.values():
        counts[classification] = counts.get(classification, 0) + 1
    return {"schema_version": "remeizu.los16.vendor-map.v1", "device": report["device"],
            "boot_sha256": report["boot"]["sha256"], "seed_count": len(seeds),
            "stock_nodes": nodes, "unique_dependencies_by_classification": counts,
            "platform_definition_sha256": definitions, "vendor_ready": False,
            "limitations": ["module definitions are candidates, not built ABI providers",
                            "absence of a literal module declaration does not prove proprietary ownership",
                            "dynamic dlopen targets and init services need a separate audit",
                            "same library basename does not establish Android ABI compatibility"]}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--stock-report", type=Path, required=True)
    parser.add_argument("--private-extract", type=Path, required=True)
    parser.add_argument("--platform", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = json.loads(args.stock_report.read_text())
    result = map_vendor(report, args.private_extract, platform_modules(args.platform), args.platform)
    args.output.write_text(json.dumps(result, indent=2, sort_keys=True) + "\n")
    print(json.dumps({"device": result["device"], "stock_nodes": len(result["stock_nodes"]),
                      "dependencies": result["unique_dependencies_by_classification"], "vendor_ready": False}))


if __name__ == "__main__":
    main()
