#!/usr/bin/env python3
"""Profile the remaining 15-second failure with the checked D2 CPU sampler.

Run from HEAD under scripts/capped, CERB_MEM_MAX=48G, after ordinary D4
measurements finish. Uses each revision's own ordinary-run cabs bridge.
Profiling CPU is not used for a timing ratio or a lane verdict.
"""
from collections import Counter
import datetime
import hashlib
import json
import os
from pathlib import Path
import subprocess


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def stamp():
    return dict(utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                uptime=subprocess.check_output(['uptime'], text=True).strip())


def observations(p):
    return Counter(l for l in p.read_text().splitlines() if l.startswith(('Defined ', 'Undefined ')))


def main():
    assert os.environ['CERB_MEM_MAX'] == '48G'
    root = Path.cwd()
    raw = root / '.tmp/fuel-measure-cost/d4-repeats'
    ordinary_meta = json.loads((raw / 'metadata.json').read_text())
    assert ordinary_meta['identities_unchanged']
    out = root / '.tmp/fuel-measure-cost/d4-profile'
    out.mkdir(exist_ok=False)
    sampler = root / '.tmp/fuel-measure-cost/d2-profile/sampler.so'
    analyzer = root / 'lean_frontend/docs/2026-09-07_fuel-measure-cost-evidence/analyze-fused-cpu-stacks.py'
    for repeat in (1, 2):
        for rev in ('pre', 'after') if repeat == 1 else ('after', 'pre'):
            name = 'sa_csmith_419'
            repo = Path(ordinary_meta['repos'][rev])
            binary = repo / 'lean_frontend/.lake/build/bin/cerberus-lean'
            ordinary = raw / f'r{repeat}-{rev}-{name}'
            bridge = ordinary / f'{name}.json'
            oracle = ordinary / f'{name}.nolibc.oracle.out'
            paths = [binary, sampler, analyzer, bridge, oracle, repo / 'scripts/exec_csmith_corpus_baseline.txt']
            identities = {str(p): sha(p) for p in paths}
            prefix = out / f'r{repeat}-{rev}-{name}'
            command = ['/usr/bin/time', '-v', '-o', str(prefix) + '.time', 'timeout', '90',
                       'env', 'LEAN_ABORT_ON_PANIC=1', f'LD_PRELOAD={sampler}',
                       f'FC_SAMPLE_FILE={prefix}.samples', 'FC_SAMPLE_US=10000', str(binary), '--batch', str(bridge)]
            meta = dict(start=stamp(), identities_before=identities, command=command)
            with Path(str(prefix) + '.out').open('w') as stdout, Path(str(prefix) + '.err').open('w') as stderr:
                result = subprocess.run(command, cwd=repo, stdout=stdout, stderr=stderr)
            assert result.returncode == 0
            obs = observations(Path(str(prefix) + '.out'))
            assert obs and obs == observations(oracle)
            assert identities == {str(p): sha(p) for p in paths}
            meta.update(end=stamp(), exit=result.returncode, identities_unchanged=True,
                        full_observation_multisets_equal=True, observations=sum(obs.values()),
                        observable_multiset_sha256=hashlib.sha256(json.dumps(sorted(obs.items())).encode()).hexdigest(),
                        trace_sha256=sha(Path(str(prefix) + '.samples')))
            Path(str(prefix) + '.meta.json').write_text(json.dumps(meta, indent=2) + '\n')
            with Path(str(prefix) + '.profile.txt').open('w') as f:
                subprocess.run(['python3', str(analyzer), str(binary), str(prefix) + '.samples'], stdout=f, check=True)
            print('\n'.join(Path(str(prefix) + '.profile.txt').read_text().splitlines()[:8]), flush=True)
    print('D4 residual profiles complete: two repeats per revision; full oracle/Lean observation multisets agree; identities unchanged.', flush=True)


if __name__ == '__main__':
    main()
