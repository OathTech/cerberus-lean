#!/usr/bin/env python3
"""Alpha-canonicalize generated identifiers for id-insensitive diffing
(arc-2 S4; ruling 2026-08-18, design note §12).

Rewrites symbol ids (`<name>_<num>`, e.g. `a_1064`) and bare thread-id
fields (`tid=<num>`) to first-occurrence ordinals, so two traces/goldens
that differ only in id SEQUENCES compare equal, while structural
differences (different id count, ids used in different positions) still
show. Apply to BOTH sides of a diff:

    canonicalize_ids.py < left.txt  > left.canon
    canonicalize_ids.py < right.txt > right.canon
    diff left.canon right.canon

Self-test: `canonicalize_ids.py --self-test`.
"""
import re
import sys

SYM = re.compile(r'\b([A-Za-z][A-Za-z0-9]*)_(\d+)\b')
TID = re.compile(r'\btid=(\d+)\b')


def canonicalize(text: str) -> str:
    sym_map: dict[str, int] = {}
    tid_map: dict[str, int] = {}

    def sub_sym(m: re.Match) -> str:
        key = m.group(2)
        if key not in sym_map:
            sym_map[key] = len(sym_map)
        return f"{m.group(1)}_{sym_map[key]}"

    def sub_tid(m: re.Match) -> str:
        key = m.group(1)
        if key not in tid_map:
            tid_map[key] = len(tid_map)
        return f"tid={tid_map[key]}"

    return TID.sub(sub_tid, SYM.sub(sub_sym, text))


def self_test() -> None:
    # Sequence-offset traces canonicalize equal...
    a = "load a_107 into x_108; spawn tid=3; use a_107"
    b = "load a_55 into x_59; spawn tid=1; use a_55"
    assert canonicalize(a) == canonicalize(b), (canonicalize(a), canonicalize(b))
    # ...but structural differences still differ: c reuses one id where
    # a uses two distinct ids.
    c = "load a_55 into x_55; spawn tid=1; use a_55"
    assert canonicalize(a) != canonicalize(c)
    # Same-numeral ids share one canonical assignment across prefixes
    # (a symbol's id is the number; the prefix is display only).
    d = canonicalize("a_9 b_9 a_9")
    assert d == "a_0 b_0 a_0", d
    print("canonicalize_ids: self-test OK")


if __name__ == "__main__":
    if "--self-test" in sys.argv:
        self_test()
    else:
        sys.stdout.write(canonicalize(sys.stdin.read()))
