#!/usr/bin/env python3
"""Reproduce WP1 decision evidence. Diagnostic only; no new standing gate.

Run under the scoped project environment after regenerating/building semantics.
Every Lean invocation is capped and panic-aborting. Raw output, exact commands,
source hashes and loaded module hashes are retained for independent review.
"""
import hashlib
import json
import os
import re
from pathlib import Path
import subprocess
import time

ROOT = Path(__file__).resolve().parent.parent
LF = ROOT / 'lean_frontend'
OUT = ROOT / '.tmp/sc-wp1/decision'
PROBES = {
    'operations': ('test/SCWP1DecisionChecks.lean', 16),
    'publication': ('test/SCWP1PublicationChecks.lean', 4),
    'race-prefix': ('test/SCWP1RacePrefixChecks.lean', 4),
    'retention': ('test/SCWP1RetentionChecks.lean', 7),
    'reference': ('test/SCWP1ReferenceChecks.lean', 2),
    'source-orders': ('docs/sc-wp1-evidence/followup-source-order.lean', 22),
}
MODULES = ['SCWP1Decision', 'SCWP1DecisionProofs', 'SCWP1Summary', 'SCWP1SummaryRuntime',
           'SCWP1SourceProofs', 'SCWP1Contracts']


def sha(p):
    return hashlib.sha256(p.read_bytes()).hexdigest()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    runs = {}

    def call(name, command):
        start = time.monotonic()
        result = subprocess.run(command, cwd=LF, capture_output=True, timeout=180,
            env={**os.environ, 'LEAN_ABORT_ON_PANIC': '1', 'DUNE_CACHE': 'disabled'})
        (OUT / f'{name}.stdout').write_bytes(result.stdout)
        (OUT / f'{name}.stderr').write_bytes(result.stderr)
        runs[name] = {'command': command, 'cwd': str(LF), 'returncode': result.returncode,
            'elapsed_seconds': time.monotonic() - start,
            'stdout_sha256': hashlib.sha256(result.stdout).hexdigest(),
            'stderr_sha256': hashlib.sha256(result.stderr).hexdigest()}
        if result.returncode:
            raise RuntimeError(f'{name}: failed; inspect {OUT}')
        return result

    call('build', ['../scripts/capped', 'lake', 'build'] + ['Unit.' + m for m in MODULES])
    for name, (source, lines) in PROBES.items():
        result = call(name, ['../scripts/capped', '../scripts/lean_probe.sh', source])
        if result.stderr or len(result.stdout.decode().splitlines()) != lines:
            raise RuntimeError(f'{name}: unexpected diagnostic output; inspect {OUT}')
    for name, expected_count in [('SCWP1Summary', 4), ('SCWP1SourceProofs', 4), ('SCWP1DecisionProofs', 2)]:
        result = call(name + '-axioms', ['../scripts/capped', '../scripts/lean_probe.sh',
            f'test/Unit/{name}.lean'])
        text = result.stdout.decode()
        cones = re.findall(r"depends on axioms: \[(.*?)\]", text)
        count = len(cones) + text.count('does not depend on any axioms')
        if result.stderr or count != expected_count or any(
                set(filter(None, (a.strip() for a in cone.split(',')))) -
                {'propext', 'Classical.choice', 'Quot.sound'} for cone in cones):
            raise RuntimeError(f'{name}: axiom-cone transcript changed; inspect {OUT}')
    source_files = [LF / 'test/Unit' / (m + '.lean') for m in MODULES]
    source_files += [LF / p for p, _ in PROBES.values()]
    source_files += [ROOT / p for p in ['frontend/model/core_reduction.lem',
        'frontend/model/driver.lem', 'frontend/model/core_run.lem',
        'frontend/model/core_run_aux.lem', 'frontend/concurrency/cmm_csem.lem',
        'lean_frontend/CerbMem.lean', 'scripts/test_sc_wp1_decision.py']]
    source_files += [LF / 'generated' / (m + '.lean') for m in
        ['Core_reduction', 'Core_run', 'Core_run_aux', 'Driver', 'Cmm_csem']]
    artifacts = [LF / '.lake/build/lib/lean/Unit' / (m + '.olean') for m in MODULES]
    artifacts += [LF / '.lake/build/lib/lean' / (m + '.olean') for m in
        ['Core_reduction', 'Core_run', 'Core_run_aux', 'Driver', 'Cmm_csem', 'CerbMem']]
    record = {'scope': 'WP1 bounded feasibility, source-order/reference diagnostics and kernel local laws; not public SC acceptance',
        'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
        'sources': {str(p.relative_to(ROOT)): sha(p) for p in source_files},
        'artifacts': {str(p.relative_to(ROOT)): sha(p) for p in artifacts}, 'runs': runs}
    (OUT / 'record.json').write_text(json.dumps(record, indent=2) + '\n')
    print('WP1 decision: operations, publication, first-race prefix, source orders, retention, finite reference and ten axiom cones passed')


if __name__ == '__main__':
    main()
