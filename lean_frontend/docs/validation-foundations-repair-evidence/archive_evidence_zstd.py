"""Archive explicit owned evidence paths and verify every retained raw byte.

Uses a standard tar stream and zstd's long window for repetitive Cabs captures.
No build trees are selected implicitly. Symlinks are rejected, not followed.
"""
from pathlib import Path
import hashlib
import json
import subprocess
import tarfile


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def archive(root, output, name, paths):
    root = Path(root).resolve()
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    selected = {}
    for entry in paths:
        entry = Path(entry)
        if not entry.is_absolute():
            entry = root / entry
        if not entry.exists():
            raise FileNotFoundError(entry)
        for path in entry.rglob('*') if entry.is_dir() else [entry]:
            if path.is_symlink():
                raise RuntimeError('review symlink before archiving: ' + str(path))
            if path.is_file():
                selected[str(path.relative_to(root))] = path
    target = output / (name + '.tar.zst')
    if target.exists():
        raise FileExistsError(target)
    rows = []
    with subprocess.Popen(['zstd', '-q', '-10', '--long=27', '-T1', '-o', str(target)],
                          stdin=subprocess.PIPE) as proc:
        with tarfile.open(fileobj=proc.stdin, mode='w|') as tar:
            for rel, path in sorted(selected.items()):
                rows.append({'path': rel, 'size': path.stat().st_size, 'sha256': digest(path)})
                tar.add(path, arcname=rel, recursive=False)
        proc.stdin.close()
        if proc.wait() != 0:
            raise RuntimeError('zstd compression failed')
    report = {'schema': 1, 'archive': target.name, 'compression': 'zstd --long=27',
              'archive_sha256': digest(target), 'file_count': len(rows),
              'total_bytes': sum(row['size'] for row in rows), 'files': rows}
    expected = {row['path']: row for row in rows}
    seen = set()
    with subprocess.Popen(['zstd', '-q', '-d', '-c', str(target)], stdout=subprocess.PIPE) as proc:
        with tarfile.open(fileobj=proc.stdout, mode='r|') as tar:
            for member in tar:
                assert member.isfile() and not member.name.startswith('/')
                assert '..' not in Path(member.name).parts and member.name not in seen
                seen.add(member.name)
                row = expected[member.name]
                assert member.size == row['size']
                with tar.extractfile(member) as stream:
                    assert hashlib.file_digest(stream, 'sha256').hexdigest() == row['sha256']
        # Drain the standard tar's trailing padding before waiting for zstd.
        while proc.stdout.read(1024 * 1024):
            pass
        if proc.wait() != 0:
            raise RuntimeError('zstd verification failed')
    assert seen == set(expected)
    (output / (name + '.json')).write_text(json.dumps(report, indent=2) + '\n')
    print(name, len(rows), 'verified files;', target.stat().st_size, 'archive bytes', flush=True)
    return report
