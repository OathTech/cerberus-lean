/-
  RelSem.PerStepOwnP — arc-18 C2 (2026-08-25): THE TRANSITIONAL OwnP
  SURFACE, disentangled from the live route (the C0 contracts doc's
  entry-1 live wrinkle: the OwnP interpretation every landed threaded
  theorem used to bind was DEFINED in the arc-7 module IrisState.lean
  and reused wholesale by PerStepIris.lean — this module is the
  preparatory surgery for both the C2 migration and the C5 purge).

  Contents, all NAME-STABLE moves (statements byte-identical to their
  previous homes; cones pinned unchanged in Audit.lean):

  * from RelSem/IrisState.lean — the OwnP interpretation itself:
    `CerbGpreS`/`CerbGS`/`stateIs` (abbrevs onto the iris-lean OwnP
    library) + the closed functor bundle `CerbS`;
  * from RelSem/PerStepIris.lean — the OwnP lifting layer over the
    per-step language: `ownP_lift_det_step_no_fork` (generic),
    `wpk_seq_active`/`wpk_seq_killed`, the re-homed seq-law faces
    `wpk_seq_active_ecast`/`wpk_seq_active_proj`, and the adequacy
    bridge `kAdequate_of_wp`;
  * from RelSem/PerStepCall.lean — the ambient statement-facing
    bridges `kCallHarnessAdequate_of_wp`/`kCallHarnessUBFree_of_wp`;
  * from RelSem/Threaded.lean — the threaded statement-facing bridges
    `kCallHarnessAdequateThr_of_wp`/`kCallHarnessUBFreeThr_of_wp`;
  * from RelSem/PerStepTactics.lean — the OwnP-route tactic macros
    (`wp_pure1`/`wp_pures`/`wp_step`/`wp_mode`) + `wpk_ite_conj`.

  DIRECTION OF DEPENDENCE (the disentanglement): the live route
  (PerStep/PerStepIris/PerStepCall/Threaded/the heap RA) imports NONE
  of this; this module and the arc-7 shell (IrisState.lean now imports
  it, so the ambient family resolves the same names) sit strictly
  above. Consumers today: the ambient family + the arc-16 smokes
  (retirement-register entry 4, C5) and — until the C2 migration
  lands them on `CerbMemInterp` — the threaded walks. END STATE: the
  migration removes the walk consumers; C5 deletes this module with
  the ambient family.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import Iris.ProgramLogic.OwnP
import RelSem.PerStepIris
import RelSem.PerStepCall
import RelSem.Threaded
import RelSem.LawRegistry
-- for `wp_expose` (the interpretation-generic goal-normalizer the
-- moved macros expand to; PerStepTactics is live-route and imports
-- nothing from this module — the dependence is strictly this way)
import RelSem.PerStepTactics

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

/-! ## The OwnP state interpretation (moved verbatim from
    RelSem/IrisState.lean, arc-9 S2; the arc-7 names are kept so no
    consumer churns) -/

/-- Functor-inclusion prerequisite (pre-allocation form): iris-lean's
    `OwnPGpreS` at `driver_state`. The NAME is kept from arc-7 so the
    adequacy-facing signatures don't churn (S2 abbrev discipline,
    design §1.1; call sites rename at S4 consolidation). -/
abbrev CerbGpreS (GF : BundledGFunctors) : Type := OwnPGpreS driver_state GF

/-- The allocated form: iris-lean's `OwnPGS` at `driver_state`. The
    `hlc` parameter is vestigial (OwnP is `.hasLC`-only upstream) and
    kept solely so arc-7 call sites `[CerbGS .hasLC GF]` re-elaborate
    unchanged; it is IGNORED. -/
abbrev CerbGS (_hlc : HasLC) (GF : BundledGFunctors) : Type :=
  OwnPGS driver_state GF

variable {GF : BundledGFunctors}

/-- The proof-side state assertion: iris-lean's `ownP` (the ExclAuth
    fragment over the full driver state). Kept under the arc-7 name as
    a reducible alias (S2 abbrev discipline). NOTE: the arc-7 `hlc`
    parameter is GONE (OwnP is `.hasLC`-only upstream); the handful of
    `(hlc := .hasLC)` call sites were renamed in the adoption commit. -/
abbrev stateIs [η : OwnPGS driver_state GF] (σ : driver_state) :
    IProp GF :=
  ownP σ

/-! ## A closed functor bundle carrying `CerbGpreS` (the HeapLangS
    pattern, reworked per design §1.1): indices 0-3 are the
    invariant/credit machinery, index 4 the OwnP ExclAuth cell over
    `driver_state` (was: a GhostVar functor). Downstream theorems
    needing a concrete `GF` (the T1-T5 discharges) instantiate at
    `CerbS`. -/

def CerbS : BundledGFunctors
  | 0 => ⟨InvMapF, by infer_instance⟩
  | 1 => ⟨constOF CoPsetDisjL, by infer_instance⟩
  | 2 => ⟨constOF (DisjointLeibnizSet PosSet), by infer_instance⟩
  | 3 => ⟨Auth.AuthURF (constOF Credit), by infer_instance⟩
  | 4 => ⟨ownPRF driver_state, by infer_instance⟩
  | _ => ⟨constOF Unit, by infer_instance⟩

instance instCerbGpreS_CerbS : CerbGpreS CerbS where
  toWsatGpreS := by
    constructor
    · exists 0
    · exists 1
    · exists 2
  toLcGpreS := by
    constructor
    · exists 3
  inG := ⟨4, rfl⟩

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

/-! ## The per-step WP rules at the OwnP interpretation (the S1
    lifting set; moved verbatim from RelSem/PerStepIris.lean) -/

variable {s : Stuckness} {E : CoPset}

/-- SEQ, active head: ONE per-step move — consume `stateIs σ`, step
    the leading atom, hand `stateIs σ'` to the continuation's WP. The
    per-step composition rule the whole-run shell could not express. -/
theorem wpk_seq_active {GF : BundledGFunctors} [CerbGS .hasLC GF]
    {α : Type}
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
theorem wpk_seq_killed {GF : BundledGFunctors} [CerbGS .hasLC GF]
    {α : Type}
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

/-! ## The live seq-law faces (re-homed from PerStepLaws at arc-18 C1,
    then moved here with the OwnP surface at C2: the wp-tactic layer's
    `wp_step`/`wp_pures` backing lemmas; registered in the one
    registry as the wpSeq lane) -/

/-- `wpk_seq_active` with BOTH the expression and the state given up
    to definitional casts (for tactic use: `iapply` unifies at
    reducible transparency, so a proved equation whose atom spelling
    is a computed form of the goal's needs the bridge; both casts
    discharge by `rfl`). -/
@[step_law (kind := wpSeq) (variant := ecast) (side := rfl)
  (frontier := "wp/seq-ecast")
  (trace := "{law := wpk_seq_active_ecast, joint := wp/seq, hyps := [h : fed, he : rfl, hcast : rfl]}")
  (lineage := "HeapLang wp_step shape: one WP step by a proved app equation, endpoints bridged by definitional casts")]
theorem wpk_seq_active_ecast {GF : BundledGFunctors} [CerbGS .hasLC GF]
    {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {e0 : KDriveExpr} {σ0 σ σ' : driver_state}
    {v : α}
    (h : app m σ = (NDactive v, σ'))
    (he : e0 = KExpr.seq m k) (hσ : σ0 = σ)
    {Φ : DriveVal → IProp GF} :
    stateIs σ0 ∗ (stateIs σ' -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP e0 @ s ; E {{ Φ }} :=
  he ▸ hσ ▸ wpk_seq_active h

/-- The self-computing step: the successor state is the projection
    `(app m σ).2` — whnf computes it on demand while goals stay
    compact; the ONE side condition (the head activates) discharges by
    `rfl` when the atom computes. This is `wp_pures`' backing lemma. -/
@[step_law (kind := wpSeq) (variant := proj) (side := rfl)
  (frontier := "wp/seq-proj")
  (trace := "{law := wpk_seq_active_proj, joint := wp/seq, hyps := [h : rfl]}")
  (lineage := "HeapLang wp_pures shape: the self-computing deterministic step, successor as a projection")]
theorem wpk_seq_active_proj {GF : BundledGFunctors} [CerbGS .hasLC GF]
    {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {σ : driver_state} {v : α}
    (h : (app m σ).1 = NDactive v)
    {Φ : DriveVal → IProp GF} :
    stateIs σ ∗ (stateIs (app m σ).2 -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} :=
  wpk_seq_active (show app m σ = (NDactive v, (app m σ).2) by
    rw [← h])

/-! ## The ambient statement-facing bridges (moved verbatim from
    RelSem/PerStepCall.lean; CONCLUSIONS byte-identical to the
    existing statement forms) -/

/-- WP over the per-step instance at the reified harness ⇒ the
    CerbND-shaped HEADLINE (`CallHarnessAdequate`, unchanged): every
    outcome the production runner enumerates for the harness call is
    `Active` and satisfies `spec`. -/
theorem kCallHarnessAdequate_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state file1 fs)) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequate tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [← callK_denote] at hmem
  have hφ := kAdequate_of_wp (GF := GF) (callK tagDefs file1 fname args)
    (initial_driver_state file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    Hwp out tr st' hmem
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- WP over the per-step instance ⇒ the UB-freedom HEADLINE. -/
theorem kCallHarnessUBFree_of_wp {GF : BundledGFunctors} [CerbGpreS GF]
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state file1 fs)) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFree tagDefs file1 fname args fs :=
  callHarnessUBFree_of_callHarnessAdequate
    (kCallHarnessAdequate_of_wp tagDefs file1 fname args fs spec Hwp)

/-! ## The threaded statement-facing bridges (moved verbatim from
    RelSem/Threaded.lean; cones exactly the classical trio) -/

/-- WP over the per-step instance at the reified harness, FROM the
    threaded initial state ⇒ the threaded headline face. -/
theorem kCallHarnessAdequateThr_of_wp {GF : BundledGFunctors}
    [CerbGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state_threaded seed file1 fs)) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessAdequateThr seed tagDefs file1 fname args fs spec := by
  intro out tr st' hmem
  rw [← callK_denote] at hmem
  have hφ := kAdequate_of_wp (GF := GF) (callK tagDefs file1 fname args)
    (initial_driver_state_threaded seed file1 fs)
    (fun o => ∃ r : driver_result, o = Outcome.value r ∧ spec r)
    Hwp out tr st' hmem
  obtain ⟨r, hr, hs⟩ := hφ
  exact ⟨r, ofStatus_value_inv hr, hs⟩

/-- WP over the per-step instance at the threaded state ⇒ the threaded
    UB-freedom headline. -/
theorem kCallHarnessUBFreeThr_of_wp {GF : BundledGFunctors}
    [CerbGpreS GF] (seed : Nat)
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (file1 : file core_run_annotation) (fname : String)
    (args : List value) (fs : CerbFS.FsState)
    (spec : driver_result → Prop)
    (Hwp : ∀ [CerbGS .hasLC GF],
      (stateIs (GF := GF) (initial_driver_state_threaded seed file1 fs)) ⊢
        WP (callK tagDefs file1 fname args)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜∃ r : driver_result, o = Outcome.value r ∧ spec r⌝ }}) :
    CallHarnessUBFreeThr seed tagDefs file1 fname args fs :=
  callHarnessUBFreeThr_of_adequateThr
    (kCallHarnessAdequateThr_of_wp seed tagDefs file1 fname args fs spec Hwp)

/-! ## The OwnP-route tactic macros (moved verbatim from
    RelSem/PerStepTactics.lean; the heap-route macros stay there) -/

/-- The mode-split law in IPM-consumable form (both arms under one
    context; `∧` duplicates it). -/
theorem wpk_ite_conj {GF : BundledGFunctors} [CerbGS .hasLC GF]
    {s : Stuckness} {E : CoPset} {c : Bool} {e₁ e₂ : KDriveExpr}
    {Φ : DriveVal → IProp GF} :
    iprop((WP e₁ @ s ; E {{ Φ }}) ∧ (WP e₂ @ s ; E {{ Φ }})) ⊢
      WP (if c then e₁ else e₂) @ s ; E {{ Φ }} := by
  cases c with
  | false => rw [if_neg Bool.false_ne_true]; exact and_elim_r
  | true => rw [if_pos rfl]; exact and_elim_l

/-- One self-computing deterministic step: the head atom's `app`
    activation is computed by `rfl` AFTER the state is pinned by
    framing `H` (deferred side condition — the S1 late-defeq move). -/
macro "wp_pure1" h:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_active_proj ?wpprf
             rotate_left
             iframe $h:ident
             case wpprf => rfl
             iintro $h:ident))

/-- All available self-computing steps (stops at the first atom whose
    activation does not compute — a genuine law/equation site). -/
macro "wp_pures" h:ident : tactic =>
  `(tactic| repeat wp_pure1 $h)

/-- One step by a proved `app` equation (the seq/bind stepper); the
    goal's state spelling is bridged by a deferred definitional
    check. -/
macro "wp_step" e:term:max h:ident : tactic =>
  `(tactic| (wp_expose
             iapply wpk_seq_active_ecast $e ?wpe ?wpcast
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wpcast => rfl
             iintro $h:ident))

/-- Split the reified scheduler-mode `if` into its two arms (shared
    context). -/
macro "wp_mode" : tactic =>
  `(tactic| (iapply wpk_ite_conj
             isplit))

end Cerb
end RelSem
