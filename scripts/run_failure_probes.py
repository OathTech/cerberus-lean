#!/usr/bin/env python3
"""Measure deliberate-failure strictness on the identified provider toolchain.

Known disagreement is a finding, not a passing semantic comparison. The
script succeeds when every probe was built/run and its controls behaved;
the report preserves all original statuses, streams and source identities.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

from build_independent_oracle import sha, files

ROOT = Path(__file__).resolve().parent.parent
NAMES = ('unused_binding', 'unused_argument', 'projection', 'discarded_result',
         'callback', 'mapped_projection', 'required', 'control')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--provider-manifest', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    args = parser.parse_args()
    manifest = json.loads(args.provider_manifest.read_text())
    if manifest['status'] != 'passed':
        raise SystemExit('provider manifest is not a completed rehearsal')
    provider = args.provider_manifest.resolve().parent
    lem, cerb = provider/'lem', provider/'cerberus'
    compiler = lem/'local-install/bin/lem'
    if sha(compiler) != manifest['compiler']['sha256']:
        raise SystemExit('provider compiler bytes changed')
    out = args.out.resolve()
    out.mkdir(parents=True, exist_ok=False)
    env = dict(os.environ, CERB_MEM_MAX='32G', LEAN_ABORT_ON_PANIC='1')
    cap = ROOT/'scripts/capped'
    report = {'schema': 1, 'status': 'incomplete', 'provider_manifest_sha256': sha(args.provider_manifest),
              'compiler': manifest['compiler'], 'commands': [], 'observations': []}

    def save():
        (out/'report.json').write_text(json.dumps(report, indent=2)+'\n')

    def run(name, command, expected=None):
        proc = subprocess.run(list(map(str, command)), cwd=out, env=env, capture_output=True, timeout=120)
        (out/(name+'.stdout')).write_bytes(proc.stdout)
        (out/(name+'.stderr')).write_bytes(proc.stderr)
        (out/(name+'.status')).write_text(str(proc.returncode)+'\n')
        row = {'name': name, 'command': list(map(str, command)), 'exit_status': proc.returncode,
               'stdout_sha256': sha(out/(name+'.stdout')), 'stderr_sha256': sha(out/(name+'.stderr'))}
        report['commands'].append(row)
        save()
        if expected is not None and proc.returncode != expected:
            raise RuntimeError(f'{name}: exit {proc.returncode}; see retained streams')
        return proc

    try:
        for name in ('discarded_failures.lem', 'failure_main.ml', 'FailureMain.lean'):
            shutil.copy2(ROOT/'tests/failure-probes'/name, out/name)
        shutil.copy2(cerb/'lean_frontend/lean-toolchain', out/'lean-toolchain')
        runtime = cerb/'lean_frontend/.lake/packages/LemLib/lean-lib'
        (out/'lakefile.toml').write_text('name = "FailureProbes"\ndefaultTargets = ["failure-probes"]\n'
            f'[[require]]\nname = "LemLib"\npath = {json.dumps(str(runtime))}\n'
            '[[lean_lib]]\nname = "FailureInputs"\nroots = ["Discarded_failures"]\n'
            '[[lean_exe]]\nname = "failure-probes"\nroot = "FailureMain"\n')
        report['inputs'] = files(out)
        run('generate', [compiler, '-wl', 'ign', '-i', lem/'library/pervasives_extra.lem',
                         '-lean', '-ocaml', 'discarded_failures.lem'], 0)
        ocamllib = lem/'ocaml-lib/_build_zarith'
        run('ocaml-build', ['ocamlfind', 'ocamlopt', '-package', 'zarith', '-linkpkg', '-I', ocamllib,
                            ocamllib/'extract.cmxa', 'discarded_failures.ml', 'failure_main.ml', '-o', 'oracle'], 0)
        run('lean-build', [cap, 'lake', 'build'], 0)
        report['artifacts'] = {p: sha(out/p) for p in ['oracle', '.lake/build/bin/failure-probes',
                              'Discarded_failures.lean', 'discarded_failures.ml', 'lake-manifest.json']}
        for name in NAMES:
            observed = {}
            for side, command in [('ocaml', [out/'oracle', name]),
                                  ('lean-native', [out/'.lake/build/bin/failure-probes', name]),
                                  ('lean-interpreted', [cap, 'lake', 'env', 'lean', '--run', 'FailureMain.lean', name])]:
                proc = run(name+'.'+side, command)
                observed[side] = {'exit_status': proc.returncode,
                    'stdout_last_line': proc.stdout.decode(errors='replace').splitlines()[-1:]}
            report['observations'].append({'mechanism': name, 'results': observed})
            save()
            print(name+': '+json.dumps(observed), flush=True)
        controls = {r['mechanism']: r['results'] for r in report['observations']}
        if any(r['exit_status'] != 0 or r['stdout_last_line'] != ['1'] for r in controls['control'].values()):
            raise RuntimeError('positive control failed')
        if any(r['exit_status'] == 0 for r in controls['required'].values()):
            raise RuntimeError('required failure control failed')
        if any(r['results']['ocaml']['exit_status'] == 0 for r in report['observations'] if r['mechanism'] != 'control'):
            raise RuntimeError('strict OCaml failure was not triggered')
        report.update(status='measured', semantic_parity='inspect observations; known failures are not waived')
        save()
        return 0
    except (OSError, RuntimeError, subprocess.SubprocessError) as exc:
        report.update(status='incomplete', error=str(exc))
        save()
        print(str(exc), file=sys.stderr)
        return 1


if __name__ == '__main__': sys.exit(main())
