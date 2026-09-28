#!/usr/bin/env python3
"""WP1 diagnostic: C lowering into the experimental stepper (Lean native).

This is not a concurrency acceptance gate. Build/regenerate the normal drivers
first. Main is an executable root, not an importable library: append the probe
to its current source, rename only its command-line entry, and link with its
actual link inputs. No copied frontend implementation is maintained here.
"""
import hashlib
import json
import os
from pathlib import Path
import shlex
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
LF = ROOT / 'lean_frontend'
OUT = ROOT / '.tmp/sc-wp1/source-stepping'
SCRATCH = LF / '.tmp/sc-wp1'
FIXTURES = {
    'return': 'int main(void) { return 42; }\n',
    'loop': 'int main(void) { while (1) {} }\n',
    'rmw': 'int main(void) { int x = 0; return x++; }\n',
    'members': 'int main(void) { struct { int a; int b; } p = { 1, 2 }; return p.a + p.b; }\n',
    'comma': 'int main(void) { int x = 0; return (x = 1, x); }\n',
    'global': 'int g = 42; int main(void) { return g; }\n',
    'args': 'int main(int argc, char **argv) { return argc; }\n',
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    SCRATCH.mkdir(parents=True, exist_ok=True)
    records = {}

    def run(name, command, cwd=ROOT):
        # Keep capped alive through timeout's process-group cleanup.
        command = list(command)
        at = 1 if Path(command[0]).name == 'capped' else 0
        command[at:at] = ['timeout', '--kill-after=5', '170']
        start = time.monotonic()
        r = subprocess.run(command, cwd=cwd, capture_output=True, timeout=200,
            env={**os.environ, 'LEAN_ABORT_ON_PANIC': '1', 'DUNE_CACHE': 'disabled'})
        (OUT/f'{name}.stdout').write_bytes(r.stdout)
        (OUT/f'{name}.stderr').write_bytes(r.stderr)
        records[name] = {'command': command, 'cwd': str(cwd), 'returncode': r.returncode,
            'elapsed_seconds': time.monotonic()-start,
            'stdout_sha256': hashlib.sha256(r.stdout).hexdigest(),
            'stderr_sha256': hashlib.sha256(r.stderr).hexdigest()}
        if r.returncode:
            raise RuntimeError(f'{name} failed: see {OUT}')
        return r.stdout

    run('native-build', ['dune', 'build', '--force', 'backend/driver/main.exe',
        'cerberus.install', 'cerberus-lib.install'])
    run('lean-build', ['../scripts/capped', 'lake', 'build', 'CerberusLean', 'cerberus-lean'], LF)
    for name, text in FIXTURES.items():
        source = OUT.parent/f'source-{name}.c'
        source.write_text(text)
        data = run(f'parse-{name}', ['_build/default/backend/driver/main.exe',
            '--cabs-json', str(source)])
        (OUT.parent/f'source-{name}.json').write_bytes(data)
    current_main = (LF/'Main.lean').read_text()
    if current_main.count('def main (') != 1:
        raise RuntimeError('Main entry changed; inspect the probe integration')
    body = (LF/'test/SCWP1SourceChecks.lean.in').read_text()
    footer = '\ndef main : IO Unit := do\n' + ''.join(
        f'  SCWP1Source.check {fuel} "{name}"\n' for fuel in [256, 512] for name in FIXTURES)
    (SCRATCH/'SourceStepping.lean').write_text(
        current_main.replace('def main (', 'def sequentialMain (') + '\n' + body + footer)
    run('elaborate', ['../scripts/capped', '../scripts/lean_probe.sh',
        '.tmp/sc-wp1/SourceStepping.lean', '-c', '.tmp/sc-wp1/source-stepping.c'], LF)
    run('compile', ['../scripts/capped', 'lake', 'env', 'leanc', '-O1', '-c',
        '.tmp/sc-wp1/source-stepping.c', '-o', '.tmp/sc-wp1/source-stepping.o'], LF)
    rsp = (LF/'.lake/build/bin/cerberus-lean.rsp').read_text().splitlines()
    if not rsp[0].endswith('/Main.c.o.export"'):
        raise RuntimeError('Main link inputs changed; inspect before updating the probe')
    rsp[0] = '"' + str(SCRATCH/'source-stepping.o') + '"'
    (SCRATCH/'source-stepping.rsp').write_text('\n'.join(rsp)+'\n')
    run('link', ['../scripts/capped', 'lake', 'env', 'leanc', '-o',
        '.tmp/sc-wp1/source-stepping', '@.tmp/sc-wp1/source-stepping.rsp'], LF)
    output = run('execute', ['../scripts/capped', '.tmp/sc-wp1/source-stepping'], LF)
    lines = output.decode().splitlines()
    if len(lines) != len(FIXTURES)*2 or any(not line.startswith('source ') for line in lines):
        raise RuntimeError('unexpected source probe transcript')
    inputs = ['frontend/model/core_reduction.lem', 'frontend/model/driver.lem',
        'lean_frontend/Main.lean', 'lean_frontend/CerbMem.lean',
        'lean_frontend/generated/Driver.lean', 'lean_frontend/generated/Core_reduction.lean',
        'lean_frontend/test/SCWP1SourceChecks.lean.in', 'scripts/test_sc_wp1_source.py']
    objects = [Path(t) for t in shlex.split('\n'.join(rsp))
        if t.endswith(('.o', '.o.export', '.a'))]
    objects = [p if p.is_absolute() else LF/p for p in objects]
    artifacts = [SCRATCH/n for n in ['SourceStepping.lean', 'source-stepping.c',
        'source-stepping.rsp', 'source-stepping']] + objects
    record = {'scope': 'C-to-Core bounded stepping on Lean native; no SC or source-order correspondence claim',
        'sources': {p: sha(ROOT/p) for p in inputs}, 'fixtures': FIXTURES,
        'artifacts': {(str(p.relative_to(ROOT)) if p.is_relative_to(ROOT) else str(p)): sha(p) for p in artifacts}, 'runs': records}
    (OUT/'record.json').write_text(json.dumps(record, indent=2)+'\n')
    print('WP1 source stepping: seven C fixtures at fuels 256/512 passed; loop budgets 1/2/7/4096')


if __name__ == '__main__':
    main()
