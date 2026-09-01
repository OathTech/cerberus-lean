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

SYNTAX-AWARE CANONICALIZATION (C2 hardening, closing the C1 audit's
minor-1 admitted-corner holes; route chosen [AGENT]: string-aware +
comment-aware canonicalization rather than refuse-preconditions —
detecting the precondition needs the same lexer anyway, and the lexer
route keeps legitimately-renumbered artifacts adjudicable while
STRICTLY TIGHTENING both legs; over-strictness is safe, this gate
only ever ADMITS, never excuses). The input is lexed into CODE /
STRING-LITERAL / `--`-LINE-COMMENT segments (double-quoted strings
with backslash escapes, possibly spanning newlines; both the Core
pretty-printer's dump syntax and the SpecLab .lean re-emissions use
`--` line comments and double-quoted strings):

  * STRING LITERALS are compared VERBATIM — never id-canonicalized,
    never whitespace-normalized. A string-content change that is
    shaped like a renumbering (the s5 hole) or a whitespace change
    inside a string (the l1 hole) now FAILS on both legs.
  * COMMENTS are id-canonicalized like code (renumbering cited in a
    comment is still renumbering) but are ATOMIC tokens on the LAYOUT
    leg: whitespace collapses only WITHIN a comment, never across its
    terminating newline, so a line-break change can never move text
    into or out of a comment (the l3/l4 holes).
  * FAIL-CLOSED preconditions: an unterminated string literal refuses
    the pair loudly (exit 1) rather than guessing.
  * LINE ENDINGS are read RAW (newline='' — C2 audit minor-3): a CRLF
    rewrite inside a string literal REFUSES (verbatim contract); a
    pure code/comment-side CRLF rewrite is a whitespace-only change
    and admits as class=LAYOUT, never STRICT (ruling [AGENT], stated
    at the open() call; plant-tested both directions).

Symbol-token shape: the oracle's pretty-printers render symbols as
<prefix>_<digits> (a_517, while_518, ret_512, case_1024, ...). The
regex below rewrites exactly those trailing-numeric tokens in code and
comment segments; numeric literals not attached to an identifier are
left alone and any mismatch routed through them fails closed.

Usage:
  check_renumber_only.py OLD NEW [--label NAME]
  exit 0: ADMIT (prints the evidence row)
  exit 1: FINDING (count mismatch, non-permutation delta, string
          delta, comment-boundary delta, or a refused input)

Evidence row (machine-consumable, quoted verbatim in rebaseline
commits):
  RENUMBER-ONLY ADMIT <label> class=<STRICT|LAYOUT> ids=<n> moved=<m> canon=<sha256[:12]>
where moved = ids whose value changed under the bijection.

Admission classes (both are permutation-only; the class is reported so
reviewers see which rows re-wrapped):
  STRICT — canonical texts byte-identical (layout untouched);
  LAYOUT — canonical texts identical as SEGMENTED TOKEN STREAMS with
           code/comment-internal whitespace collapsed (the oracle
           pretty-printer breaks lines by WIDTH, so a renamed id with
           a different digit count moves wrap points). String content,
           comment extents, the token sequence, and emission order are
           required identical; section reordering, any token change,
           any string delta, and any comment-boundary movement fail
           (plant-tested: tests/renumber_plants/ +
           scripts/test_renumber_plants.sh).
"""

import argparse
import hashlib
import re
import sys

SYM = re.compile(r"\b([A-Za-z][A-Za-z0-9_]*_)(\d+)\b")


def lex(text: str, label: str):
    """Split text into segments [(kind, content)], kind in
    {'code', 'str', 'comment'}. Strings keep their quotes and escapes
    verbatim; comments run from `--` to (not including) the newline.
    Fail-closed: unterminated string refuses the input."""
    segs = []
    cur = []
    i, n = 0, len(text)

    def flush():
        if cur:
            segs.append(("code", "".join(cur)))
            cur.clear()

    while i < n:
        c = text[i]
        if c == '"':
            flush()
            j = i + 1
            while j < n:
                if text[j] == "\\":
                    j += 2
                    continue
                if text[j] == '"':
                    break
                j += 1
            if j >= n:
                print(
                    f"RENUMBER-ONLY REFUSED {label}: unterminated string "
                    f"literal at offset {i} (fail-closed precondition)",
                    file=sys.stderr,
                )
                sys.exit(1)
            segs.append(("str", text[i : j + 1]))
            i = j + 1
            continue
        if c == "-" and text[i : i + 2] == "--":
            flush()
            j = text.find("\n", i)
            j = n if j == -1 else j
            segs.append(("comment", text[i:j]))
            i = j  # the newline (if any) stays with the following code
            continue
        cur.append(c)
        i += 1
    flush()
    return segs


def canonicalize(text: str, label: str):
    """Lex, then replace each distinct trailing-numeric id in CODE and
    COMMENT segments by its first-occurrence rank; strings verbatim.
    Returns (segments-after-canonicalization, mapping id->rank)."""
    mapping = {}

    def repl(m):
        ident = m.group(2)
        if ident not in mapping:
            mapping[ident] = len(mapping)
        return f"{m.group(1)}%{mapping[ident]}%"

    out = []
    for kind, content in lex(text, label):
        if kind == "str":
            out.append((kind, content))
        else:
            out.append((kind, SYM.sub(repl, content)))
    return out, mapping


def flat(segs):
    return "".join(content for _, content in segs)


def layout_stream(segs):
    """The LAYOUT-leg comparison form: code splits into whitespace-
    separated words; a comment is ONE token with internal whitespace
    collapsed (its boundary is part of the token identity); a string
    is one verbatim token."""
    stream = []
    for kind, content in segs:
        if kind == "code":
            stream.extend(("w", w) for w in content.split())
        elif kind == "comment":
            # inner whitespace collapses AND boundary whitespace strips:
            # a \r sitting before the comment-terminating \n (CRLF
            # input) is layout, not comment content
            stream.append(("c", re.sub(r"\s+", " ", content).strip()))
        else:
            stream.append(("s", content))
    return stream


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
        # newline='' (C2 audit minor-3): Python's universal-newline
        # default silently translated \r\n -> \n on read, so a full
        # CRLF rewrite — INCLUDING inside string literals — admitted
        # as STRICT, contradicting the strings-verbatim contract. With
        # raw newlines: CR inside a STRING differs verbatim -> REFUSE;
        # CR in code/comments is whitespace -> a pure code-side CRLF
        # rewrite admits as class=LAYOUT (ruled [AGENT]: it IS a
        # whitespace-only layout change — tokens, strings, comment
        # extents and emission order all still required identical, and
        # the LAYOUT class in the evidence row surfaces it for review).
        old = open(args.old, encoding="utf-8", errors="strict", newline="").read()
        new = open(args.new, encoding="utf-8", errors="strict", newline="").read()
    except OSError as e:
        print(f"RENUMBER-ONLY ERROR {label}: {e}", file=sys.stderr)
        return 1

    segs_old, map_old = canonicalize(old, label)
    segs_new, map_new = canonicalize(new, label)

    if len(map_old) != len(map_new):
        print(
            f"RENUMBER-ONLY FINDING {label}: DRAW-COUNT MISMATCH "
            f"(old distinct ids={len(map_old)}, new={len(map_new)}) — stop condition",
            file=sys.stderr,
        )
        return 1

    canon_old, canon_new = flat(segs_old), flat(segs_new)
    cls = "STRICT"
    if canon_old != canon_new:
        # renaming-induced re-wrap: compare the segmented token streams
        # (code words / atomic ws-collapsed comments / verbatim strings)
        st_old, st_new = layout_stream(segs_old), layout_stream(segs_new)
        if st_old != st_new:
            div = None
            for k, (x, y) in enumerate(zip(st_old, st_new)):
                if x != y:
                    div = f"first token divergence at index {k}:\n  old: {x[0]}:{x[1][:160]}\n  new: {y[0]}:{y[1][:160]}"
                    break
            if div is None:
                div = f"token-stream length differs (old={len(st_old)}, new={len(st_new)})"
            ld = first_divergence(canon_old, canon_new)
            where = (
                f"{div}\n  canonical line {ld[0]}:\n  old: {ld[1][:160]}\n  new: {ld[2][:160]}"
                if ld
                else div
            )
            print(
                f"RENUMBER-ONLY FINDING {label}: NON-PERMUTATION DELTA — stop condition\n  {where}",
                file=sys.stderr,
            )
            return 1
        cls = "LAYOUT"
        # digest over the form that proved equal
        canon_old = "\x00".join(f"{k}\x01{v}" for k, v in st_old)

    # the induced bijection: k-th first-use id in old <-> k-th in new
    inv_new = {rank: ident for ident, rank in map_new.items()}
    moved = sum(1 for ident, rank in map_old.items() if inv_new[rank] != ident)
    digest = hashlib.sha256(canon_old.encode()).hexdigest()[:12]
    print(f"RENUMBER-ONLY ADMIT {label} class={cls} ids={len(map_old)} moved={moved} canon={digest}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
