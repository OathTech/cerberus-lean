#!/usr/bin/env python3
"""Ensure the pristine independent oracle is STANDING at the lane's default path.

The ONE entry point for the LADDER Tier B row-10 prerequisite (WP-O, charter
lean_frontend/docs/2026-09-16_charter-pristine-oracle-instrument.md §2 O3):

  (a) validate the manifest exactly as the lane does — test_upstream_oracle.
      validate_build is imported and REUSED; there is no second validator;
  (b) if the build directory is ABSENT, build it with build_independent_oracle.py
      into that (new) directory — `--lem-repo` / `--cerberus-repo` discovered
      from the container layout or given explicitly, loud failure otherwise;
  (c) if the directory is PRESENT but the manifest is missing or INVALID,
      REFUSE with the validator's reason and name the directory for the
      operator to remove. This script never deletes or overwrites anything.

The lane (scripts/test_upstream_oracle.py) and scripts/release.py keep their
PREREQUISITE stance: they never build, and a missing manifest fails them
closed. Run under the project's OCaml environment (scripts/ce or env.sh):
the build needs lem/dune/ocamlfind on PATH. Relocating an existing build is
not attempted (the manifest records absolute paths; a rebuild is ~1 minute).

Exit status: 0 = a valid build is standing (found or just built); 1 = refused,
missing prerequisites, or build/validation failure.
"""
from __future__ import annotations

import argparse
import os
from pathlib import Path
import subprocess
import sys

from build_independent_oracle import CERBERUS_REV, LEM_REV
from test_upstream_oracle import validate_build

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_OUT = ROOT / '.validation-foundations/independent-oracle-v2'


def has_commit(repo: Path, rev: str) -> tuple[bool, str]:
    """True iff `repo` is a git checkout whose object store contains `rev`."""
    if not repo.is_dir():
        return False, 'not a directory'
    proc = subprocess.run(['git', '-C', str(repo), 'cat-file', '-e', rev + '^{commit}'],
                          capture_output=True, text=True)
    return proc.returncode == 0, proc.stderr.strip()


def discover(name: str, rev: str, explicit: Path | None, env_var: str,
             candidates: list[Path]) -> Path:
    """Pick the checkout holding `rev`: explicit flag > env var > container candidates."""
    tried = []
    if explicit is not None:
        ok, why = has_commit(explicit.resolve(), rev)
        if ok:
            return explicit.resolve()
        raise SystemExit(f'ensure_independent_oracle: --{name}-repo {explicit} does not contain '
                         f'{rev}: {why or "commit absent"}')
    if os.environ.get(env_var):
        path = Path(os.environ[env_var]).resolve()
        ok, why = has_commit(path, rev)
        if ok:
            return path
        raise SystemExit(f'ensure_independent_oracle: {env_var}={path} does not contain {rev}: '
                         f'{why or "commit absent"}')
    for path in candidates:
        ok, why = has_commit(path, rev)
        if ok:
            return path.resolve()
        tried.append(f'{path}: {why or "commit absent"}')
    raise SystemExit(f'ensure_independent_oracle: no {name} checkout containing {rev} found; '
                     f'pass --{name}-repo or set {env_var}. Tried:\n  ' + '\n  '.join(tried))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--out', type=Path, help='build directory (default: the lane\'s default path, or the '
                        'parent of CERB_INDEPENDENT_MANIFEST when that is set)')
    parser.add_argument('--lem-repo', type=Path, help='lem-lean checkout holding the pinned upstream lem commit '
                        '(default: CERB_LEM_REPO, else a container sibling lem-lean / deps/lem-pinned)')
    parser.add_argument('--cerberus-repo', type=Path, help='cerberus checkout holding the pinned pristine commit '
                        '(default: CERB_CERBERUS_REPO, else this checkout itself)')
    parser.add_argument('--no-build', action='store_true', help='validate only; never build (exit 1 when absent)')
    args = parser.parse_args()

    if args.out is not None:
        out = args.out.resolve()
    elif os.environ.get('CERB_INDEPENDENT_MANIFEST'):
        out = Path(os.environ['CERB_INDEPENDENT_MANIFEST']).resolve().parent
    else:
        out = DEFAULT_OUT
    manifest = out / 'manifest.json'

    if manifest.is_file():
        try:
            validate_build(manifest)
        except (ValueError, KeyError, OSError) as exc:
            print(f'ensure_independent_oracle: REFUSED — existing build at {out} is INVALID: {exc}\n'
                  f'  Nothing was deleted or overwritten. To rebuild, remove that directory yourself '
                  f'and rerun.', file=sys.stderr)
            return 1
        print(f'ensure_independent_oracle: VALID standing build: {manifest} '
              f'(cerberus {CERBERUS_REV[:9]}, lem {LEM_REV[:7]})', flush=True)
        return 0
    if out.exists():
        print(f'ensure_independent_oracle: REFUSED — {out} exists but has no manifest.json (a partial or '
              f'foreign directory). Nothing was deleted or overwritten. Remove it yourself and rerun.',
              file=sys.stderr)
        return 1
    if args.no_build:
        print(f'ensure_independent_oracle: ABSENT — no build at {out} (--no-build: not building)',
              file=sys.stderr)
        return 1

    parents = [ROOT, *ROOT.parents]
    lem_repo = discover('lem', LEM_REV, args.lem_repo, 'CERB_LEM_REPO',
                        [p / 'lem-lean' for p in parents] + [p / 'deps/lem-pinned' for p in parents])
    cerberus_repo = discover('cerberus', CERBERUS_REV, args.cerberus_repo, 'CERB_CERBERUS_REPO',
                             [ROOT] + [p / 'cerberus-lean' for p in parents])
    print(f'ensure_independent_oracle: ABSENT — building the pristine oracle into {out}\n'
          f'  lem-repo:      {lem_repo}\n  cerberus-repo: {cerberus_repo}', flush=True)
    build = subprocess.run([sys.executable, str(ROOT / 'scripts/build_independent_oracle.py'),
                            '--lem-repo', str(lem_repo), '--cerberus-repo', str(cerberus_repo),
                            '--out', str(out)], cwd=ROOT)
    if build.returncode != 0:
        print(f'ensure_independent_oracle: BUILD FAILED (exit {build.returncode}); the incomplete directory '
              f'{out} is left in place for inspection — remove it yourself before retrying.', file=sys.stderr)
        return 1
    try:
        validate_build(manifest)
    except (ValueError, KeyError, OSError) as exc:
        print(f'ensure_independent_oracle: BUILT but the manifest FAILS the lane\'s validator: {exc} '
              f'({manifest}); left in place for inspection.', file=sys.stderr)
        return 1
    print(f'ensure_independent_oracle: BUILT+VALID standing build: {manifest} '
          f'(cerberus {CERBERUS_REV[:9]}, lem {LEM_REV[:7]})', flush=True)
    return 0


if __name__ == '__main__':
    sys.exit(main())
