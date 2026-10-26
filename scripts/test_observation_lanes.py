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

import observations as obs
import pnvi_lane
from test_stops import INV, CRASH, OK, FUEL, PANIC, TRACE, wire, model, multi


ROOT = Path(__file__).resolve().parent.parent
LEGACY_LANES = ('bytes', 'libc_exec', 'libxml2_uri', 'immaculate', 'speclab',
                'speclab_divmod', 'speclab_bytearr', 'speclab_list', 'speclab_tree', 'speclab_seed')
LANES = ('exec', 'multi_tu', 'cn_coverage', 'ci_sweep', 'gcc_oracle', 'verify', *LEGACY_LANES)
STUB = r'''#!/usr/bin/env python3
import json, os, pathlib, re, subprocess, sys
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
if kind == 'switch_report':
    # The production driver reports its switch set once, after execution
    # returns (a panic's envelope stays intact). The plant REPLACES that one
    # line with a switched-mode report: the lanes must tolerate exactly one
    # report of any supported set without changing a verdict token, and the
    # decoder treats a second report as a problem (duplicate), so the plant
    # must not append (post-rebase fix, 2026-10-26).
    if rc in (0, 1) and out.startswith((b'Defined {', b'Undefined {', b'Error {', b'ModelFailure {', b'EXECUTION ')):
        err = re.sub(rb'cerberus-lean switches: \[[^\]\n]*\]\n', b'', err) + b'cerberus-lean switches: [inner_arg_temps]\n'
elif kind == 'bytes':
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
elif kind in ('crash_model', 'crash_model_suffix'):
    stop = ['1', 'UPSTREAM_CRASH', 'CerbMem.memcmpByte', 'non-integer byte',
            ['cerberus', 'b9aeedcb4dd438763b0eef7f95ac19e93875d7de',
             'memory/concrete/impl_mem.ml', '2658', '2659', 'assert false'], ['none'], None]
    payload = 'cerberus-lean stop ' + json.dumps(stop, separators=(',', ':'))
    out, err, rc = ('ModelFailure {msg: ' + json.dumps(payload) + '}\n').encode(), b'', 1
    if kind == 'crash_model_suffix':
        out += b'garbage after complete-looking record\n'
elif kind == 'crash_other':
    out, err, rc = b'', b'PANIC at Other.unreviewed Other:10:3: unrelated panic\n', 134
elif kind == 'crash_invariant':
    payload = 'cerberus-lean stop ' + json.dumps(
        ['1', 'INVARIANT', 'plant.guard', 'guard failed', 'plant contract'], separators=(',', ':'))
    out, err, rc = ('ModelFailure {msg: ' + json.dumps(payload) + '}\n').encode(), b'', 1
elif kind == 'crash_legacy':
    out, err, rc = b'', b'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: old failure\n', 134
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


def stop_policy_plants(outdir):
    """Exercise the actual Python and shell classification functions cheaply.

    The full immaculate entry-point plants below additionally check that the
    unconditional invariant veto prevents baseline acceptance.
    """
    outdir.mkdir(parents=True, exist_ok=True)
    source = (ROOT / 'scripts/test_immaculate.sh').read_text()
    functions = source[source.index('verdict() {'):source.index(': > "$OUTPUT_DIR/baseline.new"')]
    common = (ROOT / 'scripts/common.sh').read_text()
    start = common.index('is_cap_kill() {')
    cap_function = common[start:common.index('\n}\n', start) + 3]
    harness = outdir / 'immaculate-functions.sh'
    harness.write_text('set -euo pipefail\nsource "$1/scripts/observations.sh"\n'
                       'CAP_OOM_PATTERN=$(cat "$1/scripts/cap_oom.regex")\n' + cap_function + '\n' + functions +
                       '\nl=$(verdict "$2.stdout" "$3" "$2.stderr" lean)\n'
                       'classify "$4" "$l"\n')
    prefix = outdir / 'capture'
    invariant_cases = [
        ('typed', model(wire(INV)), b'', 1),
        ('panic', b'', PANIC + wire(INV) + b'\n' + TRACE, 134),
        ('cli', b'', wire(INV) + b'\n', 2),
        ('mixed', multi(model(wire(CRASH)), model(wire(INV)), FUEL), b'', 0),
        ('bad-tail', model(wire(INV)) + b'truncated', b'', 1),
        ('timeout', model(wire(INV)), b'', 124),
        ('bare137', model(wire(INV)), b'', 137),
        ('oom', model(wire(INV)), b'capped: OOM-KILLED (memory.events oom_kill=1; command exit 0)\n', 0),
    ]
    problem_cases = [
        ('malformed-reserved-panic', b'', PANIC + wire(['2', *INV[1:]]) + b'\n' + TRACE, 134),
        ('malformed-reserved-model', model(b'cerberus-lean stop [broken'), b'', 1),
        ('envelope-less-model', model(b'old message'), b'', 1),
    ]
    counts = {'INVARIANT': 0, 'INVALID': 0}
    cases = [(*case, 'INVARIANT') for case in invariant_cases]
    cases += [(*case, 'INVALID') for case in problem_cases]
    for name, stdout, stderr, status, expected in cases:
        if expected == 'INVALID':
            decoded = obs.decode_stop(stdout, stderr, status)
            assert decoded.problems and not decoded.stops, (name, decoded)
        prefix.with_suffix('.stdout').write_bytes(stdout)
        prefix.with_suffix('.stderr').write_bytes(stderr)
        prefix.with_suffix('.status').write_text(str(status))
        lean = pnvi_lane.classify_side(str(prefix), True)
        for oracle, token in [(('OBS', ('VAL:0',), ('VAL:0',)), 'VAL:0'),
                              (('CRASH', 'unrelated'), 'CRASH'),
                              (('RESOURCE', 'KILL'), 'KILL'),
                              (('RESOURCE', 'TIMEOUT'), 'INVALID'),
                              (('INVALID', 'bad oracle'), 'INVALID')]:
            cls, why = pnvi_lane.classify_row('exhaustive', oracle, lean)
            assert cls == 'INVALID', (name, oracle, lean, cls, why)
            assert lean[0] == 'INVALID', (name, lean)
            if expected == 'INVARIANT':
                assert lean[1].startswith('INVARIANT:') and 'INVARIANT:' in why, (lean, why)
            else:
                assert lean[1].startswith('stop protocol: '), (name, lean)
            p = subprocess.run(['bash', str(harness), str(ROOT), str(prefix), str(status), token],
                               capture_output=True, env=dict(os.environ, OBSERVATION_CODEC=str(ROOT/'scripts/observations.py')))
            assert p.returncode == 0 and p.stdout == (expected + '\n').encode(), (name, p)
            if expected == 'INVARIANT':
                assert not p.stderr, (name, p)
            else:
                assert p.stderr.startswith(b'OBSERVATION ERROR: immaculate INVALID: stop protocol: '), (name, p)
            counts[expected] += 1
    # These pre-existing resource exits remain ahead of protocol problems.
    oom = b'capped: OOM-KILLED (memory.events oom_kill=1; command exit 0)\n'
    for name, stdout, stderr, status, pnvi_expected, shell_expected in (
            ('oom-problem', model(b'old message'), oom, 0, ('RESOURCE', 'KILL'), b'KILL\n'),
            ('bare137-problem', model(b'old message'), b'', 137, ('RESOURCE', 'KILL'), b'INVALID\n'),
            ('timeout-problem', model(b'old message'), b'', 124, ('RESOURCE', 'TIMEOUT'), b'INVALID\n'),
            ('fuel-tail-problem', FUEL + b'bad tail\n', b'', 1, ('RESOURCE', 'FUEL'), b'INVALID\n')):
        assert obs.decode_stop(stdout, stderr, status).problems, name
        prefix.with_suffix('.stdout').write_bytes(stdout)
        prefix.with_suffix('.stderr').write_bytes(stderr)
        prefix.with_suffix('.status').write_text(str(status))
        assert pnvi_lane.classify_side(str(prefix), True) == pnvi_expected, name
        p = subprocess.run(['bash', str(harness), str(ROOT), str(prefix), str(status), 'CRASH'], capture_output=True)
        assert p.returncode == 0 and p.stdout == shell_expected, (name, p)
        if shell_expected == b'KILL\n':
            assert not p.stderr, (name, p)
        else:
            assert p.stderr.startswith(b'OBSERVATION ERROR: immaculate INVALID: stop protocol: '), (name, p)
    # Exercise the imported OOM helper and the ordinary path too: a missing
    # helper must not silently turn a shell error into a passing negative test.
    for stdout, stderr, status, oracle, expected in (
            (OK, b'', 0, 'VAL:' + OK.decode().split(' ', 1)[1].strip(), b'MATCH\n'),
            (b'', b'capped: OOM-KILLED (memory.events oom_kill=1; command exit 0)\n', 0, 'CRASH', b'KILL\n')):
        prefix.with_suffix('.stdout').write_bytes(stdout)
        prefix.with_suffix('.stderr').write_bytes(stderr)
        p = subprocess.run(['bash', str(harness), str(ROOT), str(prefix), str(status), oracle], capture_output=True)
        assert p.returncode == 0 and p.stdout == expected and not p.stderr, p
    # A recognized panic remains a coarse crash, explicitly without an origin.
    prefix.with_suffix('.stdout').write_bytes(b'')
    prefix.with_suffix('.stderr').write_bytes(PANIC + b'old failure\n' + TRACE)
    prefix.with_suffix('.status').write_text('134')
    decoded = obs.decode_stop(b'', prefix.with_suffix('.stderr').read_bytes(), 134)
    assert not decoded.stops and not decoded.problems and len(decoded.legacy_panics) == 1
    assert pnvi_lane.classify_side(str(prefix), True) == ('CRASH', 'old failure')
    p = subprocess.run(['bash', str(harness), str(ROOT), str(prefix), '134', 'CRASH'], capture_output=True)
    assert p.returncode == 0 and p.stdout == b'MATCH\n' and p.stderr == (
        b'immaculate: legacy, origin unattributed (coarse CRASH pin only)\n'), p
    print(f"STOP POLICY: {counts['INVARIANT']} invariant/oracle and {counts['INVALID']} malformed/oracle pairs RED in both classifiers; ordinary/resource/legacy controls passed", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lane', choices=LANES, action='append')
    parser.add_argument('--out', help='retain logs, raw captures and JSON report here')
    parser.add_argument('--plant', action='append', help='run only these named plants in selected lanes')
    parser.add_argument('--stop-policy-only', action='store_true', help='focused PNVI/immaculate stop-policy plants')
    args = parser.parse_args()
    outdir = Path(args.out).resolve() if args.out else Path(tempfile.mkdtemp(prefix='observation-lanes-', dir=ROOT / '.tmp'))
    outdir.mkdir(parents=True, exist_ok=True)
    if args.stop_policy_only:
        stop_policy_plants(outdir)
        return 0
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
    stop_policy_plants(outdir / 'policy')
    results = []
    print(f'PLANT MODE: real lane entry points, explicit engine overrides; evidence {outdir}', flush=True)
    for lane in args.lane or LANES:
        # The existing positive control also plants the run-report diagnostic:
        # each actual lane must ignore it without changing any verdict token.
        variants = [('control', 'good', 'switch_report'), ('bytes', 'good', 'bytes'),
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
                             for kind in ('crash_fuel', 'crash_garbage', 'crash_other', 'crash_model', 'crash_model_suffix')])
            # 2026-09-06 landing finding: the ambient TERM must not reach the
            # engines (Cmdliner styles the crash envelope from TERM/NO_COLOR);
            # the harness pin in common.sh must win over an interactive shell.
            variants.append(('ambient-term', 'good', 'good'))
            variants.extend([('crash-invariant', 'good', 'crash_invariant'),
                             ('crash-legacy', 'good', 'crash_legacy')])
        if args.plant:
            missing = set(args.plant) - {v[0] for v in variants}
            if missing:
                parser.error(f'unknown plants for {lane}: {sorted(missing)}')
            variants = [v for v in variants if v[0] in args.plant]
        for name, okind, lkind in variants:
            case_dir = outdir / f'{lane}.{name}'
            case_dir.mkdir(exist_ok=True)
            case_env = dict(env, ORACLE_PLANT_KIND=okind, LEAN_PLANT_KIND=lkind,
                            CERB_OBSERVATION_DIR=str(case_dir / 'raw'))
            if name == 'ambient-term':
                case_env['TERM'] = 'xterm-256color'
                case_env.pop('NO_COLOR', None)
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
            expected_accept = name in ('control', 'refusal-control', 'native-exit137', 'ub-control', 'ambient-term', 'crash-model', 'crash-legacy')
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
            elif name == 'crash-invariant':
                valid = valid and 'FAIL: INVARIANT in g2-memcmp-uninit (oracle CRASH)' in text
            else:
                valid = valid and 'OBSERVATION ERROR' in text
            if name == 'crash-legacy':
                valid = valid and 'legacy, origin unattributed' in text and 'SHARED_CRASH' not in text
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
