# Concurrency Phase 0 — S5 change manifest for the consumer (2026-09-05)

Addendum to the S1 manifest and the S3/S4 addenda (review Q5: staged
re-pin — this is the last content stage before S6's cumulative manifest).
Base: mainline `a910f097c`; S4 head `9b1b3ff6d`. Attachment:
`2026-09-05_concurrency-S5-generated-diff.patch`.

## 1. Signature changes (generated Lean)

- `Global.using_concurrency : Unit → Bool` — DELETED (Global.lean; and the
  hand-written `CerbGlobal.using_concurrency` opaque with its
  `implemented_by`). It had no caller since S1. If a statement of yours
  mentioned it, the replacement is the explicit `model` argument of
  `drive`/`step_ctx`.
- `CerbConcurrency` — module DELETED (`statically_satisfied` stub; no
  emitted Lean referenced it).
- Cmm_csem.lean: `apply_tree` and `apply_tree_fp_aux` are now plain
  `def`s (were `partial`) with the same signatures; NEW companions
  `apply_tree_list : List (String × named_predicate_tree) → … → Bool` and
  `apply_tree_fp_aux_list`, the branch-list walkers (mutual structural
  recursion — unfold freely; no fuel, no stability lemma needed).
  `apply_tree (Node l) X = apply_tree_list l X`;
  `apply_tree_list ((n, b) :: rest) X = (apply_tree b X && apply_tree_list rest X)`.
- Cmm_op.lean: the `axBehaviour` inline is no longer emitted for Lean
  (it never was referenced).
- No other generated signature changes; `drive`, `step_ctx`, the model
  type, the refusal/inconsistency types are as in S4.

## 2. What is unchanged for a sequential statement — now as theorems

`test/Unit/SCBridgeTest.lean` §SequentialIdentity (kernel-checked, builds
in the unit-test target):

```
add_to_sb_ctx_sequential   : add_to_sb_ctx   CM_sequential p_aids ctx = ctx
add_to_asw_ctx_sequential  : add_to_asw_ctx  CM_sequential aids   ctx = ctx
add_to_sb_stack_sequential : add_to_sb_stack CM_sequential p_aids st  = st
add_to_asw_stack_sequential: add_to_asw_stack CM_sequential aids  st  = st
add_to_sb_sequential       : add_to_sb  CM_sequential p_aids g = g     (the fuel'd walker, at its measure)
add_to_asw_sequential      : add_to_asw CM_sequential aids   g = g
```

Copy them or import the module; they are the facts a sequential theorem
needs to discharge the parameter.

## 3. Gate surface you may rely on

The totality slice now covers the Cmm modules (zero `partial` in Cmm_aux /
Cmm_csem / Cmm_op); the opaque census lost `using_concurrency`; the
`sorry`-token census stays at zero with 24 fewer `declare lean target_rep
… = sorry` lines in the source. DESIGN.md §4 has the model section your
SC-instance rules should cite (the DRF-SC premise, the value-at-issue
boundary).

## 4. Theorem targets (recorded, not proved — S5 record §4)

The agreement lemma (`epar_free f → drive … CM_sequential … = drive …
CM_sc …` on verdict sets), the bridge invariant as a lemma, and
`sc_fragment_ok_iff`. Yours to request in the shape your rules need.
