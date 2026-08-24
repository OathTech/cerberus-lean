/-
  RelSem.PerStepTactics — arc-16 S3 (2026-08-24): THE WP-TACTIC LAYER.

  Per-construct tactics over the per-step language, packaged in the
  brick-wp mold: every recurring proof step is a LEMMA
  (RelSem/PerStepLaws.lean, RelSem/CerbHeapWP.lean), and this layer is
  deliberately THIN — macros that apply the lemma, route the one state
  hypothesis (named selectively — S0's iframe-width discipline), and
  discharge side conditions by kernel computation
  (`rfl`/`decide`/`assumption` — ban-compliant reflection only).

  Donors (attribution): iris-lean `Iris/HeapLang/{Tactic,ProofMode}.lean`
  — the `wp_pures`/`wp_load`/… vocabulary and the tactic-per-construct
  packaging; brick-wp (deps/brick-wp) — the lemmas-plus-thin-tactics
  factoring. The donor's Qq redex/points-to SEARCH (HeapLang's
  `findECtx`/`lookupPointsTo`) is the named upgrade path if goal
  shapes outgrow syntactic application — part-2 work, priced in the
  S3 record; nothing here steers elaboration blindly: each macro's
  one-sentence contract is "apply the named law; compute the side
  conditions".

  Vocabulary:
  * `wp_pure1 H` / `wp_pures H` — one/all self-computing deterministic
    steps (the `wp_pures` analogue: the head atom's `app` computes by
    whnf; states stay compact as `(app m σ).2` projections).
  * `wp_step e H`   — one step by a PROVED app equation `e` (the
    seq/bind stepper; state spelling bridged by a deferred `rfl`).
  * `wp_mode`       — split the opaque scheduler-mode `if` (both arms).
  * `wp_done`       — value discharge (`wpk_done`).
  * `wp_load/wp_store/wp_alloc/wp_kill` — the S2 HEAP rules, side
    conditions discharged by `assumption`/`rfl`/`decide`; resource
    splitting stays with the caller (footprint names are theirs).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.PerStepLaws
import RelSem.CerbHeapWP

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

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

open Lean Elab Tactic Meta in
/-- Expose the WP goal's head redex: definitionally normalize the
    expression under `WP` to weak head normal form (a `change`, so the
    step is an ordinary kernel-checked defeq). The analogue of the
    HeapLang donor's `wp_expr_simp`/`tac_wp_expr_simp`: `iapply`'s
    unification is reducible-transparency, so continuation `match`es
    over computed driver values must be reduced explicitly before a
    step rule can see the next `seq` joint. No-op when the head is
    already exposed. -/
elab "wp_expose" : tactic => do
  let g ← getMainGoal
  let tgt ← instantiateMVars (← g.getType)
  let some wpApp := tgt.find? (fun t =>
      t.isAppOf ``Iris.Wp.wp && t.getAppNumArgs ≥ 9)
    | throwError "wp_expose: no WP application in the goal"
  let args := wpApp.getAppArgs
  let eIdx := args.size - 2
  let e := args[eIdx]!
  let e' ← whnf e
  if e == e' then
    return ()
  let wpApp' := mkAppN wpApp.getAppFn (args.set! eIdx e')
  let tgt' := tgt.replace (fun t => if t == wpApp then some wpApp' else none)
  let g' ← g.change tgt'
  replaceMainGoal [g']

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

/-- Value discharge. -/
macro "wp_done" : tactic => `(tactic| iapply wpk_done)

/-! ## Heap-route tactics (consume S2's four op rules UNMODIFIED;
    side conditions computed, resources left to the caller's names) -/

macro "wp_side" : tactic =>
  `(tactic| first | assumption | rfl | decide)

macro "wp_load" : tactic =>
  `(tactic| iapply (wpk_load (hbounds := by wp_side)
      (hatomic := by wp_side) (hlen := by wp_side)
      (hrecon := by wp_side) (hnotbool := by wp_side)))

macro "wp_store" : tactic =>
  `(tactic| iapply (wpk_store (hcompat := by wp_side)
      (hbounds := by wp_side) (hro := by wp_side)
      (hatomic := by wp_side) (hbytes := by wp_side)
      (hlen := by wp_side)))

macro "wp_alloc" : tactic =>
  `(tactic| iapply (wpk_alloc (hsz := by wp_side)
      (haddr := by wp_side) (hnz := by wp_side)))

macro "wp_kill" : tactic =>
  `(tactic| iapply (wpk_kill (hbase := by wp_side)))

end Cerb
end RelSem
