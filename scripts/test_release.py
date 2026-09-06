#!/usr/bin/env python3
"""Test membership interpretation and actual fail-closed runner processes."""

from contextlib import nullcontext, redirect_stdout
import io
import json
import os
import signal
import sys
import time
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import release
from process_scope import destroy


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

    def run_fixture(self, root, out, *flags, real_inventory=False):
        inventory = nullcontext() if real_inventory else patch.object(release, 'artifacts', return_value={})
        with patch.object(release, 'ROOT', root), inventory, \
             patch.object(release, 'external_inputs', return_value={}), \
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


    def test_reporting_discrepancy_preserves_exit_and_requires_complete_rows(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root/'baseline.txt').write_text('# expected report\na.c DIFF\n')
            (root/'stdout').write_text('SUMMARY: total=1 match=0\nBaseline written: report (1 entries)\n')
            self.assertEqual(release.reporting_result(['./scripts/test_exec.sh'], root, 1), 'reported')
            self.assertEqual(release.reporting_result(['./scripts/test_exec.sh'], root, 137), 'failed')
            (root/'baseline.txt').write_text('# incomplete\n')
            self.assertEqual(release.reporting_result(['./scripts/test_exec.sh'], root, 1), 'failed')

    def test_missing_inventory_prevents_success(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base)
            with patch.object(release, 'artifact_issues', return_value=['missing compiler']):
                code, report = self.run_fixture(root, base/'evidence')
            self.assertNotEqual(code, 0)
            self.assertNotEqual(report['status'], 'passed')

    def test_actual_inventory_rejects_lost_files_and_required_roots(self):
        for removal in ('', 'rm -rf _build/install/default/lib/cerberus/runtime lean_frontend/native',
                        'rm _build/install/default/lib/cerberus-lib/resource'):
            with self.subTest(removal=removal), tempfile.TemporaryDirectory() as tmp:
                base = Path(tmp)
                root = self.make_fixture(base, b=(removal+'\n' if removal else '')+'echo PASSED\n')
                (root/'.gitignore').write_text('/_build/\n/lean_frontend/\n/ocaml_frontend/\n/driver_fresh*\n')
                subprocess.run(['git', '-C', str(root), 'add', '.gitignore'], check=True)
                subprocess.run(['git', '-C', str(root), '-c', 'user.name=Runner test',
                                '-c', 'user.email=runner-test@example.invalid', 'commit', '-qm', 'ignore fixture products'], check=True)
                for name in [*release.REQUIRED_ARTIFACTS, '_build/install/default/lib/cerberus-lib/resource']:
                    path = root/name; path.parent.mkdir(parents=True, exist_ok=True); path.write_text('fixture artifact\n')
                (root/'lean_frontend/.lake/packages/LemLib').mkdir(parents=True)
                bins = base/'bin'; bins.mkdir()
                for name in ('lem', 'ocamlc', 'dune', 'gcc', 'lean', 'elan'):
                    tool = bins/name
                    tool.write_text('#!/bin/sh\n'+('echo "'+str(bins/'lean')+'"' if name == 'elan' else 'echo fixture-version')+'\n')
                    tool.chmod(0o755)
                with patch.dict(os.environ, PATH=str(bins)+os.pathsep+os.environ['PATH']):
                    code, report = self.run_fixture(root, base/'evidence', real_inventory=True)
                self.assertTrue(report['source_unchanged'])
                self.assertEqual(code, int(bool(removal)))
                self.assertEqual(report['status'], 'failed' if removal else 'passed')
                if removal:
                    self.assertTrue(report['artifact_issues'])
                    self.assertTrue(any('lost inventory entry:' in s or s.endswith('md5.o') for s in report['artifact_issues']))

    def test_nested_timeout_and_capped_descendants_are_cleaned(self):
        cap = Path(release.__file__).with_name('capped')
        for capped in (False, True):
            with self.subTest(capped=capped), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                pidfile = root/'child.pid'
                nested = ['sh', '-c', 'echo $$ > "$1"; exec sleep 30', 'owned-child', str(pidfile)]
                if capped:
                    nested = ['env', 'CERB_MEM_MAX=128M', str(cap), *nested]
                lane = release.Lane('A1', 'A', ['timeout', '30', *nested])
                result = release.execute_lane(lane, root, 0.5, root=root)
                self.assertTrue(pidfile.exists(), (root/'A1/stderr').read_text())
                self.assertEqual(result['status'], 'incomplete')
                self.assertTrue(result['containment_cleaned'])
                self.assertFalse(Path(result['cgroup']).exists())
                pid = int(pidfile.read_text())
                stat = Path(f'/proc/{pid}/stat')
                self.assertTrue(not stat.exists() or stat.read_text().split(') ')[1].split()[0] in ('Z', 'X'))

    def test_successful_leader_cannot_leave_background_work(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            lane = release.Lane('A1', 'A', ['sh', '-c', 'sleep 30 & echo $! > child.pid; echo ALL-PASSED'])
            result = release.execute_lane(lane, root, 10, root=root)
            self.assertEqual(result['exit_status'], 0)
            self.assertEqual(result['status'], 'incomplete')
            self.assertEqual(result['reason'], 'command exited with live descendants')
            self.assertTrue(result['containment_cleaned'])
            self.assertFalse(Path(result['cgroup']).exists())

    def test_interrupt_during_cleanup_is_not_lost(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            marker = base/'second-started'
            root = self.make_fixture(base, b=f"touch '{marker}'\n")
            sent = False
            def interrupt_then_destroy(scope):
                nonlocal sent
                if not sent:
                    sent = True
                    # Deliver a real signal exactly while the normal cleanup
                    # is active. Only this trigger is substituted; actual
                    # scope removal, finalization and dispatch are exercised.
                    os.kill(os.getpid(), signal.SIGTERM)
                destroy(scope)
            with patch('process_scope.destroy', side_effect=interrupt_then_destroy):
                code, report = self.run_fixture(root, base/'evidence')
            self.assertEqual(code, 1)
            self.assertEqual(report['status'], 'incomplete')
            self.assertEqual(report['interrupted_signal'], signal.SIGTERM)
            self.assertEqual(len(report['lanes']), 1)
            self.assertEqual(report['lanes'][0]['exit_status'], 0)
            self.assertTrue(report['lanes'][0]['containment_cleaned'])
            self.assertFalse(Path(report['lanes'][0]['cgroup']).exists())
            self.assertFalse(marker.exists(), 'dispatch continued after cancellation during cleanup')

    def test_provider_cancellation_during_cleanup_stops_before_next_checkout(self):
        import build_provider_smoke as provider
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            root = self.make_fixture(base)
            rev = subprocess.check_output(['git', '-C', str(root), 'rev-parse', 'HEAD'], text=True).strip()
            out = base/'provider'
            sent = False
            def interrupt_then_destroy(scope):
                nonlocal sent
                if not sent:
                    sent = True
                    os.kill(os.getpid(), signal.SIGTERM)
                destroy(scope)
            # Tiny actual Git worktrees exercise the shipped provider entry.
            # Even a broken cancellation cannot start a Lean build: the
            # fixture has no generation script and refuses before that step.
            argv = ['build_provider_smoke.py', '--cerberus-repo', str(root),
                    '--cerberus-rev', rev, '--lem-repo', str(root), '--out', str(out)]
            with patch.object(provider, 'LEM_REV', rev), patch('sys.argv', argv), \
                 patch('process_scope.destroy', side_effect=interrupt_then_destroy), \
                 redirect_stdout(io.StringIO()):
                code = provider.main()
            report = json.loads((out/'manifest.json').read_text())
            self.assertEqual(code, 1)
            self.assertEqual(report['status'], 'incomplete')
            self.assertEqual(len(report['commands']), 1)
            row = report['commands'][0]
            self.assertEqual(row['exit_status'], 0)
            self.assertEqual(row['interrupted_signal'], signal.SIGTERM)
            self.assertTrue(row['containment_cleaned'])
            self.assertFalse(Path(row['cgroup']).exists())
            self.assertFalse((out/'lem').exists())

    def test_runner_signals_leave_incomplete_report_and_identified_process(self):
        for sig in (signal.SIGTERM, signal.SIGKILL):
            with self.subTest(signal=sig), tempfile.TemporaryDirectory() as tmp:
                base = Path(tmp)
                root = self.make_fixture(base, a='echo CLAIMED-PASS\ntimeout 30 sh -c \'echo $$ > child.pid; exec sleep 30\'\n')
                out = base/'evidence'
                program = (f'import sys; sys.path.insert(0, {str(Path(release.__file__).parent)!r}); '
                    'import release; from pathlib import Path; '
                    f'release.ROOT=Path({str(root)!r}); release.artifacts=lambda: {{}}; '
                    'release.external_inputs=lambda: {}; '
                    f'sys.argv=["release.py","--mode","full","--out",{str(out)!r}]; '
                    'sys.exit(release.main())')
                child = subprocess.Popen([sys.executable, '-c', program], stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
                pgid = None
                try:
                    deadline = time.monotonic()+10
                    while time.monotonic() < deadline:
                        if (out/'report.json').exists():
                            report = json.loads((out/'report.json').read_text())
                            pgid = report.get('active_lane', {}).get('process_group')
                            if pgid and (root/'child.pid').exists(): break
                        time.sleep(0.01)
                    self.assertIsNotNone(pgid)
                    self.assertTrue((root/'child.pid').exists())
                    nested_pid = int((root/'child.pid').read_text())
                    scope_path = Path(report['active_lane']['cgroup'])
                    child.send_signal(sig)
                    child.wait(timeout=10)
                    report = json.loads((out/'report.json').read_text())
                    self.assertNotEqual(report['status'], 'passed')
                    self.assertTrue(report['release_certification'].startswith('incomplete:'))
                    if sig == signal.SIGTERM:
                        self.assertEqual(report['status'], 'incomplete')
                        self.assertEqual(report['lanes'][0]['interrupted_signal'], sig)
                        self.assertIn('B1', [row['id'] for row in report['unrun']])
                        # A reaped leader cannot still be a running process.
                        self.assertFalse(Path(f'/proc/{pgid}').exists())
                    else:
                        self.assertEqual(report['status'], 'running')
                        self.assertEqual(report['active_lane']['process_group'], pgid)
                    deadline = time.monotonic()+10
                    while scope_path.exists() and time.monotonic() < deadline:
                        time.sleep(0.01)
                    self.assertFalse(scope_path.exists(), 'guardian must clean after supervisor SIGKILL too')
                    stat = Path(f'/proc/{nested_pid}/stat')
                    self.assertTrue(not stat.exists() or stat.read_text().split(') ')[1].split()[0] in ('Z', 'X'))
                finally:
                    if pgid and 'scope_path' in locals():
                        destroy(scope_path)
                    if child.poll() is None: child.kill()
                    child.communicate(timeout=10)


if __name__ == '__main__':
    unittest.main(verbosity=2)
