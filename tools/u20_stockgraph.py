#!/usr/bin/env python3
"""Prepare private, pinned U20, U10 or M3s inputs for a diagnostic LOS16 graph.

The graph packages the stock kernel and a reviewed graphics/lights native subset.
It does not establish Pie kernel binder support, ABI compatibility or a bootable ROM.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re
import shutil
import stat
import struct

from los16_stock_inputs import boot_header, elf_needs, safe_relative

REPO = Path(__file__).resolve().parents[1]
BOARD_SPECS = {
    "u20": {"hal_platform": "mt6755", "ramdisk_platform": "mt6755"},
    "u10": {"hal_platform": "mt6750", "ramdisk_platform": "mt6755"},
    "m3s": {"hal_platform": "mt6750", "ramdisk_platform": "mt6755",
            "lights_platform": "default", "ueventd_file": "ueventd.rc"},
}
# Exact 3.10 M3s entry header: AArch64 branch to offset 0x20 and text_offset
# 0x80000. This pinned legacy input predates the later ARM64 header magic;
# accepting it does not relax the modern U10/U20 header or boot hash checks.
M3S_LEGACY_IMAGE_HEADER = bytes.fromhex(
    "0800001400000000000008000000000000000000000000000000000000000000")
EXTRA_REVIEWED = {"lib/libgpu_aux.so", "lib64/libgpu_aux.so"}
FORBIDDEN = {"libc.so", "libdl.so", "libm.so", "libc++.so", "libbinder.so", "libutils.so", "libui.so", "libgui.so", "libbluetooth_jni.so", "libandroid_runtime.so", "libnativehelper.so"}
SOONG_INPUTS = {"lib/libnvram.so": 32, "lib64/libnvram.so": 64}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def soong_inputs(stock):
    """Real own-board providers needed even by unselected global Soong modules.

    This does not add Bluetooth/NVRAM to PRODUCT_PACKAGES or assert their ABI.
    The graphics diagnostic product still selects only its reviewed native set.
    """
    inventory = json.loads((stock / "inventory.json").read_text())
    files = {row["path"]: row for row in inventory["files"] if "sha256" in row}
    providers = {}
    for relative, bits in SOONG_INPUTS.items():
        path = stock / "system" / relative
        row = files.get(relative)
        if not row or path.is_symlink() or sha(path.read_bytes()) != row["sha256"]:
            raise ValueError("changed or missing own-board Soong input: " + relative)
        native = elf_needs(path)
        if not native or native["elf_class"] != bits:
            raise ValueError("Soong input ELF class mismatch: " + relative)
        providers[relative] = {"sha256": row["sha256"], "elf_class": bits,
                               "needed": native["needed"], "module": "libnvram",
                               "installed_by_diagnostic_product": False,
                               "runtime_abi_verified": False}
    return providers


def android_blueprint(providers):
    if set(providers) != set(SOONG_INPUTS):
        raise ValueError("exact own-board multilib Soong providers required")
    return '''// PROPER-FIX: global MTK Bluetooth graph requires a real libnvram owner.
// Own-board files only; this diagnostic product does not select Bluetooth/NVRAM.
cc_prebuilt_library_shared {
    name: "libnvram",
    proprietary: true,
    compile_multilib: "both",
    multilib: {
        lib32: { srcs: ["proprietary/lib/libnvram.so"] },
        lib64: { srcs: ["proprietary/lib64/libnvram.so"] },
    },
    strip: { none: true },
}
'''


def cpio_files(raw):
    files, pos = {}, 0
    while pos + 110 <= len(raw):
        header = raw[pos:pos + 110]
        if header[:6] not in (b"070701", b"070702"):
            raise ValueError("unsupported ramdisk CPIO format")
        values = [int(header[6 + i * 8:14 + i * 8], 16) for i in range(13)]
        mode, size, name_size = values[1], values[6], values[11]
        name_bytes = raw[pos + 110:pos + 110 + name_size]
        if not name_bytes.endswith(b"\0"):
            raise ValueError("invalid CPIO filename")
        name = name_bytes[:-1].decode()
        pos = (pos + 110 + name_size + 3) & ~3
        if name == "TRAILER!!!":
            return files
        name = safe_relative(name)
        data = raw[pos:pos + size]
        if len(data) != size:
            raise ValueError("truncated ramdisk CPIO data")
        pos = (pos + size + 3) & ~3
        if stat.S_ISREG(mode):
            if name in files:
                raise ValueError("duplicate ramdisk filename")
            files[name] = data
    raise ValueError("missing ramdisk CPIO trailer")


def module_name(relative, device="u20"):
    stem = relative[:-3] if relative.endswith(".so") else relative
    return device + "_stock_" + re.sub(r"[^A-Za-z0-9_]", "_", stem)


def native_selection(stock, vendor_map, device="u20"):
    inventory = json.loads((stock / "inventory.json").read_text())
    files = {row["path"]: row for row in inventory["files"] if "sha256" in row}
    platform, approved = {}, set(EXTRA_REVIEWED)
    for node in vendor_map["stock_nodes"]:
        for edge in node["dependencies"]:
            key = (node["elf_class"], edge["needed"])
            if edge["classification"] == "platform-source-candidate":
                platform[key] = edge["platform_modules"]
            elif edge["classification"] == "own-stock-only-candidate":
                approved.update(edge["stock_candidates"])
    platform_name = BOARD_SPECS[device]["hal_platform"]
    board_seeds = [f"hw/{name}.{platform_name}.so" for name in ("gralloc", "hwcomposer")]
    board_seeds.append("hw/lights." + BOARD_SPECS[device].get("lights_platform", platform_name) + ".so")
    board_seeds.append("egl/libGLES_mali.so")
    seeds = [f"{directory}/{seed}" for directory in ("lib", "lib64") for seed in board_seeds]
    todo, selected = list(seeds), {}
    while todo:
        relative = todo.pop(0)
        if relative in selected:
            continue
        if Path(relative).name in FORBIDDEN:
            raise ValueError(f"platform library cannot be replaced by stock: {relative}")
        row = files.get(relative)
        if not row:
            raise ValueError(f"own-stock input missing: {relative}")
        path = stock / "system" / relative
        if path.is_symlink() or sha(path.read_bytes()) != row["sha256"]:
            raise ValueError(f"changed own-stock input: {relative}")
        native = elf_needs(path)
        expected = 64 if relative.startswith("lib64/") else 32
        if not native or native["elf_class"] != expected:
            raise ValueError(f"ELF class mismatch: {relative}")
        directory = "lib64" if expected == 64 else "lib"
        dependencies, abi = [], []
        for needed in native["needed"]:
            provider = platform.get((expected, needed))
            if provider:
                dependencies.append(needed[:-3] if needed.endswith(".so") else needed)
                abi.append({"needed": needed, "source_candidates": provider})
                continue
            candidates = [p for p in (f"{directory}/{needed}", f"vendor/{directory}/{needed}") if p in files]
            if len(candidates) != 1 or candidates[0] not in approved:
                raise ValueError(f"dependency needs explicit provider review: {relative}: {needed}")
            dependency = candidates[0]
            if Path(dependency).name in FORBIDDEN:
                raise ValueError(f"platform provider missing; no stock fallback: {needed}")
            dependencies.append(module_name(dependency, device))
            todo.append(dependency)
        selected[relative] = {"sha256": row["sha256"], "elf_class": expected,
                              "module": module_name(relative, device), "shared_libraries": sorted(set(dependencies)),
                              "unverified_platform_abi": abi}
    return selected


def android_make(selected, device="u20"):
    lines = [f"# DIAGNOSTIC: exact {device.upper()} own-stock inputs; ABI remains unverified.",
             "LOCAL_PATH := $(call my-dir)", f"ifeq ($(TARGET_PRODUCT),lineage_{device}_stockgraph)"]
    for relative, entry in sorted(selected.items()):
        destination = Path(relative)
        lines += ["", "include $(CLEAR_VARS)", f"LOCAL_MODULE := {entry['module']}",
                  "LOCAL_MODULE_CLASS := SHARED_LIBRARIES", "LOCAL_MODULE_SUFFIX := .so",
                  f"LOCAL_MODULE_STEM := {destination.stem}", "LOCAL_MODULE_TAGS := optional",
                  "LOCAL_MODULE_OWNER := meizu", f"LOCAL_MULTILIB := {entry['elf_class']}",
                  f"LOCAL_SRC_FILES := proprietary/{relative}",
                  f"LOCAL_MODULE_PATH := $(TARGET_OUT)/{destination.parent}",
                  "LOCAL_STRIP_MODULE := false", "LOCAL_SHARED_LIBRARIES := " + " ".join(entry["shared_libraries"]),
                  "include $(BUILD_PREBUILT)"]
    return "\n".join(lines + ["", "endif", ""])


def vendor_product(selected):
    return ("# DIAGNOSTIC native graph; no stock platform libraries or JNI.\nPRODUCT_PACKAGES += "
            + " ".join(entry["module"] for _, entry in sorted(selected.items())) + "\n")


def kernel_image(kernel, device):
    import zlib
    decompressor = zlib.decompressobj(16 + zlib.MAX_WBITS)
    image = decompressor.decompress(kernel) + decompressor.flush()
    if not decompressor.eof or not decompressor.unused_data.startswith(b"\xd0\x0d\xfe\xed"):
        raise ValueError("expected complete gzip Image with appended stock DTB")
    if device == "m3s":
        valid_header = image.startswith(M3S_LEGACY_IMAGE_HEADER)
    else:
        valid_header = image[56:60] == b"ARM\x64"
    if not valid_header:
        raise ValueError(f"unexpected {device} ARM64 Image header")
    return image


def verify_prepared(output, device="u20"):
    expected = json.loads((REPO / f"planning/los16-stock/{device}-stockgraph-evidence.json").read_text())
    actual = json.loads((output / "stockgraph-evidence.json").read_text())
    if actual != expected:
        raise ValueError(f"private {device} evidence differs from the committed selection")
    expected_paths = {"Android.mk", "BoardConfigVendor.mk", f"{device}-stockgraph-vendor.mk",
                      "stockgraph-evidence.json", "proprietary/boot/Image.gz-dtb"}
    expected_paths.update("proprietary/" + path for path in expected["native_files"])
    providers = expected.get("soong_providers", {})
    if providers:
        expected_paths.add("Android.bp")
        expected_paths.update("proprietary/" + path for path in providers)
        blueprint = android_blueprint(providers)
        if (output / "Android.bp").read_text() != blueprint:
            raise ValueError("private Soong provider declaration changed")
        for relative, entry in providers.items():
            path = output / "proprietary" / relative
            if path.is_symlink() or sha(path.read_bytes()) != entry["sha256"]:
                raise ValueError("private own-board Soong input changed: " + relative)
    actual_paths = {path.relative_to(output).as_posix() for path in output.rglob("*")
                    if path.is_file() or path.is_symlink()}
    if actual_paths != expected_paths:
        raise ValueError(f"unexpected or missing files in private {device} vendor")
    for relative, entry in expected["native_files"].items():
        if Path(relative).name in FORBIDDEN:
            raise ValueError(f"platform library cannot be replaced by stock: {relative}")
        path = output / "proprietary" / relative
        if path.is_symlink() or sha(path.read_bytes()) != entry["sha256"]:
            raise ValueError(f"private {device} payload changed: {relative}")
    kernel = output / "proprietary/boot/Image.gz-dtb"
    if kernel.is_symlink() or sha(kernel.read_bytes()) != expected["kernel_sha256"]:
        raise ValueError(f"private {device} kernel payload changed")
    if (output / "Android.mk").read_text() != android_make(expected["native_files"], device):
        raise ValueError(f"private {device} module declarations changed")
    if (output / f"{device}-stockgraph-vendor.mk").read_text() != vendor_product(expected["native_files"]):
        raise ValueError(f"private {device} package selection changed")
    if (output / "BoardConfigVendor.mk").read_text() != f"# {device.upper()} stockgraph vendor: architecture/layout live in the device tree.\n":
        raise ValueError(f"private {device} board overrides changed")
    return expected


def prepare(stock, boot, output, device="u20"):
    if output.exists():
        raise ValueError("output must not already exist")
    report = json.loads((REPO / f"planning/los16-stock/{device}.json").read_text())
    vendor_map = json.loads((REPO / f"planning/los16-stock/{device}-vendor-map.json").read_text())
    inventory = json.loads((stock / "inventory.json").read_text())
    raw = boot.read_bytes()
    if sha(raw) != report["boot"]["sha256"] or inventory["boot_sha256"] != sha(raw):
        raise ValueError(f"{device} boot/full-system identity mismatch")
    header = boot_header(raw)
    page, size = header["page_size"], header["kernel_size"]
    kernel = raw[page:page + size]
    if sha(kernel) != header["kernel_payload_sha256"]:
        raise ValueError("kernel payload hash mismatch")
    image = kernel_image(kernel, device)
    ramdisk_offset = page + ((size + page - 1) // page) * page
    packed_ramdisk = raw[ramdisk_offset:ramdisk_offset + header["ramdisk_size"]]
    ramdisk = cpio_files(gzip.decompress(packed_ramdisk))
    selected = native_selection(stock, vendor_map, device)
    providers = soong_inputs(stock)
    if set(providers) & set(selected):
        raise ValueError("Soong provider also selected by native Make graph; review ownership")
    output.mkdir(parents=True, mode=0o700)
    (output / "proprietary/boot").mkdir(parents=True)
    (output / "proprietary/boot/Image.gz-dtb").write_bytes(kernel)
    for relative in list(selected) + list(providers):
        target = output / "proprietary" / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(stock / "system" / relative, target)
    (output / "Android.mk").write_text(android_make(selected, device))
    (output / "Android.bp").write_text(android_blueprint(providers))
    (output / "BoardConfigVendor.mk").write_text(f"# {device.upper()} stockgraph vendor: architecture/layout live in the device tree.\n")
    (output / f"{device}-stockgraph-vendor.mk").write_text(vendor_product(selected))
    evidence = {"schema_version": f"remeizu.{device}.stockgraph.v1", "boot_sha256": sha(raw),
                "kernel_sha256": sha(kernel), "ramdisk_sha256": sha(packed_ramdisk),
                "kernel_arch": "arm64", "ikconfig_available": b"IKCFG_ST" in image,
                "kernel_string_presence": {s: s.encode() in image for s in ("hwbinder", "vndbinder", "binder.devices", "binder_ioctl", "binder_transaction")},
                "stock_binder_abi_verified": False, "runtime_verified": False,
                "native_files": selected, "soong_providers": providers,
                "stock_fstab_sha256": sha(ramdisk["fstab." + BOARD_SPECS[device]["ramdisk_platform"]]),
                "stock_init_sha256": sha(ramdisk["init." + BOARD_SPECS[device]["ramdisk_platform"] + ".rc"]),
                "stock_ueventd_sha256": sha(ramdisk[BOARD_SPECS[device].get("ueventd_file",
                    "ueventd." + BOARD_SPECS[device]["ramdisk_platform"] + ".rc")])}
    if device == "m3s":
        evidence["kernel_header_format"] = "pinned-legacy-arm64-3.10"
        evidence["stock_ueventd_file"] = "ueventd.rc"
    (output / "stockgraph-evidence.json").write_text(json.dumps(evidence, indent=2, sort_keys=True) + "\n")
    return evidence


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--device", choices=tuple(BOARD_SPECS), default="u20")
    parser.add_argument("--private-stock", type=Path)
    parser.add_argument("--boot", type=Path)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--verify-existing", action="store_true")
    args = parser.parse_args()
    if args.verify_existing:
        evidence = verify_prepared(args.output, args.device)
    else:
        if args.private_stock is None or args.boot is None:
            parser.error("preparation requires --private-stock and --boot")
        evidence = prepare(args.private_stock, args.boot, args.output, args.device)
    print(json.dumps({"native_files": len(evidence["native_files"]), "kernel_sha256": evidence["kernel_sha256"],
                      "stock_binder_abi_verified": False, "runtime_verified": False}))


if __name__ == "__main__":
    main()
