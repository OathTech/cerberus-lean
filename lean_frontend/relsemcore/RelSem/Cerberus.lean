/-
  RelSem.Cerberus — spike/relsem (2026-08-19). SPIKE-GRADE SKELETON.

  Instantiation of the generic ND machine (RelSem.Machine) at the REAL
  generated Cerberus driver types, plus:
  * the pure-expression step (Core_eval.step_eval_pexpr) as a fuel-erased
    relation, with a PROVED fuel-erasure instance on the value case;
  * the wrapper-defeq hooks (arc-3 pattern: `f = f_lemFuel lemDefaultFuel`
    by rfl) re-proved here as named theorems so the relational layer can
    cite them;
  * arc-scale soundness/adequacy statement SHAPES as Prop-valued defs
    (stated, not proved — no sorry; the proofs are future-arc work);
  * the memory points-to base over CerbMem.MemState's bytemap.

  Statement-TCB doctrine (adopted from golean,
  deps/golean/docs/2026-08-01_tcb-and-layering-doctrine.md and
  docs/2026-08-03_sem-adequacy-arc.md:27-41): the fuel opsem (Layer 1,
  the generated code + its runners) is the ONLY semantics allowed in
  headline statements; `RelSem.Step`/`Steps` are proof infrastructure at
  the same trust level as Iris, and adequacy must discharge into
  fuel-opsem-only statements. The defs below are tagged accordingly.
-/

import Driver
import Core_eval
import CerbND
import RelSem.Machine
import RelSem.RunND
import RelSem.ExecModel

set_option autoImplicit false

namespace RelSem
namespace Cerb

/-! ## Driver-level configurations over the real generated types -/

/-- Machine expression of a whole-program driver run: `drive` yields
    `ndM driver_result step_kind driver_error mem_iv_constraint
    driver_state` (Driver.lean:500, driverM at Driver.lean:208). -/
abbrev DriveExpr :=
  MExpr driver_result step_kind driver_error mem_iv_constraint driver_state

/-- Whole-program driver configuration. -/
abbrev DriveConfig :=
  Config driver_result step_kind driver_error mem_iv_constraint driver_state

/-- The exhaustive (no constraint pruning) discipline — the one the
    executable runner `CerbND.runND` implements today (CerbND.lean:7-14,
    recorded divergence, survey finding 23). -/
def γexh : CsSem mem_iv_constraint driver_state :=
  CsSem.exhaustive _ _

/-- Driver-level step relation (the Layer-2 relation for Cerberus). -/
abbrev DStep : DriveConfig → DriveConfig → Prop := Step γexh

/-- Its reflexive-transitive closure. -/
abbrev DSteps : DriveConfig → DriveConfig → Prop := Steps γexh

/-- Initial configuration of a linked Core file: the suspended `drive`
    computation (Driver.lean:500) over `initial_driver_state`
    (Driver.lean:435). `with_concurrency` is fixed to `false` — the
    concurrency path is the declared boundary (CONCURRENCY IS BROKEN,
    Driver.lean:512 region). -/
def initConfig (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (args : List String)
    (fs : CerbFS.FsState) : DriveConfig :=
  ⟨.running (drive tagDefs false file1 args), initial_driver_state file1 fs⟩

/-! ## Proved micro-lemmas: the relation computes on real driver objects -/

/-- Existence proof, driver level: the scheduler's `pick` (used by
    `driver2` at "driver non_blocked", Driver.lean:384) with ≥ 2
    candidates offers each candidate as a genuine relational step. This
    is nondeterminism-as-relational-branching on the real generated
    scheduler combinator (pick builds an `NDnd` node,
    Nondeterminism.lean:257). -/
theorem pick_steps_head {A : Type} (info : step_kind) (x y : A)
    (xs : List A) (st : driver_state) :
    Step γexh
      (⟨.running (pick info (x :: y :: xs) :
          ndM A step_kind driver_error mem_iv_constraint driver_state), st⟩ :
        Config A step_kind driver_error mem_iv_constraint driver_state)
      ⟨.running (nd_return x), st⟩ :=
  Step.nd (i := info) (j := info) rfl (List.Mem.head _)

/-- ... and the second candidate too (the branching is real). -/
theorem pick_steps_second {A : Type} (info : step_kind) (x y : A)
    (xs : List A) (st : driver_state) :
    Step γexh
      (⟨.running (pick info (x :: y :: xs) :
          ndM A step_kind driver_error mem_iv_constraint driver_state), st⟩ :
        Config A step_kind driver_error mem_iv_constraint driver_state)
      ⟨.running (nd_return y), st⟩ :=
  Step.nd (i := info) (j := info) rfl (List.Mem.tail _ (by
    -- second element of (info, nd_return x) :: List.map ... (y :: xs)
    exact List.Mem.head _))

/-- MEMORY-OP STEP (continuation, 2026-08-19): a memory-model action with
    an active head, lifted into the driver through the real `liftMem`
    lens (Driver.lean:218), is one driver-level relational step that ends
    `done` with the action's value and writes the new memory state back
    into `layout_state` — the other driver fields untouched. This is the
    node-granularity memory step of the spike design (§2 "granularity"):
    whatever `m` computed inside the memory model (a store, a load, an
    allocation) is one step; its state effect is exactly the
    `layout_state` update. Instantiating `m` with a concrete
    `CerbMem.storeM`/`allocateObject` composition is a `Step`-existence
    fact whenever its `app` equation is established. -/
theorem liftMem_step_active {A : Type}
    {m : ndM A String mem_error (mem_constraint CerbMem.IntegerValue)
        CerbMem.MemState}
    {dr : driver_state} {v : A} {mem' : CerbMem.MemState}
    (h : app m dr.layout_state = (NDactive v, mem')) :
    Step γexh
      (⟨.running (liftMem m), dr⟩ :
        Config A step_kind driver_error mem_iv_constraint driver_state)
      ⟨.done (.value v), { dr with layout_state := mem' }⟩ :=
  Step.active
    (app_liftND_active (fun (dr_st : driver_state) => dr_st.layout_state)
      (fun (dr_st : driver_state) (mem_st : CerbMem.MemState) =>
        { dr_st with layout_state := mem_st })
      (fun (err_str : String) => SK_misc ["memory", err_str])
      (fun (mem_err : mem_error) => DErr_memory mem_err) h)

/-- MEMORY-OP KILL (arc-7 S3, the killed counterpart): a memory-model
    action that KILLS (a memory UB/error verdict) is one driver-level
    `killed` step through the same `liftMem` lens, the reason mapped by
    `liftKill` (memory errors become `DErr_memory`; UB payloads pass
    through untouched) and the memory state written back. -/
theorem liftMem_step_killed {A : Type}
    {m : ndM A String mem_error (mem_constraint CerbMem.IntegerValue)
        CerbMem.MemState}
    {dr : driver_state} {r : kill_reason mem_error}
    {mem' : CerbMem.MemState}
    (h : app m dr.layout_state = (NDkilled r, mem')) :
    Step γexh
      (⟨.running (liftMem m), dr⟩ :
        Config A step_kind driver_error mem_iv_constraint driver_state)
      ⟨.done (.killed
          (liftKill (fun (mem_err : mem_error) => DErr_memory mem_err) r)),
        { dr with layout_state := mem' }⟩ :=
  Step.killed
    (app_liftND_killed (fun (dr_st : driver_state) => dr_st.layout_state)
      (fun (dr_st : driver_state) (mem_st : CerbMem.MemState) =>
        { dr_st with layout_state := mem_st })
      (fun (err_str : String) => SK_misc ["memory", err_str])
      (fun (mem_err : mem_error) => DErr_memory mem_err) h)

/-! ## The pure-expression step (Core_eval), fuel-erased -/

/-- Pure-expression small step: `pe` reduces to `pe'` in the environment
    `(tagDefs, ext, env, mem?, file1)` if SOME fuel'd run of the
    generated worker says so (Core_eval.lean:142). The `∃ fuel` is the
    fuel-erasure move: the relation does not mention a fuel budget, and
    the wrapper-defeq theorems below connect it back to the executable
    default (`step_eval_pexpr = step_eval_pexpr_lemFuel lemDefaultFuel`).
    Sub-`Defined` outcomes (Undef/Error) are deliberately NOT steps: they
    are terminal verdicts, handled at driver level. -/
def PexprStep (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc1 : CerbLocation.Loc) (ext : Fmap sym sym)
    (env : List (Fmap sym value)) (mem? : Option CerbMem.MemState)
    (file1 : file core_run_annotation) (pe pe' : pexpr) : Prop :=
  ∃ fuel : Nat,
    step_eval_pexpr_lemFuel (fuel + 1) tagDefs 0 loc1 none ext env mem?
        file1 false pe
      = Result (Defined pe')

/-! ## Fuel-erasure instances (proved) via the arc-3 wrapper-defeq hook -/

/-- Wrapper-defeq hook for the pure-expression worker (arc-3 pattern;
    cf. test/Unit/TotalityProofTest.lean). Named here so the relational
    layer can cite it. -/
theorem step_eval_pexpr_wrapper_defeq :
    step_eval_pexpr = step_eval_pexpr_lemFuel lemDefaultFuel := rfl

/-- Wrapper-defeq hook for the driver loop (Driver.lean:386). -/
theorem driver2_wrapper_defeq :
    driver2 = driver2_lemFuel lemDefaultFuel := rfl

/-- FUEL ERASURE, proved instance: on an already-evaluated pure
    expression (`PEval v`), the fuel'd worker's verdict is the same at
    EVERY positive fuel — the fuel argument only feeds the recursive
    occurrences, which the value case never takes. Proof is `rfl`:
    both sides reduce past the `Nat.succ` fuel guard into the same
    fuel-free term. -/
theorem step_eval_pexpr_val_fuel_indep
    (n m : Nat) (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (k : Nat) (loc1 : CerbLocation.Loc) (pcl : Option CerbLocation.Loc)
    (ext : Fmap sym sym) (env : List (Fmap sym value))
    (mem? : Option CerbMem.MemState) (file1 : file core_run_annotation)
    (hc : Bool) (ann : List annot) (v : value) :
    step_eval_pexpr_lemFuel (n + 1) tagDefs k loc1 pcl ext env mem? file1 hc
        (Pexpr ann () (PEval v))
      = step_eval_pexpr_lemFuel (m + 1) tagDefs k loc1 pcl ext env mem? file1
        hc (Pexpr ann () (PEval v)) := rfl

/-- The same erasure connected to the DEFAULT-fuel executable wrapper
    (the Layer-1 artifact the differential harness runs): any positive
    fuel agrees with `step_eval_pexpr` on the value case.
    (`lemDefaultFuel = 1000000 = 999999 + 1`, LemLib.lean:60.) -/
theorem step_eval_pexpr_val_erase
    (n : Nat) (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (k : Nat) (loc1 : CerbLocation.Loc) (pcl : Option CerbLocation.Loc)
    (ext : Fmap sym sym) (env : List (Fmap sym value))
    (mem? : Option CerbMem.MemState) (file1 : file core_run_annotation)
    (hc : Bool) (ann : List annot) (v : value) :
    step_eval_pexpr_lemFuel (n + 1) tagDefs k loc1 pcl ext env mem? file1 hc
        (Pexpr ann () (PEval v))
      = step_eval_pexpr tagDefs k loc1 pcl ext env mem? file1 hc
        (Pexpr ann () (PEval v)) :=
  step_eval_pexpr_val_fuel_indep n 999999 tagDefs k loc1 pcl ext env mem?
    file1 hc ann v

/-- A `PexprStep` really holds on a concrete instance: a value pexpr
    re-presents itself as `Defined` (the worker's PEval arm) — witness
    fuel 0(+1), verdict by `rfl`. -/
theorem pexprStep_val
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc1 : CerbLocation.Loc) (ext : Fmap sym sym)
    (env : List (Fmap sym value)) (mem? : Option CerbMem.MemState)
    (file1 : file core_run_annotation) (ann : List annot) (v : value) :
    PexprStep tagDefs loc1 ext env mem? file1
      (Pexpr ann () (PEval v)) (Pexpr [] () (PEval v)) :=
  ⟨0, rfl⟩

/-! ## Arc-scale statements (Prop-valued defs; proofs are future arcs) -/

/-- SOUNDNESS TARGET (relation ⊇ executable runner, the analogue of
    golean's `stepFn_sound`/`execStmt_sound_normal`,
    deps/golean/GoLean/GoCore/MachineSound.lean:44/529): every `Active`
    verdict enumerated by the exhaustive runner is reachable in the
    relation. HISTORY: while `CerbND.runND` was a `partial def` (through
    arc-7 S1) this was the DECLARED SEAM — stated, unprovable (no kernel
    equations). The Q1 AMENDED ruling totalized the runner (arc-7 S2),
    and the seam is now CLOSED by `runNDActiveSound` below. -/
def RunNDActiveSound : Prop :=
  ∀ (m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state)
    (st st' : driver_state) (r : driver_result) (tr : List String),
    (Active r, tr, st') ∈ CerbND.runND m st →
    DSteps ⟨.running m, st⟩ ⟨.done (.value r), st'⟩

/-- The former declared seam, PROVED against the production runner
    (arc-7 S2, the Q1 AMENDED ruling executed): direct corollary of
    `runND_sound` — `Outcome.ofStatus (Active r) = .value r` by rfl and
    `γexh` IS the exhaustive discipline. -/
theorem runNDActiveSound : RunNDActiveSound :=
  fun m st st' r tr h => runND_sound m st (Active r) tr st' h

/-- Whole-program reachability of a result, RELATION-quantified (proof
    infrastructure — never a headline statement, per the golean
    statement-TCB doctrine). -/
def DriveReaches (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (args : List String)
    (fs : CerbFS.FsState) (r : driver_result) (st' : driver_state) : Prop :=
  DSteps (initConfig tagDefs file1 args fs) ⟨.done (.value r), st'⟩

/-- ADEQUACY DISCHARGE SHAPE for a library-function harness (the arc-6
    libxml2 `xmlParseURISafe` shape): the headline statement quantifies
    the FUEL OPSEM's exhaustive outcome set only — no Iris, no `Step` —
    and the reference function (`spec`, e.g. a pure URI parser) appears
    here as specification of the result value, never as proof method.
    An Iris WP proof will discharge into exactly this via:
    WP ⇒ (iris-lean `wp_adequacy`, Iris/ProgramLogic/Adequacy.lean:300)
    `adequate` over `DStep` ⇒ (RunNDActiveSound-style soundness) every
    runner verdict is a relational trace ⇒ this statement. -/
def HarnessAdequate (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (args : List String)
    (fs : CerbFS.FsState) (spec : driver_result → Prop) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (drive tagDefs false file1 args)
        (initial_driver_state file1 fs) →
    ∃ r : driver_result, out = Active r ∧ spec r

/-! ## The parametric adequacy interface, instantiated
    (continuation, 2026-08-19 — the MODEL-PARAMETRICITY principle).

    The adequacy plumbing is stated over the abstract `ExecModel`
    interface (RelSem/ExecModel.lean); `seqModel` below is THE current
    instance — sequential driver-level machine, observable behaviors =
    (outcome, final state) pairs extracted by the fuel-erased TOTAL
    runner (CerbND.runNDFuel, soundness in RelSem/RunND.lean), UB = an
    `Undef0` kill. A concurrency
    instance (candidate-execution behaviors per the cmm direction) or an
    RC11-style instance replaces the `behavior`/`isUB` fields without
    reshaping any `Adequate`-formed statement (fields-only sketch in the
    spike doc's continuation section). `HarnessAdequate` above remains
    the CerbND-shaped HEADLINE form against the production runner; since
    the arc-7 S2 totalization the two speak about the same function
    (`CerbND.runND = CerbND.runNDFuel ndDefaultFuel` by rfl,
    `runND_wrapper_defeq`), and the headline is the instance's
    `Adequate` unfolded at the default budget. -/

/-- Observable behavior of a sequential driver run: terminal outcome +
    final driver state. (Traces are not observable: the runner never
    populates them.) -/
abbrev DriveBehavior := Outcome driver_result driver_error × driver_state

/-- Behavior extraction from one enumerated execution triple. -/
def behaviorOfRun :
    RunResult driver_result driver_error driver_state → DriveBehavior
  | (out, _, st') => (Outcome.ofStatus out, st')

/-- THE sequential instance of the model interface. -/
def seqModel : ExecModel where
  Config := DriveConfig
  Step := DStep
  Behavior := DriveBehavior
  behavior c b :=
    match c.expr with
    | .done o => b = (o, c.st)
    | .running m => ∃ fuel x,
        x ∈ CerbND.runNDFuel fuel m c.st ∧ b = behaviorOfRun x
  isUB b := ∃ loc ubs, b.1 = Outcome.killed (Undef0 loc ubs)

/-- PROVED coherence of the instance: every behavior the model extracts
    is reachable in the Layer-2 relation (via `runNDFuel_sound`). This is
    the instance-level fact the Layer-3 adequacy discharge consumes. -/
theorem seqModel_behavior_sound {c : DriveConfig} {b : DriveBehavior}
    (h : seqModel.behavior c b) : DSteps c ⟨.done b.1, b.2⟩ := by
  cases c with
  | mk e st =>
    cases e with
    | done o =>
      have hb : b = (o, st) := h
      subst hb
      exact Steps.refl
    | running m =>
      cases h with
      | intro fuel h =>
        cases h with
        | intro x h =>
          cases x with
          | mk out p =>
            cases p with
            | mk tr st' =>
              have hb := h.2
              subst hb
              exact runNDFuel_sound fuel m st out tr st' h.1

/-- BEHAVIOR-SET CHARACTERIZATION on a terminal head (arc-7 S3): if the
    suspended computation's one `app` unfolding is ACTIVE, the model
    admits EXACTLY ONE behavior — the value at the post-state. This is
    the model-level face of the ∃-fuel erasure instances
    (`behaviors_active_iff`, RelSem/RunND.lean): on the slate corpus
    (every run one bind-collapsed node, tests/verify trace evidence) a
    single proved `app` equation determines the whole behavior set. -/
theorem seqModel_behavior_running_active_iff
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {st st' : driver_state} {v : driver_result}
    (h : app m st = (NDactive v, st')) (b : DriveBehavior) :
    seqModel.behavior ⟨.running m, st⟩ b ↔ b = (.value v, st') := by
  constructor
  · intro hb
    obtain ⟨fuel, x, hmem, hbx⟩ := hb
    have hx := (behaviors_active_iff h x).mp ⟨fuel, hmem⟩
    subst hx; subst hbx; rfl
  · intro hb
    subst hb
    exact ⟨1, (Active v, [], st'),
      by rw [runNDFuel_active 0 h]; exact List.Mem.head _, rfl⟩

/-- The killed-head counterpart: exactly one behavior, the kill at the
    post-state. -/
theorem seqModel_behavior_running_killed_iff
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {st st' : driver_state} {r : kill_reason driver_error}
    (h : app m st = (NDkilled r, st')) (b : DriveBehavior) :
    seqModel.behavior ⟨.running m, st⟩ b ↔ b = (.killed r, st') := by
  constructor
  · intro hb
    obtain ⟨fuel, x, hmem, hbx⟩ := hb
    have hx := (behaviors_killed_iff h x).mp ⟨fuel, hmem⟩
    subst hx; subst hbx; rfl
  · intro hb
    subst hb
    exact ⟨1, (Killed st' r, [], st'),
      by rw [runNDFuel_killed 0 h]; exact List.Mem.head _, rfl⟩

/-- Layer-2 → adequacy discharge (proved): a relational proof covering
    every `Steps`-reachable terminal configuration discharges into the
    model-parametric adequacy statement. This is the plumbing an Iris
    proof exits through (WP ⇒ iris `adequate` ⇒ per-trace fact ⇒ this). -/
theorem seqModel_adequate_of_reach
    (c : DriveConfig) (spec : DriveBehavior → Prop)
    (h : ∀ b : DriveBehavior, DSteps c ⟨.done b.1, b.2⟩ → spec b) :
    seqModel.Adequate c spec :=
  fun b hb => h b (seqModel_behavior_sound hb)

/-- Model-parametric harness adequacy (the `HarnessAdequate` shape, said
    through the interface): every observable behavior of the initial
    configuration satisfies `spec`. Statement-TCB note: this quantifies
    BEHAVIORS (per the survey §7.7 discipline), not enumerator output;
    the CerbND-shaped headline is recovered per-instance. -/
def HarnessAdequateM
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (args : List String)
    (fs : CerbFS.FsState) (spec : DriveBehavior → Prop) : Prop :=
  seqModel.Adequate (initConfig tagDefs file1 args fs) spec

/-- Model-parametric UB-freedom of a harness. -/
def HarnessUBFree
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (args : List String)
    (fs : CerbFS.FsState) : Prop :=
  seqModel.UBFree (initConfig tagDefs file1 args fs)

/-! ## Memory: the points-to base over CerbMem.MemState -/

/-- Denotation of the bytemap as a partial function. Since arc-6 S3 the
    bytemap is a `Std.TreeMap Int AbsByte` (keyed lookup replaces the
    spike-era leftmost-wins assoc-list denotation — graft fix on
    arc/layer2, 2026-08-19). This finite-map denotation is the carrier
    the Iris `gen_heap` points-to sits on (realized as CerbHeapRA's
    CerbMemInterp, arc-16 S2; the paper-only IrisCoupling.lean sketch
    was deleted at arc-18 R3). -/
def heapOf (st : CerbMem.MemState) (a : Int) : Option CerbMem.AbsByte :=
  st.bytemap.get? a

/-- Assertion-level byte points-to (the model-level shadow of the Iris
    `a ↦ b` resource): address `a` holds abstract byte `b`. -/
def PointsToByte (a : Int) (b : CerbMem.AbsByte)
    (st : CerbMem.MemState) : Prop :=
  heapOf st a = some b

/-- The points-to base is functional — the separation-logic heap is a
    genuine partial function of the address. -/
theorem pointsToByte_functional {a : Int} {b b' : CerbMem.AbsByte}
    {st : CerbMem.MemState}
    (h : PointsToByte a b st) (h' : PointsToByte a b' st) : b = b' := by
  unfold PointsToByte at h h'
  exact Option.some.inj (h.symm.trans h')

/-- Allocation-granular ownership (candidate coarser points-to, open
    question Q3): allocation id `aid` is live with block `alloc`. -/
def OwnsAlloc (aid : Int) (alloc : CerbMem.Allocation)
    (st : CerbMem.MemState) : Prop :=
  st.allocations.get? aid = some alloc
    ∧ aid ∉ st.deadAllocations

end Cerb
end RelSem
