#!/usr/bin/env python3
"""check_renumber_only.py — the C1-F1 rebaseline property check.

Adjudication basis (C1-F1 resolution, [USER 2026-09-01] via the
orchestrator; lean_frontend/docs/2026-09-01_C1-adoption-record.md §5):
a moved pinned oracle artifact is admitted to the effect-retirement
rebaseline ONLY on demonstrated

  (1) SAME-DRAW-COUNT: the two artifacts contain the same number of
      distinct numeric symbol ids; and
  (2) PERMUTATION-ONLY equivalence: after canonicalizing every numeric
      symbol id to its first-occurrence rank (per file), the two
      artifacts are byte-identical.

(2) implies the artifacts are the SAME TERM up to a bijective renaming
of symbol ids applied consistently at every occurrence — in
particular, definition/section EMISSION ORDER and all non-symbol text
are required byte-equal (this doubles as the gate-item-(a) dump-order
check: a PASS proves no order-sensitive output moved beyond binding
identity). Anything else — a draw-count change, a structural edit, a
reordered section — FAILS, remains a FINDING, and is a stop condition.

Symbol-token shape: the oracle's pretty-printers render symbols as
<prefix>_<digits> (a_517, while_518, ret_512, case_1024, ...). The
regex below rewrites exactly those trailing-numeric tokens; numeric
literals not attached to an identifier are left alone and any
mismatch routed through them fails closed (over-strictness is safe:
this gate only ever ADMITS, never excuses).

Usage:
  check_renumber_only.py OLD NEW [--label NAME]
  exit 0: ADMIT (prints the evidence row)
  exit 1: FINDING (count mismatch or non-permutation delta)

Evidence row (machine-consumable, quoted verbatim in rebaseline
commits):
  RENUMBER-ONLY ADMIT <label> class=<STRICT|LAYOUT> ids=<n> moved=<m> canon=<sha256[:12]>
where moved = ids whose value changed under the bijection.

Admission classes (both are permutation-only; the class is reported so
reviewers see which rows re-wrapped):
  STRICT — canonical texts byte-identical (layout untouched);
  LAYOUT — canonical texts identical after whitespace normalization
           (s/\\s+/ /g). The oracle pretty-printer breaks lines by
           WIDTH, so a renamed id with a different digit count moves
           wrap points; the token sequence — content, structure, and
           emission order — is still required identical, so section
           reordering and any token change keep failing (plant-tested).
"""

import argparse
import hashlib
import re
import sys

SYM = re.compile(r"\b([A-Za-z][A-Za-z0-9_]*_)(\d+)\b")


def canonicalize(text: str):
    """Replace each distinct trailing-numeric id by its first-occurrence
    rank; return (canonical text, mapping id->rank in first-use order)."""
    mapping = {}

    def repl(m):
        ident = m.group(2)
        if ident not in mapping:
            mapping[ident] = len(mapping)
        return f"{m.group(1)}%{mapping[ident]}%"

    return SYM.sub(repl, text), mapping


def first_divergence(a: str, b: str):
    la, lb = a.splitlines(), b.splitlines()
    for i, (x, y) in enumerate(zip(la, lb), 1):
        if x != y:
            return i, x, y
    if len(la) != len(lb):
        return min(len(la), len(lb)) + 1, "<EOF at differing line counts>", ""
    return None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("old")
    ap.add_argument("new")
    ap.add_argument("--label", default=None)
    args = ap.parse_args()
    label = args.label or args.new

    try:
        old = open(args.old, encoding="utf-8", errors="strict").read()
        new = open(args.new, encoding="utf-8", errors="strict").read()
    except OSError as e:
        print(f"RENUMBER-ONLY ERROR {label}: {e}", file=sys.stderr)
        return 1

    canon_old, map_old = canonicalize(old)
    canon_new, map_new = canonicalize(new)

    if len(map_old) != len(map_new):
        print(
            f"RENUMBER-ONLY FINDING {label}: DRAW-COUNT MISMATCH "
            f"(old distinct ids={len(map_old)}, new={len(map_new)}) — stop condition",
            file=sys.stderr,
        )
        return 1
    cls = "STRICT"
    if canon_old != canon_new:
        # renaming-induced re-wrap: compare with whitespace normalized
        ws_old = re.sub(r"\s+", " ", canon_old)
        ws_new = re.sub(r"\s+", " ", canon_new)
        if ws_old != ws_new:
            div = first_divergence(canon_old, canon_new)
            where = f"first divergence at canonical line {div[0]}:\n  old: {div[1][:160]}\n  new: {div[2][:160]}" if div else "(?)"
            print(
                f"RENUMBER-ONLY FINDING {label}: NON-PERMUTATION DELTA — stop condition\n  {where}",
                file=sys.stderr,
            )
            return 1
        cls = "LAYOUT"
        canon_old = ws_old  # digest over the form that proved equal

    # the induced bijection: k-th first-use id in old <-> k-th in new
    inv_new = {rank: ident for ident, rank in map_new.items()}
    moved = sum(1 for ident, rank in map_old.items() if inv_new[rank] != ident)
    digest = hashlib.sha256(canon_old.encode()).hexdigest()[:12]
    print(f"RENUMBER-ONLY ADMIT {label} class={cls} ids={len(map_old)} moved={moved} canon={digest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
