#!/usr/bin/env python3
"""Independent pristine OCaml versus fork OCaml over Tier A C inputs and legacy APIs.

Build the pristine side with build_independent_oracle.py first. Every unexpected
difference fails; reviewed exceptions bind both full observations and rationale.
Raw process failures are reported separately from completed semantic verdicts.
"""
from __future__ import annotations

import argparse
from collections import Counter
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import time

from build_independent_oracle import CERBERUS_REV, LEM_REV, files, sha
from observations import ProtocolError, load_capture
from release import artifacts, source_identity

ROOT = Path(__file__).resolve().parent.parent


def validate_build(path):
    manifest = json.loads(path.read_text())
    if manifest['status'] != 'built' or manifest['sources']['lem']['commit'] != LEM_REV or \
            manifest['sources']['cerberus']['commit'] != CERBERUS_REV:
        raise ValueError('independent build is incomplete or has wrong source pins')
    required = {'compiler', 'lem_runtime', 'lem_library', 'generated', 'oracle', 'runtime'}
    if set(manifest['artifacts']) != required or any(not entry.get('files') for entry in
            manifest['artifacts'].values() if 'root' in entry):
        raise ValueError('independent artifact inventory missing or empty')
    if manifest.get('environment', {}).get('DUNE_CACHE') != 'disabled' or \
            not manifest.get('environment', {}).get('GIT_CEILING_DIRECTORIES'):
        raise ValueError('build recipe did not isolate cache/source-version provenance')
    for name, source in manifest['sources'].items():
        if sha(path.parent / (name + '.tar')) != source['archive_sha256']:
            raise ValueError(f'independent {name} source archive changed')
    for name, entry in manifest['artifacts'].items():
        if 'path' in entry:
            if sha(entry['path']) != entry['sha256']:
                raise ValueError(f'independent {name} artifact changed')
        else:
            if files(Path(entry['root'])) != entry['files']:
                raise ValueError(f'independent {name} resources changed or file set drifted')
    return manifest


def capture(prefix, command, env, limit):
    started = time.monotonic()
    command = ['timeout', str(limit), *map(str, command)]
    prefix.with_suffix('.command.json').write_text(json.dumps(command) + '\n')
    with prefix.with_suffix('.stdout').open('wb') as stdout, prefix.with_suffix('.stderr').open('wb') as stderr:
        proc = subprocess.run(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr)
    status = proc.returncode if proc.returncode >= 0 else 128 - proc.returncode
    prefix.with_suffix('.status').write_text(str(status) + '\n')
    diagnostics = prefix.with_suffix('.stderr').read_bytes()
    # backend/driver/main.ml's elapsed-time trailer is instrumentation.
    # Remove only its exact whole-line grammar from diagnostic comparison;
    # preserve all original bytes in the capture and all semantic fields.
    projected = re.sub(rb'^Time spent: [0-9]+\.[0-9]+ seconds\n', b'', diagnostics, flags=re.M)
    return {'status': status, 'seconds': round(time.monotonic() - started, 3),
            'stdout_sha256': sha(prefix.with_suffix('.stdout')),
            'stderr_sha256': sha(prefix.with_suffix('.stderr')),
            'diagnostic_sha256': hashlib.sha256(projected).hexdigest(),
            'capture': str(prefix), 'command': command}


def signature(record):
    return {key: record[key] for key in ('status', 'stdout_sha256', 'stderr_sha256')}


def compare(left, right, kind, exception=None):
    # No exception may admit an incomplete process or silent success.
    if any(r['status'] in (124, 137) for r in (left, right)):
        return 'incomplete', 'timeout or signal termination'
    if exception:
        if exception.get('rationale') and exception.get('upstream') == signature(left) and \
                exception.get('fork') == signature(right):
            return 'reviewed_difference', exception['rationale']
        return 'difference', 'reviewed diagnostic-difference pin moved; review before changing it'
    if kind == 'batch':
        try:
            a, b = load_capture(left['capture']), load_capture(right['capture'])
            if a.verdicts == b.verdicts:
                return 'semantic_agreement', ''
            reason = 'completed semantic observations differ'
        except (ProtocolError, OSError, ValueError) as exc:
            reason = str(exc)
            # This is evidence about matching rejection/failure of the CLI,
            # explicitly not a successful semantic execution comparison.
            if all(left[key] == right[key] for key in ('status', 'stdout_sha256', 'diagnostic_sha256')) and \
                    left['status'] in (1, 125, 134):
                raw = Path(left['capture'] + '.stdout').read_bytes()
                err = Path(left['capture'] + '.stderr').read_bytes()
                if not raw and err:
                    return 'matching_failure', 'same failure under diagnostic projection; no semantic result'
    elif signature(left) == signature(right) and left['status'] == 0:
        if Path(left['capture'] + '.stdout').stat().st_size or kind == 'typecheck':
            return 'interface_agreement', ''
        reason = 'unexpected silent interface success'
    else:
        reason = 'legacy interface output/status differs'
    return 'difference', reason


def corpus(cn_root):
    cases = []
    for folder in ('minimal', 'coverage', 'debug', 'float', 'bytes', 'libc_exec'):
        paths = sorted((ROOT / 'tests' / folder).rglob('*.c'))
        if not paths:
            raise ValueError(f'missing/empty Tier A corpus: {folder}')
        for path in paths:
            if path.name.endswith(('.syntax-only.c', '.exhaust.c')):
                continue  # same explicit execution exclusions as test_exec.sh
            flags = ['--exec', '--batch']
            if folder != 'libc_exec':
                flags += ['--nolibc', '--mode=exhaustive']
            cases.append((str(path.relative_to(ROOT / 'tests')), 'batch', flags + [str(path.relative_to(ROOT))]))
    directories = sorted(p for p in (ROOT / 'tests/multi_tu').iterdir() if p.is_dir())
    if not directories:
        raise ValueError('empty multi-TU corpus')
    for directory in directories:
        paths = sorted(directory.glob('*.c'))
        if len(paths) < 2:
            raise ValueError(f'multi-TU case has fewer than two inputs: {directory}')
        cases.append((f'multi_tu/{directory.name}', 'batch',
                      ['--exec', '--batch', '--nolibc', '--mode=exhaustive',
                       *[str(p.relative_to(ROOT)) for p in paths]]))
    if cn_root is None:
        cn_root = next((parent / 'deps/cn/tests/cn' for parent in ROOT.parents
                        if (parent / 'deps/cn/tests/cn').is_dir()), None)
    if cn_root is None:
        raise ValueError('CN corpus missing; provide --cn-root')
    rows = (ROOT / 'tests/cn_coverage/manifest.txt').read_text().splitlines()
    for row in rows:
        if not row or row.startswith('#'):
            continue
        name, classification, extras, note = row.split('|')
        path = cn_root / name
        tus = [path]
        for extra in filter(None, extras.split(',')):
            tus.append(cn_root / extra[3:] if extra.startswith('cn:') else ROOT / 'tests/cn_coverage' / extra)
        if not all(p.is_file() for p in tus):
            raise ValueError(f'CN input missing: {name}')
        cases.append((f'cn/{name}', 'batch', ['--exec', '--batch', '--nolibc', '--mode=exhaustive',
                                           '-I', str(path.parent), *map(str, tus)]))
    prep = subprocess.check_output([str(ROOT / 'scripts/libxml2_prep.sh'), 'uri.c'], text=True).splitlines()
    if not prep:
        raise ValueError('libxml2 preparation emitted no arguments')
    uri = Path(prep[-1])
    tus = [ROOT / 'tests/libxml2/uri_harness.c', uri,
           *[uri.parent / name for name in ('xmlstring.c', 'xmlmemory.c', 'globals.c')]]
    if not all(p.is_file() for p in tus):
        raise ValueError('libxml2 URI harness/input missing')
    for mode in ('libc', 'nolibc'):
        cases.append(('libxml2/uri-' + mode, 'batch', ['--exec', '--batch',
                      *(['--nolibc'] if mode == 'nolibc' else []), *prep[:-1], *map(str, tus)]))
    # Same representative input through legacy parse/typecheck/pretty-print CLI.
    simple = 'tests/minimal/001-return-literal.c'
    cases.extend([('cli/core-dump', 'core', ['--nolibc', '--pp=core', simple]),
                  ('cli/typecheck-core', 'typecheck', ['--nolibc', '--typecheck-core', simple]),
                  ('cli/args', 'batch', ['--nolibc', '--exec', '--batch', '--args', 'ab cd',
                                        'tests/immaculate/argv/argv1.c'])])
    return cases


def library_probe(out, sides, environments, limit):
    # A public generated helper exercises package
    # resolution/linking. Public pipeline signature drift is a separate reviewed
    # interface limitation, not concealed by pretending this is a full API test.
    source = 'let () = let n = Cerb_frontend.Utils.fromJust "provider-api" (Some 42) in Printf.printf "%d\\n" n\n'
    result = []
    for side in ('upstream', 'fork'):
        directory = out / ('library-' + side)
        directory.mkdir()
        src, exe = directory / 'client.ml', directory / 'client'
        src.write_text(source)
        env = dict(environments[side])
        env['OCAMLPATH'] = str(sides[side]['runtime'] / 'lib') + os.pathsep + env.get('OCAMLPATH', '')
        built = capture(directory / 'build', ['ocamlfind', 'ocamlopt', '-package',
                        'cerberus-lib.mem.concrete', '-linkpkg', src, '-o', exe], env, limit)
        if built['status'] != 0:
            result.append((built, None))
        else:
            result.append((built, capture(directory / 'run', [exe], env, limit)))
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build-manifest', type=Path, default=os.environ.get(
        'CERB_INDEPENDENT_MANIFEST', str(ROOT / '.validation-foundations/independent-oracle-v2/manifest.json')))
    parser.add_argument('--out', type=Path)
    parser.add_argument('--cn-root', type=Path)
    parser.add_argument('--only', help='explicit regex subset; never a full independent lane')
    parser.add_argument('--plant', action='store_true', help='real control plus unexpected fork-verdict mutation')
    parser.add_argument('--timeout', type=float, default=30)
    args = parser.parse_args()
    if args.plant and args.only:
        parser.error('--plant and --only are separate scopes')
    out = args.out.resolve() if args.out else Path(tempfile.mkdtemp(prefix='upstream-oracle-', dir=ROOT / '.tmp'))
    out.mkdir(parents=True, exist_ok=True)
    report = {'schema': 1, 'status': 'incomplete', 'source': source_identity(), 'rows': [],
              'scope': 'plant' if args.plant else 'subset' if args.only else 'Tier A execution C inputs plus representative legacy interfaces',
              'diagnostic_projection': 'remove only ^Time spent: [0-9]+\\.[0-9]+ seconds newline; raw stderr retained',
              'not_applicable': [
                  {'interface': '--cabs-json, --call, --batch-alloc-census',
                   'reason': 'fork extensions; absent from pristine upstream CLI'},
                  {'interface': 'Lean unit/kernel gates and generated fixture pins',
                   'reason': 'provider-specific artifacts; not upstream OCaml interfaces'},
              ]}
    def save():
        temp = out / 'report.tmp'
        temp.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
        temp.replace(out / 'report.json')
    save()
    try:
        manifest = validate_build(args.build_manifest.resolve())
        report['upstream_build_manifest'] = {'path': str(args.build_manifest.resolve()),
                                             'sha256': sha(args.build_manifest)}
        subprocess.run([str(ROOT / 'tools/check_driver_fresh.sh'), '--check-oracle'], check=True)
        fork = ROOT / '_build/default/backend/driver/main.exe'
        report['fork_binary'] = {'path': str(fork), 'sha256': sha(fork)}
        report['fork_artifacts'] = artifacts()
        sides = {'upstream': {'binary': Path(manifest['artifacts']['oracle']['path']),
                               'runtime': Path(manifest['artifacts']['runtime']['root'])},
                 'fork': {'binary': fork, 'runtime': ROOT / '_build/install/default'}}
        envs = {'fork': dict(os.environ), 'upstream': dict(os.environ, **manifest['environment'])}
        exceptions = json.loads((ROOT / 'scripts/upstream_oracle_differences.json').read_text())['cases']
        cases = corpus(args.cn_root)
        if set(exceptions) - {name for name, kind, flags in cases}:
            raise ValueError('reviewed difference refers to a case absent from the corpus')
        report['membership'] = [{'id': name, 'kind': kind, 'arguments': flags} for name, kind, flags in cases]
        inputs = {arg for name, kind, flags in cases for arg in flags if Path(arg).is_file()}
        report['input_files'] = {arg: sha(arg) for arg in sorted(inputs)}
        report['manifest_files'] = {rel: sha(ROOT / rel) for rel in
                                  ['tests/cn_coverage/manifest.txt', 'scripts/upstream_oracle_differences.json',
                                   'tests/libxml2/config/config.h', 'tests/libxml2/config/libxml/xmlversion.h']}
        report['source_archives'] = 'upstream source archives and all binary/runtime hashes checked before dispatch'
        if args.only:
            cases = [case for case in cases if re.search(args.only, case[0])]
        if args.plant:
            cases = [cases[0], ('plant/unexpected-verdict', *cases[0][1:])]
            print('PLANT MODE: passing real pair then mutate the fork engine verdict', flush=True)
        if not cases:
            raise ValueError('empty independent oracle selection')
        for i, (name, kind, flags) in enumerate(cases, 1):
            directory = out / f'{i:04d}'
            directory.mkdir()
            pair = {}
            for side, info in sides.items():
                command = [info['binary'], '--runtime=' + str(info['runtime']), *flags]
                if args.plant and name.startswith('plant/') and side == 'fork':
                    wrapper = ('import subprocess,sys; p=subprocess.run(sys.argv[1:],capture_output=True); '
                               'sys.stdout.buffer.write(p.stdout.replace(b"Specified(",b"Specified(999")); '
                               'sys.stderr.buffer.write(p.stderr); sys.exit(p.returncode)')
                    command = [sys.executable, '-c', wrapper, *command]
                pair[side] = capture(directory / side, command, envs[side], args.timeout)
            status, reason = compare(pair['upstream'], pair['fork'], kind, exceptions.get(name))
            if args.plant and name.startswith('plant/'):
                status = 'plant_rejected' if status == 'difference' else 'plant_failed'
            report['rows'].append({'id': name, 'kind': kind, 'status': status, 'reason': reason, **pair})
            print(f'{i}/{len(cases)} {status}: {name}', flush=True)
            save()
        if not args.only and not args.plant:
            library = library_probe(out, sides, envs, args.timeout)
            report['library_probe'] = library
            if all(run and run['status'] == 0 and Path(run['capture'] + '.stdout').read_bytes() == b'42\n'
                   for build, run in library):
                report['library_status'] = 'passed'
            else:
                report['library_status'] = 'failed'
        report['counts'] = dict(Counter(row['status'] for row in report['rows']))
        report['source_after'] = source_identity()
        report['source_unchanged'] = report['source_after'] == report['source']
        failed = any(row['status'] in ('difference', 'incomplete', 'plant_failed') for row in report['rows']) or report.get('library_status') == 'failed' or not report['source_unchanged']
        report['status'] = 'failed' if failed else 'plants_passed' if args.plant else 'subset_passed' if args.only else 'passed'
        save()
        print(f'Independent oracle: {report["status"]}; {report["counts"]}; {out / "report.json"}', flush=True)
        return int(failed)
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as exc:
        report.update(status='incomplete', error=str(exc))
        save()
        print(f'INDEPENDENT ORACLE INCOMPLETE: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
