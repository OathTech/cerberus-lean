#!/usr/bin/env python3
"""D3 ratio derivation for the are-compatible-assumed-set slice (charter D3).

Usage: python3 derive-d3-ratios.py EVIDENCE_DIR

Reads cpu-before-15.tsv (the primary checkout at mainline 86daea264, the pre-change
binaries, measured read-only) and cpu-after-15.tsv (this branch), both produced by
scripts/measure_csmith_cpu.py --max 470 --timeout 15 (the csmith small_arrays set, one
row per input per engine, CPU = GNU time user+sys at 0.01 s precision). Pairs the LEAN
rows of every input whose joint lane status is MATCH on both runs, writes
cpu-ratios.tsv (ratio = cpu_after / cpu_before as an exact Decimal quotient printed to
six places; over_1_10 = YES when cpu_after > 1.10 * cpu_before), and prints the
aggregate ratio (sum of after CPU / sum of before CPU over the compared rows), the
over-bar rows with both CPUs, every status movement between the two runs, and the
rows excluded (either side not MATCH). Nothing is censored: every input appears
either in the ratio table or in the exclusion list.
"""
import csv
from decimal import Decimal as D
from pathlib import Path
import sys


def read(path):
    return list(csv.DictReader(path.open(), delimiter='\t'))


def main(e):
    before = read(e / 'cpu-before-15.tsv')
    after = read(e / 'cpu-after-15.tsv')
    def by_input(rows):
        out = {}
        for r in rows:
            out.setdefault(r['input'], {})[r['engine']] = r
        return out
    b, a = by_input(before), by_input(after)
    assert set(b) == set(a), (set(b) ^ set(a))
    ratios, excluded, moved = [], [], []
    for name in sorted(b):
        sb, sa = b[name]['lean']['status'], a[name]['lean']['status']
        if sb != sa:
            moved.append((name, sb, sa))
        if sb == 'MATCH' and sa == 'MATCH':
            cb, ca = D(b[name]['lean']['cpu_s']), D(a[name]['lean']['cpu_s'])
            ratio = ca / cb if cb else None
            ratios.append(dict(input=name, cpu_before=f'{cb:.2f}', cpu_after=f'{ca:.2f}',
                               ratio=('NA' if ratio is None else f'{ratio:.6f}'),
                               over_1_10=('YES' if ca > D('1.10') * cb else 'NO'),
                               oracle_cpu_before=b[name]['oracle']['cpu_s'],
                               oracle_cpu_after=a[name]['oracle']['cpu_s']))
        else:
            excluded.append((name, sb, sa))
    with (e / 'cpu-ratios.tsv').open('w') as f:
        w = csv.DictWriter(f, fieldnames=list(ratios[0]), delimiter='\t', lineterminator='\n')
        w.writeheader(); w.writerows(ratios)
    sb_ = sum(D(r['cpu_before']) for r in ratios); sa_ = sum(D(r['cpu_after']) for r in ratios)
    print(f'compared (lean MATCH on both): {len(ratios)} rows; excluded: {len(excluded)}; status movements: {len(moved)}')
    print(f'aggregate lean CPU before={sb_:.2f} s after={sa_:.2f} s ratio={sa_ / sb_:.6f}')
    ob = [r for r in ratios if r['over_1_10'] == 'YES']
    print(f'rows over the 1.10 bar: {len(ob)}')
    for r in ob:
        print(f"  {r['input']}\tbefore={r['cpu_before']}\tafter={r['cpu_after']}\tratio={r['ratio']}")
    for name, sb, sa in moved:
        print(f'STATUS MOVED: {name}\t{sb} -> {sa}')
    print('excluded (status before -> after):')
    from collections import Counter
    print('  ' + str(Counter((sb, sa) for _, sb, sa in excluded)))


if __name__ == '__main__':
    main(Path(sys.argv[1]))
