#!/usr/bin/env python3
"""AUDITOR hermetic plants against scripts/test_upstream_oracle.py's HEADER_POSITION extension (C1b).
Each plant: a pristine/fork stderr pair (status 125, stdout empty unless stated) -> compare() class.
Also re-derives the PRE-C1b projection (TIME_SPENT + FRAME_POSITION only) to show what changed."""
import importlib.util, re, sys, tempfile, hashlib
from pathlib import Path
ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'scripts'))
spec = importlib.util.spec_from_file_location('lane', ROOT / 'scripts/test_upstream_oracle.py')
lane = importlib.util.module_from_spec(spec); sys.modules['lane'] = lane; spec.loader.exec_module(lane)

def pre_c1b(stderr: bytes) -> bytes:
    return lane.FRAME_POSITION.sub(rb'\1, line N, characters A-B', lane.TIME_SPENT.sub(b'', stderr))

HDR = (b'cerberus: internal error, uncaught exception:\n'
       b'          File "memory/concrete/impl_mem.ml", line 2659, characters 16-22: Assertion failed\n'
       b'          Raised at Cerb_frontend__Impl_mem.Concrete.memcmp.get_bytes.(fun) in file "memory/concrete/impl_mem.ml", line 2659, characters 16-28\n'
       b'          Called from Cerb_frontend__Nondeterminism.nd_bind.(fun) in file "ocaml_frontend/generated/nondeterminism.ml", line 66, characters 26-31\n')
def R(s, old, new): return s.replace(old, new)

plants = []  # (name, left_stderr, right_stderr, left_stdout, right_stdout, lstatus, rstatus, want)
plants.append(('H1 header position only', HDR, R(HDR, b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 125, 125, 'matching_failure'))
plants.append(('H2 header + frame positions', HDR, R(R(HDR, b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'line 2659, characters 16-28', b'line 2664, characters 16-28'), b'', b'', 125, 125, 'matching_failure'))
plants.append(('H3 header PATH differs', HDR, R(HDR, b'File "memory/concrete/impl_mem.ml"', b'File "memory/vip/impl_mem.ml"'), b'', b'', 125, 125, 'difference'))
plants.append(('H4 header TEXT differs (Assertion failed vs Pattern matching failed)', HDR, R(HDR, b'Assertion failed', b'Pattern matching failed'), b'', b'', 125, 125, 'difference'))
plants.append(('H5 exception KIND differs (header vs Failure payload)', HDR, R(HDR, b'File "memory/concrete/impl_mem.ml", line 2659, characters 16-22: Assertion failed', b'Failure("memcmp: get_bytes")'), b'', b'', 125, 125, 'difference'))
plants.append(('H6 header-shaped line in STDOUT, position differs, stderr identical', HDR, HDR, b'File "a.ml", line 1, characters 1-2: Assertion failed\n', b'File "a.ml", line 2, characters 1-2: Assertion failed\n', 125, 125, 'difference'))
plants.append(('H7 Cerberus diagnostic quoting a position (not header-shaped) differs', b'tests/ci/x.c:3:5: error: bad thing at line 3, characters 4-5\n', b'tests/ci/x.c:3:5: error: bad thing at line 4, characters 4-5\n', b'', b'', 1, 1, 'difference'))
plants.append(('H8 frame position only (pre-existing normalisation; control)', HDR, R(HDR, b'line 66, characters 26-31', b'line 64, characters 26-31'), b'', b'', 125, 125, 'matching_failure'))
plants.append(('H9 header `lines N-M` vs `line N` (regex alternation)', HDR, R(HDR, b'line 2659, characters 16-22:', b'lines 2659-2660, characters 16-22:'), b'', b'', 125, 125, 'matching_failure'))
plants.append(('H10 header TEXT itself contains a position that differs', R(HDR, b'Assertion failed', b'Assertion failed near line 7'), R(HDR, b'Assertion failed', b'Assertion failed near line 8'), b'', b'', 125, 125, 'difference'))
plants.append(('H11 header not at line start (prefixed) differing in position', R(HDR, b'          File', b'cerberus: File'), R(R(HDR, b'          File', b'cerberus: File'), b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 125, 125, 'difference'))
SAMEFN_L = (b'cerberus: internal error, uncaught exception:\n'
            b'          File "memory/concrete/impl_mem.ml", line 2659, characters 16-22: Assertion failed\n'
            b'          Raised at Cerb_frontend__Impl_mem.Concrete.memcmp.get_bytes.(fun) in file "memory/concrete/impl_mem.ml", line 2659, characters 16-28\n')
SAMEFN_R = (b'cerberus: internal error, uncaught exception:\n'
            b'          File "memory/concrete/impl_mem.ml", line 2701, characters 10-16: Assertion failed\n'
            b'          Raised at Cerb_frontend__Impl_mem.Concrete.memcmp.get_bytes.(fun) in file "memory/concrete/impl_mem.ml", line 2701, characters 10-22\n')
plants.append(('H12 TWO DIFFERENT assert sites in the SAME function/file (residual blind spot)', SAMEFN_L, SAMEFN_R, b'', b'', 125, 125, 'matching_failure'))
plants.append(('H13 header line with CRLF ending differing in position', R(HDR, b'Assertion failed\n', b'Assertion failed\r\n'), R(R(HDR, b'Assertion failed\n', b'Assertion failed\r\n'), b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 125, 125, 'difference'))
plants.append(('H14 header position only but stdout NON-empty identical', HDR, R(HDR, b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'x\n', b'x\n', 125, 125, 'difference'))
plants.append(('H15 header position only but statuses differ (125 vs 134)', HDR, R(HDR, b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 125, 134, 'difference'))
plants.append(('H16 header position only, status 1 (front-end failure class)', HDR, R(HDR, b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 1, 1, 'matching_failure'))
plants.append(('H17 header position only, status 0 (not a failure status)', HDR, R(HDR, b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 0, 0, 'difference'))
plants.append(('H18 header where the path has spaces/unicode, position differs', R(HDR, b'memory/concrete/impl_mem.ml', b'mem ory/\xc3\xa9/impl.ml'), R(R(HDR, b'memory/concrete/impl_mem.ml', b'mem ory/\xc3\xa9/impl.ml'), b'line 2659, characters 16-22:', b'line 2664, characters 16-22:'), b'', b'', 125, 125, 'matching_failure'))

fails = 0
with tempfile.TemporaryDirectory(dir=ROOT / '.tmp/audit/plants') as tmp:
    tmp = Path(tmp)
    for i, (name, ls, rs, lo, ro, lst, rst, want) in enumerate(plants):
        a = lane.synthetic_record(tmp / f'l{i}', lst, lo, ls)
        b = lane.synthetic_record(tmp / f'r{i}', rst, ro, rs)
        got, why = lane.compare(a, b, 'batch', None)
        pre = 'same' if hashlib.sha256(pre_c1b(ls)).hexdigest() == hashlib.sha256(pre_c1b(rs)).hexdigest() else 'differs'
        post = 'same' if a['diagnostic_sha256'] == b['diagnostic_sha256'] else 'differs'
        ok = got == want
        fails += (not ok)
        print(f"{'PLANT OK  ' if ok else 'PLANT FAIL'} {name}: got {got!r}, want {want!r}; projected stderr pre-C1b={pre} post-C1b={post}")
print(f'{len(plants)} plants, {fails} FAIL')
src = (ROOT / 'scripts/test_upstream_oracle.py').read_text()
print('project_diagnostics( occurrences:', src.count('project_diagnostics('), '->', [l.strip()[:90] for l in src.splitlines() if 'project_diagnostics(' in l])
print('HEADER_POSITION:', lane.HEADER_POSITION.pattern)
