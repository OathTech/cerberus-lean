"""Focused protocol and resource controls for the Core/CoreB orchestrator."""

import copy
import importlib.util
import json
from pathlib import Path
import sys
import tempfile
import time
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("coreb_diff", ROOT / "scripts/coreb-diff.py")
diff = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = diff
spec.loader.exec_module(diff)


def rows(origin="Core"):
    return [
        {"record": "header", "header": {"version": 1, "input": "source", "prepared": "ail",
            "config": {"fuel": 100}, "coreBuild": "A", "coreBBuild": "B", "origin": origin}},
        {"record": "event", "event": {"channel": "memory", "address": 9, "stored": 7}},
        {"record": "choice", "choice": {"ordinal": 0, "kind": "nd", "parent": "parent",
            "alternatives": ["same", "same"], "index": 1}},
        {"record": "outcome", "outcome": {"kind": "defined", "result": {"value": 0, "stdout": "", "stderr": ""}}},
        {"record": "end", "complete": True, "kind": "defined", "visited": 2, "choices": 1},
    ]


def encoded(records):
    return ("\n".join(json.dumps(row) for row in records) + "\n").encode()


class ComparisonTests(unittest.TestCase):
    def test_origin_is_the_only_header_erasure(self):
        left, right = rows(), rows("CoreB")
        diff.compare(diff.parse_trace(encoded(left)), diff.parse_trace(encoded(right)), "paired")
        right[0]["header"]["config"]["fuel"] = 99
        with self.assertRaises(diff.Mismatch):
            diff.compare(diff.parse_trace(encoded(left)), diff.parse_trace(encoded(right)), "config")

    def test_changed_effect_same_result(self):
        left, right = rows(), rows("CoreB")
        right[1]["event"]["stored"] = 8
        self.assertEqual(left[3], right[3])
        with self.assertRaises(diff.Mismatch):
            diff.compare(diff.parse_trace(encoded(left)), diff.parse_trace(encoded(right)), "effect")

    def test_choices_and_terminal_counts_are_compared(self):
        for record, field, changed in [(2, "index", 0), (4, "visited", 3)]:
            left, right = rows(), rows("CoreB")
            target = right[record]["choice"] if record == 2 else right[record]
            target[field] = changed
            with self.assertRaises(diff.Mismatch):
                diff.compare(diff.parse_trace(encoded(left)), diff.parse_trace(encoded(right)), "choice/count")

    def test_missing_duplicate_incomplete_and_malformed(self):
        incomplete = rows()
        incomplete[-1]["complete"] = False
        bad_count = rows()
        bad_count[-1]["choices"] = 0
        duplicate = rows()
        duplicate.insert(-1, copy.deepcopy(duplicate[-2]))
        for records in [rows()[:-1], incomplete, bad_count, duplicate]:
            with self.assertRaises(diff.Incomplete):
                diff.parse_trace(encoded(records))
        for data in [b"", b"{broken\n", b'{"record":"end","record":"header"}\n', b'{"record":NaN}\n']:
            with self.assertRaises(diff.Incomplete):
                diff.parse_trace(data)

    def test_valid_tape_replay_refusal_is_a_mismatch(self):
        replay = rows("CoreB")
        replay[-2]["outcome"] = {"kind": "replay-mismatch", "reason": "different choices"}
        replay[-1].update(complete=False, kind=None)
        with self.assertRaises(diff.Mismatch):
            diff.parse_trace(encoded(replay), replay=True)

    def test_json_type_and_precision_are_not_lost(self):
        self.assertNotEqual(diff.structural(True), diff.structural(1))
        self.assertNotEqual(diff.structural(diff.decode("9007199254740993.1")),
                            diff.structural(diff.decode("9007199254740993.2")))

    def test_owned_child_limits(self):
        code, out, err = diff.run_child([sys.executable, "-c", "print('bounded')"], 5, 64 * 1024**2, 1024)
        self.assertEqual((code, out, err), (0, b"bounded\n", b""))
        with self.assertRaises(diff.Incomplete):
            diff.run_child([sys.executable, "-c", "import time; time.sleep(10)"], 0.1, 64 * 1024**2, 1024)
        with self.assertRaises(diff.Incomplete):
            diff.run_child([sys.executable, "-c", "print('x'*1000000)"], 5, 64 * 1024**2, 128)
        code, _, _ = diff.run_child([sys.executable, "-c", "x=bytearray(128*1024**2)"], 5, 64 * 1024**2, 4096)
        self.assertNotEqual(code, 0)

    def test_exited_leader_descendant_is_stopped(self):
        with tempfile.TemporaryDirectory(prefix="coreb-child-test-") as scratch:
            marker = Path(scratch) / "escaped"
            child = f"import time,pathlib; time.sleep(1); pathlib.Path({str(marker)!r}).write_text('escaped')"
            leader = f"import os,subprocess,sys; subprocess.Popen([sys.executable,'-c',{child!r}]); os._exit(0)"
            with self.assertRaises(diff.Incomplete):
                diff.run_child([sys.executable, "-c", leader], 0.5, 64 * 1024**2, 4096)
            time.sleep(0.8)
            self.assertFalse(marker.exists(), "a descendant survived the owned process-group timeout")


if __name__ == "__main__":
    unittest.main()
