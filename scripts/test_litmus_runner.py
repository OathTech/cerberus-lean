#!/usr/bin/env python3
"""Exercise the real litmus runner with fixture executables, not source slices.

This checks harness wiring only. The production reference and SC semantics are
tested by the real lane; the tiny reference stub below supplies no semantic claim.
"""
import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
ENGINE = r'''#!/usr/bin/env python3
import json, os, sys
from pathlib import Path
case = os.environ['SC_TEST_CASE']
args = sys.argv[1:]
with open(os.environ['SC_TEST_CALLS'], 'a') as trace:
    trace.write(json.dumps(args) + '\n')
if '--cabs-json' in args:
    print('{' if case == 'truncated-bridge' else '{}')
    sys.exit(17 if case == 'failed-bridge' else 0)
assert '--concurrency=sc' in args, args
if '--batch' in args and '--exec' not in args:
    json.loads(Path(args[args.index('--batch') + 1]).read_text())
value = 9 if case == 'wrong-result' else 0
output = 'different' if case == 'different-output' and '--exec' not in args else ''
print(f'Defined {{value: "Specified({value})", stdout: "{output}", stderr: "", blocked: "false"}}')
if case == 'trailing-garbage': print('UNKNOWN {}')
sys.exit(124 if case == 'result-before-timeout' else 0)
'''


def main():
    with tempfile.TemporaryDirectory(prefix='litmus-runner-') as directory:
        base = Path(directory)
        engine = base / 'engine'
        engine.write_text(ENGINE)
        engine.chmod(0o755)
        corpus = base / 'corpus'
        corpus.mkdir()
        (corpus / 'sc_reference.py').write_text("print('fixture reference check')\n")
        source = corpus / 'probe.c'
        expectations = corpus / 'expectations.txt'
        rows = 'probe.c RMW {Specified(0)}\n'
        cases = [
            ('control', rows, True),
            ('pending', rows.replace('RMW', 'PENDING'), False),
            ('wrong-result', rows, False),
            ('different-output', rows, False),
            ('result-before-timeout', rows, False),
            ('trailing-garbage', rows, False),
            ('failed-bridge', rows, False),
            ('truncated-bridge', rows, False),
            ('duplicate-row', rows + rows, False),
            ('missing-row', '', False),
            ('orphan-row', rows + 'orphan.c RMW {Specified(0)}\n', False),
            ('empty-corpus', '', False),
        ]
        failures = []
        for name, reference, expected in cases:
            calls = base / (name + '.calls')
            source.write_text('int main(void) { return 0; }\n')
            if name == 'empty-corpus':
                source.unlink()
            expectations.write_text(reference)
            env = dict(os.environ, SKIP_BUILD='1', LITMUS_DIR=str(corpus),
                       CERB_ORACLE_BIN_OVERRIDE=str(engine),
                       CERB_LEAN_BIN_OVERRIDE=str(engine),
                       CERB_OBSERVATION_DIR=str(base / name),
                       SC_TEST_CASE=name, SC_TEST_CALLS=str(calls))
            run = subprocess.run(['bash', str(ROOT / 'scripts/test_litmus.sh'), '--check'],
                                 cwd=ROOT, env=env, capture_output=True, text=True)
            invoked = [json.loads(line) for line in calls.read_text().splitlines()] if calls.exists() else []
            correct = (run.returncode == 0) == expected
            if name == 'control':
                correct &= len(invoked) == 3 and 'ALL ROWS AT target' in run.stdout
            if name == 'failed-bridge':
                correct &= len(invoked) == 2 and 'Cabs producer failed' in ''.join(
                    p.read_text() for p in (base / name).rglob('*.capture-error'))
            if not correct:
                failures.append(name)
                print(run.stdout, run.stderr)
            print(f'{name}: {"PASS" if correct else "FAIL"}')
        return bool(failures)


if __name__ == '__main__':
    raise SystemExit(main())
