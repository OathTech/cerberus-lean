#!/usr/bin/env python3
"""Repeat the D4 per-program comparison, serially, using each tree's measure.sh.

Both revisions use the identical retained lane-staged C input, but each uses
its own oracle bridge. Each engine pair and all four ordinary repetitions
must have equal full Defined/Undefined-line multisets. No build, baseline
write, profiler, worker change or lane-classifier change is performed.
Raw artifacts and the per-engine observations are written to a NEW directory.
Run this script under scripts/capped with CERB_MEM_MAX=48G.
"""
import argparse
from collections import Counter
import csv
import datetime
import hashlib
import io
import json
import os
from pathlib import Path
import subprocess


COLS = ['probe', 'mode', 'engine', 'exit', 'wall_s', 'maxrss_kb', 'verdict', 'note', 'cpu_s']


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def stamp():
    return {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
            'uptime': subprocess.check_output(['uptime'], text=True).strip()}


def identity(repo):
    paths = ['lean_frontend/.lake/build/bin/cerberus-lean', '_build/default/backend/driver/main.exe',
             'tests/mem-scale-probes/measure.sh', 'scripts/exec_csmith_corpus_baseline.txt',
             'frontend/model/core_reduction.lem', 'lean_frontend/lake-manifest.json']
    result = {p: sha(repo / p) for p in paths}
    result['head'] = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip()
    result['status'] = subprocess.check_output(['git', 'status', '--porcelain'], cwd=repo, text=True)
    result['diff_sha256'] = hashlib.sha256(subprocess.check_output(
        ['git', 'diff', '--binary', 'HEAD'], cwd=repo)).hexdigest()
    return result


def observations(path):
    return Counter(line for line in path.read_text().splitlines()
                   if line.startswith(('Defined ', 'Undefined ')))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    for name in ('head-repo', 'pre-repo', 'staged', 'out', 'inputs'):
        ap.add_argument('--' + name, required=True, type=Path)
    args = ap.parse_args()
    assert os.environ.get('CERB_MEM_MAX') == '48G'
    repos = {'pre': args.pre_repo.resolve(), 'after': args.head_repo.resolve()}
    staged, out = args.staged.resolve(), args.out.resolve()
    selected = list(csv.DictReader(args.inputs.open(), delimiter='\t'))
    names = [r['input'] for r in selected]
    assert len(names) == len(set(names)) == 287
    assert all(Path(n).name == n and n.endswith('.c') for n in names)
    out.mkdir(parents=True, exist_ok=False)
    inputs = {n: sha(staged / n) for n in names + ['csmith_cerberus.h', 'safe_math.h']}
    before = {k: identity(p) for k, p in repos.items()}
    meta = {'start': stamp(), 'script_sha256': sha(Path(__file__)),
            'input_table_sha256': sha(args.inputs), 'repos': {k: str(v) for k, v in repos.items()},
            'staged': str(staged), 'identities_before': before, 'input_sha256': inputs,
            'CERB_MEM_MAX': '48G', 'TIMEOUT_SECS': 90, 'repetitions': 2,
            'order': 'two passes over all 287 names; alternate pre/after order within each pair',
            'table_boundaries': []}
    (out / 'metadata.json').write_text(json.dumps(meta, indent=2) + '\n')
    reference = {}
    verdicts = []
    completed = 0
    with (out / 'observations.tsv').open('w') as f:
        writer = csv.DictWriter(f, fieldnames=['repeat', 'revision', 'input'] + COLS,
                                delimiter='\t', lineterminator='\n')
        writer.writeheader()
        for repeat in (1, 2):
            meta['table_boundaries'].append({'repeat': repeat, 'start': stamp()})
            for index, name in enumerate(names):
                order = ('pre', 'after') if (repeat + index) % 2 else ('after', 'pre')
                cpus = {}
                for rev in order:
                    repo = repos[rev]
                    run = out / f'r{repeat}-{rev}-{name.removesuffix(".c")}'
                    command = [str(repo / 'tests/mem-scale-probes/measure.sh'), '--nolibc',
                               '--timeout', '90', '--engines', 'oracle,lean-exh',
                               '--outdir', str(run), str(staged / name)]
                    result = subprocess.run(command, cwd=repo, text=True, capture_output=True)
                    run.mkdir(exist_ok=True)
                    (run / 'measure.stdout').write_text(result.stdout)
                    (run / 'measure.stderr').write_text(result.stderr)
                    (run / 'measure.command.json').write_text(json.dumps(command) + '\n')
                    assert result.returncode == 0, (name, repeat, rev, result.returncode)
                    rows = list(csv.DictReader(io.StringIO(result.stdout), fieldnames=COLS, delimiter='\t'))
                    assert len(rows) == 2 and [r['engine'] for r in rows] == ['oracle', 'lean-exh']
                    for r in rows:
                        assert r['exit'] == '0' and r['note'] == '-', (name, repeat, rev, r)
                        writer.writerow(dict(repeat=repeat, revision=rev, input=name, **r))
                    f.flush()
                    obs = [observations(run / f'{name.removesuffix(".c")}.nolibc.{engine}.out')
                           for engine in ('oracle', 'lean-exh')]
                    assert obs[0] and obs[0] == obs[1], (name, repeat, rev, 'engine observations differ')
                    if name in reference:
                        assert reference[name] == obs[0], (name, repeat, rev, 'revision/repeat observations differ')
                    else:
                        reference[name] = obs[0]
                    cpus[rev] = rows[1]['cpu_s']
                    assert sha(staged / name) == inputs[name]
                    completed += 1
                verdicts.append({'input': name, 'repeat': repeat, 'pre_cpu_s': cpus['pre'],
                                 'after_cpu_s': cpus['after'], 'observations': sum(reference[name].values()),
                                 'observable_multiset_sha256': hashlib.sha256(json.dumps(
                                     sorted(reference[name].items())).encode()).hexdigest()})
                if (index + 1) % 25 == 0 or index + 1 == len(names) or name in {
                        'sa_csmith_369.c', 'sa_csmith_371.c', 'sa_csmith_419.c'}:
                    print(f'repeat {repeat}: {index + 1}/287; {name}: pre CPU {cpus["pre"]}, '
                          f'after CPU {cpus["after"]}; full observation multisets agree', flush=True)
            meta['table_boundaries'][-1]['end'] = stamp()
    assert {k: identity(p) for k, p in repos.items()} == before
    assert {n: sha(staged / n) for n in inputs} == inputs
    assert completed == 1148
    meta['end'] = stamp()
    meta['identities_unchanged'] = True
    (out / 'metadata.json').write_text(json.dumps(meta, indent=2) + '\n')
    (out / 'verdicts.json').write_text(json.dumps(verdicts, indent=2) + '\n')
    print('D4 repeats complete: 287 inputs, two repeats per revision, 1148 oracle/Lean pairs; '
          'all full observation multisets agree; all identities unchanged.', flush=True)


if __name__ == '__main__':
    main()
