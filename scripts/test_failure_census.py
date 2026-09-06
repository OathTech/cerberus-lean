#!/usr/bin/env python3
"""Adversaries for the lexical inventory; not proofs about Lean evaluation."""
from pathlib import Path
import tempfile
import unittest

from failure_census import census, strip_comments


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


if __name__ == '__main__': unittest.main(verbosity=2)
