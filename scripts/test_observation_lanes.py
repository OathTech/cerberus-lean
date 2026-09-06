#!/usr/bin/env python3
"""Plant real lane entry points with controlled engine streams.

Uses the existing corpora/bridges, explicit tiny subsets where supported,
and both loud binary-override hooks. Verify runs its real corpus and engines;
only call-mode output/status is altered. No tracked input or binary is edited.
"""

import argparse
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile


ROOT = Path(__file__).resolve().parent.parent
LEGACY_LANES = ('bytes', 'libc_exec', 'libxml2_uri', 'immaculate', 'speclab',
                'speclab_divmod', 'speclab_bytearr', 'speclab_list', 'speclab_tree', 'speclab_seed')
LANES = ('exec', 'multi_tu', 'cn_coverage', 'ci_sweep', 'gcc_oracle', 'verify', *LEGACY_LANES)
STUB = r'''#!/usr/bin/env python3
import os, pathlib, subprocess, sys
side = pathlib.Path(sys.argv[0]).name
kind = os.environ[side.upper() + '_PLANT_KIND']
real = os.environ['REAL_' + side.upper()]
args = sys.argv[1:]
if side == 'oracle' and '--exec' not in args and not (
        os.environ.get('PLANT_BRIDGE_STATUS') == '1' and kind.startswith('exit')):
    os.execv(real, [real, *args])
rc = 0
out = b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'
err = b''
if os.environ.get('PLANT_REAL_EXEC') == '1':
    p = subprocess.run([real, *args], capture_output=True)
    out, err, rc = p.stdout, p.stderr, p.returncode
    # Verify's former hole was in call mode. Leave main-mode results alone.
    if os.environ.get('PLANT_ONLY_CALL') == '1' and side == 'lean' and '--call' not in args:
        kind = 'good'
    if os.environ.get('PLANT_ONLY_CRASH') == '1' and side == 'lean' and not any(
            pathlib.Path(a).name == 'g2-memcmp-uninit.json' for a in args):
        kind = 'good'
if kind == 'bytes':
    out = out.replace(b'stdout: "', b'stdout: "\\000\\128\\255')
elif kind == 'exit2':
    rc = 2
elif kind == 'exit124':
    rc = 124
elif kind == 'value137':
    out = out.replace(b'Specified(0)', b'Specified(137)')
elif kind in ('ub_ref', 'ub_diff'):
    if any(pathlib.Path(a).stem == 'ub' for a in args):
        out = b'Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<probe.c:2:' + (b'1' if kind == 'ub_ref' else b'2') + b'>"}\n'
        rc = 1
elif kind == 'descendant_oom':
    err += b'capped: OOM-KILLED (memory.events oom_kill=1; command exit 0; descendant killed)\n'
elif kind == 'crash_fuel':
    out, err, rc = b'', b'PANIC at LemLib.failwithIImpl LemLib.lean:10:3: lem: fuel exhausted\n', 134
elif kind == 'crash_garbage':
    out = b'corrupted transport bytes\n'
elif kind == 'crash_other':
    out, err, rc = b'', b'PANIC at Other.unreviewed Other:10:3: unrelated panic\n', 134
elif kind in ('refusal', 'different_refusal'):
    word = b'one' if kind == 'refusal' else b'two'
    out = b'Error {msg: "model refused: ' + word + b'"}\n'
    rc = 1
elif kind != 'good':
    raise SystemExit('unknown plant kind')
sys.stdout.buffer.write(out)
sys.stderr.buffer.write(err)
sys.exit(rc if rc >= 0 else 128 - rc)
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lane', choices=LANES, action='append')
    parser.add_argument('--out', help='retain logs, raw captures and JSON report here')
    args = parser.parse_args()
    outdir = Path(args.out).resolve() if args.out else Path(tempfile.mkdtemp(prefix='observation-lanes-', dir=ROOT / '.tmp'))
    outdir.mkdir(parents=True, exist_ok=True)
    oracle, lean = outdir / 'oracle', outdir / 'lean'
    for path in (oracle, lean):
        path.write_text(STUB)
        path.chmod(0o755)
    fixture = outdir / 'zero.c'
    fixture.write_text('int main(void) { return 0; }\n')
    execdir = outdir/'exec-mixed'; execdir.mkdir(exist_ok=True)
    for name in ('control.c', 'ub.c'):
        (execdir/name).write_text(fixture.read_text())
    partial_baseline = outdir/'exec-partial-baseline.txt'
    partial_baseline.write_text('control.c MATCH\n')
    gccdir = outdir / 'gcc'
    gccdir.mkdir(exist_ok=True)
    (gccdir / 'zero.c').write_text(fixture.read_text())
    multitree = outdir / 'multi' / 'basic'
    multitree.mkdir(parents=True, exist_ok=True)
    (multitree / 'a.c').write_text('int other(void); int main(void) { return other(); }\n')
    (multitree / 'b.c').write_text('int other(void) { return 0; }\n')
    cn_row = next(line.split()[0] for line in (ROOT / 'tests/cn_coverage/manifest.txt').read_text().splitlines()
                  if line.strip() and not line.startswith('#'))
    env = dict(os.environ, SKIP_BUILD='1', CERB_ORACLE_BIN_OVERRIDE=str(oracle),
               CERB_LEAN_BIN_OVERRIDE=str(lean),
               REAL_ORACLE=str(ROOT / '_build/default/backend/driver/main.exe'),
               REAL_LEAN=str(ROOT / 'lean_frontend/.lake/build/bin/cerberus-lean'))
    results = []
    print(f'PLANT MODE: real lane entry points, explicit engine overrides; evidence {outdir}', flush=True)
    for lane in args.lane or LANES:
        variants = [('control', 'good', 'good'), ('bytes', 'good', 'bytes'),
                    ('lean-exit2', 'good', 'exit2'),
                    ('descendant-oom', 'good', 'descendant_oom')]
        if lane != 'gcc_oracle':
            variants.append(('oracle-exit2', 'exit2', 'good'))
        if lane == 'verify':
            variants.append(('call-verdict-then-timeout', 'good', 'exit124'))
        if lane == 'cn_coverage':
            variants.extend([('refusal-control', 'refusal', 'refusal'),
                             ('refusal-text', 'refusal', 'different_refusal')])
        if lane == 'gcc_oracle':
            variants.append(('native-exit137', 'value137', 'value137'))
        if lane == 'exec':
            variants.extend([('ub-control', 'ub_ref', 'ub_ref'),
                             ('ub-difference', 'ub_ref', 'ub_diff'),
                             ('ub-difference-new-baseline', 'ub_ref', 'ub_diff'),
                             ('ub-difference-only', 'ub_ref', 'ub_diff')])
        if lane == 'immaculate':
            variants.extend([(kind.replace('_', '-'), 'good', kind)
                             for kind in ('crash_fuel', 'crash_garbage', 'crash_other')])
        for name, okind, lkind in variants:
            case_dir = outdir / f'{lane}.{name}'
            case_dir.mkdir(exist_ok=True)
            case_env = dict(env, ORACLE_PLANT_KIND=okind, LEAN_PLANT_KIND=lkind,
                            CERB_OBSERVATION_DIR=str(case_dir / 'raw'))
            if lane == 'exec':
                flags = [str(fixture)]
                if name.startswith('ub-'):
                    flags = [str(execdir/'ub.c' if name.endswith('-only') else execdir)]
                    if name.endswith('-new-baseline'):
                        flags.insert(0, '--check-baseline='+str(partial_baseline))
            elif lane == 'multi_tu':
                flags = [str(multitree.parent)]
            elif lane == 'cn_coverage':
                flags = ['--only', '^' + re.escape(cn_row) + '$']
            elif lane == 'ci_sweep':
                flags = ['--suite', 'ci', '--max', '1', '--out', str(case_dir / 'scoreboard')]
            elif lane == 'gcc_oracle':
                (gccdir / 'zero.c').write_text(f'int main(void) {{ return {137 if name == "native-exit137" else 0}; }}\n')
                flags = ['--no-csmith', '--max', '1', str(gccdir)]
            elif lane == 'verify':
                flags = ['--verbose']
                case_env['PLANT_REAL_EXEC'] = '1'
                case_env['PLANT_ONLY_CALL'] = '1'
            elif lane in LEGACY_LANES:
                flags = ['--selftest'] if lane == 'speclab' else ['--plant'] if lane.startswith('speclab_') else []
                case_env['PLANT_REAL_EXEC'] = '1'
                if lane == 'immaculate' and name.startswith('crash-'):
                    case_env['PLANT_ONLY_CRASH'] = '1'
                if lane == 'bytes':
                    case_env['PLANT_BRIDGE_STATUS'] = '1'
            command = [str(ROOT / 'scripts' / f'test_{lane}.sh'), *flags]
            result = subprocess.run(command, cwd=ROOT, env=case_env, capture_output=True)
            (case_dir / 'stdout').write_bytes(result.stdout)
            (case_dir / 'stderr').write_bytes(result.stderr)
            text = (result.stdout + result.stderr).decode('utf8', errors='replace')
            expected_accept = name in ('control', 'refusal-control', 'native-exit137', 'ub-control')
            if lane == 'gcc_oracle' and name == 'bytes':
                # This lane deliberately compares integer exits. Demonstrate
                # that the richer bytes survive, rather than pretend it is a
                # second full-output oracle.
                expected_accept = True
            if lane == 'ci_sweep':
                tsv = case_dir / 'scoreboard/ci.tsv'
                accepted = tsv.exists() and '\tMATCH\t' in tsv.read_text()
                observed = tsv.read_text().strip() if tsv.exists() else text[-800:]
            else:
                accepted = result.returncode == 0
                observed = text[-1400:]
            valid = accepted == expected_accept and 'PLANT MODE' in text
            if expected_accept:
                if lane in ('exec', 'cn_coverage'):
                    valid = valid and bool(re.search(r'^\[[0-9]+/[0-9]+\] (?:MATCH|REJECT_MATCH) ', text, re.M))
                elif lane == 'multi_tu':
                    valid = valid and '[1] MATCH basic:' in text
                elif lane == 'gcc_oracle':
                    valid = valid and bool(re.search(r'^\[1/1\] AGREE ', text, re.M))
                elif lane == 'verify':
                    valid = valid and '127 passed, 0 failed' in text
                elif lane == 'bytes':
                    valid = valid and 'exec_match=9 neg_pinned=5 fail=0' in text
                elif lane == 'libc_exec':
                    valid = valid and 'ALL MATCH RECORDED BASELINE' in text
                elif lane == 'libxml2_uri':
                    valid = valid and 'GATE PASS:' in text
                elif lane == 'immaculate':
                    valid = valid and 'OK: lane matches the committed baseline' in text
                elif lane.startswith('speclab'):
                    valid = valid and f'test_{lane}: PASS' in text
            elif lane == 'verify':
                valid = valid and 'complete observation mismatch/incomplete engine' in text
            elif name == 'bytes':
                valid = valid and any(word in text for word in
                                      ('MISMATCH', 'STDOUT_DIFF', 'DIFF', '[FAIL]', 'pipelines disagree'))
            elif name == 'refusal-text':
                valid = valid and 'REJECT_DIFF' in text
            elif name.startswith('ub-difference'):
                rate = '0%' if name.endswith('-only') else '50%'
                valid = valid and 'ub_diff=1' in text and f'Match rate:   {rate}' in text
                if name.endswith('-new-baseline'):
                    valid = valid and 'REGRESSION: new file (not in baseline) with failing status: ub.c UB_DIFF' in text
            elif name == 'descendant-oom':
                valid = valid and any(word in text for word in ('OBSERVATION ERROR', 'KILL', 'killed'))
            elif lane == 'bytes' and name == 'oracle-exit2':
                valid = valid and 'cabs-json production failed' in text
            else:
                valid = valid and 'OBSERVATION ERROR' in text
            if lane == 'gcc_oracle' and name == 'bytes':
                captures = list((case_dir / 'raw').rglob('*.lean.stdout'))
                valid = valid and len(captures) == 1 and b'\\000\\128\\255' in captures[0].read_bytes()
            if lane == 'gcc_oracle' and name == 'native-exit137':
                statuses = list((case_dir / 'raw').rglob('*.run*.status'))
                valid = valid and len(statuses) >= 2 and all(p.read_text().strip() == '137' for p in statuses)
            results.append({'lane': lane, 'plant': name, 'passed': valid,
                            'process_status': result.returncode, 'expected_accept': expected_accept,
                            'command': command, 'evidence': str(case_dir), 'observed': observed})
            print(('PLANT OK   ' if valid else 'PLANT FAIL ') + f'{lane}: {name}', flush=True)
            if not valid:
                print(observed, flush=True)
    (outdir / 'report.json').write_text(json.dumps({'schema': 1, 'plants': results}, indent=2) + '\n')
    failures = sum(not r['passed'] for r in results)
    print(f'observation lane plants: {len(results) - failures}/{len(results)} passed', flush=True)
    return bool(failures)


if __name__ == '__main__':
    sys.exit(main())
