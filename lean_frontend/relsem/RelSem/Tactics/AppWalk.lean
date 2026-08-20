/-
  RelSem.Tactics.AppWalk — arc-9 S2 (2026-08-20): THE WALKER (L2,
  design docs/2026-08-20_arc9-s1-design.md §1.3).

  Architecture = golean's `go_walk` law-table core retargeted to PURE
  app-equation goals; discipline = brick-wp's measured lessons:
  dispatch is GOAL-GUARDED (DiscrTree match on the goal head before
  any apply; failed candidates restore state), and the mechanical/
  semantic division is absolute — side hypotheses are discharged ONLY
  by assumption / registered-law one-shots / rfl; anything else stays
  a goal for an explicit `app_walk_step` (golean GoWalk.lean:52-56:
  "a tactic that guessed at those would be guessing at the
  semantics").

  Tactics:
  * `app_walk` / `app_walk n` — the loop: match the goal LHS head in
    the `@[app_eq]` law table, apply the one lemma whose side
    hypotheses discharge mechanically, chain by `Eq.trans`, repeat;
    stops (goal untouched by the failed attempt) at the first
    configuration no law covers, closing the goal by `rfl` if the two
    sides meet.
  * `app_walk_step e` — apply ONE explicit block equation `e` (the
    manual-step primitive the proof-size bar counts): closes the goal
    with `e` or chains `Eq.trans e ?_`.
  * `app_walk_finish e` — walk, then the goal MUST close with `e`.
  * `app_walk?` — `app_walk 1` + report which law fired (debugging
    only; grep-banned from committed proofs by
    scripts/check_proof_size.sh).

  Meta-code residency (design §1.3): `partial` is allowed here (inside
  the tactic monad only); every proof produced is kernel-checked and
  swept by the in-build audit; the D14 ban applies to outputs via the
  axiom gates.

  House rules: no sorry, no axioms.
-/

import Lean
import RelSem.Tactics.AppEqAttr

set_option autoImplicit false

open Lean Meta Elab Tactic

namespace RelSem.Tactics

/-- Run one candidate attempt under its OWN heartbeat window, capped
    BELOW the ambient budget (golean GoWalk discipline: per-candidate
    try under saved state with a small budget — this lowers, never
    raises), with runtime exceptions (the heartbeat trip) catchable so
    a stuck attempt fails fast instead of killing the elaboration. -/
def attempt {α : Type} (hb : Nat) (x : MetaM α) : MetaM (Option α) := do
  let curMax := (← readThe Core.Context).maxHeartbeats
  let hb := if curMax == 0 then hb else min hb curMax
  Core.withCurrHeartbeats do
    withTheReader Core.Context
        (fun ctx => { ctx with maxHeartbeats := hb }) do
      tryCatchRuntimeEx
        (try
          return some (← x)
        catch _ =>
          return none)
        (fun _ => return none)

/-- The per-candidate heartbeat window (a quarter of the default
    200000; every legitimate mechanical discharge measured so far fits
    well under it). -/
def candidateBudget : Nat := 50000 * 1000

/-- Head-normalize a computed value into a constructor SPINE, to
    bounded depth: `whnf` at each level, recursing into constructor
    arguments only. This is the discovery normalizer: lazy unification
    would otherwise assign computed values (the `step_ctx` results) as
    unreduced redexes that no registered law's DiscrTree key can see.
    Payloads below the depth bound ride as delivered (defeq is what
    the kernel checks; the spine is what dispatch needs). -/
partial def normSpine : Nat → Expr → MetaM Expr
  | 0, e => return e
  | d + 1, e => do
    let e ← whnf e
    let f := e.getAppFn
    match f with
    | .const n _ =>
      match (← getEnv).find? n with
      | some (.ctorInfo _) =>
        let args ← e.getAppArgs.mapM fun a => do
          if (← instantiateMVars (← inferType a)).isSort then
            pure a
          else
            normSpine d a
        return mkAppN f args
      | _ => return e
    | _ => return e

/-- Discharge one side hypothesis of a candidate law, mechanically:
    computed-value assignment (normalize-and-assign for a bare-mvar
    RHS), `assumption`, then (for app-equation hyps) a one-shot
    registered law whose own hypotheses discharge recursively, then
    `rfl` (definitional unfolding — the T1-round move). Anything else:
    failure (the law does not apply). -/
partial def dischargeHyp (fuel : Nat) (h : MVarId) : MetaM Bool := do
  if (← h.isAssigned) then return true
  let ty ← instantiateMVars (← h.getType)
  -- (0) computed-value hypothesis: `lhs = ?m` with a bare unassigned
  -- mvar RHS — normalize the computation's spine and assign.
  if let some (_, lhs, rhs) := ty.eq? then
    if rhs.isMVar then
     if !(← rhs.mvarId!.isAssigned) then
      let st ← saveState
      match ← attempt candidateBudget (do
          let v ← normSpine 4 lhs
          if (← isDefEq rhs v) then
            h.assign (← mkEqRefl lhs)
            return true
          else
            return false) with
      | some true => return true
      | _ => restoreState st
  -- (i) assumption (range/overflow side conditions from the context)
  if (← observing? h.assumption).isSome then return true
  match fuel, ty.eq? with
  | fuel + 1, some (_, lhs, _) =>
    -- (ii) one-shot registered law on an app-shaped hypothesis
    let lhs ← whnfCore lhs
    let cands ← appEqMatches lhs
    for law in cands do
      let st ← saveState
      let res ← attempt candidateBudget (do
        let lemExpr ← mkConstWithFreshMVarLevels law.name
        let (args, _, lemTy) ← forallMetaTelescopeReducing
          (← inferType lemExpr)
        unless (← isDefEq lemTy ty) do return false
        let mut ok := true
        for a in args do
          if a.isMVar then
            if !(← a.mvarId!.isAssigned) then
              if (← isProp (← inferType a)) then
                unless (← dischargeHyp fuel a.mvarId!) do
                  ok := false
                  break
        unless ok do return false
        -- any remaining non-Prop arg mvars must be determined
        let proof ← instantiateMVars (mkAppN lemExpr args)
        if proof.hasExprMVar then
          return false
        h.assign proof
        return true)
      match res with
      | some true => return true
      | _ => restoreState st
    -- (iii) rfl (definitional computation) — NOT for `app`-shaped
    -- hypotheses: every app-crossing must go through a registered law
    -- (a raw-whnf'd crossing would synthesize junk states that defeat
    -- both dispatch and term-size hygiene; the walker STOPS instead,
    -- leaving the crossing to an explicit `app_walk_step`).
    if lhs.isAppOf `RelSem.app then
      return false
    let st ← saveState
    let res ← attempt candidateBudget (do
      let some (_, lhs', rhs') := (← instantiateMVars (← h.getType)).eq?
        | return false
      if (← isDefEq lhs' rhs') then
        h.assign (← mkEqRefl lhs')
        return true
      else
        return false)
    match res with
    | some true => return true
    | _ => restoreState st; return false
  | _, _ =>
    -- non-equation Prop that `assumption` missed: try rfl-style decide?
    -- No: mechanical means mechanical. Fail.
    return false

/-- One walker round on goal `app C σ = R`: try registered laws
    most-specific-first; on success return the fired law's name and
    the continuation goal (none when the goal is CLOSED terminally). -/
partial def walkOnce (goal : MVarId) (verbose : Bool := false) :
    TacticM (Option (Name × Option MVarId)) := do
  goal.withContext do
  let tgt ← instantiateMVars (← goal.getType)
  let some (α, lhs, rhs) := tgt.eq? | return none
  let lhs ← whnfCore lhs
  let cands ← appEqMatches lhs
  if verbose then
    logInfo m!"app_walk?: {cands.size} candidate(s):       {cands.map (·.name)}"
  for law in cands do
    let st ← saveState
    let res ← attempt candidateBudget (do
      let lemExpr ← mkConstWithFreshMVarLevels law.name
      let (args, _, lemTy) ← forallMetaTelescopeReducing
        (← inferType lemExpr)
      let some (_, lemLhs, lemRhs) := lemTy.eq? | return none
      unless (← isDefEq lemLhs lhs) do return none
      -- side hypotheses
      let mut ok := true
      for a in args do
        if a.isMVar then
         if !(← a.mvarId!.isAssigned) then
          if (← isProp (← inferType a)) then
            unless (← dischargeHyp 4 a.mvarId!) do
              if verbose then
                logInfo m!"app_walk?: {law.name} rejected — side \
                  hypothesis not mechanical: \
                  {← instantiateMVars (← a.mvarId!.getType)}"
              ok := false
              break
      unless ok do return none
      let proof ← instantiateMVars (mkAppN lemExpr args)
      if proof.hasExprMVar then return none
      let lemRhs ← instantiateMVars lemRhs
      -- terminal: the law's RHS meets the goal's RHS directly
      if (← withReducible <| isDefEq lemRhs rhs) then
        goal.assign (← mkEqTrans proof (← mkEqRefl rhs))
        return some (law.name, none)
      -- chain: Eq.trans into a continuation goal
      let restTy ← mkEq lemRhs rhs
      let rest ← mkFreshExprMVar restTy (userName := `walk)
      goal.assign (← mkEqTrans proof rest)
      return some (law.name, some rest.mvarId!))
    match res with
    | some (some r) => return some r
    | _ => restoreState st
  -- no law fired: leave the goal untouched
  let _ := α
  return none

/-- The walk loop: up to `budget` rounds, then (if the goal survives)
    try `rfl`. Reports the trace when `verbose`. -/
partial def walkLoop (goal : MVarId) (budget : Nat) (verbose : Bool) :
    TacticM (Option MVarId) := do
  let mut g := goal
  for _ in [0:budget] do
    -- Each ROUND runs in a fresh heartbeat window (capped at the
    -- ambient per-declaration budget, never larger): the walker
    -- replaces one declaration PER ROUND (the arc-7 per-round lemma
    -- files), so per-round accounting is parity, not a budget bump;
    -- the total is bounded by the explicit round budget.
    match ← Core.withCurrHeartbeats (walkOnce g verbose) with
    | some (n, some g') =>
      if verbose then logInfo m!"app_walk: {n}"
      g := g'
    | some (n, none) =>
      if verbose then logInfo m!"app_walk: {n} (closed)"
      return none
    | none =>
      -- stuck: try rfl, else stop with the goal as-is
      if (← attempt candidateBudget (do
          let some (_, l, r) := (← instantiateMVars (← g.getType)).eq?
            | failure
          unless (← isDefEq l r) do failure
          g.assign (← mkEqRefl l))).isSome then
        if verbose then logInfo m!"app_walk: closed by rfl"
        return none
      return some g
  return some g

/-- `app_walk` / `app_walk n` — see the header contract. -/
syntax (name := appWalk) "app_walk" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    match ← walkLoop goal budget false with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk?` — one reported step (debug only; banned in committed
    proofs). -/
syntax (name := appWalkDebug) "app_walk?" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk? $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 1
    let goal ← getMainGoal
    match ← walkLoop goal budget true with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk_step e` — the manual-step primitive: close the goal with
    the explicit block equation `e`, or chain it by `Eq.trans`. Runs
    in its own heartbeat window (budget parity with the per-round
    lemma DECLARATIONS this style replaces — each proof step is
    bounded by the standard per-declaration budget; nothing is
    raised). -/
elab "app_walk_step" e:term : tactic => do
  Core.withCurrHeartbeats do
    -- CHAIN-first: `exact`-first would unify the step's RHS against
    -- the goal's terminal RHS — a whole-remaining-run reduction grind
    -- (measured: it alone trips the budget on the T1 chain).
    evalTactic (← `(tactic| first
      | refine Eq.trans $e ?_
      | exact $e))

/-- `app_walk_finish e` — walk, then the goal must close with `e`
    (the honest segment end). Own heartbeat window, as
    `app_walk_step`. -/
elab "app_walk_finish" e:term : tactic => do
  evalTactic (← `(tactic| app_walk))
  Core.withCurrHeartbeats do
    evalTactic (← `(tactic| first
      | exact $e
      | (refine Eq.trans $e ?_; rfl)))

end RelSem.Tactics
