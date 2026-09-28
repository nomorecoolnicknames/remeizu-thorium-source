import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from test_u20_stockgraph import graph


class OwnSoongProviderTests(unittest.TestCase):
    def make_stock(self, root):
        files = []
        for relative in graph.SOONG_INPUTS:
            path = root / "system" / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(("own-board:" + relative).encode())
            files.append({"path": relative, "sha256": graph.sha(path.read_bytes())})
        (root / "inventory.json").write_text(json.dumps({"files": files}))

    def native(self, path):
        return {"elf_class": 64 if "lib64" in path.parts else 32,
                "needed": ["libcustom_nvram.so", "libc.so"]}

    def test_real_provider_does_not_promote_bluetooth_or_runtime_packages(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(graph, "elf_needs", self.native):
            root = Path(tmp)
            self.make_stock(root)
            providers = graph.soong_inputs(root)
            self.assertEqual(set(providers), set(graph.SOONG_INPUTS))
            self.assertIn('name: "libnvram"', graph.android_blueprint(providers))
            self.assertNotIn("libnvram", graph.vendor_product({}))
            for value in providers.values():
                self.assertFalse(value["runtime_abi_verified"])
                self.assertFalse(value["installed_by_diagnostic_product"])
                self.assertIn("libcustom_nvram.so", value["needed"])
            with self.assertRaisesRegex(ValueError, "exact own-board"):
                graph.android_blueprint({"lib/libnativehelper.so": {}})

    def test_donor_bytes_and_wrong_architecture_are_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.make_stock(root)
            with patch.object(graph, "elf_needs", return_value={"elf_class": 32, "needed": []}):
                with self.assertRaisesRegex(ValueError, "ELF class mismatch"):
                    graph.soong_inputs(root)
            (root / "system/lib/libnvram.so").write_bytes(b"foreign board")
            with self.assertRaisesRegex(ValueError, "own-board Soong input"):
                graph.soong_inputs(root)

    def test_private_verifier_rejects_changed_provider_or_blueprint(self):
        with tempfile.TemporaryDirectory() as tmp, patch.object(graph, "elf_needs", self.native):
            root = Path(tmp)
            self.make_stock(root)
            providers = graph.soong_inputs(root)
            out = root / "vendor"
            (out / "proprietary/boot").mkdir(parents=True)
            (out / "proprietary/boot/Image.gz-dtb").write_bytes(b"kernel")
            for relative in providers:
                target = out / "proprietary" / relative
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_bytes((root / "system" / relative).read_bytes())
            expected = {"native_files": {}, "soong_providers": providers,
                        "kernel_sha256": graph.sha(b"kernel")}
            evidence = root / "planning/los16-stock/u20-stockgraph-evidence.json"
            evidence.parent.mkdir(parents=True)
            evidence.write_text(json.dumps(expected))
            (out / "stockgraph-evidence.json").write_text(json.dumps(expected))
            (out / "Android.mk").write_text(graph.android_make({}))
            (out / "Android.bp").write_text(graph.android_blueprint(providers))
            (out / "u20-stockgraph-vendor.mk").write_text(graph.vendor_product({}))
            (out / "BoardConfigVendor.mk").write_text("# U20 stockgraph vendor: architecture/layout live in the device tree.\n")
            with patch.object(graph, "REPO", root):
                graph.verify_prepared(out)
                (out / "Android.bp").write_text("stub provider")
                with self.assertRaisesRegex(ValueError, "declaration changed"):
                    graph.verify_prepared(out)
                (out / "Android.bp").write_text(graph.android_blueprint(providers))
                (out / "proprietary/lib/libnvram.so").write_bytes(b"other board")
                with self.assertRaisesRegex(ValueError, "Soong input changed"):
                    graph.verify_prepared(out)
