#!/usr/bin/env python3
"""sc_reference.py — the finite scalar reference enumerator for tests/litmus.

Derives only the SC-class rows of expectations.txt. The current scope and
limits are in README.md and the September 21 SC prototype charter. This is
an independent implementation over hand transcriptions, not a C parser or a
proof of correspondence with Cmm. Mixed result sets are per-schedule evidence,
not assertions of program-level definedness.

Model (stated independently of the engines):
  * every interleaving of the threads at memory-action granularity, with the
    main thread's pre-par actions first and post-par actions last (asw);
  * a load reads the value of the most recent store in the interleaving;
  * hb = (program order ∪ asw ∪ sw)+ where sw = {(w, r) | r is an atomic
    load reading-from the atomic store w}  (seq_cst implies release/acquire);
  * data race = two accesses to the same location, at least one a store, at
    least one non-atomic, from different threads, unordered by hb
    (cmm_csem.lem:1431-1438 `data_races`, specialised to this fragment);
  * outcome tokens: `Specified(v)` for every race-free trace's return value,
    plus `UB005_data_race` iff some trace has a race.

Each litmus C file has a hand transcription below (a bug in a transcription
is a bug in the expectation; the C file's header comment records the
independent source of its set where one exists).

Usage:
  sc_reference.py                       print every derived set
  sc_reference.py --check EXPECTATIONS  fail (rc 1) unless every SC-class
                                        row equals its derived set and every
                                        transcribed test has an SC-class row
"""
import sys

# ---- IR ------------------------------------------------------------------
# op := ('st', var, val) | ('ld', var, reg) | ('set', reg, val)
#     | ('if', reg, val, then_ops, else_ops)          val := int | reg name
# test := dict(vars={name: (atomic: bool, init: int|None)}, regs={..},
#              pre=[ops], threads=[[ops], ...], post=[ops], ret=lambda regs)

def st(var, val): return ('st', var, val)
def ld(var, reg): return ('ld', var, reg)
def setr(reg, val): return ('set', reg, val)
def iff(reg, val, then_ops, else_ops=()): return ('if', reg, val, tuple(then_ops), tuple(else_ops))

TESTS = {
 'SB+sc_sc+sc_sc.c': dict(vars={'x': (True, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[st('x', 1), ld('y', 'r1')], [st('y', 1), ld('x', 'r2')]], post=[],
    ret=lambda r: r['r1'] + 2 * r['r2']),
 'LB+sc_sc+sc_sc.c': dict(vars={'x': (True, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[ld('x', 'r1'), st('y', 1)], [ld('y', 'r2'), st('x', 1)]], post=[],
    ret=lambda r: r['r1'] + 2 * r['r2']),
 'MP+na_sc+sc_na.c': dict(vars={'x': (False, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[st('x', 1), st('y', 1)],
                     [ld('y', 'z1'), iff('z1', 1, [ld('x', 'z2')], [setr('z2', 2)])]], post=[],
    ret=lambda r: r['z2']),
 'WRC+sc+sc_sc+sc_sc.c': dict(vars={'x': (True, 0), 'y': (True, 0)}, regs={'z1': 0},
    pre=[], threads=[[st('x', 1)],
                     [ld('x', 'z1'), iff('z1', 1, [st('y', 1)])],
                     [ld('y', 'z2'), ld('x', 'z3')]], post=[],
    ret=lambda r: r['z1'] + 2 * r['z2'] + 4 * r['z3']),
 'IRIW+sc+sc+sc_sc+sc_sc.c': dict(vars={'x': (True, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[st('x', 1)], [st('y', 1)],
                     [ld('x', 'z1'), ld('y', 'z2')], [ld('y', 'z3'), ld('x', 'z4')]], post=[],
    ret=lambda r: r['z1'] + 2 * (r['z2'] + 2 * (r['z3'] + 2 * r['z4']))),
 'coherence+sc_sc_sc.c': dict(vars={'x': (True, None)}, regs={},
    pre=[st('x', 0), st('x', 1), ld('x', 'a')], threads=[], post=[],
    ret=lambda r: r['a']),
 'coherence+init+sc_sc.c': dict(vars={'x': (True, None)}, regs={},
    pre=[st('x', 0)], threads=[[st('x', 1), ld('x', 'a')], []], post=[],
    ret=lambda r: r['a']),
 'hb-mo-cycle+Wsc_Wsc_Rsc+Wsc_Wsc_Rsc.c': dict(vars={'x': (True, None), 'y': (True, None)}, regs={},
    pre=[], threads=[[st('x', 0), st('y', 1), ld('y', 'a1')],
                     [st('y', 0), st('x', 1), ld('x', 'a2')]], post=[],
    ret=lambda r: r['a1'] + 2 * r['a2']),
 'datarace+Rna+Rna.c': dict(vars={'x': (False, 0)}, regs={},
    pre=[], threads=[[ld('x', 'r1')], [ld('x', 'r2')]], post=[], ret=lambda r: 0),
 'datarace+Wna+Wna.c': dict(vars={'x': (False, 0)}, regs={},
    pre=[], threads=[[st('x', 1)], [st('x', 2)]], post=[ld('x', 'r')], ret=lambda r: r['r']),
 'datarace+Rna+Wna.c': dict(vars={'x': (False, 0)}, regs={},
    pre=[], threads=[[ld('x', 'r')], [st('x', 1)]], post=[], ret=lambda r: r['r']),
 'datarace+Rna+Rna_Wna.c': dict(vars={'x': (False, 0)}, regs={},
    pre=[], threads=[[ld('x', 'r1')], [ld('x', 'r2'), st('x', 1)]], post=[], ret=lambda r: 0),
 'datarace+Wna_sc+sc_Rna.c': dict(vars={'x': (False, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[st('x', 1), st('y', 1)], [ld('y', 'r1'), ld('x', 'r2')]], post=[],
    ret=lambda r: r['r2']),
 'MP+na+na.c': dict(vars={'x': (False, 0)}, regs={'r': 7},
    pre=[], threads=[[st('x', 1)], [ld('x', 'r')]], post=[], ret=lambda r: r['r']),
 # --- S7 (pre-merge audit F1): the shared objects at FILE SCOPE. The reference
 # model's `vars` initial values ARE static initialisation (sequenced before
 # program startup, C11 5.1.2p1 / 6.2.4p3), so the transcripts equal their
 # block-scope rows'; the two globals+init rows are the audit's probes p8a/p8d.
 'SB+sc_sc+sc_sc+globals.c': dict(vars={'x': (True, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[st('x', 1), ld('y', 'r1')], [st('y', 1), ld('x', 'r2')]], post=[],
    ret=lambda r: r['r1'] + 2 * r['r2']),
 'MP+na_sc+sc_na+globals.c': dict(vars={'x': (False, 0), 'y': (True, 0)}, regs={},
    pre=[], threads=[[st('x', 1), st('y', 1)],
                     [ld('y', 'z1'), iff('z1', 1, [ld('x', 'z2')], [setr('z2', 2)])]], post=[],
    ret=lambda r: r['z2']),
 'datarace+Wna+Wna+globals.c': dict(vars={'x': (False, 0)}, regs={},
    pre=[], threads=[[st('x', 1)], [st('x', 2)]], post=[ld('x', 'r')], ret=lambda r: r['r']),
 'globals+init+Wna_Wna.c': dict(vars={'p': (False, 0), 'q': (False, 0)}, regs={},
    pre=[], threads=[[st('p', 1)], [st('q', 2)]], post=[ld('p', 'a'), ld('q', 'b')],
    ret=lambda r: r['a'] + r['b']),
 'globals+init+Rna_Rna.c': dict(vars={'c': (False, 5)}, regs={},
    pre=[], threads=[[ld('c', 'r1')], [ld('c', 'r2')]], post=[], ret=lambda r: r['r1'] + r['r2']),
}

MAIN = 'main'

def run_ops(ops, tid, regs, mem, events, atomic_of):
    """Execute a straight-line op list deterministically (pre/post)."""
    ops = list(ops)
    while ops:
        op = ops.pop(0)
        ops = step(op, tid, regs, mem, events, atomic_of) + ops

def step(op, tid, regs, mem, events, atomic_of):
    """Execute one op; return the ops it expands into (for 'if')."""
    kind = op[0]
    if kind == 'set':
        _, reg, val = op
        regs[reg] = regs[val] if isinstance(val, str) else val
        return []
    if kind == 'if':
        _, reg, val, then_ops, else_ops = op
        return list(then_ops) if regs[reg] == val else list(else_ops)
    if kind == 'st':
        _, var, val = op
        v = regs[val] if isinstance(val, str) else val
        eid = len(events)
        events.append(dict(eid=eid, tid=tid, kind='W', var=var, atomic=atomic_of[var], rf=None))
        mem[var] = (v, eid)
        return []
    if kind == 'ld':
        _, var, reg = op
        if mem[var] is None:
            raise RuntimeError(f'load of uninitialised {var} (transcription bug)')
        v, weid = mem[var]
        regs[reg] = v
        eid = len(events)
        events.append(dict(eid=eid, tid=tid, kind='R', var=var, atomic=atomic_of[var], rf=weid))
        return []
    raise RuntimeError(op)

def has_race(events, pre_count, thread_count_end):
    n = len(events)
    hb = [[False] * n for _ in range(n)]
    by_tid = {}
    for e in events:
        by_tid.setdefault(e['tid'], []).append(e['eid'])
    # program order
    for lst in by_tid.values():
        for i in range(len(lst)):
            for j in range(i + 1, len(lst)):
                hb[lst[i]][lst[j]] = True
    # asw: main pre-events before every thread event; thread events before main post-events
    thread_eids = [e['eid'] for e in events if e['tid'] != MAIN]
    pre_eids = [e['eid'] for e in events[:pre_count]]
    post_eids = [e['eid'] for e in events[thread_count_end:]]
    for a in pre_eids:
        for b in thread_eids + post_eids:
            hb[a][b] = True
    for a in thread_eids:
        for b in post_eids:
            hb[a][b] = True
    # sw: atomic store -> atomic load reading from it
    for e in events:
        if e['kind'] == 'R' and e['atomic'] and e['rf'] is not None and events[e['rf']]['atomic']:
            hb[e['rf']][e['eid']] = True
    # transitive closure
    for k in range(n):
        for i in range(n):
            if hb[i][k]:
                row_k = hb[k]
                row_i = hb[i]
                for j in range(n):
                    if row_k[j]:
                        row_i[j] = True
    for a in events:
        for b in events:
            if a['eid'] < b['eid'] and a['var'] == b['var'] and (a['kind'] == 'W' or b['kind'] == 'W') \
               and not (a['atomic'] and b['atomic']) and a['tid'] != b['tid'] \
               and not hb[a['eid']][b['eid']] and not hb[b['eid']][a['eid']]:
                return True
    return False

def derive(test):
    atomic_of = {v: a for v, (a, _) in test['vars'].items()}
    outcomes = set()
    racy = False
    base_regs = dict(test['regs'])
    base_mem = {v: (None if init is None else (init, -1)) for v, (_, init) in test['vars'].items()}
    # init writes are main-thread pre events (hb-before everything via asw)
    base_events = []
    for v, (a, init) in test['vars'].items():
        if init is not None:
            eid = len(base_events)
            base_events.append(dict(eid=eid, tid=MAIN, kind='W', var=v, atomic=a, rf=None))
            base_mem[v] = (init, eid)
    run_ops(test['pre'], MAIN, base_regs, base_mem, base_events, atomic_of)
    pre_count = len(base_events)

    def dfs(pcs, regs, mem, events):
        nonlocal racy
        live = [i for i, ops in enumerate(pcs) if ops]
        if not live:
            regs2, mem2, events2 = dict(regs), dict(mem), list(events)
            thread_end = len(events2)
            run_ops(test['post'], MAIN, regs2, mem2, events2, atomic_of)
            if has_race(events2, pre_count, thread_end):
                racy = True
            else:
                outcomes.add(test['ret'](regs2))
            return
        for i in live:
            pcs2 = [list(o) for o in pcs]
            regs2, mem2, events2 = dict(regs), dict(mem), list(events)
            op = pcs2[i].pop(0)
            pcs2[i] = step(op, i, regs2, mem2, events2, atomic_of) + pcs2[i]
            dfs(pcs2, regs2, mem2, events2)

    dfs([list(t) for t in test['threads']], base_regs, base_mem, base_events)
    toks = [f'Specified({v})' for v in outcomes]
    if racy:
        toks.append('UB005_data_race')
    # canonical order = the lane's (`LC_ALL=C sort -u`: bytewise/lexicographic,
    # so Specified(10) < Specified(2)); Python's default str sort is the same
    return '{' + ','.join(sorted(toks)) + '}'

def parse_expectations(path):
    rows = {}
    with open(path) as f:
        for lineno, line in enumerate(f, 1):
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.split()
            if len(parts) != 3:
                raise SystemExit(f'expectations: malformed row: {line!r}')
            if parts[0] in rows:
                raise SystemExit(f'expectations: duplicate row {parts[0]!r} at {path}:{lineno}')
            rows[parts[0]] = (parts[1], parts[2])
    return rows

def main(argv):
    derived = {name: derive(t) for name, t in TESTS.items()}
    if len(argv) == 1:
        for name in sorted(derived):
            print(f'{name}  SC  {derived[name]}')
        return 0
    if argv[1] == '--check' and len(argv) == 3:
        rows = parse_expectations(argv[2])
        bad = 0
        for name, tokset in sorted(derived.items()):
            if name not in rows:
                print(f'[FAIL] {name}: transcribed here but no row in expectations'); bad += 1; continue
            cls, exp = rows[name]
            if cls != 'SC':
                print(f'[FAIL] {name}: row class {cls}, transcription says SC'); bad += 1; continue
            if exp != tokset:
                print(f'[FAIL] {name}: expectations {exp} vs derived {tokset}'); bad += 1; continue
            print(f'[OK]   {name}: {tokset}')
        for name, (cls, exp) in sorted(rows.items()):
            if cls == 'SC' and name not in derived:
                print(f'[FAIL] {name}: SC-class row without a transcription'); bad += 1
        if bad:
            print(f'sc_reference: {bad} mismatch(es)'); return 1
        print(f'sc_reference: all {len(derived)} SC rows agree with the derivation')
        return 0
    print(__doc__); return 2

if __name__ == '__main__':
    sys.exit(main(sys.argv))
