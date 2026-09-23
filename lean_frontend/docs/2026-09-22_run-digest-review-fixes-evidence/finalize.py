from pathlib import Path
import hashlib,json,shutil,subprocess
root=Path('.tmp/run-digest-review');ev=Path('lean_frontend/docs/2026-09-22_run-digest-review-fixes-evidence')
r=json.loads((root/'fast/report.json').read_text())
assert r['status']=='passed' and r['source_unchanged'] and r['selection_complete']
assert len(r['lanes'])==16 and all(x['status']=='passed' for x in r['lanes'])
assert not r['artifact_issues'],r['artifact_issues']
snap=json.loads((root/'frozen-source.json').read_text())
assert all(hashlib.sha256(Path(p).read_bytes()).hexdigest()==h for p,h in snap.items())
assert subprocess.check_output(['git','branch','--show-current'],text=True).strip()=='arc/run-digest'
for p in ['scripts/failure_reach_register.txt','scripts/unsafebaseio_allowlist.txt','scripts/check_theorem_axioms.sh','lean_frontend/handwritten_copy.manifest','lean_frontend/CerberusFresh.lean','lean_frontend/CoreParser.lean','scripts/upstream_oracle_differences.json']:
 assert Path(p).read_bytes()==subprocess.check_output(['git','show','24f19d6f5:'+p]),p
for name in ['report.json','summary.txt']:shutil.copyfile(root/'fast'/name,ev/name)
for name in ['steps.jsonl','lane-polls.jsonl','coordination-state.json','boundary-checks.txt','frozen-source.json']:
 shutil.copyfile(root/name,ev/name)
parts=[]
for row in r['lanes']:
 parts.append(f"{row['id']} {row['status']} ({row['seconds']}s): {' '.join(row['command'])}\n")
 for stream in ['stdout','stderr']:
  lines=Path(row[stream]).read_text(errors='replace').splitlines()
  if lines:parts.append('['+stream+': verbatim tail]\n'+'\n'.join(lines[-10:])+'\n')
 if row['id']=='A1':
  lines=Path(row['stdout']).read_text().splitlines()
  assert 'Total: 14 passed, 0 failed' in lines
  assert any(x.startswith('check_fork_drift: SELFTEST OK (14 plants') for x in lines)
  assert any('layer 2: 29 differing generated files, all hash-pinned' in x for x in lines)
  for stream in ['stdout','stderr']:
   data=Path(row[stream]).read_bytes()
   assert hashlib.sha256(data).hexdigest()==row[stream+'_sha256']
   (ev/('row-1-'+stream+'.txt')).write_bytes(data)
  parts.append('[A1 unit total and final fork-drift verdicts, verbatim]\n'+'\n'.join(x for x in lines if x.startswith(('Total:', 'check_fork_content: OK', 'check_fork_drift: OK', 'check_fork_drift: SELFTEST OK'))) +'\n')
 parts.append('\n')
(ev/'tier-a-tails.txt').write_text(''.join(parts).rstrip()+'\n')
steps=[json.loads(x) for x in (root/'steps.jsonl').read_text().splitlines()]
assert steps[-1]['step']=='fast' and steps[-1]['rc']==0
coord=json.loads((root/'coordination-state.json').read_text());assert coord['wait_started'] is None
text=(root/'fast/summary.txt').read_text()+f"Frozen source/record comparison: {len(snap)}/{len(snap)} unchanged (derived count).\n"+f"Runner wall time {steps[-1]['wall_s']}s, including {coord['wait_seconds']:.3f}s of per-lane coordination waits; initial wait before launch {steps[-1]['wait_s']}s.\n"+f"Derived total elapsed {steps[-1]['wall_s'] + steps[-1]['wait_s']:.1f}s; runner time excluding lane waits {steps[-1]['wall_s'] - coord['wait_seconds']:.3f}s.\n"+'Original independent Tier B/C5 evidence remains at audited head 24f19d6f5; this is the final documentation/comment correction Tier A run.\n'+'Verbatim-evidence whitespace exceptions: generated-comment-diff.txt lines 32, 39, 43, 45 retain unified-diff context spaces; row-1-stdout.txt lines 637, 686, 687, 704 retain gate-output trailing spaces/tabs. All source and other staged files pass git diff --cached --check.\n'
(ev/'final-validation.txt').write_text(text)
print(text)
