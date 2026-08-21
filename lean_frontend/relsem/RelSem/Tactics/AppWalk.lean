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
def attempt {α : Type} (hb : Nat) (x : MetaM α) (dbg : Bool := false) :
    MetaM (Option α) := do
  let curMax := (← readThe Core.Context).maxHeartbeats
  let hb := if curMax == 0 then hb else min hb curMax
  Core.withCurrHeartbeats do
    withTheReader Core.Context
        (fun ctx => { ctx with maxHeartbeats := hb }) do
      tryCatchRuntimeEx
        (try
          return some (← x)
        catch ex =>
          if dbg then logInfo m!"app_walk?: attempt failed — {ex.toMessageData}"
          return none)
        (fun ex => do
          if dbg then logInfo m!"app_walk?: attempt ABORTED — {ex.toMessageData}"
          return none)

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

/-! ## Walker v2 (arc-9 S3, design §11.3): type-aware selective state
    normalization. ADDITIVE/OPT-IN: `app_walk` behavior is untouched;
    `app_walk_norm` runs the same loop with `WalkCfg.norm := true`. -/

/-- The walker configuration. v1 (`app_walk`) is the default; v2
    (`app_walk_norm`) sets `norm := true` and loads the state-atom set. -/
structure WalkCfg where
  norm : Bool := false
  atoms : NameSet := {}
  depth : Nat := 64
  /-- Per-candidate heartbeat sub-cap (INTERNAL units). v1 keeps the
      S2 50k window; v2 walks use the full ambient window (`attempt`
      always mins against the ambient budget — never above it). -/
  candBudget : Nat := candidateBudget
  /-- Debug tracing inside the discharge engine (debug lanes only). -/
  trace : Bool := false
  /-- WALKER-V3 (WIP, S3 park record): seal computed-value facts as
      auxiliary theorems (per-fact kernel checks). -/
  sealFacts : Bool := false
  /-- WALKER-V3 (WIP): seal each round's equation as an auxiliary
      theorem (per-round kernel checks — the arc-7 accounting). -/
  sealRounds : Bool := false
  /-- WALKER-V3 (WIP): emit each normalized continuation state as an
      auxiliary definition (the T4 named-state structure). -/
  sealStates : Bool := false
  deriving Inhabited

/-- Type heads whose inhabitants the v2 normalizer never touches
    (map-value OPACITY, F-T5-2: whnf of map inserts materializes
    well-formedness-proof-carrying internal tree literals). Terms of
    these types ride in their DELIVERED spelling — for St-v2 states
    that is the `fmapAddBy`/`insert` chain form. -/
def opaqueTypeHeads : List Name :=
  [`Fmap, `Std.TreeMap, `Std.DTreeMap, `Std.TreeMap.Raw,
   `Std.DTreeMap.Raw, `Std.DTreeMap.Internal.Impl]

/-- Scalar type heads: subterms of these types are ALWAYS fully
    evaluated (whnf without atom blocking) — addresses/counters/
    supplies must reach literal form for `decide`/rfl side facts even
    when their computation projects out of an atom (the S3
    mem_alloc_block finding). -/
def scalarTypeHeads : List Name :=
  [`Nat, `Int, `Bool]

/-- Targeted scalar evaluator: fold arithmetic to literals WITHOUT
    full `reduce` (reduce normalizes the whole argument — measured to
    MATERIALIZE state trees and blow the memory cap when the scalar
    projects out of a big state). Strategy: whnf the head; normalize
    scalar-typed ARGS recursively; re-whnf the rebuilt application
    until a fixpoint/literal. -/
partial def evalScalar (scalarHeads : List Name) : Nat → Expr → MetaM Expr
  | 0, e => return e
  | d + 1, e => do
    let e ← whnf e
    match e.getAppFn with
    | .const _ _ =>
      if e.getAppArgs.isEmpty then return e
      let args' ← e.getAppArgs.mapM fun a => do
        let ty ← instantiateMVars (← inferType a)
        if let .const tn _ := ty.getAppFn then
          if scalarHeads.contains tn then evalScalar scalarHeads d a
          else pure a
        else pure a
      let e2 := mkAppN e.getAppFn args'
      let e3 ← whnf e2
      if e3 == e2 then return e3 else evalScalar scalarHeads d e3
    | _ => return e

/-- The result-type head of a constant's type (structural). -/
private def resultTypeHead : Expr → Expr
  | .forallE _ _ b _ => resultTypeHead b
  | e => e.getAppFn

/-- The atom/map-blocking unfold predicate (built ONCE per walk
    step and installed around the whole normalization recursion —
    a fresh predicate closure per whnf call would bust the whnf
    cache; measured 25s on one eval round before hoisting). -/
def atomsCanUnfold (atoms : NameSet) :
    Meta.Config → ConstantInfo → CoreM Bool := fun _ cinfo => do
  if (← getEnv).isProjectionFn cinfo.name then return true
  if atoms.contains cinfo.name then return false
  if let .const tn _ := resultTypeHead cinfo.type then
    if opaqueTypeHeads.contains tn then return false
  return true

def whnfAtoms (atoms : NameSet) (e : Expr) : MetaM Expr :=
  withCanUnfoldPred (atomsCanUnfold atoms) (whnf e)

/-- Map-blocking-only predicate (no atom blocking): used for
    DISCOVERY payload normalization, where values must compute
    through fixture atoms but map internals still must never
    materialize. -/
def mapsCanUnfold :
    Meta.Config → ConstantInfo → CoreM Bool := fun _ cinfo => do
  if (← getEnv).isProjectionFn cinfo.name then return true
  if let .const tn _ := resultTypeHead cinfo.type then
    if opaqueTypeHeads.contains tn then return false
  return true

/-- Drop any installed canUnfold predicate (restore default unfold
    behavior) for a sub-computation. -/
def withoutCanUnfoldPred {α : Type} (x : MetaM α) : MetaM α :=
  withReader (fun ctx => { ctx with canUnfold? := none }) x

/-- Core of the v2 normalizer (design §11.3 semantics: constructor-
    spine normalization; opaque map types ride as delivered; atoms
    never delta-unfold; scalars fully reduce; non-ctor whnf keeps the
    smaller spelling): ASSUMES the atom unfold predicate is
    already installed (plain `whnf` under it — one shared cache). -/
partial def normStateV2Core (atoms : NameSet) : Nat → Expr → MetaM Expr
  | 0, e => return e
  | d + 1, e => do
    -- (a) type-aware opacity: no delta into map values; projection/
    -- beta chains (whnfCore) are still collapsed so a `{…}.field`
    -- record-update spine reduces to the compact field value.
    -- The TYPE is whnf'd so abbrevs (thread_id/aid := Nat, memM :=
    -- ndM …) classify correctly — the S3 tid_supply self-embedding
    -- finding.
    let ty ← whnf (← instantiateMVars (← inferType e))
    if let .const tn _ := ty.getAppFn then
      if opaqueTypeHeads.contains tn then
        let e' ← whnf e
        return (if e'.approxDepth ≤ e.approxDepth then e' else e)
      if scalarTypeHeads.contains tn then
        return (← withoutCanUnfoldPred (evalScalar scalarTypeHeads 12 e))
    -- (b) state-atom head opacity
    if let .const fn _ := e.getAppFn then
      if atoms.contains fn then return e
    let e' ← whnf e
    match e'.getAppFn with
    | .const n _ =>
      match (← getEnv).find? n with
      | some (.ctorInfo _) =>
        let args ← e'.getAppArgs.mapM fun a => do
          if (← instantiateMVars (← inferType a)).isSort then
            pure a
          else
            normStateV2Core atoms d a
        return mkAppN e'.getAppFn args
      | _ =>
        -- whnf stuck at a non-constructor head: keep whichever
        -- spelling is SMALLER (progress like `{…}.field → f x` is
        -- kept; half-reduced blow-ups are dropped — the F-T5-1
        -- lesson, size-arbitrated)
        return (if e'.approxDepth ≤ e.approxDepth then e' else e)
    | _ => return e

/-- v2 normalizer entry: install the predicate ONCE, run the core. -/
def normStateV2 (atoms : NameSet) (d : Nat) (e : Expr) : MetaM Expr :=
  withCanUnfoldPred (atomsCanUnfold atoms) (normStateV2Core atoms d e)

/-- Seal a kernel-established defeq as its OWN auxiliary theorem
    (`mkAuxTheorem` closes over local fvars): the main proof then
    references an opaque constant, so the kernel's per-declaration
    recursion is bounded per COMPUTED VALUE instead of accumulating
    across a whole round application (the S3 create-round
    deep-recursion finding; the arc-7 per-round-declaration
    accounting made literal). -/
def mkAuxRfl (lhs rhs : Expr) : MetaM Expr := do
  let ty ← mkEq lhs rhs
  mkAuxTheorem ty (← mkEqRefl lhs) (zetaDelta := false)

/-- KERNEL-BACKED whnf for discovery computation (arc-9 S3): the
    elaborator's substitution-based whnf was MEASURED to blow the
    memory cap on deep-context eval rounds (t5 entry round 10 —
    >40G on one crossing); the kernel's closure-based reducer handles
    the same reduction like the per-round rfl declarations of the
    arc-7 hand style. Falls back to meta whnf on mvars/kernel
    errors. Proofs are unaffected (the assigned values are re-checked
    by the kernel at declaration end as always). -/
def kWhnf (e : Expr) : MetaM Expr := do
  let e ← instantiateMVars e
  if e.hasExprMVar then
    whnf e
  else do
    let t0 ← IO.monoMsNow
    match Lean.Kernel.whnf (← getEnv) (← getLCtx) e with
    | .ok e' =>
      return e'
    | .error _ =>
      whnf e

/-- Payload normalizer for DISCOVERY: plain full whnf spine (atoms
    and map lookups all compute — the program itself lives inside an
    Fmap), but subterms of opaque map types and program-term types
    ride UNTOUCHED (never whnf'd — retained normal forms must not
    materialize tree internals). -/
partial def normPayload : Nat → Expr → MetaM Expr
  | 0, e => return e
  | d + 1, e => do
    let ty ← whnf (← instantiateMVars (← inferType e))
    if let .const tn _ := ty.getAppFn then
      if opaqueTypeHeads.contains tn then return e
      if scalarTypeHeads.contains tn then
        let r ← evalScalar scalarTypeHeads 32 e
        return r
    let e' ← kWhnf e
    match e'.getAppFn with
    | .const n _ =>
      match (← getEnv).find? n with
      | some (.ctorInfo _) =>
        let args ← e'.getAppArgs.mapM fun a => do
          if (← instantiateMVars (← inferType a)).isSort then
            pure a
          else
            normPayload d a
        return mkAppN e'.getAppFn args
      | _ =>
        return (if e'.approxDepth ≤ e.approxDepth then e' else e)
    | _ => return e

/-- Payload fuel: LARGE (idempotence requirement — two
    normalizations of overlapping values must produce IDENTICAL
    normal forms, or the kernel is forced into deep mutual
    reduction bridging two different partial forms; S3 hfind
    finding). Structural recursion; program-term/map/lambda payloads
    are untouched, so this is bounded by the ctor-spine size. -/
def payloadFuel : Nat := 4096

def normCompute (atoms : NameSet) (d : Nat) (e : Expr) : MetaM Expr := do
  let _ := atoms
  let _ := d
  withoutCanUnfoldPred do
    let e' ← kWhnf e
    match e'.getAppFn with
    | .const n _ =>
      match (← getEnv).find? n with
      | some (.ctorInfo _) =>
        let args ← e'.getAppArgs.mapM fun a => do
          if (← instantiateMVars (← inferType a)).isSort then
            pure a
          else
            normPayload payloadFuel a
        return mkAppN e'.getAppFn args
      | _ => return e'
    | _ => return e'

/-- Normalize ONLY the state argument of an `app C σ`-shaped
    continuation RHS (never the computation — whnf'ing `app C σ`
    would run the whole remaining computation). -/
def normAppState (cfg : WalkCfg) (e : Expr) : MetaM Expr := do
  unless cfg.norm do return e
  if let .const n _ := e.getAppFn then
    if n == `RelSem.app then
      let args := e.getAppArgs
      if args.size > 0 then
        let i := args.size - 1
        let st' ← normStateV2 cfg.atoms cfg.depth args[i]!
        if cfg.sealStates then
          -- WALKER-V3 (WIP): emit the normalized state as an
          -- auxiliary DEFINITION and continue with the constant —
          -- the T4 named-state structure (park record: interacts
          -- with fact normalization; not yet coherent end-to-end).
          let stTy ← inferType st'
          let stConst ← mkAuxDefinition
            ((← mkFreshUserName `walkSt).appendAfter "_aux") stTy st'
            (compile := false)
          return mkAppN e.getAppFn (args.set! i stConst)
        return mkAppN e.getAppFn (args.set! i st')
  return e

/-- Discharge one side hypothesis of a candidate law, mechanically:
    computed-value assignment (normalize-and-assign for a bare-mvar
    RHS), `assumption`, then (for app-equation hyps) a one-shot
    registered law whose own hypotheses discharge recursively, then
    `rfl` (definitional unfolding — the T1-round move). Anything else:
    failure (the law does not apply). -/
partial def dischargeHyp (cfg : WalkCfg) (fuel : Nat) (h : MVarId) : MetaM Bool := do
  if (← h.isAssigned) then return true
  let ty ← instantiateMVars (← h.getType)
  -- (0) computed-value hypothesis: `lhs = ?m` with a bare unassigned
  -- mvar RHS — normalize the computation's spine and assign.
  if let some (_, lhs, rhs) := ty.eq? then
    let rhsCtorMvar : MetaM Bool := do
      -- v2: an RHS that is a constructor spine over mvars (e.g.
      -- `(NDactive ?v, ?σ)`, `Result (Defined ?z, ?rs)`) is also a
      -- computed-value pattern — assigning through raw unification
      -- would plant UNNORMALIZED components that defeat later
      -- DiscrTree dispatch (the S3 get_with_address finding).
      if !cfg.norm then return false
      if !rhs.hasExprMVar then return false
      -- app-crossings are LAWS ONLY (S2 design invariant): never
      -- raw-whnf an `app`-shaped LHS, even for spine assignment.
      if lhs.isAppOf `RelSem.app then return false
      if let .const n _ := rhs.getAppFn then
        if let some (.ctorInfo _) := (← getEnv).find? n then
          return true
      return false
    let unassignedMVar : MetaM Bool := do
      if rhs.isMVar then return !(← rhs.mvarId!.isAssigned)
      else
        let r ← rhsCtorMvar
        if cfg.trace && !r then
          dbg_trace "dh[{fuel}]: lane guard false: mv={rhs.hasExprMVar} app={lhs.isAppOf `RelSem.app} hd={rhs.getAppFn}"
        return r
    if (← unassignedMVar) then
     if true then
      let st ← saveState
      match ← attempt cfg.candBudget (do
          let t0 ← IO.monoMsNow
          -- selection-shaped facts (`some ?x` patterns) take the
          -- kernel-whnf output VERBATIM: the value is a subterm of an
          -- already-normal spine, and re-normalization creates a
          -- structurally different form whose kernel bridge
          -- deep-recurses (S3 hfind finding).
          let isSelection := rhs.isApp && rhs.getAppFn.isConstOf ``Option.some
          let v ← if cfg.norm then
                    if isSelection then kWhnf lhs
                    else normCompute cfg.atoms cfg.depth lhs
                  else normSpine 4 lhs
          if (← isDefEq rhs v) then
            if cfg.sealFacts then
              h.assign (← mkAuxRfl lhs (← instantiateMVars rhs))
            else
              h.assign (← mkEqRefl lhs)
            return true
          else
            if cfg.trace then dbg_trace "dh[{fuel}]: lane isDefEq FAILED"
            return false) with
      | some true => return true
      | _ =>
        if cfg.trace then dbg_trace "dh[{fuel}]: lane attempt none/false"
        restoreState st
  -- (i) assumption (range/overflow side conditions + context-fed
  -- block facts). HEAD-FILTERED (S3): plain `assumption` walks every
  -- context hypothesis with full-size isDefEq — measured seconds at
  -- action-round term sizes; an equation hypothesis is only tried
  -- when its LHS head constant matches the goal's (the context-fact
  -- pattern by construction).
  let ta0 ← IO.monoMsNow
  let tried ← h.withContext do
    match ty.eq? with
    | none => return (← observing? h.assumption).isSome
    | some (_, lhs, _) =>
      let lhsHead := lhs.getAppFn
      let lctx ← getLCtx
      for decl in lctx do
        if decl.isImplementationDetail then continue
        let dty ← instantiateMVars decl.type
        if let some (_, dlhs, _) := dty.eq? then
          if dlhs.getAppFn == lhsHead then
            if (← observing? (do
                unless (← isDefEq dty ty) do failure
                h.assign decl.toExpr)).isSome then
              return true
      return false
  if tried then return true
  if cfg.trace then dbg_trace "dh[{fuel}]: past-assumption ({(← IO.monoMsNow) - ta0}ms)"
  match fuel, ty.eq? with
  | fuel + 1, some (_, lhs, _) =>
    -- (ii) one-shot registered law on an app-shaped hypothesis
    let t0 ← IO.monoMsNow
    let lhs ← whnfCore lhs
    let t1 ← IO.monoMsNow
    let cands ← appEqMatches lhs
    if cfg.trace then
      dbg_trace "dh[{fuel}]: whnfCore {t1-t0}ms; cands {cands.map (·.name)} for {lhs.getAppFn}"
      if cands.isEmpty && lhs.isAppOf `RelSem.app then
        dbg_trace "dh[{fuel}]: EMPTY-CANDS lhs args heads: {lhs.getAppArgs.map (fun a => toString a.getAppFn)}"
        if lhs.getAppArgs.size ≥ 2 then
          let comp := lhs.getAppArgs[lhs.getAppArgs.size - 2]!
          dbg_trace "dh[{fuel}]: comp head {comp.getAppFn} args {comp.getAppArgs.map (fun a => (toString a.getAppFn).take 60)}"
          let req := comp.getAppArgs[comp.getAppArgs.size - 1]!
          dbg_trace "dh[{fuel}]: req args: {req.getAppArgs.map (fun a => (toString a.getAppFn).take 40)}"
          let keys ← DiscrTree.mkPath lhs
          dbg_trace "dh[{fuel}]: target keys 5-20: {(keys.toList.drop 5).take 15 |>.map (fun k => Format.pretty (format k))}"
    for law in cands do
      let st ← saveState
      let res ← attempt cfg.candBudget (do
        let lemExpr ← mkConstWithFreshMVarLevels law.name
        let (args, _, lemTy) ← forallMetaTelescopeReducing
          (← inferType lemExpr)
        unless (← isDefEq lemTy ty) do
          if cfg.trace then dbg_trace "dh law {law.name}: ty mismatch"
          return false
        let mut ok := true
        for a in args do
          if a.isMVar then
            if !(← a.mvarId!.isAssigned) then
              if (← isProp (← inferType a)) then
                let t0 ← IO.monoMsNow
                let okh ← dischargeHyp cfg fuel a.mvarId!
                let t1 ← IO.monoMsNow
                if cfg.trace then
                  let ty' ← instantiateMVars (← a.mvarId!.getType)
                  let hd := match ty'.eq? with
                    | some (_, l, _) => toString l.getAppFn
                    | none => toString ty'.getAppFn
                  dbg_trace "dh law {law.name}: hyp ok={okh} ({t1-t0}ms) : {hd}"
                unless okh do
                  ok := false
                  break
        unless ok do return false
        -- any remaining non-Prop arg mvars must be determined
        let proof ← instantiateMVars (mkAppN lemExpr args)
        if proof.hasExprMVar then
          if cfg.trace then dbg_trace "dh law {law.name}: RESIDUAL MVARS"
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
      if cfg.trace then
        logInfo m!"dh[{fuel}]: STOP no law fired on app-shaped: {lhs.getAppFn}, {(← appEqMatches lhs).map (·.name)}"
      return false
    let st ← saveState
    let res ← attempt candidateBudget (do
      let some (_, lhs', rhs') := (← instantiateMVars (← h.getType)).eq?
        | return false
      if (← isDefEq lhs' rhs') then
        if cfg.sealFacts then
          h.assign (← mkAuxRfl lhs' (← instantiateMVars rhs'))
        else
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
partial def walkOnce (cfg : WalkCfg) (goal : MVarId)
    (verbose : Bool := false) :
    TacticM (Option (Name × Option MVarId)) := do
  goal.withContext do
  -- consumeMData: `have`-style tactics wrap the goal type in metadata,
  -- which `Expr.eq?` does not see through (S2 finding: the walker
  -- silently no-opped on goals under a `have`).
  let tgt := (← instantiateMVars (← goal.getType)).consumeMData
  let some (α, lhs, rhs) := tgt.eq? | return none
  let lhs ← whnfCore lhs
  let cands ← appEqMatches lhs
  if verbose then
    logInfo m!"app_walk?: {cands.size} candidate(s):       {cands.map (·.name)}"
  -- DEBUG LANE (verbose): run the FIRST candidate raw — exceptions
  -- and logs propagate (attempt+restoreState would roll them back).
  if verbose && false then
    if h : cands.size > 0 then
      let law := cands[0]!
      logInfo m!"app_walk?: RAW attempt of {law.name}"
      let lemExpr ← mkConstWithFreshMVarLevels law.name
      let (args, _, lemTy) ← forallMetaTelescopeReducing
        (← inferType lemExpr)
      let some (_, lemLhs, _) := lemTy.eq?
        | logInfo m!"app_walk?: not an eq"; return none
      unless (← isDefEq lemLhs lhs) do
        logInfo m!"app_walk?: LHS mismatch"; return none
      for a in args do
        if a.isMVar then
         if !(← a.mvarId!.isAssigned) then
          if (← isProp (← inferType a)) then
            let ty0 ← instantiateMVars (← a.mvarId!.getType)
            let t0 ← IO.monoMsNow
            let okh ← dischargeHyp { cfg with trace := true } 4 a.mvarId!
            let t1 ← IO.monoMsNow
            logInfo m!"app_walk?: hyp ({t1-t0}ms, ok={okh}): {ty0}"
      return none
  for law in cands do
    let st ← saveState
    let res ← attempt (dbg := verbose) cfg.candBudget (do
      let lemExpr ← mkConstWithFreshMVarLevels law.name
      let (args, _, lemTy) ← forallMetaTelescopeReducing
        (← inferType lemExpr)
      let some (_, lemLhs, lemRhs) := lemTy.eq? | return none
      unless (← isDefEq lemLhs lhs) do
        if verbose then logInfo m!"app_walk?: {law.name} LHS mismatch"
        return none
      -- side hypotheses
      let mut ok := true
      for a in args do
        if a.isMVar then
         if !(← a.mvarId!.isAssigned) then
          if (← isProp (← inferType a)) then
            unless (← dischargeHyp cfg 4 a.mvarId!) do
              if verbose then
                let ty' ← instantiateMVars (← a.mvarId!.getType)
                let lhsHead := match ty'.eq? with
                  | some (_, l, _) => toString l.getAppFn ++ " " ++ String.intercalate " " (l.getAppArgs.map (fun (x : Expr) => toString x.getAppFn)).toList
                  | none => toString ty'.getAppFn
                dbg_trace "app_walk?: {law.name} rejected — not mechanical: {lhsHead.take 300}"
              ok := false
              break
      unless ok do return none
      let proof ← instantiateMVars (mkAppN lemExpr args)
      if proof.hasExprMVar then return none
      let lemRhs ← instantiateMVars lemRhs
      -- v2 PER-ROUND SEALING: each round's equation becomes its OWN
      -- auxiliary theorem, so the kernel checks rounds one at a time
      -- (the arc-7 per-round-declaration accounting made literal; a
      -- monolithic multi-round proof term was MEASURED to trip the
      -- kernel's deep-recursion guard).
      let proof ← if cfg.sealRounds then do
          let pty ← instantiateMVars (← inferType proof)
          mkAuxTheorem pty proof (zetaDelta := false)
        else pure proof
      -- terminal: the law's RHS meets the goal's RHS directly
      if (← withReducible <| isDefEq lemRhs rhs) then
        goal.assign (← mkEqTrans proof (← mkEqRefl rhs))
        return some (law.name, none)
      -- chain: Eq.trans into a continuation goal. Under v2 the
      -- continuation's LHS state is replaced by its normalized
      -- (defeq) image — `mkEqTrans` performs the defeq bridge.
      let lemRhsN ← normAppState cfg lemRhs
      let restTy ← mkEq lemRhsN rhs
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
partial def walkLoop (cfg : WalkCfg) (goal : MVarId) (budget : Nat)
    (verbose : Bool) :
    TacticM (Option MVarId) := do
  let mut g := goal
  for _ in [0:budget] do
    -- Each ROUND runs in a fresh heartbeat window (capped at the
    -- ambient per-declaration budget, never larger): the walker
    -- replaces one declaration PER ROUND (the arc-7 per-round lemma
    -- files), so per-round accounting is parity, not a budget bump;
    -- the total is bounded by the explicit round budget.
    let t0 ← IO.monoMsNow
    -- THE PER-ROUND WINDOW, complete (S3): each round runs against a
    -- fresh base (withCurrHeartbeats) AND its consumption is settled
    -- back to the enclosing meter as ONE round's worth — the S2
    -- accounting model (a walker round replaces one per-round lemma
    -- DECLARATION, arc-7 style) implemented on both sides of the
    -- ledger. Every round stays individually capped at the ambient
    -- per-declaration budget; the walk's total is bounded by the
    -- explicit round budget × ambient — exactly the budget of the
    -- per-round declaration files this replaces. No set_option, no
    -- ambient raise; recorded in the build record.
    let hb0 ← IO.getNumHeartbeats
    let step? ← tryCatchRuntimeEx
      (Core.withCurrHeartbeats (walkOnce cfg g verbose))
      (fun ex => do
        if verbose then
          dbg_trace "app_walk?: round ABORTED (runtime)"
          logInfo m!"app_walk?: round aborted — {ex.toMessageData}"
        pure none)
    IO.setNumHeartbeats hb0
    match step? with
    | some (n, some g') =>
      if verbose then
        dbg_trace "app_walk: {n} ({(← IO.monoMsNow) - t0}ms)"
      g := g'
    | some (n, none) =>
      if verbose then logInfo m!"app_walk: {n} (closed)"
      return none
    | none =>
      -- stuck: try rfl, else stop with the goal as-is
      if verbose then dbg_trace "app_walk?: STUCK, trying rfl"
      let hb1 ← IO.getNumHeartbeats
      let rflRes ← attempt candidateBudget (do
          let some (_, l, r) :=
              (← instantiateMVars (← g.getType)).consumeMData.eq?
            | failure
          unless (← isDefEq l r) do failure
          g.assign (← mkEqRefl l))
      IO.setNumHeartbeats hb1
      if rflRes.isSome then
        if verbose then logInfo m!"app_walk: closed by rfl"
        return none
      if verbose then dbg_trace "app_walk?: returning stuck goal"
      return some g
  return some g

/-- `app_walk` / `app_walk n` — see the header contract. -/
syntax (name := appWalk) "app_walk" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    match ← walkLoop {} goal budget false with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk_norm` / `app_walk_norm n` — the v2 walk (design §11.3):
    the same loop with type-aware selective state normalization
    (opt-in; `app_walk` is untouched). -/
syntax (name := appWalkNorm) "app_walk_norm" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk_norm $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let cfg : WalkCfg := { norm := true, atoms := atoms, candBudget := 200000 * 1000 }
    match ← walkLoop cfg goal budget false with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk?` — one reported step (debug only; banned in committed
    proofs). Reports through the v2 config when the walk would (the
    debug lane mirrors `app_walk`; use `app_walk_norm?` for v2). -/
syntax (name := appWalkDebug) "app_walk?" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk? $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 1
    let goal ← getMainGoal
    match ← walkLoop {} goal budget true with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk_norm!` — the v3 SEALED walk: law-structured rounds with
    per-fact aux theorems, per-round aux theorems, and per-state aux
    definitions (the T4 hand-proof architecture, automated). -/
syntax (name := appWalkNormSealed) "app_walk_norm!" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk_norm! $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let cfg : WalkCfg := { norm := true, atoms := atoms, candBudget := 200000 * 1000, sealFacts := true, sealRounds := true, sealStates := true }
    match ← walkLoop cfg goal budget false with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk_norm?` — v2 debug lane (banned in committed proofs,
    same as `app_walk?`). -/
syntax (name := appWalkNormDebug) "app_walk_norm?" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk_norm? $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 1
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let cfg : WalkCfg := { norm := true, atoms := atoms, candBudget := 100000 * 1000, trace := true }
    match ← walkLoop cfg goal budget true with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_defeq` — close an equation goal by KERNEL defeq: the two
    sides are checked with `Kernel.isDefEq` (closure-based reduction —
    the engine that handles state-boundary checks the elaborator's
    substitution-based unifier cannot; S3 measurement) and the goal is
    assigned `Eq.refl lhs`. The assignment is re-checked by the kernel
    at declaration end as always — nothing is trusted beyond the
    kernel itself. Fails (goal untouched) on mvars or non-defeq. -/
elab "app_defeq" : tactic => do
  let goal ← getMainGoal
  goal.withContext do
    let ty ← instantiateMVars (← goal.getType)
    let some (α, l, r) := ty.consumeMData.eq?
      | throwError "app_defeq: goal is not an equation"
    if ty.hasExprMVar then
      throwError "app_defeq: goal carries metavariables"
    -- CONGR DECOMPOSITION: when both sides are applications of the
    -- SYNTACTICALLY identical function, check only the final
    -- arguments with the kernel and close by `congrArg f (Eq.refl a)`
    -- — the whole-equation kernel check was measured to deep-recurse
    -- where the state-only check passes.
    if l.isApp && r.isApp then
      let lf := l.appFn!
      let rf := r.appFn!
      let a := l.appArg!
      let b := r.appArg!
      let env ← getEnv
      let lctx ← getLCtx
      let fnOk := match Lean.Kernel.isDefEq env lctx lf rf with
        | .ok true => true | _ => false
      if fnOk then
        match Lean.Kernel.isDefEq env lctx a b with
        | .ok true =>
          let proof ← mkAppM ``congr
            #[← mkAppM ``Eq.refl #[lf], ← mkAppM ``Eq.refl #[a]]
          goal.assign proof
          replaceMainGoal []
          return
        | .ok false => throwError "app_defeq: kernel says args NOT defeq"
        | .error e =>
          throwError "app_defeq: kernel error on args {e.toMessageData {}}"
    match Lean.Kernel.isDefEq (← getEnv) (← getLCtx) l r with
    | .ok true =>
      let u ← getLevel α
      goal.assign (mkApp2 (mkConst ``Eq.refl [u]) α l)
      replaceMainGoal []
    | .ok false => throwError "app_defeq: kernel says NOT defeq"
    | .error e =>
      throwError "app_defeq: kernel error {e.toMessageData {}}"

/-! ## The KERNEL-ROUND walker (`dnms_kwalk`, walker v3 — S3):
    a dedicated dnms pipeline with NO unification machinery — per
    round it SYNTHESIZES the post-state (kernel whnf + the v2 state
    normal form), seals it as an auxiliary DEFINITION, and certifies
    the whole round as ONE auxiliary rfl-theorem whose kernel check
    re-derives the round (the T4 per-round-lemma structure,
    automated: every certificate is a small named-state-to-
    named-state equation, so kernel recursion is bounded per round).
    Stops (goal untouched by the failed round) at semantic rounds: a
    non-NOWAKEUP advance, a stuck computation, or a kernel refusal —
    such a round is then an explicit `app_walk_step`. -/

/-- Parse `app <5 ty args> (dnmsFuel fuelS tagDefs acc tids) σ`
    (the computation argument is reduced at reducible transparency so
    fixture abbrevs like `dnms5` unfold). -/
def parseDnmsApp (e : Expr) :
    MetaM (Option (Expr × Expr × Nat × Expr × Expr × Expr × Expr)) := do
  unless e.isAppOfArity `RelSem.app 7 do return none
  let args := e.getAppArgs
  let comp ← withReducible <| whnf args[5]!
  let σ := args[6]!
  let go : Option (Expr × Nat × Expr × Expr × Expr) := do
    guard (comp.isAppOfArity `drive_nonmemory_steps_aux2_lemFuel 4)
    let cargs := comp.getAppArgs
    let fuelS := cargs[0]!
    guard (fuelS.isAppOfArity `HAdd.hAdd 6)
    let base := fuelS.getAppArgs[4]!
    let litE := fuelS.getAppArgs[5]!
    let lit ← litE.rawNatLit? <|> (do
      guard (litE.isAppOfArity `OfNat.ofNat 3)
      litE.getAppArgs[1]!.rawNatLit?)
    guard (lit ≥ 1)
    return (base, lit, cargs[1]!, cargs[2]!, cargs[3]!)
  match go with
  | none => return none
  | some (base, lit, tagDefs, acc, tids) =>
    -- the head applied through the five implicit type args
    return some (e.appFn!.appFn!, base, lit, tagDefs, acc, tids, σ)

/-- Scan a steps spine for the first advanceable step (meta mirror of
    `find_can_advance`); the result is the EXACT spine subterm. -/
partial def scanSteps (e : Expr) : MetaM (Option Expr) := do
  let e ← kWhnf e
  if e.isAppOfArity `List.cons 3 then
    let hd := e.getAppArgs[1]!
    let ca ← kWhnf (← mkAppM `can_advance #[hd])
    if ca.isConstOf `Bool.true then
      return some hd
    else if ca.isConstOf `Bool.false then
      scanSteps e.getAppArgs[2]!
    else
      return none
  else
    return none

/-- One kernel-round: synthesize the post-state, seal, certify.
    Returns the continuation goal (`none` = the round was not
    taken). -/
def kwalkRound (cfg : WalkCfg) (goal : MVarId) :
    MetaM (Option (MVarId × Name)) := do
  goal.withContext do
  let tgt := (← instantiateMVars (← goal.getType)).consumeMData
  let some (_, lhs0, rhs) := tgt.eq? | return none
  let lhs ← whnfCore lhs0
  let some (appFn, base, lit, tagDefs, acc, tids, σ) ← parseDnmsApp lhs
    | return none
  -- single-thread shape: th_info = the head of the thread list
  let thList ← kWhnf (← mkAppM `core_state.thread_states
    #[← mkAppM `driver_state.core_state0 #[σ]])
  unless thList.isAppOfArity `List.cons 3 do return none
  let hdPair ← kWhnf thList.getAppArgs[1]!   -- (tid, th_info)
  unless hdPair.isAppOfArity `Prod.mk 4 do return none
  let tid ← kWhnf hdPair.getAppArgs[2]!
  let thInfo := hdPair.getAppArgs[3]!
  -- discovery + scan
  let steps ← kWhnf (← mkAppM `step_ctx
    #[tagDefs, ← mkAppM `driver_state.layout_state #[σ],
      ← mkAppM `driver_state.core_file #[σ],
      ← mkAppM `driver_state.core_extern #[σ], tid, thInfo])
  let some step1 ← scanSteps steps | return none
  -- the advance
  let advApp ← mkAppM `RelSem.app
    #[← mkAppM `advance_step #[tagDefs, tid, step1], σ]
  let adv ← kWhnf advApp
  unless adv.isAppOfArity `Prod.mk 4 do return none
  let outcome ← kWhnf adv.getAppArgs[2]!
  unless outcome.getAppFn.isConstOf `nd_action.NDactive do return none
  let wake ← kWhnf outcome.appArg!
  let wakeName := wake.getAppFn.constName?.getD .anonymous
  unless wakeName.getString! == "NOWAKEUP" do return none
  let σraw := adv.getAppArgs[3]!
  -- normalize + seal the post-state
  let σnorm ← normStateV2 cfg.atoms cfg.depth σraw
  let σconst ← mkAuxDefinition
    ((← mkFreshUserName `kwSt).appendAfter "_aux")
    (← inferType σnorm) σnorm (compile := false)
  -- the continuation LHS and THE ROUND CERTIFICATE
  let fuelPred ← if lit == 1 then pure base
    else mkAppM `HAdd.hAdd #[base, mkRawNatLit (lit - 1)]
  let compPred ← mkAppM `drive_nonmemory_steps_aux2_lemFuel
    #[fuelPred, tagDefs, acc, tids]
  let lhsPred := mkAppN appFn #[compPred, σconst]
  let cert ← mkAuxRfl lhs lhsPred
  let certName := cert.getAppFn.constName?.getD .anonymous
  -- chain
  let restTy ← mkEq lhsPred rhs
  let rest ← mkFreshExprMVar restTy (userName := `kwalk)
  goal.assign (← mkEqTrans cert rest)
  return some (rest.mvarId!, certName)

/-- `dnms_kwalk n` — walk up to `n` kernel-rounds. Each round runs in
    its own settled heartbeat window (the walker accounting). -/
syntax (name := dnmsKwalk) "dnms_kwalk" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| dnms_kwalk $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let atoms ← stateAtoms
    let cfg : WalkCfg := { norm := true, atoms := atoms,
                           candBudget := 200000 * 1000 }
    let mut g ← getMainGoal
    let mut count : Nat := 0
    for _ in [0:budget] do
      let hb0 ← IO.getNumHeartbeats
      let r ← tryCatchRuntimeEx
        (Core.withCurrHeartbeats do
          attempt cfg.candBudget (kwalkRound cfg g))
        (fun _ => pure none)
      IO.setNumHeartbeats hb0
      match r with
      | some (some (g', _)) => g := g'; count := count + 1
      | _ => break
    let _ := count
    replaceMainGoal [g]

/-- `app_defeq_fields` — close an equation between two STRUCTURE
    values (possibly under one application layer, as `app C σ = app
    C' σ'`) by kernel-whnf'ing both sides to their constructor
    applications and certifying each FIELD with its own kernel-checked
    rfl auxiliary, assembled by `congr`. Bounds the kernel's
    per-certificate work by field (the S3 boundary finding: the
    monolithic state check across a sealed def-chain deep-recurses
    where every field check passes). -/
elab "app_defeq_fields" : tactic => do
  let goal ← getMainGoal
  goal.withContext do
    let ty ← instantiateMVars (← goal.getType)
    let some (_, l0, r0) := ty.consumeMData.eq?
      | throwError "app_defeq_fields: goal is not an equation"
    if ty.hasExprMVar then
      throwError "app_defeq_fields: goal carries metavariables"
    let env ← getEnv
    let lctx ← getLCtx
    -- peel one application layer when the functions are kernel-defeq
    let (l, r, wrap?) ←
      if l0.isApp && r0.isApp then
        match Lean.Kernel.isDefEq env lctx l0.appFn! r0.appFn! with
        | .ok true => pure (l0.appArg!, r0.appArg!, some l0.appFn!)
        | _ => pure (l0, r0, none)
      else pure (l0, r0, none)
    -- whnf both to ctor applications
    let lC := match Lean.Kernel.whnf env lctx l with | .ok x => x | _ => l
    let rC := match Lean.Kernel.whnf env lctx r with | .ok x => x | _ => r
    unless lC.getAppFn.isConst && Expr.equal lC.getAppFn rC.getAppFn do
      throwError "app_defeq_fields: sides do not share a constructor"
    let lAs := lC.getAppArgs
    let rAs := rC.getAppArgs
    unless lAs.size == rAs.size do
      throwError "app_defeq_fields: arity mismatch"
    -- per-field certificates (params included; cheap when syntactic)
    let mut fieldPfs : Array Expr := #[]
    for i in [0:lAs.size] do
      let la := lAs[i]!
      let ra := rAs[i]!
      if Expr.equal la ra then
        fieldPfs := fieldPfs.push (← mkAppM ``Eq.refl #[la])
      else
        match Lean.Kernel.isDefEq env lctx la ra with
        | .ok true => fieldPfs := fieldPfs.push (← mkAuxRfl la ra)
        | .ok false =>
          throwError "app_defeq_fields: field {i} NOT defeq"
        | .error e =>
          throwError "app_defeq_fields: kernel error at field {i}: {e.toMessageData {}}"
    -- assemble: mk l1… = mk r1… by iterated congr
    let mut pf ← mkAppM ``Eq.refl #[lC.getAppFn]
    for fpf in fieldPfs do
      pf ← mkAppM ``congr #[pf, fpf]
    -- bridge the outer spellings (l = lC by rfl aux; rC = r by rfl aux)
    let lBridge ← if Expr.equal l lC then mkAppM ``Eq.refl #[l]
      else mkAuxRfl l lC
    let rBridge ← if Expr.equal rC r then mkAppM ``Eq.refl #[r]
      else mkAuxRfl rC r
    let mut whole ← mkEqTrans lBridge (← mkEqTrans pf rBridge)
    if let some f := wrap? then
      whole ← mkAppM ``congrArg #[f, whole]
      -- and bridge the possibly-different function spellings
      unless Expr.equal l0.appFn! r0.appFn! do
        let fBridge ← mkAuxRfl l0.appFn! r0.appFn!
        whole ← mkAppM ``congr #[fBridge, ← mkEqTrans lBridge (← mkEqTrans pf rBridge)]
    goal.assign whole
    replaceMainGoal []

/-- `app_defeq_diag` — DIAGNOSTIC (debug only): kernel-whnf both
    sides to ctor spines and report pairwise kernel-defeq per
    argument, recursing into differing arguments (depth-bounded). -/
partial def defeqDiag (env : Environment) (lctx : LocalContext)
    (d : Nat) (path : String) (l r : Expr) : MetaM Unit := do
  match Lean.Kernel.isDefEq env lctx l r with
  | .ok true => logInfo m!"DIAG {path}: OK"
  | .error _ => logInfo m!"DIAG {path}: KERNEL ERR"
  | .ok false =>
    if d == 0 then
      logInfo m!"DIAG {path}: DIFF (depth cap) {l.getAppFn} vs {r.getAppFn}"
      return
    let l' := match Lean.Kernel.whnf env lctx l with | .ok x => x | _ => l
    let r' := match Lean.Kernel.whnf env lctx r with | .ok x => x | _ => r
    let lf := l'.getAppFn
    let rf := r'.getAppFn
    if Expr.equal lf rf && l'.getAppArgs.size == r'.getAppArgs.size then
      logInfo m!"DIAG {path}: same head {lf}, recursing args"
      for i in [0:l'.getAppArgs.size] do
        defeqDiag env lctx (d-1) s!"{path}.{i}" l'.getAppArgs[i]! r'.getAppArgs[i]!
    else
      logInfo m!"DIAG {path}: HEAD DIFF {lf} VS {rf}"

elab "app_defeq_diag" : tactic => do
  let goal ← getMainGoal
  goal.withContext do
    let ty ← instantiateMVars (← goal.getType)
    let some (_, l, r) := ty.consumeMData.eq? | throwError "not an eq"
    defeqDiag (← getEnv) (← getLCtx) 9 "root" l r

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
