# Concurrency Phase 0 — S3 change manifest for the consumer (2026-09-05)

Addendum to `2026-09-04_concurrency-S1-change-manifest.md` (review Q5:
staged re-pin — this is the "rest of Phase 0" stage's first part; S4/S5
follow). Base for this slice: mainline `a910f097c` (fuel arc C2).

## 1. Signature changes (generated Lean)

- `core_step2.Step_action_request2` : 5 → 7 components —
  `String → Loc → thread_id → Bool → polarity → core_run_annotation →
  core_runM (action_request2 thread_state)` (Core_reduction.lean). Every
  `match` on `core_step2` gains two binders in that arm (our
  `CerbStepInstances.lean` did; your `Round.lean` classification will).
- `step_ctx` : first explicit argument is now the model —
  `step_ctx tds model mem_st file core_extern tid (parent, th_st)`
  (Core_reduction.lean). Our exemplar's `loop_step_done` hypothesis
  `hsteps : @step_ctx ⟨_⟩ tds CM_sequential …` is the one-token rewrite.
- `Core_run.kill_thread` unchanged in signature; its body annotates the
  parent's arena (asw) as well as the stack.
- `driver_error.DErr_model_inconsistent`'s payload type gains
  `MI_sc_inconsistent (leaf : String)` (Driver.lean).
- NEW generated definitions (Driver.lean): `lk_of_ctype`,
  `sc_tag_thread_state`, `sc_record_action`, `action_request_sc2`,
  `sc_failing_leaves`/`sc_failing_leaves_list` (mutual, structural, plain
  `def`s), `sc_candidate_execution`. NEW (Core_run_aux.lean):
  `add_to_sb_ctx`, `add_to_asw_ctx` (structural on `context`, plain `def`s).
- `add_to_sb`/`add_to_asw` (fuel'd, measure `lemSize g`) gained arms; the
  C2 obligations `add_to_sb_measure_sufficient`/`add_to_asw_measure_
  sufficient` are re-proved with the model binder (Core_run_aux_
  lemMeasureProofs.lean).

## 2. What is unchanged for a sequential statement

Under `CM_sequential`: `wrap_tagged` (the sb hook) is the identity on the
context and the stack (both walkers return their argument by the first
`match model`); `kill_thread`'s asw annotation is the identity; the
`Eproc` entry's sb/asw annotation is the identity; `perform_action_request2`'s
`CM_sequential` arm is textually the historical one. The FULL battery is
at zero movement (S3 record §3). The only statement-visible change for you
is the two extra binders in a `Step_action_request2` match and the
`step_ctx` argument.

## 3. New outcome arms (CM_sc only)

- `drive … CM_sc …` tail: `if ¬(setIsEmpty (data_races ex)) then
  kill (Undef0 (Loc.other "concurrency (SC instance): data race")
  [UB005_data_race]) else match sc_failing_leaves … with leaf :: _ => kill
  (Other (DErr_model_inconsistent (MI_sc_inconsistent leaf))) | [] =>
  return (finalize "drive (sc)" dr_st')` (driver.lem, the drive tail).
- `action_request_sc2`'s arms end in `sc_record_action …` (an `ND.update`)
  after the historical effects; no new kill arms.

## 4. Theorem-facing facts

- The bridge invariant (every race-free CM_sc trace's candidate execution
  satisfies `sc_accesses_consistent_execution`) is checked at RUNTIME per
  trace; it is not yet a theorem. It is the natural statement for the
  agreement/adequacy work of S5 and for your SC-instance rules.
- `data_races` is the library's predicate over `hb` from
  `release_acquire_fenced_relations` (the SC model's own relation
  calculator, cmm_csem.lem `sc_accesses_memory_model`).
- The recorded non-parametric point stands (read values at issue).
