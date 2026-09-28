#!/usr/bin/env python3
"""Audit existing Flyme stock extracts without treating them as complete vendors.

This reads firmware, never builds or flashes. Only metadata may be committed.
The ELF audit is a dependency inventory; neither linkability nor runtime ABI is
proved by a matching library name in the stock file list.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import struct
import subprocess
import zipfile


DEVICES = {"m3s": ("Y15", "M3s"), "u10": ("U10", "U10"), "u20": ("U20", "U20")}
BOARD_PAIRS = {
    "boot": ("logo", "BOARD_BOOTIMAGE_PARTITION_SIZE"),
    "recovery": ("para", "BOARD_RECOVERYIMAGE_PARTITION_SIZE"),
    "system": ("cache", "BOARD_SYSTEMIMAGE_PARTITION_SIZE"),
    "cache": ("userdata", "BOARD_CACHEIMAGE_PARTITION_SIZE"),
}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def boot_header(raw):
    if len(raw) < 1632 or raw[:8] != b"ANDROID!":
        raise ValueError("not an Android legacy boot image")
    values = struct.unpack_from("<10I", raw, 8)
    keys = ("kernel_size", "kernel_addr", "ramdisk_size", "ramdisk_addr",
            "second_size", "second_addr", "tags_addr", "page_size", "dt_size", "unused")
    header = dict(zip(keys, values))
    page = header["page_size"]
    if page not in (2048, 4096, 8192, 16384) or header["dt_size"] != 0:
        raise ValueError("unsupported page size or non-legacy header")
    end = page
    for name in ("kernel_size", "ramdisk_size", "second_size"):
        end += (header[name] + page - 1) // page * page
    if end > len(raw):
        raise ValueError("truncated boot payload")
    header["name"] = raw[48:64].split(b"\0")[0].decode("ascii")
    header["cmdline"] = (raw[64:576].split(b"\0")[0] + raw[608:1632].split(b"\0")[0]).decode("ascii")
    header["sha256"] = digest(raw)
    header["kernel_payload_sha256"] = digest(raw[page:page + header["kernel_size"]])
    return header


def partition_geometry(text):
    rows = []
    for line in text.splitlines():
        fields = line.split()
        if len(fields) != 2 or not re.fullmatch(r"[a-z0-9_]+", fields[0]):
            raise ValueError("unsupported scatter format")
        rows.append((fields[0], int(fields[1], 0)))
    if len(dict(rows)) != len(rows):
        raise ValueError("duplicate scatter partition")
    result = {}
    for name, (following, variable) in BOARD_PAIRS.items():
        matches = [i for i, row in enumerate(rows) if row[0] == name]
        if len(matches) != 1:
            raise ValueError(f"missing scatter partition: {name}")
        index = matches[0]
        if index + 1 >= len(rows) or rows[index + 1][0] != following:
            raise ValueError(f"unproven adjacent boundary: {name}/{following}")
        start, end = rows[index][1], rows[index + 1][1]
        if not 0 < start < end < 0xffff0000:
            raise ValueError(f"invalid partition extent: {name}")
        result[name] = {"start": start, "end": end, "size": end - start, "variable": variable}
    # flashinfo/sgpt are sentinel values. They do not define userdata capacity.
    return result


def safe_relative(path):
    normalized = path[2:] if path.startswith("./") else path
    if not re.fullmatch(r"[A-Za-z0-9_.+/-]+", normalized):
        raise ValueError(f"unsafe stock path: {path!r}")
    if normalized.startswith("/") or ".." in Path(normalized).parts:
        raise ValueError(f"unsafe stock path: {path!r}")
    return normalized


def elf_needs(path):
    with path.open("rb") as stream:
        header = stream.read(5)
    if header[:4] != b"\x7fELF":
        return None
    if header[4] not in (1, 2):
        raise ValueError(f"invalid ELF class: {path}")
    result = subprocess.run(["readelf", "--dynamic", "--wide", str(path)],
                            check=True, text=True, capture_output=True)
    needs = sorted(set(re.findall(r"\(NEEDED\).*?\[([^\]]+)\]", result.stdout)))
    return {"elf_class": 32 if header[4] == 1 else 64, "needed": needs}


def audit(stock_root, device):
    if device not in DEVICES:
        raise ValueError("device has no audited Flyme baseline")
    unpacked = stock_root / device / "unpacked"
    metadata = dict(line.split("=", 1) for line in (unpacked / "metadata").read_text().splitlines() if "=" in line)
    pre_device, product = DEVICES[device]
    if metadata.get("pre-device") != pre_device or f"/{product}:" not in metadata.get("post-build", ""):
        raise ValueError("stock identity does not match the requested board")
    with zipfile.ZipFile(stock_root / device / f"flyme-6.3.0.0G-intl-{device}.zip") as archive:
        raw_scatter = archive.read("scatter.txt")
        # Match the boot in the actual archive, not merely its adjacent label.
        archived_boot = archive.read("boot.img")
    raw_boot = (unpacked / "boot.img").read_bytes()
    if raw_boot != archived_boot:
        raise ValueError("unpacked boot does not match firmware archive")
    header = boot_header(raw_boot)
    geometry = partition_geometry(raw_scatter.decode("ascii"))
    if len(raw_boot) > geometry["boot"]["size"]:
        raise ValueError("boot artifact exceeds declared stock partition")
    stock_files = {safe_relative(p) for p in (unpacked / "system-files.txt").read_text().splitlines() if p}
    blob_root = unpacked / "vendor-blobs"
    blobs = []
    links = []
    for path in sorted(blob_root.rglob("*")):
        if path.is_symlink():
            # Stock HAL aliases are recorded, never followed into the host.
            target = safe_relative(str(path.readlink()))
            links.append({"path": safe_relative(path.relative_to(blob_root).as_posix()), "target": target})
            continue
        if not path.is_file():
            continue
        relative = safe_relative(path.relative_to(blob_root).as_posix())
        if relative not in stock_files:
            raise ValueError(f"curated file absent from stock listing: {relative}")
        row = {"path": relative, "size": path.stat().st_size, "sha256": digest(path.read_bytes())}
        native = elf_needs(path)
        if native:
            row.update(native)
        blobs.append(row)
    available = {row["path"] for row in blobs}
    missing = {}
    for row in blobs:
        for needed in row.get("needed", []):
            library_dir = "lib64" if row["elf_class"] == 64 else "lib"
            candidates = [f"{library_dir}/{needed}", f"vendor/{library_dir}/{needed}"]
            if available.intersection(candidates):
                continue
            key = f"{library_dir}/{needed}"
            entry = missing.setdefault(key, {"stock_candidates": sorted(stock_files.intersection(candidates)), "required_by": []})
            entry["required_by"].append(row["path"])
    return {
        "schema_version": "remeizu.los16.stock-inputs.v1", "device": device,
        "firmware_fingerprint": metadata["post-build"], "boot": header,
        "scatter_sha256": digest(raw_scatter), "partition_bounds": geometry,
        "userdata_capacity": None, "stock_gpt_readback_verified": False,
        "curated_blob_count": len(blobs), "curated_elf_count": sum("elf_class" in row for row in blobs),
        "blobs": blobs, "symlinks": links, "dependencies_absent_from_curated_extract": missing,
        "vendor_complete": False, "build_ready": False, "runtime_verified": False,
        "blockers": ["full stock extraction and vendor ABI/module audit", "board-specific kernel port", "stock fstab/init and board feature mapping"],
    }


def board_make(report):
    header = report["boot"]
    # Absolute addresses with base zero avoid choosing an invented base/offset decomposition.
    lines = ["# Generated from the pinned Flyme boot header and adjacent scatter offsets.",
             "# Not a live GPT readback; userdata capacity deliberately remains unset.",
             f"# boot SHA256: {header['sha256']}",
             f"# scatter SHA256: {report['scatter_sha256']}",
             "BOARD_KERNEL_BASE := 0x00000000", f"BOARD_KERNEL_PAGESIZE := {header['page_size']}",
             f"BOARD_RAMDISK_OFFSET := 0x{header['ramdisk_addr']:08x}",
             "BOARD_MKBOOTIMG_ARGS := " + " ".join(f"--{name}_offset 0x{header[key]:08x}" for name, key in (("kernel", "kernel_addr"), ("ramdisk", "ramdisk_addr"), ("second", "second_addr"), ("tags", "tags_addr"))),
             f"# Stock cmdline (reference; Android release policy stays in common): {header['cmdline']}"]
    for name in sorted(report["partition_bounds"]):
        bounds = report["partition_bounds"][name]
        lines.append(f"{bounds['variable']} := {bounds['size']}")
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("device", choices=DEVICES)
    parser.add_argument("--stock-root", type=Path, required=True)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--board-make", type=Path)
    args = parser.parse_args()
    report = audit(args.stock_root, args.device)
    if args.report:
        args.report.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    if args.board_make:
        args.board_make.write_text(board_make(report))
    summary = {k: report[k] for k in ("device", "curated_blob_count", "curated_elf_count", "vendor_complete", "build_ready")}
    summary["missing_curated_libraries"] = len(report["dependencies_absent_from_curated_extract"])
    print(json.dumps(summary))


if __name__ == "__main__":
    main()
