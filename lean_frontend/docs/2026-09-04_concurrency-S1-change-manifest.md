# Concurrency Phase 0 — S1+S2 change manifest for the consumer (2026-09-04)

For refined-cerberus (review response §6 Q5: a STAGED re-pin, S1's signature
change announced as its own change). Base: mainline `753644005` (the fuel
arc C1 head). Branch `feature/concurrency` (the S1+S2 commit; the S1+S2
record `2026-09-04_concurrency-S1-S2-record.md` has the gate evidence).
Attachment: `2026-09-04_concurrency-S1-generated-diff.patch` — the unified
diff of EVERY generated Lean module that differs from the base tree
(`Core_run_aux`, `Core_run`, `Mini_pipeline`, `Driver` + two auxiliaries;
every other generated module is byte-identical; base = the primary
checkout's tree at lem-sync src stamp `03c176935c…`, i.e. the C1 head).

## 1. The one statement-text change (Q1)

`drive`'s second explicit argument is the model selector, not a bool
(generated `Driver.lean:716`):

    drive [LemFuel] (tagDefs) (model : concurrency_model) (file1) (arg_strs)

`false` → `CM_sequential` is the ONLY rewrite a sequential statement needs.
Same substitution for any statement naming `driver2` (`Driver.lean` —
`driver2_lemFuel fuel tds CM_sequential`), `driver_globals` (:671),
`process_core_step2` (:571; its continuation argument is now
`concurrency_model → ndM …`), `perform_action_request2` (:464),
`advance_step` (:527), `new_drive_core_threads` (:549),
`drive_nonmemory_steps_aux2_lemFuel` (the model sits between `tds` and
`acc`), `can_advance` (:502, now `model → multi_threaded → step → Bool`),
`find_can_advance`, `Core_run.kill_thread` (`Core_run.lean:112`), and
`Core_run_aux.add_to_sb/add_to_sb_stack/add_to_asw/add_to_asw_stack`
(the four former `Global.using_concurrency ()` readers, now taking the
selector). The type: `Core_run_aux.lean:113`

    inductive concurrency_model | CM_sequential | CM_sc   -- payload-free; derived BEq/Ord

## 2. What leaves your cones (Q1, reasoning-artifact row A step 2)

`CerbGlobal.using_concurrency` is no longer read by any generated module
(the four `core_run_aux.lem` guards match on the threaded selector). The
opaque still exists in `CerbGlobal.lean` (deleted with its census re-pin in
S5); it is simply unreached from `drive`.

## 3. New constructors and new arms (Q2, review §6)

`driver_error` (`Driver.lean:195`) gains

    | DErr_model_refused (r : model_refusal)
    | DErr_model_inconsistent (i : model_inconsistency)

with DATA payloads (`Driver.lean:114`): `model_refusal = MR_spawn_under_sequential
| MR_non_sc_order (mo : memory_order) | MR_fence (mo : memory_order) |
MR_linux_action | MR_wait`; `model_inconsistency = MI_spawn_after_scan`.
Both are kills `NDkilled (Other (DErr_model_… _))` in the driver monad;
no `panic!`. `DErr_concurrency (s : String)` is unchanged and gains no
producer. Rendering for the batch line is the GENERATED
`string_of_model_refusal` / `string_of_model_inconsistency`
(`driver.lem:207-230`), identical on both engines.

Arms that gain a kill (your round classification re-proves against these;
`driver.lem` cites, generated `Driver.lean` as above):
- `drive` :1946-1954 — ENTRY: `match model_check_file model file with
  | Just r -> ND.kill (ND.Other (DErr_model_refused r)) | Nothing -> <the
  historical body>`. Under `CM_sequential` the scan refuses any `Epar`
  (`MR_spawn_under_sequential`); under `CM_sc` any non-`Seq_cst` atomic
  order / `Fence` / `Linux*` / `Ewait`.
- `advance_step` :1136, the `Step_spawn_threads2` arm :1215-1221 — under
  `CM_sequential`: `ND.kill (ND.Other (DErr_model_inconsistent
  MI_spawn_after_scan))` (unreachable after the entry scan; the defensive
  invariant); under `CM_sc`: the historical spawn.
No other arm changes its outcome set. `perform_action_request2` :925
matches on the model with two textually identical arms (S3 fills the
`CM_sc` arm with the execution construction).

## 4. The scheduler under each model (review §4/§7)

- `can_advance model multi_threaded` (:1099): under `CM_sequential` the
  historical values; under `CM_sc`, `Step_action_request2` and
  `Step_memop_request2` are NOT advanceable when `multi_threaded` (= at
  least two threads exist, computed once per per-thread read in
  `drive_nonmemory_steps_aux2` :1279 as
  `List.length dr_st.core_state.thread_states >= 2`). With one thread the
  path is the sequential one — the agreement lemma's mechanism (review
  §5; proof is S5).
- `drive_nonmemory_steps_aux2`'s per-thread `ND.read` now returns the PAIR
  `(multi_threaded, steps)` (previously `steps`). A symbolic step over it
  binds the pair (our exemplar: `runOne_bind_active (z := (false,
  [Step_done2 v]))`, `test/Unit/FuelExemplar.lean` `loop_step_done`).
- `new_drive_core_threads` :1482-1500: a thread whose saved steps are ALL
  `Step_blocked2` contributes ONE blocked step (the k identical entries of
  a k-child wait are not a choice). Measured effect: SB 496 → 20 traces
  (= 6!/(3!3!), the interleaving count), IRIW unfinished-at-300 s/15 GB →
  6300 traces (= 10!/(4!4!)) in 1.05 s. Outcome SETS unchanged; the
  single-thread loop's step-list discipline (last component first, first
  advanceable) is untouched (§7).
- `drive`'s tail keeps the bind shape `(… >> driver2 model) >> (ND.get >>=
  finalize …)` — the parentheses are load-bearing (lem's `>>`/`>>=` are
  left-associative; without them the outermost bind's first component
  changes type and the symbolic step stops unifying first-order — measured
  as the exemplar proof going from 2 s to an OOM kill before the fix).
  `finalize`'s debug string is `"drive (without concur)"` under
  `CM_sequential` (unchanged) and `"drive (sc)"` under `CM_sc`.

## 5. Shipped predicates (Q3)

`sc_fragment_ok : file → Bool` (`Driver.lean:274`), `epar_free` (:278),
both `match model_check_file … with none => true | some _ => false`;
`model_check_file : concurrency_model → file → Option model_refusal`
(:259, reads only the file: `funs`, `stdlib`, `globs`; `Fun`s and `impl`
are pure). The scan is the mutual structural triple `model_check_expr /
model_check_exprs / model_check_pat_exprs` — plain `def`s (no `partial`,
no fuel, no `termination_by`), KERNEL-COMPUTABLE: pinned by
`example : sc_fragment_ok exemplarFile = true := rfl` (+ `epar_free`, +
`model_check_file CM_sequential exemplarFile = none := rfl`) in
`test/Unit/FuelExemplar.lean`, a gate exe. The `_iff` Prop form is S5.

## 6. Exemplar adaptation (what a consumer proof does)

`drive_after_setup`: after `conv => lhs; unfold drive`, add
`rw [show model_check_file CM_sequential exemplarFile = none from rfl]`
then `dsimp only` (the entry `match` iota-reduces), then the historical
steps unchanged. `loop_step_done`: `dsimp only` after the unfold (the list
`match` on the literal), and the read's value is the pair. Everything
else in the file compiled unchanged. Elaboration time: unchanged order
(the whole file in ~1 min).

## 7. CLI (harness only, not a statement change)

Oracle: `--concurrency=sc` (cmdliner `opt (some (enum ["sc", CM_sc]))`;
bare `--concurrency`/unknown name refused). Lean: `--concurrency=sc`
accepted anywhere after the mode flag; bare/unknown refused (Z-24
message names the selector). Default: `CM_sequential` on both.
