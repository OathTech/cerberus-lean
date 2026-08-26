/-
  RelSem.RoundEval.Classify — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: THE CLASSIFIER — candidate collection for the minter
  (collectMintCands: post-order, share-deduped, head-filtered) and
  the `.all` DIG (digStuck: one memoized smart-unfolding override
  exposing towers hidden inside folded definitions). The head lists
  (registryBoolHead/registryDecHead/recLikeHead) are CLASSIFIER
  HEURISTICS — which heads are worth testing — not law selection;
  law selection is the registry's (LawRegistry) and the lanes'.

  Split from RoundEval.lean; code carried VERBATIM apart from
  `private` removed where the lane module consumes a definition.

  House rules: no sorry, no axioms; meta code only.
-/
import RelSem.RoundEval.Core
import RelSem.RoundEval.Hyp
import RelSem.Kit.Map

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

/-- Bool-lane registry (v1; grown empirically, fail-closed). -/
def registryBoolHead (c : Name) : Bool :=
  c == ``Nat.ble || c == ``Nat.blt || c == ``Nat.beq ||
  c == ``natLtb || c == ``natLteb || c == ``natGteb ||
  c == ``intLtb || c == ``intLteb || c == ``intGtb || c == ``intGteb

/-- Decidable-instance heads worth testing BEFORE whnf explodes them
    (post-explosion towers are caught by the matcher filter). -/
def registryDecHead (c : Name) : Bool :=
  c == ``Nat.decLt || c == ``Nat.decLe || c == ``Nat.decEq ||
  c == ``Int.decLt || c == ``Int.decLe || c == ``Int.decEq ||
  c == ``Int.decNonneg ||
  c == ``instDecidableEqNat || c == ``Int.instDecidableEq ||
  c == ``instDecidableEqBool

/-- Recursor-like heads: whnf's smart unfolding leaves stuck towers
    as raw `rec`/`casesOn` applications (the S2b "raw Acc.rec towers"
    observation), not just matcher auxiliaries. -/
def recLikeHead (env : Environment) (c : Name) : Bool :=
  match env.find? c with
  | some (.recInfo _) => true
  | _ => c.isStr &&
      (c.getString! == "casesOn" || c.getString! == "recOn")

/-- Candidate collection: post-order (children before parents, so the
    INNERMOST stuck tower is minted first and patterns stay small),
    share-deduped; `inferType` is gated behind the syntactic filter
    (matcher/recursor apps + registry heads). -/
partial def collectMintCands (root : Expr) :
    MetaM (Array Expr) := do
  let env ← getEnv
  let seen ← IO.mkRef ({} : Std.HashSet Expr)
  let out ← IO.mkRef (#[] : Array Expr)
  let rec go (e : Expr) : MetaM Unit := do
    if (← seen.get).contains e then return
    seen.modify (·.insert e)
    match e with
    | .app .. =>
      for a in e.getAppArgs do go a
      go e.getAppFn
      unless e.hasLooseBVars do
        if let .const c _ := e.getAppFn then
          if registryBoolHead c || registryDecHead c
              || c == ``fmapLookupBy || c == ``BEq.beq
              -- the evalArith + evalPull lanes' heads (arc-18 C3)
              || c == ``mk_conv_int
              || c == ``mk_call_catch_exceptional_condition
              || c == ``pull_constrained
              || c == ``pull_constrained_lemFuel
              || c == ``CerbMem.readBytesFrom
              || c == ``CerbMem.MemState.allocations
              || c == ``CerbMem.MemState.deadAllocations
              || c == ``CerbMem.MemState.funptrmap
              || c == ``CerbMem.MemState.lastUsedUnionMembers
              || c == ``CerbMem.MemState.bytemap
              || isMatcherAppCore env e || recLikeHead env c then
            out.modify (·.push e)
    | .lam _ t b _ => go t; go b
    | .forallE _ t b _ => go t; go b
    | .letE _ t v b _ => go t; go v; go b
    | .mdata _ b => go b
    | .proj sN _ b =>
      go b
      -- MemState projections over a fenced byte-write (the mem
      -- read-over-write lane's projection candidates)
      if sN == ``CerbMem.MemState
          && b.isAppOfArity ``CerbMem.writeBytesTo 3
          && !e.hasLooseBVars then
        out.modify (·.push e)
    | _ => pure ()
  go root
  out.get

/-- THE `.all` DIG (arc-17 S3 — the anon-env unlock): smart
    unfolding refuses to unfold a definition whose internal match is
    stuck, so a tree operation over a seed-symbolic key keeps its
    comparison towers INSIDE the folded definition — invisible to
    both the minter and any rewrite (measured: the round-23
    `Impl.Const.get?`-over-`Impl.insert` wall). For a stuck
    hyp-mode application that is NOT a minter candidate and does NOT
    contain any registered pattern head (the substitute-first
    tidiness guard), one `.all` whnf EXPOSES the internals; the
    towers then surface as ordinary candidates and the verdict
    substitutions let the structure compute. Memoized (the same
    lookup spelling recurs across rounds); a dig that exposes
    nothing (or times out on its own scoped budget) is cached as
    permanently stuck. -/
def digStuck (e : Expr) : MetaM (Option Expr) := do
  let some hp ← (activeHypPack.get : BaseIO _) | return none
  if hp.isEmpty then return none
  let env ← getEnv
  let cName? ← (do
    match e.getAppFn with
    | .const c _ =>
      -- minter-handled candidates are minted, not dug
      if registryBoolHead c || registryDecHead c || c == ``fmapLookupBy
          || isMatcherAppCore env e || recLikeHead env c then
        return none
      -- fenced heads are NEVER dug: the fence exists to preserve the
      -- spelling and the dig's `.all` is attribute-blind
      if (← (baseFenceHeads.get : BaseIO _)).contains c then
        return none
      if let some (.ctorInfo _) := env.find? c then return none
      unless e.isApp do return none
      return some c
    | .proj .. =>
      -- projection-headed redexes (WF-aux `._f` partial-application
      -- projections — measured at the round-23 wall) dig too
      return some `_proj
    | _ => return none)
  let some c := cName? | return none
  unless e.hasFVar do return none
  -- tidiness guard: never expose a spelling carrying a CURATED
  -- pattern head (minted verdict patterns don't count — their
  -- substitution sites are exactly what digging exposes)
  for r in hp.baseRw do
    if let .const pc _ := r.lhs.getAppFn then
      if (e.find? (·.isConstOf pc)).isSome then
        trace[RelSem.roundEval] "dig: refused {c} (contains pattern head {pc})"
        return none
  if let some r := (← digCache.get).get? e then
    return if r == e then none else some r
  let r ← (try
      -- smart unfolding is what HIDES the towers (it refuses to
      -- unfold a def whose match is stuck, at EVERY transparency);
      -- the dig exists to override exactly that, once, memoized
      withCurrHeartbeats <|
        withOptions (fun o => o.set `smartUnfolding false) <|
          withTransparency .all (whnf e)
    catch _ => (do
      trace[RelSem.roundEval] "dig: {c} timed out"
      pure e))
  digCache.modify (·.insert e r)
  if r == e then
    trace[RelSem.roundEval] "dig: {c} exposed nothing"
    return none
  trace[RelSem.roundEval] "dig: exposed {c}"
  return some r

initialize digHook.set digStuck

end RoundEval
end RelSem
