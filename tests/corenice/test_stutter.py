"""Explicit stutter projection retains payload order and genuine choice barriers."""

import copy
import importlib.util
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("corenice_stutter_diff", ROOT / "scripts/corenice-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)


def info(text):
    return {"tag": "tau", "fields": [text]}


def nd(index, kind, alternatives=None, selected=None):
    return {"channel": "nd", "node": index, "kind": kind,
            "parent": None if kind in {"active", "killed"} else info("parent"),
            "alternatives": alternatives or [], "selected": selected}


def effect(boundary, channel, values):
    key = "text" if channel in {"stdout", "stderr"} else "events"
    return {"boundary": boundary, "observation": {"channel": channel, key: values}}


def fixture(split=False):
    first = {"tag": "store", "fields": [0, 0, 0, 0, 0, 11]}
    second = {"tag": "store", "fields": [0, 0, 0, 0, 0, 22]}
    alternatives = [info("left"), info("right")]
    branch = 1 if split else 0
    events = ([effect(0, "driver", [first]), effect(0, "stdout", "X"),
               nd(0, "step", [info("singleton")], 0),
               effect(1, "driver", [second]), effect(1, "stdout", "Y")]
              if split else [effect(0, "driver", [first, second]), effect(0, "stdout", "XY")])
    events.extend([nd(branch, "nd", alternatives, 0),
                   effect(branch + 1, "memory", [{"tag": "access_receipt", "fields": [0] * 9}]),
                   effect(branch + 1, "stdout", "Z"), nd(branch + 1, "active")])
    return diff.Trace(
        {"version": 2, "input": "input", "prepared": "prepared",
         "config": {"fuel": 100, "observationSchema": "boundary-channels-v1"},
         "coreBuild": "A", "coreNiceBuild": "B", "origin": "Core"}, events,
        [{"ordinal": 0, "kind": "nd", "parent": info("parent"), "alternatives": alternatives, "index": 0}],
        {"kind": "defined", "result": {"value": 0, "stdout": "XYZ", "stderr": ""}},
        {"record": "end", "complete": True, "kind": "defined", "visited": branch + 2, "choices": 1})


class StutterTests(unittest.TestCase):
    def test_extra_singleton_and_same_segment_repartition(self):
        left, right = fixture(), fixture(True)
        with self.assertRaises(diff.Mismatch):
            diff.compare(left, right, "exact")
        diff.compare(left, right, "stutter", "stutter")

    def test_store_crossing_genuine_choice_is_not_stutter(self):
        left, right = fixture(), fixture()
        moved = right.events[0]["observation"]["events"].pop()
        right.events.insert(3, effect(1, "driver", [moved]))
        with self.assertRaises(diff.Mismatch):
            diff.compare(left, right, "choice barrier", "stutter")

    def test_changed_store_output_order_outcome_and_header_reject(self):
        def store(trace):
            trace.events[0]["observation"]["events"][0]["fields"][-1] = 99
        def output(trace):
            trace.events[1]["observation"]["text"] = "YX"
        def order(trace):
            trace.events[0]["observation"]["events"].reverse()
        def result(trace):
            trace.outcome["result"]["value"] = 1
        def config(trace):
            trace.header["config"]["fuel"] = 99
        for change in [store, output, order, result, config]:
            right = fixture()
            change(right)
            with self.assertRaises(diff.Mismatch):
                diff.compare(fixture(), right, change.__name__, "stutter")

    def test_changed_branch_metadata_is_preserved(self):
        left, right = fixture(), fixture()
        right.events[2]["alternatives"][0] = info("changed")
        # Fixture shares the alternatives with its tape, keeping the lane
        # internally consistent while changing genuine branch metadata.
        with self.assertRaises(diff.Mismatch):
            diff.compare(left, right, "branch", "stutter")
        right = fixture()
        right.events[2]["selected"] = 1
        with self.assertRaises(diff.ProtocolFailure):
            diff.compare(left, right, "invalid tape agreement", "stutter")

    def test_malformed_counts_boundaries_and_unknown_shapes_refuse(self):
        cases = []
        wrong_count = fixture(); wrong_count.end["visited"] = 3; cases.append(wrong_count)
        wrong_boundary = fixture(); wrong_boundary.events[0]["boundary"] = 1; cases.append(wrong_boundary)
        missing_node = fixture(True); del missing_node.events[2]; cases.append(missing_node)
        unknown_channel = fixture(); unknown_channel.events[0]["observation"]["channel"] = "checkpoint"; cases.append(unknown_channel)
        unknown_tag = fixture(); unknown_tag.events[0]["observation"]["events"][0]["tag"] = "new_store"; cases.append(unknown_tag)
        unknown_field = fixture(); unknown_field.events[2]["surprise"] = 1; cases.append(unknown_field)
        for case in cases:
            with self.assertRaises(diff.ProtocolFailure):
                diff.compare(fixture(), case, "malformed", "stutter")
        incomplete = fixture(); incomplete.end["complete"] = False
        with self.assertRaises(diff.Incomplete):
            diff.compare(incomplete, copy.deepcopy(incomplete), "incomplete", "stutter")

    def test_stderr_excerpt_keeps_panic_cause_and_tail(self):
        data = b"PANIC original cause\n" + b"stack frame\n" * 1000 + b"final signal marker"
        excerpt = diff.stderr_excerpt(data)
        self.assertIn("PANIC original cause", excerpt)
        self.assertIn("final signal marker", excerpt)
        self.assertIn("truncated", excerpt)
        self.assertLessEqual(len(excerpt), 1500)

    def test_future_schema_and_hidden_checkpoint_payload_refuse(self):
        schema = fixture()
        schema.header["config"]["observationSchema"] = "future-schema"
        with self.assertRaises(diff.ProtocolFailure):
            diff.compare(schema, copy.deepcopy(schema), "future schema", "stutter")
        for metadata in [{"tag": "tau", "fields": [{"checkpoint": "pause"}]},
                         {"tag": "action", "fields": [0]},
                         {"tag": "misc", "fields": [1]},
                         {"tag": "misc", "fields": [[1]]}]:
            trace = fixture(True)
            trace.events[2]["parent"] = metadata
            with self.assertRaises(diff.ProtocolFailure):
                diff.compare(trace, copy.deepcopy(trace), "hidden metadata", "stutter")


if __name__ == "__main__":
    unittest.main()
