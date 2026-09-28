import importlib.util
from pathlib import Path
import struct
import sys
import unittest

MODULE = Path(__file__).resolve().parents[1] / "tools/los16_stock_inputs.py"
sys.path.insert(0, str(MODULE.parent))
spec = importlib.util.spec_from_file_location("stock_inputs", MODULE)
stock = importlib.util.module_from_spec(spec)
spec.loader.exec_module(stock)
extract_spec = importlib.util.spec_from_file_location("stock_extract", MODULE.with_name("los16_extract_stock.py"))
extractor = importlib.util.module_from_spec(extract_spec)
extract_spec.loader.exec_module(extractor)


class StockInputsTest(unittest.TestCase):
    def header(self):
        data = bytearray(6144)
        data[:8] = b"ANDROID!"
        struct.pack_into("<10I", data, 8, 100, 0x40080000, 100, 0x45000000,
                         0, 0x40f00000, 0x44000000, 2048, 0, 0)
        data[64:68] = b"boot"
        return data

    def scatter(self):
        return "recovery 0x8000\npara 0x1008000\nboot 0x2c600000\nlogo 0x2d600000\nsystem 0x30000000\ncache 0xd0000000\nuserdata 0xeb000000\nflashinfo 0xffff0080\nsgpt 0xffff0000\n"

    def test_boot_addresses_and_hash(self):
        result = stock.boot_header(self.header())
        self.assertEqual(result["ramdisk_addr"], 0x45000000)
        self.assertEqual(result["cmdline"], "boot")
        self.assertEqual(len(result["kernel_payload_sha256"]), 64)

    def test_truncated_payload_rejected(self):
        with self.assertRaisesRegex(ValueError, "truncated"):
            stock.boot_header(self.header()[:3000])

    def test_unsupported_header_rejected(self):
        data = self.header()
        struct.pack_into("<I", data, 40, 2)
        with self.assertRaisesRegex(ValueError, "unsupported"):
            stock.boot_header(data)

    def test_partition_bounds_do_not_invent_userdata(self):
        result = stock.partition_geometry(self.scatter())
        self.assertEqual(result["recovery"]["size"], 16777216)
        self.assertEqual(result["system"]["size"], 2684354560)
        self.assertNotIn("userdata", result)

    def test_nonadjacent_boundaries_rejected(self):
        text = self.scatter().replace("logo 0x2d600000", "unrelated 0x2d000000\nlogo 0x2d600000")
        with self.assertRaisesRegex(ValueError, "adjacent"):
            stock.partition_geometry(text)

    def test_duplicate_partition_rejected(self):
        with self.assertRaisesRegex(ValueError, "duplicate"):
            stock.partition_geometry(self.scatter() + "boot 0x2c600000\n")

    def test_board_make_uses_exact_addresses(self):
        report = {"boot": stock.boot_header(self.header()),
                  "partition_bounds": stock.partition_geometry(self.scatter()),
                  "scatter_sha256": "a" * 64}
        text = stock.board_make(report)
        self.assertIn("BOARD_KERNEL_BASE := 0x00000000", text)
        self.assertIn("--kernel_offset 0x40080000", text)
        self.assertIn("BOARD_RECOVERYIMAGE_PARTITION_SIZE := 16777216", text)
        self.assertNotIn("BOARD_USERDATAIMAGE_PARTITION_SIZE", text)

    def test_unsafe_paths_rejected(self):
        for path in ("../blob.so", "/tmp/blob.so", "lib/$(touch)", "lib/a b"):
            with self.subTest(path=path), self.assertRaises(ValueError):
                stock.safe_relative(path)
        self.assertEqual(stock.safe_relative("./lib64/hw/camera.mt6755.so"), "lib64/hw/camera.mt6755.so")

    def test_newcomers_require_their_own_vendor(self):
        root = MODULE.parents[1] / "device/meizu"
        for device in ("m3s", "u10", "u20", "m5", "m5note"):
            with self.subTest(device=device):
                product = (root / device / "device.mk").read_text()
                board = (root / device / "BoardConfig.mk").read_text()
                self.assertIn(f"$(call inherit-product, vendor/meizu/{device}/{device}-vendor.mk)", product)
                self.assertNotIn("inherit-product-if-exists, vendor/", product)
                self.assertNotIn("vendor/meizu/meizu_m6", product + board)
                self.assertNotIn("-include vendor/", board)
                self.assertGreater(board.index(f"include vendor/meizu/{device}/"),
                                   board.index("include device/meizu/mt6755-common/BoardConfigCommon.mk"))

    def test_committed_board_geometry_matches_evidence(self):
        root = MODULE.parents[1]
        import json
        for device in ("m3s", "u10", "u20"):
            with self.subTest(device=device):
                report = json.loads((root / "planning/los16-stock" / f"{device}.json").read_text())
                self.assertFalse(report["build_ready"])
                self.assertFalse(report["vendor_complete"])
                self.assertEqual((root / "device/meizu" / device / "BoardConfigStock.mk").read_text(),
                                 stock.board_make(report))

    def test_full_ota_ranges(self):
        commands = extractor.transfer_commands("3\n4\n0\n0\nnew 2,0,2\nzero 2,2,3\nerase 2,3,4\n")
        self.assertEqual(commands, [("new", 0, 2), ("zero", 2, 3), ("erase", 3, 4)])

    def test_incremental_and_overlapping_ota_rejected(self):
        for command in ("move abcd 2,0,2", "new 4,0,2,1,3"):
            with self.subTest(command=command), self.assertRaises(ValueError):
                extractor.transfer_commands("3\n4\n0\n0\n" + command + "\n")

    def test_initial_partition_erase_can_cover_later_new_ranges(self):
        text = "2\n3\n0\n0\nerase 2,0,4\nnew 4,0,1,2,4\n"
        self.assertEqual(extractor.transfer_commands(text),
                         [("erase", 0, 4), ("new", 0, 1), ("new", 2, 4)])

    def test_later_erase_or_zero_must_not_hide_written_data(self):
        for commands in ("new 2,0,2\nerase 2,0,4", "new 2,0,2\nzero 2,1,3",
                         "zero 2,0,2\nnew 2,1,3"):
            with self.subTest(commands=commands), self.assertRaises(ValueError):
                extractor.transfer_commands("2\n4\n0\n0\n" + commands + "\n")


if __name__ == "__main__":
    unittest.main()
