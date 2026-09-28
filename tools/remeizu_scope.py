#!/usr/bin/env python3
"""Read-only ReMeizu planning coverage and a deliberately small public view.

Does not execute JavaScript, Make, builds, source preflight, device discovery or
flash commands. Planning scopes never establish a working device or OS release.
"""
import argparse
import json
from pathlib import Path
import re

REPO = Path(__file__).resolve().parents[1]
EXPECTED = {"thorium": 10, "site": 15, "runtime": 8, "android_targets": 21}
SCOPES = {"active", "planned", "candidate", "external"}
SDK = {9: 28, 11: 30, 13: 33}
CARD = re.compile(r"^\s*name:\s*'[^'\n]+',\s*codename:\s*'([A-Za-z0-9_]+)'\s*,", re.M)


def read_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def normalized(value):
    return value.strip().casefold()


def rooted(roots, root, relative):
    if root not in roots or not isinstance(relative, str) or not relative:
        raise ValueError("invalid root/path reference")
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError("reference path must be relative without parent traversal")
    return roots[root] / path


def check(registry, overrides=None, repo_root=REPO):
    errors = []
    if registry.get("schema_version") != "remeizu.planning.v1":
        raise ValueError("unsupported registry schema")
    roots = {}
    for name, value in registry["roots"].items():
        path = Path(value)
        roots[name] = (path if path.is_absolute() else repo_root / path).resolve()
    for name, value in (overrides or {}).items():
        if name not in roots:
            raise ValueError("unknown root override: " + name)
        roots[name] = Path(value).resolve()
    for name in ("thorium", "fleet", "site", "build_station"):
        if name not in roots or not roots[name].is_dir():
            raise ValueError("missing root directory: " + name)

    def reference(ref, owner):
        try:
            path = rooted(roots, ref["root"], ref["path"])
            if not path.exists():
                errors.append(owner + ": missing reference " + str(path))
        except (KeyError, TypeError, ValueError) as exc:
            errors.append(owner + ": invalid reference: " + str(exc))

    families = registry["families"]
    for name, family in families.items():
        goals = family["android_goals"]
        if (not isinstance(goals, list) or any(type(v) is not int or v not in SDK for v in goals)
                or len(goals) != len(set(goals)) or set(goals) != set(SDK)):
            errors.append(name + ": Android goals must be 9, 11, 13")
        for key in ("android_plan", "mainline_plan"):
            reference(family.get(key), name + "." + key)
        if "shared_android" in family:
            reference(family["shared_android"], name + ".shared_android")

    boards = registry["boards"]
    aliases, ids = {}, set()
    for board in boards:
        ident = board["id"]
        if not isinstance(ident, str) or not re.fullmatch(r"[a-z0-9_]+", ident):
            raise ValueError("invalid canonical board ID")
        if ident in ids:
            errors.append("duplicate board ID: " + ident)
        ids.add(ident)
        if board["scope"] not in SCOPES:
            errors.append(ident + ": invalid planning scope")
        if board["family"] not in families:
            errors.append(ident + ": unknown family")
        for key in ("name", "soc", "next_gate"):
            if not isinstance(board[key], str) or not board[key].strip():
                errors.append(ident + ": missing " + key)
        if not isinstance(board["aliases"], list):
            raise ValueError(ident + ": aliases must be a list")
        for alias in [ident, *board["aliases"]]:
            if not isinstance(alias, str) or not alias.strip():
                raise ValueError(ident + ": invalid alias")
            key = normalized(alias)
            if key in aliases and aliases[key] != ident:
                errors.append("ambiguous alias " + alias + ": " + aliases[key] + " / " + ident)
            aliases[key] = ident
        for ref in board["evidence_refs"]:
            reference(ref, ident + ".evidence_refs")
        if not isinstance(board["android_targets"], list):
            raise ValueError(ident + ": android_targets must be a list")

    sources = registry["source_paths"]
    snapshot = read_json(rooted(roots, "thorium", sources["scope_snapshot"]))
    required_external = snapshot["required_external_boards"]
    if (not isinstance(required_external, list) or not required_external
            or any(not isinstance(value, str) or not value for value in required_external)
            or len(required_external) != len(set(required_external))):
        raise ValueError("scope snapshot requires unique external board IDs")
    boards_by_id = {board["id"]: board for board in boards}
    for ident in required_external:
        if ident not in boards_by_id:
            errors.append("external_boards: uncovered " + ident)
        elif boards_by_id[ident]["scope"] != "external":
            errors.append(ident + ": required external board must retain external scope")
    inventory = read_json(rooted(roots, "thorium", sources["thorium_inventory"]))["devices"]
    site_text = rooted(roots, "site", sources["site_catalog"]).read_text(encoding="utf-8")
    site = CARD.findall(site_text)
    runtime = read_json(rooted(roots, "fleet", sources["runtime_profiles"]))["devices"]
    targets = {p.relative_to(roots["fleet"]).as_posix(): read_json(p)
               for p in sorted((roots["fleet"] / "targets/android").glob("*.json"))}
    actual = {"thorium": list(inventory), "site": site, "runtime": list(runtime),
              "android_targets": list(targets)}
    for source, entries in actual.items():
        if len(entries) != EXPECTED[source]:
            errors.append(f"{source}: expected {EXPECTED[source]}, found {len(entries)}")
        if len(entries) != len(set(entries)):
            errors.append(source + ": duplicate source entries")

    def resolve(value):
        return aliases.get(normalized(value))

    def mapped_coverage(source, field):
        owners = {}
        for board in boards:
            if field not in board:
                continue
            value = board[field]
            if not isinstance(value, str):
                errors.append(board["id"] + ": invalid " + field)
                continue
            if value not in actual[source]:
                errors.append(board["id"] + ": unknown " + field + " " + value)
            if value in owners:
                errors.append(source + ": duplicate mapping for " + value)
            owners[value] = board["id"]
            if resolve(value) != board["id"]:
                errors.append(board["id"] + ": cross-board " + field + " " + value)
        for value in actual[source]:
            if value not in owners:
                errors.append(source + ": uncovered " + value)

    mapped_coverage("thorium", "thorium_key")
    mapped_coverage("site", "site_card")
    runtime_owners = set()
    for key in runtime:
        owner = resolve(key)
        if owner is None:
            errors.append("runtime: unresolved " + key)
        elif owner in runtime_owners:
            errors.append("runtime: duplicate canonical board " + owner)
        runtime_owners.add(owner)

    target_owners = {}
    for board in boards:
        versions = set()
        for value in board["android_targets"]:
            if not isinstance(value, str) or value not in targets:
                errors.append(board["id"] + ": unknown Android target " + str(value))
                continue
            if value in target_owners:
                errors.append("android_targets: duplicate ownership " + value)
            target_owners[value] = board["id"]
            target = targets[value]
            device, version = target.get("device"), target.get("android_version")
            if not isinstance(device, str) or resolve(device) != board["id"]:
                errors.append(board["id"] + ": cross-board Android target " + value)
            if (type(version) is not int or version not in SDK
                    or target.get("sdk") != SDK.get(version)
                    or target.get("target_id") != f"{device}-a{version}"
                    or Path(value).name != f"{device}-a{version}.json"):
                errors.append(value + ": inconsistent Android target identity")
            if version in versions:
                errors.append(board["id"] + ": duplicate Android version")
            versions.add(version)
        # Empty lists deliberately support planned/candidate/external boards.
        if versions and versions != set(SDK):
            errors.append(board["id"] + ": current Android target set must cover 9/11/13")
    for value in targets:
        if value not in target_owners:
            errors.append("android_targets: uncovered " + value)

    return {"schema_version": "remeizu.planning-coverage.v1",
            "planning_status": "pass" if not errors else "blocked",
            "runtime_verified": False, "build_verified": False,
            "coverage": {**{key: {"expected": EXPECTED[key], "found": len(values)}
                            for key, values in actual.items()},
                         "external_boards": {"expected": len(required_external),
                                             "found": len(set(required_external) & ids)}},
            "board_count": len(boards), "family_count": len(families),
            "errors": errors}


def has_absolute_path(value):
    """Reject path tokens, preserving HTTPS links and words such as panel/touch."""
    if isinstance(value, dict):
        return any(has_absolute_path(item) for item in value.values())
    if isinstance(value, list):
        return any(has_absolute_path(item) for item in value)
    if not isinstance(value, str):
        return False
    prose = re.sub(r"https?://[^\s<>\"']+", "", value, flags=re.I)
    # A standalone slash used as prose punctuation is allowed; a token beginning
    # with /foo or //host, a drive-root path, or a UNC path is private filesystem
    # syntax regardless of its directory name.
    return bool(re.search(r"(?<![\w/])/(?:[^\s/]|/[^\s])"
                          r"|(?<!\w)[A-Za-z]:[\\/]"
                          r"|(?<![\w\\])\\\\[^\s\\]", prose))


def public_projection(registry):
    boards = []
    for board in registry["boards"]:
        item = {key: board[key] for key in ("id", "name", "aliases", "family", "soc", "next_gate")}
        item["android_goals"] = registry["families"][board["family"]]["android_goals"]
        item["planning_status"] = board["scope"]
        # Allowlisted prose must not accidentally carry host paths either.
        if has_absolute_path(item):
            raise ValueError("public fields contain a local path for " + board["id"])
        boards.append(item)
    return {"schema_version": "remeizu.public-planning.v1", "runtime_verified": False,
            "boards": boards}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--registry", type=Path, default=REPO / "planning/fleet.json")
    parser.add_argument("--root", action="append", default=[], metavar="NAME=/path")
    parser.add_argument("--public", action="store_true", help="print allowlisted public planning JSON")
    args = parser.parse_args()
    try:
        overrides = {}
        for value in args.root:
            name, separator, path = value.partition("=")
            if not separator or not name or not path or name in overrides:
                raise ValueError("invalid or duplicate --root")
            overrides[name] = path
        registry = read_json(args.registry)
        report = check(registry, overrides)
        if args.public and report["errors"]:
            parser.exit(2, "BLOCKED: planning coverage failed; run without --public for details\n")
        output = public_projection(registry) if args.public else report
    except (OSError, ValueError, KeyError, TypeError) as exc:
        parser.exit(2, "BLOCKED: " + str(exc) + "\n")
    print(json.dumps(output, ensure_ascii=False, indent=2))
    return 2 if report["errors"] else 0


if __name__ == "__main__":
    raise SystemExit(main())
