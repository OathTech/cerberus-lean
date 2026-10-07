#!/usr/bin/env python3
"""pnvi_lane.py — the classifier and baseline check of the PNVI-ae-udi differential
lane (scripts/test_pnvi.sh; PNVI arc S4, 2026-10-07; design record
lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §D.1, §D.2, §D.5;
record lean_frontend/docs/2026-10-07_pnvi-s4-lane-record.md).

TRUST SURFACE (classified per [USER 2026-10-07] "we don't want our gates to be
adversarially robust unless they are trust surfaces"): this lane is the validation
evidence for the PNVI_ae_udi mode, so it is fail-closed both directions and
plant-tested (test_pnvi.sh --selftest).

Input: a MANIFEST written by test_pnvi.sh, one row per line,
    <row-name>\t<mode>\t<oracle-prefix>\t<lean-prefix>\t<oracle-default-prefix or ->
where every prefix names an observation capture (<prefix>.stdout/.stderr/.status,
scripts/observations.sh observation_capture) and <mode> is `exhaustive` or `first`.

Each SIDE is decoded with the shared codec (scripts/observations.py) into one of
    OBS <tokens>        a complete batch observation (the codec's `batch` policy, `full`
                        projection: value, stdout, stderr, UB and its location)
    REFUSAL <id>        Lean only: exit 134 under LEAN_ABORT_ON_PANIC, LemLib's failure
                        leaf, message `PNVI_ae_udi refusal (unsupported upstream arm):
                        R-PNVI-nn: …` (CerbMem.pnviRefusal, the §H shape)
    CRASH <message>     an internal failure (oracle exit 125 uncaught exception / Lean
                        exit 134 PANIC) that is not a PNVI refusal (the codec's `litmus`
                        policy)
    CLI_REFUSAL <line>  Lean only: exit 2 `cerberus-lean: refused — …`
    RESOURCE <kind>     KILL (capped's OOM witness / exit 137), TIMEOUT (exit 124), FUEL
    INVALID <reason>    anything else (RED)

Row classes (the ONLY ones; anything else is DIFF):
    AGREE                       OBS on both sides, identical token SEQUENCES (exhaustive)
    AGREE-FIRST                 the same in `first` mode (oracle --mode=random one trace vs
                                Lean --first): outside CONTRACT §1 (§2: --first is not the
                                promise); used only where the oracle's trace set is too large
    REFUSAL <id> ORACLE_CRASH   Lean refuses with <id> where the oracle crashes with THE
                                upstream failure that <id> names (ORACLE_SIDE below) — a
                                registered refusal row, NEVER agreement, never "both crash"
    REFUSAL <id> ORACLE_VERDICT Lean refuses with <id> where the oracle runs through an arm
                                upstream itself flags (classes (A')/(B)/(C)/(D), §G) — a
                                registered refusal row, never agreement
    RESOURCE oracle:<kind>      the ORACLE exceeded the lane bound (direction rule,
                                VALIDATION §1(b): the converse — Lean failing where the
                                oracle completes — is a (b)-VIOLATION, i.e. DIFF)
    BOTH_FAIL                   both engines fail (CRASH/front-end Error) with no PNVI
                                refusal involved: class (a), never agreement
Every non-AGREE row must be in the committed baseline with the same class; the baseline
also pins a hash of the ORACLE side (its tokens / crash message / resource kind) and, for
rows with a default-mode oracle capture, whether the switch changed the oracle's answer
(`default=same|changed`). Both directions, fail-closed: a missing row, an extra row, a
changed class or hash, an empty selection, a DIFF or INVALID row is RED.
"""
from __future__ import annotations

import argparse
import hashlib
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import observations as obs  # noqa: E402

REFUSAL_PREFIX = 'PNVI_ae_udi refusal (unsupported upstream arm): '
REFUSAL_ID = re.compile(r'(R-PNVI-[0-9]{2}b?): ')
# The oracle side each refusal id pairs with (design §G.1, the refusal's own upstream arm).
# 'crash': the oracle must die with exactly this uncaught failure (the codec's decoded
# exception payload); 'verdict': the oracle runs through the flagged arm and answers.
ORACLE_SIDE = {
    'R-PNVI-01': ('crash', re.compile(r'Concrete\.combine_prov: found a Prov_symbolic')),
    'R-PNVI-01b': ('crash', re.compile(r'Concrete\.combine_prov: found a Prov_symbolic')),
    'R-PNVI-02': ('crash', re.compile(r'File "memory/concrete/impl_mem\.ml", line [0-9]+, characters [0-9]+-[0-9]+: Assertion failed')),
    'R-PNVI-04': ('crash', re.compile(r'Not_found')),
    'R-PNVI-06': ('crash', re.compile(r'Concrete\.array_shift_ptrval found a Prov_symbolic')),
    'R-PNVI-07': ('crash', re.compile(r'case_ptrval')),
    'R-PNVI-03': ('verdict', None),
    'R-PNVI-05': ('verdict', None),
    'R-PNVI-08': ('verdict', None),
    'R-PNVI-10': ('verdict', None),
}
ROW_CLASS = re.compile(r'^(AGREE|AGREE-FIRST|BOTH_FAIL|RESOURCE oracle:(KILL|TIMEOUT|FUEL)|'
                       r'REFUSAL R-PNVI-[0-9]{2}b? (ORACLE_CRASH|ORACLE_VERDICT))$')


def read(prefix: str, ext: str) -> bytes:
    return Path(prefix + ext).read_bytes()


def classify_side(prefix: str, lean: bool):
    if Path(prefix + '.capture-error').exists():
        return ('INVALID', 'capture not completed')
    try:
        stdout, stderr = read(prefix, '.stdout'), read(prefix, '.stderr')
        status = int(read(prefix, '.status').decode().strip())
    except (OSError, ValueError) as exc:
        return ('INVALID', f'unreadable capture: {exc}')
    if obs.CAP_OOM.search(stderr) or status == 137:
        return ('RESOURCE', 'KILL')
    if status == 124:
        return ('RESOURCE', 'TIMEOUT')
    if obs.FUEL_RECORD.search(stdout + b'\n' + stderr):
        return ('RESOURCE', 'FUEL')
    if lean and status == 2 and stderr.startswith('cerberus-lean: refused — '.encode()):
        return ('CLI_REFUSAL', stderr.split(b'\n')[0].decode('utf-8', 'replace')[:200])
    try:
        o = obs.parse(stdout, stderr, status, 'batch')
        return ('OBS', tuple(o.tokens('full')))
    except obs.ProtocolError as batch_exc:
        batch_reason = str(batch_exc)
    # the internal-failure decoders: Lean's PANIC under the `litmus` policy; the oracle's
    # bare uncaught-exception envelope (`cerberus: internal error, uncaught exception:` +
    # the Failure payload + its OCaml frames) is decoded by the `immaculate` policy only
    policy = 'litmus' if lean else 'immaculate'
    try:
        o = obs.parse(stdout, stderr, status, policy)
    except obs.ProtocolError as exc:
        return ('INVALID', f'batch: {batch_reason}; {policy}: {exc}')
    if o.internal:
        msg = o.verdicts[0].field('msg').decode('utf-8', 'replace')
        if lean and msg.startswith(REFUSAL_PREFIX):
            m = REFUSAL_ID.match(msg[len(REFUSAL_PREFIX):])
            if not m:
                return ('INVALID', 'PNVI refusal without an R-PNVI id: ' + msg[:160])
            return ('REFUSAL', m.group(1))
        return ('CRASH', msg)
    return ('INVALID', f'batch: {batch_reason}')


def is_fe_error(side) -> bool:
    """A single Error verdict (a front-end or driver failure reported as a verdict)."""
    return side[0] == 'OBS' and len(side[1]) == 1 and side[1][0].startswith('ERR:')


def classify_row(mode: str, o, l) -> tuple[str, str]:
    """(class, explanation). class 'DIFF' / 'INVALID' are always RED."""
    if o[0] == 'INVALID':
        return ('INVALID', 'oracle: ' + o[1])
    if l[0] == 'INVALID':
        return ('INVALID', 'lean: ' + l[1])
    if l[0] == 'CLI_REFUSAL':
        return ('DIFF', 'lean refused at the CLI: ' + l[1])
    if o[0] == 'RESOURCE':
        return (f'RESOURCE oracle:{o[1]}', f'lean side {l[0]}')
    if l[0] == 'RESOURCE':
        return ('DIFF', f'(b)-VIOLATION: lean {l[1]} where the oracle completed ({o[0]})')
    if o[0] == 'OBS' and l[0] == 'OBS':
        if o[1] == l[1]:
            return ('AGREE-FIRST' if mode == 'first' else 'AGREE', '')
        if is_fe_error(o) and is_fe_error(l):
            # both engines answer with ONE Error verdict whose text differs (e.g. the
            # ill-formed-program text embeds a symbol number, tray 17): VALIDATION §1(a)
            return ('BOTH_FAIL', 'both Error, text differs: ' + l[1][0][:120])
        return ('DIFF', 'observations differ')
    if l[0] == 'REFUSAL':
        rid = l[1]
        if rid not in ORACLE_SIDE:
            return ('DIFF', f'unregistered refusal id {rid}')
        kind, pat = ORACLE_SIDE[rid]
        if kind == 'crash':
            if o[0] == 'CRASH' and pat.search(o[1]):
                return (f'REFUSAL {rid} ORACLE_CRASH', o[1])
            return ('DIFF', f'{rid} must pair with the oracle crash /{pat.pattern}/; oracle: {o[0]} {str(o[1])[:120]}')
        if o[0] == 'OBS':
            return (f'REFUSAL {rid} ORACLE_VERDICT', '')
        return ('DIFF', f'{rid} must pair with an oracle verdict; oracle: {o[0]} {str(o[1])[:120]}')
    if (o[0] == 'CRASH' or is_fe_error(o)) and (l[0] == 'CRASH' or is_fe_error(l)):
        return ('BOTH_FAIL', f'oracle {o[0]} / lean {l[0]}')
    return ('DIFF', f'oracle {o[0]} vs lean {l[0]}')


def oracle_hash(o) -> str:
    if o[0] == 'OBS':
        text = '\n'.join(o[1])
    else:
        text = f'{o[0]}:{o[1]}'
    return hashlib.sha256(text.encode('utf-8', 'surrogateescape')).hexdigest()[:12]


def load_manifest(path: Path):
    rows = []
    for n, line in enumerate(path.read_text().splitlines(), 1):
        f = line.split('\t')
        if len(f) != 5 or f[1] not in ('exhaustive', 'first'):
            raise SystemExit(f'pnvi_lane: FAIL — malformed manifest line {n}: {line[:160]}')
        rows.append(f)
    return rows


def load_baseline(path: Path):
    if not path.is_file():
        raise SystemExit(f'pnvi_lane: FAIL — baseline missing: {path}')
    base = {}
    for n, line in enumerate(path.read_text().splitlines(), 1):
        if not line.strip() or line.startswith('#'):
            continue
        m = re.fullmatch(r'(\S+) (.+?) oracle=([0-9a-f]{12})(?: default=(same|changed))?', line)
        if not m:
            raise SystemExit(f'pnvi_lane: FAIL — malformed baseline line {n}: {line[:160]}')
        if not ROW_CLASS.match(m.group(2)):
            raise SystemExit(f'pnvi_lane: FAIL — baseline line {n}: unknown row class {m.group(2)!r}')
        if m.group(1) in base:
            raise SystemExit(f'pnvi_lane: FAIL — duplicate baseline row {m.group(1)}')
        base[m.group(1)] = (m.group(2), m.group(3), m.group(4))
    if not base:
        raise SystemExit(f'pnvi_lane: FAIL — empty baseline {path}')
    return base


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--manifest', required=True, type=Path)
    ap.add_argument('--baseline', required=True, type=Path)
    ap.add_argument('--select', default='', help='regex the run was restricted to (subset check)')
    ap.add_argument('--write-baseline', type=Path, help='write the observed rows (refused if any is RED)')
    args = ap.parse_args()
    rows = load_manifest(args.manifest)
    if not rows:
        print('pnvi_lane: FAIL — empty selection (no rows ran)')
        return 1
    observed = {}
    red = []
    counts = {}
    changed = {}
    for name, mode, op, lp, dp in rows:
        o, l = classify_side(op, False), classify_side(lp, True)
        cls, why = classify_row(mode, o, l)
        default = None
        if dp != '-':
            d = classify_side(dp, False)
            default = 'same' if (d[0] == o[0] and d[1] == o[1]) else 'changed'
            sect = name.split('/')[0]
            changed.setdefault(sect, [0, 0])[0 if default == 'same' else 1] += 1
        observed[name] = (cls, oracle_hash(o), default)
        key = cls.split(' ')[0] if cls.startswith(('REFUSAL', 'RESOURCE')) else cls
        counts[key] = counts.get(key, 0) + 1
        line = f'  {cls:<34} {name}' + (f'  [{why}]' if why and cls not in ('AGREE', 'AGREE-FIRST') else '') \
            + (f'  default={default}' if default else '')
        print(line)
        if cls in ('DIFF', 'INVALID'):
            red.append(f'{name}: {cls} — {why}')
            if o[0] == 'OBS' and l[0] == 'OBS':
                print(f'      O: {list(o[1])[:3]}')
                print(f'      L: {list(l[1])[:3]}')
    if args.write_baseline:
        if red:
            print('pnvi_lane: REFUSED to write a baseline over RED rows:')
            for r in red:
                print('  ' + r)
            return 1
        with args.write_baseline.open('w') as f:
            for name in sorted(observed):
                cls, h, default = observed[name]
                f.write(f'{name} {cls} oracle={h}' + (f' default={default}' if default else '') + '\n')
        print(f'pnvi_lane: wrote {len(observed)} rows to {args.write_baseline} (header must be re-added by test_pnvi.sh)')
        return 0
    base = load_baseline(args.baseline)
    sel = re.compile(args.select) if args.select else None
    expected = {k: v for k, v in base.items() if sel is None or sel.search(k)}
    if not expected:
        print(f'pnvi_lane: FAIL — the selection {args.select!r} matches no baseline row')
        return 1
    for name in sorted(set(expected) - set(observed)):
        red.append(f'{name}: baseline row not run (missing)')
    for name in sorted(set(observed) - set(expected)):
        red.append(f'{name}: row ran but is not in the baseline (unclassified)')
    for name in sorted(set(observed) & set(expected)):
        cls, h, default = observed[name]
        bcls, bh, bdefault = expected[name]
        if cls != bcls:
            red.append(f'{name}: class {cls} != baseline {bcls}')
        if h != bh:
            red.append(f'{name}: oracle-side hash {h} != baseline {bh} (the oracle\'s answer moved)')
        if default != bdefault:
            red.append(f'{name}: default-mode comparison {default} != baseline {bdefault}')
    tally = ' '.join(f'{k}={v}' for k, v in sorted(counts.items()))
    undisturbed = ' '.join(f'{s}:same={v[0]},changed={v[1]}' for s, v in sorted(changed.items()))
    print(f'SUMMARY: rows={len(observed)} {tally}' + (f' | switch vs default (oracle): {undisturbed}' if undisturbed else ''))
    if red:
        print(f'pnvi_lane: FAIL — {len(red)} RED item(s):')
        for r in red:
            print('  ' + r)
        return 1
    print(f'pnvi_lane: BASELINE OK ({len(observed)} rows = the baseline' + (f' rows matching {args.select!r}' if sel else '') + ', classes and oracle hashes exact)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
