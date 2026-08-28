/-
  RelSem.CerbStateStep — V2 (2026-08-28): THE PER-ROUND STATE RULES +
  THE CASE-SPLIT RULES (infrastructure plan component C; the heart).

  Extends the V1 stateWP lane (RelSem/CerbStateWP.lean) with what the
  peeled driver body (RelSem/PerStepPeel.lean) needs:

  * CASE-SPLIT at a symbolic discriminant (`wpk_case_bool` /
    `wpk_case_decide` / `wpk_case_or`) — the historically absent
    capability: one subgoal per arm under the corresponding PATH
    CONDITION. Lineage: RefinedC `typed_if` (deps/refinedc/theories/
    typing/int.v — `typed_if (val_of_bool b)` splits into subgoals
    under `b = true` / `b = false`), BRiCk `wp_if` (stmt.v, ideas
    only), symbolic-execution canon (path conditions). Path conditions
    enter the LEAN context (directly usable by omega/decide — the
    arith side-condition machinery) and lift to ⌜·⌝ at will.
  * supply-moving control rounds (`wpk_seq_ctl_sup`,
    `wpk_seq_ctl_sup_env1`) — body memory rounds draw action ids, so
    the supply component moves with the token.
  * BIRTH rounds (`wpk_seq_birth1`, `wpk_seq_birth1_env1`,
    `wpk_seq_birth2`) — a round that binds a fresh local mints its
    cell against the DOMAIN LEDGER (`domIs`; RelSem/CerbStateRA.lean
    §BIRTH — the gen_heap alloc-fresh analogue).
  * state-value reads (`wpk_seq_read_ctl`) — atoms whose value is a
    state projection (`nd_get`, `get_thread_states`, the peel's
    discovery read): the continuation receives the state VALUE under
    the token's characterization.

  Every rule is an ordinary named theorem, hand-applicable (the
  escalation ladder's floor); the working-tactic faces sit above.

  House rules: no sorry, no new axioms. Under the in-build audit.
-/

import RelSem.CerbStateWP

set_option autoImplicit false

namespace RelSem
namespace CerbSt

open Iris Iris.BI Iris.ProgramLogic
open RelSem.Cerb

variable {GF : BundledGFunctors}

/-! ## THE CASE-SPLIT RULES -/

/-- CASE-SPLIT on a Bool discriminant: prove the WP under each PATH
    CONDITION. The `e`/`P` may mention `b` — each arm's hypothesis
    rewrites the goal closed. -/
@[step_law (kind := stateWP) (variant := caseBool) (side := fed)
  (frontier := "state/case-bool")
  (trace := "{law := wpk_case_bool, joint := state/case-split, hyps := [ht : fed(path true), hf : fed(path false)]}")
  (lineage := "RefinedC typed_if (typing/int.v): one subgoal per arm under the boolean path condition; symbolic-execution canon")]
theorem wpk_case_bool [CerbStGS GF] (b : Bool) {P : IProp GF} {e : KDriveExpr}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (ht : b = true → (P ⊢ WP e @ s ; E {{ Φ }}))
    (hf : b = false → (P ⊢ WP e @ s ; E {{ Φ }})) :
    P ⊢ WP e @ s ; E {{ Φ }} := by
  cases b
  · exact hf rfl
  · exact ht rfl

/-- CASE-SPLIT on a decidable proposition of the symbolic inputs (the
    `x < 0` shape — P01's emblem branch). -/
@[step_law (kind := stateWP) (variant := caseDecide) (side := fed)
  (frontier := "state/case-decide")
  (trace := "{law := wpk_case_decide, joint := state/case-split, hyps := [ht : fed(path p), hf : fed(path ¬p)]}")
  (lineage := "RefinedC typed_if at the Prop face; the path condition is a Lean hypothesis consumable by omega")]
theorem wpk_case_decide [CerbStGS GF] (p : Prop) [Decidable p] {P : IProp GF}
    {e : KDriveExpr}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (ht : p → (P ⊢ WP e @ s ; E {{ Φ }}))
    (hf : ¬ p → (P ⊢ WP e @ s ; E {{ Φ }})) :
    P ⊢ WP e @ s ; E {{ Φ }} := by
  by_cases hp : p
  · exact ht hp
  · exact hf hp

/-- CASE-SPLIT on a structural disjunction (P03's `alias = 0 ∨
    alias = 1` — case vocabulary, not a data domain). -/
@[step_law (kind := stateWP) (variant := caseOr) (side := fed)
  (frontier := "state/case-or")
  (trace := "{law := wpk_case_or, joint := state/case-split, hyps := [hpq : fed(disjunction), h1 : fed, h2 : fed]}")
  (lineage := "structural-disjunction split (the both-alias-arms spec shape); RefinedC case-split-into-subgoals")]
theorem wpk_case_or [CerbStGS GF] {p q : Prop} {P : IProp GF} {e : KDriveExpr}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hpq : p ∨ q)
    (h1 : p → (P ⊢ WP e @ s ; E {{ Φ }}))
    (h2 : q → (P ⊢ WP e @ s ; E {{ Φ }})) :
    P ⊢ WP e @ s ; E {{ Φ }} := by
  rcases hpq with hp | hq
  · exact h1 hp
  · exact h2 hq

/-- The Iris-facing split face: path conditions as ⌜·⌝ premises (the
    RefinedC-shaped subgoal form; derived from `wpk_case_bool`). -/
theorem wpk_if_split [CerbStGS GF] (b : Bool) {e : KDriveExpr}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF} :
    ((⌜b = true⌝ -∗ WP e @ s ; E {{ Φ }}) ∧
     (⌜b = false⌝ -∗ WP e @ s ; E {{ Φ }})) ⊢
      WP e @ s ; E {{ Φ }} := by
  refine wpk_case_bool b ?_ ?_ <;> intro hb
  · iintro ⟨H, -⟩
    iapply H
    ipureintro
    exact hb
  · iintro ⟨-, H⟩
    iapply H
    ipureintro
    exact hb

/-! ## State-value reads: the atom's value is a state projection; the
    continuation receives it under the token's characterization. -/

/-- READ AT THE TOKEN: for a state-preserving atom whose value is the
    projection `g` (`nd_get`: `g = id`; `get_thread_states`; the
    peel's discovery read), the WP of the continuation — proven for
    EVERY state the token admits, with the projection value in hand —
    gives the WP of the sequence. `R` carries the prover's other
    resources through. -/
@[step_law (kind := stateWP) (variant := readCtl) (side := fed)
  (frontier := "state/read-ctl")
  (trace := "{law := wpk_seq_read_ctl, joint := state/read, hyps := [hread : rfl, hwp : fed(per admitted state)]}")
  (lineage := "state-preserving read at the control token (the nd_get joint generalized; HeapLang pure-read analogue)")]
theorem wpk_seq_read_ctl [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {g : driver_state → α} {k : α → KDriveExpr} {c : driver_state}
    {R : IProp GF}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hread : ∀ σ, app m σ = (NDactive (g σ), σ))
    (hwp : ∀ σv, ctlOf σv = c → EnvWf σv →
      ((ctlIs (GF := GF) stHalf c ∗ R : IProp GF) ⊢
        WP (k (g σv)) @ s ; E {{ Φ }})) :
    ctlIs (GF := GF) stHalf c ∗ R ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  iintro ⟨Hc, HR⟩
  iapply wp_lift_step rfl
  iintro %σ %ns %obs %obs' %nt Hσ
  icases cerbStInterp_eq.1 $$ Hσ with Hσ
  icases interp_ctl_agree $$ [$Hσ $Hc] with ⟨%h1, Hσ, Hc⟩
  icases interp_envwf $$ Hσ with ⟨%h2, Hσ⟩
  iapply fupd_mask_intro Std.LawfulSet.empty_subset
  iintro Hclose
  isplitl []
  · ipureintro
    cases s
    · exact kreducible_of_app_active (hread σ)
    · trivial
  iintro !> %e₂ %σ₂ %eₜ %Hprim Hcred
  iclear Hcred
  obtain ⟨hd, -, hefs⟩ := kPrimStep_inv Hprim
  have hconf := kstep_seq_active_inv (hread σ) hd
  injection hconf with he hσ
  subst he; subst hσ; subst hefs
  imod Hclose
  imodintro
  icases cerbStInterp_eq.2 $$ Hσ with Hσ
  iframe Hσ
  simp only [Algebra.BigOpL.bigOpL_nil]
  iframe
  iapply hwp _ h1 h2 $$ [$Hc $HR]

/-! ## Supply-moving control rounds (body memory rounds draw action
    ids; the supply component moves with the token) -/

/-- CONTROL + SUPPLY STEP: as `wpk_seq_ctl`, with the supplies moving
    (both exclusive tokens consumed and returned at the new values). -/
@[step_law (kind := stateWP) (variant := ctlSup) (side := fed)
  (frontier := "state/ctl-sup")
  (trace := "{law := wpk_seq_ctl_sup, joint := state/ctl-sup, hyps := [Happ : fed, transports : fed]}")
  (lineage := "control-token + supply-counter step (ghost_var halves pair; the action-id-drawing round class)")]
theorem wpk_seq_ctl_sup [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {S S' : Supplies}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      (upd σ).layout_state = σ.layout_state)
    (hsup' : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      suppliesOf (upd σ) = S')
    (henvT : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      thread0Env (upd σ) = thread0Env σ) :
    (ctlIs (GF := GF) stHalf c ∗ supIs stHalf S) ∗
      ((ctlIs stHalf c' ∗ supIs stHalf S')
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (Pre := fun σ => (ctlOf σ = c ∧ EnvWf σ) ∧ suppliesOf σ = S)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1.1 hp.1.2 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, Hs⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    icases interp_sup_agree $$ [$Hi $Hs] with ⟨%h3, Hi, Hs⟩
    iframe Hi Hc Hs
    ipureintro
    exact ⟨⟨h1, h2⟩, h3⟩
  · intro σ hp
    iintro ⟨Hi, Hc, Hs⟩
    rw [show c = ctlOf σ from hp.1.1.symm,
      show S = suppliesOf σ from hp.2.symm]
    imod interp_ctl_sup_move (hlay σ hp.1.1 hp.1.2 hp.2)
      (henvT σ hp.1.1 hp.1.2 hp.2) $$ [$Hi $Hc $Hs] with ⟨Hi, Hc, Hs⟩
    imodintro
    rw [hctl' σ hp.1.1 hp.1.2 hp.2, hsup' σ hp.1.1 hp.1.2 hp.2]
    iframe Hi Hc Hs

/-- CONTROL + SUPPLY STEP WITH ONE ENV READ. -/
@[step_law (kind := stateWP) (variant := ctlSupEnv1) (side := fed)
  (frontier := "state/ctl-sup-env1")
  (trace := "{law := wpk_seq_ctl_sup_env1, joint := state/ctl-sup-env1, hyps := [Happ : fed(one-cell lookup), transports : fed]}")
  (lineage := "supply-moving control step characterized by one owned env cell at a symbolic value")]
theorem wpk_seq_ctl_sup_env1 [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {S S' : Supplies}
    {x : sym} {vx : value} {dq : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      envLookup σ x = some vx → app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      envLookup σ x = some vx → ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      envLookup σ x = some vx →
      (upd σ).layout_state = σ.layout_state)
    (hsup' : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      envLookup σ x = some vx → suppliesOf (upd σ) = S')
    (henvT : ∀ σ, ctlOf σ = c → EnvWf σ → suppliesOf σ = S →
      envLookup σ x = some vx →
      thread0Env (upd σ) = thread0Env σ) :
    (ctlIs (GF := GF) stHalf c ∗ supIs stHalf S ∗ envIs x dq vx) ∗
      ((ctlIs stHalf c' ∗ supIs stHalf S' ∗ envIs x dq vx)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (Pre := fun σ => ((ctlOf σ = c ∧ EnvWf σ) ∧ suppliesOf σ = S) ∧
      envLookup σ x = some vx)
    (upd := upd)
    ?_ (fun σ hp => Happ σ hp.1.1.1 hp.1.1.2 hp.1.2 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, Hs, He⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    icases interp_sup_agree $$ [$Hi $Hs] with ⟨%h3, Hi, Hs⟩
    icases interp_env_lookup $$ [$Hi $He] with ⟨%h4, Hi, He⟩
    iframe Hi Hc Hs He
    ipureintro
    exact ⟨⟨⟨h1, h2⟩, h3⟩, h4⟩
  · intro σ hp
    iintro ⟨Hi, Hc, Hs, He⟩
    rw [show c = ctlOf σ from hp.1.1.1.symm,
      show S = suppliesOf σ from hp.1.2.symm]
    imod interp_ctl_sup_move
      (hlay σ hp.1.1.1 hp.1.1.2 hp.1.2 hp.2)
      (henvT σ hp.1.1.1 hp.1.1.2 hp.1.2 hp.2)
      $$ [$Hi $Hc $Hs] with ⟨Hi, Hc, Hs⟩
    imodintro
    rw [hctl' σ hp.1.1.1 hp.1.1.2 hp.1.2 hp.2,
      hsup' σ hp.1.1.1 hp.1.1.2 hp.1.2 hp.2]
    iframe Hi Hc Hs He

/-! ## BIRTH rounds: a step that binds a FRESH local mints its cell
    against the domain ledger (RelSem/CerbStateRA §BIRTH). -/

/-- BIRTH of one cell (supply-preserving; the pattern-bind tau round). -/
@[step_law (kind := stateWP) (variant := birth1) (side := fed)
  (frontier := "state/birth1")
  (trace := "{law := wpk_seq_birth1, joint := state/birth, hyps := [Happ : fed, hfresh : ground(ledger), transports : fed]}")
  (lineage := "gen_heap alloc-fresh at the locals view: ledger freshness certifies the coherence-auth insert (HeapLang wp_alloc shape)")]
theorem wpk_seq_birth1 [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {x : sym} {vNew : value} {d : List Int}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hfresh : symNum x ∉ d)
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ →
      (upd σ).layout_state = σ.layout_state)
    (hsup : ∀ σ, ctlOf σ = c → EnvWf σ →
      suppliesOf (upd σ) = suppliesOf σ)
    (hnew : ∀ σ, ctlOf σ = c → EnvWf σ →
      envLookup (upd σ) x = some vNew)
    (hpres : ∀ σ, ctlOf σ = c → EnvWf σ →
      ∀ z v', envLookup σ z = some v' →
        envLookup (upd σ) z = some v')
    (hrev : ∀ σ, ctlOf σ = c → EnvWf σ →
      ∀ z v', envLookup (upd σ) z = some v' →
        (∃ v₀, envLookup σ z = some v₀) ∨ symNum z = symNum x)
    (hwfp : ∀ σ, ctlOf σ = c → EnvWf σ → EnvWf (upd σ)) :
    (ctlIs (GF := GF) stHalf c ∗ domIs stHalf d) ∗
      ((ctlIs stHalf c' ∗ domIs stHalf (symNum x :: d)
          ∗ envIs x (.own 1) vNew)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det (Pre := fun σ => ctlOf σ = c ∧ EnvWf σ)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, Hd⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    iframe Hi Hc Hd
    ipureintro
    exact ⟨h1, h2⟩
  · intro σ hp
    iintro ⟨Hi, Hc, Hd⟩
    rw [show c = ctlOf σ from hp.1.symm]
    imod interp_ctl_dom_birth1 x (hlay σ hp.1 hp.2) (hsup σ hp.1 hp.2)
      hfresh (hnew σ hp.1 hp.2) (hpres σ hp.1 hp.2)
      (hrev σ hp.1 hp.2) (fun _ => hwfp σ hp.1 hp.2)
      $$ [$Hi $Hc $Hd] with ⟨Hi, Hc, Hd, He⟩
    imodintro
    rw [hctl' σ hp.1 hp.2]
    iframe Hi Hc Hd He

/-- BIRTH of one cell while READING one owned cell (the Erun/eval
    round that binds the jump argument from a looked-up local). -/
@[step_law (kind := stateWP) (variant := birth1env1) (side := fed)
  (frontier := "state/birth1-env1")
  (trace := "{law := wpk_seq_birth1_env1, joint := state/birth, hyps := [Happ : fed(one-cell lookup), hfresh : ground, transports : fed]}")
  (lineage := "birth + read in one round (the label-jump bind class)")]
theorem wpk_seq_birth1_env1 [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {x : sym} {vNew : value} {d : List Int}
    {y : sym} {vy : value} {dqy : DFrac}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hfresh : symNum x ∉ d)
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      (upd σ).layout_state = σ.layout_state)
    (hsup : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      suppliesOf (upd σ) = suppliesOf σ)
    (hnew : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      envLookup (upd σ) x = some vNew)
    (hpres : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      ∀ z v', envLookup σ z = some v' →
        envLookup (upd σ) z = some v')
    (hrev : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      ∀ z v', envLookup (upd σ) z = some v' →
        (∃ v₀, envLookup σ z = some v₀) ∨ symNum z = symNum x)
    (hwfp : ∀ σ, ctlOf σ = c → EnvWf σ → envLookup σ y = some vy →
      EnvWf (upd σ)) :
    (ctlIs (GF := GF) stHalf c ∗ domIs stHalf d ∗ envIs y dqy vy) ∗
      ((ctlIs stHalf c' ∗ domIs stHalf (symNum x :: d)
          ∗ envIs x (.own 1) vNew ∗ envIs y dqy vy)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det
    (Pre := fun σ => (ctlOf σ = c ∧ EnvWf σ) ∧
      envLookup σ y = some vy)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1.1 hp.1.2 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, Hd, Hy⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    icases interp_env_lookup $$ [$Hi $Hy] with ⟨%h3, Hi, Hy⟩
    iframe Hi Hc Hd Hy
    ipureintro
    exact ⟨⟨h1, h2⟩, h3⟩
  · intro σ hp
    iintro ⟨Hi, Hc, Hd, Hy⟩
    rw [show c = ctlOf σ from hp.1.1.symm]
    imod interp_ctl_dom_birth1 x (hlay σ hp.1.1 hp.1.2 hp.2)
      (hsup σ hp.1.1 hp.1.2 hp.2) hfresh (hnew σ hp.1.1 hp.1.2 hp.2)
      (hpres σ hp.1.1 hp.1.2 hp.2) (hrev σ hp.1.1 hp.1.2 hp.2)
      (fun _ => hwfp σ hp.1.1 hp.1.2 hp.2)
      $$ [$Hi $Hc $Hd] with ⟨Hi, Hc, Hd, He⟩
    imodintro
    rw [hctl' σ hp.1.1 hp.1.2 hp.2]
    iframe Hi Hc Hd He Hy

/-- BIRTH of two cells in one round (the pair-pattern bind). -/
@[step_law (kind := stateWP) (variant := birth2) (side := fed)
  (frontier := "state/birth2")
  (trace := "{law := wpk_seq_birth2, joint := state/birth, hyps := [Happ : fed, hfresh12/hne : ground(ledger), transports : fed]}")
  (lineage := "two-cell alloc-fresh (the weak-pair bind round class)")]
theorem wpk_seq_birth2 [CerbStGS GF] {α : Type}
    {m : ndM α step_kind driver_error mem_iv_constraint driver_state}
    {k : α → KDriveExpr} {v : α} {upd : driver_state → driver_state}
    {c c' : driver_state} {x₁ x₂ : sym} {v₁ v₂ : value} {d : List Int}
    {s : Stuckness} {E : CoPset} {Φ : DriveVal → IProp GF}
    (hfresh₁ : symNum x₁ ∉ d) (hfresh₂ : symNum x₂ ∉ d)
    (hne : symNum x₁ ≠ symNum x₂)
    (Happ : ∀ σ, ctlOf σ = c → EnvWf σ →
      app m σ = (NDactive v, upd σ))
    (hctl' : ∀ σ, ctlOf σ = c → EnvWf σ → ctlOf (upd σ) = c')
    (hlay : ∀ σ, ctlOf σ = c → EnvWf σ →
      (upd σ).layout_state = σ.layout_state)
    (hsup : ∀ σ, ctlOf σ = c → EnvWf σ →
      suppliesOf (upd σ) = suppliesOf σ)
    (hnew₁ : ∀ σ, ctlOf σ = c → EnvWf σ →
      envLookup (upd σ) x₁ = some v₁)
    (hnew₂ : ∀ σ, ctlOf σ = c → EnvWf σ →
      envLookup (upd σ) x₂ = some v₂)
    (hpres : ∀ σ, ctlOf σ = c → EnvWf σ →
      ∀ z v', envLookup σ z = some v' →
        envLookup (upd σ) z = some v')
    (hrev : ∀ σ, ctlOf σ = c → EnvWf σ →
      ∀ z v', envLookup (upd σ) z = some v' →
        (∃ v₀, envLookup σ z = some v₀) ∨ symNum z = symNum x₁ ∨
          symNum z = symNum x₂)
    (hwfp : ∀ σ, ctlOf σ = c → EnvWf σ → EnvWf (upd σ)) :
    (ctlIs (GF := GF) stHalf c ∗ domIs stHalf d) ∗
      ((ctlIs stHalf c' ∗ domIs stHalf (symNum x₁ :: symNum x₂ :: d)
          ∗ envIs x₁ (.own 1) v₁ ∗ envIs x₂ (.own 1) v₂)
        -∗ WP (k v) @ s ; E {{ Φ }}) ⊢
      WP (KExpr.seq m k : KDriveExpr) @ s ; E {{ Φ }} := by
  refine wpk_seq_res_det (Pre := fun σ => ctlOf σ = c ∧ EnvWf σ)
    (upd := upd) ?_ (fun σ hp => Happ σ hp.1 hp.2) ?_
  · intro σ
    iintro ⟨Hi, Hc, Hd⟩
    icases interp_ctl_agree $$ [$Hi $Hc] with ⟨%h1, Hi, Hc⟩
    icases interp_envwf $$ Hi with ⟨%h2, Hi⟩
    iframe Hi Hc Hd
    ipureintro
    exact ⟨h1, h2⟩
  · intro σ hp
    iintro ⟨Hi, Hc, Hd⟩
    rw [show c = ctlOf σ from hp.1.symm]
    imod interp_ctl_dom_birth2 x₁ x₂ (hlay σ hp.1 hp.2)
      (hsup σ hp.1 hp.2) hfresh₁ hfresh₂ hne (hnew₁ σ hp.1 hp.2)
      (hnew₂ σ hp.1 hp.2) (hpres σ hp.1 hp.2) (hrev σ hp.1 hp.2)
      (fun _ => hwfp σ hp.1 hp.2)
      $$ [$Hi $Hc $Hd] with ⟨Hi, Hc, Hd, He₁, He₂⟩
    imodintro
    rw [hctl' σ hp.1 hp.2]
    iframe Hi Hc Hd He₁ He₂

/-! ## The registry-backing check (R4 contract, extending the
    CerbStateWP one to the V2 lane). -/
open Lean in
#eval show Lean.Elab.Term.TermElabM Unit from do
  let backing : List Name :=
    [``RelSem.CerbSt.wpk_case_bool, ``RelSem.CerbSt.wpk_case_decide,
     ``RelSem.CerbSt.wpk_case_or, ``RelSem.CerbSt.wpk_seq_read_ctl,
     ``RelSem.CerbSt.wpk_seq_ctl_sup,
     ``RelSem.CerbSt.wpk_seq_ctl_sup_env1,
     ``RelSem.CerbSt.wpk_seq_birth1,
     ``RelSem.CerbSt.wpk_seq_birth1_env1,
     ``RelSem.CerbSt.wpk_seq_birth2]
  for n in backing do
    let some _ ← RelSem.LawRegistry.byName? n
      | throwError "CerbStateStep registry-backing check: the V2 rule {n} is NOT registered (R4)"
  Lean.logInfo s!"CerbStateStep registry-backing check:    {backing.length} V2 rules registered"

end CerbSt
end RelSem
