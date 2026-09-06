#!/usr/bin/env python3
"""Build the pinned pristine oracle with upstream Lem in a fresh owned directory.

Load the project's OCaml environment first. No package installation, repinning,
network operation, or shared build cache is used. Both source trees come from
git archives, with no copied generated files or compilation products.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tarfile
import time

CERBERUS_REV = 'b9aeedcb4dd438763b0eef7f95ac19e93875d7de'
LEM_REV = '3802cb04b53d5f1096a464e51ecbfb2a750a7ccd'


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def files(root):
    return {str(p.relative_to(root)): sha(p) for p in sorted(root.rglob('*')) if p.is_file()}


def command(args, cwd, env, out, name, report):
    started = time.monotonic()
    record = {'command': list(map(str, args)), 'cwd': str(cwd), 'status': 'running'}
    report['commands'].append(record)
    save(out, report)
    with (out / (name + '.stdout')).open('wb') as stdout, (out / (name + '.stderr')).open('wb') as stderr:
        proc = subprocess.run(record['command'], cwd=cwd, env=env, stdout=stdout, stderr=stderr)
    record.update(exit_status=proc.returncode, seconds=round(time.monotonic() - started, 3),
                  stdout=name + '.stdout', stderr=name + '.stderr',
                  stdout_sha256=sha(out / (name + '.stdout')),
                  stderr_sha256=sha(out / (name + '.stderr')))
    record['status'] = 'passed' if proc.returncode == 0 else 'failed'
    save(out, report)
    print(f'{name}: {record["status"]} ({record["seconds"]}s)', flush=True)
    if proc.returncode:
        raise RuntimeError(f'{name} failed; see {out / (name + ".stderr")}')


def save(out, report):
    temp = out / 'manifest.tmp'
    temp.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
    temp.replace(out / 'manifest.json')


def archive(repo, rev, tree, out, name, report):
    path = out / (name + '.tar')
    with path.open('wb') as stream:
        subprocess.run(['git', '-C', str(repo), 'archive', rev], stdout=stream, check=True)
    tree.mkdir()
    with tarfile.open(path) as tar:
        # data filter refuses symlinks escaping the owned extraction directory.
        tar.extractall(tree, filter='data')
    report['sources'][name] = {'commit': rev, 'archive_sha256': sha(path),
                               'repository': str(repo), 'tree': str(tree)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lem-repo', type=Path, required=True)
    parser.add_argument('--cerberus-repo', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True, help='new directory; existing outputs are refused')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    report = {'schema': 1, 'status': 'incomplete', 'sources': {}, 'commands': [],
              'build_policy': 'git archives; own compiler/runtime prefix; DUNE_CACHE=disabled; --force'}
    save(out, report)
    try:
        # These archives may be nested in the fork's worktree. Prevent version
        # generators from attributing an archive to that unrelated parent git
        # checkout. Cerberus reports "unknown"; this manifest pins its source.
        env = dict(os.environ, DUNE_CACHE='disabled', GIT_CEILING_DIRECTORIES=str(out))
        for tool in ('git', 'make', 'ocamlc', 'ocamlbuild', 'ocamlfind', 'dune'):
            path = shutil.which(tool)
            if not path:
                raise RuntimeError(f'missing prerequisite: {tool}; load the project OCaml environment')
            report.setdefault('tools', {})[tool] = {'path': path, 'sha256': sha(path)}
        lem, cerb, prefix = out / 'lem', out / 'cerberus', out / 'lem/local-install'
        archive(args.lem_repo.resolve(), LEM_REV, lem, out, 'lem', report)
        archive(args.cerberus_repo.resolve(), CERBERUS_REV, cerb, out, 'cerberus', report)
        # Upstream's version generator asks git; archives deliberately have no
        # repository metadata. Supply the immutable source commit via its make
        # variable, and retain the archive hash as the source identity.
        common = ['INSTALL_DIR=' + str(prefix), 'LEMVERSION=' + LEM_REV[:7]]
        command(['make', 'bin/lem', *common], lem, env, out, 'lem-compiler', report)
        command(['make', '-C', 'library', 'ocaml-libs', *common], lem, env, out, 'lem-libraries', report)
        command(['make', '-C', 'ocaml-lib', 'all'], lem, env, out, 'lem-runtime-build', report)
        (prefix / 'bin').mkdir(parents=True)
        (prefix / 'lib').mkdir()
        (prefix / 'share/lem/library').mkdir(parents=True)
        shutil.copy2(lem / 'bin/lem', prefix / 'bin/lem')
        for pattern in ('*.lem', '*_constants'):
            for path in (lem / 'library').glob(pattern):
                shutil.copy2(path, prefix / 'share/lem/library' / path.name)
        # INSTALLDIR (without underscore) is the runtime makefile's variable.
        # Root `make install` without it would mutate shared findlib packages.
        command(['make', '-C', 'ocaml-lib', 'install', 'INSTALLDIR=' + str(prefix / 'lib'),
                 'LEMVERSION=' + LEM_REV[:7]],
                lem, env, out, 'lem-runtime-install', report)
        env.update(PATH=str(prefix / 'bin') + os.pathsep + env['PATH'], OCAMLPATH=str(prefix / 'lib'))
        for package in ('lem', 'lem_zarith'):
            actual = subprocess.check_output(['ocamlfind', 'query', package], env=env, text=True).strip()
            if Path(actual).resolve() != (prefix / 'lib' / package).resolve():
                raise RuntimeError(f'wrong runtime selected: {package}: {actual}')
        report['environment'] = {key: env[key] for key in
                                 ('PATH', 'OCAMLPATH', 'DUNE_CACHE', 'GIT_CEILING_DIRECTORIES')}
        command(['make', 'prelude-src'], cerb, env, out, 'cerberus-generation', report)
        command(['dune', 'build', '--root', str(cerb), '--force',
                 'backend/driver/main.exe', 'cerberus-lib.install', 'cerberus.install'],
                cerb, env, out, 'cerberus-build', report)
        for tool, flag in [('ocamlc', '-version'), ('dune', '--version'), ('lem', '-v')]:
            report.setdefault('versions', {})[tool] = subprocess.check_output([tool, flag], env=env, text=True).strip()
        report['artifacts'] = {
            'compiler': {'path': str(prefix / 'bin/lem'), 'sha256': sha(prefix / 'bin/lem')},
            'lem_runtime': {'root': str(prefix / 'lib'), 'files': files(prefix / 'lib')},
            'lem_library': {'root': str(prefix / 'share/lem/library'), 'files': files(prefix / 'share/lem/library')},
            'generated': {'root': str(cerb / 'ocaml_frontend/generated'), 'files': files(cerb / 'ocaml_frontend/generated')},
            'oracle': {'path': str(cerb / '_build/default/backend/driver/main.exe'),
                       'sha256': sha(cerb / '_build/default/backend/driver/main.exe')},
            'runtime': {'root': str(cerb / '_build/install/default'), 'files': files(cerb / '_build/install/default')},
        }
        report['status'] = 'built'
        save(out, report)
        print(f'Independent upstream oracle: {out / "manifest.json"}', flush=True)
        return 0
    except (OSError, RuntimeError, subprocess.CalledProcessError) as exc:
        report.update(status='incomplete', error=str(exc))
        save(out, report)
        print(f'BUILD INCOMPLETE: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
