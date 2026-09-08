#!/usr/bin/env python3
"""Derive D4 tables from committed D1-D3 evidence and the completed raw D4 run.

Usage: python3 derive-after-ratios.py EVIDENCE_DIR D4_RAW_DIR
No timing is censored into a completed CPU ratio. Exact decimal comparisons
use the ratio of the two CPU sums; printed ratios have six decimal places.
"""
import csv
from decimal import Decimal as D
import hashlib
import json
from pathlib import Path
import statistics
import sys


def read(path):
    return list(csv.DictReader(path.open(), delimiter='\t'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, rows):
    with path.open('w') as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0]), delimiter='\t', lineterminator='\n')
        w.writeheader()
        w.writerows(rows)


def main(e, raw):
    meta = json.loads((raw / 'metadata.json').read_text())
    assert meta['identities_unchanged'] and meta['end']
    ordinary = read(raw / 'observations.tsv')
    assert len(ordinary) == 2296
    obs = {(r['input'], r['revision'], r['repeat']): r for r in ordinary if r['engine'] == 'lean-exh'}
    assert len(obs) == 1148
    verdicts = json.loads((raw / 'verdicts.json').read_text())
    assert len(verdicts) == 574
    after = {r['input']: r for r in read(e / 'head-after-15.tsv') if r['engine'] == 'lean'}
    fallback = [D(r['cpu_s']) for r in read(e / 'candidate3-fused-90.tsv')
                if r['probe'] == 'sa_csmith_419' and r['engine'] == 'lean-exh']
    assert len(fallback) == 2
    rows = []
    for r in read(e / 'before-prearc-ratios.tsv'):
        n = r['input']
        a = after[n]
        initial_pre = D(r['cpu_pre'])
        if a['status'] == 'MATCH':
            initial_after = D(a['cpu_s'])
            source = '15s_full_lane'
        else:
            assert n == 'sa_csmith_419.c' and a['status'] == 'TIMEOUT'
            initial_after = sum(fallback) / 2
            source = 'two_completed_90s_candidate3_runs'
        cpus = {(rev, rep): D(obs[n, rev, rep]['cpu_s']) for rev in ('pre', 'after') for rep in ('1', '2')}
        pre, head = (sum(cpus[rev, rep] for rep in ('1', '2')) / 2 for rev in ('pre', 'after'))
        over = head > D('1.10') * pre
        rows.append(dict(input=n, cpu_pre_initial=f'{initial_pre:.3f}', cpu_after_initial=f'{initial_after:.3f}',
                         ratio_initial=f'{initial_after / initial_pre:.6f}', initial_after_source=source,
                         status_pre_15=r['status_pre_15'], status_after_15=a['status'],
                         pre_1=f'{cpus["pre", "1"]:.2f}', after_1=f'{cpus["after", "1"]:.2f}',
                         pre_2=f'{cpus["pre", "2"]:.2f}', after_2=f'{cpus["after", "2"]:.2f}',
                         cpu_pre_mean=f'{pre:.3f}', cpu_after_mean=f'{head:.3f}', ratio=f'{head / pre:.6f}',
                         exceeds_1_10='YES' if over else 'NO'))
    assert len(rows) == 287
    write(e / 'after-prearc-ratios.tsv', rows)
    excluded = []
    for r in read(e / 'before-prearc-excluded.tsv'):
        a = after[r['input']]
        excluded.append(dict(input=r['input'], status_pre_15=r['status_pre_15'],
                             status_after_15=a['status'], exit_pre_15=r['exit_pre_15'], exit_after_15=a['exit'],
                             reason='unexecuted_or_censored_pre_arc; no completed-CPU ratio'))
    assert len(excluded) == 271
    assert len({r['input'] for r in rows + excluded}) == 558
    write(e / 'after-prearc-excluded.tsv', excluded)
    inputs = meta.pop('input_sha256')
    meta['input_inventory'] = dict(count=len(inputs), sha256_of_sorted_json=hashlib.sha256(
        json.dumps(inputs, sort_keys=True).encode()).hexdigest(), raw='metadata.json/input_sha256')
    meta['raw_directory'] = str(raw.resolve())
    meta['raw_sha256'] = {p: sha(raw / p) for p in ('metadata.json', 'observations.tsv', 'verdicts.json')}
    meta['console_sha256'] = sha(raw.parent / 'd4-repeats-console.log')
    meta['derived_tallies'] = dict(inputs=287, engine_rows=len(ordinary), oracle_lean_pairs=1148,
                                 initial_exceptions=sum(D(r['ratio_initial']) > D('1.10') for r in rows),
                                 repeated_exceptions=sum(r['exceeds_1_10'] == 'YES' for r in rows),
                                 median_repeated_ratio=str(statistics.median(D(r['ratio']) for r in rows)))
    (e / 'after-prearc-repeat.meta.json').write_text(json.dumps(meta, indent=2) + '\n')
    print('D4 table integrity OK: 287 complete ratios, 271 explicit exclusions, 558 unique selected inputs; exact Decimal threshold; no censored CPU used.')
    print('Derived tallies: ' + json.dumps(meta['derived_tallies'], sort_keys=True))
    for r in rows:
        if r['exceeds_1_10'] == 'YES' or r['input'] in ('sa_csmith_369.c', 'sa_csmith_371.c', 'sa_csmith_419.c'):
            print(r['input'], r['pre_1'], r['after_1'], r['pre_2'], r['after_2'], r['ratio'], r['status_after_15'])


if __name__ == '__main__':
    main(*map(Path, sys.argv[1:]))
