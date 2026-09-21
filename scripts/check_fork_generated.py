#!/usr/bin/env python3
"""Check reviewed additions to the otherwise shared generated OCaml file set.

Existing-file deltas remain checked by check_fork_drift.sh. Removing a pristine
file is always an error. Additions require an exact filename/content manifest;
--emit-additions prepares that manifest for review, not a passing gate result.
"""
import argparse
import hashlib
from pathlib import Path
import re
import sys


def files(root: Path) -> dict[str, Path]:
    entries = list(root.iterdir())
    if not entries:
        raise ValueError(f"empty generated tree: {root}")
    result = {}
    for entry in entries:
        if entry.is_symlink() or not entry.is_file():
            raise ValueError(f"non-regular generated entry: {entry}")
        if not re.fullmatch(r"[A-Za-z0-9_]+\.ml", entry.name):
            raise ValueError(f"unexpected generated filename: {entry}")
        result[entry.name] = entry
    return result


def pins(manifest: Path) -> dict[str, str]:
    result = {}
    active = False
    seen = False
    for line in manifest.read_text().splitlines():
        line = line.strip()
        if line.startswith("["):
            active = line == "[expected-added]"
            if active:
                if seen:
                    raise ValueError("duplicate [expected-added] section")
                seen = True
            continue
        if not active or not line or line.startswith("#"):
            continue
        match = re.fullmatch(r"([0-9a-f]{64}) ([A-Za-z0-9_]+\.ml)", line)
        if not match:
            raise ValueError(f"malformed generated addition pin: {line}")
        digest, name = match.groups()
        if name in result:
            raise ValueError(f"duplicate generated addition pin: {name}")
        result[name] = digest
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--upstream", type=Path, required=True)
    parser.add_argument("--fork", type=Path, required=True)
    parser.add_argument("--manifest", type=Path, required=True)
    parser.add_argument("--emit-additions", action="store_true")
    args = parser.parse_args()
    try:
        upstream, fork = files(args.upstream), files(args.fork)
        missing = upstream.keys() - fork.keys()
        if missing:
            raise ValueError(f"pristine generated files missing from fork: {sorted(missing)}")
        added = {name: hashlib.sha256(fork[name].read_bytes()).hexdigest()
                 for name in sorted(fork.keys() - upstream.keys())}
        expected = pins(args.manifest)
        if not args.emit_additions:
            if added.keys() != expected.keys():
                raise ValueError("generated addition set drift: "
                                 f"unregistered={sorted(added.keys() - expected.keys())}; "
                                 f"stale={sorted(expected.keys() - added.keys())}")
            for name, digest in added.items():
                if digest != expected[name]:
                    raise ValueError(f"generated addition content drift: {name}")
        for name, digest in added.items():
            print(f"{digest} {name}")
        return 0
    except (OSError, ValueError) as exc:
        print(f"check_fork_generated: FAIL — {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
