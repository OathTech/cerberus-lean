#!/usr/bin/env python3
"""Fixed four additional ordinary pairs for D4's sole repeated-ratio exception.

Run from HEAD under scripts/capped, CERB_MEM_MAX=48G. Preserve the initial
287-row experiment; this is a separate follow-up, not repeat-until-pass.
"""
import csv
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import sys
sys.dont_write_bytecode = True
helper = Path(__file__).with_name('repeat-prearc-comparison.py')
spec = importlib.util.spec_from_file_location('d4', helper)
d4 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(d4)


def main():
    assert os.environ['CERB_MEM_MAX'] == '48G'
    raw = Path('.tmp/fuel-measure-cost/d4-repeats').resolve()
    prior = json.loads((raw / 'metadata.json').read_text())
    assert prior['identities_unchanged']
    repos = {k: Path(v) for k, v in prior['repos'].items()}
    name = 'sia_csmith_078.c'
    src = Path(prior['staged']) / name
    out = Path('.tmp/fuel-measure-cost/d4-exception-repeats').resolve()
    out.mkdir(exist_ok=False)
    before = {k: d4.identity(v) for k, v in repos.items()}
    meta = dict(start=d4.stamp(), identities_before=before, source_sha256=d4.sha(src),
                script_sha256=d4.sha(Path(__file__)), helper_sha256=d4.sha(helper),
                repetitions=4, timeout_s=90, CERB_MEM_MAX='48G')
    ref = d4.observations(raw / 'r1-pre-sia_csmith_078/sia_csmith_078.nolibc.oracle.out')
    assert ref
    with (out / 'observations.tsv').open('w') as f:
        writer = csv.DictWriter(f, fieldnames=['repeat', 'revision', 'input'] + d4.COLS,
                                delimiter='\t', lineterminator='\n')
        writer.writeheader()
        for rep in range(3, 7):
            for rev in ('pre', 'after') if rep % 2 else ('after', 'pre'):
                run = out / f'r{rep}-{rev}-sia_csmith_078'
                command = [str(repos[rev] / 'tests/mem-scale-probes/measure.sh'), '--nolibc',
                           '--timeout', '90', '--engines', 'oracle,lean-exh', '--outdir', str(run), str(src)]
                result = subprocess.run(command, cwd=repos[rev], text=True, capture_output=True)
                assert result.returncode == 0
                (run / 'measure.command.json').write_text(json.dumps(command) + '\n')
                (run / 'measure.stdout').write_text(result.stdout)
                (run / 'measure.stderr').write_text(result.stderr)
                rows = list(csv.DictReader(io.StringIO(result.stdout), fieldnames=d4.COLS, delimiter='\t'))
                assert len(rows) == 2 and [r['engine'] for r in rows] == ['oracle', 'lean-exh']
                for r in rows:
                    assert r['exit'] == '0' and r['note'] == '-'
                    assert d4.observations(run / f'sia_csmith_078.nolibc.{r["engine"]}.out') == ref
                    writer.writerow(dict(repeat=rep, revision=rev, input=name, **r))
                f.flush()
                print(f'follow-up repeat {rep}: {rev} CPU {rows[1]["cpu_s"]}; full observation multisets agree', flush=True)
    assert before == {k: d4.identity(v) for k, v in repos.items()}
    assert meta['source_sha256'] == d4.sha(src)
    meta.update(end=d4.stamp(), identities_unchanged=True, full_observation_multisets_equal=True,
                observations_per_engine=sum(ref.values()))
    (out / 'metadata.json').write_text(json.dumps(meta, indent=2) + '\n')
    print('D4 exception follow-up complete: four additional pairs; full observation multisets agree; identities unchanged.', flush=True)


if __name__ == '__main__':
    main()
