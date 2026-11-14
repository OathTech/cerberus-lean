"""The packaging boundary must preserve declaration bodies and diagnostics."""

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location("generate_coreb", ROOT / "tools/generate_coreb.py")
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class PackagingTests(unittest.TestCase):
    def test_imports_only(self):
        header = "/- example: /- nested -/\nimport Core\n-/\nimport Core\nimport LemLib"
        body = '\n\nnamespace Helper\ndef message := "Core\\nimport Core"\nend Helper\n'
        expected_header = header.replace("-/\nimport Core\nimport LemLib", "-/\nimport CoreB.Core\nimport LemLib")
        self.assertEqual(
            module.package(header + body, {"Core"}),
            expected_header + "\n\nnamespace CoreB\n" + body + "\nend CoreB\n",
        )

    def test_body_is_not_scanned(self):
        body = '\n/- A body comment:\nimport Core\n-/\ndef message := "unchanged"\n'
        self.assertEqual(
            module.package("import Core" + body, {"Core"}),
            "import CoreB.Core\n\nnamespace CoreB\n" + body + "\nend CoreB\n",
        )

    def test_bad_header_refuses(self):
        for text in ["def x := 0\n", "/- unterminated\nimport Core\n"]:
            with self.assertRaises(ValueError):
                module.package(text, {"Core"})


if __name__ == "__main__":
    unittest.main()
