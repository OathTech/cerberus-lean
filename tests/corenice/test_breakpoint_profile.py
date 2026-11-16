"""Breakpoint erasure preserves effects and genuine choice barriers."""
import copy
import unittest

from test_stutter import diff, fixture


def paused_fixture():
    trace = fixture(True)
    trace.events[2] = {
        "channel": "nd", "node": 0, "kind": "pause", "alternatives": [], "selected": None,
        "parent": {"schema": "corenice-breakpoint-v1", "procedure": "test", "site": 7,
                   "role": "statement-join", "ailOrigin": [1, 0], "location": "test",
                   "thread": 0, "encounter": 1, "phase": "nonmemory",
                   "remainingBudget": 90, "driverSteps": 3}}
    return trace


class BreakpointProfileTests(unittest.TestCase):
    def test_declared_profile_only(self):
        diff.compare(fixture(), paused_fixture(), "pause", "breakpoints")
        with self.assertRaises(diff.ProtocolFailure):
            diff.compare(fixture(), paused_fixture(), "not implicit stutter", "stutter")
        with self.assertRaises(diff.Mismatch):
            diff.compare(fixture(), paused_fixture(), "not exact", "exact")

    def test_effects_remain_observable(self):
        changed = paused_fixture()
        changed.events[0]["observation"]["events"][0]["fields"][-1] = 999
        with self.assertRaises(diff.Mismatch):
            diff.compare(fixture(), changed, "changed effect", "breakpoints")
        moved = paused_fixture()
        effect = moved.events.pop(3)
        effect["boundary"] = 2
        moved.events.insert(-1, effect)
        with self.assertRaises(diff.Mismatch):
            diff.compare(fixture(), moved, "effect moved across choice", "breakpoints")

    def test_invalid_pause_and_incomplete_refuse(self):
        for field, value in [("phase", "restart"), ("encounter", 0), ("site", -1),
                             ("role", "invented"), ("ailOrigin", ["not-an-id"])]:
            trace = copy.deepcopy(paused_fixture())
            trace.events[2]["parent"][field] = value
            with self.assertRaises(diff.ProtocolFailure):
                diff.compare(fixture(), trace, field, "breakpoints")
        trace = paused_fixture()
        trace.end["complete"] = False
        with self.assertRaises(diff.Incomplete):
            diff.compare(fixture(), trace, "incomplete", "breakpoints")


if __name__ == "__main__":
    unittest.main()
