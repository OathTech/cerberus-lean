#!/usr/bin/env python3
"""Repeat the D3 over-bar rows serially with each tree's measure.sh (charter D3, the
"exceptions listed and attributed" clause).

Usage: python3 repeat-d3-exceptions.py --pre-repo DIR --after-repo DIR --evidence DIR
       [--repeats N] [--out DIR]

Reads cpu-ratios.tsv (derive-d3-ratios.py), takes every row with over_1_10 = YES,
re-stages each input exactly as scripts/test_csmith_corpus.sh does (the kit header
shim `#define CSMITH_MINIMAL / #include "csmith_cerberus.h"`, the sa_ prefix, the two
headers copied beside it), and runs tests/mem-scale-probes/measure.sh --nolibc
--timeout 15 --engines oracle,lean-exh in the PRE tree and the AFTER tree
alternately, N times each (odd repeats pre-first, even repeats after-first). Writes
cpu-repeats.tsv (one row per input: every repeat's lean CPU on both sides, the means,
the mean ratio, over_1_10 by the means) and prints the tally. Every engine pair must
agree on the verdict line multiset with the D3 runs' MATCH; a disagreement aborts.
Nothing is repeated until it passes: N is fixed on the command line and recorded.
Run under scripts/capped with CERB_MEM_MAX=48G, with no other heavy job on the box.
"""
import argparse
import csv
from decimal import Decimal as D
import hashlib
import io
import json
from pathlib import Path
import subprocess
import sys
import datetime

COLS = ['probe', 'mode', 'engine', 'exit', 'wall_s', 'maxrss_kb', 'verdict', 'note', 'cpu_s']


def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--pre-repo', type=Path, required=True)
    ap.add_argument('--after-repo', type=Path, required=True)
    ap.add_argument('--evidence', type=Path, required=True)
    ap.add_argument('--repeats', type=int, default=2)
    ap.add_argument('--out', type=Path, default=Path('.tmp/acas-repeats'))
    a = ap.parse_args()
    out = a.out.resolve(); out.mkdir(parents=True, exist_ok=False)
    staged = out / 'staged'; staged.mkdir()
    hdr = a.after_repo / 'tests/csmith'
    for h in ('csmith_cerberus.h', 'safe_math.h'):
        (staged / h).write_bytes((hdr / h).read_bytes())
    ratios = list(csv.DictReader((a.evidence / 'cpu-ratios.tsv').open(), delimiter='\t'))
    todo = [r for r in ratios if r['over_1_10'] == 'YES']
    meta = dict(start=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                uptime_start=subprocess.check_output(['uptime'], text=True).strip(),
                repeats=a.repeats, timeout_s=15, inputs=len(todo),
                pre_head=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=a.pre_repo, text=True).strip(),
                after_head=subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=a.after_repo, text=True).strip(),
                pre_lean=sha(a.pre_repo / 'lean_frontend/.lake/build/bin/cerberus-lean'),
                after_lean=sha(a.after_repo / 'lean_frontend/.lake/build/bin/cerberus-lean'),
                pre_oracle=sha(a.pre_repo / '_build/default/backend/driver/main.exe'),
                after_oracle=sha(a.after_repo / '_build/default/backend/driver/main.exe'))
    repos = {'pre': a.pre_repo, 'after': a.after_repo}
    rows = []
    for r in todo:
        name = r['input']                       # sa_csmith_NNN.c
        src = hdr / 'small_arrays' / name[len('sa_'):]
        text = src.read_text()
        staged_text = text.replace('#include "csmith.h"', '#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"')
        (staged / name).write_text(staged_text)
        cpus = {'pre': [], 'after': []}
        verdicts = set()
        for rep in range(1, a.repeats + 1):
            for rev in (('pre', 'after') if rep % 2 else ('after', 'pre')):
                run = out / f'r{rep}-{rev}-{name}'
                cmd = [str(repos[rev] / 'tests/mem-scale-probes/measure.sh'), '--nolibc', '--timeout', '15',
                       '--engines', 'oracle,lean-exh', '--outdir', str(run), str(staged / name)]
                res = subprocess.run(cmd, cwd=repos[rev], text=True, capture_output=True)
                if res.returncode != 0:
                    print(f'ABORT: measure.sh rc={res.returncode} for {rev} {name}\n{res.stderr[-2000:]}'); sys.exit(1)
                (run / 'measure.stdout').write_text(res.stdout)
                trows = list(csv.DictReader(io.StringIO(res.stdout), fieldnames=COLS, delimiter='\t'))
                trows = [t for t in trows if t['probe'] != 'probe']
                lean = [t for t in trows if t['engine'] == 'lean-exh']
                orac = [t for t in trows if t['engine'] == 'oracle']
                assert len(lean) == 1 and len(orac) == 1, trows
                if lean[0]['verdict'] != orac[0]['verdict'] or lean[0]['exit'] != '0':
                    print(f'ABORT: verdict disagreement or failure on {rev} {name}: {trows}'); sys.exit(1)
                verdicts.add(lean[0]['verdict'])
                cpus[rev].append(D(lean[0]['cpu_s']))
        if len(verdicts) != 1:
            print(f'ABORT: verdicts differ across repeats for {name}: {verdicts}'); sys.exit(1)
        mp = sum(cpus['pre']) / len(cpus['pre']); ma = sum(cpus['after']) / len(cpus['after'])
        row = dict(input=name, initial_before=r['cpu_before'], initial_after=r['cpu_after'], initial_ratio=r['ratio'])
        for i in range(a.repeats):
            row[f'pre_{i+1}'] = f"{cpus['pre'][i]:.2f}"; row[f'after_{i+1}'] = f"{cpus['after'][i]:.2f}"
        row.update(mean_before=f'{mp:.4f}', mean_after=f'{ma:.4f}',
                   mean_ratio=(f'{ma / mp:.6f}' if mp else 'NA'), over_1_10_by_means=('YES' if ma > D('1.10') * mp else 'NO'))
        rows.append(row)
        print(f"{name}\tpre={row['mean_before']}\tafter={row['mean_after']}\tratio={row['mean_ratio']}\t{row['over_1_10_by_means']}", flush=True)
    with (a.evidence / 'cpu-repeats.tsv').open('w') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]), delimiter='\t', lineterminator='\n'); w.writeheader(); w.writerows(rows)
    meta.update(end=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                uptime_end=subprocess.check_output(['uptime'], text=True).strip(),
                still_over=[r['input'] for r in rows if r['over_1_10_by_means'] == 'YES'])
    (a.evidence / 'cpu-repeats.meta.json').write_text(json.dumps(meta, indent=2) + '\n')
    print(f"repeated {len(rows)} inputs x {a.repeats}; still over 1.10 by means: {len(meta['still_over'])} {meta['still_over']}")


if __name__ == '__main__':
    main()
