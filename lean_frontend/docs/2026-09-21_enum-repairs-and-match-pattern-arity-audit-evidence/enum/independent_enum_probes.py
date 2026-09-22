from pathlib import Path
import json, os, re, subprocess, sys

root = Path.cwd()
out = root / '.tmp/two-range-audit'
sys.path.insert(0, str(root / 'scripts'))
from observations import parse
prior = json.loads((out / 'probes-results.json').read_text())
expected = {r['case']: r['tokens'] for r in prior if r['engine'] == 'fork'
            and r['status'] == 0 and r.get('tokens')}
pristine = root / '.validation-foundations/independent-oracle-v2/cerberus'
rows = []
for case, tokens in sorted(expected.items()):
    source = out / 'probes' / (case + '.c')
    dest = out / 'independent-captures' / case
    dest.mkdir(parents=True, exist_ok=True)
    args = [str(pristine / '_build/default/backend/driver/main.exe'),
            '--runtime=' + str(pristine / '_build/install/default'),
            '--nolibc', '--exec', '--batch', '--mode=exhaustive', str(source)]
    p = subprocess.run(['timeout', '30s', *args], capture_output=True)
    (dest / 'pristine.stdout').write_bytes(p.stdout)
    (dest / 'pristine.stderr').write_bytes(p.stderr)
    got = parse(p.stdout, p.stderr, p.returncode, 'batch').tokens('full')
    row = {'case': case, 'pristine_args': args, 'pristine_status': p.returncode,
           'pristine_tokens': got, 'expected': tokens, 'pristine_match': got == tokens}
    args = ['gcc', '-std=gnu11', '-O0', str(source), '-o', str(dest / 'native')]
    p = subprocess.run(args, capture_output=True, timeout=30)
    (dest / 'gcc.stdout').write_bytes(p.stdout)
    (dest / 'gcc.stderr').write_bytes(p.stderr)
    row.update(gcc_args=args, gcc_compile_status=p.returncode)
    if p.returncode == 0:
        p = subprocess.run([str(dest / 'native')], capture_output=True, timeout=30)
        (dest / 'native.stdout').write_bytes(p.stdout)
        (dest / 'native.stderr').write_bytes(p.stderr)
        row.update(native_status=p.returncode)
        match = re.search(r'Specified\((-?\d+)\)', tokens[0])
        row['gcc_match'] = len(tokens) == 1 and match is not None and p.returncode == int(match[1]) % 256
    else:
        row['gcc_match'] = False
    rows.append(row)
    print(case, 'pristine', row['pristine_match'], 'gcc', row['gcc_match'], flush=True)
(out / 'independent-enum-results.json').write_text(json.dumps(rows, indent=2) + '\n')
assert len(rows) == 24
assert all(r['pristine_match'] and r['pristine_status'] == 0 and r['gcc_match'] for r in rows)
