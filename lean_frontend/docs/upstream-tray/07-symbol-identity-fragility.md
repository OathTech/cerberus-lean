# Question / for the record: symbol identity rests on an implicit global-counter invariant; equality never consults names

**Affected (for orientation):** `frontend/model/symbol.lem:132-146`
(`symbolEqual`), `:153-156` (`symbol_compare`); `util/cerb_fresh.ml`
(process-global counter, per-file digest, set at
`backend/common/pipeline.ml:181` and `:262`);
`parsers/core/core_parser.mly:184` (`register_sym`) and `:220`
(`register_label`) (checked against `master` @ `b9aeedcb4`).

**Status note, stated up front:** the failure we observed occurred in our
own re-implementation, which had (deliberately) changed one of the
minting streams; we have *not* observed a miscompare in unmodified
upstream Cerberus. This is therefore a design question plus a case study
of what happens when the implicit invariant breaks — drafted primarily
for the record, with filing optional.

## The invariant, as we reconstructed it

A symbol is `Symbol (digest, num, description)`. Both `symbolEqual` and
`symbol_compare` use only `digest` and `num`; the human-readable
description is ignored (there is a level-5 debug hook that warns on
"suspicious equality" — same digest+num, different descriptions —
`symbol.lem:137-141`, suggesting the aliasing risk is known).

Uniqueness of `num` therefore carries all of symbol identity within one
input file (every symbol minted while processing a given file shares
that file's digest, `Cerb_fresh.set_digest`). Uniqueness holds because
*every* minting site — the Core parser interning the standard library
(`core_parser.mly:184/:220`, one `Cerb_fresh.int()` each; on the order
of 490 draws for the current `std.core`), C desugaring, elaboration
temporaries, run-time fresh symbols — draws from the single process-
global counter in `util/cerb_fresh.ml`. That is sufficient, but it is
implicit: nothing documents or checks that all streams share the
counter, and correctness silently depends on the order in which the
stages happen to run.

## Case study: what breaks when one stream is renumbered

In our Lean port of the frontend we threaded a pure, 0-based symbol
supply through desugaring (to remove the global effect). Result: desugar
ids `[0, N)` overlapped the ambient ids that translation temporaries
draw after the std.core parse has advanced the shared counter (~490).
Because equality ignores descriptions, a translation temporary with the
same `num` as a desugared object symbol was *the same key* to the
evaluator's environment: a later `let`-binding of the temporary
clobbered the object's binding, and Core `Store`/`Load`/`Kill` actions
then saw loaded integers where pointers were expected
(`ACTION_ILLTYPED`), i.e. silent corruption surfacing far from the
cause. The fix was a large fixed base offset (2^20) for the ambient
stream, recreating upstream's disjointness with an explicit margin. The
same hazard applies to any embedder, port, or tool that constructs
symbols with small `num`s (e.g. `Symbol (_, 0, _)` placeholders) or
reuses marshalled symbols in a process whose counter state differs.

## Questions for upstream

1. Is the "all minting goes through `Cerb_fresh.int`" invariant recorded
   anywhere, and would a patch documenting it (in `symbol.lem` /
   `cerb_fresh.ml`) be welcome?
2. Would a cheap runtime check be acceptable — e.g. promoting the
   existing level-5 "suspicious equality" debug warning to an assertion
   (or a loud warning) under a switch? In our experience that exact
   check is what turns days of misbehaviour-at-a-distance into an
   immediate diagnosis.
3. Longer-term, would per-stream tagging (a stream id folded into the
   symbol, or fixed disjoint base offsets per minting site) be
   considered? Our port runs with a 2^20 base offset for the ambient
   stream, which is evidence the offset approach is workable and cheap.

## Impact

No known miscompare in unmodified upstream. The cost today is fragility:
the invariant is easy to break from outside (embedding, marshalled-state
reuse, refactoring a stage to a local supply), and when it breaks the
failure is silent aliasing with symptoms far downstream.

## Classification

**UNCLEAR — design hazard, framed as a question.** The current code
works as designed; we cannot tell from the code whether the implicit
disjointness invariant is considered part of the design contract. Not a
defect claim.

<!-- internal provenance:
  cerberus-lean/lean_frontend/docs/2026-08-19_arc4-s0-frontier.md
  ("Post-S3a frontier": root cause, the ~488 std.core offset, the
  duplicate nat-21 SD_None/SD_ObjectAddress dump, the 2^20 fix, and the
  "OCaml invariant itself is fragile" note; S5 addendum: current
  invariant + startup assertion + per-draw floor check in
  native/fresh_int.c); 2026-08-19_arc4-decision-log.md D6 ("one-line C
  fix mirroring the OCaml parser-offset invariant; fragility of the
  OCaml invariant itself recorded — upstream-reportable").
  Honesty check performed for this report: the 0-based desugar supply is
  OUR commit (cerberus-lean 8923d6436, "State-thread fresh symbol
  generation through desugM"); upstream desugaring draws from
  Symbol.fresh -> Cerb_fresh.int (single shared counter), so the observed
  collision does NOT reproduce on unmodified upstream — hence the
  question framing and the record-only default, which is narrower than
  the D6 "upstream-reportable" phrasing.
-->

---

## ADDENDUM (2026-08-22, arc-13 — the fork's own experience as evidence)

For-the-record update strengthening this report's thesis: the fork
LIVED the fragility this note describes. Its April-2026 desugar
supply threading violated the implicit global-counter invariant,
producing a declaration-layout-sensitive corruption family
(internal errors, spurious UB, silently wrong defined results —
fully characterized with deterministic reproducers in the fork's
tests/csmith_findings/; upstream itself was verified unaffected).
The fork's remediation arc restored the single-supply discipline
(re-converging byte-identically with upstream output) and added a
runtime window-check backstop (util/cerb_fresh.ml in the fork) that
turns any future invariant violation into a loud refusal — a
mechanism upstream may find worth adopting as cheap insurance for
exactly the fragility this report records. The suggested remedy
stands: symbol identity deserving of an explicit, checked invariant
rather than an implicit convention.
