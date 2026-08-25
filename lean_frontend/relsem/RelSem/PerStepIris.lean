/-
  RelSem.PerStepIris — arc-16 S1 (2026-08-24): THE PER-STEP LANGUAGE
  INSTANCE. Arc-18 C2 (2026-08-25): DISENTANGLED — this module is now
  the INTERPRETATION-FREE language core (the C0 contracts doc's
  entry-1 live wrinkle resolved): the iris-lean `Language` instance at
  the driver instantiation, its inversion/reducibility lemmas, the
  thread-pool trace erasure, and the interpretation-GENERIC value rule
  `wpk_done`. It imports NO state interpretation: the OwnP surface it
  used to reuse from the arc-7 shell (IrisState.lean) lives in the
  transitional RelSem/PerStepOwnP.lean (deletes at C5); the surviving
  interpretation is the heap RA (RelSem/CerbHeapRA.lean), which builds
  ON this module.

  Design record: docs/2026-08-24_arc16-s1-language-instance.md.
  Language-class call ([AGENT], record §2.3): plain `Language`, not
  `EctxLanguage` — the driver monad is continuation-structured (no
  fill/decompose on `ndM`; evaluation position is always the leading
  atom); `seq` plays the sequencing-context role by construction and
  its WP laws are proved per interpretation (PerStepOwnP / CerbHeapWP).

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.WeakestPre
import RelSem.PerStep

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

/-! ## The language instance -/

/-- The value type of the coupled language: terminal outcomes. A
    `killed` outcome (UB included) is a VALUE of the machine, not a
    stuck configuration — specs exclude UB explicitly (spike
    stuckness-honesty note). (Moved from RelSem/IrisLang.lean at
    arc-18 C2, name-stable — the live route defines its own value
    vocabulary; the arc-7 shell now imports it from here.) -/
abbrev DriveVal := Outcome driver_result driver_error

/-- Per-step expressions at the driver instantiation. -/
abbrev KDriveExpr :=
  KExpr driver_result step_kind driver_error mem_iv_constraint
    driver_state

/-- Per-step configurations at the driver instantiation. -/
abbrev KDriveConfig :=
  KConfig driver_result step_kind driver_error mem_iv_constraint
    driver_state

/-- Driver-level per-step relation (exhaustive discipline, as the
    arc-7 `DStep`). -/
abbrev KDStep : KDriveConfig → KDriveConfig → Prop :=
  KStep (CsSem.exhaustive _ _)

/-- Its reflexive-transitive closure. -/
abbrev KDSteps : KDriveConfig → KDriveConfig → Prop :=
  KSteps (CsSem.exhaustive _ _)

/-- The primitive step relation of the coupled language: one `KStep`,
    no observations, no forks (mirror of arc-7's `CerbPrimStep`; the
    thread pool stays a singleton — driver-internal threads live in
    the generated scheduler, concurrency forward-design untouched). -/
inductive KPrimStep :
    KDriveExpr × driver_state → List Empty →
    KDriveExpr × driver_state × List KDriveExpr → Prop where
  | step {e : KDriveExpr} {σ : driver_state} {e' : KDriveExpr}
      {σ' : driver_state} :
      KDStep ⟨e, σ⟩ ⟨e', σ'⟩ → KPrimStep (e, σ) [] (e', σ', [])

/-- THE per-step language instance. -/
instance instLanguageKDrive :
    Language KDriveExpr driver_state Empty DriveVal where
  toVal := KExpr.toVal
  ofVal := KExpr.ofVal
  coe_of_toVal_eq_some := KExpr.ofVal_toVal
  toVal_coe := KExpr.toVal_ofVal
  primStep := KPrimStep
  val_stuck h := by cases h with | step s => exact kval_stuck s

/-- primStep inversion: a primitive step IS a `KDStep` with no
    observations and no forks. -/
theorem kPrimStep_inv {e : KDriveExpr} {σ : driver_state}
    {obs : List Empty} {e' : KDriveExpr} {σ' : driver_state}
    {efs : List KDriveExpr}
    (h : KPrimStep (e, σ) obs (e', σ', efs)) :
    KDStep ⟨e, σ⟩ ⟨e', σ'⟩ ∧ obs = [] ∧ efs = [] := by
  cases h with | step s => exact ⟨s, rfl, rfl⟩

/-- An active-headed `seq` is reducible (the lifting rules' safety
    side condition). -/
theorem kreducible_of_app_active {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {σ σ' : driver_state} {v : α}
    (h : app m σ = (NDactive v, σ')) :
    PrimStep.Reducible ((KExpr.seq m k : KDriveExpr), σ) :=
  ⟨[], k v, σ', [], KPrimStep.step (KStep.seq_active h)⟩

/-- A killed-headed `seq` is reducible. -/
theorem kreducible_of_app_killed {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {σ σ' : driver_state}
    {r : kill_reason driver_error}
    (h : app m σ = (NDkilled r, σ')) :
    PrimStep.Reducible ((KExpr.seq m k : KDriveExpr), σ) :=
  ⟨[], .done (.killed r), σ', [], KPrimStep.step (KStep.seq_killed h)⟩

/-! ## The thread-pool trace erasure (adequacy's left leg; the pool is
    always the singleton — no fork rule exists in `KPrimStep`) -/

open Language in
/-- One per-step move is one erased thread-pool step. -/
theorem kErasedStep_of_kstep {c c' : KDriveConfig} (h : KDStep c c') :
    ErasedStep ([c.expr], c.st) ([c'.expr], c'.st) :=
  ⟨[], Language.Step.atomic (e := c.expr) (e' := c'.expr)
    (KPrimStep.step h) [] []⟩

open Language FromMathlib in
/-- `KDSteps` traces erase to thread-pool traces (singleton pool
    throughout) — what `adequate_result` consumes. -/
theorem ksteps_erased {c c' : KDriveConfig} (h : KDSteps c c') :
    Relation.ReflTransGen ErasedStep
      ([c.expr], c.st) ([c'.expr], c'.st) := by
  induction h with
  | refl => exact .refl
  | tail _ hs ih => exact .tail ih (kErasedStep_of_kstep hs)

/-! ## The interpretation-generic value rule (arc-18 C2: `wpk_done`
    generalized from its arc-16 `[CerbGS]` binder to ANY IrisGS route
    for the per-step language — it is `wp_value'`, which never touches
    the state interpretation; both the transitional OwnP route and the
    heap route consume it). -/

/-- RETURN: a `done` configuration is a value. -/
theorem wpk_done {GF : BundledGFunctors}
    [IrisGS_gen .hasLC KDriveExpr GF]
    {s : Stuckness} {E : CoPset}
    {o : DriveVal} {Φ : DriveVal → IProp GF} :
    Φ o ⊢ WP (KExpr.done o : KDriveExpr) @ s ; E {{ Φ }} :=
  wp_value'

end Cerb
end RelSem
