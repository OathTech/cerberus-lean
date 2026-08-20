/-
  RelSem.IrisRules — arc-9 S2 (2026-08-20): THE WP RULES, reworked per
  the OwnP adoption (design docs/2026-08-20_arc9-s1-design.md §1.1).

  The arc-7 hand-rolled lifting bodies (~40 IPM lines each: the
  wp_lift_atomic_step shell + ghost agree/update + constructor
  inversion) are RETIRED. Each rule is now a ~10-line wrapper over
  iris-lean's `ownP_lift_atomic_det_step_no_fork` (OwnP.lean:225),
  with
    Hsafe := reducible_of_app_active/_killed  (RelSem/IrisLang.lean)
    Hdet  := step_running_active/_killed_inv  (RelSem/Machine.lean)
      + primStep_inv's empty-forks component
  — the arc-7 determinism inversions ARE OwnP's premises (survey §1.3
  observation, verified by the S2 probe).

  SIGNATURES ARE UNCHANGED from arc-7 (the acceptance test: T1-T4
  re-elaborate with identical statements and axiom cones). `wp_done`
  stays the one-line `wp_value'` reuse; `wp_callND`/`wp_callND_killed`
  stay thin instantiations at `callND`.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.OwnP
import RelSem.IrisState

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

variable {GF : BundledGFunctors} [CerbGS .hasLC GF]
variable {s : Stuckness} {E : CoPset}

/-- RETURN (pure reuse, as arc-7): a `done` configuration is a value;
    its WP is its postcondition. -/
theorem wp_done {o : DriveVal} {Φ : DriveVal → IProp GF} :
    Φ o ⊢ WP (MExpr.done o : DriveExpr) @ s ; E {{ Φ }} :=
  wp_value'

/-- THE DRIVER-STEP LIFTING, active head: a proved `app` equation with
    an active head is one WP step — consume `stateIs σ`, step, hand
    back `stateIs σ'` to the continuation. Now a wrapper over
    `ownP_lift_atomic_det_step_no_fork`; the safety premise is the
    arc-7 reducibility lemma and the determinism premise is the arc-7
    terminal-head inversion. -/
theorem wp_app_active
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {σ σ' : driver_state} {v : driver_result}
    (h : app m σ = (NDactive v, σ'))
    {Φ : DriveVal → IProp GF} :
    stateIs σ ∗ (stateIs σ' -∗ Φ (.value v)) ⊢
      WP (MExpr.running m : DriveExpr) @ s ; E {{ Φ }} := by
  have Hsafe : ReducibleOrNotVal s ((MExpr.running m : DriveExpr), σ) := by
    cases s
    · exact reducible_of_app_active h
    · rfl
  have Hdet : ∀ {obs' : List Empty} {e₂' : DriveExpr} {σ₂' : driver_state}
      {eₜ' : List DriveExpr},
      PrimStep.primStep ((MExpr.running m : DriveExpr), σ) obs'
        (e₂', σ₂', eₜ') →
      σ₂' = σ' ∧ ProgramLogic.toVal e₂'
          = some (Outcome.value v : DriveVal) ∧ eₜ' = [] := by
    intro obs' e₂' σ₂' eₜ' hstep
    obtain ⟨hd, -, hefs⟩ := primStep_inv hstep
    have hconf := step_running_active_inv h hd
    injection hconf with he hσ
    exact ⟨hσ, he ▸ rfl, hefs⟩
  have htriple := ownP_lift_atomic_det_step_no_fork
    (GF := GF) (s := s) (E := E)
    (e₁ := (MExpr.running m : DriveExpr)) (σ₁ := σ) (σ₂ := σ')
    (v₂ := (Outcome.value v : DriveVal)) Hsafe Hdet
  iintro ⟨Hst, HΦ⟩
  iapply htriple $$ Hst HΦ

/-- THE DRIVER-STEP LIFTING, killed head: the UB/error twin. The kill
    verdict is a VALUE of the machine (`Outcome.killed`), so it lands
    in the postcondition and specs EXCLUDE it explicitly — never
    encoded as stuckness (spike honesty note). -/
theorem wp_app_killed
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {σ σ' : driver_state} {r : kill_reason driver_error}
    (h : app m σ = (NDkilled r, σ'))
    {Φ : DriveVal → IProp GF} :
    stateIs σ ∗ (stateIs σ' -∗ Φ (.killed r)) ⊢
      WP (MExpr.running m : DriveExpr) @ s ; E {{ Φ }} := by
  have Hsafe : ReducibleOrNotVal s ((MExpr.running m : DriveExpr), σ) := by
    cases s
    · exact reducible_of_app_killed h
    · rfl
  have Hdet : ∀ {obs' : List Empty} {e₂' : DriveExpr} {σ₂' : driver_state}
      {eₜ' : List DriveExpr},
      PrimStep.primStep ((MExpr.running m : DriveExpr), σ) obs'
        (e₂', σ₂', eₜ') →
      σ₂' = σ' ∧ ProgramLogic.toVal e₂'
          = some (Outcome.killed r : DriveVal) ∧ eₜ' = [] := by
    intro obs' e₂' σ₂' eₜ' hstep
    obtain ⟨hd, -, hefs⟩ := primStep_inv hstep
    have hconf := step_running_killed_inv h hd
    injection hconf with he hσ
    exact ⟨hσ, he ▸ rfl, hefs⟩
  have htriple := ownP_lift_atomic_det_step_no_fork
    (GF := GF) (s := s) (E := E)
    (e₁ := (MExpr.running m : DriveExpr)) (σ₁ := σ) (σ₂ := σ')
    (v₂ := (Outcome.killed r : DriveVal)) Hsafe Hdet
  iintro ⟨Hst, HΦ⟩
  iapply htriple $$ Hst HΦ

/-! ## The call rule (the harness protocol at the WP level).

    `callND`'s app equation IS the caller protocol: startup globals,
    name resolution, the by-pointer argument injection
    (allocate-at-declared-ctype + store + pass pointer,
    RelSem/Call.lean design note), the driver loop on the designated
    body, finalize — all inside one bind-collapsed node. So the call
    rule is the lifting rule instantiated at the harness computation,
    and a slate precondition (T2's no-signed-overflow, T1's int-range)
    is exactly the LEAN HYPOTHESIS under which the active-headed app
    equation is proved. -/

/-- CALL, value case: a proved harness app equation yields the harness
    WP against the initial state cell. -/
theorem wp_callND
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : driver_result} {st' : driver_state}
    (h : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st'))
    {Φ : DriveVal → IProp GF} :
    stateIs (initial_driver_state file1 fs) ∗
      (stateIs st' -∗ Φ (.value r)) ⊢
      WP (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
        @ s ; E {{ Φ }} :=
  wp_app_active h

/-- CALL, killed case (the UB-instance twin — T2's overflow instances
    take this shape at concrete out-of-range points). -/
theorem wp_callND_killed
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : kill_reason driver_error} {st' : driver_state}
    (h : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDkilled r, st'))
    {Φ : DriveVal → IProp GF} :
    stateIs (initial_driver_state file1 fs) ∗
      (stateIs st' -∗ Φ (.killed r)) ⊢
      WP (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
        @ s ; E {{ Φ }} :=
  wp_app_killed h

end Cerb
end RelSem
