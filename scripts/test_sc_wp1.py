#!/usr/bin/env python3
"""Run WP1's bounded-stepping experiment, not an SC acceptance gate.

The two producers check fixture-derived values/counts and print the same six
rows. Lean additionally distinguishes generated-call fuel from step budget.
Selecting the otherwise unchosen bad Erun must fail in separate processes.
"""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / '.tmp/sc-wp1/paired-stepping'
ROWS = '''lifecycle: zero budget passive; main entered; 3 tau steps; finalized 42; 4 choices unused
singleton Core loop: incomplete at 1, 2, 7, 4096 steps; call fuel does not count loop iterations
globals: suspended before main; environment retained; looping initializer incomplete at 100
discovery: two contexts; unchosen faulty Erun untouched; selected store writes 42 once
outcomes: UB, blocked, empty, invalid choice, done and incomplete distinguished
SeqRMW: explicitly unsupported; no load/store performed
'''


def call(name, command, cwd=ROOT):
    start = time.monotonic()
    result = subprocess.run(command, cwd=cwd, env={**os.environ, 'LEAN_ABORT_ON_PANIC': '1',
        'DUNE_CACHE': 'disabled'}, capture_output=True, timeout=180)
    (OUT / f'{name}.stdout').write_bytes(result.stdout)
    (OUT / f'{name}.stderr').write_bytes(result.stderr)
    return result, {'command': command, 'cwd': str(cwd), 'returncode': result.returncode,
        'elapsed_seconds': time.monotonic() - start,
        'stdout_sha256': hashlib.sha256(result.stdout).hexdigest(),
        'stderr_sha256': hashlib.sha256(result.stderr).hexdigest()}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    records = {}
    r, records['native-build'] = call('native-build', ['dune', 'build', '--root', '.', '--force',
        'backend/memory_probe/sc_step_probe.exe'])
    if r.returncode:
        raise RuntimeError('native build failed; see ' + str(OUT))
    native = ['_build/default/backend/memory_probe/sc_step_probe.exe']
    lean = ['../scripts/capped', '../scripts/lean_probe.sh']
    positive = [('native', native, ROOT, ROWS),
        ('lean', lean + ['test/Unit/SCWP1Stepping.lean'], ROOT / 'lean_frontend',
         'generated-call fuel 64\n' + ROWS + 'generated-call fuel 128\n' + ROWS +
         'zero call fuel: explicit fuel failure, not incomplete\n')]
    positive.append(('rmw-continuations', lean + ['test/Unit/SCWP1RMWContinuation.lean'],
        ROOT / 'lean_frontend',
        ('production SeqRMW callback: sibling store completed; saved callback resurrected it; executing it produced a second receipt\n' * 2) +
        ('production SeqRMW update: saved memory rejects a function pointer published by a real store; current-memory evaluation returns 1\n' * 2)))
    for name, command, cwd, expected in positive:
        r, records[name] = call(name, command, cwd)
        if r.returncode or r.stderr or r.stdout != expected.encode():
            raise RuntimeError(name + ' positive probe failed; see ' + str(OUT))
    for name, command, cwd in [
        ('native-selected-fault', native + ['selected-fault'], ROOT),
        ('lean-selected-fault', lean + ['test/SCWP1SelectedFault.lean'], ROOT / 'lean_frontend')]:
        r, records[name] = call(name, command, cwd)
        if r.returncode == 0 or b'Erun outside of a proc' not in r.stdout + r.stderr:
            raise RuntimeError(name + ' failed to detect the selected fault; see ' + str(OUT))
    files = ['frontend/model/core_reduction.lem', 'frontend/model/driver.lem',
        'backend/memory_probe/sc_step_probe.ml',
        'lean_frontend/test/Unit/SCWP1Stepping.lean', 'lean_frontend/test/Unit/SCWP1SteppingProofs.lean',
        'lean_frontend/test/Unit/SCWP1ContextProofs.lean', 'lean_frontend/test/Unit/SCWP1RMWContinuation.lean',
        'lean_frontend/generated/Core_reduction.lean',
        'lean_frontend/test/SCWP1SelectedFault.lean', 'scripts/test_sc_wp1.py',
        'lean_frontend/generated/Driver.lean', 'ocaml_frontend/generated/driver.ml']
    record = {'scope': 'WP1 bounded-stepping experiment; not SC acceptance',
        'sources': {p: hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in files},
        'runs': records}
    (OUT / 'record.json').write_text(json.dumps(record, indent=2) + '\n')
    print('WP1 stepping: native + Lean fuels 64/128 passed; both selected-fault controls detected; both SeqRMW suspension counterexamples reproduced')


if __name__ == '__main__':
    main()
