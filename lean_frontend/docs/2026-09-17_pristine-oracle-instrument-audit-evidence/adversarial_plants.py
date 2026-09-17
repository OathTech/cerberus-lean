#!/usr/bin/env python3
"""Auditor's adversarial plants against scripts/test_upstream_oracle.py at 586b550b8.
Hermetic compare()/loader/regex plants + REAL process plants (capture(), the two oracles).
Nothing in the tree is modified; all files under .tmp/audit/plants/work/."""
import sys, os, json, hashlib, subprocess, shutil, re
from pathlib import Path
ROOT = Path('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument')
sys.path.insert(0, str(ROOT / 'scripts'))
import test_upstream_oracle as t

OUT = ROOT / '.tmp/audit/plants/work'
shutil.rmtree(OUT, ignore_errors=True); OUT.mkdir(parents=True)
results = []
def check(name, got, want, detail=''):
    ok = got == want
    results.append((name, ok))
    print(f'{"PLANT OK  " if ok else "PLANT FAIL"} {name}: got {got!r}, want {want!r}' + (f' — {detail}' if detail else ''), flush=True)
def note(name, got, detail=''):
    print(f'PLANT NOTE {name}: {got!r}' + (f' — {detail}' if detail else ''), flush=True)

empty = hashlib.sha256(b'').hexdigest()
def rec(status, so='a'*64, diag=empty, cap='nonexistent'):
    return {'status': status, 'stdout_sha256': so, 'diagnostic_sha256': diag, 'capture': str(OUT / cap)}
done, other = rec(0), rec(0, so='b'*64)
timeout_, killed = rec(124, so=empty), rec(137, so=empty)
register = json.loads(t.REGISTER.read_text())['cases']
node_row = register['multi_tu_tray/node']

print('\n## A. hermetic compare() matrix (auditor-written)')
check('A1 one-sided pristine timeout, no row', t.compare(timeout_, done, 'batch', None)[0], 'incomplete')
forged = {'class': 'shared-model-fix', 'citation': 'x', 'rationale': 'forged', 'upstream': t.signature(done), 'fork': t.signature(timeout_)}
check('A2 one-sided FORK timeout WITH forged admitting row (compare level)', t.compare(done, timeout_, 'batch', forged)[0], 'incomplete')
check('A3a 137 pristine', t.compare(killed, done, 'batch', None)[0], 'incomplete')
check('A3b 137 fork', t.compare(done, killed, 'batch', None)[0], 'incomplete')
check('A3c 137 fork with forged row', t.compare(done, killed, 'batch', dict(forged, fork=t.signature(killed)))[0], 'incomplete')
check('A3d 137 both', t.compare(killed, killed, 'batch', None)[0], 'incomplete')
check('A4 both 124 no row', t.compare(timeout_, timeout_, 'batch', None)[0], 'matching_incomplete')
# The registered case `node` (pristine 124 / fork 0 pinned) if the FORK also times out:
both_node = t.compare(timeout_, timeout_, 'batch', node_row)[0]
note('A5 registered node row, fork ALSO 124 (pin fork.status=0 NOT reproduced)', both_node,
     'charter O1 stale-row rule says a row whose case no longer differs is RED; the code returns this (non-failing)')
check('A6 139 (SIGSEGV) both sides, same shas', t.compare(rec(139, so=empty, diag='c'*64), rec(139, so=empty, diag='c'*64), 'batch', None)[0] in ('difference',), True, 'fail-closed: not in the matching_failure status set')

print('\n## B. REAL capture(): status mapping for kills and timeouts')
k = t.capture(OUT / 'kill9', ['sh', '-c', 'kill -9 $$'], dict(os.environ), 30)
check('B1 real SIGKILL of the child -> 137', k['status'], 137)
s = t.capture(OUT / 'slow', ['sleep', '5'], dict(os.environ), 1)
check('B2 real timeout -> 124', s['status'], 124)
check('B3 real 137 vs completed -> incomplete', t.compare(k, done, 'batch', None)[0], 'incomplete')
check('B4 real 124 vs completed (no row) -> incomplete', t.compare(s, done, 'batch', None)[0], 'incomplete')
check('B5 real 124 vs real 124 -> matching_incomplete', t.compare(s, s, 'batch', None)[0], 'matching_incomplete')
sg = t.capture(OUT / 'segv', ['sh', '-c', 'kill -SEGV $$'], dict(os.environ), 30)
note('B6 real SIGSEGV of the child -> status', sg['status'], 'compare treats as completed; both-sides identical -> difference (fail-closed)')

print('\n## C. REAL both-crash captures from the two oracles (immaculate/nolibc/g4-bswap64-overflow)')
manifest = t.validate_build(ROOT / '.validation-foundations/independent-oracle-v2/manifest.json')
pin = {'NO_COLOR': '1', 'TERM': 'dumb'}
env_up = {**os.environ, **manifest['environment'], **pin}
env_fk = {**os.environ, **pin}
up_bin = manifest['artifacts']['oracle']['path']; up_rt = manifest['artifacts']['runtime']['root']
fk_bin = str(ROOT / '_build/default/backend/driver/main.exe'); fk_rt = str(ROOT / '_build/install/default')
src = 'tests/immaculate/nolibc/g4-bswap64-overflow.c'
a = t.capture(OUT / 'g4-up', [up_bin, '--runtime=' + up_rt, '--exec', '--batch', '--nolibc', src], env_up, 60)
b = t.capture(OUT / 'g4-fk', [fk_bin, '--runtime=' + fk_rt, '--exec', '--batch', '--nolibc', src], env_fk, 60)
print(f'   pristine status {a["status"]} raw-stderr {a["stderr_sha256"][:12]} diag {a["diagnostic_sha256"][:12]}; fork status {b["status"]} raw {b["stderr_sha256"][:12]} diag {b["diagnostic_sha256"][:12]}')
check('C1 real both-crash pair (frame positions differ) -> matching_failure', t.compare(a, b, 'batch', None)[0], 'matching_failure')
check('C1b raw stderr differs while diagnostic sha agrees', a['stderr_sha256'] != b['stderr_sha256'] and a['diagnostic_sha256'] == b['diagnostic_sha256'], True)
fk_err = Path(b['capture'] + '.stderr').read_bytes()
lines = fk_err.split(b'\n')
# payload = the first line after the envelope header
pi = next(i for i, l in enumerate(lines) if l.startswith(b'cerberus: internal error')) + 1
print('   exception payload line:', lines[pi][:120])
mut = lines[:]; mut[pi] = mut[pi][:-1] + (b'x' if mut[pi][-1:] != b'x' else b'y')   # one character changed
c = t.synthetic_record(OUT / 'g4-fk-text1', b['status'], b'', b'\n'.join(mut))
check('C2 exception TEXT differs by ONE character -> difference', t.compare(a, c, 'batch', None)[0], 'difference')
# one character changed inside a NUMBER of the payload? (e.g. an offset) -> also difference
mut2 = lines[:]; m = re.search(rb'[0-9]', mut2[pi])
if m:
    mut2[pi] = mut2[pi][:m.start()] + (b'7' if m.group() != b'7' else b'8') + mut2[pi][m.end():]
    d = t.synthetic_record(OUT / 'g4-fk-text2', b['status'], b'', b'\n'.join(mut2))
    check('C3 a DIGIT in the exception payload changed -> difference', t.compare(a, d, 'batch', None)[0], 'difference')
# the FILE NAME inside a frame changed
fi = next(i for i, l in enumerate(lines) if b' in file "' in l)
mut3 = lines[:]; mut3[fi] = mut3[fi].replace(b' in file "', b' in file "X', 1)
e = t.synthetic_record(OUT / 'g4-fk-file', b['status'], b'', b'\n'.join(mut3))
check('C4 frame FILE name differs -> difference', t.compare(a, e, 'batch', None)[0], 'difference')
# a frame DROPPED (frame count differs)
mut4 = lines[:fi] + lines[fi+1:]
f = t.synthetic_record(OUT / 'g4-fk-drop', b['status'], b'', b'\n'.join(mut4))
check('C5 one frame dropped -> difference', t.compare(a, f, 'batch', None)[0], 'difference')
# stdout beside identical crashes
g = t.synthetic_record(OUT / 'g4-fk-stdout', b['status'], b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n', fk_err)
check('C6 stdout beside an identical crash -> difference', t.compare(b, g, 'batch', None)[0], 'difference')
# position OUTSIDE a frame line: same crash on both sides plus a non-frame diagnostic line with a position
h1 = t.synthetic_record(OUT / 'g4-nf1', 125, b'', b'tests/x.c:3:5: error: bad thing at line 3, characters 4-5\n' + fk_err)
h2 = t.synthetic_record(OUT / 'g4-nf2', 125, b'', b'tests/x.c:4:5: error: bad thing at line 4, characters 4-5\n' + fk_err)
check('C7 position in a Cerberus-style diagnostic line (outside a frame) -> difference', t.compare(h1, h2, 'batch', None)[0], 'difference')
i1 = t.synthetic_record(OUT / 'g4-cf1', 125, b'', fk_err + b'Called from Foo.bar, line 3, characters 4-5\n')
i2 = t.synthetic_record(OUT / 'g4-cf2', 125, b'', fk_err + b'Called from Foo.bar, line 4, characters 4-5\n')
check('C8 `Called from` line WITHOUT ` in file "…"` -> not normalised -> difference', t.compare(i1, i2, 'batch', None)[0], 'difference')
j1 = t.synthetic_record(OUT / 'g4-pl1', 125, b'', b'cerberus: internal error, uncaught exception:\n          Failure("boom in file \\"x.ml\\", line 3, characters 1-2")\n' + fk_err)
j2 = t.synthetic_record(OUT / 'g4-pl2', 125, b'', b'cerberus: internal error, uncaught exception:\n          Failure("boom in file \\"x.ml\\", line 4, characters 1-2")\n' + fk_err)
check('C9 position inside a Failure(...) payload line -> difference', t.compare(j1, j2, 'batch', None)[0], 'difference')
k1 = t.synthetic_record(OUT / 'g4-tr1', 125, b'', fk_err + b'Called from Foo.bar in file "x.ml", line 3, characters 4-5 (extra)\n')
k2 = t.synthetic_record(OUT / 'g4-tr2', 125, b'', fk_err + b'Called from Foo.bar in file "x.ml", line 4, characters 4-5 (extra)\n')
check('C10 frame-like line with trailing text after the position -> not normalised -> difference', t.compare(k1, k2, 'batch', None)[0], 'difference')
# stdout is never projected: identical crash stderr, stdout differing only in a frame-shaped line
l1 = t.synthetic_record(OUT / 'g4-so1', 1, b'Called from Foo.bar in file "x.ml", line 3, characters 4-5\n', fk_err)
l2 = t.synthetic_record(OUT / 'g4-so2', 1, b'Called from Foo.bar in file "x.ml", line 4, characters 4-5\n', fk_err)
check('C11 batch: stdout differing only by a frame-shaped position -> difference (stdout never projected)', t.compare(l1, l2, 'batch', None)[0], 'difference')
m1 = t.synthetic_record(OUT / 'g4-core1', 0, b'proc main: Called from Foo.bar in file "x.ml", line 3, characters 4-5\n', b'')
m2 = t.synthetic_record(OUT / 'g4-core2', 0, b'proc main: Called from Foo.bar in file "x.ml", line 4, characters 4-5\n', b'')
check('C12 core kind: stdout differing only by a frame-shaped position -> difference', t.compare(m1, m2, 'core', None)[0], 'difference')
check('C13 stdout projected anywhere in record_of?', 'project_diagnostics(prefix.with_suffix(\'.stdout\')' in (ROOT / 'scripts/test_upstream_oracle.py').read_text(), False)

print('\n## D. silent success / malformed / missing captures')
n1 = t.synthetic_record(OUT / 'silent1', 0, b'', b'')
check('D1 batch both status 0, empty stdout+stderr (silent success) -> difference', t.compare(n1, n1, 'batch', None)[0], 'difference')
check('D2 core kind silent success -> difference', t.compare(n1, n1, 'core', None)[0], 'difference')
check('D3 typecheck kind status 0 empty stdout -> interface_agreement (declared behaviour)', t.compare(n1, n1, 'typecheck', None)[0], 'interface_agreement')
o1 = t.synthetic_record(OUT / 'malf1', 125, b'', fk_err); Path(str(OUT / 'malf1') + '.status').write_text('abc\n')
note('D4 record says 125 but the .status FILE is garbage (tampered capture) ->', t.compare(o1, b, 'batch', None)[0], 'record-vs-file inconsistency is not detected by compare()')
miss_a = dict(b, capture=str(OUT / 'does-not-exist-a')); miss_b = dict(b, capture=str(OUT / 'does-not-exist-b'))
try:
    got = t.compare(miss_a, miss_b, 'batch', None)[0]
except OSError as exc:
    got = f'raised OSError ({type(exc).__name__}) -> main() catches -> INCOMPLETE rc 1'
check('D5 both capture files missing, identical records -> not a passing class', got in ('semantic_agreement', 'matching_failure', 'interface_agreement'), False, got)
miss_c = dict(a, capture=str(OUT / 'does-not-exist-c'))
try:
    got = t.compare(miss_c, miss_b, 'batch', None)[0]
except OSError as exc:
    got = f'raised OSError'
check('D6 capture files missing, records differ -> difference', got, 'difference')

print('\n## E. loader: citations and statuses (auditor extras beyond the 16 worker plants)')
good = json.loads(t.REGISTER.read_text())
def try_load(mut, name):
    d = json.loads(json.dumps(good)); mut(d)
    p = OUT / (name + '.json'); p.write_text(json.dumps(d))
    try:
        t.load_register(p); return 'ACCEPTED'
    except ValueError as exc:
        return 'REJECTED: ' + str(exc)[:110]
first = next(iter(good['cases']))
check('E1 nonexistent citation file -> rejected', try_load(lambda d: d['cases'][first].update(citation='lean_frontend/docs/no-such-file.md'), 'e1').startswith('REJECTED'), True)
check('E2 pristine 124 under diagnostic-text -> rejected', try_load(lambda d: (d['cases'][first].update({'class': 'diagnostic-text'}), d['cases'][first]['upstream'].update(status=124)), 'e2').startswith('REJECTED'), True)
check('E3 fork 124 under shared-model-fix (forged admitting row) -> rejected at load', try_load(lambda d: d['cases'][first]['fork'].update(status=124), 'e3').startswith('REJECTED'), True)
check('E4 citation to a DIRECTORY -> rejected', try_load(lambda d: d['cases'][first].update(citation='lean_frontend/docs'), 'e4').startswith('REJECTED'), True)
check('E5 absolute-path citation -> rejected', try_load(lambda d: d['cases'][first].update(citation=str(ROOT / 'README.md')), 'e5').startswith('REJECTED'), True)
note('E6 citation escaping the repo via `..` (../lem-lean/README.md exists in the container)', try_load(lambda d: d['cases'][first].update(citation='../lem-lean/README.md'), 'e6'))
(OUT / 'untracked-citation.md').write_text('not a repo record\n')
note('E7 citation to an UNTRACKED, gitignored file under .tmp/', try_load(lambda d: d['cases'][first].update(citation='.tmp/audit/plants/work/untracked-citation.md'), 'e7'))
note('E8 citation with a line range beyond the file length (:99999)', try_load(lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md:99999'), 'e8'))
check('E9 status as bool True -> rejected', try_load(lambda d: d['cases'][first]['upstream'].update(status=True), 'e9').startswith('REJECTED'), True)
check('E10 uppercase sha -> rejected', try_load(lambda d: d['cases'][first]['fork'].update(stdout_sha256='A'*64), 'e10').startswith('REJECTED'), True)

print('\n## F. FRAME_POSITION regex adversarial lines (normalised? = line changed by project_diagnostics)')
def normalised(line: bytes) -> bool:
    return t.project_diagnostics(line + b'\n') != line + b'\n'
for label, line, want in [
    ('F1 standard frame', b'          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33', True),
    ('F2 lines range frame', b'Called from Dune__exe__Main.cerberus in file "backend/driver/main.ml", lines 261-287, characters 8-15', True),
    ('F3 inlined frame', b'Called from Lem_list.map in file "lem_list.ml" (inlined), line 178, characters 22-39', True),
    ('F4 primitive-operation frame', b'Raised by primitive operation at Foo.bar in file "x.ml", line 3, characters 4-5', True),
    ('F5 re-raised frame', b'Re-raised at Foo.bar in file "x.ml", line 3, characters 4-5', True),
    ('F6 Cerberus diagnostic with source loc', b'tests/ci/0120.c:3:5: error: something in file "x", line 3, characters 4-5', False),
    ('F7 batch Error line on stderr', b'Error {msg: "ill-formed program: in file "x", line 3, characters 4-5"}', False),
    ('F8 Lean panic line', b'PANIC at CerbMem.arrayShiftPtrval Cerberus.Mem:123:45: TODO in file "x", line 3, characters 4-5', False),
    ('F9 Failure payload containing frame text', b'          Failure("Raised at X in file \\"y\\", line 3, characters 4-5")', False),
    ('F10 old-style frame without function (`Raised at file "…"`)', b'Raised at file "stdlib.ml", line 29, characters 17-33', False),
    ('F11 frame with trailing text', b'Called from X in file "y", line 3, characters 4-5 (inlined)', False),
    ('F12 CRLF-terminated frame', b'Called from X in file "y", line 3, characters 4-5\r', False),
    ('F13 keyword not at line start', b'note: Called from X in file "y", line 3, characters 4-5', False),
    ('F14 Time spent trailer', b'Time spent: 0.023220 seconds', True),
    ('F15 Time spent with extra text', b'Time spent: 0.023220 seconds (user)', False),
]:
    check(label, normalised(line), want)
check('F16 stdout untouched by project_diagnostics call sites', (ROOT / 'scripts/test_upstream_oracle.py').read_text().count('project_diagnostics(') , 2, 'definition + the single .stderr call in record_of')

print('\n## G. does a C program\'s own exit value leak into the oracle\'s status under --batch? (124/137 ambiguity)')
for val in (124, 137, 1):
    csrc = OUT / f'ret{val}.c'; csrc.write_text(f'int main(void) {{ return {val}; }}\n')
    ra = t.capture(OUT / f'ret{val}-up', [up_bin, '--runtime=' + up_rt, '--exec', '--batch', '--nolibc', '--mode=exhaustive', str(csrc)], env_up, 30)
    rb = t.capture(OUT / f'ret{val}-fk', [fk_bin, '--runtime=' + fk_rt, '--exec', '--batch', '--nolibc', '--mode=exhaustive', str(csrc)], env_fk, 30)
    so = Path(rb['capture'] + '.stdout').read_bytes().strip()
    note(f'G{val} main returns {val}: pristine status {ra["status"]}, fork status {rb["status"]}, fork stdout {so[:80]!r}; compare ->', t.compare(ra, rb, 'batch', None)[0])

print('\n## SUMMARY')
fails = [n for n, ok in results if not ok]
print(f'{len(results)} checks, {len(fails)} FAIL: {fails}')
