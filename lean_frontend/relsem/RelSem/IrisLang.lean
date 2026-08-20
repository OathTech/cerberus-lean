/-
  RelSem.IrisLang — arc-7 S4 (2026-08-20): THE LANGUAGE INSTANCE.

  iris-lean (pinned 79dab154a64051384179c4d4e00511752cf2a168, Lean
  4.32.2) coupled to the sequential ExecModel instance: this file
  realizes the spike's typechecked sketch (RelSem/IrisCoupling.lean
  header; docs/2026-08-19_relsem-spike.md §1b/"4.32.2 verification
  note") as load-bearing code.

  Instantiation (field-by-field against
  Iris/ProgramLogic/Language.lean:34-115):

    Expr  := DriveExpr   (MExpr over the real generated driver types)
    Val   := Outcome driver_result driver_error   (`DriveVal`)
    State := driver_state
    Obs   := Empty       (v0: no observations; the step_kind labels in
                          the Step premises can become observations
                          later without reshaping the instance)

  PrimStep wraps ONE `DStep` (the Layer-2 driver relation at the
  exhaustive discipline) with NO forked threads, ever — the driver's
  thread interleaving is reified INSIDE the ndM tree by the generated
  scheduler, so the Iris thread pool stays a singleton (golean's
  sequential-instance pattern; concurrency forward-design constraint 1
  is untouched: the POOL in the generated types is where threads live).

  PARAMETRICITY (charter success condition 4): this is the coupling of
  THE sequential ExecModel instance — `seqModel.Config` IS `⟨expr, st⟩`
  and `seqModel.Step = DStep` definitionally, and every Layer-3 EXIT
  statement (RelSem/IrisAdequacy.lean) lands in
  `seqModel.Adequate`-shaped conclusions. The Language typeclass itself
  is necessarily per-model (Lean instance resolution needs a concrete
  Expr type); the model-generic half of the design is the
  behavior-quantified adequacy SHAPE, not the coupling — recorded in
  docs/2026-08-20_arc7-s4-iris-coupling.md §2.

  House rules: no sorry, no new axioms. Under the in-build audit
  (RelSem/Audit.lean).
-/

import Iris.ProgramLogic.Language
import RelSem.Machine
import RelSem.Cerberus
import RelSem.Call

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris.ProgramLogic

/-- The value type of the coupled language: terminal outcomes. A
    `killed` outcome (UB included) is a VALUE of the machine, not a
    stuck configuration — specs exclude UB explicitly (spike
    stuckness-honesty note). -/
abbrev DriveVal := Outcome driver_result driver_error

/-- The primitive step relation: one Layer-2 driver step, no
    observations, no forks. -/
inductive CerbPrimStep :
    DriveExpr × driver_state → List Empty →
    DriveExpr × driver_state × List DriveExpr → Prop where
  | step {e : DriveExpr} {σ : driver_state} {e' : DriveExpr}
      {σ' : driver_state} :
      DStep ⟨e, σ⟩ ⟨e', σ'⟩ → CerbPrimStep (e, σ) [] (e', σ', [])

/-- THE language instance (all fields at once so the `ToVal`/`PrimStep`
    parents are projections of this single instance — no diamonds).
    The three laws are the spike's proved lemmas. -/
instance instLanguageDrive :
    Language DriveExpr driver_state Empty DriveVal where
  toVal := RelSem.toVal
  ofVal := RelSem.ofVal
  coe_of_toVal_eq_some := RelSem.ofVal_toVal
  toVal_coe := RelSem.toVal_ofVal
  primStep := CerbPrimStep
  val_stuck h := by cases h with | step s => exact RelSem.val_stuck s

/-- `toVal` on the coupled language, computed (`done` configurations
    are values). -/
theorem toVal_done (o : DriveVal) :
    ToVal.toVal (MExpr.done o : DriveExpr) = some o := rfl

/-- `toVal` on a running configuration, computed. -/
theorem toVal_running
    (m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state) :
    ToVal.toVal (MExpr.running m : DriveExpr) = none := rfl

/-! ## Step inversion at the coupled language -/

/-- primStep inversion: a primitive step IS a driver step with no
    observations and no forks. -/
theorem primStep_inv {e : DriveExpr} {σ : driver_state}
    {obs : List Empty} {e' : DriveExpr} {σ' : driver_state}
    {efs : List DriveExpr}
    (h : CerbPrimStep (e, σ) obs (e', σ', efs)) :
    DStep ⟨e, σ⟩ ⟨e', σ'⟩ ∧ obs = [] ∧ efs = [] := by
  cases h with | step s => exact ⟨s, rfl, rfl⟩

/-- An active-headed node is `Reducible` (the lifting rule's safety
    side condition). -/
theorem reducible_of_app_active
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {σ σ' : driver_state} {v : driver_result}
    (h : app m σ = (NDactive v, σ')) :
    PrimStep.Reducible ((MExpr.running m : DriveExpr), σ) :=
  ⟨[], MExpr.done (.value v), σ', [], CerbPrimStep.step (Step.active h)⟩

/-- A killed-headed node is `Reducible`. -/
theorem reducible_of_app_killed
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {σ σ' : driver_state} {r : kill_reason driver_error}
    (h : app m σ = (NDkilled r, σ')) :
    PrimStep.Reducible ((MExpr.running m : DriveExpr), σ) :=
  ⟨[], MExpr.done (.killed r), σ', [], CerbPrimStep.step (Step.killed h)⟩

/-! ## The Layer-2 → thread-pool trace erasure (the adequacy bridge's
    left leg: golean's `steps_erased` analogue). The pool is always the
    singleton `[e]` — no fork rule exists in `CerbPrimStep`. -/

open Language in
/-- One driver step is one erased thread-pool step at the singleton
    pool. -/
theorem erasedStep_of_dstep {c c' : DriveConfig} (h : DStep c c') :
    ErasedStep ([c.expr], c.st) ([c'.expr], c'.st) :=
  ⟨[], Language.Step.atomic (e := c.expr) (e' := c'.expr)
    (CerbPrimStep.step h) [] []⟩

open Language FromMathlib in
/-- `Steps`-traces erase to thread-pool erased traces (singleton pool
    throughout). This is the lemma `adequate_result` consumes. -/
theorem steps_erased {c c' : DriveConfig} (h : DSteps c c') :
    Relation.ReflTransGen ErasedStep ([c.expr], c.st) ([c'.expr], c'.st) := by
  induction h with
  | refl => exact .refl
  | tail _ hs ih => exact .tail ih (erasedStep_of_dstep hs)

end Cerb
end RelSem
