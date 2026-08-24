/-
  RelSem.PerStepIris — arc-16 S1 (2026-08-24): THE PER-STEP LANGUAGE
  INSTANCE + its lifting rules + the adequacy bridge.

  The iris-lean coupling of RelSem/PerStep.lean's KExpr language at the
  driver instantiation. Replaces the arc-7 shell's granularity (one
  atomic whole-run step) with steps at the sequencing joints; the OwnP
  state interpretation is REUSED WHOLESALE from RelSem/IrisState.lean
  (CerbGpreS/CerbGS/stateIs/CerbS unchanged — swapping the language
  did not touch the state layer, as the arc-7 design note promised).

  Design record: docs/2026-08-24_arc16-s1-language-instance.md.
  Language-class call ([AGENT], record §2.3): plain `Language`, not
  `EctxLanguage` — the driver monad is continuation-structured (no
  fill/decompose on `ndM`; evaluation position is always the leading
  atom); `seq` plays the sequencing-context role by construction and
  its WP laws are proved directly below.

  New GENERIC machinery (Iris-compatible, built): the deterministic
  non-atomic lifting rule `ownP_lift_det_step_no_fork` — the library
  ships atomic-det and pure-det variants only; the per-step language
  needs the "deterministic step to a non-value expression" form.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.OwnP
import RelSem.PerStep
import RelSem.IrisState

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

/-! ## The language instance -/

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

/-! ## The deterministic non-atomic lifting rule (GENERIC, built:
    iris-lean ships `ownP_lift_atomic_det_step_no_fork` (successor is
    a value) and `ownP_lift_pure_det_step_no_fork` (state untouched);
    a per-step language needs the mixed form — deterministic state
    change, successor an arbitrary expression). Stated for any
    Language over any OwnP state, shaped for upstreaming. -/

section GenericLifting

variable {Expr State Obs Val : Type _} {GF : BundledGFunctors}
variable [Language Expr State Obs Val] [OwnPGS State GF]
variable {s : Stuckness} {E : CoPset}

theorem ownP_lift_det_step_no_fork {e₁ e₂ : Expr} {σ₁ σ₂ : State}
    {Φ : Val → IProp GF}
    (Hsafe : ReducibleOrNotVal s (e₁, σ₁))
    (Hdet : ∀ {obs' : List Obs} {e₂' : Expr} {σ₂' : State}
        {eₜ' : List Expr},
      PrimStep.primStep (e₁, σ₁) obs' (e₂', σ₂', eₜ') →
      σ₂' = σ₂ ∧ e₂' = e₂ ∧ eₜ' = []) :
    ▷ ownP σ₁ ∗ ▷ (ownP σ₂ -∗ WP e₂ @ s ; E {{ Φ }}) ⊢
      WP e₁ @ s ; E {{ Φ }} := by
  iintro ⟨Hσ₁, Hcont⟩
  iapply ownP_lift_step
  iapply fupd_mask_intro Std.LawfulSet.empty_subset
  iintro Hclose
  iexists σ₁
  iframe Hσ₁ %Hsafe
  iintro !> %obs %e₂' %σ₂' %eₜ' %Hstep Hσ₂
  obtain ⟨rfl, rfl, rfl⟩ := Hdet Hstep
  imod Hclose
  imodintro
  simp only [Algebra.BigOpL.bigOpL_nil]
  iframe
  iapply Hcont $$ Hσ₂

end GenericLifting

/-! ## The per-step WP rules (the S1 lifting set; per-construct laws
    are S3's layer above these) -/

variable {GF : BundledGFunctors} [CerbGS .hasLC GF]
variable {s : Stuckness} {E : CoPset}

/-- RETURN: a `done` configuration is a value. -/
theorem wpk_done {o : DriveVal} {Φ : DriveVal → IProp GF} :
    Φ o ⊢ WP (KExpr.done o : KDriveExpr) @ s ; E {{ Φ }} :=
  wp_value'

/-- SEQ, active head: ONE per-step move — consume `stateIs σ`, step
    the leading atom, hand `stateIs σ'` to the continuation's WP. The
    per-step composition rule the whole-run shell could not express. -/
theorem wpk_seq_active {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {σ σ' : driver_state} {v : α}
    (h : app m σ = (NDactive v, σ'))
    {Φ : DriveVal → IProp GF} :
    stateIs σ ∗ (stateIs σ' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hsafe : ReducibleOrNotVal s ((KExpr.seq m k : KDriveExpr), σ) := by
    cases s
    · exact kreducible_of_app_active h
    · rfl
  have Hdet : ∀ {obs' : List Empty} {e₂' : KDriveExpr}
      {σ₂' : driver_state} {eₜ' : List KDriveExpr},
      PrimStep.primStep ((KExpr.seq m k : KDriveExpr), σ) obs'
        (e₂', σ₂', eₜ') →
      σ₂' = σ' ∧ e₂' = k v ∧ eₜ' = [] := by
    intro obs' e₂' σ₂' eₜ' hstep
    obtain ⟨hd, -, hefs⟩ := kPrimStep_inv hstep
    have hconf := kstep_seq_active_inv h hd
    injection hconf with he hσ
    exact ⟨hσ, he, hefs⟩
  have hlift := ownP_lift_det_step_no_fork
    (GF := GF) (s := s) (E := E)
    (e₁ := (KExpr.seq m k : KDriveExpr)) (e₂ := k v)
    (σ₁ := σ) (σ₂ := σ') (Φ := Φ) Hsafe Hdet
  iintro ⟨Hst, Hcont⟩
  iapply hlift
  iframe Hst
  iintro !> Hst'
  iapply Hcont $$ Hst'

/-- SEQ, killed head: the UB/error twin — the kill is a VALUE
    (`Outcome.killed`), so it lands in the postcondition; specs
    exclude it explicitly (stuckness-honesty, unchanged). -/
theorem wpk_seq_killed {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {σ σ' : driver_state}
    {r : kill_reason driver_error}
    (h : app m σ = (NDkilled r, σ'))
    {Φ : DriveVal → IProp GF} :
    stateIs σ ∗ (stateIs σ' -∗ Φ (.killed r)) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  have Hsafe : ReducibleOrNotVal s ((KExpr.seq m k : KDriveExpr), σ) := by
    cases s
    · exact kreducible_of_app_killed h
    · rfl
  have Hdet : ∀ {obs' : List Empty} {e₂' : KDriveExpr}
      {σ₂' : driver_state} {eₜ' : List KDriveExpr},
      PrimStep.primStep ((KExpr.seq m k : KDriveExpr), σ) obs'
        (e₂', σ₂', eₜ') →
      σ₂' = σ' ∧ ProgramLogic.toVal e₂'
          = some (Outcome.killed r : DriveVal) ∧ eₜ' = [] := by
    intro obs' e₂' σ₂' eₜ' hstep
    obtain ⟨hd, -, hefs⟩ := kPrimStep_inv hstep
    have hconf := kstep_seq_killed_inv h hd
    injection hconf with he hσ
    exact ⟨hσ, he ▸ rfl, hefs⟩
  have htriple := ownP_lift_atomic_det_step_no_fork
    (GF := GF) (s := s) (E := E)
    (e₁ := (KExpr.seq m k : KDriveExpr)) (σ₁ := σ) (σ₂ := σ')
    (v₂ := (Outcome.killed r : DriveVal)) Hsafe Hdet
  iintro ⟨Hst, HΦ⟩
  iapply htriple $$ Hst HΦ

/-! ## The adequacy bridge (statement-facing): WP over the per-step
    instance ⇒ facts about the production runner on the DENOTED
    program. The envelope is exactly the production budget
    (`ksteps_of_runND`; S1 record §2.4 records why the ∃-fuel
    `seqModel.behavior` mid-layer is deliberately bypassed on this
    route). -/

/-- WP ⇒ every production-runner outcome of the denoted program
    satisfies the postcondition. -/
theorem kAdequate_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (e : KDriveExpr) (σ : driver_state) (φ : DriveVal → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) σ) ⊢
        WP e @ Stuckness.NotStuck ; ⊤ {{ o, ⌜φ o⌝ }}) :
    ∀ (out : nd_status driver_result driver_error driver_state)
      (tr : List String) (σ' : driver_state),
      (out, tr, σ') ∈ CerbND.runND e.denote σ →
      φ (Outcome.ofStatus out) := by
  have Had : adequate .NotStuck e σ (fun v _ => φ v) :=
    ownP_adequacy .NotStuck e σ φ Hwp
  intro out tr σ' hmem
  exact Had.adequate_result [] σ' (Outcome.ofStatus out)
    (ksteps_erased (ksteps_of_runND hmem))

end Cerb
end RelSem
