# Concurrency Phase 0 — cumulative change manifest for the consumer (2026-09-05)

The one document to read at re-pin time. It supersedes nothing: the
per-slice manifests (S1 `2026-09-04_concurrency-S1-change-manifest.md`,
S3/S4/S5 `2026-09-05_concurrency-S{3,4,5}-change-manifest.md`) and their
generated-diff attachments stay the detailed record; this page is the sum.
Range: mainline `928aa1e76` (fuel-parameter C3) → `feature/concurrency`
head (the rebased S0–S5 commits). Charter:
`2026-09-04_concurrency-phase0-sc-charter.md`; consumer note (charter §8):
`2026-09-05_concurrency-phase0-consumer-note.md`.

## 1. Statement-text changes (what a production statement must edit)

| Was | Is | Where | Note |
|---|---|---|---|
| `drive tds false file args` | `drive tds CM_sequential file args` | Driver.lean | the ONE token per statement (review Q1/Q5); `concurrency_model = CM_sequential \| CM_sc` (Core_run_aux.lean) |
| `step_ctx tds mem_st file core_extern tid (parent, th_st)` | `step_ctx tds model mem_st file core_extern tid (parent, th_st)` | Core_reduction.lean | S3 |
| `Step_action_request2 s loc tid b k` (5) | `Step_action_request2 s loc tid b pol annots k` (7) | Core_reduction.lean `core_step2` | S3: polarity + `core_run_annotation` |
| `match … action_request2` exhaustive | + arm `CompareExchangeRequest2 strong ty obj exp desired mo_s mo_f k` | Core_reduction.lean | S4 |
| `match … driver_error` exhaustive | + `DErr_model_refused (r : model_refusal)`, `DErr_model_inconsistent (i : model_inconsistency)` | Driver.lean | S1/S3 |
| `Global.using_concurrency ()` | — (deleted) | Global.lean / CerbGlobal.lean | S5; no caller existed |
| `CerbConcurrency.statically_satisfied` | — (module deleted) | — | S5; never referenced |

Everything else on your statement surface is unchanged in signature:
`drive_nonmemory_steps_aux2` (the single-thread executor; its step-list
discipline — last component first, first advanceable — untouched, review
§7), `driver2`, `process_core_step2`, the memory model, the ND runner.

## 2. New definitions (generated), by slice

- S1: `concurrency_model`; `model_refusal = MR_spawn_under_sequential |
  MR_non_sc_order mo | MR_fence mo | MR_linux_action | MR_wait`;
  `model_inconsistency = MI_spawn_after_scan | MI_sc_inconsistent leaf`;
  `string_of_model_refusal`/`_inconsistency`; the scan `model_check_file`,
  `sc_fragment_ok`, `epar_free` (mutual structural, `rfl`-evaluable —
  pinned by `example … := rfl` in the exemplar); `can_advance model
  multi_threaded`; `find_can_advance`.
- S3: `lk_of_ctype`, `sc_tag_thread_state`, `sc_record_action`,
  `action_request_sc2`, `sc_failing_leaves`/`_list`,
  `sc_candidate_execution` (Driver.lean); `add_to_sb_ctx`, `add_to_asw_ctx`
  (Core_run_aux.lean); `add_to_sb`/`add_to_asw` take the model (fuel'd,
  measure `lemSize g`, obligations re-proved).
- S4: `cmpxchg_values_equal`, `perform_compare_exchange` (Driver.lean);
  `wrap_tagged_many`, `compare_exchange_action` (Core_reduction.lean).
- S5: `apply_tree_list`, `apply_tree_fp_aux_list` (Cmm_csem.lean;
  `apply_tree`/`apply_tree_fp_aux` are plain structural `def`s now).

## 3. Behaviour under `CM_sequential` (your instance)

Identical to the pre-arc semantics EXCEPT: a thread spawn (`Epar` /
`Step_spawn_threads2`) is `kill (Other (DErr_model_refused
MR_spawn_under_sequential))` at `advance_step` (S1 manifest §3 lists the
arms by file:line) where it used to be silently serialized. No sequential
lane program spawns (S0 grep over 1,669 files: zero); the FULL battery is
at zero movement at every slice (E3). The six theorems in
`test/Unit/SCBridgeTest.lean` §SequentialIdentity state that every
concurrency hook is the identity under `CM_sequential` (S5 manifest §2).

## 4. Behaviour under `CM_sc` (the SC-DRF instance; not your instance yet)

Entry scan → typed refusal outside F_SC; interleavings enumerated (memory
actions/memops are scheduling points iff ≥ 2 threads); candidate
execution recorded per action; trace end: `data_races` → `UB005_data_race`,
then the SC consistency tree must hold (`MI_sc_inconsistent leaf`
otherwise). sb within a thread = execution order (S4 record §1). Value at
issue = the recorded non-parametric point (DESIGN.md §4; mover Phase 1).

## 5. Gates you may rely on at re-pin

Totality slice incl. Cmm_aux/Cmm_csem/Cmm_op (0 partials); axiom census
0; `sorry` census 0; boundary-opaque population 25 rows (−1); litmus lane
24/24 at target on both engines (E1); every slice's FULL battery verbatim
in its record.

## 6. Owed (stated, not hidden)

The `Epar`-free agreement lemma (your Q4; accepted in our response record
as an S5 proof) is NOT discharged — see the consumer note §3 for the
precise statement, what changed since the accepted design, and the
decision pending with the operator.

## 7. Attachments

Generated-Lean diffs: `2026-09-04_concurrency-S1-generated-diff.patch`,
`2026-09-05_concurrency-S{3,4,5}-generated-diff.patch` (S2 changed no
generated signature beyond S1's; S0 changed no `.lem`).
