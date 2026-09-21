#!/usr/bin/env python3
"""Durable first-audit adversaries against actual litmus/reference helpers.

No engines or builds are run. Positive controls and raw command/capture records
make extraction failures visible. The source is derived from the first audit
reproducer; expected results now require rejection of every demonstrated defect.
"""
from pathlib import Path
import argparse
import tempfile
import hashlib
import json
import os
import subprocess

ROOT = Path(__file__).resolve().parent.parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--out', type=Path)
args = parser.parse_args()
base = Path(os.environ.get('CERB_OBSERVATION_DIR', ROOT/'.tmp'))
base.mkdir(parents=True, exist_ok=True)
OUT = args.out.resolve() if args.out else Path(tempfile.mkdtemp(prefix='litmus-references-', dir=base))
OUT.mkdir(parents=True, exist_ok=True)
print(f'PLANT MODE: litmus reference/failure adversaries; raw records {OUT}', flush=True)
lane = (ROOT/'scripts/test_litmus.sh').read_text()
def between(start, end):
    return lane[lane.index(start):lane.index(end)]
helpers = '\n'.join([
    between('tokens_of() {', '\nrun_oracle() {'),
    between('# read_rows', '\necho ""\necho "litmus lane'),
])
# Runners are the only production functions replaced. They copy exact fixtures
# into the capture triplets consumed by the unmodified codec and helper code.
script = r'''
set -uo pipefail
source "$1/scripts/observations.sh"
LITMUS_DIR="$2"; OUTPUT_DIR="$2"; MODEL_FLAGS=(--concurrency=sc)
''' + helpers + r'''
emit() {
    local side="$1" prefix="$2" rc
    cp "$LITMUS_DIR/input.$side.stdout" "$prefix.stdout"
    cp "$LITMUS_DIR/input.$side.stderr" "$prefix.stderr"
    cp "$LITMUS_DIR/input.$side.status" "$prefix.status"
    cat "$prefix.stdout" "$prefix.stderr" > "$prefix"
    rc=$(cat "$prefix.status")
    return "$rc"
}
run_oracle() { emit oracle "$2"; }
run_lean() { emit lean "$3"; }
run_all
compare_to "$LITMUS_DIR/rows.txt" audit
printf 'DIFF_FAIL=%s COMPARE_FAIL=%s\n' "$DIFF_FAIL" "$COMPARE_FAIL"
[[ "$DIFF_FAIL" == 0 && "$COMPARE_FAIL" == 0 ]]
'''
(OUT/'helpers.sh').write_text(script)
def capture_run(name, command, cwd=ROOT, env=None):
    (OUT/f'{name}.command.json').write_text(json.dumps(command, indent=2)+'\n')
    result = subprocess.run(command, cwd=cwd, capture_output=True, env=env)
    (OUT/f'{name}.stdout').write_bytes(result.stdout)
    (OUT/f'{name}.stderr').write_bytes(result.stderr)
    (OUT/f'{name}.status').write_text(str(result.returncode)+'\n')
    print(name, 'status=',result.returncode)
    print(result.stdout.decode(errors='replace'),end='')
    if result.stderr: print(result.stderr.decode(errors='replace'),end='')
    return result.returncode

defined = b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'
refusal = b'Error {msg: "model refused: thread spawn is unavailable"}\n'
multi_refusal = b'EXECUTION 0:\n'+refusal+b'EXECUTION 1:\nError {msg: "unrelated evaluator failure"}\n'
internal_o = b'internal error: reason\n'
internal_l = b'PANIC at _private.LemLib.0.failwithIImpl LemLib.lean:10:3: reason\n'
cases = [
 ('defined-control', defined,b'',0,defined,b'',0,'probe.c SC {Specified(0)}\n','all'),
 ('empty-corpus', defined,b'',0,defined,b'',0,'','all'),
 ('unterminated-control', defined,b'',0,defined,b'',0,'probe.c SC {Specified(0)}','all'),
 ('unterminated-orphan', defined,b'',0,defined,b'',0,'probe.c SC {Specified(0)}\norphan.c SC {Specified(0)}','all'),
 ('unknown-class', defined,b'',0,defined,b'',0,'probe.c TYPO {Specified(0)}\n','all'),
 ('pending-is-not-support', defined,b'',0,defined,b'',0,'probe.c PENDING {Specified(0)}\n','all'),
 ('bad-row-control', defined,b'',0,defined,b'',0,'probe.c SC {Specified(99)}\n','all'),
 ('duplicate-overwrite', defined,b'',0,defined,b'',0,'probe.c SC {Specified(99)}\nprobe.c SC {Specified(0)}\n','all'),
 ('duplicate-reverse-control', defined,b'',0,defined,b'',0,'probe.c SC {Specified(0)}\nprobe.c SC {Specified(99)}\n','all'),
 ('duplicate-identical', defined,b'',0,defined,b'',0,'probe.c SC {Specified(0)}\nprobe.c SC {Specified(0)}\n','all'),
 ('missing-row', defined,b'',0,defined,b'',0,'other.c SC {Specified(0)}\n','all'),
 ('orphan-row', defined,b'',0,defined,b'',0,'probe.c SC {Specified(0)}\norphan.c SC {Specified(0)}\n','all'),
 ('internal-control', b'',internal_o,125,b'',internal_l,134,'probe.c NONSC {INTERNAL_ERROR(reason)}\n','all'),
 ('internal-different-first-control', b'',internal_o,125,b'',internal_l.replace(b'reason',b'different'),134,'probe.c NONSC {INTERNAL_ERROR(reason)}\n','all'),
 ('internal-different-continuation', b'',internal_o+b'left payload continuation\n',125,b'',internal_l+b'right payload continuation\n',134,'probe.c NONSC {INTERNAL_ERROR(reason)}\n','all'),
 ('internal-extra-fatal', b'',internal_o,125,b'',internal_l+b'Fatal error: exception Failure("second fault")\n',134,'probe.c NONSC {INTERNAL_ERROR(reason)}\n','all'),
 ('refusal-control', refusal,b'',1,refusal,b'',1,'probe.c NONSC REFUSE\n','seq'),
 ('refusal-plus-unrelated-error', multi_refusal,b'',0,multi_refusal,b'',0,'probe.c NONSC REFUSE\n','seq'),
 ('unrelated-error-first-control', multi_refusal.replace(refusal,b'Error {msg: "unrelated evaluator failure"}\n',1),b'',0,multi_refusal.replace(refusal,b'Error {msg: "unrelated evaluator failure"}\n',1),b'',0,'probe.c NONSC REFUSE\n','seq'),
]
expected_green = {'unterminated-control', 'defined-control', 'internal-control', 'refusal-control', 'reference-control', 'reference-reordered'}
rows=[]
for name,ostd,oerr,orc,lstd,lerr,lrc,ref,action in cases:
    d=OUT/name; d.mkdir(exist_ok=True)
    (d/'probe.c').write_text('int main(void) { return 0; }\n')
    if name == 'empty-corpus': (d/'probe.c').unlink()
    (d/'rows.txt').write_text(ref)
    for side,stdout,stderr,rc in [('oracle',ostd,oerr,orc),('lean',lstd,lerr,lrc)]:
        (d/f'input.{side}.stdout').write_bytes(stdout)
        (d/f'input.{side}.stderr').write_bytes(stderr)
        (d/f'input.{side}.status').write_text(str(rc)+'\n')
    cmd=['bash',str(OUT/'helpers.sh'),str(ROOT),str(d),action]
    rc=capture_run(name,cmd)
    rows.append({'name':name,'accepted':rc==0,'status':rc,'passed':rc in (0,1) and (rc==0)==(name in expected_green)})

original = (ROOT/'tests/litmus/expectations.txt').read_text()
(OUT/'expectations-duplicate.txt').write_text('SB+sc_sc+sc_sc.c SC {Specified(99)}\n'+original)
(OUT/'expectations-bad-only.txt').write_text(original.replace('SB+sc_sc+sc_sc.c  SC  {Specified(1),Specified(2),Specified(3)}','SB+sc_sc+sc_sc.c SC {Specified(99)}'))
(OUT/'expectations-identical.txt').write_text('SB+sc_sc+sc_sc.c SC {Specified(1),Specified(2),Specified(3)}\n'+original)
(OUT/'expectations-reordered.txt').write_text('\n'.join(reversed([s for s in original.splitlines() if s.strip() and not s.startswith('#')]))+'\n')
for name,path in [('reference-reordered',OUT/'expectations-reordered.txt'),('reference-identical-duplicate',OUT/'expectations-identical.txt'),('reference-control',ROOT/'tests/litmus/expectations.txt'),('reference-duplicate',OUT/'expectations-duplicate.txt'),('reference-bad-only-control',OUT/'expectations-bad-only.txt')]:
    rc = capture_run(name,['python3',str(ROOT/'tests/litmus/sc_reference.py'),'--check',str(path)])
    rows.append({'name':name,'status':rc,'passed':rc in (0,1) and (rc==0)==(name in expected_green)})
(OUT/'result.json').write_text(json.dumps(rows,indent=2)+'\n')
(OUT/'source-hashes.json').write_text(json.dumps({str(ROOT/p):hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in ['scripts/test_litmus.sh','scripts/observations.py','scripts/observations.sh','tests/litmus/sc_reference.py']},indent=2)+'\n')

failures = [r["name"] for r in rows if not r["passed"]]
print(f"litmus reference/failure plants: {len(rows)-len(failures)}/{len(rows)} passed", flush=True)
if failures: print("FAILED: "+", ".join(failures), flush=True)
raise SystemExit(bool(failures))
