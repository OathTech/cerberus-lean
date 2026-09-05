# Concurrency Phase 0 — S4 change manifest for the consumer (2026-09-05)

Addendum to `2026-09-04_concurrency-S1-change-manifest.md` and the S3
addendum (review Q5: staged re-pin — this is the second part of the "rest
of Phase 0" stage; S5 follows). Base: mainline `a910f097c`; S3 head
`5e4552f40`. Attachment: `2026-09-05_concurrency-S4-generated-diff.patch`.

## 1. Signature changes (generated Lean)

- `action_request2` gains ONE constructor (Core_reduction.lean):
  `CompareExchangeRequest2 : Bool → ctype → pointer_value → pointer_value
  → mem_value → memory_order → memory_order → (List aid → footprint →
  footprint → Bool → α) → action_request2 α` — strong-flag, the (unatomic)
  lvalue type of the object, object pointer, expected pointer, desired
  value, success order, failure order, continuation (the ids of the actions
  the request produced, the two footprints, the C `_Bool` result). Every
  exhaustive `match` on `action_request2` gains an arm.
- NEW generated definitions (Driver.lean): `cmpxchg_values_equal`,
  `perform_compare_exchange`; (Core_reduction.lean): `wrap_tagged_many`,
  `compare_exchange_action` (local to `step_action`'s arms — the two
  `CompareExchange{Strong,Weak}` arms replaced their `failwithI "TODO
  [Core_reduction]…"` bodies).
- `add_to_sb_ctx`'s `Cunseq` arm (Core_run_aux.lean) now maps `add_to_sb`
  over both sibling lists (S4 record §1). Signature unchanged.
- No change to `core_step2`, `step_ctx`, `drive`, the model type, the
  refusal/inconsistency types, or any measure obligation.

## 2. What is unchanged for a sequential statement

Under `CM_sequential` every walker is still the identity by its first
`match model`; `perform_action_request2`'s `CM_sequential` arm gains the
`CompareExchangeRequest2` case (perform, no recording). The FULL battery is
at zero movement (S4 record §3): no sequential lane program uses
`atomic_compare_exchange_*` (they were internal errors before S4 on both
engines; any such row would have been a matched `TODO` verdict).

## 3. New outcome arms

- `CompareExchange*` on a NON-integer object: `kill (Other (DErr_other
  "compare_exchange on a non-integer object (Phase 0: integers only)"))`
  on both models. On an unspecified object/expected value:
  `kill (Undef0 … [UB_unspecified_lvalue])`.
- The WEAK form: an `ND.msum`/nd-branch at equal values (success / spurious
  failure); exhaustive mode yields both.
- CM_sc recording per request (Driver.lean `action_request_sc2`): a
  non-atomic `Load` (expected) — then `RMW` (success) or `Load mo_fail` +
  non-atomic `Store` (expected). ONE scheduling point per request: the
  request is atomic w.r.t. other threads by construction.

## 4. Theorem-facing facts

- Within a request, the recorded actions are sb-chained in recording
  order and the continuation is sb-after ALL of them (`wrap_tagged_many`).
- `well_formed_threads`' `indeterminate_sequencing` conjunct forced the
  S4 change to unseq-sibling tagging: the SC-instance rule for your side is
  "sb = the interpreter's execution order within a thread" (a linear order
  per thread, hence the C11 indeterminate-sequencing choice made
  explicit). For your sequential statements nothing changes.
