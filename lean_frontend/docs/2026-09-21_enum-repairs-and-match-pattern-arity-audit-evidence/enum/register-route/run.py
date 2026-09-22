"""Check the Core-TEXT entry route asserted by the new failure-register row."""
from pathlib import Path
import json, os, subprocess

root = Path.cwd()
out = root / '.tmp/two-range-audit/register-route'
oracle = root / '.validation-foundations/independent-oracle-v2/cerberus'
env = {**os.environ, 'CERB_MEM_MAX': '8G', 'LEAN_ABORT_ON_PANIC': '1'}
results = []
for name, ctype in [('signed-control', 'signed int'), ('enum-query', 'enum E')]:
    source = out / (name + '.core')
    source.write_text("proc main (): eff loaded integer :=\n"
                      f"  pure (Specified (if is_signed('{ctype}') then 1 else 0))\n")
    for side, tree in [('fork', root), ('pristine', oracle)]:
        args = [str(tree / '_build/default/backend/driver/main.exe'),
                '--runtime=' + str(tree / '_build/install/default'),
                '--nolibc', '--exec', '--batch', '--mode=exhaustive', str(source)]
        p = subprocess.run(args, env=env, capture_output=True, text=True, timeout=30)
        row = dict(case=name, engine=side, args=args, status=p.returncode,
                   stdout=p.stdout, stderr=p.stderr)
        results.append(row)
        print(name, side, p.returncode, p.stdout, p.stderr, flush=True)
    args = [str(root / 'scripts/capped'),
            str(root / 'lean_frontend/.lake/build/bin/cerberus-lean'),
            '--parse-core', str(source)]
    p = subprocess.run(args, env=env, capture_output=True, text=True, timeout=30)
    results.append(dict(case=name, engine='lean-parse-only', args=args,
                        status=p.returncode, stdout=p.stdout, stderr=p.stderr))
    print(name, 'lean-parse-only', p.returncode, p.stdout, p.stderr, flush=True)
(out / 'results.json').write_text(json.dumps(results, indent=2) + '\n')
