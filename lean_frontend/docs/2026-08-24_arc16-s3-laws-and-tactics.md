# Arc 16 S3 — the loop peels, the primitive law library, the wp-tactics (record)

Worker record, 2026-08-24. Charter:
`2026-08-24_arc16-iris-refounding-charter.md`, slice S3. Branch
`iris-refounding` (off `f8629bea0`, the S4-amendment commit).
Companion context: the S0 record (perf cliffs + IPM vocabulary,
consumed throughout), the S1 record (§5 is this slice's requirements
list), the S2 record (the four op rules + the Lem-jungle hazard note).
[AGENT] design decisions are marked; measurement numbers are from this
session's builds.

## 1. The problem this slice closes

After S1/S2, per-step WP reasoning existed at HARNESS-STAGE
granularity: the S1 smoke walks eleven stages, but the whole driver
loop is ONE atom (`driver2_iter` — a per-fixture whole-loop equation),
because bind-collapse erases every step boundary inside the two
generated fuel recursions (`drive_nonmemory_steps_aux2_lemFuel`,
`driver2_lemFuel`). S2's four heap rules fire at `liftMem` atoms —
which no expression exposed. S3 delivers (1) the two LOOP PEELS that
re-erect those boundaries, (2) a PRIMITIVE LAW LIBRARY (one WP lemma
per exec-relevant Core construct) on the peeled granularity, (3) a
THIN WP-TACTIC layer, with the T1 smoke re-proof as the economics
instrument.

## 2. The peels (deliverable 1 — BOTH LANDED)

### 2.1 Design: reified loop formers + runner-level simulation

`RelSem/PerStepPeel.lean`:

- `dnmsK` — `drive_nonmemory_steps_aux2` reified to PER-CORE-STEP
  granularity: one `seq` joint for the step-discovery read
  (`stepDiscovery`, pure-active by `rfl` — the S1 §5 prediction held)
  and one for the advance. The SEQUENTIAL ACTION-REQUEST rounds reify
  deeper — request draw, aid draw, then per request class
  (`arsK`): the four memory ops expose their `liftMem` ATOMS — the
  byte-identical trigger shapes of S2's `wpk_load/store/alloc/kill` —
  plus the bookkeeping `nd_update` as its own joint; other request
  classes and other advance classes stay one-atom residuals (still
  per-Core-step joints). Fuel-0 and the exits mirror the generated
  recursion.
- `driver2K` — `driver2_lemFuel` reified to per-iteration granularity:
  `new_drive_core_threads`'s spine as joints with `dnmsK` SPLICED for
  the inner loop segment, the scheduler stages (`ndctPick` mapM, mode
  `if`, `pick`) as joints, and `process_core_step2` reified per arm
  (`pcsK`: ccall dispatch, memop, program exit as joints; fs/wrong
  arms as residual atoms carrying the real recursion).
- `callK2`/`callFinishK2` — the S1 harness `callK` with the one
  `driver2` atom replaced by `driver2K` at the production budget.

THE CONNECTION (the S1 §5 design, built): a denotation equality is
UNAVAILABLE (fuel'd bind re-association is propositionally false), so
the peel theorems are RUNNER-LEVEL simulations — the production
enumerator cannot distinguish the peeled denotation from the generated
loop at any fuel within the production envelope:

    dnmsK_runner_eq    : runNDFuel F (dnmsK n acc tids k).denote σ
                       = runNDFuel F (nd_bind (dnms_lemFuel n …) (denote ∘ k)) σ   (F ≤ lemDefaultFuel)
    driver2K_runner_eq : … same shape for driver2K/driver2_lemFuel …
    callK2_runner_eq   : runNDFuel F (callK2 …).denote σ = runNDFuel F (callND …) σ

*Lineage (canon-first)*: the standard functional-big-step ↔ small-step
equivalence ("the interpreter implements the machine"), one walk per
loop body; stated observationally because the observational level is
where the ND monad's laws hold (the interaction-tree `eutt`-style
move). Statement-facing adequacy then rides the GENERIC S1
completeness (`ksteps_of_runND`) — `kCallHarnessAdequate_of_wpK2` /
`kCallHarnessUBFree_of_wpK2` (PerStepLaws) land the byte-identical
committed conclusion forms; `callND` and every statement are
untouched.

### 2.2 The runner-observation algebra (the general-purpose part)

`RelSem/PerStepRunner.lean` — proved once, consumed by every walk;
these are the ND monad's laws recovered as observational equalities:

- `runNDFuel_bind_congr` — pointwise-equal continuations under a bind
  are runner-equal (ALL node casing of the walks concentrates here);
- `runNDFuel_bind_assoc` — bind re-association, runner-observed
  (the value-level failure is quarantined to unreachable wrap fuels);
- `runNDFuel_bind_active`/`_killed`, `app_bindFuel_congr` — collapse
  observed fuel-free.

Induction template: S1's `runNDFuel_bind_fuel_irrel`, unchanged.

### 2.3 Walk price (measured vs the S1 §5 estimate)

The dnms walk (deep arm included, i.e. finer than the priced
"advance-opaque" version): ~230 lines including the formers; the
driver2 walk + pcsK arm lemma: ~250 lines; the callK2 spine descent:
~50. S1's estimate (40–120 + 300–600) bracketed it. The generated-code
anchors are `rfl`s (`h1`/`h2` in `driver2K_runner_eq`, the `show`s in
`dnmsK_runner_eq`): Unit structure eta + zeta erase the debug-print
stages and dead lets definitionally, so the clean mirrors
(`stepDiscovery`, `ndctPick`, `driver2Body`, `nonBlockedFilter`,
`wakeupIns`) anchor against the generated text without transcribing
the giant print lambdas; drift in Driver.lean's loop bodies breaks
these anchors build-fatally (cite-and-anchor discipline).

Known granularity limits (recorded): at an in-iteration ND node the
successor stays at ATOM granularity within the same joint structure
(`KStep.seq_nd` keeps the continuation); an fs-step or wrong-step arm
degrades the REST of the loop to one residual atom (the S1 §5
limitation, unchanged); the cmm arc owns the scheduler-pick upgrade.

## 3. The law library (deliverable 2)

`RelSem/PerStepLaws.lean` — one WP lemma per exec-relevant Core
construct, at the OwnP interpretation over the PEELED expressions;
hypotheses are the Kit law table's, hypothesis for hypothesis (the
arc-9 `@[app_eq]` equations REUSED at the per-construct level —
`advance_tau_misc`, `advance_runstate_eval`, `advance_runstate_tau_misc`,
`aid_draw`, `liftCore_run_defined`, `app_liftMem_active`, the
`ars_*_unfold`s; no chase machinery — the S0 freeze gate enforces).

| Core construct | round class | law |
|---|---|---|
| wseq/sseq/case/let strip | `Step_tau2 TSK_Misc` | `wpk_round_tau` |
| proc return (tau kind) | `Step_tau2 TSK_Return` | `wpk_round_tau_ret` |
| pure eval, Erun/Esave jumps | `RSK_eval` | `wpk_round_eval` |
| runstate tau | `RSK_tau TSK_Misc` | `wpk_round_rsk_tau` |
| runstate proc return | `RSK_tau TSK_Return` | `wpk_round_rsk_ret` |
| create | `CreateRequest2` | `wpk_round_create` |
| load | `LoadRequest2` | `wpk_round_load` |
| store | `StoreRequest2` | `wpk_round_store` |
| kill | `KillRequest2` | `wpk_round_kill` |
| no-advance (offer accumulated) | `find_can_advance = none` | `wpk_round_accum` |
| any other advance (generic) | — | `wpk_round_advance` |
| ccall/proc dispatch | `Step_ccall2` | `wpk_pcs_ccall` |
| program exit | `Step_done2` | `wpk_pcs_done` |
| scheduler mode split | opaque config read | `wpk_ite` / `wpk_ite_conj` |
| action-request entry spine | — | `wpk_round_request_entry` |

Two NEW equation-layer entries (the Kit table covered the Misc kinds
only): `advance_tau_return`, `advance_runstate_return` (the
function-return trace advances — same computed-RHS discipline).

Each law is proved once against the generated semantics and fires for
every program containing its construct; side conditions are
kernel-computable pure facts (`rfl`/`decide` at concrete instances).
*Lineage*: per-construct Floyd–Hoare/WP rules (the HeapLang
`PrimitiveLaws.lean` shape); the compiled-shape factoring is
Myreen-style decompilation at Core's stereotyped output.

HEAP-ROUTE STATUS (honest scope line): S2's four rules attach
UNMODIFIED at the `liftMem` atoms `arsK` exposes (trigger shapes
byte-identical — that requirement is met by construction and
exercised at the atom level by `two_alloc_frame_tac`). Stepping a FULL
round under `CerbMemInterp` additionally needs heap-route rules for
the round's NEIGHBOR atoms (discovery read, request/aid draws, the
bookkeeping update — all rest-cell business via S2's
`wpk_seq_res_det` skeleton, plus a characterization of `step_ctx`'s
layout_state dependence). Priced for part 2: ~1 skeleton instantiation
per neighbor atom (the S2 pattern, known shape) + the discovery
characterization (S–M; the one open question is which memory
components `step_ctx` actually reads).

## 4. The wp-tactics (deliverable 3)

`RelSem/PerStepTactics.lean` — packaged brick-wp-style: recurring
steps are lemmas (PerStepLaws/CerbHeapWP), the tactic layer is thin
macros. *Donors (in-file attribution)*: iris-lean
`Iris/HeapLang/{Tactic,ProofMode}.lean` (vocabulary + packaging;
`wp_expose` is the analogue of its `wp_expr_simp`/`tac_wp_expr_simp`),
brick-wp (the factoring). The donor's Qq redex/points-to SEARCH is the
named upgrade path (part 2) if goal shapes outgrow syntactic
application.

- `wp_pure1 H` / `wp_pures H` — self-computing deterministic steps:
  `wpk_seq_active_proj` keeps states as compact `(app m σ).2`
  projections; the activation side condition is a DEFERRED `rfl`
  (elaborated after framing pins the state — the S1 late-defeq
  technique, automated).
- `wp_expose` — 20-line elab: whnf the expression under `WP` and
  `change` (kernel-checked defeq). Needed because `iapply` unifies at
  reducible transparency, so continuation `match`es over computed
  driver values block until reduced.
- `wp_step e H` — the seq/bind stepper: one step by a proved app
  equation, expression and state spellings bridged by deferred `rfl`
  casts (`wpk_seq_active_ecast`).
- `wp_mode` — the scheduler-mode split (`wpk_ite_conj` + `isplit`).
- `wp_done` — value discharge.
- `wp_load/wp_store/wp_alloc/wp_kill` — S2's heap rules applied with
  side conditions discharged by `assumption | rfl | decide`
  (`wp_side`); footprint routing stays with the caller's names.

## 5. THE ECONOMICS MEASUREMENT (`RelSem/PerStepTacSmoke.lean`)

- **T1 smoke re-proof** (`t1_wpK_tac`, statement byte-identical to
  S1's `t1_wpK`; `T1_perStep_tac : T1Statement` — the committed
  statement through the tactic route, cone identical): S1's ELEVEN
  manual WP steps (each hand-fed its `app` equation; 48 proof-body
  lines) become a NINE-LINE script with THREE hand-fed equations —
  all REUSED committed lemmas, zero new per-fixture text:

      iintro Hst
      wp_pures Hst                            -- stages 1–7 SELF-COMPUTE
      wp_step (k8_errno x) Hst                -- errno composite (S1 lemma)
      wp_step (k9_update x _ (by rfl)) Hst    -- thread setup (S1 lemma)
      wp_step (driver2_iter x hx.1 hx.2) Hst  -- the loop atom (T1AppEq)
      wp_pures Hst                            -- the post-loop read
      wp_done
      ipureintro
      exact ⟨_, rfl, t1_result_eq x⟩

  THE ECONOMICS NUMBER: 11 manual WP steps → 9 tactic lines / 3 fed
  equations (48 → 9 proof-body lines); elaboration 1.1 s (vs the
  manual route's 951 ms — parity). Measured boundary (the k9
  bracket): replacing the `k9_update` feed with `wp_pures` sends
  elaboration past 120 s — the proj-state→named-state defeq bridge at
  the thread-record is the cost cliff (S1 §6 flagged exactly this
  unification; the committed equations chain named states, which is
  why feeding them is free).
- **End-to-end by tactics alone through the PEELED loop: PARKED at a
  measured wall** (the in-file park note in PerStepTacSmoke §2 is the
  registration). The attempted `t1_peeled_concrete` (T1 at argument 5
  through `callK2`, `wp_pures` alone, committed `CallHarnessAdequate`
  conclusion via `kCallHarnessAdequate_of_wpK2`) fails on cost, not
  on structure: stepping INTO the loop makes a single `whnf` exceed
  the default heartbeat budget ((deterministic) timeout at `whnf`,
  200000 — isolated measurement, peak RSS ~10.4 GB; the full-module
  attempt grew past the 64 G blast-radius cap and was killed).
  Root cause: the compute-forward style whnf-INLINES a full
  `driver_state` per step, and every state carries the whole program
  term (`core_file`); named-state feeding keeps constants folded and
  is measured-cheap (the 1.1 s above). NO budget was raised (heartbeat
  doctrine: pressure = design input). Named canonical fixes for part
  2: per-fixture named-state definitions fed to `wp_step` (the
  committed-T1AppEq pattern, known cost), or donor-style Qq stepping
  that computes successor states once outside the goal (HeapLang
  `wp_load`'s architecture). The peel theorems, the adequacy bridge,
  and the law library are proved and unaffected.
- **Heap tactics** (`two_alloc_frame_tac`): the S2 framing demo
  re-proved with `wp_store`/`wp_load` — the rules' 11 side-condition
  pluggings disappear into the macros (`assumption | rfl | decide`);
  the 8-line footprint routing (caller-owned names) remains.

## 6. Cones (VERBATIM from the close probe; the marked set is
    Audit-pinned build-fatally)

```
'RelSem.app_bindFuel_congr' depends on axioms: [propext]
'RelSem.runNDFuel_bindFuel_active' depends on axioms: [propext]
'RelSem.runNDFuel_bind_active' depends on axioms: [propext]
'RelSem.runNDFuel_bind_congr' depends on axioms: [propext, Quot.sound]
'RelSem.runNDFuel_bind_assoc' depends on axioms: [propext, Quot.sound]
'RelSem.Cerb.denote_seq' does not depend on any axioms
'RelSem.Cerb.app_ite_return' does not depend on any axioms
'RelSem.Cerb.dnmsK_runner_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.driver2K_runner_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.callK2_runner_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_seq_active'' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_seq_active_ecast' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_seq_active_proj' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_ite' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_ite_conj' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.stepDiscovery_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_accum' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_advance' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_tau' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_eval' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_rsk_tau' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.advance_tau_return' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.advance_runstate_return' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_tau_ret' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_rsk_ret' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_request_entry' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_load' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_store' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_create' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_round_kill' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_pcs_done' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_pcs_ccall' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.kCallHarnessAdequate_of_wpK2' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.Cerb.kCallHarnessUBFree_of_wpK2' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.t1_wpK_tac' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.T1_perStep_tac' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.two_alloc_frame_tac' depends on axioms: [propext, Classical.choice, Quot.sound]
```

Every cone is within the classical trio except where the TEMPORAL
effect boundary's `runEffectful` enters through the quoted harness
substrate (`callND`/`initial_driver_state`) — exactly as the
committed T1's cone, per the S4-amendment plan (the ∀-seed re-proof
dissolves it there). Where the construct allows (peels, runner
algebra, laws, heap smoke), S2's trio-clean bar is MATCHED.

## 7. Perf vs the S0 cliffs, and the honest cost line

Fresh clean-elaboration times (forced rebuild, `lake build` lines):

```
✔ [373/380] Built RelSem.PerStepRunner (323ms)
✔ [374/380] Built RelSem.PerStepPeel (1.2s)
✔ [375/380] Built RelSem.PerStepLaws (1.5s)
✔ [376/380] Built RelSem.PerStepTactics (1.1s)
✔ [377/380] Built RelSem.PerStepTacSmoke (1.2s)
```

All far below any S0 cliff at the LAW/lemma level: rule goals carry
1–5 spatial hypotheses; the tactics frame the ONE named state
hypothesis. Default budgets throughout; ZERO heartbeat/maxRecDepth
changes anywhere.

THE HONEST COST LINE (this slice's headline perf finding, feeding
part 2): tactic-driven stepping has two regimes —

- NAMED-STATE regime (equations fed, or self-computing steps anchored
  a constant depth from a named state): seconds; scales like the
  committed route.
- COMPUTE-FORWARD regime (projection-state chains + `wp_expose` whnf
  at fixture-scale states): each exposure inlines a `driver_state`
  carrying the whole program term; measured to cross the default
  heartbeat budget inside one `whnf` and to grow past 10 GB RSS
  within a driver iteration. This is a TERM-REPRESENTATION cost, not
  a semantics cost; the S1 §6 compact-projection technique works
  until the first `match`-on-computed-value, which forces the inline.

Design consequence (canon-first, both named lineages): part 2's
tactic upgrade takes the donor's architecture (HeapLang ProofMode:
compute successor states ONCE in the meta layer, keep goals folded)
or per-fixture named-state ladders (the committed pattern) — not
budget raises.

## 8. Validation

- relsem `lake build` (capped): green, all in-build gates pass —
  `RelSem audit sweep: 3904 declarations (module-of-origin root
  RelSem, within RelSem.Audit's import closure — NOT the whole tree),
  all within the declared axiom boundary (0 recorded sorryAx
  exceptions)` (re-baselined 3692 → 3904 this slice, provenance
  comment at the pin; 212 new declarations), the DAEMON absence gate,
  the statement gate (16 slate statements fuel-opsem-clean —
  statements untouched), the S3 cone pins (§6, `#guard_msgs`).
- `./scripts/test_unit.sh` and `./scripts/test_verify.sh`: see the
  close transcript in §8a below (run at the close commit).
- No sorries; no new axioms; no edits to any statement, committed
  theorem, or existing proof file — pre-existing files touched only
  by additive registration (lakefile roots, RelSemAll imports, Audit
  imports + pins + sweep re-baseline).

§8a — close transcript (verbatim):

```
Total: 7 passed, 0 failed
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
```

## 9. Walls, parks, what part 2 needs

- PARKED (registered in-file + §5): tactics-alone end-to-end through
  the peeled loop at fixture scale — the compute-forward cost wall;
  two named canonical fixes priced above. The peel + adequacy bridge
  are proved; part 2's T5-by-invariant consumes them with named
  states.
- PARKED (charter-consistent): heap-route ROUND laws (the neighbor
  atoms of a memory round under `CerbMemInterp` — rest-cell skeleton
  instantiations + a `step_ctx` layout-dependence characterization);
  S2's four op rules attach unmodified at the `arsK`-exposed atoms
  (trigger shapes byte-identical), demonstrated at atom level by
  `two_alloc_frame_tac`.
- Known granularity limits carried forward (from §2.3): ND-node
  successors stay atoms inside their joint; fs/wrong-step arms
  degrade the loop remainder to a residual atom; the cmm arc owns the
  scheduler-pick upgrade.
- WHAT S4 NEEDS FROM S3: nothing blocking — S4 re-proves T1–T4 at
  the threaded ∀-seed statements; the tactic vocabulary (`wp_step`
  feeding committed equations + `wp_pures` for cheap prefixes) is the
  economical route measured here; `T1_perStep_tac` is the working
  template for a slate re-proof in single-digit lines per fixture.
  The seed-parametric states are exactly the named-state regime
  (statement-led supply-passing keeps them closed terms).
- Lem-jungle encounters: none new — the S2 hazards were dodged by
  never `==`-ing at symbolic states in this slice (the laws take
  equation hypotheses; the smokes run at concrete/named states).
