#!/usr/bin/env python3
"""Hermetic integration plants against test_litmus's actual control flow.

Only engine runners are replaced. The lane's tokens_of/run_all and
the shared codec are loaded from the candidate under test. Positive controls
are mandatory, so broken extraction or missing dependencies cannot pass.
"""

from pathlib import Path
import argparse
import json
import os
import subprocess
import tempfile


ROOT = Path(__file__).resolve().parent.parent
lane = (ROOT / 'scripts/test_litmus.sh').read_text()


def between(start, end):
    return lane[lane.index(start):lane.index(end)]


helpers = '\n'.join([between('tokens_of() {', '\nrun_oracle() {'),
                     between('run_all() {', '\n# compare_to')])
script = r'''
set -uo pipefail
source "$1/scripts/observations.sh"
LITMUS_DIR="$2"; OUTPUT_DIR="$2"; MODEL_FLAGS=(--concurrency=sc)
ORACLE_RC="$3"; LEAN_RC="$4"; ORACLE_DATA="$5"; LEAN_DATA="$6"; ACTION="$7"
declare -A SET ERRMSG_O ERRMSG_L
DIFF_FAIL=0
''' + helpers + r'''
emit() {
    local prefix="$1" rc="$2" data="$3"
    printf '%s' "$data" > "$prefix.stdout"
    : > "$prefix.stderr"
    if [[ "$rc" == 137 ]]; then
        echo 'capped: OOM-KILLED (memory.events oom_kill=1)' > "$prefix.stderr"
    fi
    printf '%s\n' "$rc" > "$prefix.status"
    cat "$prefix.stdout" "$prefix.stderr" > "$prefix"
    return "$rc"
}
run_oracle() { emit "$2" "$ORACLE_RC" "$ORACLE_DATA"; }
run_lean() { emit "$3" "$LEAN_RC" "$LEAN_DATA"; }
run_all
[[ "$DIFF_FAIL" == 0 && -n "${SET[probe.c]-}" ]] && exit 42
exit 0
'''

defined = 'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'
undefined = 'Undefined {ub: "UB005_data_race", stderr: "", loc: "<probe.c:2:1>"}\n'
refusal = 'Error {msg: "model refused: thread spawn is unavailable"}\n'
cases = [('defined control', 0, 0, defined, defined, 'all', True),
         ('undefined control', 1, 1, undefined, undefined, 'all', True),
         ('refusal control', 1, 1, refusal, refusal, 'all', True)]
for action, data in [('all', defined), ('refusal', refusal)]:
    healthy = 0 if action == 'all' else 1
    for side in ('oracle', 'lean'):
        for bad in (2, 124, 137):
            codes = (bad, healthy) if side == 'oracle' else (healthy, bad)
            cases.append((f'{action} {side} verdict then exit {bad}', *codes, data, data, action, False))
for name, changed in [('stdout bytes', defined.replace('stdout: ""', 'stdout: "\\000\\128\\255"')),
                      ('stderr bytes', defined.replace('stderr: ""', 'stderr: "\\195\\169"')),
                      ('blocked', defined.replace('false', 'true')),
                      ('truncated', defined[:-3]), ('empty', ''),
                      ('trailing unknown record', defined + 'UNKNOWN {}\n')]:
    cases.append((name, 0, 0, defined, changed, 'all', False))
cases.extend([
    ('UB location', 1, 1, undefined, undefined.replace(':2:1', ':3:1'), 'all', False),
    ('Error text', 1, 1, refusal, refusal.replace('unavailable', 'not enabled'), 'all', False),
    ('both silent exit zero', 0, 0, '', '', 'all', False),
])

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out', type=Path)
args = parser.parse_args()
base = Path(os.environ.get('CERB_OBSERVATION_DIR', ROOT / '.tmp')).resolve()
base.mkdir(parents=True, exist_ok=True)
out = args.out.resolve() if args.out else Path(tempfile.mkdtemp(prefix='litmus-plants-', dir=base))
out.mkdir(parents=True, exist_ok=True)
(out/'helpers.sh').write_text(script)
print(f'PLANT MODE: actual litmus helpers, fake engines; no semantics evidence; raw captures {out}')
failed, rows = 0, []
for index, (name, orc, lrc, out_o, out_l, action, expected) in enumerate(cases):
    tmp = out / f'{index:02d}'
    tmp.mkdir(exist_ok=False)
    (tmp / 'probe.c').write_text('int main(void) { return 0; }\n')
    command = ['bash', '-c', script, '_', str(ROOT), str(tmp),
               str(orc), str(lrc), out_o, out_l, action]
    (tmp/'command.json').write_text(json.dumps(command, indent=2)+'\n')
    result = subprocess.run(command, capture_output=True)
    (tmp/'stdout').write_bytes(result.stdout)
    (tmp/'stderr').write_bytes(result.stderr)
    (tmp/'status').write_text(str(result.returncode)+'\n')
    accepted = result.returncode == 42
    valid = result.returncode in (0, 42) and accepted == expected
    valid = valid and b'command not found' not in result.stderr
    rows.append({'name': name, 'expected_accept': expected, 'accepted': accepted,
                 'plant_passed': valid, 'exit_status': result.returncode, 'evidence': str(tmp)})
    print(('PLANT OK   ' if valid else 'PLANT FAIL ') + name)
    if not valid:
        failed += 1
        print(result.stdout.decode(errors='replace'), result.stderr.decode(errors='replace'))

# Exercise the actual Cabs-to-Lean runner too, including an old valid-looking
# Lean capture beside a failed producer. A bridge status is not a Lean verdict.
bridge_helpers = between('run_lean() {', '\n# read_rows')
bridge_script = r"""
set -uo pipefail
source "$1/scripts/observations.sh"
OUTPUT_DIR="$2"; PROJECT_ROOT="$1"; TIMEOUT_SECS=5
CERBERUS_BIN="$2/bridge"; CERBERUS_LEAN_BIN="$2/lean"
CAPPED_TEST=(); TIME_BIN=/usr/bin/time
""" + bridge_helpers + r"""
rc=0
run_lean "$OUTPUT_DIR/probe.c" "$OUTPUT_DIR/probe.json" "$OUTPUT_DIR/result" --concurrency=sc || rc=$?
python3 "$OBSERVATION_CODEC" tokens --capture "$OUTPUT_DIR/result" --status "$rc" --policy litmus >/dev/null
"""
bridge_cases = [('bridge control', 0, '{}', False, True),
                ('bridge empty', 0, '', False, False),
                ('bridge failure 1 beside old UB', 1, '{}', True, False),
                ('bridge timeout beside old UB', 124, '{}', True, False),
                ('bridge kill beside old UB', 137, '{}', True, False),
                ('bridge failure 2', 2, '{}', False, False)]
for index, (name, rc, data, stale, expected) in enumerate(bridge_cases):
    tmp = out / f'bridge-{index:02d}'; tmp.mkdir()
    (tmp/'probe.c').write_text('int main(void) { return 0; }\n')
    (tmp/'bridge').write_text('#!/bin/bash\nprintf %s '+"'"+data+"'"+'\nexit '+str(rc)+'\n')
    (tmp/'lean').write_text('#!/bin/bash\nprintf %s '+"'"+defined+"'"+'\n')
    (tmp/'bridge').chmod(0o755); (tmp/'lean').chmod(0o755)
    if stale:
        (tmp/'result.stdout').write_text(undefined)
        (tmp/'result.stderr').write_text('')
        (tmp/'result.status').write_text('1\n')
    command = ['bash', '-c', bridge_script, '_', str(ROOT), str(tmp)]
    (tmp/'command.json').write_text(json.dumps(command, indent=2)+'\n')
    result = subprocess.run(command, capture_output=True)
    (tmp/'stdout').write_bytes(result.stdout); (tmp/'stderr').write_bytes(result.stderr)
    (tmp/'status').write_text(str(result.returncode)+'\n')
    accepted = result.returncode == 0
    valid = (result.returncode == 0 if expected else
             result.returncode == 2 and b"OBSERVATION ERROR: capture failed or reused its prefix:" in result.stderr)
    rows.append({'name': name, 'expected_accept': expected, 'accepted': accepted,
                 'plant_passed': valid, 'exit_status': result.returncode, 'evidence': str(tmp)})
    print(('PLANT OK   ' if valid else 'PLANT FAIL ') + name)
    if not valid:
        failed += 1
        print(result.stdout.decode(errors='replace'), result.stderr.decode(errors='replace'))
(out/'report.json').write_text(json.dumps({'schema': 1, 'plants': rows, 'failed': failed}, indent=2)+'\n')
print(f'litmus observation plants: {len(rows) - failed}/{len(rows)} passed')
raise SystemExit(bool(failed))
