/-
  RelSem.IrisRules — arc-7 S4 (2026-08-20): THE WP RULES, per the
  reuse-vs-build table (docs/2026-08-20_arc7-s4-iris-coupling.md §0.3).

  Built here (table row R3, the ONLY WP-level build): the driver-step
  lifting pair `wp_app_active`/`wp_app_killed` — one rule each
  connecting a Step-visible `app` equation to a WP step over the
  full-state ghost interpretation — by REUSE of iris-lean's
  `wp_lift_atomic_step` shell + the Layer-2 terminal-head determinism
  (`step_running_*_inv`, RelSem/Machine.lean).

  Everything else per the table: return = value-ness of `done`
  (`wp_done`, a one-line reuse of `wp_value'`, row R4); bind/frame/
  mono/wand = iris-lean generics verbatim (row R1/R2); the call rule =
  the lifting rule at `callND` (`wp_callND`/`wp_callND_killed`, rows
  R3/R5 — the by-pointer argument injection is INSIDE the harness app
  equation, and the T2-style precondition is the Lean hypothesis of
  that equation). Points-to (R6/R7) and the loop rule (R8) are
  deliberately NOT here — Layer-2 items / parked, see the table.

  Escalation-rule log for this file: no escalation events — every
  proof is the lifting shell + agree/update on the ghost cell +
  constructor-disjointness inversion.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.Lifting
import RelSem.IrisState

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

variable {hlc : HasLC} {GF : BundledGFunctors} [CerbGS hlc GF]
variable {s : Stuckness} {E : CoPset}

/-- RETURN (table row R4, pure reuse): a `done` configuration is a
    value; its WP is its postcondition. -/
theorem wp_done {o : DriveVal} {Φ : DriveVal → IProp GF} :
    Φ o ⊢ WP (MExpr.done o : DriveExpr) @ s ; E {{ Φ }} :=
  wp_value'

/-- THE DRIVER-STEP LIFTING, active head (table row R3): a proved
    `app` equation with an active head is one WP step — consume
    `stateIs σ`, step, hand back `stateIs σ'` to the continuation.
    On the slate corpus (one bind-collapsed node per run, S3 trace
    evidence) this single rule carries an ENTIRE harness run. -/
theorem wp_app_active
    {m : ndM driver_result step_kind driver_error mem_iv_constraint
        driver_state}
    {σ σ' : driver_state} {v : driver_result}
    (h : app m σ = (NDactive v, σ'))
    {Φ : DriveVal → IProp GF} :
    stateIs σ ∗ (stateIs σ' -∗ Φ (.value v)) ⊢
      WP (MExpr.running m : DriveExpr) @ s ; E {{ Φ }} := by
  iintro ⟨Hst, HΦ⟩
  iapply wp_lift_atomic_step rfl
  iintro %σ₁ %ns %obs %obs' %nt Hσ
  icases (stateInterp_eq σ₁ ns (obs ++ obs') nt).mp $$ Hσ with Hσ
  ihave %heq := stateIs_agree σ₁ σ $$ Hσ Hst
  subst heq
  imodintro
  isplitr
  · ipureintro
    cases s <;> simp only [Stuckness.MaybeReducible]
    exact reducible_of_app_active h
  inext
  iintro %e₂ %σ₂ %eₜ %Hstep Hcred
  obtain ⟨hd, -, hefs⟩ := primStep_inv Hstep
  subst hefs
  have hconf := step_running_active_inv h hd
  injection hconf with he hσ
  subst he; subst hσ
  imod (stateIs_update σ₂ σ₁ σ₁) $$ Hσ Hst with ⟨Hσ', Hst'⟩
  imodintro
  isplitl [Hσ']
  · iapply (stateInterp_eq σ₂ (ns + 1) obs' _).mpr $$ Hσ'
  isplitl [HΦ Hst']
  · iexists (Outcome.value v)
    isplit
    · ipureintro; rfl
    · iapply HΦ $$ Hst'
  · simp only [Algebra.BigOpL.bigOpL_nil]
    itrivial

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
  iintro ⟨Hst, HΦ⟩
  iapply wp_lift_atomic_step rfl
  iintro %σ₁ %ns %obs %obs' %nt Hσ
  icases (stateInterp_eq σ₁ ns (obs ++ obs') nt).mp $$ Hσ with Hσ
  ihave %heq := stateIs_agree σ₁ σ $$ Hσ Hst
  subst heq
  imodintro
  isplitr
  · ipureintro
    cases s <;> simp only [Stuckness.MaybeReducible]
    exact reducible_of_app_killed h
  inext
  iintro %e₂ %σ₂ %eₜ %Hstep Hcred
  obtain ⟨hd, -, hefs⟩ := primStep_inv Hstep
  subst hefs
  have hconf := step_running_killed_inv h hd
  injection hconf with he hσ
  subst he; subst hσ
  imod (stateIs_update σ₂ σ₁ σ₁) $$ Hσ Hst with ⟨Hσ', Hst'⟩
  imodintro
  isplitl [Hσ']
  · iapply (stateInterp_eq σ₂ (ns + 1) obs' _).mpr $$ Hσ'
  isplitl [HΦ Hst']
  · iexists (Outcome.killed r)
    isplit
    · ipureintro; rfl
    · iapply HΦ $$ Hst'
  · simp only [Algebra.BigOpL.bigOpL_nil]
    itrivial

/-! ## The call rule (the harness protocol at the WP level).

    `callND`'s app equation IS the caller protocol: startup globals,
    name resolution, the by-pointer argument injection
    (allocate-at-declared-ctype + store + pass pointer,
    RelSem/Call.lean design note), the driver loop on the designated
    body, finalize — all inside one bind-collapsed node. So the call
    rule is the lifting rule instantiated at the harness computation,
    and a slate precondition (T2's no-signed-overflow, T1's int-range)
    is exactly the LEAN HYPOTHESIS under which the active-headed app
    equation is proved (table row R5). -/

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
