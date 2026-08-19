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
    relation. NOTE `CerbND.runND` is `partial` (opaque to the logic), so
    THIS statement is the bridge obligation as stated against the
    executable; the proof route is a total fuel'd/structural mirror of
    the runner proved equal-by-cases against `Step` (open question Q1 in
    the spike doc). -/
def RunNDActiveSound : Prop :=
  ∀ (m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state)
    (st st' : driver_state) (r : driver_result) (tr : List String),
    (Active r, tr, st') ∈ CerbND.runND m st →
    DSteps ⟨.running m, st⟩ ⟨.done (.value r), st'⟩

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

/-! ## Memory: the points-to base over CerbMem.MemState -/

/-- Leftmost-wins denotation of the associative bytemap
    (CerbMem.lean:119-134; stores prepend fresh entries and filter stale
    ones, CerbMem.lean:1097, loads use the first match). This finite-map
    denotation is the carrier the Iris `gen_heap` points-to will sit on
    (paper design in RelSem/IrisCoupling.lean). -/
def heapOf (st : CerbMem.MemState) (a : Int) : Option CerbMem.AbsByte :=
  (st.bytemap.find? (fun p => p.1 == a)).map (·.2)

/-- Assertion-level byte points-to (the model-level shadow of the Iris
    `a ↦ b` resource): address `a` holds abstract byte `b`. -/
def PointsToByte (a : Int) (b : CerbMem.AbsByte)
    (st : CerbMem.MemState) : Prop :=
  heapOf st a = some b

/-- The points-to base is functional — the separation-logic heap is a
    genuine partial function despite the assoc-list representation. -/
theorem pointsToByte_functional {a : Int} {b b' : CerbMem.AbsByte}
    {st : CerbMem.MemState}
    (h : PointsToByte a b st) (h' : PointsToByte a b' st) : b = b' := by
  unfold PointsToByte at h h'
  exact Option.some.inj (h.symm.trans h')

/-- Allocation-granular ownership (candidate coarser points-to, open
    question Q3): allocation id `aid` is live with block `alloc`. -/
def OwnsAlloc (aid : Int) (alloc : CerbMem.Allocation)
    (st : CerbMem.MemState) : Prop :=
  (st.allocations.find? (fun p => p.1 == aid)).map (·.2) = some alloc
    ∧ aid ∉ st.deadAllocations

end Cerb
end RelSem
