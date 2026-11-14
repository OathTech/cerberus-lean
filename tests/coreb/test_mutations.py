"""Fast controls for source patching, cache isolation and result classification."""
import importlib.util
from pathlib import Path
import sys
import tempfile
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("coreb_mutations_tested", ROOT / "scripts/coreb-mutations.py")
M = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = M
SPEC.loader.exec_module(M)


def shape(value):
    if isinstance(value, dict):
        return tuple(sorted((key, shape(item)) for key, item in value.items()))
    if isinstance(value, list):
        return tuple(map(shape, value))
    return value


def trace(value=0, stores=(9,), choices=()):
    return SimpleNamespace(outcome={"kind": "defined", "value": value}, choices=list(choices),
        events=[{"boundary": 0, "observation": {"channel": "driver", "events":
            [{"tag": "store", "value": item} for item in stores]}}])


class MutationControls(unittest.TestCase):
    def test_each_patch_changes_only_its_owned_file(self):
        for name, mutation in M.MUTATIONS.items():
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                path = root / mutation.path
                path.parent.mkdir(parents=True)
                path.write_text("before\n" + mutation.old + "\nafter\n")
                untouched = root / "original-core.txt"
                untouched.write_text("original")
                M.apply_mutation(root, mutation)
                self.assertEqual(path.read_text(), "before\n" + mutation.new + "\nafter\n")
                self.assertEqual(untouched.read_text(), "original")

    def test_missing_or_ambiguous_patch_fails(self):
        mutation = M.MUTATIONS["arithmetic"]
        for text in ["unrelated", mutation.old + mutation.old]:
            with tempfile.TemporaryDirectory() as directory:
                path = Path(directory) / mutation.path
                path.parent.mkdir(parents=True)
                path.write_text(text)
                with self.assertRaises(RuntimeError):
                    M.apply_mutation(Path(directory), mutation)
                self.assertEqual(path.read_text(), text)

    def test_build_or_generic_failure_is_not_detection(self):
        mutation = M.MUTATIONS["arithmetic"]
        self.assertFalse(M.detected(mutation, 1, "", "compiler failed"))
        self.assertFalse(M.detected(mutation, 2, "", "INCOMPLETE: timeout"))
        self.assertTrue(M.detected(mutation, 1, "", "MISMATCH: events differ"))

    def test_panic_requires_actual_marker(self):
        mutation = M.MUTATIONS["panic"]
        self.assertFalse(M.detected(mutation, 2, "", "INCOMPLETE: missing binary"))
        self.assertTrue(M.detected(mutation, 2, "", "INCOMPLETE: injected CoreB mutation panic"))
        self.assertFalse(M.detected(mutation, 0, "", "INCOMPLETE: injected CoreB mutation panic"))

    def test_arithmetic_requires_changed_store_and_equal_outcome(self):
        M.verify_witness("arithmetic", trace(stores=(9,)), trace(stores=(5,)), shape)
        with self.assertRaises(RuntimeError):
            M.verify_witness("arithmetic", trace(), trace(value=1, stores=(5,)), shape)
        with self.assertRaises(RuntimeError):
            M.verify_witness("arithmetic", trace(), trace(), shape)

    def test_observer_requires_equal_outcome_and_event_loss(self):
        M.verify_witness("observer", trace(), trace(stores=()), shape)
        with self.assertRaises(RuntimeError):
            M.verify_witness("observer", trace(), trace(value=1, stores=()), shape)

    def test_order_requires_duplicate_descriptors_and_changed_result(self):
        duplicates = [{"alternatives": ["same", "same"]}]
        M.verify_witness("choice-order", trace(choices=duplicates), trace(value=1), shape)
        with self.assertRaises(RuntimeError):
            M.verify_witness("choice-order", trace(choices=[{"alternatives": ["x", "y"]}]), trace(value=1), shape)

    def test_semantic_mutants_refuse_nondefined_outcome(self):
        bad = trace()
        bad.outcome = {"kind": "undefined"}
        with self.assertRaises(RuntimeError):
            M.verify_witness("arithmetic", trace(), bad, shape)

    def test_copied_pinned_compiler_precedes_inherited_switch(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            package = root / "lean_frontend/.lake/packages/LemLib"
            (package / "bin").mkdir(parents=True)
            (package / "bin/lem").write_text("pinned compiler")
            env = M.build_environment(root, "12G")
            self.assertEqual(env["PATH"].split(":")[0], str(package / "bin"))
            self.assertEqual(env["LEMLIB"], str(package / "library"))
            self.assertEqual(env["CERB_MEM_MAX"], "12G")

    def test_warm_cache_is_physically_independent(self):
        with tempfile.TemporaryDirectory() as directory:
            source, destination = Path(directory) / "source", Path(directory) / "destination"
            cache = source / "lean_frontend/.lake"
            cache.mkdir(parents=True)
            (cache / "object").write_text("original")
            (cache / "link").symlink_to("object")
            (source / "lean_frontend/generated").mkdir()
            (source / "lean_frontend/native").mkdir()
            (source / "lean_frontend/native/md5.o").write_text("object")
            M.copy_warm(source, destination)
            copied = destination / "lean_frontend/.lake/link"
            self.assertFalse(copied.is_symlink())
            copied.write_text("changed")
            self.assertEqual((cache / "object").read_text(), "original")
            self.assertNotEqual(copied.stat().st_ino, (cache / "object").stat().st_ino)


if __name__ == "__main__":
    unittest.main()
