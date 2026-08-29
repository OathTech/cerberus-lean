# `--pp core` output is ambiguous: `if` operands and `;`-sequences re-parse to a different tree

**Affected:** `ocaml_frontend/pprinters/pp_core.ml:69-97` (`precedence_pexpr`),
`:161-164` (`compare_precedence`), `:648-649` (`Esseq` unit-pattern print)
(checked against `master` @ `b9aeedcb4`; file unchanged there).

Unlike the companion report on rejected forms, these two classes produce
text that a grammar-faithful parser accepts — as a *different* program.

## 1. `PEif` is never parenthesised

`precedence_pexpr` returns `None` for `PEif` (pp_core.ml:69-97), and
`compare_precedence` treats `None` as "no parentheses needed" in every
position (:161-164). So an `if` printed as a binary-operator operand gets
no delimiters. The elaborator generates exactly this shape routinely: the
integer-promotion wrapper

```
if all_values_representable_in(...) then conv_int(...) else conv_int(...)
```

appears as an operand and as the leading atom of another `if` condition
(the elaboration of the shipped C library contains 39 `if if` token
sequences). On re-parse, a greedy `if` swallows the rest of the
surrounding expression into its `else` branch.

## 2. `;`-sequences are delimited only by layout

`Esseq` with a unit pattern prints as `e1 ; <hardline> e2` with no
brackets (pp_core.ml:648-649). Nested under an `if`, e.g.

```
if c then
  ...
else
  pure(Unit) ;
rest
```

the only signal that `rest` belongs to the enclosing sequence rather
than the `else` branch is indentation, which the grammar does not
consume. A C `if` without `else` elaborates to exactly this shape, so it
is pervasive. A grammar-faithful parser attaches `rest` to the `else`
branch — silently.

## Observed vs expected

- Observed: re-parsing `--pp core` output yields a well-formed Core
  program with different association (mis-nested `if` branches /
  sequence tails); no error is reported.
- Expected: printed text determines the AST (or the printer refuses to
  print ambiguously).

## Impact

Any tool that consumes `--pp core` text (differential testing, external
analyses, round-trip checks) can silently operate on the wrong AST. We
hit both classes in practice: the mis-nested `else` branch surfaced only
when the re-parsed Core was *executed* and a value escaped through the
wrong branch — parse-success testing cannot detect this class at all.

## Proposed remedy

Rules that resolved both classes in our re-implementation, translated
back to the printer (making the *printer* unambiguous is the smaller
change than making the parser layout-sensitive):

1. Parenthesise `PEif` (and for the same reason `PElet`/`PEcase`, which
   share the `None` precedence) whenever it occurs as an operand of an
   operator or as the leading atom of another `if`'s condition — i.e.
   give these constructs a precedence level instead of `None`, so
   `compare_precedence` wraps them in operand position.
2. Parenthesise (or explicitly bracket) a branch body that contains a
   top-level `;`-sequence, so sequence extent no longer depends on
   indentation.

Alternatively (or additionally): an explicit fully-parenthesised pp mode
for machine consumption. (For reference, our parser resolves class 2 by
mirroring the printer's layout — a `;`-sequel is consumed only if its
first token's column is at or left of the sequence's own column — which
works but bakes the pretty-printer's indentation discipline into the
grammar; emitting unambiguous text seems preferable.)

## Classification

**TRUE BUG** conditional on the same intent question as the companion
report: if `--pp core` output is meant to be machine-consumable, silent
misassociation is a correctness defect (and nastier than the rejected
forms, because nothing fails). If the printer is intended for human
consumption only, this is a documentation gap — we could not determine
that intent from the code, and note the parser does accept most printed
output, which suggests round-tripping is expected to work.

<!-- internal provenance:
  worktrees/cerberus-lean-arc/libc-load/lean_frontend/docs/
  2026-08-19_arc6-s1-libc-load.md ("Two reparse-ambiguity classes fixed":
  PEif-as-operand rule, layout-sensitive `;` rule, both unit-tested; the
  libc fwrite path exposed class 2 as a "PEcase, mismatched ==> Unit"
  panic from the mis-nested value). Arc-6 decision log D10 records the
  parse-success-only blind spot of test_core.sh.
-->
