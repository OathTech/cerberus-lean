# Relational-semantics spike (spike/relsem) — study + design + skeleton

Date: 2026-08-19. Status: SPIKE (design + skeleton deliverable; no merge
bar). Author: relsem spike worker [AGENT]. All recommendations below are
tagged `[AGENT:spike]` and are for operator review, NOT decisions.

Architecture frame (operator-set, fixed): Layer 1 = the generated fuel
opsem (TCB, arcs 1-5). Layer 2 = a relational semantics proved sound
w.r.t. the fuel opsem. Layer 3 = Iris coupled to the relational layer;
adequacy discharges every Iris proof into opsem-only statements. Reference
functions appear in final theorem statements as specification only.

---

## 1a. Study: golean's Layer-2

(Pattern source: /home/dev/projects/cerberus-lean-proj/deps/golean.
file:line references are into that tree.)

**Doctrine first — the naming inverts naive expectations.** golean's
trusted/primary artifact is the FUEL EXECUTABLE; the Prop-level relation
is proof infrastructure at the same trust level as Iris, and is FORBIDDEN
in headline statements (docs/2026-08-03_sem-adequacy-arc.md:27-41;
docs/2026-08-01_tcb-and-layering-doctrine.md:9-46,72-84 — the "deletion
test" and the deprecation of relation-quantified statements). A mechanized
statement-TCB gate walks each headline theorem's statement closure and
fails the build on any Iris constant or any of `Step/Steps/StepE/StepM/…`
(proofs/Audit.lean:112-181,198-207). This matches our operator frame
exactly: Layer 1 is the TCB; Layers 2-3 are proof devices.

- **Fuel opsem (L1):** `stepFn : ExecState → Config → Choices → Except
  GoError (Config × ExecState × Choices)` (GoLean/GoCore/StepFn.lean:82),
  iterated by `runConfig` (:751), `execStmtLoop`/`execStmt` (:799/:820 —
  `execStmt` is the statement-language carrier `sem()`), raw iteration
  `stepFnIter` (:833). Fuel counts machine steps.
- **Relational layer (L2):** configuration = `(Config, ExecState)` pair;
  `Config` is a CK-machine control (stmt/expr + continuation + terminal +
  blocked shapes, Machine.lean:1864-1927); the relation is a ~700-line
  flat inductive `Step : Config → ExecState → Config → ExecState → Prop`
  (Machine.lean:2393) with RT-closure `Steps` (:3113). Pool level:
  `StepE` (spawn-extended per-thread, Multi.lean:1480 — shaped so
  iris-lean's thread-pool Language consumes it verbatim), `StepM` (pool,
  Multi.lean:1508) with relational scheduler latitude `schedPick`
  (Multi.lean:1490).
- **KEY STRUCTURAL TRICK:** relation and stepFn are defined ALONGSIDE
  each other, SHARING PREMISE HELPER FUNCTIONS VERBATIM (`strictPlan`,
  `applyStmtOp`, `enterFrame`, …). Soundness is therefore case analysis
  on the definition tree (`fun_cases`), not simulation induction
  (StepFn.lean:6-11, MachineSound.lean:9-12).
- **Soundness/fuel-erasure lemma shapes** (MachineSound.lean):
  - fuel ⇒ relation: `stepFn_sound : stepFn s c ch = .ok (c', s', ch') →
    Step c s c' s'` (:44); run level `execStmt_sound_normal :
    execStmt fuel env σ ch prog = .ok (.normal σf, ch') →
    Steps (.exec prog env .stop) σ (.next .stop) σf` (:529);
    `stepFnIter_sound` (:546).
  - relation ⇒ fuel: `step_complete : Step c s c' s' → ∃ ch ch', stepFn
    s c ch = .ok (c', s', ch')` (:347). The run-level converse is
    deliberately NOT built (stream-stitching lemma recorded as unneeded,
    :535-545); its replacement is `execStmtLoop_ok_or_fuelOut` (:2437):
    relational Progress ⇒ every bounded fuel run is `.ok` or `.fuelOut`.
  - fuel monotonicity: `execStmtLoop_mono` (:598), `execStmt_mono` (:625).
- **ND/scheduling:** an external oracle stream `Choices := List Nat`
  (State.lean:151) threaded OUTSIDE the state so relation/executable
  compare oracle-free states (:143-146). The executable consumes it at 5
  canonical sites (docs/2026-08-04_nondeterminism-doctrine.md:70-74); the
  relation QUANTIFIES the choice (choice variables are existential in
  rule premises, e.g. `mapIterNext`'s in-range index, Machine.lean:2696;
  pool rules carry `schedPick m i` premises).
- **Iris instance:** sequential `instance : Language Config ExecState
  Unit Unit` with `Val := Unit` (results live in the state), primStep
  wrapping `Step` with `obs = []`, `efs = []`
  (proofs/GoLeanProofs/Lang.lean:25-49); concurrent variants LangC.lean
  (fork fragment) and LangD.lean (decomposed pairing; simulation
  `stepM_erasedD`, LangD.lean:483). Heap resource: `gen_heap` over
  `heapToMap : Heap → ExtTreeMap Nat HeapCell` with proved read/write
  faithfulness bridges (HeapBridge.lean:26-84), state interp = gen_heap
  interp of the denotation ∗ pure wf facts (Ghost.lean:71-75).
- **Adequacy + discharge:** `go_adequacy … : adequate .NotStuck c σ (fun
  v _ => φ v)` (proofs/GoLeanProofs/Adequacy.lean:83-88) with an honesty
  note that deadlock/panic count as stuck (:63-82); the fuel→Iris-trace
  bridge is `steps_erased : Steps c σ c' σ' → ([c], σ) -·->ₜₚ* ([c'], σ')`
  (:133). The exit into fuel-only statements is SurfaceExit.lean:
  `goSpec_of_wp` (:96) chains `execStmt_sound_normal` ⇒ `steps_erased` ⇒
  `adequate_result` for the triple half, and `adequate_not_stuck` ⇒
  `execStmtLoop_ok_or_fuelOut` for the safety half; the conclusion
  `GoSpec` quantifies `execStmt` runs only (Surface.lean:210,384,454) and
  the Surface module is lint-enforced Iris-free (Surface.lean:15-19).

## 1b. Study: iris-lean's language interface

(/home/dev/projects/cerberus-lean-proj/deps/iris-lean, toolchain
4.32.2, upstream leanprover-community/iris-lean @ 79dab15. The
ProgramLogic + HeapLang stack is COMPLETE: zero sorries/axioms in
Iris/ProgramLogic/* and Iris/HeapLang/*, exercised end-to-end by a
closed quicksort adequacy theorem, HeapLang/Lib/Quicksort.lean:362.)

- **What a language must provide** (Iris/ProgramLogic/Language.lean):
  three classes —
  - `ToVal (Expr) (Val : outParam _)`: `toVal : Expr → Option Val`,
    `ofVal : Val → Expr`, laws `coe_of_toVal_eq_some` (toVal e = some v →
    ofVal v = e) and `toVal_coe` (toVal (ofVal v) = some v)
    (Language.lean:34-48).
  - `PrimStep (Expr) (State Obs : outParam _)`: `primStep : Expr × State
    → Obs → Expr × State × List Expr → Prop` — configurations are inline
    pairs; the `List Expr` is forked threads (Language.lean:67-69).
  - `Language (Expr) (State Obs Val : outParam _) extends PrimStep Expr
    State (List Obs), ToVal Expr Val` adding the SINGLE law `val_stuck :
    (e,σ) -<obs>-> (e',σ',eₜ) → toVal e = none` (Language.lean:109-115).
  Total law burden for a bare instance: 3 lemmas. Alternative richer
  entry points: `Language.Context` (Language.lean:269), `EctxLanguage`
  (EctxLanguage.lean:150), `EctxItemLanguage` (EctxiLanguage.lean:18 —
  the HeapLang route; 7 fields).
- **Derived layer:** Reducible/Irreducible/Stuck (Language.lean:85-103),
  thread-pool `Step` (:126), `ErasedStep`/`-·->ₜₚ*` (:165-179), `Atomic`
  (:247), `PureExec` (:422).
- **WP:** `StateInterp` (`stateInterp : State → Nat → List Obs → Nat →
  IProp GF`, WeakestPre.lean:35-42), `IrisGS_gen` (:44-61 — adds
  numLatersPerStep, forkPost, stateInterp_mono), `wp.pre` over primStep
  (:72-83), lifting lemmas in Lifting.lean/EctxLifting.lean.
- **Adequacy entry points** (Iris/ProgramLogic/Adequacy.lean): record
  `adequate (s) (e1) (σ1) (φ : Val → State → Prop)` with fields
  `adequate_result` (erased-trace to a value ⇒ φ) and
  `adequate_not_stuck` (:236-243); master `wp_strong_adequacy_gen`
  (:172-231, conclusion a bare Lean Prop); workhorse `wp_adequacy`
  (:300-337, WP {{v, ⌜φ v⌝}} ⇒ adequate); `wp_invariance` (:339-375);
  safety corollary `adequate_tp_safe` (:265). Termination:
  `twp_total` ⇒ `Relation.StronglyNormalizing ErasedStep ([e], σ)`
  (TotalAdequacy.lean:197-213). Model instance: `heap_adequacy`
  (HeapLang/PrimitiveLaws.lean:129-160).
- **Points-to machinery:** complete gen_heap port —
  `genHeapGS`/`genHeapInterp`/`pointsTo` + alloc/valid/update lemmas
  (Iris/BI/Lib/GenHeap.lean:44-517), over `Std.LawfulFiniteMap`
  (Iris/Std/PartialMap.lean; ExtTreeMap instances in
  Iris/Std/HeapInstances.lean); GhostMap, View/HeapView CMRAs, DFrac.

---

## 2. Design: mapping the pattern onto our substrate

Our Layer 1 differs from golean's in ONE structural way that drives the
whole design: **nondeterminism is already reified as a data structure.**
The generated monad is `ndM a info err cs st = ND (st → nd_action × st)`
(generated/Nondeterminism.lean:101-119) whose `nd_action` nodes are
NDactive / NDkilled / NDnd / NDguard / NDbranch / NDstep — i.e. Layer 1
hands us the full branching tree; golean had to route choices through an
external `Choices` oracle stream precisely because its stepFn returns ONE
successor. We therefore need NO oracle parameter at all: the relation
steps to EVERY successor the current tree node offers, and quantification
over Step-paths IS quantification over schedules/choices. This is
golean's "choice variables are existential in rule premises" pattern
taken to its limit. driver.lem/core_reduction.lem are NOT restructured:
the relation only OBSERVES the generated code through one total function
`app (ND f) st = f st`.

**Configuration.** `Config A I E C S = { expr : MExpr, st : S }` where
`MExpr = running (ndM A I E C S) | done (Outcome A E)` and `Outcome =
value A | killed (kill_reason E)`. The `done` injection exists because
iris-lean's `ToVal` needs value-ness of an expression to be
state-INdependent, and a raw `ndM` cannot reveal `NDactive` without
being applied to a state. Instantiated at the driver:
`DriveConfig = Config driver_result step_kind driver_error
mem_iv_constraint driver_state` — i.e. the REAL generated types:
`driver_state` (Driver.lean:133 — core_file, core_state0 with
thread_states, core_run_state0, layout_state : CerbMem.MemState,
fs_state0, trace, …), result `driver_result` (Driver.lean:400), labels
`step_kind` (Driver.lean:173). The whole-program initial configuration
suspends `drive` (Driver.lean:500) over `initial_driver_state`
(Driver.lean:435).

**Step relation & granularity.** `Step γ : Config → Config → Prop`
(inductive, 7 rules) unfolds the tree once at the current state and
commits to one offered successor: active/killed → `done`; NDnd/NDstep →
membership in the branch list; NDguard → continuation under `γ.sat`;
NDbranch → left arm under `γ.sat`, right arm under `γ.nsat`. Granularity
is therefore "one ND-tree node", which at the driver instantiation is
exactly the granularity the generated scheduler exposes (driver2's
NDnd/NDstep nodes carry whole `core_step2` thread steps — scheduling
choice points, memory action requests, etc.). Anything INSIDE a tree
node (the pure Core-expression evaluator, memory ops) is a single
relational step — which is fine for v0 because those parts are pure
functions of the state, and is revisitable later via a finer relation
for `core_step2` if atomicity demands it (open question Q4).

**Where ND appears.** Three distinct sources, all covered: (1) scheduler
and outcome branching = NDnd/NDstep lists (e.g. `pick` at "driver
non_blocked", Driver.lean:384 → Nondeterminism.lean:257 builds the NDnd
node — the skeleton PROVES both candidates of a 2-way pick are genuine
steps); (2) constraint branching = NDguard/NDbranch, parameterized by a
constraint discipline `CsSem` (sat/nsat : cs → st → Prop) — the
`CsSem.exhaustive` instance reproduces the recorded executable
divergence (no pruning, CerbND.lean:7-14, survey finding 23), and a
future `CsSem.concrete` can encode the OCaml concrete model's `eval_cs`
(impl_mem.ml:321-361) WITHOUT touching the relation; (3) the runner's
trace order (prepend accumulation) is invisible to the relation, as it
should be — the relation defines the SET of executions.

**Where fuel-erasure bites.** Fuel enters Layer 1 in two places:
(a) the arc-3 fuel'd workers (`f_lemFuel : Nat → …` + wrapper
`f = f_lemFuel lemDefaultFuel`, defeq by rfl — the 52 wrapper-defeq
examples of test/Unit/TotalityProofTest.lean); exhaustion is the OPAQUE
`fuelExhausted(With)` sentinel (LemLib.lean:141-150), so no proof can
ever cross an exhausted branch — cone hygiene means fuel-erasure lemmas
are only provable along non-exhausted paths, which is exactly what we
want. (b) `nd_bind` itself is fuel'd (Nondeterminism.lean:167) — bind
fuel bounds tree DEPTH re-distribution.
The relational layer erases fuel by the `∃ fuel` move: e.g. the
pure-expression step `PexprStep … pe pe' := ∃ n,
step_eval_pexpr_lemFuel (n+1) … pe = Result (Defined pe')`
(worker: generated/Core_eval.lean:142; wrapper :148). The wrapper-defeq
hook is what connects this back to the executable default: the skeleton
PROVES (all by rfl) `step_eval_pexpr = step_eval_pexpr_lemFuel
lemDefaultFuel`, `driver2 = driver2_lemFuel lemDefaultFuel`, and the
erasure instance `step_eval_pexpr_lemFuel (n+1) … (PEval v) =
step_eval_pexpr_lemFuel (m+1) … (PEval v)` for all n m (the value case
is fuel-independent), plus its corollary at the default wrapper. The
arc-scale generalization (fuel monotonicity on `Defined` verdicts —
golean's `execStmt_mono` analogue) is stated as future work, not
claimed.

**Soundness lemma shape (the L1↔L2 bridge).** Adopted from golean
`stepFn_sound`/`execStmt_sound_normal`: fuel-runner verdict ⇒ relational
trace. Our executable runner `CerbND.runND` (CerbND.lean:39) is
`partial`, hence opaque to the logic — the skeleton states the bridge
`RunNDActiveSound : (Active r, tr, st') ∈ runND m st → DSteps
⟨running m, st⟩ ⟨done (value r), st'⟩` as a Prop-valued def; the proof
route is open question Q1. The completeness direction (relation ⇒
executable) mirrors golean's `step_complete` and is per-node trivial
here (every Step successor is literally in the tree the runner walks);
run-level completeness is NOT needed (golean precedent: the
stream-stitching converse is recorded as unbuilt and unneeded).

**Memory points-to over CerbMem.MemState.** MemState (CerbMem.lean:119)
is counters + `allocations : List (Int × Allocation)` + `bytemap :
List (Int × AbsByte)`, with leftmost-wins assoc-list semantics (stores
prepend + filter, CerbMem.lean:1097; loads take the first match). The
separation structure is over the DENOTATION, not the list: `heapOf st :
Int → Option AbsByte` (skeleton, proved functional). Iris side (golean
HeapBridge pattern): `heapToMap : MemState → ExtTreeMap Int AbsByte`
with read/write faithfulness bridges, `gen_heap` over it giving
`a ↦{dq} b` at byte granularity; allocation-granular facts (bounds,
isReadonly, lifetime/deadAllocations — skeleton's `OwnsAlloc`) layer
above as derived predicates or a second ghost map keyed by allocation
id. Byte granularity is the honest primitive because the concrete model
really is a bytemap; `mval ↦ ty v` assertions are big-sep bundles of
byte points-tos via the (pure, existing) repr/abst functions.

**Adequacy statement for a library-function harness (libxml2 uri
shape).** Headline form (fuel-opsem-only, relation- and Iris-free,
skeleton's `HarnessAdequate`): for the linked Core file F (harness
calling `xmlParseURISafe` on input s), every triple in
`CerbND.runND (drive tagDefs false F args) (initial_driver_state F fs)`
has verdict `Active r` with `spec r` — where `spec` encodes "r's
dres_core_value equals the pure reference parser's answer on s". The
discharge chain: WP proof ⇒ `wp_adequacy` (Adequacy.lean:300) ⇒
`adequate` over the ND-machine language ⇒ `adequate_result` on each
relational trace ⇒ `RunNDActiveSound` converts runner membership to a
relational trace ⇒ headline. UB shows up as `Outcome.killed (Undef0 …)`
— a VALUE of the machine, not a stuck config, so specs exclude UB
explicitly (stronger and more honest than encoding UB as stuckness;
contrast go_adequacy's deadlock caveat, Adequacy.lean:63-82).

### Open design questions (operator input wanted)

**Q1 — the runND bridge: how does the relation meet the partial
runner?** Options: (a) totalize a MIRROR runner (fuel'd or by
well-founded recursion on the nested-inductive tree via `ndM.rec`) in
the relsem lib, prove mirror sound against `Step` by case analysis
(golean's shared-premise trick applies: the mirror IS `app` + list
recursion), and connect mirror↔`CerbND.runND` by differential testing
only (runND stays the arc-4/5 harness artifact); (b) re-implement
`CerbND.runND` itself as a total function (fuel over tree depth) and
make THAT the Layer-1 runner everywhere, retiring `partial`; (c) leave
the bridge statement `RunNDActiveSound` as the declared seam and prove
adequacy directly against the tree (never mentioning runND).
`[AGENT:spike]` recommend (a) short-term — no churn in the validated
executable, honest proof object, differential harness already exists —
with (b) as the arc-end goal if the mirror and runND are
observably identical on the corpus (they should be: same recursion,
same order).

**Q2 — fuel in the relational layer: ∃-fuel vs default-fuel vs
monotonicity.** The skeleton uses `∃ fuel` in `PexprStep` (erasure by
quantification). Options: (a) keep ∃-fuel and prove per-verdict fuel
MONOTONICITY once, arc-scale (`Defined` at fuel n ⇒ same at n+1 —
golean `execStmt_mono` analogue), making ∃-fuel ↔ default-fuel
interconvertible for terminating runs; (b) fix `lemDefaultFuel` into
the relation via wrapper-defeq (no quantifier, but statements then
depend on a magic number); (c) index the relation by fuel and erase at
the adequacy boundary only. `[AGENT:spike]` recommend (a): the
quantified form is the mathematically honest relation, the wrapper-defeq
hook (proved) plus monotonicity discharges to the executable default,
and the opaque `fuelExhausted` sentinel already guarantees no proof can
smuggle an exhausted branch.

**Q3 — points-to granularity over the bytemap.** Options: (a) byte
points-to `Int ↦ AbsByte` as the ONLY primitive, everything derived;
(b) allocation points-to (`aid ↦ Allocation` + range ownership) as a
second primitive resource (needed for free/kill reasoning and
provenance); (c) typed `ptr ↦ty mval` primitive à la RefinedC.
`[AGENT:spike]` recommend (a) primitive + (b) as a second ghost map, (c)
strictly derived — the concrete memory model's own update discipline is
bytewise, and Allocation-level facts (isReadonly, deadAllocations,
bounds) don't denote into the bytemap, so they need their own resource
anyway.

**Q4 — relation granularity below the driver node.** v0 treats one
ND-tree node as one step; Core pure-expression evaluation happens
INSIDE nodes (it's pure, `step_eval_pexpr`), surfaced separately as
`PexprStep`. If atomicity/invariant-opening ever needs finer driver
steps (e.g. around single memory actions), options: (a) refine the
driver relation to `core_step2` granularity later (additive change —
new rules, same Config); (b) accept node granularity and use Iris
`Atomic`-instance machinery only at node level. `[AGENT:spike]`
recommend deferring: node granularity suffices for the sequential uri
harness (single-thread, no invariants shared across driver steps);
revisit only when a concurrent or invariant-based proof forces it.

---

## 3. Skeleton (compiles on 4.29, no Iris import)

New lib `RelSem` (lakefile.toml `[[lean_lib]]`, srcDir `relsem` — the
one shared-file touch; NOT in defaultTargets; build with
`lake build RelSem`). Files:

- `relsem/RelSem/Machine.lean` — generic ND machine over the generated
  `ndM`: `Outcome`, `MExpr`, `Config`, `toVal/ofVal` (+ BOTH iris-lean
  ToVal laws proved), `app`, `CsSem` (+ `exhaustive`), `Step` (7 rules),
  `Steps` (+ single/trans). Proved: `step_nd_return`, `step_kill`,
  `val_stuck`, `done_irreducible`. All Machine lemmas are AXIOM-FREE.
- `relsem/RelSem/Cerberus.lean` — driver instantiation over the real
  generated types (`DriveConfig`, `γexh`, `DStep/DSteps`, `initConfig`
  over `drive`/`initial_driver_state`); driver-level step existence
  PROVED on the real scheduler combinator (`pick_steps_head/second`);
  `PexprStep` (∃-fuel pure-expression step); wrapper-defeq hooks +
  fuel-erasure value-case instance + `pexprStep_val`, all PROVED by rfl;
  arc-scale statements as Prop-valued defs (`RunNDActiveSound`,
  `DriveReaches` [relation-quantified, proof-infra only],
  `HarnessAdequate` [fuel-opsem-only headline shape]); memory base
  (`heapOf`, `PointsToByte` + proved functionality, `OwnsAlloc`).
  Axiom cones of the proved lemmas: within the declared boundary
  (DAEMON + propext/choice/Quot — same cone class as `driver2` itself;
  no sorryAx anywhere).
- `relsem/RelSem/IrisCoupling.lean` — PAPER-ONLY (comments; no Iris
  import): the intended `ToVal`/`PrimStep`/`Language` instantiation
  field-by-field against Language.lean:34-115, state interpretation via
  gen_heap over the bytemap denotation, and the adequacy pipe.
- House rules kept: zero `sorry`, zero new axioms; `lake build`,
  `./scripts/test_unit.sh` (incl. purity + axiom-cone + totality gates)
  green; no existing file touched except lakefile.toml.

**4.32.2 verification note.** The operator's network window landed
mid-spike: Lean 4.32.2 is installed and deps/iris-lean builds offline.
The IrisCoupling paper design was therefore spot-CHECKED against the
real library: a scratch file (worktree
`lean_frontend/.scratch/iris_coupling_check.lean`, deliberately
UNCOMMITTED — no 4.32 code enters this repo) with shape-faithful
substrate stand-ins (the mutual `ndM`/`nd_action` with the
state-function field), the RelSem machine, and the full
`ToVal`/`PrimStep`/`Language` instantiation typechecks CLEAN under
`lake env lean` against iris-lean @ 4.32.2, with all three laws proved
(`val_stuck` by `cases … <;> rfl`, exactly as the Machine.lean proof
predicts) and the `adequate` record stateable over the instance. The
coupling design is not speculative.

## Q1 AMENDED (operator-prompted, 2026-08-19)

**[USER]** The operator challenged Q1's differential-bridge recommendation:
"why would we need to differentially test vs runND — why can't we prove
it?" **[AGENT]** Resolution, superseding the original recommendation: the
mirror-vs-runND link is unprovable ONLY because runND is a `partial def`
(no kernel equations — the arc-3 pathology, surviving at the top of the
stack because CerbND is hand-written, outside the totality-gate boundary
per arc-4 G3). The correct move is therefore NOT a bridge but
elimination: fuel-totalize runND itself (arc-3 pattern; tree-walk, fuel
on depth, honest sentinel), make the TOTAL runner the production runner,
and prove Step-soundness directly against it. The executable and the
proof object become the same artifact at every level of the stack; the
only remaining differential is the epistemically necessary one (vs
OCaml). Migration safety = the standing OCaml differential corpora
staying green through the swap (the arc-5 seam-change pattern); an
old-vs-new transient check is optional. This amendment is an arc-7
charter input: "totalize CerbND" becomes a Layer-2 prerequisite slice,
and the totality-gate boundary can then extend to CerbND (arc-4 G3
next-arc item, partially discharged).

## Forward-design constraint: concurrency (operator refinement, 2026-08-19)

**[USER]** Temporal boundary entries must not be entrenched by design:
"we should design so we can eventually support concurrency." **[AGENT]**
Layer-2/3 consequences, recorded as arc-7 charter constraints: (1) the
Config/Step design already carries the driver's thread pool
(Step_spawn_threads2/Step_tau2/schedPick are in the generated types the
spike builds on) — keep it that way; do NOT specialize Config to a
single-thread projection for convenience. (2) The cmm stub sits at the
MEMORY-MODEL seam, not the scheduler: the Iris coupling's StateInterp
must be parameterized so a future cmm instantiation replaces the
state-interpretation without reshaping the language instance (iris-lean
supports per-language state interps — the spike's gen_heap choice is the
SC instantiation of a slot, not the slot itself; say so in the
instance's docstring when built). (3) Adequacy statements should
quantify over scheduler behaviors the way the exhaustive driver already
does, so weak-memory ND arrives as MORE behaviors in the same shape,
not a new statement form.

### Prior art for the eventual cmm move (operator pointer, 2026-08-19)

**[USER]** "There's a lot of weak memory + Iris work we can steal from
when we get to the point of use." **[AGENT]** Named anchors to start
from when the concurrency arc opens (references to chase, not
commitments): FSL/FSL++ (Doko & Vafeiadis — fenced separation logic for
C11 atomics, closest in spirit to cerberus's cmm since both target the
Batty et al. C11 model); iRC11 / "RustBelt meets relaxed memory" (Dang
et al. — Iris for the RC11 fragment, the most complete
Iris-on-relaxed-memory stack); GPS (Turon et al. — protocols over
release/acquire); Cosmo (Mével/Jourdan/Pottier — Iris for the Multicore
OCaml model; methodologically useful for how a StateInterp swap looks
in practice); Simuliris and Islaris (relation/simulation machinery and
ISA-level Iris respectively — pattern sources for coupling shapes).
Fit note: cerberus's cmm is the C11 axiomatic model reified in the
model's cmm_csem/cmm_op modules — the operational-vs-axiomatic bridge
these logics build (promising/operational RC11 presentations) is
exactly the seam where our Step-relation parameterization (forward
constraint 2/3 above) must eventually plug in.

### Superseded by the commissioned survey (2026-08-19)

**[USER]** The operator-commissioned weak-memory survey landed:
`2026-08-19_iris-concurrency-weak-memory-survey.md` (mainline docs). It
SUPERSEDES the anchor list above and REVISES forward constraint (2):
**[AGENT]** the cmm move is not only a StateInterp swap — the mature
stack needs view-indexed propositions (vProp), the subjective/objective
split, and objective-only invariants, so the surface logic must not bake
in view-independence of all propositions. Constraint (2) is amended to:
keep the base coupling swappable AND keep the surface-logic proposition
type abstractable (Cosmo's two-level pattern). Constraint (3) stands.
New arc-7+ inputs adopted from the survey: RA+NA finite submodel as the
first concurrency slice (already named in cmm_csem); the two-route
Stage-2 bake-off (cmm_op commitment machine vs AxSL-style opax) as the
selection method; the §7.7 statement discipline (adequacy quantifies
behaviors, never enumerator output, absent a proved completeness);
model-change decisions (e.g. RC11 adoption) are [USER]-only forks.
