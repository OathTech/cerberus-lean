#!/usr/bin/env python3
"""Auditor's DELTA plants against scripts/test_upstream_oracle.py at 46e5d2f19 (O6 fixes).
M1: registered cases judged ONLY by their row; unregistered both-124 still matching_incomplete.
N1: citation_exists — untracked file, `..` path, out-of-range line, inverted range, git unusable."""
import sys, os, json, hashlib, subprocess, shutil, tempfile
from pathlib import Path
ROOT = Path('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument')
sys.path.insert(0, str(ROOT / 'scripts'))
import test_upstream_oracle as t
print('lane script sha256:', hashlib.sha256((ROOT / 'scripts/test_upstream_oracle.py').read_bytes()).hexdigest()[:16])
OUT = ROOT / '.tmp/audit-o6/plants/work'; shutil.rmtree(OUT, ignore_errors=True); OUT.mkdir(parents=True)
results = []
def check(name, got, want, detail=''):
    ok = got == want; results.append((name, ok))
    print(f'{"PLANT OK  " if ok else "PLANT FAIL"} {name}: got {got!r}, want {want!r}' + (f' — {detail}' if detail else ''), flush=True)
empty = hashlib.sha256(b'').hexdigest()
def rec(status, so='a'*64, diag=empty): return {'status': status, 'stdout_sha256': so, 'diagnostic_sha256': diag, 'capture': str(OUT / 'none')}
done, other, timeout_, killed = rec(0), rec(0, so='b'*64), rec(124, so=empty), rec(137, so=empty)
register = json.loads(t.REGISTER.read_text())['cases']
node = register['multi_tu_tray/node']            # pins pristine 124 / fork 0
arr = register['multi_tu_tray/arr-2-2-return']   # pins pristine 1 / fork 0
node_up = {**node['upstream'], 'capture': str(OUT / 'n')}; node_fk = {**node['fork'], 'capture': str(OUT / 'n')}
arr_up = {**arr['upstream'], 'capture': str(OUT / 'n')}; arr_fk = {**arr['fork'], 'capture': str(OUT / 'n')}

print('\n## M1 — registered cases are judged ONLY by their row; unregistered both-124 unchanged')
check('M1.1 registered node row, both signatures reproduce -> reviewed_difference', t.compare(node_up, node_fk, 'batch', node)[0], 'reviewed_difference')
check('M1.2 registered node row, FORK also 124 (the audit A5 case) -> difference', t.compare(node_up, {**timeout_, 'capture': 'x'}, 'batch', node)[0], 'difference')
check('M1.3 registered node row, fork 124 with pristine completing -> difference', t.compare(done, timeout_, 'batch', node)[0], 'difference')
check('M1.4 registered arr row, both 124 -> difference', t.compare(timeout_, timeout_, 'batch', arr)[0], 'difference')
check('M1.5 registered arr row, pristine now 124 (pin moved) -> difference', t.compare(timeout_, arr_fk, 'batch', arr)[0], 'difference')
check('M1.6 registered arr row, fork sha moved -> difference', t.compare(arr_up, {**arr_fk, 'stdout_sha256': 'c'*64}, 'batch', arr)[0], 'difference')
check('M1.7 registered arr row, pair now AGREES (stale row) -> difference', t.compare(arr_fk, arr_fk, 'batch', arr)[0], 'difference')
check('M1.8 registered row + 137 pristine -> incomplete (137 above everything)', t.compare(killed, arr_fk, 'batch', arr)[0], 'incomplete')
check('M1.9 registered row + 137 fork -> incomplete', t.compare(arr_up, killed, 'batch', arr)[0], 'incomplete')
diag_row = {**node, 'class': 'diagnostic-text'}
check('M1.10 pristine 124 admitted only via resource/shared-model-fix (compare-level too) -> incomplete', t.compare(node_up, node_fk, 'batch', diag_row)[0], 'incomplete')
check('M1.11 UNREGISTERED both 124 -> matching_incomplete', t.compare(timeout_, timeout_, 'batch', None)[0], 'matching_incomplete')
check('M1.12 UNREGISTERED fork-only 124 -> incomplete', t.compare(done, timeout_, 'batch', None)[0], 'incomplete')
check('M1.13 UNREGISTERED pristine-only 124 -> incomplete', t.compare(timeout_, done, 'batch', None)[0], 'incomplete')
check('M1.14 UNREGISTERED both 137 -> incomplete', t.compare(killed, killed, 'batch', None)[0], 'incomplete')
check('M1.15 empty-dict row (not None) is treated as registered -> difference (fail-closed)', t.compare(timeout_, timeout_, 'batch', {})[0], 'difference')
# real processes: both-124 unregistered vs registered
s1 = t.capture(OUT / 'slow1', ['sleep', '5'], dict(os.environ), 1); s2 = t.capture(OUT / 'slow2', ['sleep', '5'], dict(os.environ), 1)
check('M1.16 REAL both-124, unregistered -> matching_incomplete', t.compare(s1, s2, 'batch', None)[0], 'matching_incomplete')
check('M1.17 REAL both-124, registered (node row) -> difference', t.compare(s1, s2, 'batch', node)[0], 'difference')

print('\n## N1 — citation_exists')
good = json.loads(t.REGISTER.read_text()); first = next(iter(good['cases']))
def try_load(mut, name):
    d = json.loads(json.dumps(good)); mut(d); p = OUT / (name + '.json'); p.write_text(json.dumps(d))
    try: t.load_register(p); return 'ACCEPTED'
    except ValueError as exc: return 'REJECTED: ' + str(exc)[:100]
(ROOT / '.tmp/audit-o6/plants/work/untracked.md').write_text('scratch\n')
check('N1.1 untracked ignored file -> rejected', try_load(lambda d: d['cases'][first].update(citation='.tmp/audit-o6/plants/work/untracked.md'), 'n11').startswith('REJECTED'), True)
# an untracked but NOT ignored file inside a tracked directory
stray = ROOT / 'lean_frontend/docs/upstream-tray/zz-auditor-stray-untracked.md'; stray.write_text('stray\n')
try:
    check('N1.2 untracked NON-ignored file in a tracked dir -> rejected', try_load(lambda d: d['cases'][first].update(citation='lean_frontend/docs/upstream-tray/zz-auditor-stray-untracked.md'), 'n12').startswith('REJECTED'), True)
finally:
    stray.unlink()
check('N1.3 `..` path -> rejected', try_load(lambda d: d['cases'][first].update(citation='../lem-lean/README.md'), 'n13').startswith('REJECTED'), True)
check('N1.4 `..` inside the path -> rejected', try_load(lambda d: d['cases'][first].update(citation='scripts/../scripts/LADDER.md'), 'n14').startswith('REJECTED'), True)
check('N1.5 out-of-range line -> rejected', try_load(lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md:99999'), 'n15').startswith('REJECTED'), True)
check('N1.6 inverted range -> rejected', try_load(lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md:9-3'), 'n16').startswith('REJECTED'), True)
check('N1.7 line 0 -> rejected', try_load(lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md:0'), 'n17').startswith('REJECTED'), True)
n = len((ROOT / 'tests/multi_tu_tray/README.md').read_text().splitlines())
check(f'N1.8 last line ({n}) -> accepted', try_load(lambda d: d['cases'][first].update(citation=f'tests/multi_tu_tray/README.md:{n}'), 'n18'), 'ACCEPTED')
check(f'N1.9 line {n+1} -> rejected', try_load(lambda d: d['cases'][first].update(citation=f'tests/multi_tu_tray/README.md:{n+1}'), 'n19').startswith('REJECTED'), True)
check('N1.10 tracked file with #anchor -> accepted', try_load(lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md#the-projection'), 'n110'), 'ACCEPTED')
check('N1.11 the committed register loads', try_load(lambda d: None, 'n111'), 'ACCEPTED')
check('N1.12 tracked but DELETED-in-worktree file -> rejected (is_file first)', try_load(lambda d: d['cases'][first].update(citation='lean_frontend/docs/upstream-tray/00-does-not-exist.md'), 'n112').startswith('REJECTED'), True)
# git unusable -> must raise (fail closed), never ACCEPT
env = dict(os.environ); env['PATH'] = '/nonexistent'
code = ("import sys; sys.path.insert(0, %r); import test_upstream_oracle as t\n"
        "try:\n    print('RESULT', t.citation_exists('tests/multi_tu_tray/README.md'))\n"
        "except OSError as e:\n    print('RAISED OSError', type(e).__name__)") % str(ROOT / 'scripts')
r = subprocess.run([sys.executable, '-c', code], capture_output=True, text=True, env=env, cwd=ROOT)
last = (r.stdout.strip().splitlines() or [''])[-1]
check('N1.13 git unusable (PATH empty) -> raises OSError (lane INCOMPLETE), never ACCEPTED', last.startswith('RAISED OSError'), True, last or r.stderr.strip()[-200:])

print('\n## SUMMARY'); fails = [n for n, ok in results if not ok]; print(f'{len(results)} checks, {len(fails)} FAIL: {fails}')
