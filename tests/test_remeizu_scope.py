import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

SPEC = importlib.util.spec_from_file_location("remeizu_scope", Path(__file__).resolve().parents[1] / "tools/remeizu_scope.py")
scope = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(scope)


class ScopeTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="remeizu-scope-")
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.roots = {key: self.root / key for key in ("thorium", "fleet", "site", "build_station")}
        for path in self.roots.values():
            path.mkdir()
        self.put("thorium", "plan.md", "planning only")
        self.put("thorium", "sources.json", {"required_external_boards": ["board15", "board16"]})
        self.put("thorium", "inventory.json", {"devices": {"board" + str(i): {} for i in range(10)}})
        self.put("site", "catalog.html", "\n".join(f"name: 'Phone {i}', codename: 'board{i}', s: 'planned'," for i in range(15)))
        self.put("fleet", "runtime.json", {"devices": {"board" + str(i): {} for i in range(8)}})
        boards = []
        for i in range(17):
            ident = "board" + str(i)
            refs = []
            for version, sdk in scope.SDK.items():
                if i >= 7:
                    break
                relative = f"targets/android/{ident}-a{version}.json"
                self.put("fleet", relative, {"target_id": f"{ident}-a{version}", "device": ident,
                                            "android_version": version, "sdk": sdk})
                refs.append(relative)
            board = {"id": ident, "name": f"Phone {i}", "aliases": [ident.upper()],
                     "family": "family", "soc": "mt6753",
                     "scope": "active" if i < 7 else "external" if i >= 15 else "planned",
                     "android_targets": refs, "evidence_refs": [], "next_gate": "Identify board and recovery",
                     "notes": ["/home/private/private_serial"]}
            if i < 15:
                board["site_card"] = ident
            if i < 10:
                board["thorium_key"] = ident
            boards.append(board)
        self.registry = {"schema_version": "remeizu.planning.v1",
                         "roots": {key: str(value) for key, value in self.roots.items()},
                         "source_paths": {"scope_snapshot": "sources.json",
                                          "thorium_inventory": "inventory.json", "site_catalog": "catalog.html",
                                          "runtime_profiles": "runtime.json"},
                         "families": {"family": {"label": "Family", "android_goals": [9, 11, 13],
                             "android_plan": {"root": "thorium", "path": "plan.md"},
                             "mainline_plan": {"root": "thorium", "path": "plan.md"}}},
                         "boards": boards}

    def put(self, root, path, value):
        target = self.roots[root] / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(json.dumps(value) if isinstance(value, dict) else value)

    def errors(self):
        return scope.check(self.registry)["errors"]

    def test_valid_coverage_and_same_board_case_aliases(self):
        report = scope.check(self.registry)
        self.assertEqual(report["errors"], [])
        self.assertEqual(report["coverage"]["android_targets"]["found"], 21)
        self.assertFalse(report["runtime_verified"])
        self.assertFalse(report["build_verified"])

    def test_alias_collision_between_boards_blocks(self):
        self.registry["boards"][1]["aliases"].append("BOARD0")
        self.assertTrue(any("ambiguous alias" in error for error in self.errors()))

    def test_site_omission_blocks(self):
        del self.registry["boards"][14]["site_card"]
        self.assertIn("site: uncovered board14", self.errors())

    def test_runtime_omission_blocks(self):
        self.put("fleet", "runtime.json", {"devices": {**{"board" + str(i): {} for i in range(7)}, "unmapped": {}}})
        self.assertIn("runtime: unresolved unmapped", self.errors())

    def test_target_omission_blocks(self):
        removed = self.registry["boards"][0]["android_targets"].pop()
        self.assertIn("android_targets: uncovered " + removed, self.errors())

    def test_cross_board_target_and_card_mapping_block(self):
        left, right = self.registry["boards"][:2]
        left["android_targets"], right["android_targets"] = right["android_targets"], left["android_targets"]
        left["site_card"], right["site_card"] = right["site_card"], left["site_card"]
        errors = self.errors()
        self.assertTrue(any("cross-board Android target" in error for error in errors))
        self.assertTrue(any("cross-board site_card" in error for error in errors))

    def test_public_projection_omits_private_sources_notes_and_unknown_fields(self):
        self.registry["boards"][0]["serial"] = "private_serial"
        projected = scope.public_projection(self.registry)
        text = json.dumps(projected)
        for secret in ("private_serial", "/home/", str(self.root), "evidence_refs", "source_paths", "android_targets"):
            self.assertNotIn(secret, text)
        expected = {"id", "name", "aliases", "family", "soc", "next_gate", "android_goals", "planning_status"}
        self.assertEqual(set(projected["boards"][0]), expected)

    def test_public_prose_cannot_carry_host_paths(self):
        self.registry["boards"][0]["next_gate"] = "Read /srv/private/dump"
        with self.assertRaisesRegex(ValueError, "local path"):
            scope.public_projection(self.registry)

    def test_public_path_detection_is_generic_and_preserves_urls_and_slash_words(self):
        for path in ("/var/lib/remeizu/captures", "/opt/private", "C:\\private\\dump",
                     "C:/private/dump", "\\\\server\\private", "//server/private"):
            with self.subTest(path=path):
                self.registry["boards"][0]["next_gate"] = "Read (" + path + ")"
                with self.assertRaisesRegex(ValueError, "local path"):
                    scope.public_projection(self.registry)
        prose = "Review https://example.org/ports/board and A9/A11/A13 / panel/touch"
        self.registry["boards"][0]["next_gate"] = prose
        self.assertEqual(scope.public_projection(self.registry)["boards"][0]["next_gate"], prose)

    def test_external_board_omission_or_wrong_scope_blocks_even_outside_inventory(self):
        self.registry["boards"].pop()
        self.assertIn("external_boards: uncovered board16", self.errors())
        self.registry["boards"][15]["scope"] = "candidate"
        self.assertIn("board15: required external board must retain external scope", self.errors())

    def test_planned_board_does_not_create_build_target(self):
        before = sorted((self.roots["fleet"] / "targets/android").iterdir())
        self.assertEqual(self.errors(), [])
        projection = scope.public_projection(self.registry)
        planned = projection["boards"][14]
        self.assertEqual(planned["planning_status"], "planned")
        self.assertEqual(planned["android_goals"], [9, 11, 13])
        self.assertEqual(self.registry["boards"][14]["android_targets"], [])
        self.assertEqual(before, sorted((self.roots["fleet"] / "targets/android").iterdir()))

    def test_raw_card_count_and_inventory_coverage_are_independent(self):
        self.put("site", "catalog.html", "name: 'Phone', codename: 'board0',")
        self.registry["boards"][9].pop("thorium_key")
        errors = self.errors()
        self.assertIn("site: expected 15, found 1", errors)
        self.assertIn("thorium: uncovered board9", errors)

    def test_bad_target_version_and_missing_plan_block(self):
        self.put("fleet", "targets/android/board0-a9.json",
                 {"target_id": "board0-a9", "device": "board0", "android_version": 13, "sdk": 33})
        self.registry["families"]["family"]["mainline_plan"]["path"] = "missing.md"
        errors = self.errors()
        self.assertTrue(any("missing reference" in error for error in errors))
        self.assertTrue(any("inconsistent Android target identity" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
