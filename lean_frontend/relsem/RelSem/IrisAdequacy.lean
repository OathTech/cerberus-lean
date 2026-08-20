/-
  RelSem.IrisAdequacy — arc-7 S4 (2026-08-20): THE ADEQUACY THEOREM.

  Iris WP judgment on the harness configuration ⇒ ExecModel-level
  behavior statement. The discharge chain (spike design, realized):

    Hwp : stateIs init ⊢ WP (running (callND …)) {{ o, ⌜φ o⌝ }}
      ⇒ iris-lean `wp_adequacy_gen` (Iris/ProgramLogic/Adequacy.lean:302)
        [ghost cell allocated + split at the initial state]
      ⇒ `adequate .NotStuck … (fun v _ => φ v)`
      ⇒ per behavior b: `callOutcomes_sound` (S3) gives a DSteps trace,
        `steps_erased` (IrisLang) erases it to a thread-pool trace,
        `adequate_result` fires on it
      ⇒ `CallAdequate … (fun b => φ b.1)`  — seqModel.Adequate at
        callConfig: THE ExecModel-shaped conclusion.

  STATEMENT-TCB: the CONCLUSION mentions only ExecModel-level objects
  (`CallAdequate`/`CallHarnessAdequate` — runner outcomes); Iris
  appears only in the discharged HYPOTHESIS. S5's slate theorems are
  direct corollaries: `callHarnessAdequate_of_wp` below lands exactly
  the CerbND-shaped headline form.

  FALLBACK STATUS (charter, pre-approved restricted-Config fallback):
  NOT TAKEN — no restriction on the harness configuration class was
  needed; the theorem covers every `callConfig`.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.Adequacy
import RelSem.IrisRules

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

/-- THE ADEQUACY THEOREM: an Iris WP for the harness computation —
    against the SC state interpretation, provable at ANY functor
    bundle carrying the prerequisites — discharges into the
    model-parametric adequacy of the harness configuration. -/
theorem callAdequate_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (φ : DriveVal → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (hlc := .hasLC) (GF := GF)
          (initial_driver_state file1 fs)) ⊢
        WP (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
          @ Stuckness.NotStuck ; ⊤ {{ o, ⌜φ o⌝ }}) :
    CallAdequate tagDefs file1 fname args fs (fun b => φ b.1) := by
  -- Leg 1: the iris-lean adequacy record for the coupled language.
  have Had : adequate .NotStuck
      (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
      (initial_driver_state file1 fs) (fun v _ => φ v) := by
    refine wp_adequacy_gen (GF := GF) (hlc := .hasLC) .NotStuck _ _ φ ?_
    intro Hinv κs
    imod (ghost_var_alloc (initial_driver_state file1 fs)) with ⟨%γ, Hγ⟩
    letI η : CerbGS .hasLC GF := ⟨γ⟩
    have hsplit : ⊢@{IProp GF}
        (γ ↪VAR (initial_driver_state file1 fs)) -∗
          stateIs (hlc := .hasLC) (initial_driver_state file1 fs) ∗
          stateIs (initial_driver_state file1 fs) := by
      have h0 := ghost_var_split (GF := GF) γ
        (initial_driver_state file1 fs) (1 : Qp).half (1 : Qp).half
      rw [Qp.half_add_half] at h0
      exact h0
    icases hsplit $$ Hγ with ⟨Hσ, Hst⟩
    iexists (fun σ _ => stateIs (hlc := .hasLC) (GF := GF) σ)
    iexists (fun _ => iprop(True))
    dsimp only
    ihave Hwp' := (@Hwp η) $$ Hst
    iframe Hσ
    imodintro
    -- The premise's WP is stated over `instIrisGSDrive η`; the goal's is
    -- over the `IrisGS_gen.mk` term `wp_adequacy_gen` builds from the
    -- witnesses. The two instances are definitionally equal field-by-field
    -- (same invGS, same interpretation, 0 laters, True forkPost; the mono
    -- proofs are irrelevant), so drop to a plain entailment and close by
    -- defeq.
    irevert Hwp'
    istop
    exact Iris.BI.entails_wand Iris.BI.BIBase.Entails.rfl
  -- Leg 2: every model behavior is a relational trace, every relational
  -- trace erases to a thread-pool trace, and the adequacy record fires.
  intro b hb
  exact Had.adequate_result [] b.2 b.1 (steps_erased (callOutcomes_sound hb))

/-- COROLLARY (the S5 discharge shape): a WP with the value-shaped
    postcondition yields the CerbND-shaped HEADLINE
    (`CallHarnessAdequate`: fuel opsem only — the statement form of
    every slate theorem). -/
theorem callHarnessAdequate_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (hlc := .hasLC) (GF := GF)
          (initial_driver_state file1 fs)) ⊢
        WP (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequate tagDefs file1 fname args fs spec :=
  callHarnessAdequate_of_adequate
    (callAdequate_of_wp tagDefs file1 fname args fs
      (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r) Hwp)

/-- COROLLARY: value-shaped adequacy is UB-freedom (a value behavior is
    never classified UB) — pure ExecModel plumbing, no Iris. -/
theorem callUBFree_of_value_adequate
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {file1 : file core_run_annotation} {fname : String}
    {args : List value} {fs : CerbFS.FsState}
    {spec : driver_result → Prop}
    (h : CallAdequate tagDefs file1 fname args fs
      (fun b => ∃ r : driver_result, b.1 = .value r ∧ spec r)) :
    CallUBFree tagDefs file1 fname args fs :=
  ExecModel.Adequate.mono h
    (fun _ hv hub =>
      match hv, hub with
      | ⟨_, hr, _⟩, ⟨_, _, hu⟩ => by rw [hr] at hu; exact (nomatch hu))

/-- COROLLARY: the WP premise also yields UB-freedom of the call. -/
theorem callUBFree_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (hlc := .hasLC) (GF := GF)
          (initial_driver_state file1 fs)) ⊢
        WP (MExpr.running (callND tagDefs file1 fname args) : DriveExpr)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallUBFree tagDefs file1 fname args fs :=
  callUBFree_of_value_adequate
    (callAdequate_of_wp tagDefs file1 fname args fs
      (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r) Hwp)

end Cerb
end RelSem
