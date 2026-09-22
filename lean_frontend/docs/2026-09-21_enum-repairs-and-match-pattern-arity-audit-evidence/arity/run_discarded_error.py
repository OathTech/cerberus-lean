"""Check whether the tuple-typing truncation suppresses a real error."""
from pathlib import Path
import json, subprocess

root = Path.cwd()
out = root / '.tmp/two-range-audit'
base = root.parent / 'enum-base-20260920'
pristine = root / '.validation-foundations/independent-oracle-v2/cerberus'
cases = {
    'pure-let-discarded-error': '''proc main (): eff loaded integer :=
  pure (Specified (let (a: integer, b: integer) = (1, 2, error(<<<surplus>>>, 3)) in a + b))
''',
    'unseq-discarded-error': '''proc main (): eff loaded integer :=
  let weak (a: integer, b: integer) = unseq(pure (1), pure (2), pure (error(<<<surplus>>>, 3))) in
    pure (Specified (a + b))
''',
}
rows = []
for name, source in cases.items():
    pth = out / 'core-probes' / (name + '.core')
    pth.write_text(source)
    for label, tree in [('base', base), ('head', root), ('pristine', pristine)]:
        for typed in [False, True]:
            args = [str(tree / '_build/default/backend/driver/main.exe'),
                    '--runtime=' + str(tree / '_build/install/default'),
                    '--nolibc', '--exec', '--batch', '--mode=exhaustive']
            if typed:
                args.append('--typecheck-core')
            args.append(str(pth))
            p = subprocess.run(args, capture_output=True, text=True, timeout=30)
            rows.append(dict(case=name, engine=label, typed=typed, args=args,
                             status=p.returncode, stdout=p.stdout, stderr=p.stderr))
            print(name, label, 'typed' if typed else 'default', p.returncode,
                  p.stdout.strip(), p.stderr.strip(), flush=True)
(out / 'discarded-error-results.json').write_text(json.dumps(rows, indent=2) + '\n')
