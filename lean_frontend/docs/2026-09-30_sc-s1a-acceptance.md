# S1a acceptance record — the bounded SC step API, single thread (2026-09-30)

[AGENT] Implementation record of S1a (charter [`2026-09-29_sc-s1-charter.md`](2026-09-29_sc-s1-charter.md)
§3, as amended §9 and ruled §8; [USER 2026-09-30] "Agree on recommendations, go ahead"), the
plan's §4 item 2 record. Implemented on `arc/sc-s1a`; **not landed** — pre-merge audit and
per-merge sign-off pending. Every quoted output below is verbatim; derived tallies are marked
derived. Bulky evidence (lane transcripts, plant logs) lived under the worktree's `.tmp/` and
was deleted after the tails below were recorded.

## 1. Contract

The internal, bounded transition API over the existing Core reducer, memory model, lifecycle
and finalization, for the single startup thread: a configuration (`sc_config`), effect-free
discovery of the alternatives at it (`sc_alternatives`), one deterministic step per chosen
alternative (`sc_step`), an explicit step budget (`sc_run n`, `sc_explore n`), distinct terminal
outcomes (`SC_done` / `SC_killed` (UB, fail-stop incl. the Lean fuel kill, driver error) /
`SC_unsupported` / `SC_blocked`) and distinct run outcomes (`SC_stopped` / `SC_exhausted` /
`SC_needs_choice` / `SC_run_error`). Init/main/finalization run through the real `drive` text
(entered at `NDstep` boundaries); every Core reduction is one transition performed by the
unchanged sequential handlers (`advance_step` for the first `can_advance` step, else `drive`'s
`pick` over the saved steps processed by `process_core_step2`); `Epar` (`Step_spawn_threads2`)
and a second thread are classified `SC_unsupported` before any effect. No public mode; the one
CLI entry is INTERNAL (`--batch --sc-run --sc-budget N [--sc-first]`, CONTRACT.md §3).

Not in S1a: threads (S1b), pending `SeqRMW` (S1c), streaming/reclamation (S1d), race checking
(S2), atomics (S3). `runND (drive …) = sc_explore` is differential evidence, not a theorem
(charter §3.9).

## 2. Base, head, dependencies

- Base: `1864c6562` = mainline `4198f9194` + the S1 charter commits. Head: the commit(s) of
  `arc/sc-s1a` carrying this record (stated in the final report).
- Lem pin unchanged: `c2a68e79b6369e19f099dfa48767319c1daf19b3` (`lem -v` = `Lem c2a68e7`); only
  existing backend features are used (`let inline`, `structural val`, the ND monad).
- Donor provenance: none. The WP1 experiment (`arc/sc-wp1`) is a specification of behaviour;
  no code was taken from it. The par-block control fixture is written fresh (its shape is the
  Cerberus `{-{ … ||| … }-}` extension, as in `tests/sc-recovery/prefix/race-before-loop.c`).
- Source of expected behaviour: `drive` itself (rows A–C compare against it on both engines);
  the existing pinned baselines (`scripts/exec_*_baseline.txt`, `tests/immaculate/baseline.txt`,
  `tests/libc_exec/baseline.txt`) decide where cross-engine agreement is required; row E's
  figures are derived from the fixtures' Core shape and pinned in their headers.

## 3. What changed (files)

| Surface | Change |
|---|---|
| `frontend/model/driver.lem` | (i) the two lifecycle factorings of charter §3.5 — `driver_globals`' and `drive`'s bodies become `let inline driver_globals_with (run_threads : unit -> driverM unit) file` and `let inline drive_with globals run_threads with_concurrency file arg_strs`; `driver_globals`/`drive` re-apply them with the thunk `fun () -> driver2 with_concurrency` (and `drive` passes the globals stage `driver_globals with_concurrency`), so every lifecycle line stays lexically inside its original function (charter §10 item 1); (ii) the appended section "SC concurrency S1a": types `sc_choice`, `sc_terminal`, `sc_phase`, `sc_config`, `sc_step_error`, `sc_run_outcome`, `sc_policy`, `sc_steps_class`; functions `sc_boundary_kind`, `sc_boundary`, `sc_driver_globals`, `sc_initial`, `sc_start`, `sc_perform`, `sc_final`, `sc_run_action`, `sc_advance`, `sc_interpret_lifecycle`, `sc_interpret_core`, `sc_refuse`, `sc_classify_steps`, `sc_core_transition`, `sc_alternatives`, `sc_chose`, `sc_step`, `sc_run_list`/`sc_run`, `sc_explore_list`/`sc_explore`, `sc_events`, `sc_policy_first`, `sc_policy_schedule`; two `declare {lean} structural val` (the first in this tree). No other existing definition changes. |
| `lean_frontend/Main.lean` | the INTERNAL flag; `printBatchStatus` factored out of the batch loop (byte-identical output); `scRecord`/`printScOutcomes`. |
| `backend/sc_probe/{dune,sc_run.ml}` (new) | the OCaml engine of the lane: main.ml's batch pipeline (cites inline) + `Driver.sc_explore`/`sc_run` + the oracle's `string_of_batch_output`. Outside the fork-drift SURFACES. |
| `scripts/test_sc_step.py` (new), `tests/sc-step/` (new) | the lane (rows A–F, `--libc` row D, `--selftest`), its fixtures and README. |
| `lean_frontend/test/Unit/SCStepProofs.lean`, `SCStep.lean` (new); `lakefile.toml`; `scripts/test_unit.sh` | the laws L1–L6 and the `sc-step-test` exe; the lane's `--selftest` rides `test_unit.sh`. |
| `scripts/check_theorem_axioms.sh` `ENTRIES`, `test/Unit/FuelFormsTool.lean` `entries` | `+ sc_start sc_step sc_run sc_explore`. |
| `scripts/fork_drift_manifest.txt` | `driver.lem` `[source-content]` `8862f4fb… → 6cd7333f…`; `driver.ml` `[expected-semantic]` `7f4a4646… → 65af28c8…`; NOTE at the top stating exactly what moved. |
| `scripts/LADDER.md`, `lean_frontend/CONTRACT.md` §3, `VALIDATION.md` lane table, `lean_frontend/CLAUDE.md`, `SC-CONCURRENCY.md` §6, the claims register, charter §10 | rows/notes/pointers; the charter gains §10 (factual corrections, below). |

`scripts/failure_reach_register.txt` is unchanged: see §5(c).

## 4. Checks and proofs

### 4.1 Kernel laws (`sc-step-test`, `Unit.SCStepProofs`; ∀ fuel instance, ∀ reader maps, ∀ configuration)

| Law | Theorems | Method |
|---|---|---|
| L1 budget | `sc_run_zero` (rfl), `sc_run_exhausted_transitions` (`= cfg.sc_transitions + n`), `sc_run_reductions_le_transitions` (relative form: both counters monotone along a run and Δreductions ≤ Δtransitions), `sc_run_reductions_le_transitions_from_start` (absolute corollary) | induction on the budget over the definitional `sc_run_succ` |
| L2 step/run | `sc_run_succ` (rfl: one `sc_step`, then `sc_run n` on its result), `sc_step_transitions` (+1), `sc_step_reductions` (≤ +1, monotone) | `sc_step_inr_shape` (which interpreter built the result) |
| L3 absorption/stability | `sc_step_final` (`= .inl SC_terminal`), `sc_run_stable` (`SC_stopped t` at `n` ⇒ at every `m ≥ n`) | induction |
| L4 chosen alternative | `sc_step_bad_choice_core/_lifecycle` (`i ≥ length` ⇒ `SC_bad_choice i length`, configuration unchanged), `sc_step_choice_required_*`, `sc_step_no_alternatives_*` (a choice where none is offered ⇒ `SC_bad_choice i 0`), `sc_step_chosen_core/_lifecycle` (the result is `sc_interpret_*` of ONE application of the chosen branch to the stored state — no other element of `alts` occurs on the right-hand side), `sc_step_chosen_core_state` (the result's state is that application's returned state), `sc_run_action_eq` | `unfold`/`simp` with the `listGetOpt` fact |
| L5 same handlers | `sc_perform_advance` (`= nd_bind (advance_step tid s) (fun _ => nd_return ())`), `sc_perform_pick` (`= nd_bind (pick (SK_misc ["new_drive_core_threads"]) steps) (process_core_step2 false noop)`) | `unfold; rw` |
| L6 events | `TraceGrows` (suffix), `sc_events_append` (`sc_events c₀ c₂ = sc_events c₁ c₂ ++ sc_events c₀ c₁` under `TraceGrows`), `sc_step_state_from_action`/`sc_core_transition_state` (a transition's state is exactly what the action it ran returned: the machine adds nothing), `TraceGrows_core_transition`/`TraceGrows_chosen_core`/`TraceGrows_lifecycle` (the trace grows whenever the action run is hereditarily monotone); the hereditary-monotonicity toolbox `HMono`/`HMonoD` (`HMonoD_bind` for every fuel, `HMonoD_liftND` for any inner action whose `put` keeps the trace — so `liftMem` of any, even opaque, memory action, `HMono_liftCore_run` of any core_run action, `nd_return/get/read/kill/update/print_debug/pick (non-empty)/mk_step/sc_boundary/spawn_thread/update_thread_state/get_thread_states`); the S1a handlers ARM BY ARM: `HMono_action_request_sequential2` (every request), `HMono_perform_action_request2`, `HMono_advance_step_{ccall,with_runstate,tau,action_request,blocked,thread_done,done,spawn_threads,nd (non-empty),memop_request (given the memop handler's monotonicity)}`, `HMono_process_core_step2_{action_request,memop_request,done,ccall}`, `HMono_perform_memop_request2_served` (every served memop arm is monotone; the only other arm is the INVALID-memop `failwithI` leaf, stated exactly), `HMono_sc_perform_advance/_pick` | induction on depth/fuel; the `hmono` arm tactic |

Scope statement for L6, stated plainly: the fail-stop arms (`Step_error2`, `Step_fs2` in
`advance_step`; the INVALID memop; `process_core_step2`'s WRONG STEP; `pick []`) are the opaque
`failwithI` leaves of the failure-reach register — the kernel has no equation for them and at
run time there is no next configuration — and the lifecycle text's arms selected by the runtime
thread-state shape (`ERROR (in Driver …)`) are of the same kind. They are excluded by
hypothesis, never proved around; a whole-transition `TraceGrows` theorem is therefore
conditional on the action run being one of the monotone arms (the composition theorems), which
every non-fail-stop S1a transition is. `drive_fs_step` (the filesystem, refused since
2026-09-28) is not stated.

Axiom cones (verbatim from the build log):

```
'SCStepProofs.sc_run_exhausted_transitions' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCStepProofs.sc_run_stable' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCStepProofs.sc_step_chosen_core' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCStepProofs.sc_perform_advance' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCStepProofs.sc_events_append' depends on axioms: [propext, Classical.choice, Quot.sound]
'SCStepProofs.HMonoD_bind' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Entry census (`check_theorem_axioms.sh`, verbatim): `'sc_start' depends on axioms: [propext,
Classical.choice, Quot.sound]` and the same for `sc_step`, `sc_run`, `sc_explore`;
`check_theorem_axioms: C2 entry census OK (13 entries, every cone ⊆ [propext, Classical.choice,
Quot.sound])`.

### 4.2 The differential lane (`scripts/test_sc_step.py`)

Tier A rows over `tests/sc-step` (the non-fixture programs: `unseq-calls.c`) + `tests/immaculate/nolibc`
+ `tests/minimal` + `tests/coverage` + `tests/debug` + `tests/float` (357 programs; test_exec.sh's
exclusions and `--nolibc`), budget 10,000,000,
row E fuel 1000, per-run bound 180 s, 16 jobs, verdict-line sequences compared in order.
Verbatim summary of the run at the final head (see §7 for the gate run):

```
[sc-step/unseq-calls] A=MATCH B=MATCH C=MATCH baseline=MATCH
test_sc_step tier-a (rows A-C, E, F): 357 programs; A:BOTH_FAILED=13,MATCH=344 B:BOTH_FAILED=18,MATCH=339 C:BOTH_FAILED=14,MATCH=328,MISMATCH=11,ONE_FAILED=4; SCUnsupported=0; C not required on 18 non-MATCH baseline rows; wall 230.5s
PASS test_sc_step tier-a (rows A-C, E, F) (budget 10000000, row E fuel 1000); Evidence: …/.tmp/sc-step/tier-a/report.json
```

Reading (derived from `report.json`): row A (Lean `sc_explore` vs Lean `drive`) MATCH on every
program that produces a verdict and BOTH_FAILED on the 13 programs where Lean `drive` itself
fail-stops (the immaculate `L=CRASH` rows and the two `.unsupported.c` refusals) — no
one-sided failure; row B (OCaml `sc_explore` vs the oracle) MATCH on every program the oracle
completes and BOTH_FAILED on the 18 oracle-crash rows (`CERB_SKIP`/`ORACLE_CRASH` baselines);
row C (Lean vs OCaml `sc_explore`) MATCH on every program whose owning baseline row is
MATCH/UB_MATCH, BOTH_FAILED on every `MATCH | L=CRASH` immaculate row, and reported without
requirement on the 18 rows the owning lanes record as cross-engine non-MATCH (5 `CERB_SKIP`
minimal, 4 `CERB_SKIP` debug, 3 `ORACLE_CRASH` + 6 `DIFF` immaculate) — the SC walk inherits
exactly the recorded cross-engine state, no more and no less. Row E: both fixtures OK at
budgets 0/1/2/7/4096 (+13/14 for `loop-glob.c`):

```
[row E loop-glob.c] OK b0=SCExhausted {transitions: 0, core_reductions: 0}; b1=SCExhausted {transitions: 1, core_reductions: 0}; b2=SCExhausted {transitions: 2, core_reductions: 1}; b7=SCExhausted {transitions: 7, core_reductions: 6}; b13=SCExhausted {transitions: 13, core_reductions: 11}; b14=SCExhausted {transitions: 14, core_reductions: 12}; b4096=SCExhausted {transitions: 4096, core_reductions: 4094}
[row E loop-nogl.c] OK b0=SCExhausted {transitions: 0, core_reductions: 0}; b1=SCExhausted {transitions: 1, core_reductions: 0}; b2=SCExhausted {transitions: 2, core_reductions: 1}; b7=SCExhausted {transitions: 7, core_reductions: 6}; b4096=SCExhausted {transitions: 4096, core_reductions: 4095}
[row F control par-control.c] OK
```

with `drive` at fuel 1000 ending in exactly `Error {msg: "lem: fuel exhausted"}` (rc 1) on
both fixtures, budget 0 performing no lifecycle effect (`SCMemory {next_alloc_id: 0, …}`), and
the memory line identical at every budget past the startup. Row F: `SCUnsupported=0` over
every program; the control prints `SCUnsupported {msg: "sc: fork (Step_spawn_threads2, Core
par): S1b"}` with exit 3 on both engines.

Row D (`--libc`, Tier B row 13; `tests/libc_exec/*.c` first-alternative, `exhaustive/*.c` exhaustive),
verbatim from the gate run:

```
[libc_exec/exhaustive/001-unseq-order-libc] A=MATCH B=MATCH C=MATCH baseline=MATCH
[libc_exec/exhaustive/002-errno-basic] A=MATCH B=MATCH C=MATCH baseline=MATCH
test_sc_step libc (row D): 43 programs; A:MATCH=43 B:MATCH=43 C:MATCH=43; SCUnsupported=0; C not required on 0 non-MATCH baseline rows; wall 90.9s
PASS test_sc_step libc (row D) (budget 10000000, row E fuel 1000); Evidence: …/.tmp/sc-step/libc/report.json
```

### 4.3 Preservation battery (charter §3.5 (a)–(d))

(a) Generated `driver.ml` diff against the pre-slice tree (the base tree regenerated with the
pinned lem before any edit): exactly the appended SC section plus, in `driver_globals` and
`drive`, these hunks — `driver2 with_concurrency` at the two call sites reads
`(fun () -> driver2 with_concurrency) ()`; `drive`'s globals call reads `(driver_globals
with_concurrency) file1`; the `val` signatures' type abbreviations spell
`Mem_common.thread_id`/`Mem.mem_iv_constraint` where the inferred types spelt `int`/the expanded
constraint type; lem drops the two definitions' interior comments on inlining. Frame names are
unchanged (`driver_globals`, `drive`). Reviewed hunk by hunk; the manifest NOTE states the same.

(b) Gates: §7. Zero new `scripts/upstream_oracle_differences.json` rows; no baseline moved.

(c) Oracle `-d 2` stderr, pre-slice binary (built from the base tree) vs post: `tests/minimal`
113/113 programs byte-identical after normalising the `[seconds]` pass-message timestamps
(control: two runs of the pre-slice binary differ in those timestamps on 113/113 files;
stdout and exit codes identical raw); `tests/libc_exec/012-global-alloc-order.c` (libc mode,
globals): identical after the same normalisation except one line present only in the pre-slice
run — `warning: read core_object file produced with a different version of Cerberus =>
…-52-g1864c6562-dirty+mem:concrete` — the pre-slice binary reading the `libc.co` the post
tree rebuilt (a version-string artefact of the working tree, not a driver change); the
per-call `ENTERING Driver.driver2` lines: 82 pre, 82 post (1 and 1 on
`tests/minimal/001-return-literal.c`). This is the WP1 failure mode that the thunk prevents;
plant P6 (§5) shows the count moving when the thunk is removed.

(d) `FuelExemplar.lean` (`fuel-exemplar-test`) and `CerbCall.lean` are untouched and build:
`FuelExemplar: exemplar_certified_shipped_zero … — kernel-checked at compile time` /
`FuelExemplar: exemplar_killed_at_one … — kernel-checked at compile time`.

## 5. Failure controls (charter §3.11 plants; each red, then reverted and green)

Each plant is a textual mutation of the slice's own source (applied to a copy-restored tree,
never a `git checkout`), regenerated on both engines, its detector run, then the original text
restored, regenerated, rebuilt and the detector re-run green. Verbatim summary lines of the
battery (`.tmp/s1a/plants/summary.txt`, `summary2.txt`; the driver.lem hash after every
restore is the pinned `6cd7333fbb10895c…`):

**P1 — an unchosen alternative is committed** (`sc_step`'s `SC_core_choosing` arm runs
`alts[0]` from the stored state before `alts[i]`). L4 fails to typecheck:

```
  [P1] laws build RED (expected):
error: test/Unit/SCStepProofs.lean:336:92: unsolved goals
```

(line 336 is `sc_step_chosen_core`). Lane witness: on `tests/minimal` 001–099 the plant is NOT
visible (`[P1] lane --only minimal/0 rc=0` — those programs have no saved-step pick whose order
is observable), so the lane gained the `sc-step` corpus with `tests/sc-step/unseq-calls.c`
(two unsequenced calls with distinct side effects; 40 exhaustive executions on the pre-slice
oracle, `Specified(23)`/`Specified(13)` in the pick order):

```
  [P1] lane --only sc-step/ rc=1 (expected 1):
[sc-step/unseq-calls] A=ONE_FAILED B=ONE_FAILED C=BOTH_FAILED baseline=MATCH
  sc-step/unseq-calls: row A ONE_FAILED (Lean sc vs Lean drive)
  sc-step/unseq-calls: row B ONE_FAILED (OCaml sc vs oracle)
  [P1] reverted: lane --only sc-step/ rc=0 (expected 0)
```

Reverted: `[P1] reverted: laws + driver GREEN (Build completed successfully (241 jobs).)`.

**P2 — two transitions counted per step** (`sc_advance` adds 2). L1/L2 fail to typecheck and
row E's figures are wrong:

```
  [P2] laws build RED (expected):
error: test/Unit/SCStepProofs.lean:47:0: Not a definitional equality: the left-hand side
error: test/Unit/SCStepProofs.lean:48:67: Type mismatch
error: test/Unit/SCStepProofs.lean:56:83: Tactic `rfl` failed: The left-hand side
  [P2] lane --only minimal/001 (+ rows E/F) rc=1 (expected 1):
[row E loop-glob.c] FAIL b0=SCExhausted {transitions: 0, core_reductions: 0}; b1=SCExhausted {transitions: 2, core_reductions: 0}; b2=SCExhausted {transitions: 4, core_reductions: 1}; b7=SCExhausted {transitions: 14, core_reductions: 6}; …
  row E loop-glob.c budget 1: transitions=2 core_reductions=0; expected transitions=1, transitions-core_reductions=1
  [P2] reverted: laws + driver GREEN
```

**P3a — `Step_done2` without `prepare_exit`** (the charter's literal plant: the exit step's
handler is skipped, the remainder resumes on the un-prepared state): NOT detected on the single
startup thread — `[P3a] lane --only minimal/0 rc=0` … `PASS test_sc_step tier-a` — see §9.2 and
charter §10 item 10. **P3b — the exit step does not hand control back** (the phase stays
`SC_core`): every program exhausts its budget and rows A/B go red:

```
  [P3b] lane --only minimal/001 rc=1 (expected 1):
test_sc_step tier-a (rows A-C, E, F): 1 programs; A:MISMATCH=1 B:MISMATCH=1 C:MATCH=1; SCUnsupported=0; C not required on 0 non-MATCH baseline rows; wall 12.2s
  minimal/001-return-literal: row A MISMATCH (Lean sc vs Lean drive)
  minimal/001-return-literal: row B MISMATCH (OCaml sc vs oracle)
  minimal/001-return-literal: SC-specific record in a run-to-completion row: SCExhausted {transitions: 10000000, core_reductions: 9999999}
  [P3] reverted: driver GREEN
```

**P4 — the SC refusal reported under another class** (`sc_refuse` builds `SC_blocked`): the
control row goes red on both engines:

```
  [P4] lane --only minimal/001 (+ control row) rc=1 (expected 1):
[row F control par-control.c] FAIL
  row F control par-control.c: expected 'SCUnsupported {msg: "sc: fork (Step_spawn_threads2, Core par): S1b"}' + exit 3 on both engines; OCaml rc=3 [b'SCBlocked {}'], Lean rc=3 [b'SCBlocked {}']
  [P4] reverted: both engines GREEN
```

**P5 — lane vacuity.** Comparison level: the lane's `--selftest` (23 hermetic plants: a
doctored verdict value, a doctored `stderr` field, swapped order, a dropped execution, a
changed exit code, one-/both-sided failures, model fail-stop records, row E figures/memory/
budget-0/fuel-kill/drive-kill/startup boundary, baseline parsing) — `test_sc_step: SELFTEST
OK (23 plants: …)`. Engine level: the OCaml probe's `Defined` record with a doctored `stdout`
field:

```
  [P5] lane --only minimal/001 rc=1 (expected 1):
[minimal/001-return-literal] A=MATCH B=MISMATCH C=MISMATCH baseline=MATCH
  minimal/001-return-literal: row B MISMATCH (OCaml sc vs oracle)
  minimal/001-return-literal: row C MISMATCH on a MATCH baseline row (Lean sc vs OCaml sc)
  [P5] reverted: lane --only minimal/001 rc=0 (expected 0)
```

**P6 — WP1's value-passing instead of the thunk**: the per-call `ENTERING Driver.driver2` lines
of check (c). Two lessons before the plant went red. (i) With ONE global the count cannot move
(`[P6] tests/minimal/020-global-var.c: ENTERING Driver.driver2 lines pre=2 planted=2 …;
normalised stderr IDENTICAL` — charter §10 item 9). (ii) Passing the VALUE through the
`let inline` functions is not WP1's mechanism either: lem's inline is substitution (call by
name), so `run_threads` is re-evaluated at each use and nothing is lost even with two globals
(`[P6] tests/minimal/081-unseq-diff-locations.c (globals: 2): ENTERING Driver.driver2 lines
pre=3 planted=3; normalised stderr IDENTICAL`). WP1's shape is a REAL function taking the
action value (call by value, built once); planted as such (P6') the count drops with two
globals and, even with one, the line moves ahead of `HELLO from Smt2.runND` (built when `drive`
is applied, not when the round runs):

```
  [P6'] tests/minimal/081-unseq-diff-locations.c (globals: 2): ENTERING Driver.driver2 lines pre=3 planted=2; normalised stderr DIFFERS; stdout identical
      165d164
      < (debug 2): HELLO from Smt2.runND, exec mode= exhaustive
      166a166,167
      > (debug 2): ENTERING Driver.driver2
      > (debug 2): HELLO from Smt2.runND, exec mode= exhaustive
  [P6'] tests/minimal/020-global-var.c (globals: 1): ENTERING Driver.driver2 lines pre=2 planted=2; normalised stderr DIFFERS; stdout identical
  [P6'] reverted tests/minimal/081-unseq-diff-locations.c: ENTERING lines pre=3 restored=3; normalised stderr IDENTICAL
```


## 6. Cost

- Lane wall: Tier A rows 230.5 s inside the ladder run (`PASSED A14 (230.6s)`; 16 jobs; the
  largest program, `tests/immaculate/nolibc/zd-funptr-call-control.c` with 60,104 exhaustive
  executions, takes ~105 s through the Lean SC walk; an earlier stand-alone run with 8 jobs took
  344 s and with 16 jobs 293 s before the corpora were ordered longest-first); libc row
  90.9 s (`PASSED B13 (91.1s)`). Q4 placement: measured under ~4 min → Tier A row 14 (the libc row Tier B 13)
  as the LADDER rows state; the margin is thin and rests on 16 parallel jobs.
- Builds: `make prelude-src` ≈ 62 s, `make lean-prelude-src` ≈ 62 s; `Driver.lean` compiles in
  2.8 s; the laws (`sc-step-test`) in ≈ 30 s; the OCaml probe links in the ordinary dune build.
- Retained sizes on the row E fixtures (S1d's baseline, Lean; verbatim `SCMemory` lines):
  `loop-nogl.c` budget 0 `SCMemory {next_alloc_id: 0, last_address: 281474976710655, trace_events: 0}`,
  every budget ≥ 1 `SCMemory {next_alloc_id: 1, last_address: 281474976710648, trace_events: 0}`
  (errno only, allocated by `drive`'s lifecycle text through `liftMem` — no trace event; the
  loop allocates and traces nothing); `loop-glob.c` budget 7 `SCMemory {next_alloc_id: 1,
  last_address: 281474976710648, trace_events: 1}`, every budget ≥ 13 `SCMemory {next_alloc_id:
  2, last_address: 281474976710644, trace_events: 2}` (the global's create and store are the two
  retained trace events). The retained trace is thus O(memory actions), not O(transitions), on
  these fixtures. Peak RSS of the Lean process on the 40,320-execution probe `u8` (§9.1): drive
  182 MB, SC 186 MB (equal).

## 7. Gates (verbatim verdict lines)

Final run on the committed source (`release.py --mode fast`, evidence `.tmp/s1a/gates/tier-a/report.json`,
deleted after this record): `rc=0 wall=876s`, `status: passed | lanes: 18 | unrun: 32`:

```
PASSED A1 (238.7s) PASSED A2 (30.8s) PASSED A3 (77.7s) PASSED A4 (25.5s) PASSED A4b (27.0s) PASSED A4c (3.6s) PASSED A5 (106.9s) PASSED A6 (4.2s) PASSED A6b (3.8s) PASSED A7 (11.2s) PASSED A8 (9.8s) PASSED A9 (17.3s) PASSED A10 (17.5s) PASSED A11 (59.0s) PASSED A12.1 (5.2s) PASSED A12.2 (4.5s) PASSED A13 (0.9s) PASSED A14 (230.6s)
```

Row 1 (`test_unit.sh`) verdict lines, verbatim:

```
✓ sc-step-test PASSED
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
test_sc_step: SELFTEST OK (23 plants: token order/length/whole-line/exit-code, one-sided and both-sided failures, an SC record against a verdict, model fail-stop records (equal/unequal/against a crash/against a verdict), row E figures/memory/budget-0/fuel-kill/drive-kill/startup boundary, baseline parsing incl. the immaculate CRASH class)
check_fork_drift: OK — layer 1: 86 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 31 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 matches lem -v c2a68e7 (hex prefix))
check_failure_reach: OK (230 pure failure sites = the 230 register rows exactly (228 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=170 REACHABLE=39 UNKNOWN=21; every row sealed; tally line consistent)
check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (…), 13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
gen_fuel_parametricity: OK (14 ambient fuel wrappers in the generated tree = the 14 pins of TotalityProofTest.lean Part 1, both directions)
check_no_fuel_numerals: OK (332 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy))
check_lem_sync: OK (src 43e2049aa1afc7c59f6c33148fc65ef4fdc46d7ab9550529846a6db06e9cbddc, gen 908adc459c488939a0f376b54ed3d9e2e7ed1cafc0b4756dce9ed73128772e02)
check_pin_sites: OK — lem-pin c2a68e79b6369e19f099dfa48767319c1daf19b3 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
check_cli_refusals: OK (3 refused flags pinned: --concurrency, --switches=PNVI_ae_udi, --switches=strict_pointer_arith; control not refused)
```

A first Tier A run (same source but for one line) had `FAILED A1 (209.8s)`: the
`check_no_fuel_numerals.sh` allowlist pins Main.lean's `letI` line by exact text and the
`--sc-run` edit had put `scRun` on that line; moved to the continuation line (no semantic
change), the ladder was re-run in full — the lines above are the re-run's.

Tier B rows 4, 5, 7, 10 (+13) (`release.py --mode full --lane B4 --lane B5 --lane B7 --lane B10 --lane B13`;
the runner's `status: incomplete` names the unselected Tier B rows — a `--lane` selection is a subset,
never a tier certification; every selected row passed). `scripts/upstream_oracle_differences.json`
is byte-unchanged by this slice (`git diff --quiet` on it), so row 10's 7 `reviewed_difference`
are the pre-existing register rows and there are ZERO new ones. Whole battery: 2722 s.

```
PASSED B4 (49.5s) PASSED B5 (99.5s) PASSED B7 (1432.8s) PASSED B10.1 (169.1s) PASSED B10.2 (2.0s) PASSED B13 (91.1s)
B4    test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
B5    OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE…)
B7    Baseline check: 0 regression(s), 0 improvement(s)
      gcc second-oracle lane OK
B10.1 Independent oracle: passed; {'semantic_agreement': 946, 'matching_failure': 33, 'reviewed_difference': 7, 'interface_agreement': 2}
B10.2 Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}
B13   test_sc_step libc (row D): 43 programs; A:MATCH=43 B:MATCH=43 C:MATCH=43; SCUnsupported=0; C not required on 0 non-MATCH baseline rows; wall 90.9s
      PASS test_sc_step libc (row D) (budget 10000000, row E fuel 1000)
```


## 8. Sequential effects

None observable: rows A–C, the pinned baselines (unmoved), the pristine-oracle gate (row 10,
zero new register rows), the `-d 2` byte identity (§4.3 c) and `fuel-exemplar-test` all hold.
The generated `driver.ml`/`Driver.lean` text of `driver_globals` and `drive` changes as listed in
§4.3 (a); the OCaml frame names do not.

## 9. Findings and remaining limits

1. **Lean SC exploration is slower than `drive` on large exhaustive sets** (measured, not
   explained): per-transition cost is equal (a 20,000-iteration deterministic loop: Lean `drive`
   6.35 s, Lean SC 6.41 s; OCaml probe 5.6 s vs oracle 2.1 s — the probe's excess is the
   10^7-element budget list, §9.4), and small exhaustive sets are comparable (758 executions:
   0.14 s vs 0.21 s; 5,040 executions (`f()+…+f()`, 7 unsequenced calls): 0.80 s vs 0.85 s), but
   40,320 executions (8 calls): 6.6 s vs 23.2 s, and `zd-funptr-call-control.c` (60,104
   executions): 14.3 s vs 105–112 s, budget-independent (100,000 vs 10,000,000), same peak RSS
   (182 vs 186 MB), single-trace `--sc-first` 0.03 s = `--first`. The OCaml probe shows no such
   effect (`u8`: 2.0 s; the oracle 0.07 s on the 758-execution probe vs 3.56 s probe = the
   budget-list cost). `perf` is unavailable in the sandbox; the cause is open. S1d's mover
   (scale) or a profiled fix before S1b; the lane's per-run bound is 180 s because of it.
2. **`prepare_exit` is not observable in S1a** (plant P3a): on the single startup thread the
   exit step's `prepare_exit` (keep thread 0, empty stack, arena `:= mk_value_e cval`) changes
   nothing `finalize` reads, so the charter's literal P3 ("`finalize` raises `BOOM finalize`")
   cannot go red before S1b; the lifecycle plant that does go red is "the exit does not resume
   the remainder" (P3b).
3. **lem-lean backend**: `declare {lean} skip_instances` does not suppress the variant/record
   `deriving BEq, Ord` clause (emitted whenever no payload is syntactically a function type), so
   skipping the instances of a type whose payload type is itself skipped fails to compile
   (`BEq sc_terminal`). Charter §10 item 3; a lem-lean issue to file (no pin move here).
4. **OCaml budget list**: `Lem_list.replicate 10^7 ()` costs ≈ 3.5 s per probe run (the
   `structural val` fallback shape, charter R2/§10 item 2). Lean's `List.replicate` is cheap. A
   nat-structural backend form would remove it (lem-lean).
5. **Alternatives' labels** are the pick's `info` (one label repeated), charter §10 item 5;
   informative labels need a data representation of the node (S1b/S5).
6. Named obligation carried forward (charter §3.7/R8): the lifecycle remainder is a closure;
   it becomes data before WP-C's execution-fidelity proof or S5.
7. Not proved: `runND (drive …) = sc_explore` (WP-C); the fail-stop arms' monotonicity (no
   kernel equation, §4.1).

## 10. Provenance

[USER 2026-09-30] "Agree on recommendations, go ahead" (charter §8: Q1 factoring with the §3.5
battery and the gate-entry additions; Q3 the internal `--sc-run --sc-budget N` flag; Q4 Tier A
if measured under ~4 min, libc row Tier B; Q5 `SK_misc` tag). Everything else here is [AGENT]:
the implementation choices of charter §10, the lane's parameters (budget 10^7, fuel 1000, bound
180 s), the plant variants P3a/P3b and P5-engine, the tier placement from the measurement.
