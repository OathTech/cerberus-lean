#!/usr/bin/env python3
"""check_failure_reach.py — the failure-reach REGISTER check (the tripwire).

THE POINT (fuel-pending close-out 2026-09-08; option C of the pure-failure
reachability census, docs/2026-09-07_pure-failure-reachability-census.md; the
parked twin design docs/2026-09-07_pure-failure-correspondence-design.md names
this check as one of its two flip-condition tripwires): every PURE failure site
(`failwithI`/`panic!`) in the execution dependency closure is a row of
scripts/failure_reach_register.txt with its POSITION class (Q1) and its REACH
class (Q3: UNREACHABLE-BY-INVARIANT / REACHABLE / UNKNOWN) and the one-line
invariant, witness or need the census recorded. The live census (the rebuilt
reach log + scripts/failure_census.py + scripts/failure_position.py) must equal
the register exactly, both directions:

  RED  a NEW pure exec-closure site (or a pure site whose kernel owner the
       compiler ranges cannot resolve) that has no register row — it needs
       review (position by reading where the classifier is not reliable,
       reach by invariant/witness);
  RED  a register row whose site no longer exists (stale row);
  RED  a site whose live position class differs from the row's;
  RED  a DISCARDABLE position: a GENERATED-file `let x := … failwithI … ; body`
       (LET-BOUND / LET-BOUND-FUN) whose bound names are dead — the F1 shape
       (OCaml raises on the discarded failure, a strict Lean evaluation would
       not have to), the twin design's first flip condition; today 0;
  RED  a row edited without re-sealing (any change to file/definition/token/
       msg/scope/position/position_reviewed/reach flips its seal) — a class
       change is a REVIEW change and must go through --reseal in a commit
       that states why;
  RED  a row whose reach or reviewed position is UNREVIEWED, or whose class is
       not one of the three; a malformed row; a `# tally:` line that does not
       equal the rows.

The census is a KERNEL CONSTANT-DEPENDENCY closure (not a path reachability
proof — a site in the closure may be dead), and the classifier is token-level:
reliable on generated text (single-line definitions, parenthesised nested
matches), NOT on hand-written indentation-scoped files — there the census READ
every NON-TAIL candidate (the `position_reviewed` column; note `manual:`), and
the DISCARDABLE test is applied only to generated files. Reach classes are
REVIEWED CLAIMS copied from the census's Q3 assignment (invariant NAME + cite,
or a witness program), not theorems; the check keeps them from drifting
silently, it does not establish them.

Usage (scripts/check_failure_reach.sh drives this; the census.json must come
from a reach log of THIS tree):
  check_failure_reach.py --root ROOT --census census.json [--register FILE]
  check_failure_reach.py --root ROOT --census census.json --emit [--seed FILE]
        print a fresh register to stdout: rows for every live site, reviewed
        columns carried over from --seed (an existing register, or the census
        evidence TSV sites231_classified.tsv), new rows marked UNREVIEWED
  check_failure_reach.py --reseal FILE     rewrite the seals + tally of FILE in place
"""
import argparse, csv, hashlib, json, re, sys
from collections import Counter
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import failure_position as fp

COLS = ['file', 'definition', 'token', 'msg', 'scope', 'position', 'position_reviewed', 'reach',
        'need', 'cite', 'note', 'seal']
SEALED = ['file', 'definition', 'token', 'msg', 'scope', 'position', 'position_reviewed', 'reach']
REACH = ('UNREACHABLE-BY-INVARIANT', 'REACHABLE', 'UNKNOWN')
DEFAULT_REGISTER = Path(__file__).resolve().parent / 'failure_reach_register.txt'


def msg_key(following):
    return re.sub(r'\s+', ' ', following.strip())[:60]


def seal_of(row):
    return hashlib.sha256('|'.join(row[c] for c in SEALED).encode()).hexdigest()[:16]


def live_sites(root, census):
    """The pure sites of the exec closure + the pure sites with an unresolved owner,
    each with its live position class and DISCARDABLE verdict."""
    if 'reach_log_sha256' not in census:
        raise SystemExit('check_failure_reach: FAIL — census.json has no reach log (dependency columns missing; fail-closed)')
    cls = fp.Classifier(root)
    out = []
    for s in census['sites']:
        if s['group'] != 'pure_or_unresolved': continue
        status = s.get('dependency_status')
        if status == 'identified':
            if not s.get('exec_dependency'): continue
            scope = 'EXEC'
        else:
            scope = 'UNRESOLVED-OWNER'
        r = cls.classify(s['file'], s['offset'])
        names, dead = cls.dead_binding(s['file'], r)
        out.append({'file': s['file'], 'definition': s['definition'], 'token': s['token'],
                    'msg': msg_key(s['following_source']), 'scope': scope, 'position': r['cls'],
                    'line': s['line'], 'discardable': bool(s['generated'] and dead), 'let_names': names,
                    'lexical': s.get('lexical_definition', s['definition'])})
    return out


def read_register(path):
    rows, tally = [], None
    for ln, line in enumerate(Path(path).read_text().splitlines(), 1):
        if line.startswith('# tally:'):
            tally = line[len('# tally:'):].strip(); continue
        if not line.strip() or line.startswith('#') or line.startswith('file\tdefinition\t'): continue   # comments + the column-header line
        f = line.split('\t')
        if len(f) != len(COLS):
            raise SystemExit(f'check_failure_reach: FAIL — register line {ln}: {len(f)} fields, expected {len(COLS)} (TAB-separated: {" ".join(COLS)})')
        rows.append(dict(zip(COLS, f)))
    if not rows:
        raise SystemExit('check_failure_reach: FAIL — register has no rows (fail-closed)')
    return rows, tally


def tally_line(rows):
    c_scope = Counter(r['scope'] for r in rows)
    c_reach = Counter(r['reach'] for r in rows)
    c_pos = Counter('TAIL' if r['position_reviewed'] == 'TAIL' else 'NON-TAIL' for r in rows)
    return (f"sites={len(rows)} exec={c_scope.get('EXEC', 0)} unresolved-owner={c_scope.get('UNRESOLVED-OWNER', 0)} "
            f"reviewed-TAIL={c_pos.get('TAIL', 0)} reviewed-NON-TAIL={c_pos.get('NON-TAIL', 0)} "
            f"UNREACHABLE-BY-INVARIANT={c_reach.get('UNREACHABLE-BY-INVARIANT', 0)} REACHABLE={c_reach.get('REACHABLE', 0)} "
            f"UNKNOWN={c_reach.get('UNKNOWN', 0)} discardable=0")


HEADER = """# failure_reach_register.txt — THE REGISTER of the pure failure sites (`failwithI`/`panic!`)
# in the execution dependency closure (fuel-pending close-out 2026-09-08; option C of the
# pure-failure reachability census, lean_frontend/docs/2026-09-07_pure-failure-reachability-census.md,
# [USER 2026-09-07] "create a branch and send a worker to do option C"). It is the TRIPWIRE the
# parked twin design (docs/2026-09-07_pure-failure-correspondence-design.md) names: a DISCARDABLE
# site that is REACHABLE would flip that design from parked to live.
#
# One row per site; checked by scripts/check_failure_reach.sh (Tier B) = the live census
# (rebuilt reach log + scripts/failure_census.py + scripts/failure_position.py) against this file,
# both directions, fail-closed: a new site, a stale row, a moved position class, a DISCARDABLE
# generated position, an UNREVIEWED class or an edited-but-unsealed row is RED with the rows named.
# Reach classes are REVIEWED CLAIMS (the census's Q3 assignment: an invariant NAME with a .lem/.lean
# cite, or a witness program under tests/failure-probes/reach/), not theorems; position classes are
# the token-level classifier's (reliable on generated text) plus the census's READING of the
# hand-written NON-TAIL candidates (position_reviewed; `manual:` notes). The closure is a kernel
# constant-dependency closure, not a path — a listed site may be dead code.
#
# Columns (TAB-separated): file  definition(kernel owner)  token  msg(first 60 chars after the
#   token, whitespace-collapsed — the KEY with file/definition/token, multiset)  scope(EXEC |
#   UNRESOLVED-OWNER)  position(live classifier)  position_reviewed(TAIL | NON-TAIL/<kind>)
#   reach(UNREACHABLE-BY-INVARIANT | REACHABLE | UNKNOWN)  need/invariant/witness  cite  note  seal
# The seal is sha256(file|definition|token|msg|scope|position|position_reviewed|reach)[:16]: editing a
# class is a review change — re-seal with `check_failure_reach.py --reseal <file>` in a commit that
# states the justification (a new site: run the .sh, then `--emit --seed <this file>`, review the
# UNREVIEWED rows, re-seal).
"""


def emit(root, census, seed):
    sites = live_sites(root, census)
    # seeds: [(file, owner, token, loose message, line or None, reviewed columns)]
    seeds = []
    if seed:
        text = Path(seed).read_text().splitlines()
        if text and text[0].startswith('file\tline\tdefinition(kernel owner)'):
            # the census evidence TSV (sites231_classified.tsv): its `message/head` is
            # the following source with the quote characters dropped and a SHORTER
            # window than ours (cut at the ascription), on the census tree's line
            # numbers — so a seed matches when its key equals ours or is a prefix of
            # it; the LINE is the tie-break among same-message sites (a +1 shift is
            # accepted for a file that gained an import line); same-line sites of a
            # single-line generated definition are told apart by their messages
            for r in csv.DictReader(text, delimiter='\t', quoting=csv.QUOTE_NONE):
                rev = {'position_reviewed': r['Q1 position'], 'reach': r['Q3 class'],
                       'need': r['Q3 invariant / witness / need'], 'cite': r['cite'], 'note': r['Q1 note']}
                seeds.append([r['file'], r['definition(kernel owner)'], r['token'], loose(r['message/head']), int(r['line']), rev])
        else:
            for r in read_register(seed)[0]:
                seeds.append([r['file'], r['definition'], r['token'], loose(r['msg']), None, r])
    rows = []
    for s in sorted(sites, key=lambda s: (s['file'], s['line'], s['msg'])):
        lk = loose(s['msg'])
        same = [e for e in seeds if e[0] == s['file'] and e[1] == s['definition'] and e[2] == s['token']]
        exact = [e for e in same if e[3] == lk]
        prefix = [e for e in same if e[3] != lk and len(e[3]) >= 6 and (lk.startswith(e[3]) or e[3].startswith(lk))]
        prev = None
        for pool in (exact, prefix):
            if not pool: continue
            pool.sort(key=lambda e: (0 if e[4] in (s['line'], s['line'] - 1, None) else 1, -len(e[3])))
            prev = pool[0][5]; seeds.remove(pool[0]); break
        row = {c: s.get(c, '') for c in SEALED}
        if prev:
            row.update({c: prev.get(c, '') for c in ('position_reviewed', 'reach', 'need', 'cite', 'note')})
        else:
            row.update({'position_reviewed': 'UNREVIEWED', 'reach': 'UNREVIEWED',
                        'need': f'NEW SITE (line {s["line"]}): needs review', 'cite': '', 'note': ''})
        if s['discardable']: row['note'] = (row['note'] + ' ' if row['note'] else '') + f'DISCARDABLE (dead let {s["let_names"]})'
        for c in ('need', 'cite', 'note'): row[c] = row[c].replace('\t', ' ')
        row['seal'] = seal_of(row)
        rows.append(row)
    return HEADER + '# tally: ' + tally_line(rows) + '\n' + '\t'.join(COLS) + '\n' + ''.join('\t'.join(r[c] for c in COLS) + '\n' for r in rows)


def loose(msg):
    """the seeding join key: the message with `s!` interpolation markers, quote
    characters, parens and whitespace removed, first 40 chars (the census evidence
    TSV dropped the quote characters of every message and cut a shorter window)"""
    return re.sub(r'[\s"()!]', '', re.sub(r's!"', '"', msg))[:40]


def reseal(path):
    rows, _ = read_register(path)
    for r in rows: r['seal'] = seal_of(r)
    Path(path).write_text(HEADER + '# tally: ' + tally_line(rows) + '\n' + '\t'.join(COLS) + '\n'
                          + ''.join('\t'.join(r[c] for c in COLS) + '\n' for r in rows))
    print(f'check_failure_reach: resealed {len(rows)} rows of {path} (review change: commit with the justification)')


def check(root, census, register):
    rows, tally = read_register(register)
    bad = []
    # 1. row well-formedness
    for r in rows:
        if r['reach'] not in REACH: bad.append(f"reach class `{r['reach']}` not in {REACH}: {r['file']} {r['definition']} «{r['msg']}»")
        if r['position_reviewed'] == 'UNREVIEWED' or not r['position_reviewed']: bad.append(f"position_reviewed UNREVIEWED: {r['file']} {r['definition']} «{r['msg']}»")
        if r['scope'] not in ('EXEC', 'UNRESOLVED-OWNER'): bad.append(f"scope `{r['scope']}` unknown: {r['file']} {r['definition']}")
        if seal_of(r) != r['seal']: bad.append(f"SEAL MISMATCH (row edited without --reseal; a class change is a review change): {r['file']} {r['definition']} «{r['msg']}» position={r['position']} reviewed={r['position_reviewed']} reach={r['reach']}")
    if tally is None: bad.append('no `# tally:` line in the register')
    elif tally != tally_line(rows): bad.append(f'`# tally:` line does not equal the rows: register says `{tally}`, rows give `{tally_line(rows)}`')
    # 2. the site sets, as multisets on the key
    sites = live_sites(root, census)
    key = lambda r: (r['file'], r['definition'], r['token'], r['msg'], r['scope'])
    live_c, reg_c = Counter(key(s) for s in sites), Counter(key(r) for r in rows)
    for k, n in (live_c - reg_c).items():
        ex = [s for s in sites if key(s) == k]
        for s in ex[:n]:
            bad.append(f"NEW pure exec-closure site (no register row — review it): {s['file']}:{s['line']} {s['definition']} {s['token']} «{s['msg']}» position={s['position']} scope={s['scope']}")
    for k, n in (reg_c - live_c).items():
        bad.append(f"STALE register row (site gone or its key moved): {k[0]} {k[1]} {k[2]} «{k[3]}» scope={k[4]}" + (f' ×{n}' if n > 1 else ''))
    # 3. position classes (live vs row), matched on the key with multiplicity
    reg_by_key = {}
    for r in rows: reg_by_key.setdefault(key(r), []).append(r)
    for s in sites:
        # DISCARDABLE is reported for EVERY live site, registered or new
        if s['discardable']:
            bad.append(f"DISCARDABLE position (the F1 shape: a dead let-binding of a failure in a generated definition — the twin design's flip condition): {s['file']}:{s['line']} {s['definition']} «{s['msg']}» let {s['let_names']}")
        cands = reg_by_key.get(key(s), [])
        if not cands: continue
        if not any(c['position'] == s['position'] for c in cands):
            bad.append(f"POSITION CLASS CHANGED: {s['file']}:{s['line']} {s['definition']} «{s['msg']}» live={s['position']} register={'/'.join(sorted(set(c['position'] for c in cands)))}")
    n_dead = sum(1 for s in sites if s['discardable'])
    if bad:
        print('check_failure_reach: FAIL —')
        for b in bad: print('  ' + b)
        return 1
    c_reach = Counter(r['reach'] for r in rows); c_scope = Counter(r['scope'] for r in rows)
    print(f"check_failure_reach: OK ({len(sites)} pure failure sites = the {len(rows)} register rows exactly "
          f"({c_scope.get('EXEC', 0)} in the exec dependency closure + {c_scope.get('UNRESOLVED-OWNER', 0)} unresolved-owner; "
          f"key = file/owner/token/message, both directions); position classes unchanged; {n_dead} DISCARDABLE; "
          f"reach UNREACHABLE-BY-INVARIANT={c_reach.get('UNREACHABLE-BY-INVARIANT', 0)} REACHABLE={c_reach.get('REACHABLE', 0)} "
          f"UNKNOWN={c_reach.get('UNKNOWN', 0)}; every row sealed; tally line consistent)")
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--root', type=Path)
    ap.add_argument('--census', type=Path)
    ap.add_argument('--register', type=Path, default=DEFAULT_REGISTER)
    ap.add_argument('--emit', action='store_true')
    ap.add_argument('--seed', type=Path)
    ap.add_argument('--reseal', type=Path)
    a = ap.parse_args()
    if a.reseal:
        reseal(a.reseal); return 0
    if not a.root or not a.census:
        ap.error('--root and --census are required')
    census = json.loads(a.census.read_text())
    if a.emit:
        sys.stdout.write(emit(a.root.resolve(), census, a.seed)); return 0
    if not a.register.exists():
        raise SystemExit(f'check_failure_reach: FAIL — register missing: {a.register} (fail-closed)')
    return check(a.root.resolve(), census, a.register)


if __name__ == '__main__': sys.exit(main())
