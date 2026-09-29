# S1 charter — the bounded SC step API (design pass, 2026-09-29)

[AGENT] Charter for S1 of [SC-CONCURRENCY.md](../../SC-CONCURRENCY.md) (§3 S1 row,
"WP1 decision: constraints" 1–7, §4 landing rules), written on mainline `4198f9194` from
the code cited below; nothing is implemented here. It obeys the [USER 2026-09-29]
rulings: WP1 code does not land; one step function in shared Lem, no Lean-only adapter;
fork/join mirrors upstream and refuses loudly; new SC semantics may live in shared `.lem`
but must not change the behaviour of anything upstream supports. Decisions below are
[AGENT] unless marked; terms outside the plan's Terms section are defined where used.

## 1. Scope and non-goals

S1 delivers an internal, bounded transition API over the existing Core reducer, memory
model, lifecycle and finalization: a configuration, effect-free discovery of the
alternatives at that configuration, one deterministic step per chosen alternative, an
explicit step budget, and distinct terminal outcomes. It is internal until S5: no public
SC mode, no race checking (S2), no atomic families (S3), no helper/lifetime work (S4).

| Sub-slice | In scope | Not in scope |
|---|---|---|
| **S1a** single thread | Configuration, alternatives, step, budget, outcomes; init/main/finalization through the real `drive` continuation; step/run laws; a run-to-completion differential against `drive` on the sequential corpora, both engines | Any second thread: `Epar` is a classified *unsupported* outcome; scheduling policy beyond "first alternative"/"exhaustive"/"explicit schedule" |
| **S1b** threads | Thread selection as a choice; blocking; upstream's `Epar`/`Ewait` mechanics unchanged (positional fork order, `Stack_cons2` join refusal → *unsupported*); child runtime init per §8 Q2 | Races, `sb`/`hb` (S2); atomic orders (S3); fairness |
| **S1c** pending `SeqRMW` | Load / update-against-current-memory / store as three transitions; the thread is owned in between; per-owner primitive alternatives; deferred child completion into an owned parent | Atomic RMW/CAS (S3); helper suspension (S4) |
| **S1d** scale | Streaming policy for the retained `trace`; sound reclamation of Core temporaries; the negative-hoisting leak as failing control; churn measurements with real child allocations | Sequential performance work outside the SC path; a general memory port |

Common non-goals: no change to `drive`'s observable behaviour on any existing lane; no
new fuel numerals; no non-kernel proof methods; no register row excusing an S1 change; no Iris.

## 2. Where the code lives — the new-module hypothesis is OVERTURNED

The orchestrator's hypothesis was a new module `frontend/model/sc_driver.lem` importing
`Driver`. Two pieces of code evidence decide against it:

1. **The fork-drift gate fails closed on any generated file present in only one tree**:
   `scripts/check_fork_drift.sh:247-253` (`diff -rq` on the two generated OCaml trees;
   "FAIL — generated trees differ in FILE SET" on `Only in`). A new `.lem` module yields a
   new `ocaml_frontend/generated/sc_driver.ml` that pristine upstream lacks; no manifest
   section can excuse it, and widening a load-bearing trust gate to admit fork-only
   files is code placed around the gate (plan constraint 1). Appending to `driver.lem`
   instead moves the already-excused `driver.ml` `[expected-semantic]` hash
   (`scripts/fork_drift_manifest.txt:611`), which the plan anticipates: refresh
   deliberately, with a stated reason.
2. **Reusing the real init/finalization needs the lifecycle text of `driver.lem` itself**
   (§3.5); a separate module gains nothing on either path there.

Decision: S1 definitions are appended to `frontend/model/driver.lem` in one delimited
section (as the claims register announces). Existing definitions stay textually
unchanged except where §3.5 says otherwise. The generated `Driver.lean` grows; no new
Lake root, no new `EXEC_MODULES` entry (`scripts/check_exec_totality.sh:70-75`).

## 3. S1a in full

### 3.1 What the sequential driver does today (the behaviour S1a must reproduce)

- One "round" (`driver.lem:1066-1095`, `drive_nonmemory_steps_aux2`): for each thread,
  compute `Core_reduction.step_ctx` (one `core_step2` per context of `get_ctx arena`,
  `core_reduction.lem:1126-1536`), take the FIRST step for which `can_advance`
  (`driver.lem:911-938`) holds, perform it with `advance_step` (`:944-1050`), repeat. When
  no step can advance, the whole list is saved for that thread.
- `new_drive_core_threads` (`:1278-1301`) picks ONE saved step per thread (`ND.pick`);
  `driver2` (`:1372-1439`) picks one non-blocked thread's step and runs
  `process_core_step2` (`:1324-1369`), which performs it and recurses into `driver2`.
- So the nondeterminism `drive` explores is exactly: (i) `Step_nd2` alternatives (Core
  `End`, `advance_step` `:1043-1049`), (ii) the saved-step pick when nothing can advance
  (`Step_ccall2`, action/memop requests flagged `is_unseq_with_ccall`, `Step_fs2`,
  `Step_done2`, `Step_blocked2`), (iii) the thread pick, and (iv) nodes produced INSIDE a
  primitive (the concrete model's `msum "pointer equality"`,
  `memory/concrete/impl_mem.ml:1921`, reached through `liftMem`). Unsequenced memory
  actions without a C call are performed first-fit, deterministically.
- Lifecycle: `drive` (`:1734-1899`) = `driver_globals` (`:1571-1648`; one `driver2` run
  per global, `:1617`) → main lookup → `prepare_main_args` (`:1658-1729`) → errno
  allocation (`:1869-1876`) → arena parked on `main`'s body (`:1878-1891`) → `driver2`
  (`:1892`) → `finalize` (`:1476-1503`). Program completion is `Step_done2` or a
  `Step_fs2`/`FS_done` (C `exit`), both through `prepare_exit` (`:1313-1321`).
- WP1's measured defects of this shape (decision record §4): the eager round consumes
  unbounded work on a deterministic singleton loop before any ND node appears, and the
  exhaustive runner evaluates every alternative, executing unchosen effects.

S1a keeps decisions (i)–(iv) identical and makes every reduction its own transition.
This is why run-to-completion can agree with `drive` exactly.

### 3.2 Types (Lem, appended to `driver.lem`)

```
type sc_choice = | SC_alt of nat        (* index into sc_alternatives; S1b adds SC_thread of Mem.thread_id *)
type sc_terminal =
  | SC_done of driver_result                          (* finalize's result *)
  | SC_killed of ND.kill_reason driver_error          (* Undef = UB; Error/Other = fail-stop *)
  | SC_unsupported of string                          (* classified SC refusal *)
  | SC_blocked                                        (* S1b: no runnable thread *)
type sc_phase =
  | SC_lifecycle of driverM driver_result             (* the real outer continuation *)
  | SC_core of driverM driver_result                  (* Core execution; saved remainder *)
  | SC_choosing of list (step_kind * driverM unit) * driverM driver_result   (* a materialized ND node *)
  | SC_final of sc_terminal
type sc_config = <| sc_phase: sc_phase; sc_state: driver_state;
                    sc_transitions: nat; sc_core_reductions: nat; |>
type sc_step_error = | SC_bad_choice of nat * nat | SC_choice_required | SC_terminal
type sc_run_outcome = | SC_stopped of sc_config | SC_exhausted of sc_config | SC_needs_choice of sc_config
type sc_policy = sc_config -> list (step_kind * driverM unit) -> maybe sc_choice
```

`SC_killed` keeps the existing `kill_reason`, so UB (`Undef`), interpreter/model
fail-stop (`Error`, including the Lean fuel-exhaustion atom, classified by the Lean
consumer as Main does) and driver errors (`Other`) stay distinct without a parallel
taxonomy; the joint outcome note (§6) decides printing. `SC_bad_choice`/
`SC_choice_required` are API misuse, never program outcomes. The budget is a `nat`
parameter of the runner; `sc_transitions` is the budgeted unit and `sc_core_reductions`
counts `advance_step`/`process_core_step2` applications — an observed ND node alone is
not a reduction (plan §3 S1 row).

### 3.3 Functions

```
val sc_boundary: unit -> driverM unit        (* ND.mk_step SK_sc_boundary [(SK_sc_boundary, ND.return ())] *)
val sc_start: Core.file core_run_annotation -> list string -> driver_state -> sc_config
val sc_alternatives: sc_config -> list step_kind          (* pure; [] when deterministic *)
val sc_step: sc_config -> maybe sc_choice -> either sc_step_error sc_config
val sc_run: nat -> sc_policy -> sc_config -> sc_run_outcome
val sc_events: sc_config -> sc_config -> list trace_event (* trace delta between two configs *)
val sc_policy_first: sc_policy   val sc_policy_schedule: list sc_choice -> sc_policy
```

`sc_start` builds `SC_lifecycle (drive_with sc_boundary false file args)` (§3.5) on the
caller's `initial_driver_state` (`:1539`). `sc_step` by phase:

- `SC_lifecycle k`: apply `k` to the state (`let ND m = k in m st`). `NDactive r` →
  `SC_final (SC_done r)`; `NDkilled r` → `SC_final (SC_killed r)`;
  `NDstep SK_sc_boundary [(_, k')]` → `SC_core k'` (a Core body is about to run);
  `NDnd _ alts` → `SC_choosing alts k`; any other node → `SC_unsupported`.
- `SC_core k`: thread 0 is the only thread in S1a (another present → `SC_unsupported`).
  Compute `steps = step_ctx …` exactly as `:1077`. If `find_can_advance steps = Just s`
  → the deterministic transition `advance_step tid s` (`:1053-1062`, `:944`); else the
  saved list is the choice (`sc_alternatives` = its kinds in list order; `SC_alt i`
  performs `process_core_step2 false (fun _ -> ND.return ()) steps[i]`, `:1324`). The
  chosen `driverM unit` action yields: `NDactive ()` → stay `SC_core k`, except after
  `Step_done2`/`FS_done` (both ran `prepare_exit`) where the phase becomes
  `SC_lifecycle k` so the saved remainder — a global's value capture, main startup or
  `finalize` — resumes; `NDkilled` → final; `NDnd _ alts` → `SC_choosing alts k` (a
  node inside a step, e.g. pointer equality). `Step_spawn_threads2`/`Step_thread_done2`
  → `SC_unsupported` ("fork/join: S1b"); `Step_blocked2` cannot arise without `Epar`;
  `Step_error2 s` → `SC_killed (Error loc s)`, never `error`.
- `SC_choosing alts k` with `SC_alt i`: run `alts[i]` from the stored state; out of range
  → `Left (SC_bad_choice i (length alts))`, configuration unchanged; `Nothing` →
  `Left SC_choice_required`.
- `SC_final _` → `Left SC_terminal` (terminal configurations are absorbing).

`sc_run n pol cfg`: `n = 0` → `SC_exhausted cfg` unless final; else `sc_step` with the
policy's choice, recursing on `n-1`. Recursion is structural on the budget
(`declare {lean} termination_argument sc_run = automatic`); if the Lean backend rejects
the `nat` form, fall back to WP1's list-schedule shape (`experiment_run`, proven on both
targets) and derive the `nat` runner from it. S1a adds NO fuel'd worker and no `error`
site of its own (`scripts/check_failure_reach.sh` rows unchanged; `check_fuel_forms.sh`
pending register unchanged).

### 3.4 Existing functions reused, unchanged

`step_ctx`, `get_ctx`, `can_advance`, `find_can_advance`, `advance_step`,
`process_core_step2` (with a no-op continuation), `perform_action_request2 false`,
`perform_memop_request2`, `liftCore_run`, `liftMem`, `prepare_exit`, `finalize`,
`prepare_main_args`, `driver_globals`' body, `initial_driver_state`, `spawn_thread`,
`update_thread_state`. `with_concurrency` is always `false` on the SC path: the old
`--concurrency` flag (`Cerb_global.concurrency_mode`, `global.lem:38-41`) enables the
broken C11 machinery (`:759`, `:1895`) and is not the SC mode. WP1's `step_ctx`
continuation-passing factoring is NOT adopted: computing every context's step and
selecting first-fit is what `drive` does per round (`:1077`); single-context selection
is a profiled optimization for later, if ever.

### 3.5 Existing definitions that change, and the preservation argument

Exactly two, both in `driver.lem`, both for the lifecycle boundary:

```
let inline driver_globals_with (run_threads: unit -> driverM unit) file = <body of :1572-1648 with `driver2 with_concurrency` at :1617 replaced by `run_threads ()`>
let driver_globals with_concurrency file = driver_globals_with (fun () -> driver2 with_concurrency) file
let inline drive_with (run_threads: unit -> driverM unit) with_concurrency file arg_strs = <body of :1735-1899 with :1739 → driver_globals_with run_threads file and :1892 → run_threads ()>
let drive with_concurrency file arg_strs = drive_with (fun () -> driver2 with_concurrency) with_concurrency file arg_strs
```

Why a thunk: WP1 passed the action value `driver2 with_concurrency`
(`git show 186392a53:frontend/model/driver.lem`, `drive`), built once; the oracle then
lost its per-call `ENTERING Driver.driver2` debug lines at `-d ≥2` (assessment §1
item 5) — the mechanism (OCaml applies `driver2` eagerly at construction) is [AGENT]
inference from the diff, confirmed by check (c). The thunk applies `driver2` at each
original call site. Why `let inline`: the WP1 review found that moving a body into a
differently named function changed six failure backtraces and made the pristine-oracle
comparison a `difference` (bounded-stepping record; `test_upstream_oracle.py`'s
projection compares frame FUNCTION names raw). Inlining keeps the lifecycle code
lexically in `drive`/`driver_globals`. Also add `SK_sc_boundary` to `step_kind`
(`:94-100`, its `Show` arm, and the exhaustive match in `backend/web/instance.ml:380-397`,
outside the drift surface and the ladder build). Preservation evidence, all required:
(a) the generated `driver.ml` diff against the pre-slice tree shows the appended section
plus reviewed hunks in those two definitions only; (b) the full Tier A ladder and Tier B
rows 4, 5, 7, 10 pass with ZERO new `scripts/upstream_oracle_differences.json` rows and
unmoved baselines; (c) oracle `-d 2` stderr byte-identical pre/post on `tests/minimal`
and one libc-mode program; (d) `CerbCall.driveCall` and `FuelExemplar.lean` (which
restate `drive`'s setup stages by `rfl`) build unchanged. Fallback if (a)–(c) fail (e.g.
Lem's `inline` mangles the body): leave both definitions byte-identical and write
`sc_lifecycle` as an explicit restatement over the same helpers; the §3.10 lane is then
the only guard against lifecycle drift, and §8 Q1 is re-asked.

### 3.6 How alternatives are represented so discovery is effect-free

Alternatives are never computed by running anything: in `SC_core` they are the
`core_step2` values `step_ctx` returns — data holding unrun `core_runM` continuations
(`core_reduction.lem:119-136`); in `SC_choosing` they are the branches of an `NDnd` node,
each an unapplied `driverM unit` closure (`nondeterminism.lem:43-52`; `pick` `:190-208`
and `msum` `:137-150` return the node without touching state). Materializing a node is
part of the transition that produced it; branches run only when chosen, one at a time.
`NDguard`/`NDbranch` are unreachable in the concrete model (`CerbND.lean` header); S1a
returns `SC_unsupported` on them.

### 3.7 Initialization, finalization, exit

Through the real continuation: `sc_start` holds `drive_with sc_boundary …`, so global
initialization, `main`'s argument objects, errno and the arena come from the unchanged
lifecycle text; each Core body (every global's initializer, then `main`) is entered at an
`SK_sc_boundary` node and stepped; `Step_done2`/`FS_done` run production `prepare_exit`
and hand control back to the remainder, whose last segment is `finalize`. Budget 0
performs no lifecycle effect (WP1 fixture: no thread spawn, no errno store). `drive`'s
own `ND.kill`s (`:1747`, `:1753`) surface as `SC_killed (Other …)`.

### 3.8 Output and trace

Unchanged from `drive` in S1a: `io.stdout/stderr` (`core_run_aux.lem:221-231`) and
`driver_state.trace` (`driver.lem:73`, appended at `:676,686,697,710,722,743`) accumulate;
`sc_events` exposes the per-transition trace delta; WP0 receipts are drained through
`CerbMem.takeObservations`/`take_observations` as today. Streaming is S1d; S1a records
the retained sizes on the fixtures as S1d's baseline.

### 3.9 Lean exposure and kernel laws

Generated `Driver.lean` exports the definitions with the ambient `[LemFuel]` binder they
inherit from `nd_bind`. Laws live in `lean_frontend/test/Unit/SCStepProofs.lean`, imported
by a new exe `sc-step-test` (`Unit.SCStep`) so they compile on every `test_unit.sh` run
(the WP0 `memory-access-test`/`MemoryAccessProofs` pattern; no new seam, no manifest
change). Statements over the generated definitions, ∀ fuel instance, ∀ configuration:

- **L1 budget accounting.** `sc_run 0 pol cfg = if final cfg then SC_stopped cfg else SC_exhausted cfg`;
  `sc_run n pol cfg = SC_exhausted cfg' → cfg'.sc_transitions = cfg.sc_transitions + n`;
  `cfg'.sc_core_reductions ≤ cfg'.sc_transitions`.
- **L2 step/run.** `sc_run (n+1) pol cfg` unfolds to one `sc_step` followed by
  `sc_run n` on its result (the runner is the iteration of the step; definitional);
  `Right cfg' = sc_step cfg c → cfg'.sc_transitions = cfg.sc_transitions + 1`.
- **L3 terminal absorption and stability.** `final cfg → sc_step cfg c = Left SC_terminal`;
  `sc_run n pol cfg = SC_stopped t → ∀ m ≥ n, sc_run m pol cfg = SC_stopped t`
  (the analogue of `CerbNDFuelProofs.runNDFuel_stable`).
- **L4 discovery purity.** `sc_alternatives` is a function of `cfg` (definitional);
  `i ≥ length alts → sc_step (SC_choosing alts k st) (Just (SC_alt i)) = Left (SC_bad_choice i (length alts))`
  with `cfg` unchanged; `i < length alts → sc_step … = sc_resume (alts.get i) k st` —
  the unchosen closures are not applied (syntactic in the definition, pinned by `rfl`).
- **L5 same handlers.** For every `core_step2` constructor S1a performs,
  `sc_perform tid s st = (advance_step tid s).run st` or
  `(process_core_step2 false noop s).run st` by `rfl`/`simp [sc_perform]` — a pin against
  a re-implemented handler drifting from the sequential one.

Not proved in S1a: `runND (drive …) = exhaustive sc_run`. It is differential evidence
(§3.10) and a named WP-C execution-fidelity obligation (relating the fuel'd eager round
`drive_nonmemory_steps_aux2` to the transition sequence), a candidate once the API is stable.

### 3.10 Differential evidence

New lane `scripts/test_sc_step.py` (Tier A candidate; ~2–4 min expected), both engines,
exhaustive SC enumeration (choice tree walked with `runNDFuel`'s branch-order
convention, results compared as SORTED multisets of batch verdict lines):

| Row | What | Expected answer |
|---|---|---|
| A | Lean `sc_run` exhaustive vs Lean `drive` (`runND`) | equal multisets, every program |
| B | OCaml `sc_run` exhaustive vs fork oracle `--batch --mode=exhaustive` | equal multisets |
| C | Lean `sc_run` vs OCaml `sc_run` | equal multisets |
| D | rows A–C in first-alternative mode vs `--first`/oracle single trace | equal on trace-independent programs (`--first`'s own caveat, CONTRACT §2) |
| E | `tests/sc-step/loop-*.c` (deterministic `while(1)`), budgets 1, 2, 7, 4096 | `SC_exhausted`, `sc_core_reductions = budget − startup transitions`, unchanged memory; `drive` on the same input ends only in the fuel kill |
| F | every program: `SC_unsupported` count | 0 — no gated sequential corpus contains `{-{ … }-}` (measured: `grep -rl -- "{-{" tests/{ci,minimal,immaculate,coverage,debug,float,libc_exec,verify}` is empty; only `tests/sc-recovery` has par blocks) |

Corpora: `tests/minimal` (113 baseline rows), `tests/immaculate` nolibc, `tests/debug`,
`tests/float`, `tests/coverage` (test_exec.sh's corpora and flags), `tests/libc_exec`
(libc mode, row D). Expected answers are the existing pinned baselines
(`scripts/exec_baseline.txt` and friends) and the live oracle; no new baseline. Engines:
Lean via a Main flag `--sc-run --sc-budget N` after `--batch` (budget REQUIRED, no
default numeral; §8 Q3); OCaml via a new `backend/sc_probe/sc_run.exe` (the
`backend/memory_probe` precedent: links `cerberus-lib.backend_common` + `mem_concrete`,
reuses `Driver_ocaml.string_of_batch_output`, `driver_ocaml.ml:66`); the oracle binary is untouched.

### 3.11 Negative controls (plants; each must go red, then be reverted and re-verified)

P1 eager discovery (`sc_alternatives` performs the first alternative): a receipt appears
with no chosen step; row E's "unchanged memory" and L4 fail. P2 budget (two decrements
per transition): L1 fails to typecheck; row E counts wrong. P3 lifecycle (`Step_done2`
without `prepare_exit`): `finalize` raises `BOOM finalize`; row A fails. P4
classification (`SC_unsupported` mapped to `SC_done`): the lane's control row runs one
`tests/sc-recovery` par-block program and requires `SC_unsupported`. P5 lane vacuity: a
doctored verdict line in one engine → red. P6 preservation: WP1's value-passing (no
thunk) → §3.5 check (c) red.

### 3.12 Gate, manifest and pin implications

- `scripts/fork_drift_manifest.txt`: `[source-content]` row for `driver.lem`;
  `[expected-semantic]` `driver.ml` hash refreshed with a NOTE: appended SC section + the
  two `_with` factorings, nothing else. `backend/web/instance.ml` and `backend/sc_probe/`
  are outside `SURFACES` (`check_fork_drift.sh:91-95`; the `backend/memory_probe/`
  precedent); `backend/driver/main.ml` is not touched, so no `[files]` row.
- `scripts/check_theorem_axioms.sh:725-726` `ENTRIES`: add `sc_start sc_step sc_run`
  (exact allowlist `[propext, Classical.choice, Quot.sound]`); `gen_fuel_parametricity.py`
  pins: none new if no fuel'd worker is added (the goal); `check_fuel_forms.sh`: the
  drive cone is unchanged — S1a's acceptance also runs the classifier with `sc_run` as a
  root and reports the table.
- `lean_frontend/lakefile.toml`: one `[[lean_exe]]` (`sc-step-test`); `scripts/test_unit.sh`
  exe list; `Main.lean` flag (§8 Q3); `CONTRACT.md` §3 concurrency row: INTERNAL note (§6).
- lem-lean pin: none. Only existing Lem features are used (`let inline`, records, the ND
  monad, `termination_argument automatic`); the list-schedule fallback avoids a pin move.

### 3.13 Size (derived estimate)

Lem ≈ 300 lines (types 40, phase machine 130, lifecycle factoring 30, runner/policies
60, events 20); Lean proofs ≈ 200; Lean test exe ≈ 80; Main flag ≈ 40; OCaml probe exe
≈ 120; lane script ≈ 180; 3–4 C fixtures; manifest/gate edits ≈ 20. One worker, one or
two commits (semantics + lane; proofs may trail by one commit on a green lane).

## 4. S1b–S1d briefs

### S1b — threads via upstream's mechanics (depends on S1a)

Contract: `sc_choice` gains `SC_thread tid`; `sc_alternatives` in `SC_core` lists the
runnable threads (those with a non-`Step_blocked2` step; blocked steps are not offered —
the one departure from `drive`'s pick, whose blocked branch is dead) and, per thread,
§3.3's local alternatives. One transition = one reduction of one thread.
`Step_spawn_threads2` runs the unchanged `advance_step` arm (`driver.lem:1023-1038`):
children get `Stack_empty`, the parent's `env`, and the parent's arena becomes
`unseq [wait tid …]` in `spawn_tids` order — upstream's positional result order
(`foldlM` with `::`), kept. `Step_thread_done2` runs `kill_thread`
(`core_run.lem:90-105`) only after the pre-check "parent stack is `Stack_empty`"; else
`SC_unsupported "join into a procedure frame: upstream refuses (subst_wait_stack ==>
Stack_cons2, core_run_aux.lem:101-102)"`. The check is exact: the reducer pushes only
`Stack_cons2` (`core_reduction.lem:1402,1434`); from C this is reached only through a
par block inside a called function (`translation.lem:4203-4209`). All threads blocked →
`SC_final SC_blocked` (where `drive` dies in `ND.pick … []`, `:1426`). C `exit` from any
thread → `prepare_exit`, as in `drive`. Child errno: §8 Q2. Evidence:
`tests/sc-recovery/lifecycle/global-init-main.c`, `sequencing/*`, WP1's schedule fixtures
re-derived (complete enumeration of `ab/c`-shaped par programs gives exactly the
independently listed interleavings at reduction granularity; `drive`'s verdict set ⊆ the
SC set on every par program `drive` completes; a nested-call par block reports
`SC_unsupported`). Laws: L1–L5 over the extended choice; one transition changes at most
one thread's `thread_state` plus shared state.

### S1c — pending `SeqRMW` with ownership (depends on S1b)

Contract: `SeqRMWRequest2` (`core_reduction.lem:1267-1335`) becomes three transitions —
load (`Mem.load`, receipt), update, store (`Mem.store`); other threads may run between
them; the owner offers exactly one alternative, "resume". `sc_config` gains
`sc_pending: list sc_pending_rmw` (tid, aid, type, pointer, loaded value, updater, result
builder). A `Step_thread_done2` into an owned parent is not offered until ownership ends
(constraint 2); ownership adds no `sb`/`hb`. Current memory: the updater at
`core_reduction.lem:1282-1297` closes over the `mem_st` passed to `step_ctx`, a snapshot.
Change its type to `Mem.mem_state -> Mem.mem_value -> core_runM Mem.mem_value`
(`action_request2` `:102-105`, the `step_ctx` arm, and `action_request_sequential2`
`:714-724` passing `dr_st.layout_state` read after its load). Preservation for `drive`:
pure evaluation reads memory only for pointer facts, which a load does not change; the
lanes are the evidence; the touched functions are claimed first. Primitive alternatives
inside any phase (an `NDnd` from `liftMem`) are the owner's, via `SC_choosing`. Evidence:
WP1's decision-record §2 SeqRMW rows re-derived as schedule fixtures (intervening write,
forwarding, sibling exactly once, failed update keeps only the read) on real C
`x++`/compound-assignment programs; sequential lanes unchanged. Law: no transition of an
owned thread other than resume.

### S1d — scale (depends on S1a; measurements re-run after S1b/S1c)

Contract: (1) trace policy — runner option `SC_trace_stream`: each transition's trace
delta goes to the consumer and leaves `sc_state.trace`, so retained trace is O(1) per
transition; `SC_trace_retain` keeps `drive`'s behaviour; `finalize` reads `io`, not
`trace`, so `dres_*` are unaffected. (2) Lexical reclamation — a binding in the current
frame's map (`thread_state.env` head, `core_run_aux.lem:212`; caller frames are other
list elements and untouched) may be dropped only if its symbol is free in neither the
arena nor the current procedure's labeled continuations (`core_run_state.labeled`), nor
referenced by a pending S1c record; applied at `Erun` (loop back-edges), never by a
numeric or age cutoff. Proof obligation: environment agreement — every pexpr reachable
from those roots evaluates identically under the pruned and the full map. Failing
control: WP1's negative-hoisting loop (a `while` loop whose body is an assignment store;
one binding per iteration under `drive`) shows bounded map size under S1d and linear
growth with reclamation off. (3) Measurements per technical design §7: fixed objects,
lifetime churn, repeated split/join, repeated thread creation with REAL child runtime
allocations (constraint 6); transitions, retained sizes, wall time and RSS against
sequential controls. No wall-clock threshold is a gate.

## 5. V1 and the first consumer

The S1a lane is S1's first concrete consumer (decision record §5 item 2). After S1b, the
V1 lane skeleton runs real C par-block programs through init/main/finalize on both
engines with recorded schedules (complete enumeration or selected prefix, classified);
its race and publication rows arrive with S2 and the minimal S3 lowering. S1 owes
cerberus-sl no re-pin; a consumer note is written at S1's close.

## 6. Coordination

Claims register rows (append before starting each sub-slice): S1a — `driver.lem`
(appended section; `driver_globals`/`drive` thunk factoring; `step_kind`), `Main.lean`
(one internal flag), `lakefile.toml`/`test_unit.sh` (one exe), `check_theorem_axioms.sh`
`ENTRIES`, `fork_drift_manifest.txt`, new `backend/sc_probe/`, `scripts/test_sc_step.py`,
`tests/sc-step/`. S1b — `driver.lem`. S1c — `core_reduction.lem` (`action_request2`,
`step_ctx` SeqRMW arm), `driver.lem` (`action_request_sequential2`). S1d — `driver.lem`,
possibly `core_aux.lem` (free-symbol helper; overlap already noted in the coordination
response). Step-runner note (P1f-3, next-phase drafts first): §3.2–3.3 and §3.9 are
SC's contribution; a stack-ceiling repair is shown semantics-preserving separately from
any scheduling change. Outcome-taxonomy note (P1f-4, next-phase hosts):
`sc_terminal`/`sc_run_outcome`/`sc_step_error` are the SC input — completion, UB,
unsupported, blocked, budget exhaustion, fuel exhaustion (the distinguished kill), API
misuse and host failure all distinct. CONTRACT.md: S1a adds no promise; `--sc-run` is
registered in §3's concurrency row as INTERNAL (outside §1: on sequential programs it
reproduces the default verdicts by the §3.10 lane; `{-{ }-}` refuses until S1b, and
thereafter its verdicts are internal, not accepted C behaviour — plan §4).
`--concurrency` stays refused (`check_cli_refusals.sh`). The Main.lean edit is announced
against the next-phase CLI work; whichever lands second rebases. No lem-lean pin move.

## 7. Risks and reopen conditions

- R1 lifecycle factoring not shown preserving (§3.5 a–c) → fallback restatement; if that
  also fails row A, reopen the lifecycle-reuse design.
- R2 `nat`-recursive runner refused by the Lean backend → list-schedule form; a backend
  change would be an announced two-repo slice.
- R3 rows A/B below 100% on the gated sequential corpora → an S1a bug or a `drive`
  scheduling fact §3.1 missed; never a register row.
- R4 `drive`'s verdict set ⊄ S1b's on a completing par program → the local policy
  diverged from first-fit; reopen S1b's alternative rule.
- R5 S1c cannot use current memory without changing observable sequential behaviour →
  reopen the pending-operation data boundary (decision record §5).
- R6 S1d needs a rule beyond the named roots → the environment-agreement lemma arbitrates; no cutoff.
- R7 a law needing a banned method or an option bump → restructure the definition, never weaken the law.

## 8. Open questions for the operator (each with a recommendation)

- **Q1 Lifecycle boundary mechanism.** `let inline` thunk factoring of
  `drive`/`driver_globals` under the §3.5 battery, versus an explicit `sc_lifecycle`
  restatement leaving both byte-identical. Recommendation: factoring — one lifecycle
  text is the smaller long-term divergence risk; fallback as stated.
- **Q2 Child errno in S1b.** Upstream gives `Epar` children a null errno pointer
  (`core_reduction.lem:1494`, "TODO: allocate errno"); the plan's S1 row asks for actual
  child runtime/errno initialization; the brief says "as upstream does". Recommendation:
  allocate a real errno per child on the SC path only (the `driver.lem:1869-1876`
  pattern) — `drive` is untouched and the null is upstream's own placeholder, not a
  supported behaviour; record it in the S1b acceptance record. If strict mirroring is
  preferred, classify a child errno access as `SC_unsupported` instead.
- **Q3 Lean-side lane entry.** Main's pipeline (`runPipeline`, `Main.lean:884`) is not
  importable by a test exe, so the Lean lane needs a Main flag now or the next-phase
  pipeline extraction (P2a-1) first. Recommendation: one internal flag
  `--sc-run --sc-budget N` (budget required), registered INTERNAL in CONTRACT.md §3,
  renamed or replaced at S5.
- **Q4 Lane tier.** Recommendation: Tier A while under ~4 min on `tests/minimal` +
  immaculate + debug/float/coverage; the libc_exec row D in Tier B.
- **Q5 `SK_sc_boundary`** as a typed constructor (touches `backend/web/instance.ml`,
  unbuilt by the ladder) versus an `SK_misc` string tag. Recommendation: typed; the web
  arm is one line.
