/-
  RelSem.SlateWP — arc-7 S5a (2026-08-20): THE FIXTURE-GENERIC WP
  BRIDGE for the slate climb (T2–T5).

  T1 derived its headline through the full WP route inline
  (RelSem/T1.lean t1_wp / t1_of_app_eq — the D5 ruling). The remaining
  slate theorems consume the SAME derivation shape, so it is proved
  once here, generic in the harness parameters: from ONE active app
  equation, (a) the Iris WP for the harness call, (b) the CerbND-shaped
  headline through `callHarnessAdequate_of_wp`, (c) UB-freedom through
  `callUBFree_of_wp`, and (d) the direct-route twin (cross-check per
  D5 — cited, never the deliverable route).

  STATEMENT-TCB: everything CONCLUDED here is ExecModel/CerbND-shaped;
  Iris appears only inside the proofs.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.IrisAdequacy

set_option autoImplicit false

namespace RelSem.Cerb

open Iris Iris.ProgramLogic Iris.BI

/-- THE WP DERIVATION, fixture-generic (T1's `t1_wp` shape): an active
    app equation whose result satisfies `spec` yields the harness WP
    with the value postcondition. -/
theorem wp_of_app_active {GF : BundledGFunctors} [CerbGpreS GF]
    [CerbGS .hasLC GF]
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    {r : driver_result} {st' : driver_state}
    (heq : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st'))
    (hspec : spec r) :
    (stateIs (hlc := .hasLC) (GF := GF)
        (initial_driver_state file1 fs)) ⊢
      WP (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜∃ r' : driver_result, o = Outcome.value r' ∧ spec r'⌝ }} := by
  iintro Hst
  iapply wp_callND heq
  iframe Hst
  iintro Hst'
  ipureintro
  exact ⟨r, rfl, hspec⟩

/-- THE SLATE HEADLINE BRIDGE (the D5 WP route, generic): one active
    app equation with a spec-satisfying result ⇒ the CerbND-shaped
    headline, through WP + adequacy at the closed bundle `CerbS`. -/
theorem callHarnessAdequate_of_app_eq_wp
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    {r : driver_result} {st' : driver_state}
    (heq : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st'))
    (hspec : spec r) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  refine callHarnessAdequate_of_wp (GF := CerbS)
    tagDefs file1 fname args fs spec ?_
  intro η
  exact wp_of_app_active heq hspec

/-- UB-freedom face of the bridge (WP route). -/
theorem callUBFree_of_app_eq_wp
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {r : driver_result} {st' : driver_state}
    (heq : app (callND tagDefs file1 fname args)
        (initial_driver_state file1 fs) = (NDactive r, st')) :
    CallUBFree tagDefs file1 fname args fs := by
  refine callUBFree_of_wp (GF := CerbS)
    tagDefs file1 fname args fs (fun r' => r' = r) ?_
  intro η
  exact wp_of_app_active heq rfl

end RelSem.Cerb
