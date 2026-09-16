"""Bounded design probes; run through scripts/ce and scripts/capped.

The provider argument names an already-built Cerberus checkout. This does not
modify the provider or implement the proposed outcome change in its model.
"""

import argparse
import hashlib
import os
from pathlib import Path
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--provider', type=Path, required=True)
    args = parser.parse_args()
    provider = args.provider.resolve()
    frontend = provider / 'lean_frontend'
    sources = Path(__file__).resolve().parent
    inputs = [
        'outcomes_probe_stop.lem', 'outcomes_probe_undefined.lem',
        'outcomes_probe_nd.lem', 'Probe.lean', 'ProbeBefore.lean', 'Native.ml',
        'Traversal.lean',
    ]
    env = dict(os.environ)
    env['ELAN_TOOLCHAIN'] = (frontend / 'lean-toolchain').read_text().strip()
    revision = subprocess.check_output(
        ['git', 'rev-parse', 'HEAD'], cwd=provider, text=True).strip()
    print('Provider source revision:', revision, flush=True)
    print('Lean toolchain:', env['ELAN_TOOLCHAIN'], flush=True)
    print('ProbeBefore imports the existing compiled provider Undefined module.', flush=True)
    for name in inputs:
        print('SHA256', hashlib.sha256((sources / name).read_bytes()).hexdigest(), name, flush=True)

    with tempfile.TemporaryDirectory(prefix='d2-outcomes-review-') as tmp:
        scratch = Path(tmp)
        for name in inputs:
            shutil.copyfile(sources / name, scratch / name)
        env['LEAN_PATH'] = ':'.join(map(str, [
            scratch, frontend / '.lake/build/lib/lean',
            frontend / '.lake/packages/LemLib/lean-lib/.lake/build/lib/lean',
        ]))
        commands = [
            ['lem', '-v'], ['ocamlc', '-version'], ['lean', '--version'],
            ['lem', '-lib', '.', '-ocaml', '-lean', '-outdir', '.', *inputs[:3]],
        ]
        for name in ('Outcomes_probe_stop', 'Outcomes_probe_undefined', 'Outcomes_probe_nd'):
            commands.append(['lean', '-o', name + '.olean', name + '.lean'])
        commands += [
            ['lean', 'Probe.lean'], ['lean', 'ProbeBefore.lean'],
            ['lean', 'Traversal.lean'],
            ['ocamlfind', 'ocamlc', '-package', 'lem', '-linkpkg', '-w', '@8',
             '-o', 'native-probe', 'outcomes_probe_stop.ml',
             'outcomes_probe_undefined.ml', 'outcomes_probe_nd.ml', 'Native.ml'],
            ['./native-probe'],
        ]
        for command in commands:
            print('$', ' '.join(command), flush=True)
            result = subprocess.run(command, cwd=scratch, env=env,
                                    stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, text=True)
            print(result.stdout, end='', flush=True)
            print('exit:', result.returncode, flush=True)
            if result.returncode:
                raise SystemExit(result.returncode)
    print('PASS: bounded design probes completed; temporary build removed.', flush=True)


if __name__ == '__main__':
    main()
