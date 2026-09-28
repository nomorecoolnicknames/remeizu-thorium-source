"""Check publication/failure boundaries without running an Android build."""
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest

from test_u20_stockgraph import graph

ROOT = Path(__file__).resolve().parents[1]


class StockGraphRunnerTest(unittest.TestCase):
    def run_gate(self, *, graph_status=0, sdk="28", mutate_kernel=False):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            top, thorium, artifacts = root / "android", root / "thorium", root / "artifacts"
            vendor = top / "vendor/meizu/m3s"
            (vendor / "proprietary/boot").mkdir(parents=True)
            kernel = b"test-pinned-kernel"
            expected = {"kernel_sha256": hashlib.sha256(kernel).hexdigest(), "native_files": {}}
            (vendor / "proprietary/boot/Image.gz-dtb").write_bytes(b"wrong-board" if mutate_kernel else kernel)
            (vendor / "stockgraph-evidence.json").write_text(json.dumps(expected))
            (vendor / "Android.mk").write_text(graph.android_make({}, "m3s"))
            (vendor / "BoardConfigVendor.mk").write_text("# M3S stockgraph vendor: architecture/layout live in the device tree.\n")
            (vendor / "m3s-stockgraph-vendor.mk").write_text(graph.vendor_product({}))
            (thorium / "tools").mkdir(parents=True)
            for filename in ("u20_stockgraph.py", "los16_stock_inputs.py"):
                shutil.copyfile(ROOT / "tools" / filename, thorium / "tools" / filename)
            evidence = thorium / "planning/los16-stock/m3s-stockgraph-evidence.json"
            evidence.parent.mkdir(parents=True)
            evidence.write_text(json.dumps(expected))
            product = top / "device/meizu/m3s/lineage_m3s_stockgraph.mk"
            product.parent.mkdir(parents=True)
            product.touch()
            (top / "build").mkdir()
            (top / "build/envsetup.sh").write_text('''
lunch() { test "$1" = lineage_m3s_stockgraph-userdebug; }
get_build_var() {
    case "$1" in
        TARGET_PRODUCT) echo lineage_m3s_stockgraph ;;
        TARGET_BUILD_VARIANT) echo userdebug ;;
        PLATFORM_SDK_VERSION) echo "$TEST_SDK" ;;
    esac
}
m() {
    test -z "${ALLOW_MISSING_DEPENDENCIES:-}" || return 98
    test "$FORGE_OFFLINE_SOURCE_SNAPSHOT" = 1 || return 97
    test "$*" = "-j2 nothing" || return 96
    echo graph > "$TEST_GRAPH_MARKER"
    return "$TEST_GRAPH_STATUS"
}
''')
            runner = root / "runner.sh"
            runner.write_text((ROOT / "tools/run_m3s_stockgraph.sh").read_text().replace(
                "/workspace/out", str(artifacts)))
            env = dict(os.environ, OUT_DIR=str(root / "scratch/out"),
                       ALLOW_MISSING_DEPENDENCIES="true", TEST_SDK=sdk,
                       TEST_GRAPH_STATUS=str(graph_status), TEST_GRAPH_MARKER=str(root / "graph-ran"))
            result = subprocess.run(["bash", str(runner), str(top), str(thorium), "userdebug"],
                                    env=env, capture_output=True, text=True)
            files = {p.name: p.read_text() for p in artifacts.glob("*")}
            return result.returncode, (root / "graph-ran").exists(), files

    def test_success_publishes_checked_identity_after_strict_graph(self):
        status, graph_ran, files = self.run_gate()
        self.assertEqual(status, 0)
        self.assertTrue(graph_ran)
        self.assertEqual(set(files), {"m3s-stockgraph-evidence.json", "product-config.txt"})
        self.assertIn("runtime_verified=false", files["product-config.txt"])
        self.assertIn("graph_exit_code=0", files["product-config.txt"])

    def test_failed_graph_cannot_publish_success_identity(self):
        status, graph_ran, files = self.run_gate(graph_status=47)
        self.assertEqual(status, 47)
        self.assertTrue(graph_ran)
        self.assertEqual(files, {})

    def test_wrong_sdk_or_private_kernel_stops_before_graph(self):
        for options in ({"sdk": "27"}, {"mutate_kernel": True}):
            with self.subTest(options=options):
                status, graph_ran, files = self.run_gate(**options)
                self.assertNotEqual(status, 0)
                self.assertFalse(graph_ran)
                self.assertEqual(files, {})


if __name__ == "__main__":
    unittest.main()
