#!/usr/bin/env python3
"""Cold provider rehearsal in new, owned detached worktrees; no shared installs.

Run in the project OCaml environment. Immutable git dependency sources and
installed toolchains are reused; generated Cerberus, native objects and every
Lake build directory start absent. The external client source is hash-pinned
separately so a recipe can rehearse an identified semantic revision.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

from build_independent_oracle import files, save, sha
from release import RunnerInterrupted, artifacts, source_identity
from process_scope import ContainmentError, ProcessScope

ROOT = Path(__file__).resolve().parent.parent
LEM_REV = 'f6542f8e6860d12d4655e6648bc4c45dabd1d798'
PACKAGES = ('lean_frontend', 'lean_frontend/speclab', 'tests/mem-scale-probes/micro')


def pins(cerb, compiler, runtime):
    for package in PACKAGES:
        data = json.loads((cerb / package / 'lake-manifest.json').read_text())
        rows = [p for p in data['packages'] if p['name'] == 'LemLib']
        if len(rows) != 1 or rows[0]['rev'] != LEM_REV or rows[0]['inputRev'] != LEM_REV:
            raise RuntimeError(f'wrong Lem runtime manifest pin: {package}')
    version = subprocess.check_output([str(compiler), '-v'], text=True).strip()
    if version != 'Lem '+LEM_REV[:7]:
        raise RuntimeError(f'wrong Lem compiler version: {version!r}')
    actual = subprocess.check_output(['git', '-C', str(runtime), 'rev-parse', 'HEAD'], text=True).strip()
    dirty = subprocess.check_output(['git', '-C', str(runtime), 'status', '--porcelain'], text=True)
    if actual != LEM_REV or dirty:
        raise RuntimeError(f'wrong/dirty Lem runtime source: {actual}; {dirty}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cerberus-repo', type=Path, default=ROOT)
    parser.add_argument('--cerberus-rev', required=True, help='immutable full commit')
    parser.add_argument('--lem-repo', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True, help='new output directory')
    args = parser.parse_args()
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    cerb, lem = out / 'cerberus', out / 'lem'
    report = {'schema': 1, 'status': 'incomplete', 'sources': {}, 'commands': [],
              'policy': 'new detached worktrees; no priming; own compiler/runtime; DUNE_CACHE=disabled; capped Lean',
              'preconditions': ['project OCaml environment', 'installed Lean 4.32.2 and 4.28.0',
                                'local Git source objects', 'one heavy job at a time']}
    save(out, report)
    env = dict(os.environ, DUNE_CACHE='disabled', CERB_MEM_MAX='32G')
    previous_handlers = {sig: signal.getsignal(sig) for sig in (signal.SIGINT, signal.SIGTERM)}
    def interrupted(signum, _frame):
        raise RunnerInterrupted(signum)
    for sig in previous_handlers:
        signal.signal(sig, interrupted)

    def run(name, argv, cwd=out, expected=0):
        row = {'name': name, 'command': list(map(str, argv)), 'cwd': str(cwd), 'status': 'running'}
        report['commands'].append(row)
        save(out, report)
        started = time.monotonic()
        error = None
        with (out / (name + '.stdout')).open('wb') as stdout, (out / (name + '.stderr')).open('wb') as stderr:
            scope = None
            try:
                scope = ProcessScope(out/(name+'.scope'))
                proc = scope.start(row['command'], cwd=cwd, env=env, stdout=stdout, stderr=stderr)
                row.update(process_group=proc.pid, cgroup=str(scope.path))
                save(out, report)
                rc = scope.wait(3500)
                row.update(exit_status=rc, expected=expected, status='passed' if rc == expected else 'failed')
            except (OSError, ContainmentError, subprocess.SubprocessError, RunnerInterrupted) as exc:
                error = exc
                row.update(exit_status=None, status='incomplete', reason=str(exc))
            finally:
                if scope is not None:
                    try:
                        residual = scope.finish(cancel=error is not None)
                        row['containment_cleaned'] = True
                        if error is not None and scope.proc is not None and not (scope.directory/'scope-launch-error.json').exists():
                            row['exit_status'] = scope.proc.returncode
                        if residual and error is None:
                            error = ContainmentError('build command exited with live descendants')
                            row.update(status='incomplete', reason=str(error))
                    except RunnerInterrupted as exc:
                        error = exc
                        row.update(status='incomplete', interrupted_signal=exc.signum,
                                   containment_cleaned=scope.closed, reason=str(exc))
                        if scope.proc is not None and not (scope.directory/'scope-launch-error.json').exists():
                            row['exit_status'] = scope.proc.returncode
                    except (OSError, ContainmentError, subprocess.SubprocessError) as exc:
                        error = exc
                        row.update(status='incomplete', containment_cleaned=False, reason=str(exc))
        row.update(seconds=round(time.monotonic()-started, 3),
                   stdout_sha256=sha(out / (name + '.stdout')), stderr_sha256=sha(out / (name + '.stderr')))
        save(out, report)
        print(f'{name}: {row["status"]} ({row["seconds"]}s)', flush=True)
        if error is not None:
            raise error
        if row['status'] != 'passed':
            raise RuntimeError(f'{name}: expected {expected}, got {proc.returncode}; see retained logs')

    try:
        for name, repo, rev, tree in [('cerberus', args.cerberus_repo, args.cerberus_rev, cerb),
                                      ('lem', args.lem_repo, LEM_REV, lem)]:
            full = subprocess.check_output(['git', '-C', str(repo), 'rev-parse', rev + '^{commit}'], text=True).strip()
            if rev != full:
                raise RuntimeError(f'{name}: supply the immutable full commit, resolved to {full}')
            run(name+'-checkout', ['git', '-C', repo.resolve(), 'worktree', 'add', '--detach', tree, full])
            report['sources'][name] = source_identity(tree)
        for path in ('lean_frontend/generated', 'ocaml_frontend/generated', '_build',
                     'lean_frontend/.lake', 'lean_frontend/native/md5.o'):
            if (cerb / path).exists():
                raise RuntimeError(f'not a cold tree: {path}')
        report['initial_absence_checked'] = True
        cap = cerb / 'scripts/capped'
        # Actual shipped generation checks must reject the ungenerated tree.
        run('plant-omitted-lean-generation', [cerb/'tools/check_lem_sync.sh', '--check-lean'], cerb, 1)
        run('plant-omitted-ocaml-generation', [cerb/'tools/check_lem_sync.sh', '--check'], cerb, 1)
        prefix = lem / 'local-install'
        common = ['INSTALL_DIR='+str(prefix), 'LEMVERSION='+LEM_REV[:7]]
        run('lem-compiler', ['make', 'bin/lem', *common], lem)
        run('lem-ocaml-library', ['make', '-C', 'library', 'ocaml-libs', *common], lem)
        run('lem-runtime-build', ['make', '-C', 'ocaml-lib', 'all'], lem)
        (prefix/'bin').mkdir(parents=True)
        (prefix/'lib').mkdir()
        (prefix/'share/lem/library').mkdir(parents=True)
        shutil.copy2(lem/'bin/lem', prefix/'bin/lem')
        for pattern in ('*.lem', '*_constants'):
            for path in (lem/'library').glob(pattern):
                shutil.copy2(path, prefix/'share/lem/library'/path.name)
        run('lem-runtime-install', ['make', '-C', 'ocaml-lib', 'install',
                                  'INSTALLDIR='+str(prefix/'lib'), 'LEMVERSION='+LEM_REV[:7]], lem)
        env.update(PATH=str(prefix/'bin')+os.pathsep+env['PATH'], OCAMLPATH=str(prefix/'lib'))
        for pkg in ('lem', 'lem_zarith'):
            actual = subprocess.check_output(['ocamlfind', 'query', pkg], env=env, text=True).strip()
            if Path(actual).resolve() != (prefix/'lib'/pkg).resolve():
                raise RuntimeError(f'wrong OCaml runtime: {pkg}: {actual}')
        # A dependency checkout holds immutable sources, never copied .lake products.
        runtime = cerb/'lean_frontend/.lake/packages/LemLib'
        runtime.parent.mkdir(parents=True)
        run('lake-dependency-clone', ['git', 'clone', '--no-hardlinks', '--no-checkout', args.lem_repo.resolve(), runtime])
        run('lake-dependency-pin', ['git', '-C', runtime, 'checkout', '--detach', LEM_REV])
        pins(cerb, prefix/'bin/lem', runtime)
        report['compiler'] = {'path': str(prefix/'bin/lem'), 'sha256': sha(prefix/'bin/lem'), 'version': LEM_REV[:7]}
        report['ocaml_runtime'] = files(prefix/'lib')
        # Pin plants change only this owned rehearsal, restore, then check again.
        manifest = cerb/'tests/mem-scale-probes/micro/lake-manifest.json'
        original = manifest.read_bytes()
        manifest.write_bytes(original.replace(LEM_REV.encode(), b'0'*40))
        try:
            try: pins(cerb, prefix/'bin/lem', runtime)
            except RuntimeError as exc: report['plant_runtime_pin'] = str(exc)
            else: raise RuntimeError('runtime pin plant accepted')
        finally: manifest.write_bytes(original)
        wrong = out/'wrong-lem'
        wrong.write_text('#!/bin/sh\necho wrong-compiler\n')
        wrong.chmod(0o755)
        try: pins(cerb, wrong, runtime)
        except RuntimeError as exc: report['plant_compiler_pin'] = str(exc)
        else: raise RuntimeError('compiler pin plant accepted')
        pins(cerb, prefix/'bin/lem', runtime)
        run('cerberus-ocaml-generation', ['make', 'prelude-src'], cerb)
        run('cerberus-lean-generation', ['make', 'lean-prelude-src'], cerb)
        run('cerberus-ocaml-build', ['dune', 'build', '--root', cerb, '--force',
                                   'backend/driver/main.exe', 'cerberus-lib.install', 'cerberus.install'], cerb)
        # The cap wraps make too: its nested `lake env` inherits the cgroup.
        run('cerberus-native', [cap, 'make', 'lean-native-obj'], cerb)
        for i, package in enumerate(PACKAGES):
            run('lake-package-'+str(i+1), [cap, 'lake', 'build'], cerb/package)
        client = out/'client'
        client.mkdir()
        proof = ROOT/'tests/provider-smoke/ProviderSmoke.lean'
        shutil.copy2(proof, client/proof.name)
        shutil.copy2(cerb/'lean_frontend/lean-toolchain', client/'lean-toolchain')
        (client/'lakefile.toml').write_text('name = "ProviderSmoke"\ndefaultTargets = ["ProviderSmoke"]\n'
            f'packagesDir = {json.dumps(str(runtime.parent))}\n[[require]]\nname = "CerberusLean"\n'
            f'path = {json.dumps(str(cerb/"lean_frontend"))}\n[[lean_lib]]\nname = "ProviderSmoke"\n')
        report['client'] = {'source': str(proof), 'sha256': sha(proof), 'files': files(client)}
        run('provider-client', [cap, 'lake', 'build'], client)
        run('standalone-lem-runtime', [cap, 'lake', 'build'], lem/'lean-lib')
        run('standalone-lem-comprehensive', ['make', 'lean', 'CAPPED='+str(cap)], lem/'tests/comprehensive')
        pins(cerb, prefix/'bin/lem', runtime)
        report['generated_lean'] = files(cerb/'lean_frontend/generated')
        report['generated_ocaml'] = files(cerb/'ocaml_frontend/generated')
        # artifacts resolves the chosen local compiler from the same environment.
        old_path = os.environ.get('PATH')
        os.environ['PATH'] = env['PATH']
        try: report['artifacts'] = artifacts(cerb)
        finally:
            if old_path is not None: os.environ['PATH'] = old_path
        report['source_after'] = source_identity(cerb)
        if report['sources']['cerberus'] != report['source_after']:
            raise RuntimeError('cold Cerberus source changed during rehearsal')
        report['status'] = 'passed'
        save(out, report)
        return 0
    except (OSError, RuntimeError, subprocess.SubprocessError, RunnerInterrupted) as exc:
        report.update(status='incomplete', error=str(exc))
        save(out, report)
        print('PROVIDER REHEARSAL INCOMPLETE: '+str(exc), file=sys.stderr)
        return 1
    finally:
        for sig, handler in previous_handlers.items():
            signal.signal(sig, handler)


if __name__ == '__main__':
    sys.exit(main())
