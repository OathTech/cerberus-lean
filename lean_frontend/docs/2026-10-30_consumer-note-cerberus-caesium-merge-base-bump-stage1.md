# Consumer note for cerberus-caesium: the merge-base bump, stage 1 (2026-10-30)

From: the `arc/merge-base-bump` worker [AGENT]. Occasion: the Cerberus merge-base of this fork moved
from upstream `b9aeedcb4` (2026-08-13) to `c3ff8c53f` (2026-09-30), a true merge of 25 upstream commits
onto the fork (record `docs/2026-10-29_merge-base-bump-stage1-record.md`; scoping
`docs/2026-10-20_merge-base-bump-scoping-record.md`, whose §8 forecast this list). Stage 2 (to the
upstream tip) follows separately. Status: on branch `arc/merge-base-bump`; the landing is the
orchestrator's. What follows is what the next re-pin that includes the branch carries. The Lean
toolchain (4.35.0) and the lem-lean pin (`e6d8db5`) are unchanged.

## Signature changes at the entry points (upstream 334a1563b, the elaboration environment)

- `Cabs_to_ail.desugar` takes a `desug_config` after the fork's two parameters:
  `desugar sup top desug_conf core_eval_stuff cn_eval_stuff startup_str tunit` (was
  `desugar sup top core_eval_stuff …`). The fork's `Main.lean` builds `desugConf : desug_config`
  from the defaults; a consumer that calls `desugar` directly passes its own (the fields mirror
  `backend/common/pipeline.ml`'s at c3ff8c53f).
- `Translation.translate`'s calling-convention argument is now the `elab_config` record:
  `translate sup (names, stdlib) elab_conf impl prog` where `elab_conf : Translation_effect.elab_config`
  (`calling_convention1 : calling_convention`, `is_PNVI`, `is_CHERI`, `is_CN`, `strict_pointer_arith`,
  `branching_on_unspec : branching_on_unspec`). `Main.lean`'s `elabConf` is the mirror of the oracle's:
  `branching_on_unspec := .Elab_UB` (the switch `branching_on_unspec_is_nd` is REFUSED by `--switches`,
  record §0.12 Q9), the calling convention from the switch set. A consumer that passed
  `Normal_callconv` now passes `{ … with calling_convention1 := .Normal_callconv }`.
- `Translation_effect.elabM` is a function type `elab_config → elab_state → (α × elab_state)` with
  `elab_initial_state (seed)` and `runElabM_errors`; visible only to a consumer that runs
  elaboration pieces itself.

## AST constructors added (upstream c8c085d47, GNU labels as values)

`CabsElabel_addressGNU (label : identifier)` in `Cabs.cabs_expression_` and `AilElabel_addressGNU` in
`AilSyntax.expression_`. Exhaustive matches over either type (`AilToCaesium`'s, for one) gain an arm;
the fork's own walkers did (`Translation.compound_assign_lhs_has_side_effect`: no evaluation, no side
effect). `CabsImport.lean` decodes the JSON tag `CabsElabel_addressGNU` with the field `label`.

## Core text that re-quotes (every quoted Core AST)

- Branching on an unspecified value (upstream cee382443): the `Unspecified` arm of every `if`,
  `while`, `do` and `switch` test is `pure(undef(<<UB_CERB004_unspecified__if>>))` (`__while`,
  `__do`, `__switch`) where it was `nd(pure(True), pure(False))` (and `DUMMY(unspecified AilSdo)`,
  `UB036_exceptional_condition` for `do`/`switch`). Four new `Undefined.t` constructors
  `UB_CERB004_unspecified UB_unspec_if/while/do/switch`.
- `do … while (E)` (upstream 83b1a7424): the test is elaborated through `mkTestExpression` — the
  controlling expression becomes `E == 0` on a `loaded integer` and the loop re-runs on
  `not(case = 1)`; two more fresh symbols per loop, so every later `a_N` renumbers.
- `switch` (upstream cabe81c3b, 588672e95, ad233f84f): case labels are minted by
  `collect_switch_content_aux`; the controlling expression and the case expressions get the implicit
  conversions; empty GNU case ranges keep their body.
- The fork's quotation instrument re-quoted its own fixtures and the libc literal pins
  (`test/CoreQuote/core-quote-libc*.sha256`); the Core quotation visitor census is 641 constructors
  (was 638). Re-quote `CoreCaesium/Generated/*` with the branch's oracle (`--pp=core`).

## Memory interface

- `Mem.array_shift_ptrval` (upstream f4a3a3d54) returns `Undefined.t` — the fork's
  `CerbMem.arrayShiftPtrval [LemFuel] enumDefs tagDefs (loc) pv elemTy iv : t0 PointerValue`, which
  yields `.Undef loc [.UB046_array_pointer_outside]` on a null pointer where it panicked; `memcmp`
  takes a `loc` (`memcmpM`), as does `memcpy`'s lifting. A pure caller of the old total signature
  binds the result.
- `sizeof`/`alignof` left the memory interface (upstream b3e11ea33): `CerbMem.sizeofIval` and
  `CerbMem.alignofIval` are GONE; the layout block (`mkCtype`, `targetPtrSize`, the `_lemFuel`
  workers and their wrappers, `sizeof_ty`, `alignof_ty`, `offsetsof`, `memberAlign`) lives in
  `CerberusImpl` (namespace `CerberusImpl`), with the new carrier
  `CerberusImpl_lemMeasureProofs.lean` (a Lake root). `Implementation.sizeof_ty (enumDefs)
  (tagDefs reader) (tagDefs) (ty) : Int` and `alignof_ty` are the fuel-free reps over the measured
  wrappers; `Implementation.sizeof_ity` is unchanged.
- The `tagDefs` reader is still injected as before at stage 1 (its retirement is stage 2's
  `Config` work, scoping §3.2).

## Behaviour moved by the base (both engines, verified by the lanes — record §4)

- `NULL + 0` and every pure null-pointer shift: `UB046_array_pointer_outside` where both engines
  crashed (tray 04; `tests/minimal/097`, `tests/ci/0120`/`0121`).
- `_Alignas(2^62)` layouts: the oracle computes the unbounded answer Lean already gave (ISO-fix
  register R7 retired); `Cerb_floating.mul` multiplies (R6 retired; tray 01).
- Nothing else moved a verdict; the fork's refusals (D11 union initializers, D12 anonymous members,
  D13 compound assignment, inline asm) are unchanged.

## Errors and constraints

`Constraint`/`Errors` gained constructors with upstream's new diagnostics (e.g. the switch/case
constant checks of 97371d8ed, casts in constant expressions 0fc82e266, the file-scope GNU statement
expression 08e941f0e); a `stringOfDesugarCause` mirror adds arms.

## Stops

`CerbStopSites` entries whose source moved cite `c3ff8c53f` (the layout sites, via
`implSourceStage1`); every other site still cites `b9aeedcb4`, the revision it quotes.
