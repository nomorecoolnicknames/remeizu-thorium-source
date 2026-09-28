"""Pinned upstream menu fixture: explicit offline mode must never call curl."""
import hashlib
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
PATCH = ROOT / "planning/los16-stock/patches/0003-vendorsetup-offline-snapshot.patch"
FIXTURE = ROOT / "tests/fixtures/lineage_vendorsetup.sh"
BEFORE = "91e7ac5ff22267b43156a7a988f455a74a7cbd29313a0c2a501c33c03bfe3993"
AFTER = "326af9e01f62ebd20d30256bb89fb34e49ff47e434b346916239460c6b8498a5"


class OfflineVendorSetupTest(unittest.TestCase):
    def run_menu(self, flag, patched=True):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = root / "vendor/lineage/vendorsetup.sh"
            source.parent.mkdir(parents=True)
            content = FIXTURE.read_bytes()
            self.assertEqual(hashlib.sha256(content).hexdigest(), BEFORE)
            source.write_bytes(content)
            if patched:
                subprocess.run(["patch", "--batch", "--forward", "-p1", "-i", str(PATCH)],
                               cwd=root, check=True, capture_output=True, text=True)
                self.assertEqual(hashlib.sha256(source.read_bytes()).hexdigest(), AFTER)
            subprocess.run(["bash", "-n", str(source)], check=True)
            command = '''
set -eo pipefail
curl() {
    echo invoked >> "$TEST_CURL_LOG"
    printf 'testboard userdebug lineage-16.0\notherboard eng lineage-15.1\n'
}
add_lunch_combo() { echo "$1" >> "$TEST_COMBO_LOG"; }
source "$1"
'''
            env = dict(os.environ, TEST_CURL_LOG=str(root / "curl.log"),
                       TEST_COMBO_LOG=str(root / "combos.log"))
            env.pop("FORGE_OFFLINE_SOURCE_SNAPSHOT", None)
            if flag is not None:
                env["FORGE_OFFLINE_SOURCE_SNAPSHOT"] = flag
            result = subprocess.run(["bash", "--noprofile", "--norc", "-c", command, "bash", str(source)],
                                    cwd=root, env=env, capture_output=True, text=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            return (root / "curl.log").exists(), (root / "combos.log").read_text().splitlines()

    def test_explicit_offline_mode_skips_remote_menu_and_keeps_generic_choices(self):
        called, combos = self.run_menu("1")
        self.assertFalse(called)
        self.assertEqual(combos, ["lineage_arm-userdebug", "lineage_arm64-userdebug",
                                  "lineage_x86-userdebug", "lineage_x86_64-userdebug"])

    def test_unset_empty_and_other_values_preserve_original_behavior(self):
        original = self.run_menu(None, patched=False)
        self.assertTrue(original[0])
        self.assertIn("lineage_testboard-userdebug", original[1])
        for flag in (None, "", "0", "true"):
            with self.subTest(flag=flag):
                self.assertEqual(self.run_menu(flag), original)


if __name__ == "__main__":
    unittest.main()
