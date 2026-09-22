from pathlib import Path
import json, os, subprocess, sys

root = Path.cwd()
out = root / '.tmp/two-range-audit'
base = root.parent / 'enum-base-20260920'
pristine = root / '.validation-foundations/independent-oracle-v2/cerberus'
sys.path.insert(0, str(root / 'scripts'))
from observations import parse

records = []
for source in sorted((out / 'core-probes').glob('*.core')):
    if 'discarded-error' in source.stem: continue
    if not source.stem.startswith(('seq-', 'unseq-')): continue
    for engine, tree in [('base', base), ('head', root), ('pristine', pristine)]:
        for typed in [False, True]:
            name = engine + ('-typed' if typed else '-default')
            dest = out / 'core-captures' / source.stem / name
            dest.mkdir(parents=True, exist_ok=True)
            args = [str(tree / '_build/default/backend/driver/main.exe'),
                    '--runtime=' + str(tree / '_build/install/default'),
                    '--nolibc', '--exec', '--batch', '--mode=exhaustive']
            if typed:
                args.append('--typecheck-core')
            args.append(str(source))
            p = subprocess.run(['timeout', '30s', *args], capture_output=True,
                               env={**os.environ, 'NO_COLOR': '1', 'TERM': 'dumb'})
            for suffix, data in [('stdout', p.stdout), ('stderr', p.stderr),
                                 ('status', str(p.returncode).encode())]:
                (dest / suffix).write_bytes(data)
            row = {'case': source.stem, 'engine': name, 'args': args, 'status': p.returncode}
            try:
                row['tokens'] = parse(p.stdout, p.stderr, p.returncode, 'batch').tokens('full')
            except Exception as e:
                row['protocol_error'] = str(e)
            records.append(row)
            print(source.stem, name, p.returncode, row.get('tokens', row.get('protocol_error')), flush=True)
(out / 'core-sequence-results.json').write_text(json.dumps(records, indent=2) + '\n')
