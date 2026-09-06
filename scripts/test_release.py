#!/usr/bin/env python3
"""Test membership interpretation and actual fail-closed runner processes."""

from contextlib import redirect_stdout
import io
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import release


class ReleaseTests(unittest.TestCase):
    def test_real_membership_expands_every_documented_command(self):
        lanes = release.read_ladder(Path(__file__).with_name('LADDER.md'))
        commands = {lane.id: lane.command for lane in lanes}
        self.assertEqual(commands['A2'], ['./scripts/test_exec.sh', '--check-baseline'])
        self.assertEqual(commands['B6.2'], ['./scripts/test_speclab.sh', '--plant'])
        self.assertEqual(commands['B6.7'], ['./scripts/test_speclab_seed.sh', '--gate'])
        self.assertEqual(commands['B8.3'], ['./scripts/test_fuel_plant.sh'])
        self.assertEqual(commands['C3'], ['./scripts/test_csmith_corpus.sh', '--check-baseline'])
        self.assertEqual(len(commands), len(lanes))

    def test_missing_tier_duplicate_and_bad_command_refuse(self):
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / 'LADDER.md'
            for data in ['## Tier A\n| 1 | `./scripts/a.sh` | gate |\n',
                         '## Tier A\n| 1 | `rm -rf /tmp/a` | gate |\n']:
                path.write_text(data)
                with self.assertRaises(ValueError):
                    release.read_ladder(path)

    def make_fixture(self, base, a='echo PASSED\n', b='echo PASSED\n'):
        root = base / 'repo'
        (root / 'scripts').mkdir(parents=True)
        for name, body in [('a.sh', a), ('b.sh', b), ('c.sh', 'echo REPORTED\n')]:
            path = root / 'scripts' / name
            path.write_text('#!/bin/sh\n' + body)
            path.chmod(0o755)
        (root / 'scripts/LADDER.md').write_text(''.join(
            f'## Tier {tier}\n| {"1 | " if tier != "C" else ""}`./scripts/{tier.lower()}.sh` | bar |\n'
            for tier in 'ABC'))
        (root / 'source').write_text('initial\n')
        subprocess.run(['git', 'init', '-q', str(root)], check=True)
        subprocess.run(['git', '-C', str(root), 'add', '.'], check=True)
        subprocess.run(['git', '-C', str(root), '-c', 'user.name=Runner test',
                        '-c', 'user.email=runner-test@example.invalid', 'commit', '-qm', 'fixture'], check=True)
        return root

    def run_fixture(self, root, out, *flags):
        with patch.object(release, 'ROOT', root), patch.object(release, 'artifacts', return_value={}), \
             patch('sys.argv', ['release.py', '--mode', 'full', '--out', str(out), *flags]), \
             redirect_stdout(io.StringIO()):
            code = release.main()
        return code, json.loads((out / 'report.json').read_text())

    def test_complete_tier_is_distinct_from_release_certification(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base)
            code, report = self.run_fixture(root, base / 'evidence')
            self.assertEqual(code, 0)
            self.assertEqual(report['status'], 'passed')
            self.assertEqual(report['selected'], ['A1', 'B1'])
            self.assertTrue(report['release_certification'].startswith('incomplete:'))
            self.assertEqual([row['id'] for row in report['unrun']], ['C1'])

    def test_failure_after_completion_marker_is_failure(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base, a='echo ALL PASSED\nexit 1\n')
            code, report = self.run_fixture(root, base / 'evidence')
            self.assertNotEqual(code, 0)
            self.assertEqual(report['lanes'][0]['status'], 'failed')
            self.assertEqual(report['lanes'][1]['status'], 'passed')

    def test_missing_command_is_incomplete(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base)
            (root / 'scripts/a.sh').unlink()
            code, report = self.run_fixture(root, base / 'evidence')
            self.assertNotEqual(code, 0)
            self.assertEqual(report['lanes'][0]['status'], 'incomplete')
            self.assertIsNone(report['lanes'][0]['exit_status'])

    def test_timeout_after_completion_marker_is_incomplete(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base, a='echo ALL PASSED\nsleep 10\n')
            code, report = self.run_fixture(root, base / 'evidence', '--lane-timeout', '0.1')
            self.assertNotEqual(code, 0)
            self.assertEqual(report['lanes'][0]['status'], 'incomplete')
            self.assertEqual(report['lanes'][0]['reason'], 'lane timeout')

    def test_source_change_cannot_certify_original_candidate(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base, b='echo changed >> source\necho PASSED\n')
            code, report = self.run_fixture(root, base / 'evidence')
            self.assertNotEqual(code, 0)
            self.assertFalse(report['source_unchanged'])
            self.assertEqual(report['status'], 'incomplete')

    def test_subset_cannot_claim_a_complete_tier(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base)
            code, report = self.run_fixture(root, base / 'evidence', '--lane', 'A1')
            self.assertEqual(code, 0)
            self.assertFalse(report['selection_complete'])
            self.assertEqual(report['status'], 'incomplete')
            self.assertIn('B1', [row['id'] for row in report['unrun']])


if __name__ == '__main__':
    unittest.main(verbosity=2)
