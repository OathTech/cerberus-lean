#!/usr/bin/env python3
"""Adversaries for the lexical inventory; not proofs about Lean evaluation."""
from pathlib import Path
import tempfile
import unittest

from failure_census import assign_dependencies, census, strip_comments


class CensusTests(unittest.TestCase):
    def read(self, source):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            p = root/'generated/Probe.lean'
            p.parent.mkdir()
            p.write_text(source)
            return census(p, root)

    def test_nested_comments_strings_and_quote_char_do_not_hide_real_site(self):
        rows = self.read('''/- fake failwithI /- panic! -/ -/
def probe (n : Nat) : Nat :=
  let c := '"'
  let s := "failwithI: panic!"
  /- another fake panic! -/
  failwithI "actual"
''')
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['line'], 6)
        self.assertEqual(rows[0]['definition'], 'probe')

    def test_computed_message_and_state_function_ascription_are_inventoried(self):
        rows = self.read('''namespace N
def f (s : String) := (failwithI (String.append "prefix: " s) : st → exceptM (t0 Nat × st) err)
end N
def g := (failwithI "second" : Nat)
''')
        self.assertEqual([r['definition'] for r in rows], ['N.f', 'g'])
        self.assertEqual(rows[0]['group'], 'monadic_ascribed')
        self.assertEqual(rows[0]['channel'], 'undefined_Error_loc')
        self.assertEqual(rows[1]['group'], 'pure_or_unresolved')

    def test_unterminated_comment_and_string_refuse(self):
        for source in ('/- missing', 'def f := "missing'):
            with self.assertRaises(ValueError): strip_comments(source)

    def test_unused_anonymous_instance_does_not_inherit_named_exec_dependency(self):
        rows = self.read('''def used := (failwithI "used" : Nat)
instance (priority := low) : BEq Nat where
  beq := fun _ _ => failwithI "unused"
''')
        self.assertIn('<anonymous declaration>', rows[1]['definition'])
        # Include the old bad lexical hint deliberately: the range must win.
        rows[1]['definition'] = 'used'
        reach = {'used': {'exec_dependency': True, 'frontend_dependency': True},
                 'instBEqNat': {'exec_dependency': False, 'frontend_dependency': False}}
        ranges = {'Probe': [('used', 'Probe.lean', (1, 0), (1, 40)),
                            ('instBEqNat', 'Probe.lean', (2, 0), (4, 0))]}
        assign_dependencies(rows, reach, ranges)
        self.assertEqual([r['definition'] for r in rows], ['used', 'instBEqNat'])
        self.assertEqual([r['exec_dependency'] for r in rows], [True, False])

    def test_smallest_range_and_ambiguity_are_explicit(self):
        reach = {n: {'exec_dependency': True, 'frontend_dependency': False} for n in ['outer', 'inner', 'ambiguous']}
        def row(): return {'file': 'generated/Probe.lean', 'line': 3, 'column': 5, 'definition': 'outer'}
        ranges = [('outer', '', (1, 0), (5, 0)), ('inner', '', (2, 0), (4, 0))]
        r = row(); assign_dependencies([r], reach, {'Probe': ranges})
        self.assertEqual(r['kernel_names'], ['inner'])
        r = row(); assign_dependencies([r], reach, {'Probe': ranges+[('ambiguous', '', (2, 0), (4, 0))]})
        self.assertEqual(r['dependency_status'], 'range_multiple')
        self.assertNotIn('exec_dependency', r)
        r = row(); assign_dependencies([r], reach, {})
        self.assertEqual(r['dependency_status'], 'unresolved_range_or_import')
        self.assertNotIn('exec_dependency', r)


if __name__ == '__main__': unittest.main(verbosity=2)
