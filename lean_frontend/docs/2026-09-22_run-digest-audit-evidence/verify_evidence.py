"""Verify the retained run-digest audit bundle without the original worktree."""
from pathlib import Path, PurePosixPath
import hashlib, json, tarfile

root = Path(__file__).resolve().parent
manifest = {}
for line in (root / 'SHA256SUMS').read_text().splitlines():
    digest, name = line.split('  ', 1)
    path = PurePosixPath(name)
    assert not path.is_absolute() and '..' not in path.parts and name not in manifest
    manifest[name] = digest
actual = {str(p.relative_to(root)) for p in root.rglob('*')
          if p.is_file() and p.name != 'SHA256SUMS'}
assert actual == set(manifest), (actual - set(manifest), set(manifest) - actual)
for name, digest in manifest.items():
    p = root / name
    assert not p.is_symlink()
    assert hashlib.sha256(p.read_bytes()).hexdigest() == digest, name

report = json.loads((root / 'release-report.json').read_text())
assert report['status'] == 'passed'
assert report['selection_complete'] and report['source_unchanged']
assert report['source_before'] == report['source_after']
assert report['source_before']['head'] == '24f19d6f5a63204afff1991e3fc1fcf5b28ad420'
assert report['source_before']['status'] == ''
assert report['external_inputs_before'] == report['external_inputs_after']
assert report['artifacts_before'] == report['artifacts_after']
assert len(report['lanes']) == 39
with tarfile.open(root / 'lane-receipts.tar.gz') as tf:
    for lane in report['lanes']:
        assert lane['status'] == 'passed' and lane['exit_status'] == 0
        for stream in ['stdout', 'stderr']:
            data = tf.extractfile(lane['id'] + '/' + stream).read()
            assert hashlib.sha256(data).hexdigest() == lane[stream + '_sha256']
    gcc = tf.extractfile('B7/stdout').read()
    assert b'Baseline check: 0 regression(s), 0 improvement(s)' in gcc
    assert b'Total: 14 passed, 0 failed' in tf.extractfile('A1/stdout').read()
reports = []
with tarfile.open(root / 'pristine-reports.tar.gz') as tf:
    corpus = json.load(tf.extractfile('B10.1/independent-oracle/report.json'))
    assert corpus['status'] == 'passed' and corpus['source_unchanged']
    expected = dict(semantic_agreement=835, matching_failure=28,
                    reviewed_difference=7, interface_agreement=2)
    assert corpus['counts'] == expected
    plant = json.load(tf.extractfile('B10.2/independent-oracle/report.json'))
    assert plant['status'] == 'plants_passed' and plant['source_unchanged']
    chvalid = json.load(tf.extractfile('B12/independent-oracle/report.json'))
    assert chvalid['status'] == 'passed' and chvalid['source_unchanged']
    assert chvalid['counts'] == dict(semantic_agreement=4)
    three = json.load(tf.extractfile('three-engine/report.json'))
    assert three['status'] == 'passed' and three['source_unchanged']
    assert three['source']['head'] == report['source_before']['head']
    assert three['source']['status'] == ''
    assert three['counts'] == expected
    assert three['lean_counts'] == dict(lean_agreement=830, lean_both_undecodable=12,
                                       lean_difference=28, lean_not_applicable=2)
    expected_differences = json.loads((root/'expected-lean-differences.json').read_text())
    assert set(three['lean_differences']) == set(expected_differences)
    assert {row['id']: row['lean']['status'] for row in three['rows']
            if row['id'] in three['lean_differences']} == expected_differences
    reports = [corpus, plant, chvalid, three]

def captures(value):
    if isinstance(value, dict):
        if 'capture' in value:
            yield value
        for child in value.values():
            yield from captures(child)
    elif isinstance(value, list):
        for child in value:
            yield from captures(child)

capture_count = 0
with tarfile.open(root / 'pristine-captures.tar.gz') as tf:
    for retained in reports:
        for capture in captures(retained):
            prefix = PurePosixPath(capture['capture'].split('/.tmp/run-digest-audit/', 1)[1].removeprefix('full/'))
            for stream in ['stdout', 'stderr']:
                data = tf.extractfile(str(prefix.with_suffix('.' + stream))).read()
                assert hashlib.sha256(data).hexdigest() == capture[stream + '_sha256']
            status = int(tf.extractfile(str(prefix.with_suffix('.status'))).read())
            assert status == capture['status']
            capture_count += 1
with tarfile.open(root / 'focused-evidence.tar.gz') as tf:
    native = tf.extractfile('native-run.log').read().decode()
    assert sum(line.startswith('PASS:') for line in native.splitlines()) == 26
    assert 'DigestAudit: all native and kernel checks passed' in native
    build = tf.extractfile('native-build.log').read().decode()
    assert 'Build completed successfully (286 jobs).' in build
    assert 'wrong_digest expected rejection rc=2' in tf.extractfile('optional.log').read().decode()

for p in root.rglob('*.tar.gz'):
    with tarfile.open(p) as tf:
        seen = set()
        for member in tf.getmembers():
            name = PurePosixPath(member.name)
            assert not name.is_absolute() and '..' not in name.parts
            assert member.isfile() and member.name not in seen
            seen.add(member.name)
            tf.extractfile(member).read()
print('Verified', len(manifest), 'files and all archive members;', capture_count, 'capture records; 39/39 commands; source, external inputs and recorded artifacts stable; 26 native assertions; pristine and three-engine counts.')
