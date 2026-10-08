#!/usr/bin/env python3
# SPDX-License-Identifier: Apache-2.0
# Copyright (C) 2026 ReMeizu contributors
"""Derive the reviewed u7 image and matching vendor inputs without its unused DM agent."""

import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


PARENT_SHA = "701e6bd6ea68ae690a3f8c6b1d31218f0a3dd83d5ef8f71ad73af8977886747d"
BAD_SHA = "e56228e9fc4500f0e9ca6eba321aaf355131e5d753eb2cb0ebdf561ab1958075"
ENTRY = "bin/dm_agent_binder"


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def save(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n")


def main():
    p = argparse.ArgumentParser(description=__doc__)
    for name in ("parent-system", "source-vendor", "source-spec", "client-audit", "output", "scratch"):
        p.add_argument("--" + name, required=True, type=Path)
    p.add_argument("--reuse-source-copy", action="store_true",
                   help="Reuse a fully hash-verified vendor copy after an interrupted packaging step")
    a = p.parse_args()
    if not a.reuse_source_copy and (a.output.exists() or a.scratch.exists()):
        p.error("output and scratch must be fresh directories")
    if sha(a.parent_system) != PARENT_SHA:
        p.error("not the reviewed u7 parent image")
    audit = json.loads(a.client_audit.read_text())
    if audit.get("matches") or audit.get("errors") or audit.get("archives") != 241:
        p.error("reviewed APK/JAR/APEX client audit missing or failed")
    manifest_path = a.source_vendor / "proprietary/m681/mounts.tsv"
    original = manifest_path.read_text()
    line = BAD_SHA + "\t" + ENTRY + "\n"
    if original.count(line) != 1 or sha(a.source_vendor / "proprietary/m681" / ENTRY) != BAD_SHA:
        p.error("vendor parent does not contain the exact reviewed broken entry")
    proof = json.loads((a.source_vendor / "profile-proof.json").read_text())
    if proof["profiles"]["m681"]["manifest_sha256"] != sha(manifest_path):
        p.error("source vendor manifest/proof mismatch")
    if ENTRY in proof["profiles"]["l681"]["files"]:
        p.error("other revision selects DM; cannot remove shared placeholder")
    spec = json.loads(a.source_spec.read_text())
    selected = [item for item in spec["m681"]["files"] if item["destination"] == ENTRY]
    if len(selected) != 1 or selected[0]["sha256"] != BAD_SHA:
        p.error("input spec does not select the reviewed broken entry")
    derived_vendor = a.output / "vendor/meizu/m3note"
    if a.reuse_source_copy:
        if sorted(x.name for x in a.output.iterdir()) != ["vendor"] or list(a.scratch.iterdir()):
            p.error("reuse requires an otherwise empty output/scratch")
        for board, record in proof["profiles"].items():
            for path, item in record["files"].items():
                if sha(derived_vendor / "proprietary" / board / path) != item["sha256"]:
                    p.error("reused source copy differs: " + board + "/" + path)
            if sha(derived_vendor / "proprietary" / board / "mounts.tsv") != record["manifest_sha256"]:
                p.error("reused source manifest differs")
        for path in ("m3note-vendor.mk", "profile-proof.json", "empty", "unselected.xml"):
            if sha(derived_vendor / path) != sha(a.source_vendor / path):
                p.error("reused source metadata differs: " + path)
    else:
        a.output.mkdir(parents=True, mode=0o700)
        a.scratch.mkdir(parents=True, mode=0o700)
        shutil.copytree(a.source_vendor, derived_vendor)
    (derived_vendor / "proprietary/m681" / ENTRY).unlink()
    derived_manifest = derived_vendor / "proprietary/m681/mounts.tsv"
    derived_manifest.write_text(original.replace(line, ""))
    mk = derived_vendor / "m3note-vendor.mk"
    lines = mk.read_text().splitlines(keepends=True)
    removed = [s for s in lines if s.rstrip().rstrip("\\").rstrip().endswith("/dm_agent_binder")]
    if len(removed) != 2:
        raise ValueError("expected exactly profile copy and active placeholder copy")
    mk.write_text("".join(s for s in lines if s not in removed))
    del proof["profiles"]["m681"]["files"][ENTRY]
    proof["profiles"]["m681"]["manifest_sha256"] = sha(derived_manifest)
    proof["derived_from"] = {"profile_proof": str(a.source_vendor / "profile-proof.json"),
                              "sha256": sha(a.source_vendor / "profile-proof.json"),
                              "removed_unused_entry": ENTRY, "removed_sha256": BAD_SHA}
    save(derived_vendor / "profile-proof.json", proof)
    spec["m681"]["files"] = [x for x in spec["m681"]["files"] if x["destination"] != ENTRY]
    origin_path = Path(spec["m681"]["origin_receipt"])
    origin = json.loads(origin_path.read_text())
    if origin["files"].pop(ENTRY) != BAD_SHA:
        raise ValueError("origin receipt does not identify the broken source")
    origin["derived_from"] = {"path": str(origin_path), "sha256": sha(origin_path),
                              "removed_unused_entry": ENTRY, "removed_sha256": BAD_SHA}
    origin["parent_stock_subset_counts"] = origin.pop("stock_subset_counts", {})
    origin["selected_file_count"] = len(origin["files"])
    save(a.output / "m681-origin-receipt.json", origin)
    spec["m681"]["origin_receipt"] = str(a.output / "m681-origin-receipt.json")
    save(a.output / "vendor-input-spec.json", spec)
    shutil.copyfile(a.client_audit, a.output / "dm-client-audit.json")
    raw = a.scratch / "system.raw"
    subprocess.run(["cp", "--reflink=auto", "--sparse=always", str(a.parent_system), str(raw)], check=True)
    context = a.scratch / "selinux-context"
    context.write_bytes(b"u:object_r:vendor_file:s0\0")
    commands = a.output / "debugfs.commands"
    target = "/system/vendor/meizu/m681/mounts.tsv"
    commands.write_text("\n".join([
        "rm /system/vendor/meizu/m681/" + ENTRY,
        "rm /system/vendor/" + ENTRY,
        "rm " + target,
        "write " + str(derived_manifest) + " " + target,
        "set_inode_field " + target + " mode 0100644",
        "set_inode_field " + target + " uid 0",
        "set_inode_field " + target + " gid 0",
        "ea_set -f " + str(context) + " " + target + " security.selinux",
        "set_inode_field " + target + " ctime @1791242982",
        "set_inode_field " + target + " atime @1791242982",
        "set_inode_field " + target + " mtime @1791242982",
        "set_inode_field " + target + " crtime @1791299473",
    ]) + "\n")
    with (a.output / "debugfs-write.log").open("w") as log:
        subprocess.run(["/sbin/debugfs", "-w", "-f", str(commands), str(raw)], check=True,
                       stdout=log, stderr=subprocess.STDOUT)
    with (a.output / "e2fsck.log").open("w") as log:
        subprocess.run(["/sbin/e2fsck", "-f", "-n", str(raw)], check=True,
                       stdout=log, stderr=subprocess.STDOUT)
    subprocess.run(["cp", "--reflink=auto", "--sparse=always", str(raw), str(a.output / "system.raw")], check=True)
    save(a.output / "derivation.json", {
        "classification": "BOOT-UNBLOCK", "parent_system": str(a.parent_system),
        "parent_system_sha256": PARENT_SHA, "system_sha256": sha(a.output / "system.raw"),
        "system_size": raw.stat().st_size, "source_vendor": str(a.source_vendor),
        "source_spec": str(a.source_spec), "source_spec_sha256": sha(a.source_spec),
        "derived_source_vendor": str(derived_vendor), "derived_source_spec": str(a.output / "vendor-input-spec.json"),
        "removed_unused_entry": ENTRY, "removed_sha256": BAD_SHA,
        "manifest_sha256": sha(derived_manifest), "hardware_accepted": False,
        "offline_acceptance_pending": True, "boot_changed": False,
        "reason": "Legacy operator DM/OTA daemon has no init launcher or bundled system client; malformed ELF must not be activated.",
    })
    print(str(a.output / "derivation.json"))


if __name__ == "__main__":
    main()
