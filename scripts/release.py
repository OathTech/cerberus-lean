#!/usr/bin/env python3
"""Execute LADDER.md's command tables and retain versioned release evidence.

Membership comes from the Markdown tables, not a second catalogue. Commands
are argument vectors (no shell evaluation). Reporting campaigns require an
explicit lane selection; fast/full never dispatch reporting campaigns.
"""

from __future__ import annotations

import argparse
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import signal
import subprocess
import sys
import time


ROOT = Path(__file__).resolve().parent.parent


@dataclass
class Lane:
    id: str
    tier: str
    command: list[str]


def expand_braces(words: list[str]) -> list[list[str]]:
    for i, word in enumerate(words):
        match = re.search(r'\{([a-z0-9_,]+)\}', word)
        if match:
            choices = match[1].split(',')
            if len(choices) < 2 or not all(choices):
                raise ValueError(f'invalid command expansion: {word}')
            return [expanded for choice in choices for expanded in expand_braces(
                words[:i] + [word[:match.start()] + choice + word[match.end():]] + words[i + 1:])]
    if any('{' in word or '}' in word for word in words):
        raise ValueError('unsupported command braces')
    return [words]


def read_ladder(path: Path) -> list[Lane]:
    lanes, tier, reporting_row = [], None, 0
    for line in path.read_text().splitlines():
        heading = re.match(r'## Tier ([ABC])\b', line)
        if heading:
            tier = heading[1]
            continue
        if line.startswith('##'):
            tier = None
        if tier is None or not line.startswith('|'):
            continue
        cells = [cell.strip() for cell in line.strip('|').split('|')]
        if tier in ('A', 'B'):
            if len(cells) < 3 or not re.fullmatch(r'[0-9]+[a-z]?', cells[0]):
                continue
            row, command_cell = cells[0], cells[1]
        else:
            if not cells[0].startswith('`'):
                continue
            reporting_row += 1
            row, command_cell = str(reporting_row), cells[0]
        fragments = re.findall(r'`([^`]+)`', command_cell)
        if not fragments:
            raise ValueError(f'{tier}{row}: command cell has no executable command')
        commands, previous_program = [], None
        for fragment in fragments:
            words = shlex.split(fragment)
            if not words:
                raise ValueError('empty command')
            if words[0].startswith('--'):
                if previous_program is None:
                    raise ValueError('option fragment has no preceding executable')
                words = [*previous_program, *words]
            elif words[0] == 'python3' and len(words) > 1 and words[1].startswith(('./scripts/', 'scripts/')):
                previous_program = words[:2]
            elif words[0].startswith(('./scripts/', 'scripts/')):
                previous_program = words[:1]
            else:
                raise ValueError(f'unsupported ladder command: {fragment}')
            if any(word in ('|', '||', '&&', ';', '>', '<') for word in words):
                raise ValueError('shell operators are not ladder argument vectors')
            commands.extend(expand_braces(words))
        for i, command in enumerate(commands, 1):
            suffix = f'.{i}' if len(commands) > 1 else ''
            lanes.append(Lane(f'{tier}{row}{suffix}', tier, command))
    if len({lane.id for lane in lanes}) != len(lanes):
        raise ValueError('duplicate ladder row IDs')
    if not all(any(lane.tier == tier for lane in lanes) for tier in 'ABC'):
        raise ValueError('ladder must contain nonempty A, B and C command tables')
    return lanes


def run_text(args, root=None):
    root = root or ROOT
    proc = subprocess.run(args, cwd=root, capture_output=True, text=True)
    if proc.returncode:
        raise RuntimeError(f'{shlex.join(args)}: {proc.stderr.strip()}')
    return proc.stdout.strip()


def sha(path: Path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def source_identity(root=None):
    root = root or ROOT
    diff = subprocess.check_output(['git', 'diff', '--no-ext-diff', '--binary', 'HEAD'], cwd=root)
    untracked = subprocess.check_output(['git', 'ls-files', '--others', '--exclude-standard', '-z'], cwd=root)
    extra = {os.fsdecode(name): sha(root / os.fsdecode(name)) for name in untracked.split(b'\0') if name}
    return {'head': run_text(['git', 'rev-parse', 'HEAD'], root),
            'branch': run_text(['git', 'branch', '--show-current'], root),
            'status': run_text(['git', 'status', '--short'], root),
            'diff_sha256': hashlib.sha256(diff).hexdigest(), 'untracked_sha256': extra}


def artifacts(root=None):
    root = root or ROOT
    paths = ['lean_frontend/lean-toolchain', 'lean_frontend/lakefile.toml',
             'lean_frontend/lake-manifest.json', 'lean_frontend/speclab/lake-manifest.json',
             'tests/mem-scale-probes/micro/lake-manifest.json',
             'lean_frontend/lem_sync.sha256', 'ocaml_frontend/lem_sync.sha256',
             'driver_fresh.oracle.sha256', 'driver_fresh.lean.sha256',
             '_build/default/backend/driver/main.exe',
             'lean_frontend/.lake/build/bin/cerberus-lean']
    records = {}
    for rel in paths:
        path = root / rel
        records[rel] = {'present': path.is_file()}
        if path.is_file():
            records[rel].update(sha256=sha(path), resolved=str(path.resolve()))
            if path.suffix in ('.json', '.toml', '.sha256') or path.name == 'lean-toolchain':
                records[rel]['text'] = path.read_text()
    for folder in ['_build/install/default/lib/cerberus-lib',
                   '_build/install/default/lib/cerberus/runtime', 'lean_frontend/native']:
        directory = root / folder
        for path in sorted(directory.rglob('*')) if directory.is_dir() else []:
            if path.is_file():
                records[str(path.relative_to(root))] = {'present': True, 'sha256': sha(path),
                                                       'resolved': str(path.resolve())}
    lem = shutil.which('lem')
    records['lem_compiler'] = {'present': bool(lem), 'path': lem}
    if lem:
        records['lem_compiler'].update(sha256=sha(Path(lem)), version=run_text([lem, '-v']))
    for executable in ('ocamlc', 'dune', 'gcc'):
        binary = shutil.which(executable)
        records[executable] = {'present': bool(binary), 'path': binary}
        if binary:
            flag = '-version' if executable == 'ocamlc' else '--version'
            records[executable].update(sha256=sha(Path(binary)), version=run_text([binary, flag], root))
    package = root / 'lean_frontend/.lake/packages/LemLib'
    if package.is_dir():
        records['lem_runtime_checkout'] = source_identity(package)
    return records


def write_report(path, report):
    temporary = path.with_suffix('.tmp')
    temporary.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
    temporary.replace(path)


def execute_lane(lane: Lane, out: Path, limit: float, root=None):
    root = root or ROOT
    directory = out / lane.id
    directory.mkdir()
    command = list(lane.command)
    if lane.tier == 'C':
        # Measurement outputs are review artifacts, never an implicit rewrite
        # of the candidate's committed baseline/scoreboard.
        command = [('--write-baseline=' + str(directory / 'baseline.txt'))
                   if arg.startswith('--write-baseline=') else arg for arg in command]
        if Path(command[0]).name == 'test_ci_sweep.sh':
            command += ['--out', str(directory / 'scoreboard')]
    if 'scripts/test_observation_lanes.py' in ' '.join(command):
        command += ['--out', str(directory / 'plants')]
    if 'scripts/test_upstream_oracle.py' in ' '.join(command):
        command += ['--out', str(directory / 'independent-oracle')]
    env = dict(os.environ, CERB_OBSERVATION_DIR=str(directory / 'observations'))
    started = time.monotonic()
    result = {'id': lane.id, 'tier': lane.tier, 'command': command,
              'required': lane.tier != 'C', 'status': 'running',
              'stdout': str(directory / 'stdout'), 'stderr': str(directory / 'stderr')}
    with (directory / 'stdout').open('wb') as stdout, (directory / 'stderr').open('wb') as stderr:
        try:
            proc = subprocess.Popen(command, cwd=root, env=env, stdout=stdout, stderr=stderr,
                                    start_new_session=True)
            try:
                rc = proc.wait(timeout=limit)
                result.update(exit_status=rc, status=('passed' if lane.tier != 'C' else 'reported') if rc == 0 else 'failed')
            except subprocess.TimeoutExpired:
                os.killpg(proc.pid, signal.SIGTERM)
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(proc.pid, signal.SIGKILL)
                    proc.wait()
                result.update(exit_status=proc.returncode, status='incomplete', reason='lane timeout')
        except OSError as exc:
            result.update(exit_status=None, status='incomplete', reason=str(exc))
    result['seconds'] = round(time.monotonic() - started, 3)
    result['stdout_sha256'] = sha(directory / 'stdout')
    result['stderr_sha256'] = sha(directory / 'stderr')
    result['summaries'] = [line for line in (directory / 'stdout').read_text(errors='replace').splitlines()
                           if re.match(r'^(SUMMARY:|SWEEP SUMMARY|BASELINE|Baseline check:|test_verify:)', line)]
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--mode', choices=['fast', 'full', 'reporting'], default='fast')
    parser.add_argument('--lane', action='append', help='select a row or expanded command ID (repeatable)')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--out', help='new evidence directory (default: .tmp/release/<UTC timestamp>)')
    parser.add_argument('--lane-timeout', type=float, default=3600,
                        help='per-command limit; justify larger finite reporting runs before dispatch')
    args = parser.parse_args()
    lanes = read_ladder(ROOT / 'scripts/LADDER.md')
    if args.list:
        for lane in lanes:
            print(f'{lane.id:7} {shlex.join(lane.command)}')
        return 0
    if args.mode == 'reporting' and not args.lane:
        parser.error('reporting requires an explicit --lane selection; use --list')
    tiers = {'fast': 'A', 'full': 'AB', 'reporting': 'C'}[args.mode]
    eligible = [lane for lane in lanes if lane.tier in tiers]
    selected = [lane for lane in eligible if not args.lane or any(
        lane.id == key or lane.id.startswith(key + '.') for key in args.lane)]
    if args.lane and any(not any(l.id == key or l.id.startswith(key + '.') for l in selected) for key in args.lane):
        parser.error('unknown lane selection for this mode')
    if args.lane_timeout <= 0:
        parser.error('lane timeout must be positive')
    stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S.%fZ')
    out = Path(args.out).resolve() if args.out else ROOT / '.tmp/release' / stamp
    out.mkdir(parents=True, exist_ok=False)
    before = source_identity()
    report = {'schema': 1, 'started_utc': stamp, 'mode': args.mode,
              'membership_sha256': sha(ROOT / 'scripts/LADDER.md'),
              'catalogue': [asdict(lane) for lane in lanes], 'source_before': before,
              'artifacts_before': artifacts(), 'selected': [l.id for l in selected],
              'unrun': [asdict(l) for l in lanes if l not in selected],
              'lanes': [], 'status': 'running',
              'release_certification': 'incomplete: reporting/adoption/audit exits require separate evidence',
              'environment': {key: os.environ.get(key) for key in [
                  'CERB_MEM_MAX', 'CERB_TEST_MEM_MAX', 'TIMEOUT_SECS', 'DUNE_CACHE', 'SKIP_BUILD',
                  'CERB_ORACLE_BIN_OVERRIDE', 'CERB_LEAN_BIN_OVERRIDE',
                  'CERB_DRIVER_FRESH_OVERRIDE', 'CERB_FORK_DRIFT_DEV_SKIP']}}
    write_report(out / 'report.json', report)
    print(f'Release evidence: {out}', flush=True)
    for lane in selected:
        print(f'RUN {lane.id}: {shlex.join(lane.command)}', flush=True)
        # Persist the started command before waiting; a killed runner cannot
        # leave an old completion marker standing in for the unfinished lane.
        report['active_lane'] = lane.id
        write_report(out / 'report.json', report)
        result = execute_lane(lane, out, args.lane_timeout)
        report['lanes'].append(result)
        print(f'{result["status"].upper()} {lane.id} ({result["seconds"]:.1f}s)', flush=True)
        write_report(out / 'report.json', report)
    report.pop('active_lane', None)
    report['source_after'] = source_identity()
    report['artifacts_after'] = artifacts()
    unchanged = before == report['source_after']
    complete_selection = len(selected) == len(eligible)
    good = all(row['status'] in ('passed', 'reported') for row in report['lanes'])
    override = any(report['environment'].get(key) for key in [
        'CERB_ORACLE_BIN_OVERRIDE', 'CERB_LEAN_BIN_OVERRIDE',
        'CERB_DRIVER_FRESH_OVERRIDE', 'CERB_FORK_DRIFT_DEV_SKIP'])
    report['source_unchanged'] = unchanged
    report['selection_complete'] = complete_selection
    report['status'] = 'passed' if good and unchanged and not override and complete_selection else 'incomplete' if good else 'failed'
    if args.mode == 'reporting' and good and unchanged and not override:
        report['status'] = 'reported'
    report['finished_utc'] = datetime.now(timezone.utc).isoformat()
    write_report(out / 'report.json', report)
    summary = (f'{args.mode}: {report["status"]}; {sum(r["status"] in ("passed", "reported") for r in report["lanes"])}/{len(selected)} selected commands completed successfully.\n'
               f'Source unchanged: {unchanged}. Complete tier selection: {complete_selection}.\n'
               f'Release certification: {report["release_certification"]}.\n')
    (out / 'summary.txt').write_text(summary)
    print(summary, end='', flush=True)
    # A deliberate subset can succeed as a subset; the report does not call
    # its tier complete. Failed/incomplete required executions never exit 0.
    return 0 if good and unchanged and not override else 1


if __name__ == '__main__':
    sys.exit(main())
