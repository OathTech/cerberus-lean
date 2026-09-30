#!/usr/bin/env python3
"""The SC S1a step lane: run-to-completion of the shared-Lem SC step API against `drive`.

Charter: lean_frontend/docs/2026-09-29_sc-s1-charter.md section 3.10 (rows A-F),
section 3.11 (plants). Both engines run `sc_explore` (shared Lem: neither hand-writes
the walker) and the verdict-line sequences are compared IN ORDER, as test_exec.sh's
extractor compares exhaustive output and as CerbND.runNDFuel mirrors the oracle's
branch order.

  Row A  Lean `sc_explore` (cerberus-lean --batch --sc-run --sc-budget N) vs Lean `drive`
         (cerberus-lean --batch): identical sequences, every program.
  Row B  OCaml `sc_explore` (backend/sc_probe/sc_run.exe) vs the fork oracle
         (cerberus --exec --batch --mode=exhaustive): identical sequences.
  Row C  Lean `sc_explore` vs OCaml `sc_explore`: identical sequences on every program
         whose owning lane baseline is MATCH/UB_MATCH; a program the owning lane records
         as a cross-engine non-MATCH (CERB_SKIP, UNSUPPORTED, DIFF, ORACLE_CRASH, KILL,
         TRIPWIRE) is reported under that status and not required equal (the expected
         answers are the existing pinned baselines: no new baseline).
  Row D  (--libc, LADDER Tier B) rows A-C in first-alternative mode (--sc-first vs
         --first / the oracle's default single trace) over tests/libc_exec; its
         `exhaustive/` rows in exhaustive mode.
  Row E  tests/sc-step/loop-*.c, Lean only, at an explicit small --fuel: SCExhausted at
         budgets 0, 1, 2, 7, 4096 (+ the fixture's startup boundary), transitions =
         budget, core_reductions = budget - startup transitions, memory unchanged once
         the startup is over; `drive` at the same fuel ends only in the fuel kill.
  Row F  SCUnsupported count over every program: 0; the control tests/sc-step/
         par-control.c must report SCUnsupported on both engines (plant P4).

Fail-closed: any row A/B/C mismatch, a one-sided crash, an SCExhausted in rows A-C (the
budget is a lane parameter and must cover every corpus program), a wrong row E figure,
a control that does not refuse, or zero cases is red. `--selftest` plants the
comparison and row E checkers hermetically (P5 lane vacuity: a doctored verdict line
in one engine is red). Bulky evidence stays under .tmp/sc-step/ (or --out).
"""
import argparse
import concurrent.futures
import hashlib
import json
import os
import re
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT_DEFAULT = ROOT / '.tmp/sc-step'
ORACLE = ROOT / '_build/default/backend/driver/main.exe'
PROBE = ROOT / '_build/default/backend/sc_probe/sc_run.exe'
LEAN = ROOT / 'lean_frontend/.lake/build/bin/cerberus-lean'
RUNTIME = ROOT / '_build/install/default'
CAPPED = ROOT / 'scripts/capped'

# Lane parameters (harness choices, like the lanes' timeouts; none is a semantic bound):
# the per-run wall bound (180 s: the largest gated sequential program,
# tests/immaculate/nolibc/zd-funptr-call-control.c with 60104 exhaustive executions, takes
# ~105 s through the Lean SC walk against ~14 s through Lean `drive` — the S1a acceptance
# record's performance finding; the per-transition cost is equal on deterministic programs),
# the SC step budget that must cover every corpus program, and row E's explicit small fuel
# (budget exhaustion must precede fuel exhaustion; `drive` at this fuel must die in the fuel
# kill on the loop fixtures).
TIMEOUT_SECS = 180
BUDGET = 10_000_000
ROW_E_FUEL = 1000
ROW_E_BUDGETS = [0, 1, 2, 7, 4096]
FUEL_KILL = 'Error {msg: "lem: fuel exhausted"}'
UNSUPPORTED_FORK = 'SCUnsupported {msg: "sc: fork (Step_spawn_threads2, Core par): S1b"}'

# One verdict token per line: the batch records (Defined/Undefined/Error/ModelFailure)
# and the SC records, whole line, in order. `EXECUTION i…` headers are structure, the
# Lean-only `SCMemory` line belongs to row E and is consumed there.
TOKEN = re.compile(rb'^(?:Defined|Undefined|Error|ModelFailure|SCExhausted|SCUnsupported|SCBlocked|SCNeedsChoice|SCRunError) \{.*\}$')
SC_MEMORY = re.compile(rb'^SCMemory \{next_alloc_id: ([0-9]+), last_address: ([0-9]+), trace_events: ([0-9]+)\}$')
SC_EXHAUSTED = re.compile(rb'^SCExhausted \{transitions: ([0-9]+), core_reductions: ([0-9]+)\}$')
SC_SPECIFIC = re.compile(rb'^SC[A-Za-z]+ \{')

# immaculate first: it holds the longest program (see TIMEOUT_SECS), so the pool starts it early.
# `sc-step` (no baseline: cross-engine agreement REQUIRED) = tests/sc-step/*.c minus the row E
# loop fixtures and the row F control — today `unseq-calls.c`, the order-observable witness of
# plant P1 (charter §3.11).
NOLIBC_CORPORA = [('sc-step', 'tests/sc-step', None),
                  ('immaculate', 'tests/immaculate/nolibc', 'tests/immaculate/baseline.txt'),
                  ('minimal', 'tests/minimal', 'scripts/exec_baseline.txt'),
                  ('coverage', 'tests/coverage', 'scripts/exec_coverage_baseline.txt'),
                  ('debug', 'tests/debug', 'scripts/exec_debug_baseline.txt'),
                  ('float', 'tests/float', 'scripts/exec_float_baseline.txt')]


def tokens(stdout: bytes):
    return [l for l in stdout.split(b'\n') if TOKEN.match(l)]


def exit_class(rc):
    """0/1/3 are verdict exits (the batch rule; 3 = an SC-specific record was printed);
    anything else is a failure of the run (crash, timeout, cap kill, refusal)."""
    return 'verdict' if rc in (0, 1, 3) else 'failed'


def run_class(rc, toks):
    """A run is a `verdict` (a verdict exit with tokens and no model fail-stop record),
    a `modelfail` (Lean's `ModelFailure {…}` record: the port's fail-stop mirror of an
    oracle uncaught exception — the immaculate lane's CRASH class), or `failed`."""
    if not toks:
        return 'failed'
    if any(t.startswith(b'ModelFailure') for t in toks):
        return 'modelfail'
    return exit_class(rc)


def compare(left, right):
    """Compare two engine runs (rc, stdout bytes). MATCH iff both are verdict exits with
    identical token sequences and the same rc (or both are model fail-stops with the same
    record); BOTH_FAILED when both runs failed (crash/timeout/kill, or one crashed and the
    other printed a model fail-stop record: the same failure CLASS, as the owning immaculate
    baseline pins it); ONE_FAILED and MISMATCH are red."""
    lrc, lout = left
    rrc, rout = right
    lt, rt = tokens(lout), tokens(rout)
    lclass, rclass = run_class(lrc, lt), run_class(rrc, rt)
    if lclass == 'modelfail' and rclass == 'modelfail':
        return 'MATCH' if lt == rt and lrc == rrc else 'MISMATCH'
    if lclass != 'verdict' and rclass != 'verdict':
        return 'BOTH_FAILED'
    if lclass != rclass:
        return 'ONE_FAILED'
    if lt == rt and lrc == rrc:
        return 'MATCH'
    return 'MISMATCH'


def parse_baseline(path: Path):
    """name -> status for the exec/immaculate/libc_exec baselines (names without .c). An
    immaculate row `name MATCH | L=CRASH` (both engines fail-stop, by the recorded state)
    is reported as `MATCH/CRASH`: cross-engine agreement there is a both-sided failure."""
    out = {}
    for line in path.read_text().splitlines():
        if not line.strip() or line.startswith('#'):
            continue
        parts = line.split()
        name, status = parts[0], parts[1]
        if name.endswith('.c'):
            name = name[:-2]
        m = re.search(r'\| L=(CRASH|KILL)\b', line)
        if m and status == 'MATCH':
            status = 'MATCH/' + m.group(1)
        out[name] = status
    return out


def header_fields(cfile: Path):
    fields = {}
    for m in re.finditer(r'sc-step: ([a-z-]+)=([0-9]+)', cfile.read_text()):
        fields[m.group(1)] = int(m.group(2))
    return fields


def check_row_e(fixture_name, fields, runs, drive_run):
    """runs: {budget: (rc, stdout)} of Lean --sc-run at ROW_E_FUEL; drive_run: (rc, stdout)
    of Lean drive at ROW_E_FUEL. Returns a list of failure strings (empty = OK)."""
    fails = []
    startup = fields.get('startup-transitions')
    complete_at = fields.get('startup-complete-at')
    if startup is None or complete_at is None:
        return [f'{fixture_name}: header lacks sc-step: startup-transitions / startup-complete-at']
    memory = {}
    for budget, (rc, out) in sorted(runs.items()):
        toks = tokens(out)
        if rc != 3 or len(toks) != 1:
            fails.append(f'{fixture_name} budget {budget}: expected exactly one SCExhausted record and exit 3, got rc={rc} tokens={toks}')
            continue
        m = SC_EXHAUSTED.match(toks[0])
        if not m:
            fails.append(f'{fixture_name} budget {budget}: not SCExhausted: {toks[0]!r}')
            continue
        transitions, reductions = int(m.group(1)), int(m.group(2))
        expect_non_reductions = 0 if budget == 0 else (1 if budget < complete_at else startup)
        if transitions != budget or transitions - reductions != expect_non_reductions:
            fails.append(f'{fixture_name} budget {budget}: transitions={transitions} core_reductions={reductions}; expected transitions={budget}, transitions-core_reductions={expect_non_reductions}')
        mems = [SC_MEMORY.match(l) for l in out.split(b'\n') if SC_MEMORY.match(l)]
        if len(mems) != 1:
            fails.append(f'{fixture_name} budget {budget}: expected exactly one SCMemory line, got {len(mems)}')
            continue
        memory[budget] = (int(mems[0].group(1)), int(mems[0].group(2)), int(mems[0].group(3)))
    if 0 in memory and memory[0][0] != 0:
        fails.append(f'{fixture_name} budget 0: a lifecycle effect happened (next_alloc_id={memory[0][0]}); budget 0 must perform none')
    stable = {b: m for b, m in memory.items() if b >= complete_at}
    if len(set(stable.values())) > 1:
        fails.append(f'{fixture_name}: memory differs across budgets past the startup: {stable}')
    if complete_at > 1 and memory and any(b < complete_at and b > 0 for b in memory):
        before = {b: m for b, m in memory.items() if 0 < b < complete_at}
        if stable and any(m == next(iter(stable.values())) for m in before.values()):
            fails.append(f'{fixture_name}: a budget before the startup completes already shows the post-startup memory: {before} vs {stable}')
    drc, dout = drive_run
    if drc != 1 or tokens(dout) != [FUEL_KILL.encode()]:
        fails.append(f'{fixture_name}: Lean drive at fuel {ROW_E_FUEL} did not end in exactly the fuel kill: rc={drc} tokens={tokens(dout)}')
    for budget, (rc, out) in runs.items():
        if FUEL_KILL.encode() in tokens(out):
            fails.append(f'{fixture_name} budget {budget}: the SC run hit the fuel kill — the lane fuel {ROW_E_FUEL} does not let budget exhaustion precede fuel exhaustion')
    return fails


def selftest():
    good = (0, b'Defined {value: "Specified(3)", stdout: "a", stderr: "", blocked: "false"}\n')
    assert compare(good, good) == 'MATCH'
    multi = (0, b'EXECUTION 0:\nDefined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}\nEXECUTION 1:\nUndefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:1>"}\n')
    assert compare(multi, multi) == 'MATCH'
    # P5 lane vacuity: a doctored verdict line in one engine is red
    doctored = (0, good[1].replace(b'Specified(3)', b'Specified(4)'))
    assert compare(good, doctored) == 'MISMATCH'
    swapped = (0, b'EXECUTION 0:\nUndefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:1>"}\nEXECUTION 1:\nDefined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}\n')
    assert compare(multi, swapped) == 'MISMATCH', 'order is compared'
    dropped = (0, b'EXECUTION 0:\nDefined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}\n')
    assert compare(multi, dropped) == 'MISMATCH', 'length is compared'
    stderr_diff = (0, good[1].replace(b'stderr: ""', b'stderr: "x"'))
    assert compare(good, stderr_diff) == 'MISMATCH', 'the whole Defined line is the token'
    assert compare(good, (1, good[1])) == 'MISMATCH', 'the exit code is compared'
    assert compare(good, (134, b'')) == 'ONE_FAILED'
    assert compare((125, b'boom'), (134, b'')) == 'BOTH_FAILED'
    assert compare(good, (0, b'')) == 'ONE_FAILED', 'a verdict exit with nothing printed is a failure'
    exhausted = (3, b'SCExhausted {transitions: 5, core_reductions: 4}\nSCMemory {next_alloc_id: 1, last_address: 10, trace_events: 3}\n')
    assert compare(exhausted, exhausted) == 'MATCH' and tokens(exhausted[1]) == [b'SCExhausted {transitions: 5, core_reductions: 4}']
    assert compare(exhausted, good) == 'MISMATCH'
    unsupported = (3, UNSUPPORTED_FORK.encode() + b'\n')
    assert tokens(unsupported[1]) == [UNSUPPORTED_FORK.encode()] and SC_SPECIFIC.match(tokens(unsupported[1])[0])
    # row E checker: the expected figures, then each doctored figure
    fields = {'startup-transitions': 1, 'startup-complete-at': 1}
    def run(b, red=None, mem=(1, 648)):
        r = b - 1 if b else 0
        if red is not None:
            r = red
        return (3, f'SCExhausted {{transitions: {b}, core_reductions: {r}}}\nSCMemory {{next_alloc_id: {mem[0]}, last_address: {mem[1]}, trace_events: 3}}\n'.encode())
    runs = {b: run(b) for b in ROW_E_BUDGETS}
    runs[0] = (3, b'SCExhausted {transitions: 0, core_reductions: 0}\nSCMemory {next_alloc_id: 0, last_address: 655, trace_events: 0}\n')
    drive = (1, FUEL_KILL.encode() + b'\n')
    assert check_row_e('nogl', fields, runs, drive) == []
    bad = dict(runs); bad[7] = run(7, red=7)
    assert check_row_e('nogl', fields, bad, drive), 'P2 budget (two decrements / wrong count) is red'
    bad = dict(runs); bad[4096] = run(4096, mem=(2, 640))
    assert check_row_e('nogl', fields, bad, drive), 'memory movement after the startup is red'
    assert check_row_e('nogl', fields, runs, (0, b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n')), 'drive not fuel-killed is red'
    bad = dict(runs); bad[0] = (3, b'SCExhausted {transitions: 0, core_reductions: 0}\nSCMemory {next_alloc_id: 1, last_address: 648, trace_events: 3}\n')
    assert check_row_e('nogl', fields, bad, drive), 'a lifecycle effect at budget 0 is red'
    bad = dict(runs); bad[2] = (1, FUEL_KILL.encode() + b'\n')
    assert check_row_e('nogl', fields, bad, drive), 'a fuel kill inside the SC run is red'
    glob = {'startup-transitions': 2, 'startup-complete-at': 13}
    gruns = {0: runs[0], 1: (3, b'SCExhausted {transitions: 1, core_reductions: 0}\nSCMemory {next_alloc_id: 0, last_address: 655, trace_events: 0}\n'),
             2: (3, b'SCExhausted {transitions: 2, core_reductions: 1}\nSCMemory {next_alloc_id: 0, last_address: 655, trace_events: 0}\n'),
             7: (3, b'SCExhausted {transitions: 7, core_reductions: 6}\nSCMemory {next_alloc_id: 1, last_address: 648, trace_events: 3}\n'),
             13: (3, b'SCExhausted {transitions: 13, core_reductions: 11}\nSCMemory {next_alloc_id: 2, last_address: 644, trace_events: 5}\n'),
             14: (3, b'SCExhausted {transitions: 14, core_reductions: 12}\nSCMemory {next_alloc_id: 2, last_address: 644, trace_events: 5}\n'),
             4096: (3, b'SCExhausted {transitions: 4096, core_reductions: 4094}\nSCMemory {next_alloc_id: 2, last_address: 644, trace_events: 5}\n')}
    assert check_row_e('glob', glob, gruns, drive) == []
    bad = dict(gruns); bad[13] = (3, b'SCExhausted {transitions: 13, core_reductions: 12}\nSCMemory {next_alloc_id: 2, last_address: 644, trace_events: 5}\n')
    assert check_row_e('glob', glob, bad, drive), 'a startup boundary off by one is red'
    assert parse_baseline(ROOT / 'scripts/exec_baseline.txt').get('001-return-literal') == 'MATCH'
    assert parse_baseline(ROOT / 'tests/immaculate/baseline.txt').get('zd-any-bounded-int-crash') == 'MATCH/CRASH'
    modelfail = (1, b'ModelFailure {msg: "Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)"}\n')
    assert compare(modelfail, modelfail) == 'MATCH'
    assert compare(modelfail, (1, modelfail[1].replace(b'2658', b'2659'))) == 'MISMATCH', 'model fail-stop records are compared'
    assert compare(modelfail, (2, b'')) == 'BOTH_FAILED', 'a model fail-stop against a crash is the same failure class'
    assert compare(modelfail, good) == 'ONE_FAILED'
    print('test_sc_step: SELFTEST OK (23 plants: token order/length/whole-line/exit-code, one-sided and both-sided failures, '
          'an SC record against a verdict, model fail-stop records (equal/unequal/against a crash/against a verdict), row E figures/memory/budget-0/fuel-kill/drive-kill/startup boundary, baseline parsing incl. the immaculate CRASH class)')


def capped_env():
    return {**os.environ, 'LEAN_ABORT_ON_PANIC': '1',
            'CERB_MEM_MAX': os.environ.get('CERB_TEST_MEM_MAX', '4G')}


def run(cmd, cwd=ROOT):
    """Run one engine under the per-test memory cap and the wall bound (timeout INSIDE the
    cap, as scripts/common.sh CAPPED_TEST does); returns (rc, stdout, stderr)."""
    p = subprocess.run([str(CAPPED), 'timeout', '--kill-after=5', str(TIMEOUT_SECS), *map(str, cmd)],
                       cwd=cwd, capture_output=True, env=capped_env(), timeout=TIMEOUT_SECS + 30)
    return p.returncode, p.stdout, p.stderr


def build(command, cwd, log):
    with log.open('wb') as f:
        subprocess.run(command, cwd=cwd, stdout=f, stderr=subprocess.STDOUT, check=True)


def opam(*cmd):
    return ['opam', 'exec', '--switch=' + str(ROOT), '--', *cmd]


def libc_args(outdir: Path):
    jsons = subprocess.run([str(ROOT / 'scripts/libc_prep.sh'), '--jsons', str(outdir / 'libcjson')],
                           capture_output=True, text=True, check=True).stdout.split()
    if len(jsons) != 12:
        raise SystemExit(f'libc_prep.sh --jsons: expected 12 metadata jsons, got {len(jsons)}')
    args = ['--libc', str(ROOT / 'tests/libc/libc.core')]
    for j in jsons:
        args += ['--libc-tu', j]
    return args


class Case:
    def __init__(self, corpus, cfile: Path, baseline_status, libc, first):
        self.corpus, self.cfile, self.baseline, self.libc, self.first = corpus, cfile, baseline_status, libc, first
        self.name = f'{corpus}/{cfile.stem}'
        self.rows = {}
        self.notes = []
        self.unsupported = 0


def run_case(case: Case, outdir: Path, libc_flags):
    key = hashlib.sha256(case.name.encode()).hexdigest()[:12]
    stash = outdir / 'cases' / f'{case.cfile.stem}-{key}'
    stash.mkdir(parents=True, exist_ok=True)
    nolibc = [] if case.libc else ['--nolibc']
    oracle_mode = [] if case.first else ['--mode=exhaustive']
    sc_first = ['--sc-first'] if case.first else []
    lean_first = ['--first'] if case.first else []
    # 1. oracle drive; 2. OCaml sc; 3. cabs-json; 4. Lean drive; 5. Lean sc
    o = run([ORACLE, f'--runtime={RUNTIME}', *nolibc, '--exec', '--batch', *oracle_mode, case.cfile])
    s = run([PROBE, f'--runtime={RUNTIME}', *nolibc, '--sc-budget', str(BUDGET), *sc_first, case.cfile])
    jrc, jout, jerr = run([ORACLE, f'--runtime={RUNTIME}', '--cabs-json', case.cfile])
    for tag, r in (('oracle', o), ('ocaml-sc', s)):
        (stash / f'{tag}.stdout').write_bytes(r[1]); (stash / f'{tag}.stderr').write_bytes(r[2]); (stash / f'{tag}.rc').write_text(str(r[0]))
    case.rows['B'] = compare((o[0], o[1]), (s[0], s[1]))
    if jrc != 0 or not jout:
        case.notes.append(f'cabs-json failed rc={jrc}')
        case.rows['A'] = case.rows['C'] = 'BRIDGE_FAILED'
        return case
    jfile = stash / 'prog.json'
    jfile.write_bytes(jout)
    d = run([LEAN, '--batch', *lean_first, *libc_flags, jfile])
    l = run([LEAN, '--batch', '--sc-run', '--sc-budget', str(BUDGET), *sc_first, *libc_flags, jfile])
    for tag, r in (('lean-drive', d), ('lean-sc', l)):
        (stash / f'{tag}.stdout').write_bytes(r[1]); (stash / f'{tag}.stderr').write_bytes(r[2]); (stash / f'{tag}.rc').write_text(str(r[0]))
    case.rows['A'] = compare((d[0], d[1]), (l[0], l[1]))
    case.rows['C'] = compare((l[0], l[1]), (s[0], s[1]))
    for r in (s, l):
        for t in tokens(r[1]):
            if t.startswith(b'SCUnsupported'):
                case.unsupported += 1
            elif SC_SPECIFIC.match(t):
                case.notes.append(f'SC-specific record in a run-to-completion row: {t.decode(errors="replace")}')
    return case


def collect_cases(libc: bool):
    cases = []
    if not libc:
        for corpus, folder, baseline in NOLIBC_CORPORA:
            statuses = parse_baseline(ROOT / baseline) if baseline else None
            files = sorted(f for f in (ROOT / folder).glob('*.c')
                           if not f.name.endswith('.syntax-only.c') and not f.name.endswith('.exhaust.c')
                           and not (corpus == 'sc-step' and (f.name.startswith('loop-') or f.name == 'par-control.c')))
            for f in files:
                status = 'MATCH' if statuses is None else statuses.get(f.stem, 'UNBASELINED')
                cases.append(Case(corpus, f, status, libc=False, first=False))
    else:
        statuses = parse_baseline(ROOT / 'tests/libc_exec/baseline.txt')
        for f in sorted((ROOT / 'tests/libc_exec').glob('*.c')):
            cases.append(Case('libc_exec', f, statuses.get(f.stem, 'UNBASELINED'), libc=True, first=True))
        for f in sorted((ROOT / 'tests/libc_exec/exhaustive').glob('*.c')):
            cases.append(Case('libc_exec/exhaustive', f, statuses.get('exhaustive/' + f.stem, 'UNBASELINED'), libc=True, first=False))
    return cases


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--libc', action='store_true', help='row D: tests/libc_exec in libc mode (LADDER Tier B) instead of the nolibc corpora')
    ap.add_argument('--selftest', action='store_true', help='hermetic plants on the comparison and row E checkers; no engine runs')
    ap.add_argument('--jobs', type=int, default=max(1, min(16, (os.cpu_count() or 4) // 2)))
    ap.add_argument('--only', help='substring filter on corpus/name')
    ap.add_argument('--out', help='evidence directory (default .tmp/sc-step/<mode>)')
    ap.add_argument('--skip-build', action='store_true', help='SKIP_BUILD: binaries must exist and be fresh (tools/check_driver_fresh.sh --check)')
    args = ap.parse_args()
    if args.selftest:
        selftest()
        return
    t0 = time.monotonic()
    outdir = Path(args.out).resolve() if args.out else OUT_DEFAULT / ('libc' if args.libc else 'tier-a')
    outdir.mkdir(parents=True, exist_ok=True)
    if args.skip_build or os.environ.get('SKIP_BUILD') == '1':
        for b in (ORACLE, PROBE, LEAN):
            if not b.exists():
                raise SystemExit(f'SKIP_BUILD but {b} is missing')
        build([str(ROOT / 'tools/check_driver_fresh.sh'), '--check'], ROOT, outdir / 'fresh.log')
    else:
        build([str(ROOT / 'tools/check_handwritten_sync.sh')], ROOT, outdir / 'sync.log')
        build([str(ROOT / 'tools/check_lem_sync.sh'), '--check'], ROOT, outdir / 'lem-sync.log')
        build([str(ROOT / 'tools/check_lem_sync.sh'), '--check-lean'], ROOT, outdir / 'lem-sync-lean.log')
        build(opam('dune', 'build', '--root', '.', 'backend/driver/main.exe', 'backend/sc_probe/sc_run.exe',
                   'cerberus-lib.install', 'cerberus.install'), ROOT, outdir / 'native-build.log')
        build([str(CAPPED), 'lake', 'build', 'cerberus-lean'], ROOT / 'lean_frontend', outdir / 'lean-build.log')
    if not (RUNTIME / 'lib/cerberus/runtime/libc/libc.co').exists():
        raise SystemExit(f'runtime not staged: {RUNTIME}/lib/cerberus/runtime/libc/libc.co (dune build cerberus.install)')
    libc_flags = libc_args(outdir) if args.libc else []
    cases = collect_cases(args.libc)
    if args.only:
        cases = [c for c in cases if args.only in c.name]
    if not cases:
        raise SystemExit('FAIL: zero cases selected (a vacuous run is not a pass)')
    report = {'schema': 1, 'mode': 'libc' if args.libc else 'tier-a', 'budget': BUDGET, 'row_e_fuel': ROW_E_FUEL,
              'timeout_secs': TIMEOUT_SECS, 'jobs': args.jobs,
              'head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
              'diff_sha256': hashlib.sha256(subprocess.check_output(['git', 'diff', '--binary', 'HEAD'], cwd=ROOT)).hexdigest(),
              'binaries': {str(p.relative_to(ROOT)): hashlib.sha256(p.read_bytes()).hexdigest() for p in (ORACLE, PROBE, LEAN)},
              'cases': [], 'row_e': [], 'control': None}
    red = []
    tallies = {'A': {}, 'B': {}, 'C': {}}
    c_expected_diff = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=args.jobs) as pool:
        for case in pool.map(lambda c: run_case(c, outdir, libc_flags), cases):
            row = {'name': case.name, 'baseline': case.baseline, 'first': case.first, 'rows': case.rows,
                   'unsupported': case.unsupported, 'notes': case.notes}
            report['cases'].append(row)
            for r in ('A', 'B', 'C'):
                st = case.rows.get(r, 'MISSING')
                tallies[r][st] = tallies[r].get(st, 0) + 1
            a, b, c = case.rows.get('A'), case.rows.get('B'), case.rows.get('C')
            line = f'[{case.name}] A={a} B={b} C={c} baseline={case.baseline}'
            if a not in ('MATCH', 'BOTH_FAILED'):
                red.append(f'{case.name}: row A {a} (Lean sc vs Lean drive)')
            if b not in ('MATCH', 'BOTH_FAILED'):
                red.append(f'{case.name}: row B {b} (OCaml sc vs oracle)')
            if case.baseline in ('MATCH', 'UB_MATCH'):
                if c != 'MATCH':
                    red.append(f'{case.name}: row C {c} on a {case.baseline} baseline row (Lean sc vs OCaml sc)')
            elif case.baseline in ('MATCH/CRASH', 'MATCH/KILL'):
                if c != 'BOTH_FAILED':
                    red.append(f'{case.name}: row C {c} on a {case.baseline} baseline row (both engines fail-stop there; Lean sc vs OCaml sc)')
            else:
                c_expected_diff.append(f'{case.name} ({case.baseline}: C={c})')
                line += '  [C not required: owning baseline row is ' + case.baseline + ']'
            if case.notes:
                red.extend(f'{case.name}: {n}' for n in case.notes)
            print(line, flush=True)
    total_unsupported = sum(c.unsupported for c in cases)
    if total_unsupported:
        red.append(f'row F: {total_unsupported} SCUnsupported record(s) on the sequential corpora (expected 0)')
    if not args.libc:
        # Row E (Lean only, explicit small fuel) and the row F control, both engines.
        fixtures = sorted((ROOT / 'tests/sc-step').glob('loop-*.c'))
        for fx in fixtures:
            fields = header_fields(fx)
            budgets = sorted(set(ROW_E_BUDGETS) | ({fields['startup-complete-at'], fields['startup-complete-at'] + 1}
                                                    if 'startup-complete-at' in fields else set()))
            jrc, jout, _ = run([ORACLE, f'--runtime={RUNTIME}', '--cabs-json', fx])
            if jrc != 0 or not jout:
                red.append(f'row E {fx.name}: cabs-json failed rc={jrc}'); continue
            jfile = outdir / f'{fx.stem}.json'; jfile.write_bytes(jout)
            runs = {}
            for b in budgets:
                rc, out, err = run([LEAN, '--batch', '--sc-run', '--sc-budget', str(b), '--fuel', str(ROW_E_FUEL), jfile])
                (outdir / f'{fx.stem}-b{b}.stdout').write_bytes(out)
                runs[b] = (rc, out)
            drc, dout, _ = run([LEAN, '--batch', '--fuel', str(ROW_E_FUEL), jfile])
            (outdir / f'{fx.stem}-drive.stdout').write_bytes(dout)
            fails = check_row_e(fx.name, fields, runs, (drc, dout))
            red.extend(f'row E {f}' for f in fails)
            report['row_e'].append({'fixture': fx.name, 'fields': fields, 'budgets': budgets,
                                    'records': {str(b): tokens(out)[0].decode(errors='replace') if tokens(out) else None for b, (rc, out) in runs.items()},
                                    'drive_tokens': [t.decode(errors='replace') for t in tokens(dout)], 'ok': not fails})
            print(f'[row E {fx.name}] ' + ('OK ' if not fails else 'FAIL ') + '; '.join(f'b{b}={tokens(out)[0].decode(errors="replace") if tokens(out) else "?"}' for b, (rc, out) in sorted(runs.items())), flush=True)
        control = ROOT / 'tests/sc-step/par-control.c'
        s = run([PROBE, f'--runtime={RUNTIME}', '--nolibc', '--sc-budget', str(BUDGET), control])
        jrc, jout, _ = run([ORACLE, f'--runtime={RUNTIME}', '--cabs-json', control])
        jfile = outdir / 'par-control.json'; jfile.write_bytes(jout)
        l = run([LEAN, '--batch', '--sc-run', '--sc-budget', str(BUDGET), jfile]) if jrc == 0 and jout else (jrc, b'', b'')
        want = [UNSUPPORTED_FORK.encode()]
        ok = tokens(s[1]) == want and s[0] == 3 and tokens(l[1]) == want and l[0] == 3
        report['control'] = {'ocaml': [t.decode() for t in tokens(s[1])], 'lean': [t.decode() for t in tokens(l[1])], 'ok': ok}
        if not ok:
            red.append(f'row F control par-control.c: expected {UNSUPPORTED_FORK!r} + exit 3 on both engines; OCaml rc={s[0]} {tokens(s[1])}, Lean rc={l[0]} {tokens(l[1])}')
        print(f'[row F control par-control.c] ' + ('OK' if ok else 'FAIL'), flush=True)
    report['tallies'] = tallies
    report['c_not_required'] = c_expected_diff
    report['red'] = red
    report['wall_s'] = time.monotonic() - t0
    (outdir / 'report.json').write_text(json.dumps(report, indent=2) + '\n')
    mode = 'libc (row D)' if args.libc else 'tier-a (rows A-C, E, F)'
    summary = ' '.join(f'{r}:{",".join(f"{k}={v}" for k, v in sorted(t.items()))}' for r, t in tallies.items())
    print(f'test_sc_step {mode}: {len(cases)} programs; {summary}; SCUnsupported={total_unsupported}; C not required on {len(c_expected_diff)} non-MATCH baseline rows; wall {report["wall_s"]:.1f}s')
    if red:
        print('FAIL test_sc_step:')
        for r in red:
            print('  ' + r)
        print(f'Evidence: {outdir}/report.json')
        raise SystemExit(1)
    print(f'PASS test_sc_step {mode} (budget {BUDGET}, row E fuel {ROW_E_FUEL}); Evidence: {outdir}/report.json')


if __name__ == '__main__':
    main()
