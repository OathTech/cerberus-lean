#!/usr/bin/env python3
"""End-to-end plants through the lane's main() with the REGISTER path monkeypatched
(the tree is never modified): a one-sided REAL pristine timeout (node) with its row
withheld; a forged fork-124 admitting row; a row naming an absent case; an empty
selection (--only no-match; --shard beyond the list); a missing manifest."""
import sys, json, io, contextlib
from pathlib import Path
ROOT = Path('/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/pristine-oracle-instrument')
sys.path.insert(0, str(ROOT / 'scripts'))
import test_upstream_oracle as t
W = ROOT / '.tmp/audit/plants/e2e'; W.mkdir(parents=True, exist_ok=True)
good = json.loads(t.REGISTER.read_text())
def run(name, register_cases, argv):
    p = W / (name + '.register.json'); p.write_text(json.dumps({'schema': 2, 'cases': register_cases}))
    t.REGISTER = p
    sys.argv = ['test_upstream_oracle.py', '--out', str(W / name), *argv]
    buf, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(buf), contextlib.redirect_stderr(err):
        try:
            rc = t.main()
        except SystemExit as e:
            rc = e.code
    out = buf.getvalue(); e = err.getvalue()
    tail = [l for l in (out + e).splitlines() if l.startswith(('Independent oracle', 'INDEPENDENT ORACLE', 'usage', 'test_upstream'))]
    rep = W / name / 'report.json'
    counts = json.loads(rep.read_text()).get('counts') if rep.exists() else None
    status = json.loads(rep.read_text()).get('status') if rep.exists() else None
    print(f'--- {name}: rc={rc} status={status} counts={counts}')
    for l in tail[-3:]: print('    ' + l)
    return rc, status, counts
r1 = run('node-row-withheld', {k: v for k, v in good['cases'].items() if k != 'multi_tu_tray/node'}, ['--only', r'^multi_tu_tray/node$'])
print('EXPECT rc 1, status failed, incomplete 1 ->', 'OK' if r1[0] == 1 and r1[1] == 'failed' and (r1[2] or {}).get('incomplete') == 1 else 'FAIL')
forged = dict(good['cases']['multi_tu_tray/node']); forged['upstream'] = dict(forged['upstream'], status=0); forged['fork'] = dict(forged['fork'], status=124)
r2 = run('forged-fork-124-row', {**good['cases'], 'multi_tu_tray/node': forged}, ['--only', r'^multi_tu_tray/node$'])
print('EXPECT rc 1, refused at load (INCOMPLETE), no rows ->', 'OK' if r2[0] == 1 and r2[1] == 'incomplete' and not r2[2] else 'FAIL')
r3 = run('row-names-absent-case', {**good['cases'], 'multi_tu_tray/does-not-exist': good['cases']['multi_tu_tray/node']}, ['--only', r'^minimal/001'])
print('EXPECT rc 1 INCOMPLETE (absent case) ->', 'OK' if r3[0] == 1 and r3[1] == 'incomplete' else 'FAIL')
r4 = run('empty-only', good['cases'], ['--only', r'zzz-no-such-case'])
print('EXPECT rc 1 INCOMPLETE (empty selection) ->', 'OK' if r4[0] == 1 and r4[1] == 'incomplete' else 'FAIL')
r5 = run('empty-shard', good['cases'], ['--shard', '1000/1000'])
print('EXPECT rc 1 INCOMPLETE (empty shard) ->', 'OK' if r5[0] == 1 and r5[1] == 'incomplete' else 'FAIL')
r6 = run('subset-with-row', good['cases'], ['--only', r'^multi_tu_tray/(node|arr-2-2-return|arr-incomplete-ptr-return)$'])
print('EXPECT rc 0 subset_passed reviewed_difference 3 ->', 'OK' if r6[0] == 0 and r6[1] == 'subset_passed' and (r6[2] or {}).get('reviewed_difference') == 3 else 'FAIL')
import os
os.environ['CERB_INDEPENDENT_MANIFEST'] = str(W / 'no-such-manifest.json')
r7 = run('missing-manifest', good['cases'], ['--only', r'^minimal/001', '--build-manifest', str(W / 'no-such-manifest.json')])
print('EXPECT rc 1 INCOMPLETE (missing manifest) ->', 'OK' if r7[0] == 1 and r7[1] == 'incomplete' else 'FAIL')
