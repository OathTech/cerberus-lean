"""The packaging boundary must preserve declaration bodies and diagnostics."""

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("generate_corenice", ROOT / "tools/generate_corenice.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PackagingTests(unittest.TestCase):
    def test_imports_only(self):
        header = "/- example: /- nested -/\nimport Core\n-/\nimport Core\nimport LemLib"
        body = '\n\nnamespace Helper\ndef message := "Core\\nimport Core"\nend Helper\n'
        expected_header = header.replace("-/\nimport Core\nimport LemLib", "-/\nimport CoreNice.Core\nimport LemLib")
        self.assertEqual(
            module.package(header + body, {"Core"}),
            expected_header + "\n\nnamespace CoreNice\n" + body + "\nend CoreNice\n",
        )

    def test_body_is_not_scanned(self):
        body = '\n/- A body comment:\nimport Core\n-/\ndef message := "unchanged"\n'
        self.assertEqual(
            module.package("import Core" + body, {"Core"}),
            "import CoreNice.Core\n\nnamespace CoreNice\n" + body + "\nend CoreNice\n",
        )

    def test_bad_header_refuses(self):
        for text in ["def x := 0\n", "/- unterminated\nimport Core\n"]:
            with self.assertRaises(ValueError):
                module.package(text, {"Core"})

    def test_original_core_run_import_fix(self):
        source = 'import Operators\nimport Core\ndef text := "import Operators"\n'
        self.assertEqual(module.original_postprocess("Core_run.lean", source),
                         'import Core\ndef text := "import Operators"\n')
        self.assertEqual(module.original_postprocess("Core.lean", source), source)

    def test_local_open_keeps_comments_and_strings(self):
        text = 'open Operators\n/- /- nested -/\nopen Operators\n-/\ndef s := "\nopen Operators\n"\nopen Operators\n'
        expected = text.replace('open Operators\n/-', 'open _root_.CoreNice.Operators\n/-', 1)
        expected = expected[:-len('open Operators\n')] + 'open _root_.CoreNice.Operators\n'
        self.assertEqual(module.qualify_open(text, "Operators"), expected)


if __name__ == "__main__":
    unittest.main()
