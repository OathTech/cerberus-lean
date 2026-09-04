# Concurrency Phase 0 charter — the SC instance of a parametric model (2026-09-04)

Status: APPROVED [USER 2026-09-04] ("yes, approve all decisions, go ahead"):
D1–D6 are approved as recommended in §10 (D3 explicit threading; D4
end-of-trace default + per-step behind a debug flag; D5 consumer review of
§4.1/§4.6 gates S1; D6 BMC oracle deferred to Phase 1). Was: PROPOSED, for
operator sign-off before any code (the design-pass rule; brief
`2026-09-04_concurrency-feature-branch-brief.md` Phase 0 task 3).
Branch `feature/concurrency`, worktree
`worktrees/cerberus-lean-feature/concurrency`, base `mdd/cerberus-lean` @
`1b57bcf26`. Author: the concurrency-branch agent [AGENT]. Inputs: the
scoping note `2026-09-04_concurrency-scoping.md`, the brief, the
2026-08-19 parametricity principle and the 2026-08-26 rescoping (both in
the archives, cited in the scoping note §1), and the operator's direction
of 2026-09-04 (§1 below, verbatim). Everything measured below was
measured in this worktree today; every design point is [AGENT] unless
marked [USER].

## 0. One paragraph

Phase 0 does NOT resurrect the C11 operational path. It makes the
concurrency model a PARAMETER of the executable driver and lands ONE
instance: sequentially consistent interleaving over the concrete memory
model, restricted to the fragment of C11 where the standard's own DRF-SC
guarantee makes SC *the* semantics (non-atomic accesses, `seq_cst`
atomics, locks; data race = UB), refusing loudly outside it. The instance
is a named member of the model family the tree already carries
(`cmm_csem.lem:2564-2596` `SC_condition`/`SC_memory_model`), so it is
not an outsider model; its operational form is trivial (the interleaving
IS the commitment order), so it needs no symbolic values and no
constraint layer; and every trace it produces is checked, in-run,
against the library's own SC consistency and data-race predicates — an
executable bridge to the axiomatic side. The model-independent work that
any later instance needs (scheduler live, edges, RMW/fence/cmpxchg
reduction, the litmus lane, the parameter surface, the reasoning-surface
cleanups) is done here once. The C11 operational instance, RC11 and LKMM
are Phase 1–2 and are deliberately NOT designed here (§5).

## 1. Ruling and rationale ([USER 2026-09-04], verbatim)

> "One way of approaching this would be to make the executable memory
> model parametric, and initially support just an SC / strongly
> interleaved semantics. This is very easy to implement, and would
> support formal verification via Iris. It's an artifical model so the
> trick would be building it so that we *don't* commit to it as the long
> term path. I'm more scared of rushing into the weak memory semantics
> because it seems like there are a lot of subtle design questions there
> and it's going to be hard to figure out if we're even directionally
> right"

> "Great, let's approach it this way. I think even landing a working SC
> model on main would be a major success (and would let us start matching
> refined-cerberus to the model structure, and debugging the reasoning
> surface). I take your point about iris / refined-cerberus. This is
> something we should handle carefully"

[AGENT] reading: (a) parametric model, SC instance first; (b) landing SC
on main is the Phase-0 success criterion; (c) the SC instance must be
built so it does not become the long-term path by default; (d) the
Iris/refined-cerberus coupling is handled with explicit care (§8). This
is also a return to the [USER 2026-08-26] rescoping ("lock-invariants +
schedule-streams face + lem-generated C11 model; weak-memory logic
deferred as its own future program").

## 2. Measured state — the "before" (this worktree, primed mainline binaries)

### 2.1 FINDING: parallel programs are silently serialized today, on both engines

Three probe programs (container scratch `.tmp/conc-probe/`, ephemeral;
they become `tests/litmus/` fixtures in S0) run through the oracle
(`--nolibc --exec --batch --mode=exhaustive`) and the Lean pipeline
(`--cabs-json` → `cerberus-lean --batch`), verbatim outputs:

| Probe | Program shape | Oracle exhaustive | Lean batch |
|---|---|---|---|
| `sb_sc.c` | SB, two `seq_cst` stores then loads, `{-{ ‖ }-}`, returns `r1 + 2*r2` | `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` | identical |
| `mp_na.c` | `x = 1` ‖ `r = x`, both NON-atomic (a data race), returns `r` | `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}` | identical |
| `lb_rlx.c` | LB with `relaxed` loads/stores, returns `r1 + 2*r2` | `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}` | identical |
| `sb_sc.c` with `--concurrency` | — | `internal error: CONCURRENCY IS BROKEN` (Failure, uncaught) | flag refused (Z-24) |

Under SC the first probe has three outcomes {1, 2, 3}; under C11 the
third has four {0, 1, 2, 3}; the second is UB (data race). Both engines
report ONE Defined value and no UB. Cause (`frontend/model/driver.lem`):
`can_advance` :907-935 treats `Step_action_request2`/`Step_memop_request2`
as advanceable (:914-916, :925-927, each under the upstream comment
`(* TODO: only correct if there is only ONE thread *)`, with the value
`(* false *)` commented beside it), so the per-thread inner loop
`drive_nonmemory_steps_aux2` :1062 performs memory actions eagerly and
runs each thread to completion or block; the scheduler `driver2` :1369
then only ever sees done/blocked steps. This is the "degenerate
scheduler" the consumer's DECISIONS register describes for the
sequential fragment; for parallel programs it is a FAIL-OPEN behaviour
(a fixed serialization presented as an exhaustive verdict, no refusal),
i.e. a defect under the container rules independent of any concurrency
ambition. The zero-discrepancy rule is not violated (both engines agree)
— the shared `.lem` is wrong the same way on both.

### 2.2 What exists (delta to the scoping note §1, all measured)

- The annotation plumbing for the pre-execution edges survives:
  `core_run_aux.lem:17-22` (`core_run_annotation` with `sb_before`,
  `dd_before`, `asw_before`), `add_to_sb` :340, `add_to_asw` :427,
  `add_to_asw_stack` :494 — all guarded by `Global.using_concurrency ()`
  (:342, :411, :429, :494); `Core_run.kill_thread` :90 still takes the
  asw set. The 2019 reduction-context rewrite (upstream `0df8708ad`)
  dropped the edge sets from the action requests
  (`core_reduction.lem:118-121`, the commented tuple) — they must be
  re-threaded from the annotations. `dd_before` was `{} (* TODO *)`
  even in the working era (upstream `0df8708ad^` core_run.lem:271).
- Core reduction refuses the non-load/store atomics with TODO errors:
  `core_reduction.lem:799-814` (`RMW`, `Fence`, `CompareExchangeStrong`,
  `CompareExchangeWeak`, `LinuxFence/Load/Store/RMW`). The C front end
  elaborates them (`translation.lem:1182-1273`, `:2543`); memory orders
  come from constant arguments only (`translate_memory_order`).
- The historical concurrency path (upstream 2014–2017, e.g. `2b36d1978`
  "concurrency is working", 2016-03-24) ran on the SYMBOLIC memory
  model plus SAT solving: loads returned a fresh symbol
  (`Mem.concurRead_ival`), threads ran ahead on it, and the model's
  `ReadsFrom` commitment added an equality constraint. Under the
  concrete model that constructor is `failwith "TODO: concurRead_ival"`
  (`memory/concrete/impl_mem.ml:2361-2362`) and a mirrored panic
  (`CerbMem.lean:1390-1396`). This is why the C11-op instance is NOT
  Phase 0 (§5).
- Axiomatic library, generated to Lean today: `SC_condition` :2564
  (actions restricted to `NA`/`Seq_cst` loads/stores, `Seq_cst` RMW,
  locks; fences/alloc/dealloc excluded), `SC_memory_model` :2584
  (`sc_accesses_consistent_execution` :2077 as the consistency tree,
  `release_acquire_relations` :1694 computing hb, `locks_only_undefined_
  behaviour` :1440 = unsequenced races + `data_races` :1431 +
  indeterminate reads + bad mutexes). Generated status: `Cmm_op.lean`
  0 `partial`, 1 `failwithI`; `Cmm_csem.lean` 2 `partial`
  (`apply_tree` :777, `apply_tree_fp_aux` :2361 — recursion over the
  predicate tree, structural) and 75 `failwithI` residuals (incomplete
  patterns on the relation-list shapes, e.g. `("hb",hb)::_`); the 23
  unreferenced `sorry` target_reps are the `*_behaviour` functions,
  which have `{hol; isabelle; tex}`-only bodies (no OCaml body either).
- Litmus corpora in tree: `tests/popl/{cppmem,section4}` (13 Core files);
  `tests/bmc/concurrency/` (litmus 38 C+Core with `allowed/` 11 and
  `forbidden/` 7 splits, `linux-no-rcu` 10, `linux-rcu` 22, RC11
  variants under `#if __memory_model_rc11__`); upstream's deleted
  `tests/concurrency/` (29 files at `9efe31119^`, 2017-04-27) whose
  expected outcome SETS survive in the fork's
  `backend/common/tests.ml:77-89` (e.g. `LB+rlx_rlx+rlx_rlx.core
  [0; 1; 2; 3]`, `datarace+Wna+Wna.core [] [Data_race]`).
- Second-oracle candidates: `backend/bmc/` (14,905 lines, z3, C11/RC11/
  Linux modes; NOT built — needs the z3 opam binding); herd7 and cvc5 are
  NOT installed; `/usr/bin/z3` is.
- Lean ND runner: `CerbND.lean:6-27` documents `NDguard`/`NDbranch` as
  unreachable by construction; the SC instance keeps them unreachable
  (no constraints), which is a property S3's plant must re-verify.
- Consumer: every refined-cerberus production statement is stated over
  `drive fmapEmpty false …` (their README :611-616); `using_concurrency`
  is reached by 11 of their exports through the shipped driver's code.
  Changing `drive`'s signature is a consumer-visible break (§8).

## 3. Scope — the SC-DRF instance, defined

**Fragment F_SC** (the instance's domain; everything outside is a loud
refusal, never an approximation):
- Threads: Core `Epar` (C `{-{ … ||| … }-}`), `Ewait`, thread done.
- Memory actions: `create`/`alloc`/`kill`; non-atomic `load`/`store`;
  atomic `load`/`store` with `mo = Seq_cst` ONLY; `rmw`/`compare_exchange_
  {strong,weak}` with `Seq_cst` ONLY (S4); locks IF Core exposes them
  (to be measured in S0; otherwise out of F_SC with a note).
- Excluded (refused): every other memory order (`relaxed`, `consume`,
  `acquire`, `release`, `acq_rel`); fences of any order (excluded by
  `SC_condition` itself); the `Linux*` actions.

**Semantics of the instance**: the set of outcomes of all interleavings
at memory-action granularity, executed against the concrete memory model
(the read value is the value in memory at issue — in SC this IS the
value of the most recent write in the interleaving); a trace whose
candidate execution has a data race (library predicate) is UB005
(data race); unsequenced races stay the sequential machinery's business.

**Why this is C11 and not an artificial model inside F_SC**: the DRF-SC
theorem for the SC-atomics fragment (Batty, Owens, Sarkar, Sewell,
Weber, "Mathematizing C++ concurrency", POPL 2011) — race-free programs
in F_SC have exactly their SC behaviours; racy ones are UB. The instance
reports the SC behaviours and detects the races on SC executions, which
is the theorem's own hypothesis check.

**Why it does not commit us**: (i) the model is selected by a value of
a model-selector type, not a bool; (ii) the driver builds the same
event-level structure the operational C11 model consumes (a
`pre_execution` via `Cmm_op.symUpdatePreEx`-shaped steps, `cmm_op.lem:
637-677`) plus an `execution_witness`; (iii) the SC instance is checked
against the library's SC model rather than defining "SC" itself; (iv) the
one place the interface shape favours SC — read values available at
issue — is RECORDED as the known non-parametric point with mover =
Phase 1 (§4.6), not silently assumed.

## 4. Design

### 4.1 The parameter surface

- New `.lem` type (driver-level, generated to both targets):
  `concurrency_model = | CM_sequential | CM_sc` (Phase 1 adds
  `CM_c11op …`). `CM_sequential` = today's single-thread driver, and a
  program that spawns threads under it is REFUSED with a typed driver
  error (`DErr_concurrency "…"` already exists, `driver.lem:58`) —
  closing the §2.1 fail-open. `drive` takes the selector instead of
  `with_concurrency: bool` (`driver.lem:1727`); `driver2`/
  `process_core_step2`/`perform_action_request2` thread it (they already
  thread the bool: :1321-1432, :747).
- CLI: oracle `--concurrency` (main.ml:496-498, cmdliner flag; its own
  comment asks "is this flag being used?") becomes `--concurrency=sc`
  (an enumerated option; bare `--concurrency` refused with the list);
  `driver_ocaml.ml:14,158,200,264` carry the selector. Lean `Main.lean:
  1068-1069` un-refuses exactly `--concurrency=sc`. A bool that means SC
  today and C11 tomorrow is the commitment we are avoiding.
- `Global.using_concurrency ()` (global.lem:38-41; reads in
  core_run_aux.lem :342,:411,:429,:494) becomes the selector threaded as
  a parameter — the reasoning-artifact audit's instance A step 2 for this
  constant, assigned to this branch by the brief. Mechanism: explicit
  threading through `Core_run`/`Core_reduction`/`Core_run_aux`
  signatures in the `.lem` (both targets by generation; no lem-lean
  work). OPEN (§10 D3): whether to use the lem-lean reader-lift
  mechanism instead, if it generalizes beyond `tagDefs`.

### 4.2 The scheduler

Under `CM_sc`, `Step_action_request2` and `Step_memop_request2` are NOT
advanceable in the inner loop (`can_advance` :914-916, :925-927 → `false`
under the selector; `CM_sequential` keeps today's values so the
sequential battery cannot move). Each thread's pending memory action is
its saved step; `driver2` :1369 picks among threads (`ND.pick` — plain ND
branching, exhaustively enumerated by both runners) and performs the
picked action via `process_core_step2`. No fuel changes: `driver2` is
already the fuelled outer loop; interleaving is ND width, not depth
(No-magic-values: nothing numeric is introduced).

### 4.3 Execution construction

Alongside the concrete-memory effects, the instance builds a candidate
execution deterministically from the interleaving: actions carry
concrete values (`Cmm.Load aid tid mo loc v` etc.); `sb`/`asw` from the
re-threaded annotations (`dd` stays empty, as upstream always had it —
recorded); `rf` = the most recent same-location write in interleaving
order (for non-atomic reads the library's `det_read`/`consistent_non_
atomic_rf` then hold or the trace is racy); `mo` and `sc` = the
interleaving order restricted to same-location atomic writes / to SC
actions; `lo` for locks if in F_SC. Where it lives: the existing
`concurrency_state: Cmm_op.symState` field (`driver.lem:67`) — the
pre-execution in `symPre`, the witness in `symWit`, the interleaving
order as `symCommitted` — so Phase 1's operational instance uses the
same state.

### 4.4 The in-run bridge check and the race verdict

At trace end (`finalize` :1472; per-step is affordable on litmus but not
in general — end-of-trace is the default, per-step behind a debug flag
is OPEN §10 D4): evaluate `apply_tree sc_accesses_consistent_execution`
on the constructed candidate execution. It MUST hold on every trace the
instance produces; a failure is an internal error (fail-noisy), never a
pruned trace — that is the executable bridge from the interleaving
instance to the axiomatic SC model, plant-tested in S3 by corrupting
`rf`. Then `data_races` (`cmm_csem.lem:1431`, over the library's hb =
`release_acquire_relations`): non-empty ⇒ the trace's outcome is
`Undefined UB005_data_race` (the historical `drive` tail did exactly this,
upstream `0df8708ad^` driver.lem:1677-1690). Unsequenced races are not
re-derived from the library — the sequential machinery already owns them.

### 4.5 Refusals (the fail-closed boundary of F_SC)

- A thread spawn under `CM_sequential`: typed driver error.
- A non-`Seq_cst` memory order on any atomic action under `CM_sc`:
  typed driver error naming the order (`SC_condition` is the reference
  list). Consequence for the probes: `lb_rlx.c` is REFUSED under `CM_sc`,
  not run — the measured `Specified(1)` disappears rather than being
  "matched".
- `Fence`/`Linux*`: typed driver error (they are outside `SC_condition`).
- `--concurrency` bare or with an unknown model: CLI refusal on both
  sides, with the list.

### 4.6 The recorded non-parametric point

The instance obtains a load's value at issue from the concrete memory.
The C11 operational instance cannot (its value is fixed when the read is
COMMITTED, possibly later). The interface therefore does NOT yet admit
deferred values; Phase 1 owns the design (symbolic value, re-execution,
or a different thread-side protocol). This is written into DESIGN.md's
model section as a temporal boundary with mover = Phase 1, so a reader
of the parameter surface cannot mistake `CM_sc`'s shape for the general
one. Designing deferral now would be the weak-memory design work the
ruling defers.

### 4.7 Reasoning surface (what the consumer will see)

- `drive` gains a total, kernel-transparent selector argument; a theorem
  quantifies over it or fixes `CM_sequential`/`CM_sc`.
- `using_concurrency` leaves the opaque census (one fewer process-state
  read on the exec cone).
- `CerbConcurrency.lean` (`statically_satisfied := true`, the temporal
  boundary) — the referencing declare is `cmm_csem.lem:655`; S5 measures
  whether the SC path reaches it and either gives it a real body or
  deletes the stub with the declare (reasoning-artifact audit row I).
- The 23 `sorry` target_reps: `{hol;isabelle;tex}`-only functions with no
  executable body on any target; S5 replaces the Lean `sorry` reps by a
  loud refusing rep or excludes the vals from the Lean target — whichever
  the lem-lean backend supports today without a lem change (the lem-side
  "refuse a `sorry` rep" item is TODO 229-234; this branch must not block
  it).
- The Cmm modules join the totality-gate slice (`check_exec_totality.sh`
  EXEC_MODULES) with the two `apply_tree` partials totalized
  (structural recursion on the tree — `declare {lean} termination_
  argument … = automatic` if the backend accepts it, else the fuel
  mechanism per the fuel-parameter rules); the 75 `failwithI` residuals
  are pattern-incompleteness on relation-list shapes and stay unless
  reached — the SC path's reach is measured in S3 and any reached one is
  a finding.

## 5. Non-goals (Phase 0 refuses, does not approximate)

Non-SC memory orders; fences; the Linux atomics/LKMM; symbolic read
values, constraints, any solver; the C11 operational instance and its
`symStep` commitment machinery (present, generated, untouched); RC11;
partial-order or other state-space reduction; porting the Isabelle
equivalence; any consumer-side (Iris) rule or adequacy work (§8);
`dd` (data dependence) edges.

## 6. Slices (one coherent commit each; FAST-GATE = Tier A; FULL = Tier A+B per LADDER.md)

| # | Slice | Content | Gate | Size |
|---|---|---|---|---|
| S0 | Corpus + "before" pins | `tests/litmus/` with the SC subset of the recovered upstream set (Core, expectations from `tests.ml`), the bmc `allowed/`/`forbidden/` C files that are in F_SC, the §2.1 probes; a lane script `scripts/test_litmus.sh` (both engines, outcome SETS compared to each other and to the expectation file; fail-closed; vacuity plant) that today RECORDS the serialized verdicts as the "before" baseline. Measure whether Core exposes locks. No `.lem` change. | lane self-test + plant; Tier A unchanged | S |
| S1 | Parameter surface | `concurrency_model` type; `drive`/driver family take it; `CM_sequential` refuses spawns; CLI on both sides; `Main.lean` un-refusal of `--concurrency=sc`; `using_concurrency` → threaded selector. Behaviour under `CM_sequential` byte-identical to today for the sequential corpora. | FULL (signature + `.lem` bodies changed; cache-disabled regeneration per certification rule) | S–M |
| S2 | Scheduler live | `can_advance` selector-dependent; interleavings enumerated; probes yield SC sets on both engines. | Tier A + litmus lane (SC loads/stores) | S |
| S3 | Execution + bridge + races | Edge re-threading; execution construction; end-of-trace SC consistency check (plant: corrupt `rf` → internal error); `data_races` → UB005; refusals for non-SC orders/fences; NDguard-unreachable re-verified. | FULL + litmus lane incl. `datarace+*` rows | M |
| S4 | RMW / cmpxchg | Reduction rules for `RMW`, `CompareExchange{Strong,Weak}` at `Seq_cst` (mirroring the elaboration's expectations; OCaml gets them by generation); `RMW-{strong,weak}-{equal,unequal}` rows. | Tier A + litmus | M |
| S5 | Reasoning surface | §4.7 items; opaque/totality census re-pins with reasons; DESIGN/VALIDATION/README "model" sections; the §4.6 boundary entry; TODO updates; upstream-tray draft ("`--concurrency` is broken; the fork's SC instance"). | FULL | S–M |
| S6 | Merge readiness | Rebase over whatever sequential arcs landed; change manifest; consumer note (§8); "mergeable" record; STOP. | FULL, re-run after rebase | S |

Estimated total M–L, in line with the scoping note's Phase 0 price; the
saving vs the note is the absent symbolic/constraint layer, the cost
added is the bridge check and the parameter threading.

## 7. Sequencing against the sequential close-out

- `make lean-prelude-src` FAILS in this tree until C1 merges (the five
  numeric fuel declares vs lem `742506d`; brief "Environment caveat").
  S0 needs no regeneration and starts now. S1–S5 change `.lem` and wait
  for the orchestrator's C1 announcement + rebase. Design writing for
  S1/S3 proceeds meanwhile.
- Expected textual collisions (scoping note §4): `driver.lem` different
  hunks (C1/C2 touch :1915-1918; we touch :58, :745-760, :907-935,
  :980, :1321-1432, :1472-1530, :1727, :1884-1890); `Main.lean` one line
  in the flag loop; `CerbGlobal.lean` (`using_concurrency`) — we own
  A-step-2 for it only.
- Lanes: the sequential battery must show ZERO movement at every slice
  (concurrency off = `CM_sequential` = today, minus the spawn refusal,
  which no lane corpus exercises — verified by grep in S0 and by the
  battery). Any movement is a finding, not a re-baseline.
- Box discipline per the brief: capped, serial lanes, never concurrent
  with a sequential worker's battery.

## 8. refined-cerberus coordination ([USER]: "handle carefully")

What changes for them, and the proposed handling:
1. `drive`'s signature (bool → selector) breaks their pin at re-pin
   time; every production statement carries `drive fmapEmpty false`.
   Handling: announced in the S6 change manifest with the one-token
   rewrite (`false` → `CM_sequential`); their re-pin is a
   forced-semantics-change slice on their side, scouted as their practice
   requires. We do not pre-adapt their code.
2. Their scheduler-degeneracy reading (DECISIONS register, 2026-09-03:
   "the scheduler is degenerate, we never see schedule changes") stays
   TRUE under `CM_sequential` and becomes false under `CM_sc`. Handling:
   stated explicitly in the manifest.
3. The commitment risk lives on their side: Iris's stock heap and a
   stable points-to are SC-specific. Handling (proposal, theirs to
   accept): any rule or adequacy result they state over `CM_sc` carries
   F_SC membership (the DRF-SC hypothesis) as an explicit premise and is
   labelled as the SC instance; adequacy is stated over the selector
   where it can be. We provide the semantics-side facts (the selector,
   the refusal set, the bridge check) and a written consumer note in S6;
   we do not design their logic.
4. Timing: the consumer note goes out with the S6 manifest; a consumer
   REVIEW of §4.1/§4.6 (the parameter surface and the recorded
   non-parametric point) is requested BEFORE S1 lands (the fuel-arc
   practice: interface reviewed before code). OPEN §10 D5: whether the
   operator wants that review to gate S1 or run in parallel.

## 9. Exit criteria (Phase 0 = "mergeable" record)

- E1. Litmus lane green: every F_SC row's outcome SET agrees three ways
  — oracle engine, Lean engine, expectation file (recovered `tests.ml`
  sets for the SC rows; hand-derived and recorded for the rest, with the
  derivation); race rows report UB005 on both; out-of-F_SC rows are
  REFUSED identically on both (a refusal row is a row).
- E2. Bridge check: SC consistency holds on every produced trace of the
  whole litmus corpus; the corrupt-`rf` plant trips it.
- E3. Sequential battery (Tier A+B): zero movement across all slices.
- E4. Gates: totality slice includes the Cmm modules at zero partials;
  axiom census zero; `sorry` token census zero; opaque census reduced by
  `using_concurrency` with the re-pin reasons; NDguard/NDbranch still
  unreachable (plant).
- E5. Records: DESIGN/VALIDATION/README carry the model section, the
  F_SC definition, the §4.6 boundary entry, and the DRF-SC citation; the
  change manifest and consumer note exist; the tray draft exists.
- E6. No `2>/dev/null`, no `partial` in the exec cone, no heartbeat/
  maxRecDepth bumps, no numerals as budgets; grind tripwire respected
  (no pass near an hour; the litmus corpus is tiny by construction).

## 10. Decisions requested from the operator — ALL APPROVED [USER 2026-09-04], recommendations adopted

- D1. Approve the scope: Phase 0 = parametric selector + SC-DRF
  instance; C11-op/RC11/LKMM deferred to Phase 1–2 (§0, §3, §5).
- D2. Approve the fail-closed choices: spawns refused under
  `CM_sequential` (changes today's silent serialization into a refusal,
  both engines); non-SC orders and fences refused under `CM_sc` (§4.5).
- D3. Parameter mechanism for the `using_concurrency` reads: explicit
  threading in `.lem` (recommended) vs lem-lean reader-lift (§4.1).
- D4. Bridge check placement: end-of-trace default, per-step behind a
  debug flag (recommended) vs per-step always (§4.4).
- D5. Consumer review of §4.1/§4.6 gates S1 (recommended, matches the
  fuel-arc practice) vs runs in parallel (§8.4).
- D6. Whether `backend/bmc` should be built as a second oracle for the
  litmus lane in Phase 0 (needs the z3 opam binding — network/operator)
  or deferred to Phase 1 where weak orders make an independent oracle
  load-bearing (recommended: defer; the SC sets are small enough to
  derive by hand and are cross-checked by the recovered `tests.ml` sets).

## 11. Provenance

[USER 2026-09-04]: §1 quotes; the SC-first direction; "handle carefully".
[USER 2026-08-19]: the parametricity principle (archive). [USER
2026-08-26]: the rescoping (archive). [AGENT]: §2 measurements (verbatim
outputs; the table's "identical" cells are literal — the Lean lines were
byte-equal to the oracle lines), the FINDING, §3–§10 design and
recommendations. Docs-only; no code touched; nothing merged or pushed.
