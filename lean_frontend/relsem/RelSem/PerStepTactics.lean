/-
  RelSem.PerStepTactics — arc-16 S3 (2026-08-24): THE WP-TACTIC LAYER.

  Per-construct tactics over the per-step language, packaged in the
  brick-wp mold: every recurring proof step is a LEMMA
  (RelSem/PerStepIris.lean, RelSem/CerbHeapWP.lean; the dormant
  arc-16 PerStepLaws/PerStepPeel half was DELETED at arc-18 C2 per
  the Q1 [USER] ruling — the two live seq laws had already been
  re-homed into PerStepIris at C1), and this layer is
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

import RelSem.PerStepIris
import RelSem.CerbHeapWP
-- arc-17 S0: the named-state emitter (`derive_state` /
-- `derive_state_step`) — the SUPPLY SIDE of `wp_step`'s named-state
-- feeding path (S3 record §7: named-state regime = seconds;
-- compute-forward = the parked wall). Emitted step equations
-- (`…_app` / `expecting`-mode) feed `wp_step` directly; goals ride
-- state NAMES, never inlined records or projection chains.
import RelSem.DeriveState
-- arc-17 S0: the memoized ground-fact discharger backing `wp_side`.
import RelSem.WpGround

set_option autoImplicit false

namespace RelSem
namespace Cerb

open Iris Iris.ProgramLogic Iris.BI

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

-- Arc-18 C2: the OwnP-route step macros (`wp_pure1`/`wp_pures`/
-- `wp_step`/`wp_mode`) and their backing lemmas moved to
-- RelSem/PerStepOwnP.lean with the OwnP surface; the heap-route walk
-- macros live in RelSem/CerbHeapWalk.lean. This module keeps the
-- interpretation-generic pieces (`wp_expose`, `wp_done`, `wp_side`)
-- and the heap op-rule macros.

/-- Value discharge. -/
macro "wp_done" : tactic => `(tactic| iapply wpk_done)

/-! ## Heap-route tactics (consume S2's four op rules UNMODIFIED;
    side conditions computed, resources left to the caller's names) -/

-- arc-17 S0: `wp_side`'s closed-goal engine is the MEMOIZED
-- ground-fact discharger (RelSem/WpGround.lean — the ACL2Lean
-- `proveByDecide`+memo lift; kernel decide only, successes cached,
-- stats via `#wp_ground_stats`). `assumption` keeps hypothesis-fed
-- side conditions first; `rfl` remains for defeq goals without a
-- `Decidable` instance. The old trailing bare `decide` is subsumed:
-- `wp_ground` is kernel decide + memo behind a closed-goal guard.
macro "wp_side" : tactic =>
  `(tactic| first | assumption | wp_ground | rfl)

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
