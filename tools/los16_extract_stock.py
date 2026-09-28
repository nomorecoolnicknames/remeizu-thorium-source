#!/usr/bin/env python3
"""Extract a pinned full-OTA system into a private, previously absent directory.

Adapted from the local m5s sdat2img flow; rejects incremental/unknown commands
and checks all stream lengths. Output contains proprietary stock bytes and must
not be committed, published, or substituted for a reviewed vendor product.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

from los16_stock_inputs import safe_relative

BLOCK = 4096


def transfer_commands(text):
    lines = [line.strip() for line in text.splitlines()]
    version = int(lines[0])
    if version not in (1, 2, 3, 4):
        raise ValueError("unsupported transfer list version")
    commands = []
    for line in lines[2 if version == 1 else 4:]:
        if not line:
            continue
        kind, ranges = line.split()
        if kind not in ("new", "zero", "erase"):
            raise ValueError(f"not a supported full OTA: {kind}")
        numbers = [int(value) for value in ranges.split(",")]
        if numbers[0] != len(numbers) - 1 or numbers[0] % 2:
            raise ValueError("invalid transfer ranges")
        for begin, end in zip(numbers[1::2], numbers[2::2]):
            if not 0 <= begin < end:
                raise ValueError("invalid transfer extent")
            commands.append((kind, begin, end))
    if not commands:
        raise ValueError("empty transfer list")
    # Android 5 full OTAs may erase the whole partition before writing new
    # extents (M3s stock does exactly this). A fresh zeroed image implements
    # that prefix. Never ignore an erase/zero that could overwrite prior data.
    writes = []
    for kind, begin, end in commands:
        if kind == "erase":
            if any(begin < old_end and old_begin < end for old_begin, old_end in writes):
                raise ValueError("erase overlaps previously written transfer ranges")
        else:
            writes.append((begin, end))
    ordered = sorted(writes)
    if any(previous[1] > following[0] for previous, following in zip(ordered, ordered[1:])):
        raise ValueError("overlapping transfer ranges")
    return commands


def extract(archive_path, output, expected_boot, expected_files):
    if not re.fullmatch(r"/[A-Za-z0-9_./-]+", str(output)) or output.exists():
        raise ValueError("output must be a new absolute directory with a simple path")
    with zipfile.ZipFile(archive_path) as archive:
        actual_boot = hashlib.sha256(archive.read("boot.img")).hexdigest()
        if actual_boot != expected_boot:
            raise ValueError("archive boot differs from pinned stock report")
        commands = transfer_commands(archive.read("system.transfer.list").decode("ascii"))
        required_data = sum((end - begin) * BLOCK for kind, begin, end in commands if kind == "new")
        if archive.getinfo("system.new.dat").file_size != required_data:
            raise ValueError("system.new.dat size does not match new ranges")
        image_size = max(end for _, _, end in commands) * BLOCK
        output.parent.mkdir(parents=True, exist_ok=True)
        if shutil.disk_usage(output.parent).free < image_size + required_data + (256 << 20):
            raise ValueError("insufficient space for image and extracted system")
        output.mkdir(mode=0o700)
        image = output / "system.img"
        with archive.open("system.new.dat") as source, image.open("xb") as destination:
            destination.truncate(image_size)
            for kind, begin, end in commands:
                if kind != "new":
                    continue  # Fresh sparse image: zero and erase ranges are already zero.
                destination.seek(begin * BLOCK)
                remaining = (end - begin) * BLOCK
                while remaining:
                    chunk = source.read(min(remaining, 1 << 20))
                    if not chunk:
                        raise ValueError("truncated system data")
                    destination.write(chunk)
                    remaining -= len(chunk)
            if source.read(1):
                raise ValueError("unconsumed system data")
    system = output / "system"
    system.mkdir()
    with (output / "debugfs.log").open("w") as log:
        subprocess.run(["/usr/sbin/debugfs", "-R", f"rdump / {system}", str(image)],
                       check=True, stdout=log, stderr=subprocess.STDOUT)
    if not (system / "build.prop").is_file():
        raise ValueError("debugfs did not produce a complete root with build.prop")
    files = []
    for path in sorted(system.rglob("*")):
        relative = path.relative_to(system).as_posix()
        if path.is_symlink():
            files.append({"path": relative, "symlink": str(path.readlink())})
        elif path.is_file():
            hasher = hashlib.sha256()
            with path.open("rb") as source:
                for chunk in iter(lambda: source.read(1 << 20), b""):
                    hasher.update(chunk)
            files.append({"path": relative, "size": path.stat().st_size, "sha256": hasher.hexdigest()})
    expected = {safe_relative(line) for line in expected_files.read_text().splitlines() if line}
    actual = {row["path"] for row in files if "sha256" in row}
    if actual != expected:
        raise ValueError(f"incomplete system extraction: missing={len(expected - actual)} extra={len(actual - expected)}")
    result = {"schema_version": "remeizu.private-system-extract.v1", "boot_sha256": actual_boot,
              "expected_file_listing_sha256": hashlib.sha256(expected_files.read_bytes()).hexdigest(),
              "regular_files_verified": len(actual),
              "image_size": image_size, "files": files, "vendor_ready": False}
    (output / "inventory.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--archive", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--stock-report", type=Path, required=True)
    parser.add_argument("--expected-files", type=Path, required=True,
                        help="independent full stock system-files.txt inventory")
    args = parser.parse_args()
    report = json.loads(args.stock_report.read_text())
    result = extract(args.archive, args.output, report["boot"]["sha256"], args.expected_files)
    print(json.dumps({"files": len(result["files"]), "image_size": result["image_size"], "vendor_ready": False}))


if __name__ == "__main__":
    main()
