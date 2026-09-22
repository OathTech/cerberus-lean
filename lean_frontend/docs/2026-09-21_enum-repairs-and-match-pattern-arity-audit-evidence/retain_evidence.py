"""Stage audit evidence only after BOTH exact-head batteries have completed."""
from pathlib import Path
import hashlib, json, shutil, tarfile

root = Path.cwd()
scratch = root / '.tmp/two-range-audit'
arity = root.parent / 'match-pattern-arity-20260921'
dest = scratch / 'retained'
dest.mkdir(exist_ok=False)

def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()

def copy(src, dst):
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(src, dst)

def archive(target, base, files):
    with tarfile.open(target, 'w:gz') as tf:
        for p in sorted(set(files)):
            assert p.is_file() and not p.is_symlink(), p
            tf.add(p, arcname=str(p.relative_to(base)), recursive=False)

checks = {}
for label, tree, expected_head in [
    ('enum', root, 'e2fc391f21fd659c74f4dfdecdf7cc9fd45a2009'),
    ('arity', arity, '14457f1a0b30e1de3762310af51684bf6d2e347f'),
]:
    src = tree / '.tmp/two-range-audit'
    report = json.loads((src / 'full/report.json').read_text())
    assert (src / 'full.status').read_text().strip() == '0'
    assert report['status'] == 'passed'
    assert report['selection_complete'] and report['source_unchanged']
    assert report['source_before'] == report['source_after']
    assert report['source_before']['head'] == expected_head
    assert report['source_before']['status'] == ''
    assert report['external_inputs_before'] == report['external_inputs_after']
    assert report['artifacts_before'] == report['artifacts_after']
    assert len(report['lanes']) == 39
    assert all(r['status'] == 'passed' and r['exit_status'] == 0 for r in report['lanes'])
    d = dest / label
    d.mkdir()
    copy(src / 'full/report.json', d / 'release-report.json')
    copy(src / 'full/summary.txt', d / 'release-summary.txt')
    copy(src / 'full.log', d / 'full-run.txt')
    receipts = []
    for row in report['lanes']:
        for stream in ['stdout', 'stderr']:
            p = Path(row[stream])
            assert sha(p) == row[stream + '_sha256']
            receipts.append(p)
        receipts.extend((src / 'full' / row['id']).glob('*.json'))
    archive(d / 'lane-receipts.tar.gz', src / 'full', receipts)
    archive(d / 'pristine-reports.tar.gz', src / 'full', [
        src / 'full/B10.1/independent-oracle/report.json',
        src / 'full/B10.2/independent-oracle/report.json',
        src / 'full/B12/independent-oracle/report.json',
    ])
    copy(tree / '.validation-foundations/independent-oracle-v2/manifest.json', d / 'pristine-manifest.json')
    for p in ['driver_fresh.oracle.sha256', 'driver_fresh.lean.sha256',
              'ocaml_frontend/lem_sync.sha256', 'lean_frontend/lem_sync.sha256']:
        copy(tree / p, d / 'stamps' / p)
    archive(d / 'build-log.tar.gz', src, [src / 'build.log'])
    checks[label] = {
        'head': expected_head, 'started_utc': report['started_utc'],
        'finished_utc': report['finished_utc'], 'lanes': len(report['lanes']),
        'source_equal': True, 'external_equal': True, 'artifacts_equal': True,
        'report_sha256': sha(d / 'release-report.json'),
    }

enum_files = [
    'run_enum_probes.py', 'check_constructors.py', 'independent_enum_probes.py',
    'probes-results.json', 'independent-enum-results.json', 'enum-focused-summary.json',
    'scope-checks.json', 'enum-generated-delta.json', 'enum-focused-delta.json',
    'integration-merge-tree.txt', 'gcc-witness-admission.txt',
]
for rel in enum_files:
    copy(scratch / rel, dest / 'enum' / rel)
for p in (scratch / 'probes').glob('*.c'):
    copy(p, dest / 'enum/probes' / p.name)
for p in (scratch / 'register-route').iterdir():
    if p.suffix in ['.py', '.core', '.json']:
        copy(p, dest / 'enum/register-route' / p.name)
for subdir in ['constructors', 'sign-normalisation']:
    for p in (scratch / subdir).iterdir():
        if p.suffix in ['.ml', '.lean', '.json', '.py']:
            copy(p, dest / 'enum' / subdir / p.name)
raw = []
for subdir in ['captures', 'independent-captures', 'sign-normalisation']:
    for p in (scratch / subdir).rglob('*'):
        if p.is_file() and p.suffix in ['.stdout', '.stderr', '.status', '.txt', '.json']:
            raw.append(p)
raw.extend(scratch / p for p in ['enum-probes.txt', 'independent-enum.txt',
                                'generated-repair-excerpts.txt', 'repair-source-excerpts.txt'])
archive(dest / 'enum/focused-captures.tar.gz', scratch, raw)

src = arity / '.tmp/two-range-audit'
for rel in ['prepare_core_probes.py', 'run_core_probes.py', 'run_sequence_probes.py',
            'run_discarded_error.py', 'discarded-error-results.json',
            'discarded-error-parser-exploration.json',
            'ArityAudit.lean', 'base-unit-plant.source.lean', 'arity-scope.json',
            'base-identities.json',
            'core-results.json', 'core-sequence-results.json', 'rewrite-results.json']:
    copy(src / rel, dest / 'arity' / rel)
for p in (src / 'core-probes').glob('*.core'):
    copy(p, dest / 'arity/core-probes' / p.name)
raw = [src / p for p in [
    'arity-lean.txt', 'arity-lean.status', 'base-unit-plant.txt', 'base-unit-plant.status',
    'core-probes.txt', 'core-sequence.txt',
]]
for subdir in ['core-captures', 'rewrite-captures', 'typed-dumps']:
    raw.extend(p for p in (src / subdir).rglob('*') if p.is_file())
archive(dest / 'arity/focused-captures.tar.gz', src, raw)
(dest / 'verification.json').write_text(json.dumps(checks, indent=2) + '\n')
copy(scratch / 'retain_evidence.py', dest / 'retain_evidence.py')
copy(scratch / 'verify_evidence.py', dest / 'verify_evidence.py')
print(json.dumps(checks, indent=2))
