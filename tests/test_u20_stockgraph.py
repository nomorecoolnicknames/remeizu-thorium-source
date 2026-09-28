import importlib.util
from pathlib import Path
import stat
import sys
import tempfile
import unittest
from unittest.mock import patch
import json
import gzip

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("u20_stockgraph", ROOT / "tools/u20_stockgraph.py")
graph = importlib.util.module_from_spec(spec)
spec.loader.exec_module(graph)


def cpio_entry(name, data=b"", mode=stat.S_IFREG | 0o644):
    name = name.encode() + b"\0"
    fields = [1, mode, 0, 0, 1, 0, len(data), 0, 0, 0, 0, len(name), 0]
    prefix = b"070701" + b"".join(f"{value:08x}".encode() for value in fields) + name
    prefix += b"\0" * (-len(prefix) % 4)
    return prefix + data + b"\0" * (-len(data) % 4)


class U20StockGraphTest(unittest.TestCase):
    def test_m3s_legacy_kernel_is_not_accepted_for_modern_boards(self):
        image = graph.M3S_LEGACY_IMAGE_HEADER + b"\0" * 64
        kernel = gzip.compress(image) + b"\xd0\x0d\xfe\xed"
        self.assertEqual(graph.kernel_image(kernel, "m3s"), image)
        for board in ("u10", "u20"):
            with self.assertRaisesRegex(ValueError, "Image header"):
                graph.kernel_image(kernel, board)
        with self.assertRaisesRegex(ValueError, "appended stock DTB"):
            graph.kernel_image(gzip.compress(image), "m3s")
        with self.assertRaisesRegex(ValueError, "Image header"):
            graph.kernel_image(gzip.compress(b"wrong" + image) + b"\xd0\x0d\xfe\xed", "m3s")

    def test_modern_arm64_kernel_cannot_replace_m3s_legacy_input(self):
        image = bytearray(96)
        image[56:60] = b"ARM\x64"
        kernel = gzip.compress(image) + b"\xd0\x0d\xfe\xed"
        self.assertEqual(graph.kernel_image(kernel, "u10"), image)
        with self.assertRaisesRegex(ValueError, "Image header"):
            graph.kernel_image(kernel, "m3s")

    def test_m3s_selects_own_default_lights_and_explicit_elf_classes(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            files = []
            for directory in ("lib", "lib64"):
                for name in ("hw/gralloc.mt6750.so", "hw/hwcomposer.mt6750.so",
                             "hw/lights.default.so", "egl/libGLES_mali.so"):
                    relative = f"{directory}/{name}"
                    path = root / "system" / relative
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(b"own-m3s-library")
                    files.append({"path": relative, "sha256": graph.sha(path.read_bytes())})
            (root / "inventory.json").write_text(json.dumps({"files": files}))
            def native(path):
                return {"elf_class": 64 if "lib64" in path.parts else 32, "needed": []}
            with patch.object(graph, "elf_needs", native):
                selected = graph.native_selection(root, {"stock_nodes": []}, "m3s")
                self.assertEqual(len(selected), 8)
                self.assertTrue(all(row["module"].startswith("m3s_stock_") for row in selected.values()))
                with self.assertRaisesRegex(ValueError, "own-stock input missing"):
                    graph.native_selection(root, {"stock_nodes": []}, "u10")
            with patch.object(graph, "elf_needs", return_value={"elf_class": 32, "needed": []}):
                with self.assertRaisesRegex(ValueError, "ELF class mismatch"):
                    graph.native_selection(root, {"stock_nodes": []}, "m3s")

    def test_m3s_mounts_and_ueventd_do_not_inherit_u10_assumptions(self):
        directory = ROOT / "device/meizu/m3s/stockgraph"
        for name in ("fstab.mt6755", "recovery.fstab"):
            text = (directory / name).read_text()
            self.assertIn("/mtk-msdc.0/by-name/system", text)
            self.assertNotIn("/11230000.msdc0/", text)
            self.assertIn("encryptable=/dev/block/platform/mtk-msdc.0/by-name/metadata", text)
        rules = [line for line in (directory / "ueventd.mt6755.rc").read_text().splitlines()
                 if line and not line.startswith("#")]
        self.assertEqual(rules, ["/dev/mali 0666 system graphics"])

    def test_board_selection_cannot_fall_back_to_u20_hal_names(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            files = []
            for directory in ("lib", "lib64"):
                for name in ("hw/gralloc.mt6750.so", "hw/hwcomposer.mt6750.so", "hw/lights.mt6750.so", "egl/libGLES_mali.so"):
                    relative = f"{directory}/{name}"
                    path = root / "system" / relative
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(b"own-u10-library")
                    files.append({"path": relative, "sha256": graph.sha(path.read_bytes())})
            (root / "inventory.json").write_text(json.dumps({"files": files}))
            def native(path):
                return {"elf_class": 64 if "lib64" in path.parts else 32, "needed": []}
            with patch.object(graph, "elf_needs", native):
                selected = graph.native_selection(root, {"stock_nodes": []}, device="u10")
                self.assertEqual(len(selected), 8)
                self.assertTrue(all(row["module"].startswith("u10_stock_") for row in selected.values()))
                with self.assertRaisesRegex(ValueError, "own-stock input missing"):
                    graph.native_selection(root, {"stock_nodes": []}, device="u20")

    def test_u10_evidence_does_not_accept_another_board(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            evidence_dir = root / "planning/los16-stock"
            evidence_dir.mkdir(parents=True)
            (evidence_dir / "u10-stockgraph-evidence.json").write_text('{"board":"u10"}')
            (root / "stockgraph-evidence.json").write_text('{"board":"u20"}')
            with patch.object(graph, "REPO", root):
                with self.assertRaisesRegex(ValueError, "evidence differs"):
                    graph.verify_prepared(root, device="u10")

    def test_cpio_reads_regular_inputs_without_following_symlinks(self):
        data = cpio_entry("fstab.mt6755", b"board-fstab")
        data += cpio_entry("escape", b"/etc/passwd", stat.S_IFLNK | 0o777)
        data += cpio_entry("TRAILER!!!")
        self.assertEqual(graph.cpio_files(data), {"fstab.mt6755": b"board-fstab"})

    def test_cpio_traversal_and_truncation_are_rejected(self):
        for data in (cpio_entry("../fstab") + cpio_entry("TRAILER!!!"), cpio_entry("fstab", b"a")[:-4]):
            with self.assertRaises(ValueError):
                graph.cpio_files(data)

    def test_private_make_has_explicit_arch_stem_and_dependencies(self):
        entry = {"module": "u20_stock_lib64_hw_lights_mt6755", "elf_class": 64,
                 "shared_libraries": ["libc", "liblog"]}
        text = graph.android_make({"lib64/hw/lights.mt6755.so": entry})
        self.assertIn("LOCAL_MODULE_STEM := lights.mt6755", text)
        self.assertIn("LOCAL_MODULE_PATH := $(TARGET_OUT)/lib64/hw", text)
        self.assertIn("LOCAL_MULTILIB := 64", text)
        self.assertIn("LOCAL_SHARED_LIBRARIES := libc liblog", text)
        self.assertIn("ifeq ($(TARGET_PRODUCT),lineage_u20_stockgraph)", text)
        self.assertNotIn("ALLOW_MISSING_DEPENDENCIES", text)
        self.assertNotIn("LOCAL_CHECK_ELF_FILES", text)

    def test_graph_is_separate_and_uses_own_stock_kernel(self):
        board = (ROOT / "device/meizu/u20/BoardConfig.mk").read_text()
        product = (ROOT / "device/meizu/u20/lineage_u20_stockgraph.mk").read_text()
        device = (ROOT / "device/meizu/u20/stockgraph/device.mk").read_text()
        self.assertIn("ifeq ($(TARGET_PRODUCT),lineage_u20_stockgraph)", board)
        self.assertIn("TARGET_PREBUILT_KERNEL := vendor/meizu/u20/proprietary/boot/Image.gz-dtb", board)
        self.assertLess(product.index("core_64_bit.mk"), product.index("full_base_telephony.mk"))
        self.assertNotIn("mt6755-common/device-common.mk", device)
        self.assertNotIn("meizu_m6", product + device)

    def test_u20_mounts_do_not_reuse_donor_mmc_controller(self):
        for name in ("fstab.mt6755", "recovery.fstab"):
            text = (ROOT / "device/meizu/u20/stockgraph" / name).read_text()
            self.assertIn("11230000.msdc0/by-name/system", text)
            self.assertNotIn("11240000.msdc1/by-name", text)
            self.assertIn("encryptable=/dev/block/platform/mtk-msdc.0/11230000.msdc0/by-name/metadata", text)

    def test_private_preflight_rejects_mutation_and_extra_files(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            evidence_dir = root / "planning/los16-stock"
            evidence_dir.mkdir(parents=True)
            output = root / "vendor"
            (output / "proprietary/boot").mkdir(parents=True)
            (output / "proprietary/boot/Image.gz-dtb").write_bytes(b"kernel")
            expected = {"kernel_sha256": graph.sha(b"kernel"), "native_files": {}}
            (evidence_dir / "u20-stockgraph-evidence.json").write_text(json.dumps(expected))
            (output / "stockgraph-evidence.json").write_text(json.dumps(expected))
            (output / "Android.mk").write_text(graph.android_make({}))
            (output / "BoardConfigVendor.mk").write_text("# U20 stockgraph vendor: architecture/layout live in the device tree.\n")
            (output / "u20-stockgraph-vendor.mk").write_text(graph.vendor_product({}))
            with patch.object(graph, "REPO", root):
                self.assertEqual(graph.verify_prepared(output), expected)
                (output / "proprietary/boot/Image.gz-dtb").write_bytes(b"donor-kernel")
                with self.assertRaisesRegex(ValueError, "kernel payload changed"):
                    graph.verify_prepared(output)
                (output / "Android.bp").write_text("unexpected extra module")
                with self.assertRaisesRegex(ValueError, "unexpected or missing"):
                    graph.verify_prepared(output)

    def test_preflight_rejects_even_pinned_stock_jni_helper(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            evidence_dir = root / "planning/los16-stock"
            evidence_dir.mkdir(parents=True)
            output = root / "vendor"
            (output / "proprietary/boot").mkdir(parents=True)
            (output / "proprietary/lib").mkdir()
            (output / "proprietary/boot/Image.gz-dtb").write_bytes(b"kernel")
            (output / "proprietary/lib/libnativehelper.so").write_bytes(b"old-platform-jni")
            native = {"lib/libnativehelper.so": {"sha256": graph.sha(b"old-platform-jni"),
                      "module": "m3s_stock_lib_libnativehelper", "elf_class": 32,
                      "shared_libraries": []}}
            expected = {"kernel_sha256": graph.sha(b"kernel"), "native_files": native}
            (evidence_dir / "m3s-stockgraph-evidence.json").write_text(json.dumps(expected))
            (output / "stockgraph-evidence.json").write_text(json.dumps(expected))
            (output / "Android.mk").write_text(graph.android_make(native, "m3s"))
            (output / "m3s-stockgraph-vendor.mk").write_text(graph.vendor_product(native))
            (output / "BoardConfigVendor.mk").write_text("# M3S stockgraph vendor: architecture/layout live in the device tree.\n")
            with patch.object(graph, "REPO", root):
                with self.assertRaisesRegex(ValueError, "platform library cannot be replaced"):
                    graph.verify_prepared(output, "m3s")


if __name__ == "__main__":
    unittest.main()
