# Arc 16 S1 — the per-step language instance (record)

Worker record, 2026-08-24. Charter:
`2026-08-24_arc16-iris-refounding-charter.md`, slice S1. Branch
`iris-refounding` (off `198ab458f`, the S0 close). Companion context:
the S0 record (perf guidance consumed in §6) and the chase-era
post-mortem. [AGENT] design decisions below are marked; per the brief,
this DESIGN section was written before the build.

## 1. The problem, measured precisely

The arc-7 instance (`RelSem/IrisLang.lean`) is per-ND-NODE: one
`CerbPrimStep` wraps one `Machine.Step`, which is one `app` unfolding
of the reified `ndM` tree. That granularity is not the audit's
"whole-run atomic" by accident — it is forced by two generated-code
facts (both verified against `generated/Nondeterminism.lean` /
`generated/Driver.lean` in this session):

1. **Bind-collapse**: `nd_bind_lemFuel`'s `NDactive` case applies the
   continuation's action to the post-state *inside one `app`
   unfolding* (Nondeterminism.lean:190). Deterministic segments of any
   length are one node.
2. **The sequential path builds no step nodes**: `pick` on a singleton
   builds `NDactive` (Nondeterminism.lean:~280); `mk_step`
   (the `NDstep` builder) is called only from `Cmm_op` (concurrency)
   and `bindExhaustive` only from `driver2`'s random-mode branch.

Consequence (the T1 trace evidence, RelSem/Machine.lean §
Coverage-by-need): a deterministic single-threaded run is ONE
`Step.active` — the whole-run `app` equation the chase existed to
produce. The per-step content of the semantics lives in two generated
fuel recursions instead:

- `driver2_lemFuel` (Driver.lean:381) — one fuel tick per driver-loop
  iteration; recursion enters as the explicit continuation parameter
  `driver21` of `process_core_step2`.
- `drive_nonmemory_steps_aux2_lemFuel` (Driver.lean:346) — one fuel
  tick per Core step (`step_ctx` candidates → `advance_step`); this
  inner loop advances ALL advanceable steps (loads/stores included)
  within one `new_drive_core_threads` call, so for sequential code a
  single driver2 iteration contains nearly the whole program (T1: one
  iteration, nine inner rounds).

Two further measured constraints shaped everything below:

- **Fuel'd `nd_bind` is not associative as values.**
  `nd_bind (nd_bind a g) f` and `nd_bind a (fun x => nd_bind (g x) f)`
  wrap deep nodes at different residual fuels; the values differ at
  depth ~10^6. Re-association of generated bind spines is therefore
  unavailable propositionally. All connections in this slice live at
  the `app`/runner-observation level, where one collapse step is
  fuel-free and composition DOES hold (`app_bind_congr`-style lemmas).
- **Bind-fuel and runner-fuel decrement in lockstep** (one node level
  each), and `ndDefaultFuel = lemDefaultFuel` exactly. So a
  "the runner at fuel F cannot observe bind-fuel differences ≥ F"
  invariance lemma holds with `F ≤ b`, with equality exactly
  maintained along the default-budget descent. This is what makes the
  statement-facing adequacy (which quantifies `CerbND.runND` = the
  default budget, and nothing deeper) reachable.

## 2. The design ([AGENT]; recorded before built)

### 2.1 Configuration type and expression/value split

**Expressions** are continuation-reified sequencing over the driver
monad (file `RelSem/PerStep.lean`, generic over the same `A I E C S`
parameters as `RelSem.Machine`):

    inductive KExpr (A I E C S : Type) : Type 1 where
      | done : Outcome A E → KExpr A I E C S
      | seq  : {α : Type} → ndM α I E C S
               → (α → KExpr A I E C S) → KExpr A I E C S

with denotation `denote : KExpr A I E C S → ndM A I E C S`
(`done (value v) ↦ nd_return v`, `done (killed r) ↦ kill r`,
`seq m k ↦ nd_bind m (denote ∘ k)`). A **configuration** is
`⟨KExpr, S⟩` at the driver instantiation `S = driver_state` — i.e.
exactly what the fuel opsem steps over, with the expression recording
how much of the program remains and where its sequencing joints are.
**Values** are `done`-outcomes (`DriveVal = Outcome driver_result
driver_error`, unchanged from arc-7: a UB kill is a value, never
stuckness). `Type 1` is forced by the `{α : Type}` continuation field
and was probe-verified against the pinned iris-lean: the `Language`
class, WP, `ownP_adequacy`, and `ownP_lift_step` are universe-
polymorphic and all elaborate at a `Type 1` Expr (probe transcript
retained in §7).

*Lineage*: reified monadic syntax with semantic atoms — the
free-monad / interaction-tree program-logic pattern (Xia et al.'s
ITrees and the Iris program logics over them); atoms are the
GENERATED computations themselves, never re-axiomatized. The
abstraction sentence (trick filter): reification makes monadic
sequencing *syntactic*, so the step relation can stop at bind joints
that `app` computes through; every program built from the same
combinators gets the same joints for free.

### 2.2 The step relation — defined from the generated step function

`KStep (γ : CsSem C S)` has exactly seven arms, each premised on ONE
`app` equation of the leading atom (`app` = the one-node unfolding of
the generated tree, RelSem/Machine.lean:95 — the same function the
arc-7 relation consumes; nothing re-axiomatized):

    seq_active  : app m σ = (NDactive v, σ')  → ⟨seq m k, σ⟩ → ⟨k v, σ'⟩
    seq_killed  : app m σ = (NDkilled r, σ')  → ⟨seq m k, σ⟩ → ⟨done (killed r), σ'⟩
    seq_nd      : app m σ = (NDnd i br, σ') ∧ (j,m') ∈ br → … → ⟨seq m' k, σ'⟩
    seq_step    : (NDstep analogue)
    seq_guard   : γ.sat gate on NDguard        → ⟨seq mk k, σ'⟩
    seq_branchL/R : γ.sat/γ.nsat on NDbranch   → ⟨seq l/r k, σ'⟩

`done` configurations are terminal. Soundness is by construction:
every premise is an equation about the generated `app`; the relation
is `Machine.Step`'s dispatch re-hosted on expressions with joints.
Nondeterminism (allocator/scheduler/constraint) enters exactly at the
`nd`/`step`/`guard`/`branch` arms — per-step, deterministic per
resolved choice, `CsSem`-parametric as before (the Iris instance uses
`γexh`; a constraint evaluator or a cmm schedule discipline slots in
without reshaping the relation — forward-design constraint honored).

### 2.3 Language class: `Language`, not `EctxLanguage`

[AGENT] Plain `Language`. The driver monad is continuation-structured:
`ndM` is a function type; there is no fill/decompose operation on it,
and evaluation position is always the leading atom. `seq` plays the
sequencing-context role *by construction* (the continuation is data of
the expression), so the Ectx interface's `fill`/`fill_inv` obligations
have no non-contrived carrier. What Ectx would buy (wp_bind) is
delivered instead by per-constructor lifting rules (§2.5). Forcing
Ectx here would be exactly the trick-filter failure mode — machinery
whose abstraction the object does not have.

### 2.4 The fuel↔steps connection (what adequacy consumes)

- **`runNDFuel_congr_app`** (built): equal `app` observations give
  equal runner enumerations at every fuel — the composition principle
  that survives the associativity failure.
- **Bind-fuel invariance** (built): for `F ≤ b, b'`,
  `runNDFuel F (nd_bind_lemFuel b m f) = runNDFuel F (nd_bind_lemFuel b' m f)`
  — the runner cannot see wrap-fuel it cannot reach.
- **Steps-of-fuel (completeness), the load-bearing theorem**: for
  `F ≤ lemDefaultFuel`, every triple the production worker enumerates
  for `denote e` is the endpoint of a `KSteps` trace from `⟨e, σ⟩`.
  Proof: outer induction on F, inner structural induction on the
  (reflexive) `KExpr`; active heads recurse at the SAME fuel on a
  structurally smaller expression (collapse is fuel-free), node heads
  recurse at F−1 re-expressed through the invariance lemma (fuel
  alignment exact at every level).
- **Fuel-of-steps direction**: not needed for adequacy (the headline
  quantifies runner outcomes, i.e. the fuel side); per-step existence
  facts for the smoke client come from the app equations directly.

The statement-facing adequacy is derived DIRECTLY at the
`CallHarnessAdequate` shape (which quantifies `CerbND.runND`, the
default budget — exactly the completeness envelope). [AGENT] The
`seqModel.behavior` mid-layer (∃-fuel, unbounded) is deliberately
bypassed on the new route: at fuels beyond the bind-wrap budget the
re-expressed program and the collapsed artifact can differ (the wrap's
own exhaustion marker), so the ∃-fuel interface overshoots what a
re-expressed per-step language can honestly promise. The old route and
its statements are untouched.

### 2.5 The Iris coupling (`RelSem/PerStepIris.lean`)

- Instance `Language KDriveExpr driver_state Empty DriveVal` (singleton
  thread pool, no forks, no observations — as arc-7).
- State interpretation: REUSED WHOLESALE — `OwnP` at `driver_state`
  (`CerbGpreS`/`CerbGS`/`stateIs`/`CerbS` from `RelSem/IrisState.lean`,
  unchanged).
- Lifting rules (the per-step WP interface):
  - `ownP_lift_det_step_no_fork` — a NEW generic (any-Language)
    derived rule: deterministic step to a possibly-non-value
    expression; `▷ ownP σ ∗ ▷(ownP σ' -∗ WP e₂) ⊢ WP e₁`. Built
    Iris-compatible (the library has only the atomic and pure det
    variants); proved over `ownP_lift_step`.
  - `wpk_seq_active` (non-atomic det step at an active head),
    `wpk_seq_killed` (atomic: kill is a value), `wpk_done`
    (`wp_value'` reuse). ND-arm rules are S3 territory (not needed by
    the deterministic smoke corpus; recorded).
- Adequacy: `ownP_adequacy` (REUSED) + KSteps→thread-pool erasure
  (built, mirrors arc-7 `steps_erased`) + completeness ⇒
  `kCallHarnessAdequate_of_wp` / `kCallHarnessUBFree_of_wp` with
  conclusions in the EXISTING statement forms (`CallHarnessAdequate`,
  `CallHarnessUBFree` — byte-identical defs, untouched).

### 2.6 The reified harness (`callK`) and its anchor

`callK` re-expresses `RelSem.Cerb.callND`'s stage spine as a `KExpr`
(atoms = the same stage computations `driver_globals`, `nd_get`,
`resolveFunSym`, `lookupFunBody`, `lookupParamTys`, `injectArgs`, then
`callFinish`'s stages with the errno alloc/store and `driver2` as
atoms). The anchor theorem `callK_denote : denote (callK …) = callND …`
is the drift gate: `callND` itself is untouched (statement freeze),
and any future edit to Call.lean that moves the spine breaks the
anchor build-fatally. Granularity delivered now: per-stage steps for
the harness (including the allocator/store atoms), ONE atom for the
`driver2` loop segment; §5 records precisely what peeling the loop
requires.

### 2.7 Smoke client

T1 (pinned fixture, statements untouched): WP for
`⟨callK t1File.tagDefs t1File "id" [intValue x], initial…⟩` proved by
stepping the per-stage lifting rules — the stage `app` equations at
concrete states are `rfl` (as in T1AppEq's `prefix_a`) or REUSED
T1AppEq objects (`allocErr_eq`, `storeErr_eq`, and `driver2_iter` for
the loop atom — T1's loop is genuinely one iteration; consuming the
committed equation is reuse of a proved theorem, not a chase import:
the new files import no frozen surface). Adequacy lands
`T1Statement`-shaped conclusions via the NEW route as a new theorem
(`T1.lean` untouched).

## 3. Reuse-vs-built ledger

| Piece | Status |
|---|---|
| `Language`/`PrimStep`/`ToVal` classes, WP, `ownP*` incl. `ownP_adequacy`, `ownP_lift_step`, `ownP_lift_atomic_det_step_no_fork`, `adequate_result` | REUSED (iris-lean, pinned 34390a013398) |
| `app`, app-equation layer (`app_bind_active/killed`, `app_liftND_*`, `app_nd_*`), `CsSem`/`γexh`, `Outcome`/`ofStatus`, `runNDFuel` lemmas (`runNDFuel_zero`, `mem_foldl_prepend`), `CallHarnessAdequate`/`CallHarnessUBFree` (defs unchanged), OwnP shims (`CerbGpreS`/`CerbGS`/`stateIs`/`CerbS`), T1AppEq stage equations | REUSED (ours, existing) |
| `KExpr`/`KStep`/`KSteps`/`denote`; node-arm bind equations; `runNDFuel_congr_app`; bind-fuel invariance; steps-of-fuel completeness; pool erasure; `ownP_lift_det_step_no_fork` (generic); `wpk_*` rules; `callK` + `callK_denote`; `kCallHarnessAdequate_of_wp`/`kCallHarnessUBFree_of_wp`; smoke theorems | BUILT (Iris-compatible, this slice) |

## 4. Outcomes

Built, green, and gated — four new modules in the relsem package
(registered in `lakefile.toml` roots, `RelSemAll`, and the Audit
import closure + curated pins; sweep re-baselined 3356 → 3517, all
161 new declarations boundary-clean):

- `RelSem/PerStep.lean` — the language (KExpr/KStep/KSteps/denote),
  terminal-head determinism inversions, the node-arm bind equations,
  the runner dispatch/congruence lemmas, bind-fuel invariance, and
  STEPS-OF-FUEL completeness (`ksteps_of_runNDFuel` with the
  `F ≤ lemDefaultFuel` envelope + the production-budget wrapper
  `ksteps_of_runND`).
- `RelSem/PerStepIris.lean` — the `Language` instance
  (`instLanguageKDrive`), pool erasure, the NEW generic
  `ownP_lift_det_step_no_fork`, the per-step WP rules
  (`wpk_seq_active`/`wpk_seq_killed`/`wpk_done`), and
  `kAdequate_of_wp` (WP ⇒ production-runner facts on the denotation).
- `RelSem/PerStepCall.lean` — `callK`/`callFinishK` (the reified
  harness; `@[reducible]` so WP goals expose the `seq` head) + the
  anchors `callK_denote`/`callFinishK_denote` (rfl-per-branch:
  Call.lean spine drift is build-fatal) + the statement-facing
  `kCallHarnessAdequate_of_wp`/`kCallHarnessUBFree_of_wp`
  (conclusions are the byte-identical committed forms).
- `RelSem/PerStepSmoke.lean` — T1 as ELEVEN WP steps (§2.7) +
  `T1_perStep : T1Statement` and `T1_ubFree_perStep` — same
  statements, new route, cones identical to the committed route's.

**Smoke-client status: COMPLETE at stage granularity, honest prefix
overall.** The eleven steps are: globals, post-globals read, name
resolution, body/params lookup, param C types, the ARGUMENT INJECTION
(allocator surface), thread-states read, errno allocate+store through
the memory lens, thread setup, ONE driver2 iteration (T1's whole
loop — the equation is the committed `driver2_iter`), final state
read; then `wpk_done`. What remains atomic is the INSIDE of the
driver2 iteration (T1: nine collapsed dnms rounds). WHAT S3 MUST
PROVIDE (the precise requirement): the two loop peels of §5 — the
big-step↔small-step simulation for `drive_nonmemory_steps_aux2`
(per-Core-step granularity; the cheap one) and for `driver2`'s
iteration wrapper — plus per-construct characterizations of single
dnms rounds by arena shape (the law layer). With those, the
per-fixture equations (`driver2_iter`, the dnms chains) are replaced
by reusable laws and T5-class loops become steppable per iteration.

Operational note (two-package edge, extends the arc-11 finding):
`lake lean <file>` from `relsem/` mis-resolves `RelSem.PerStep` to
the ROOT package's build dir when the file also imports a root-side
module (`RelSem.Call`); `lake build RelSem.<Mod>` resolves correctly
and is what the gates run. Probes touching such files should use
`lake build`.

## 5. The loop peels — designed, priced, not built here

Per-iteration (`driver2`) and per-Core-step (`dnms`) structure require
re-erecting step boundaries that bind-collapse erased **inside** the
two generated fuel recursions. The design that survives scrutiny:

- Reified loop formers by fuel recursion (`driver2K n`, `dnmsK n`)
  producing `seq`-terms whose atoms are single-round-sized (the
  recursion sites become the formers at n−1; exit sites become the
  continuation) — no new step rules, the uniform relation carries it.
- The connection cannot be a denotation equality (bind
  re-association is propositionally false — §1); it must be the
  runner-level simulation: membership in
  `runNDFuel F (nd_bind (loop_lemFuel n …) f)` decomposes through the
  loop body's structure into per-round `KSteps`. That is ONE
  per-semantics walk of each body (driver2's ~8 bind stages + mode
  split + `process_core_step2`'s 12-arm dispatch; dnms' ~3-stage body),
  with all sub-computations opaque behind `app_bind`-inversion.
  *Lineage*: the canonical functional-big-step ↔ small-step
  equivalence proof (interpreter implements the machine); nothing
  novel.
- Pricing (calibrated against T1AppEq's concrete-state `driver2_iter`,
  ~25 lines for one iteration at one state): dnms walk ≈ 40–120 lines
  (its first stage `nd_read (step_ctx …)` is pure-active by `rfl`, so
  only `advance_step` needs opaque casing); driver2 walk ≈ 300–600
  lines. Both are one-time, fixture-independent, and are where S3's
  per-construct laws will attach (each law = one dnms round
  characterized by arena shape).
- Known limitation to carry into the cmm design: at an in-iteration ND
  node (multi-candidate `pick`) the successor degrades to a residual
  atom (the remaining loop re-collapses). Sequential code never hits
  it; the cmm arc should give the scheduler pick a dedicated rule.

## 6. Perf observations vs the S0 guidance

Per-module elaboration (from a forced clean rebuild's `lake build`
lines, verbatim):

```
✔ [361/367] Built RelSem.PerStep (449ms)
✔ [362/367] Built RelSem.PerStepIris (788ms)
✔ [363/367] Built RelSem.PerStepCall (703ms)
✔ [364/367] Built RelSem.PerStepSmoke (951ms)
```

Consistent with S0's guidance: the per-step WP proofs run at 1–2
spatial hypotheses per goal — three orders of magnitude below the
`iframe` cliffs (S0 §3: pressure begins ~n=150). The smoke's eleven
IPM lifting steps + eleven concrete-state `app` equations cost under
a second total. Two S0-flagged habits were baked in: the lifting
rules frame the ONE named state hypothesis (never whole-context
`iframe` sweeps), and no statement anywhere carries a flat ∗-chain.
Default budgets throughout; zero heartbeat/maxRecDepth changes.

Goal-size management ([AGENT] technique, worth carrying to S3): the
post-globals state is kept as the small closed projection term
`sGlob := (app (driver_globals …) init).2` — whnf computes it on
demand inside `rfl` checks while WP goals stay compact; and the one
unification the elaborator could not do syntactically (the thread
record vs the committed `th0`) is discharged as an explicit late
defeq side condition (`k9_update … (by rfl)`), keeping `iapply`
matching syntactic everywhere else.

## 7. Validation

- relsem `lake build` (capped): green, all in-build gates pass —
  `RelSem audit sweep: 3517 declarations … all within the declared
  axiom boundary (0 recorded sorryAx exceptions)` (re-baselined
  3356 → 3517 this slice, provenance comment at the pin),
  `RelSem DAEMON absence gate` OK, `RelSem statement gate: 16 slate
  statements fuel-opsem-clean` (statements untouched).
- `./scripts/test_unit.sh`: `Total: 7 passed, 0 failed`; the S0
  freeze gate line verbatim: `check_chase_freeze: OK — no
  chase-surface imports/uses outside the legacy allowlist (8/8
  allowlisted files present)` — the new modules import NO frozen
  surface (T1AppEq theorem reuse is import-of-an-allowlisted-file's
  EXPORTS, not of the walker).
- `./scripts/test_verify.sh`: `test_verify: 29 passed, 0 failed
  (5 fixtures, 18 harness points)`.
- Axiom cones of every new named theorem, VERBATIM:

```
'RelSem.ksteps_of_runNDFuel' depends on axioms: [propext, Quot.sound]
'RelSem.ksteps_of_runND' depends on axioms: [propext, Quot.sound]
'RelSem.runNDFuel_bind_fuel_irrel' depends on axioms: [propext, Quot.sound]
'RelSem.runNDFuel_succ_congr' depends on axioms: [propext]
'RelSem.kstep_seq_active_inv' does not depend on any axioms
'RelSem.kval_stuck' does not depend on any axioms
'RelSem.Cerb.instLanguageKDrive' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.ksteps_erased' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.ownP_lift_det_step_no_fork' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_seq_active' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_seq_killed' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.wpk_done' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.kAdequate_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.callFinishK_denote' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.callK_denote' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.kCallHarnessAdequate_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.Cerb.kCallHarnessUBFree_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.t1_wpK' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.T1_perStep' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.T1_ubFree_perStep' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
```

  `T1_perStep`'s cone is IDENTICAL to the committed `T1`'s
  (classical trio + the temporal effect boundary's `runEffectful`,
  entering through the quoted harness substrate exactly as before);
  all pins enforced in `RelSem/Audit.lean` (`#guard_msgs`).
- The universe probe (S0-style throwaway, deleted before commit;
  content summary): a `Type 1` Expr with an `{α : Type}`-quantified
  constructor instantiates the pinned iris-lean chain end to end —
  `Language` instance, `WP`, `ownP_adequacy`, `ownP_lift_step` all
  elaborate (the classes are `Type _`-polymorphic); this is the
  measurement behind §2.1's design call.
- No new axioms/sorries; no heartbeat/recursion-depth changes; no
  edits to any statement, any committed theorem text, or any
  existing proof file — the only edits to pre-existing files are
  additive registrations (lakefile roots, RelSemAll imports, Audit
  imports + pins + the sweep re-baseline).
