import hashlib
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
spec = importlib.util.spec_from_file_location("vendor_map", ROOT / "tools/los16_vendor_map.py")
vendor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(vendor)


class VendorMapTest(unittest.TestCase):
    def test_top_level_jni_helper_is_a_platform_provider(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "libnativehelper").mkdir()
            (root / "libnativehelper/Android.bp").write_text(
                'cc_library {\n    name: "libnativehelper",\n}\n')
            self.assertEqual(vendor.platform_modules(root)["libnativehelper"],
                             [{"path": "libnativehelper/Android.bp", "line": 2}])

    def fixture(self, directory):
        private = directory / "private"
        (private / "system/lib/hw").mkdir(parents=True)
        (private / "system/lib/hw/audio.board.so").write_bytes(b"stock-hal")
        (private / "system/lib/liboem.so").write_bytes(b"stock-oem")
        platform = directory / "platform"
        (platform / "bionic").mkdir(parents=True)
        (platform / "bionic/Android.bp").write_text('cc_library { name: "libc" }\n')
        rows = [{"path": path, "sha256": hashlib.sha256(data).hexdigest()}
                for path, data in (("lib/hw/audio.board.so", b"stock-hal"), ("lib/liboem.so", b"stock-oem"))]
        (private / "inventory.json").write_text(json.dumps({"boot_sha256": "boot-pin", "files": rows}))
        report = {"device": "board", "boot": {"sha256": "boot-pin"}, "blobs": [rows[0] | {"elf_class": 32}]}
        modules = {"libc": [{"path": "bionic/Android.bp", "line": 1}]}
        return private, platform, report, modules

    def native(self, path):
        return {"elf_class": 32, "needed": ["libc.so", "liboem.so"] if path.name.startswith("audio") else ["libc.so"]}

    def test_platform_candidates_are_not_copied_into_stock_graph(self):
        with tempfile.TemporaryDirectory() as temp:
            private, platform, report, modules = self.fixture(Path(temp))
            with patch.object(vendor, "elf_needs", side_effect=self.native):
                result = vendor.map_vendor(report, private, modules, platform)
            self.assertFalse(result["vendor_ready"])
            self.assertEqual(result["unique_dependencies_by_classification"],
                             {"platform-source-candidate": 1, "own-stock-only-candidate": 1})
            self.assertEqual({row["path"] for row in result["stock_nodes"]},
                             {"lib/hw/audio.board.so", "lib/liboem.so"})

    def test_cross_board_extract_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            private, platform, report, modules = self.fixture(Path(temp))
            report["boot"]["sha256"] = "another-board"
            with self.assertRaisesRegex(ValueError, "pinned board"):
                vendor.map_vendor(report, private, modules, platform)

    def test_mutated_stock_file_is_rejected(self):
        with tempfile.TemporaryDirectory() as temp:
            private, platform, report, modules = self.fixture(Path(temp))
            (private / "system/lib/hw/audio.board.so").write_bytes(b"changed")
            with self.assertRaisesRegex(ValueError, "changed since extraction"):
                vendor.map_vendor(report, private, modules, platform)

    def test_missing_dependency_remains_explicit(self):
        with tempfile.TemporaryDirectory() as temp:
            private, platform, report, modules = self.fixture(Path(temp))
            with patch.object(vendor, "elf_needs", return_value={"elf_class": 32, "needed": ["libmissing.so"]}):
                result = vendor.map_vendor(report, private, modules, platform)
            self.assertEqual(result["unique_dependencies_by_classification"], {"unresolved": 1})
            self.assertFalse(result["vendor_ready"])


if __name__ == "__main__":
    unittest.main()
