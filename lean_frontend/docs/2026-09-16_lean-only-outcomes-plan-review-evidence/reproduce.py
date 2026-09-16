"""Run under scripts/ce and scripts/capped; requires the built S0 prototype.

Only a TemporaryDirectory is used for generated files and compiled artifacts.
The prototype is read, not rebuilt or edited. No dependencies are downloaded.
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
    parser.add_argument('--prototype', type=Path, required=True)
    args = parser.parse_args()
    prototype = args.prototype.resolve()
    frontend = prototype / 'lean_frontend'
    here = Path(__file__).resolve().parent
    prior = here.parent / '2026-09-16_lean-only-outcomes-S0-checkpoint-evidence/S0_3_Traversal.lean'
    revision = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=prototype,
                                       text=True).strip()
    assert revision == '8f8c4dfe7bf30c8733d2ea9590f8f5ef3c4a930b', revision
    env = dict(os.environ)
    env['ELAN_TOOLCHAIN'] = (frontend / 'lean-toolchain').read_text().strip()
    inputs = [prior, *(here / n for n in (
        'PrefixStop.lean', 'NativeOrder.ml', 'default_alias.lem', 'default_mono.lem')),
        prototype / 'ocaml_frontend/generated/exception.ml',
        prototype / 'ocaml_frontend/generated/state_exception.ml']
    print('Prototype revision:', revision, flush=True)
    print('Lean toolchain:', env['ELAN_TOOLCHAIN'], flush=True)
    print('Using existing compiled prototype Lean modules; no rebuild.', flush=True)
    for source in inputs:
        print('SHA256', hashlib.sha256(source.read_bytes()).hexdigest(), source.name, flush=True)
    for name in ('State_exception_undefined', 'Exception_undefined', 'Undefined', 'Interp_stop'):
        path = frontend / '.lake/build/lib/lean' / (name + '.olean')
        print('ARTIFACT_SHA256', hashlib.sha256(path.read_bytes()).hexdigest(), path.name, flush=True)

    with tempfile.TemporaryDirectory(prefix='s0-plan-review-') as tmp:
        scratch = Path(tmp)
        for source in inputs:
            shutil.copyfile(source, scratch / source.name)
        for name in ('exception.ml', 'state_exception.ml'):
            module = scratch / name
            original = module.read_text()
            assert original.count('open Utils\n') == 1
            module.write_text(original.replace('open Utils\n', ''))
            print('Native probe: removed only unused open Utils from copied', name,
                  '; all definitions unchanged.', flush=True)
        env['LEAN_PATH'] = ':'.join(map(str, [scratch, frontend / '.lake/build/lib/lean',
            frontend / '.lake/packages/LemLib/lean-lib/.lake/build/lib/lean']))

        def run(command, expected=0):
            print('$', ' '.join(command), flush=True)
            result = subprocess.run(command, cwd=scratch, env=env,
                                    stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
            print(result.stdout, end='', flush=True)
            print('exit:', result.returncode, '(expected', str(expected) + ')', flush=True)
            assert (result.returncode == 0) if expected == 0 else (result.returncode != 0)
            return result.stdout

        run(['lem', '-v'])
        run(['ocamlc', '-version'])
        run(['lean', '--version'])
        run(['lean', '-o', 'S0_3_Traversal.olean', 'S0_3_Traversal.lean'])
        run(['lean', 'PrefixStop.lean'])
        run(['ocamlfind', 'ocamlc', '-package', 'lem', '-linkpkg', '-w', '@8',
             '-o', 'native-order', 'exception.ml', 'state_exception.ml', 'NativeOrder.ml'])
        run(['./native-order'])
        run(['lem', '-lean', '-outdir', '.', 'default_alias.lem'])
        generated = (scratch / 'Default_alias.lean').read_text()
        assert 'default := ViaAlias default' in generated
        assert 'default := Direct default' not in generated
        print('Generated alias probe default instances (selected verbatim lines):', flush=True)
        for line in generated.splitlines():
            if ' : Inhabited ' in line or 'default :=' in line:
                print(line, flush=True)
        failure = run(['lem', '-lean', '-outdir', '.', 'default_mono.lem'], expected=1)
        assert "cannot derive an Inhabited instance for type 'blocked'" in failure
    print('PASS: all review controls met their stated expectations; temporary build removed.', flush=True)


if __name__ == '__main__':
    main()
