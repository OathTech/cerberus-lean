#!/usr/bin/env python3
"""Exercise real shell entry points with isolated build/transport fixtures.

No engine or Lean build runs here. Only the fixture's prerequisites and
generator are substituted; production scripts and capture helpers are copied
verbatim. Actual builds and engines run separately in the ladder.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent


class PrerequisiteTests(unittest.TestCase):
    def test_failed_speclab_build_cannot_use_existing_generator(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scripts = root/'scripts'; scripts.mkdir()
            for name in ['common.sh', 'cap_oom.regex', 'fuel_classify.sh',
                         'observations.sh', 'observations.py', 'speclab_observations.sh']:
                shutil.copy2(ROOT/'scripts'/name, scripts/name)
            (root/'tools').mkdir()
            check = root/'tools/check_lem_sync.sh'
            check.write_text('#!/bin/sh\nexit 0\n'); check.chmod(0o755)
            (root/'_build/install/default').mkdir(parents=True)
            generator = root/'lean_frontend/speclab/.lake/build/bin/speclab-test'
            generator.parent.mkdir(parents=True)
            generator.write_text('#!/bin/sh\ntouch "$GENERATOR_MARKER"\nexit 83\n')
            generator.chmod(0o755)
            cap = scripts/'capped'
            cap.write_text('#!/bin/sh\necho "build stdout witness"\necho "build stderr witness" >&2\nexit "$BUILD_STATUS"\n')
            cap.chmod(0o755)
            marker = root/'generator-executed'
            env = dict(os.environ, SKIP_BUILD='1', GENERATOR_MARKER=str(marker),
                       CERB_ORACLE_BIN_OVERRIDE=str(generator), CERB_LEAN_BIN_OVERRIDE=str(generator),
                       CERB_OBSERVATION_DIR=str(root/'raw'))
            for suffix in ['', '_divmod', '_bytearr', '_list', '_tree', '_seed']:
                name = 'test_speclab'+suffix+'.sh'
                shutil.copy2(ROOT/'scripts'/name, scripts/name)
                for status in ['37', '0']:
                    with self.subTest(lane=name, build_status=status):
                        marker.unlink(missing_ok=True)
                        result = subprocess.run(['bash', str(scripts/name), '--plant'],
                            env=dict(env, BUILD_STATUS=status), capture_output=True, timeout=15)
                        self.assertIn(b'build stdout witness', result.stdout)
                        self.assertIn(b'build stderr witness', result.stderr)
                        if status == '37':
                            self.assertNotEqual(result.returncode, 0)
                            self.assertIn(b'speclab-test build failed', result.stderr)
                            self.assertFalse(marker.exists(), 'stale generator ran after failed build')
                        else:
                            self.assertTrue(marker.exists(), 'healthy prerequisite never reached generator')

    def test_bridge_keeps_all_bytes_and_status_without_publishing_failed_json(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            source = (ROOT/'scripts/common.sh').read_text()
            helpers = root/'helpers.sh'
            helpers.write_text(source[source.index('is_cap_kill() {'):source.index('\n# kill_label')])
            driver = root/'driver.sh'
            driver.write_text('''set -uo pipefail
source "$1/scripts/observations.sh"
CAP_OOM_PATTERN=$(cat "$1/scripts/cap_oom.regex")
source "$2/helpers.sh"
capture_cabs_json "$2/output.json" "$2/$3" "$4" -c "$5"
''')
            out = b'{"bridge":"partial"}\n'
            err = b'bridge diagnostic\x00\x80\xff\n'
            for name, status, diagnostic in [('control', 0, err), ('failed', 1, err),
                    ('oom-success', 0, err+b'capped: OOM event recorded in cgroup (memory.events oom_kill=1; command exit 0)\n')]:
                with self.subTest(case=name):
                    (root/'output.json').write_text('stale JSON')
                    code = f'import sys;sys.stdout.buffer.write({out!r});sys.stderr.buffer.write({diagnostic!r});sys.exit({status})'
                    p = subprocess.run(['bash', str(driver), str(ROOT), str(root), name, sys.executable, code], capture_output=True)
                    self.assertEqual((root/(name+'.stdout')).read_bytes(), out)
                    self.assertEqual((root/(name+'.stderr')).read_bytes(), diagnostic)
                    self.assertEqual((root/(name+'.status')).read_text(), str(status)+'\n')
                    self.assertTrue((root/(name+'.command')).is_file())
                    self.assertEqual(p.returncode == 0, name == 'control')
                    self.assertEqual((root/'output.json').read_bytes(), out if name == 'control' else b'')

    def test_observation_run_dir_retention_follows_exit_status_and_evidence_mode(self):
        """Landing prep 2026-09-06: a harness exiting 0 removes its raw-observation
        run directory; exiting non-zero keeps it and prints the path; with
        CERB_OBSERVATION_DIR set (evidence mode) it is always kept. register_cleanup
        must keep working in all three cases. Checked on the real filesystem."""
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            scripts = root/'scripts'; scripts.mkdir()
            for name in ['common.sh', 'cap_oom.regex', 'fuel_classify.sh', 'observations.sh', 'observations.py', 'capped']:
                shutil.copy2(ROOT/'scripts'/name, scripts/name)  # capped: common.sh fail-closes without it; never invoked here
            harness = scripts/'harness.sh'
            harness.write_text('''#!/bin/bash
set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/common.sh"
mkdir -p "$SCRATCH"
register_cleanup "$SCRATCH"
observation_capture "$OBSERVATION_RUN_DIR/probe" true > /dev/null
printf '%s\\n' "$OBSERVATION_RUN_DIR" > "$RUN_DIR_RECORD"
exit "$HARNESS_EXIT"
''')
            harness.chmod(0o755)
            cases = [('success', 0, None, False), ('failure', 3, None, True), ('evidence-mode', 0, 'raw', True)]
            for name, status, evidence, kept in cases:
                with self.subTest(case=name):
                    record, scratch = root/(name+'.run-dir'), root/(name+'.scratch')
                    env = dict(os.environ, HARNESS_EXIT=str(status), RUN_DIR_RECORD=str(record), SCRATCH=str(scratch))
                    env.pop('CERB_OBSERVATION_DIR', None)
                    if evidence:
                        env['CERB_OBSERVATION_DIR'] = str(root/evidence)
                    p = subprocess.run(['bash', str(harness)], env=env, capture_output=True, timeout=60)
                    self.assertEqual(p.returncode, status, p.stderr)
                    run_dir = Path(record.read_text().strip())
                    self.assertTrue(run_dir.is_relative_to(root), run_dir)
                    if evidence:
                        self.assertTrue(run_dir.is_relative_to(root/evidence), run_dir)
                    self.assertFalse(scratch.exists(), 'register_cleanup path survived exit')
                    self.assertEqual(run_dir.is_dir(), kept,
                                     f'{name}: run dir {run_dir} exists={run_dir.is_dir()}, expected kept={kept}')
                    if kept:
                        self.assertEqual((run_dir/'probe.status').read_text(), '0\n')
                    self.assertEqual(f'Raw observation evidence: {run_dir}'.encode() in p.stderr, name == 'failure', p.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)
