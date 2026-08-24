/-
  RelSem.WpGround — arc-17 S0 (2026-08-24): THE MEMOIZED GROUND-FACT
  DISCHARGER (charter S0 deliverable (b)).

  DONOR (canon-first lineage; a LIFT, near-verbatim): ACL2Lean's
  `proveByDecide` + memo cache (deps/ACL2Lean/ACL2Lean/Replay/Driver/
  Reflect.lean:93-120; donor review §2 + verdict table row 1). The
  donor's contract, kept exactly:

  * KERNEL DECISION only — synthesize the `Decidable` instance, `whnf`
    at transparency `.all` on `decide p inst`, demand literal
    `Bool.true`, emit `of_decide_eq_true p inst (Eq.refl true)`. "NOT
    heuristic: no simp set, no search." Ban-compliant: the emitted
    proof is kernel-checked ground computation — no `ofReduce*`, no
    native evaluation anywhere (D14 non-kernel-method ban).
  * MEMOIZED on the whole Prop `Expr` (structural `==` with the
    pointer-eq fast path). Donor's measured motivation: 3,869 calls
    ≈ 3.4 s on ONE theorem before memoization — the same small Prop
    set recurs constantly. Our analogue population: the wp-tactic side
    conditions (bounds/compat/atomicity/layout facts — the S3 record's
    "kernel-computable pure facts"; S2's apartness checks will lean on
    this).
  * Only SUCCESSES are cached — failures still hard-fail live
    (fail-closed; a cached failure could mask a fixed input).

  DELIBERATE DEVIATIONS from the donor (recorded per the S0 brief):
  1. Cache statistics (calls/hits/failures) are kept in a second
     `IO.Ref` and loggable via `#wp_ground_stats` — the donor logs no
     cache numbers; our heartbeat doctrine wants the instrument.
  2. The tactic face `wp_ground` guards on CLOSED goals (`hasFVar`/
     `hasExprMVar` → fail fast) so `first`-chains fall through to
     `assumption`-style handling for hypothesis-shaped side
     conditions; the donor's driver only ever passes closed Props.

  WIRING: `wp_side` (RelSem/PerStepTactics.lean) runs
  `assumption | wp_ground | rfl` — the discharger is the engine for
  every closed side condition the heap tactics
  (`wp_load`/`wp_store`/`wp_alloc`/`wp_kill`) compute.

  House rules: no sorry, no axioms; meta code only. Under the
  in-build audit.
-/

import Lean

set_option autoImplicit false

namespace RelSem
namespace WpGround

open Lean Lean.Meta Lean.Elab Lean.Elab.Tactic

/-- Cache statistics (deviation 1: the donor keeps none; our doctrine
    wants the instrument loggable). -/
structure Stats where
  calls : Nat := 0
  hits : Nat := 0
  failures : Nat := 0
  deriving Repr, Inhabited

/-- Memo cache for `proveGround` (donor: `proveByDecideCache`,
    Reflect.lean:99-100). Keyed by the WHOLE Prop `Expr` (structural
    `==` with the pointer-eq fast path). Only SUCCESSFUL proofs are
    cached. -/
initialize groundCache : IO.Ref (Array (Expr × Expr)) ← IO.mkRef #[]

/-- Running statistics for `proveGround` (see `#wp_ground_stats`). -/
initialize groundStats : IO.Ref Stats ← IO.mkRef {}

/-- Prove a decidable proposition `p` by KERNEL DECISION (donor:
    `proveByDecideCore`, Reflect.lean:114-120) — synthesize the
    `Decidable` instance, `whnf` at transparency `.all` on
    `decide p inst`, demand `Bool.true`, emit
    `of_decide_eq_true p inst (Eq.refl true)` (the kernel recomputes
    the reduction at type-checking — recompute-and-check).
    Deterministic ground computation: no simp set, no search.
    Hard-fails if `p` does not reduce to `true`. -/
def proveGroundCore (p : Expr) : MetaM Expr := do
  let inst ← synthInstance (mkApp (mkConst ``Decidable) p)
  let reduced ← withTransparency .all <| whnf (mkApp2 (mkConst ``decide) p inst)
  unless reduced.isConstOf ``Bool.true do
    throwError "wp_ground: proposition did not kernel-reduce to true:{indentExpr p}"
  return mkApp3 (mkConst ``of_decide_eq_true) p inst
    (mkApp2 (mkConst ``Eq.refl [1]) (mkConst ``Bool) (mkConst ``Bool.true))

/-- Memoizing front end (donor: `proveByDecide`, Reflect.lean:108-113).
    Successes cached keyed on `p`; failures propagate uncached. -/
def proveGround (p : Expr) : MetaM Expr := do
  groundStats.modify fun s => { s with calls := s.calls + 1 }
  if let some (_, prf) := (← groundCache.get).find? (·.1 == p) then
    groundStats.modify fun s => { s with hits := s.hits + 1 }
    return prf
  let prf ←
    try proveGroundCore p
    catch e =>
      groundStats.modify fun s => { s with failures := s.failures + 1 }
      throw e
  groundCache.modify (·.push (p, prf))
  return prf

/-- The tactic face: discharge a CLOSED decidable goal by memoized
    kernel decision. Open goals (fvars/mvars) fail fast so `first`
    chains fall through (deviation 2). -/
elab "wp_ground" : tactic => do
  let g ← getMainGoal
  let tgt ← instantiateMVars (← g.getType)
  if tgt.hasExprMVar || tgt.hasFVar then
    throwError "wp_ground: goal is not a closed proposition"
  let prf ← proveGround tgt
  g.assign prf

/-- Log the discharger's cache statistics (calls / memo hits /
    failures / cached entries). -/
elab "#wp_ground_stats" : command => do
  let s ← (groundStats.get : IO Stats)
  let c ← (groundCache.get : IO (Array (Expr × Expr)))
  logInfo s!"wp_ground stats: calls={s.calls} hits={s.hits} \
    failures={s.failures} cached={c.size}"

end WpGround
end RelSem
