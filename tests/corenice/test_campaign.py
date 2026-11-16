"""Generator diversity, observed-path and coverage denominator regressions."""

import hashlib
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
import corenice_campaign as campaign
from corenice_generate import FEATURES, TEMPLATES, generate


class CampaignTests(unittest.TestCase):
    def test_frozen_seed_is_reproducible_and_programs_are_distinct(self):
        first = generate(1701, 0)
        self.assertEqual(first, generate(1701, 0))
        self.assertEqual(hashlib.sha256(first.source.encode()).hexdigest(),
                         "d449aa7719a1c72c8c03f11c43a44be9f1467624c355535e8fc4d725eedb14dd")
        sources, templates = set(), set()
        for ordinal in range(1000):
            seed = [1701, 2718, 31415, 65537][ordinal % 4]
            program = generate(seed, ordinal // 4)
            sources.add(program.source.split("\n", 1)[1])
            templates.add(program.template)
        self.assertEqual(len(sources), 1000)
        self.assertEqual(templates, set(TEMPLATES))

    def test_actual_prefix_alternatives(self):
        first = {"indices": [0, 2], "arities": [2, 3]}
        self.assertEqual(campaign.next_prefix(first, 0), [])
        self.assertEqual(campaign.next_prefix(first, 1), [1])
        self.assertEqual(campaign.next_prefix(first, 2), [0, 0])
        self.assertIsNone(campaign.next_prefix(first, 3))

    def test_observed_effects_required_for_generated_features(self):
        summary = {"observed_tags": {"driver:load": 1, "driver:store": 1,
                                   "memory:access_receipt": 2, "driver:function_return": 2}}
        self.assertEqual(campaign.executed_features(generate(1701, 0), summary), FEATURES)
        for tag in list(summary["observed_tags"]):
            changed = {"observed_tags": dict(summary["observed_tags"])}
            del changed["observed_tags"][tag]
            with self.assertRaises(campaign.diff.Incomplete):
                campaign.executed_features(generate(1701, 0), changed)

    def test_failures_and_denominator_shortfalls_never_pass(self):
        config = campaign.initial_config("pilot")
        report = {"defined_programs": 100, "features": {feature: 100 for feature in FEATURES},
                  "nd_programs_with_two_tapes": 100, "failures": [],
                  "unattempted_programs": 0, "path_classes": {"defined": 200}}
        self.assertFalse(campaign.acceptance(report, config))
        for name, value in [("defined_programs", 99), ("nd_programs_with_two_tapes", 99),
                            ("features", {}), ("failures", [{"kind": "mismatch"}]),
                            ("unattempted_programs", 1), ("path_classes", {"model-error": 1})]:
            self.assertTrue(campaign.acceptance(dict(report, **{name: value}), config), name)

    def test_nondefined_and_incomplete_runs_keep_compact_recipes(self):
        summary = {"kind": "undefined", "both_directions": True,
                   "indices": [0], "arities": [2], "choice_kinds": ["nd"],
                   "observed_tags": {}, "outcome_sha256": "outcome", "tape_sha256": "tape"}
        config = campaign.initial_config("smoke")
        config.update(programs=1, targets={"defined_programs": 1, "per_feature": 1,
                                         "nd_programs_with_two_tapes": 1})
        with tempfile.TemporaryDirectory() as directory:
            binary = Path(directory) / "binary"
            binary.write_text("test binary")
            options = SimpleNamespace(core_bin=binary, corenice_bin=binary, producer=binary,
                                      runtime=Path(directory))
            failure = campaign.diff.Incomplete("test resource failure")
            failure.category = "resource"
            with patch.object(campaign.diff, "compare_case", side_effect=[summary, failure]):
                report = campaign.run_campaign(config, options)
        self.assertFalse(report["accepted"])
        self.assertEqual(report["defined_programs"], 0)
        self.assertEqual(report["nondefined_cases"], [{"seed": 1701, "index": 0,
            "choices": [], "kind": "undefined", "outcome_sha256": "outcome"}])
        self.assertEqual(report["failure_classes"], {"resource": 1})
        self.assertEqual(report["failures"][0]["choices"], [1])


if __name__ == "__main__":
    unittest.main()
