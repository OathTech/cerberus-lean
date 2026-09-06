#!/usr/bin/env python3
"""Content/mode pins for the fork gate's complete reviewed source-delta set.

The shell gate supplies its live path set on stdin. --emit only prints proposed
pins; accepting a pin requires review of the corresponding source diff.
"""
import argparse
import hashlib
import os
from pathlib import Path, PurePosixPath
import re
import stat
import sys


def identity(path):
    try:
        info = path.lstat()
    except FileNotFoundError:
        return '000000', '-'
    if stat.S_ISLNK(info.st_mode):
        return '120000', hashlib.sha256(os.fsencode(os.readlink(path))).hexdigest()
    if not stat.S_ISREG(info.st_mode):
        raise ValueError(f'unsupported source file type: {path}')
    return ('100755' if info.st_mode & stat.S_IXUSR else '100644',
            hashlib.sha256(path.read_bytes()).hexdigest())


def path_ok(name):
    path = PurePosixPath(name)
    if path.is_absolute() or '..' in path.parts or not name or any(c.isspace() for c in name):
        raise ValueError(f'invalid source-content path: {name!r}')


def parse_manifest(path):
    pins, inside, sections = {}, False, 0
    for line in path.read_text().splitlines():
        if line.startswith('['):
            inside = line == '[source-content]'
            sections += inside
            continue
        if not inside or not line.strip() or line.lstrip().startswith('#'):
            continue
        match = re.fullmatch(r'(000000|100644|100755|120000) (-|[0-9a-f]{64}) (\S+)', line)
        if not match or (match[1] == '000000') != (match[2] == '-'):
            raise ValueError(f'malformed [source-content] entry: {line}')
        mode, digest, name = match.groups()
        path_ok(name)
        if name in pins:
            raise ValueError(f'duplicate [source-content] entry: {name}')
        pins[name] = mode, digest
    if sections != 1 or not pins:
        raise ValueError('missing, empty or duplicated [source-content] section')
    return pins


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', required=True, type=Path)
    parser.add_argument('--manifest', required=True, type=Path)
    parser.add_argument('--emit', action='store_true')
    args = parser.parse_args()
    try:
        names = sys.stdin.read().splitlines()
        if not names or len(set(names)) != len(names):
            raise ValueError('empty or duplicate live source paths')
        for name in names:
            path_ok(name)
        live = {name: identity(args.root / name) for name in sorted(names)}
        if args.emit:
            for name, (mode, digest) in live.items():
                print(mode, digest, name)
            return 0
        pins = parse_manifest(args.manifest)
        if set(pins) != set(live):
            raise ValueError('source-content path set differs from live source delta: '
                             f'unpinned={sorted(set(live) - set(pins))}; stale={sorted(set(pins) - set(live))}')
        moved = [f'{name}: expected {pins[name]}, actual {value}'
                 for name, value in live.items() if value != pins[name]]
        if moved:
            raise ValueError('source-content drift inside reviewed file(s):\n' + '\n'.join(moved))
        print(f'check_fork_content: OK — {len(pins)} source files content/mode-pinned')
        return 0
    except (ValueError, OSError) as exc:
        print(f'check_fork_content: FAIL — {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
