#!/usr/bin/env python3
"""SC WP0's finite paired diagnostic: primitives, ND transport, erasure, draining.

Expectations below are derived from the chosen LP64 layout and fixture actions,
not recorded from either engine. Full stdout is compared; any stderr or nonzero
exit is fatal. The executables additionally check actual state/result erasure.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / '.tmp/memory-access'


def expected(count, mode):
    rows = []

    def access(name, kind, ty, offset, bs, value, status='active', pointer_bytes=False):
        rows.append(f'node {name} {status} 0 1')
        receipt(name, kind, ty, offset, bs, value, pointer_bytes)

    def receipt(name, kind, ty, offset, bs, value, pointer_bytes=False):
        addr = 65472 + offset
        bytes_text = ','.join(f'{"alloc:0/"+str(i) if pointer_bytes else "none/-"}/{"-" if b is None else b}'
                              for i, b in enumerate(bs))
        rows.append(f'access {name} loc {kind} {"-" if kind == "R" else "0"} {ty} 0:{addr} 0 {addr} {bytes_text} {value}')

    access('byte-write', 'W', 'uc', 0, [42], 'i:42')
    access('same-write', 'W', 'uc', 0, [42], 'i:42')
    access('byte-read', 'R', 'uc', 0, [42], 'i:42')
    for name, kind in [('int-write', 'W'), ('int-read', 'R')]:
        access(name, kind, 'int', 4, [4, 3, 2, 1], 'i:16909060')
    access('byte-update', 'W', 'uc', 5, [170], 'i:170')
    access('updated-int', 'R', 'int', 4, [4, 170, 2, 1], 'i:16951812')
    for name, kind in [('ptr-write', 'W'), ('ptr-read', 'R')]:
        access(name, kind, 'ptr', 8, [196, 255, 0, 0, 0, 0, 0, 0], 'p:0:65476', pointer_bytes=True)
    for name, kind in [('float-write', 'W'), ('float-read', 'R')]:
        access(name, kind, 'double', 16, [0, 0, 0, 0, 0, 0, 0, 128], 'f:9223372036854775808')
    for name, kind in [('array-write', 'W'), ('array-read', 'R')]:
        access(name, kind, 'array', 24, [1, 2, 3, 4], 'a:i:1,i:2,i:3,i:4')
    access('unspec-write', 'W', 'int', 4, [None]*4, 'unspec:int')
    access('unspec-read', 'R', 'int', 4, [None]*4, 'unspec:int')
    access('trap-byte', 'W', 'uc', 0, [2], 'i:2')
    access('trap-read', 'R', 'bool', 0, [2], 'b:2', status='trap')
    access('unspec-bool-write', 'W', 'bool', 0, [None], 'unspec:bool')
    access('unspec-bool-read', 'R', 'bool', 0, [None], 'unspec:bool', status='trap')
    rows += ['node null-read null 0 0', 'node null-write null 0 0']
    rows += ['node locking-write active 1 1',
             'access locking-write loc W 1 uc 1:65408 1 65408 none/-/7 i:7',
             'node readonly-write readonly 1 0', 'node readonly-read active 1 1',
             'access readonly-read loc R - uc 1:65408 1 65408 none/-/7 i:7']
    access('before-failure', 'R', 'uc', 24, [1], 'i:1', status='after')
    rows.append('node two-before-failure after 0 2')
    receipt('two-before-failure', 'W', 'uc', 0, [9], 'i:9')
    receipt('two-before-failure', 'R', 'uc', 24, [1], 'i:1')
    rows += ['transport active killed nd guard branch step', f'stream {mode} {count} 0']
    return ('\n'.join(rows)+'\n').encode()


def validate(result, want):
    return result.returncode == 0 and result.stderr == b'' and result.stdout == want


def controls():
    want = expected(0, 'on')
    good = subprocess.CompletedProcess([], 0, want, b'')
    assert validate(good, want)
    mutations = [want.replace(b'access same-write', b'LOST same-write'),
                 want.replace(b'node trap-read trap 0 1', b'node trap-read trap 1 1'),
                 want.replace(b'alloc:0/0/196', b'none/0/196'),
                 want.replace(b'none/-/170', b'none/-/0'),
                 want.replace(b'nd guard branch step', b'nd guard step'),
                 want.replace(b'node before-failure after', b'node before-failure active')]
    for bad in mutations:
        assert bad != want and not validate(subprocess.CompletedProcess([], 0, bad, b''), want)
    assert not validate(subprocess.CompletedProcess([], 1, want, b''), want)
    assert not validate(subprocess.CompletedProcess([], 0, want, b'unexpected diagnostic'), want)


def build(command, cwd, name):
    with (OUT/name).open('wb') as log:
        subprocess.run(command, cwd=cwd, stdout=log, stderr=subprocess.STDOUT, check=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cost', action='store_true', help='also measure fixed-state streams, on and off')
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    controls()
    build(['tools/check_handwritten_sync.sh'], ROOT, 'sync.log')
    build(['tools/check_lem_sync.sh', '--check-lean'], ROOT, 'lem-sync.log')
    build(['dune', 'build', '--root', '.', 'backend/memory_probe/access_probe.exe',
           'backend/memory_probe/memory_probe.exe'], ROOT, 'native-build.log')
    build(['../scripts/capped', 'lake', 'build', 'memory-access-test'], ROOT/'lean_frontend', 'lean-build.log')
    native = ROOT/'_build/default/backend/memory_probe/access_probe.exe'
    lean = ROOT/'lean_frontend/.lake/build/bin/memory-access-test'
    report = {'schema': 1, 'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
              'diff_sha256': hashlib.sha256(subprocess.check_output(['git', 'diff', '--binary', 'HEAD'], cwd=ROOT)).hexdigest(),
              'binaries': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in [native, lean]},
              'sources': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest()
                          for p in [ROOT/'frontend/model/mem_common.lem', ROOT/'memory/concrete/impl_mem.ml',
                                    ROOT/'ocaml_frontend/memory_model.ml', ROOT/'lean_frontend/CerbMem.lean',
                                    ROOT/'backend/memory_probe/access_probe.ml', ROOT/'lean_frontend/test/Unit/MemoryAccess.lean',
                                    ROOT/'lean_frontend/test/Unit/MemoryAccessProofs.lean', Path(__file__).resolve()]},
              'runs': [], 'controls': 8}
    specs = [('native', native, [], 0, 'on'), ('lean-17', lean, ['17'], 0, 'on'),
             ('lean-64', lean, ['64'], 1000, 'on')]
    if args.cost:
        specs += [(engine, exe, fuel, count, mode)
                  for engine, exe, fuel in [('native', native, []), ('lean-17', lean, ['17'])]
                  for count in [100000, 200000, 400000] for mode in ['off', 'on'] for _ in range(3)]
    for index, (engine, exe, fuel, count, mode) in enumerate(specs):
        command = [str(exe), *fuel, str(count), mode]
        rss_file = OUT/f'{index}.rss'
        start = time.monotonic()
        # Skeptical review F3 (2026-09-26): the executables run under the per-test resident-memory
        # cap like every other harness (scripts/common.sh CAPPED_TEST: CERB_TEST_MEM_MAX, default 4G;
        # a breach exits 137 and fails validate()). /usr/bin/time runs INSIDE the cap so %M is the exe's.
        # timeout INSIDE the cap (review S1): a Python-level kill would SIGKILL `capped` itself and leak
        # its cgroup with the executable orphaned inside; the outer Python timeout is only a backstop.
        # On cap-less hosts or CERB_MEM_MAX=none `capped` warns on stderr, so this leg fails closed (S4).
        result = subprocess.run([str(ROOT / 'scripts' / 'capped'), 'timeout', '--kill-after=5', '60',
                                 '/usr/bin/time', '-f', '%M', '-o', str(rss_file), *command],
                                cwd=ROOT, capture_output=True, timeout=120,
                                env={**os.environ, 'LEAN_ABORT_ON_PANIC': '1',
                                     'CERB_MEM_MAX': os.environ.get('CERB_TEST_MEM_MAX', '4G')})
        elapsed = time.monotonic() - start
        (OUT/f'{index}.stdout').write_bytes(result.stdout)
        (OUT/f'{index}.stderr').write_bytes(result.stderr)
        passed = validate(result, expected(count, mode))
        report['runs'].append({'engine': engine, 'iterations': count, 'mode': mode, 'wall_s': elapsed,
                               'max_rss_kib': int(rss_file.read_text().strip().splitlines()[-1]),
                               'returncode': result.returncode, 'passed': passed})
        (OUT/'report.json').write_text(json.dumps(report, indent=2)+'\n')
        if not passed:
            raise SystemExit(f'FAIL {engine}: see {OUT}/{index}.stdout and .stderr (exact expectations in this script)')
    print(f'PASS memory access: {len(specs)} runs; primitive receipts, all ND constructors, erasure, draining; 8 instrument controls')
    print(f'Evidence: {OUT}/report.json')


if __name__ == '__main__':
    main()
