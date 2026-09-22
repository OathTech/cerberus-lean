"""Verify the committed audit bundle without using the original worktrees."""
from pathlib import Path, PurePosixPath
import hashlib, json, tarfile

root = Path(__file__).resolve().parent
manifest = {}
for line in (root / 'SHA256SUMS').read_text().splitlines():
    digest, name = line.split('  ', 1)
    p = PurePosixPath(name)
    assert not p.is_absolute() and '..' not in p.parts and name not in manifest
    manifest[name] = digest
actual = {str(p.relative_to(root)) for p in root.rglob('*')
          if p.is_file() and p.name != 'SHA256SUMS'}
assert actual == set(manifest), (actual - set(manifest), set(manifest) - actual)
for name, digest in manifest.items():
    p = root / name
    assert not p.is_symlink()
    assert hashlib.sha256(p.read_bytes()).hexdigest() == digest, name

for label, head in [
    ('enum', 'e2fc391f21fd659c74f4dfdecdf7cc9fd45a2009'),
    ('arity', '14457f1a0b30e1de3762310af51684bf6d2e347f'),
]:
    report = json.loads((root / label / 'release-report.json').read_text())
    assert report['status'] == 'passed'
    assert report['selection_complete'] and report['source_unchanged']
    assert report['source_before'] == report['source_after']
    assert report['source_before']['head'] == head
    assert report['source_before']['status'] == ''
    assert report['external_inputs_before'] == report['external_inputs_after']
    assert report['artifacts_before'] == report['artifacts_after']
    assert len(report['lanes']) == 39
    with tarfile.open(root / label / 'lane-receipts.tar.gz') as tf:
        for lane in report['lanes']:
            assert lane['status'] == 'passed' and lane['exit_status'] == 0
            for stream in ['stdout', 'stderr']:
                data = tf.extractfile(lane['id'] + '/' + stream).read()
                assert hashlib.sha256(data).hexdigest() == lane[stream + '_sha256']
        assert b'Baseline check: 0 regression(s), 0 improvement(s)' in tf.extractfile('B7/stdout').read()
    with tarfile.open(root / label / 'pristine-reports.tar.gz') as tf:
        corpus = json.load(tf.extractfile('B10.1/independent-oracle/report.json'))
        assert corpus['status'] == 'passed' and corpus['source_unchanged']
        assert corpus['counts'] == dict(semantic_agreement=835 if label == 'enum' else 822,
                                       matching_failure=28, reviewed_difference=7,
                                       interface_agreement=2)
        plant = json.load(tf.extractfile('B10.2/independent-oracle/report.json'))
        assert plant['status'] == 'plants_passed' and plant['source_unchanged']
        chvalid = json.load(tf.extractfile('B12/independent-oracle/report.json'))
        assert chvalid['status'] == 'passed' and chvalid['source_unchanged']
        assert chvalid['counts'] == dict(semantic_agreement=4)
    print(label, head, '39/39; source/external/artifacts stable; receipts verified')

for p in root.rglob('*.tar.gz'):
    with tarfile.open(p) as tf:
        seen = set()
        for member in tf.getmembers():
            name = PurePosixPath(member.name)
            assert not name.is_absolute() and '..' not in name.parts
            assert member.isfile() and member.name not in seen
            seen.add(member.name)
            tf.extractfile(member).read()
print('Verified', len(manifest), 'files and every archive member')
