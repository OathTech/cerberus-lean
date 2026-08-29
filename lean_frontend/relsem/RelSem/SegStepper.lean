/-
  RelSem.SegStepper — V2b (2026-08-28): THE CUT-POINT STEPPER.

  `seg_run` — at a goal `Ctx.interp Γ ⊢ WP (dnmsK td F acc tid xs' k)
  …`, repeatedly select the applicable ROUND EQUATION from the
  registered supply (kind `roundEq`, DiscrTree goal-form dispatch —
  the R4 contract), pick the matching SEGMENT LINK RULE by trial
  against the registered `segLink` intros (RelSem/SegRun.lean),
  discharge the side premises (family shapes and control transports
  by hinted `rfl`; env-cell/footprint indexes computed against the
  canonical context; ledger freshness by literal reduction +
  membership refutation at kernel-decided `Int` disequalities;
  footprint facts from the round equation's own hypotheses; path
  conditions and range facts from the LOCAL CONTEXT), and RUN to the
  next cut point — stopping at BRANCHES (candidates under
  complementary path conditions: the tactic reports every candidate
  and its unsourced hypothesis, the user case-splits), at the
  TERMINAL (a `Sum.inr` offer round — `Seg.seg_done`'s job), or at
  any undispatchable state (LOUD fail-closed frontier).

  The accumulated run is emitted as ONE `SegStep` chain
  (`SegStep.trans` links, explicit counts) consumed by ONE
  `SegStep.consume` — the proof term applies exactly the named,
  registered rules a hand proof applies (the escalation ladder's
  floor; no closed black box). PURE Meta side-proof construction
  throughout — no internal tactic recovery (the V1 `Elab.runTactic`
  hazard); every failure throws.

  Lineage: Floyd cut points / Hoare composition (the chain IS the
  sequence rule); brick-wp `wp_auto` / Lithium goal-directed rule
  application one level up (segments, not source steps); the
  registry-dispatch discipline is arc-18 R4's.

  House rules: no sorry, no axioms; meta code only — every emitted
  object is an ordinary kernel-checked term.
-/

import RelSem.SegRun
import RelSem.CStep

set_option autoImplicit false

open Lean Elab Meta Tactic
open RelSem RelSem.Cerb RelSem.CerbSt

namespace RelSem.Seg.Stepper

initialize registerTraceClass `RelSem.segRun
initialize registerTraceClass `RelSem.segRun.detail

/-- Speculative-probe heartbeat isolation (the R4 move).
    PERF-1 finding, recorded: the `withOptions` spelling does NOT
    update `Core.Context.maxHeartbeats` (the checker reads the
    context field, set at elaboration entry), so probes actually run
    at the AMBIENT limit with a fresh baseline. This is kept AS-IS
    deliberately: heartbeats are a GLOBAL counter, so probe work
    bills the enclosing round budget too — a probe allowed to run
    past the ambient limit blows the round that hosts it (measured:
    a T1Proof 200k blowout under a true-1M probe variant). The
    honest semantics is "probe ≤ ambient, isolated baseline". -/
private def withProbeBudget {α : Type} (x : MetaM α) : MetaM α :=
  Core.withCurrHeartbeats
    (withOptions (fun o => o.set `maxHeartbeats (1000000 : Nat)) x)

/-- Hinted refl: `Eq.refl rhs` cast to `lhs = rhs`. -/
private def mkRflHint (ty : Expr) : MetaM Expr := do
  let some (_, _, rhs) := ty.eq?
    | throwError "seg_run: rfl hint on a non-equation:{indentExpr ty}"
  mkExpectedTypeHint (← mkEqRefl rhs) ty

/-- `fun xs… => rfl` at a ∀-of-equation type. -/
private def mkRflFun (ty : Expr) : MetaM Expr :=
  forallTelescope ty fun xs body => do
    mkLambdaFVars xs (← mkRflHint body)

/-- The canonical pack anchor (for control images). -/
private def mkPack0 : MetaM Expr := do
  let fe ← mkAppOptM ``fmapEmpty
    #[some (mkConst ``sym), some (mkConst ``value)]
  mkAppM ``RelSem.Seg.Pack.mk
    #[fe, mkNatLit 0, mkNatLit 0, mkNatLit 0, mkNatLit 0,
      mkConst ``CerbMem.initialMemState]

/-- `a ∉ l` at Int-literal lists: reduce, then refute membership
    structurally (kernel `decide` at `Int` Eq leaves — the ambient
    `Decidable (a ∈ l)` instance is absent in this prelude). -/
private partial def buildNotMem (a : Expr) (l : Expr) : MetaM Expr := do
  let l ← whnf l
  if l.isAppOfArity ``List.nil 1 then
    mkAppM ``RelSem.Seg.not_mem_nil_int #[a]
  else if l.isAppOfArity ``List.cons 3 then
    let b := l.getAppArgs[1]!
    let rest := l.getAppArgs[2]!
    let neTy ← mkAppM ``Ne #[a, b]
    -- verify the decide FIRST (mkDecideProof does not evaluate; an
    -- unverified proof at equal keys is the kernel-caught T5 bug)
    let d ← mkDecide neTy
    let r ← match Lean.Kernel.whnf (← getEnv) (← getLCtx) d with
      | .ok r => pure r
      | .error _ =>
        throwError "seg_run: freshness decide did not compute"
    unless r.isConstOf ``Bool.true do
      throwError "seg_run: freshness REFUTED (the key is present — \
        rebind class, not a birth):{indentExpr neTy}"
    let neP ← mkDecideProof neTy
    mkAppM ``RelSem.Seg.not_mem_cons_of #[neP, ← buildNotMem a rest]
  else
    throwError "seg_run: freshness list did not reduce to a \
      literal:{indentExpr l}"

private def mkNotMemProof (ty : Expr) : MetaM Expr := do
  unless ty.isAppOfArity ``Not 1 do
    throwError "seg_run: freshness goal is not a negation:\
      {indentExpr ty}"
  let mem := ty.appArg!
  unless mem.isAppOfArity ``Membership.mem 5 do
    throwError "seg_run: freshness goal is not a membership:\
      {indentExpr mem}"
  let args := mem.getAppArgs
  let a ← withProbeBudget <| reduce args[4]! (explicitOnly := false)
    (skipTypes := true) (skipProofs := true)
  let l0 ← withProbeBudget <| reduce args[3]! (explicitOnly := false)
    (skipTypes := true) (skipProofs := true)
  mkExpectedTypeHint (← buildNotMem a l0) ty

private def kwhnf? (e : Expr) : MetaM (Option Expr) := do
  match Lean.Kernel.whnf (← getEnv) (← getLCtx) e with
  | .ok r => pure (some r)
  | .error _ => pure none

/-- Hinted refl at the LHS (the discovery-pin device: the kernel
    re-checks `lhs ≡ rhs` at declaration add — fail-closed). -/
private def mkLhsRflHint (lhs rhs : Expr) : MetaM Expr := do
  mkExpectedTypeHint (← mkEqRefl lhs) (← mkEq lhs rhs)

/-- Deep kernel pin: unify a (possibly mvar-carrying) constructor
    PATTERN against the kernel normal form of a term, kernel-whnf-ing
    on demand and descending only where the pattern is concrete
    (mvar leaves take the kernel form as-is). -/
private partial def kMatchAssign (pat res : Expr) : MetaM Bool := do
  let patI ← instantiateMVars pat
  if patI.isMVar then
    isDefEq patI res
  else do
    let resW ← match ← kwhnf? res with
      | some r => pure r
      | none => pure res
    let pf := patI.getAppFn
    let rf := resW.getAppFn
    if pf.isConst && rf.isConst && pf.constName! == rf.constName!
        && patI.getAppNumArgs == resW.getAppNumArgs then
      let pas := patI.getAppArgs
      let ras := resW.getAppArgs
      for i in [0:pas.size] do
        unless ← kMatchAssign pas[i]! ras[i]! do return false
      return true
    else
      withProbeBudget (isDefEqGuarded patI resW)

/-- Close a ground-equation premise mvar by the deep kernel pin
    (certificate: hinted rfl at the LHS). -/
private def kpinEqPremise (m : Expr) : MetaM Unit := do
  let ty ← instantiateMVars (← m.mvarId!.getType)
  let some (_, lhs, rhs) := ty.eq?
    | throwError "mint: kpin premise is not an equation:{indentExpr ty}"
  unless ← kMatchAssign rhs lhs do
    throwError "mint: ground premise did not kernel-pin (sym-carrying \
      remainder? — supply fallback):{indentExpr ty}"
  let ty ← instantiateMVars ty
  let some (_, lhs, rhs) := ty.eq? | unreachable!
  unless ← isDefEq m (← mkLhsRflHint lhs rhs) do
    throwError "mint: kpin certificate assignment failed"


/-- Close a hypothesis hole from: the premise telescope's locals, the
    outer local context, the memory-residual gadgets, hinted `rfl`. -/
private def solveHyp (locals : Array Expr) (m : MVarId)
    (xsOnly : Bool := false) : MetaM Bool := do
  let ty ← instantiateMVars (← m.getType)
  for src in locals do
    if ← withProbeBudget (isDefEqGuarded (← inferType src) ty) then
      m.assign src
      return true
  if xsOnly then return false
  for d in (← getLCtx) do
    if d.isImplementationDetail then continue
    if ← withProbeBudget (isDefEqGuarded d.type ty) then
      m.assign d.toExpr
      return true
  if ty.isEq then
    -- memory-residual gadgets (the load class's hlum/hfpm feeders)
    for src in locals do
      let sTy ← instantiateMVars (← inferType src)
      if sTy.isEq && sTy.appFn!.appArg!.isAppOf
          ``memRestOf then
        for g in [``memRestOf_lastUsedUnionMembers,
            ``memRestOf_funptrmap,
            ``memRestOf_lastAddress,
            ``memRestOf_nextAllocId] do
          let ok ← withProbeBudget <| observing? do
            let g1 ← mkAppM g #[src]
            let some (_, _, grhs) := (← inferType g1).eq? | failure
            let some (_, _, rhs) := ty.eq? | failure
            let g2 ← mkExpectedTypeHint (← mkEqRefl rhs)
              (← mkEq grhs rhs)
            let pf ← mkEqTrans g1 g2
            unless ← isDefEq (← inferType pf) ty do failure
            pure pf
          if let some pf := ok then
            m.assign pf
            return true
    if let some (_, lhs, rhs) := ty.eq? then
      -- SOUND rfl fallback: the sides must be defeq NOW (a hinted
      -- refl's inferred type is the hint itself — checking it against
      -- `ty` is vacuous and defers the mismatch to the kernel)
      if ← withProbeBudget (isDefEqGuarded lhs rhs) then
        m.assign (← mkRflHint ty)
        return true
  -- ground decidable Props (the load/store range side conditions at
  -- literal values): kernel-verified decide (V3a continuation)
  if !ty.hasExprMVar && !ty.hasFVar then
    if let some pf ← observing? (do
        let d ← mkDecide ty
        let r ← match Lean.Kernel.whnf (← getEnv) (← getLCtx) d with
          | .ok r => pure r
          | .error _ => failure
        unless r.isConstOf ``Bool.true do failure
        mkDecideProof ty) then
      m.assign pf
      return true
  return false

/-- Fill a link's `happ` premise from the (pre-telescoped) round
    equation: unify sides left-to-right, close the hypothesis holes,
    package the lambda. -/
private def fillHapp (happTy : Expr) (cand : Name) :
    MetaM (Expr × Array Expr × Array MVarId) := do
  forallTelescope happTy fun xs body => do
    let cinfo ← getConstInfo cand
    -- the candidate is telescoped INSIDE the pack binder so its own
    -- pack/hypothesis metas may be assigned terms mentioning it
    let (margs, _, concl) ← forallMetaTelescope cinfo.type
    -- unify the equation SIDES left-to-right (the LHS pins the pack
    -- binder deterministically before the successor's higher-order
    -- abstraction)
    if let (some (_, bl, br), some (_, cl, cr)) := (body.eq?, concl.eq?)
    then
      unless ← withProbeBudget (isDefEq cl bl) do
        throwError "round {cand}: step LHS does not match"
      unless ← withProbeBudget (isDefEq cr br) do
        throwError "round {cand}: step RHS does not match"
    unless ← withProbeBudget (isDefEq concl body) do
      throwError "round {cand}: conclusion does not match the \
        expected step"
    let mut deferred : Array MVarId := #[]
    for marg in margs do
      let marg ← instantiateMVars marg
      if marg.isMVar then
        let mty ← instantiateMVars (← marg.mvarId!.getType)
        -- ONLY Prop holes are hypothesis holes; DATA holes (the
        -- branch-valued scalars like the shared rounds' `c`) stay
        -- flex — the canonical-context index premises disambiguate
        -- them (solving a data hole from the local context would
        -- grab an arbitrary same-typed term)
        unless (← inferType mty).isProp do continue
        if mty.hasExprMVar
            && (mty.getAppFn.isConstOf ``LE.le
                || mty.getAppFn.isConstOf ``LT.lt
                || mty.getAppFn.isConstOf ``GE.ge
                || mty.getAppFn.isConstOf ``GT.gt) then
          -- PERF-1 (the p02r35 wrong-scalar find): a Prop hole still
          -- carrying DATA mvars must not be closed by OUTER-context
          -- matching unless the match is UNIQUE — an ambiguous match
          -- (ha1 vs hb1 at two scalars) would pin the data to
          -- whatever hypothesis comes first. Telescope-local sources
          -- are structural (the link's own typed binders) and stay
          -- allowed; ambiguity DEFERS until the link's determined
          -- premises (indexes) pin the data.
          unless ← solveHyp xs marg.mvarId! (xsOnly := true) do
            let mut nMatch := 0
            let mtyHead := mty.getAppFn
            for d in (← getLCtx) do
              if d.isImplementationDetail then continue
              -- cheap syntactic pre-filter: only same-head
              -- hypotheses enter the defeq probe (the context also
              -- holds arena-sized Iris terms — probing those is the
              -- whnf cost class PERF-1 killed)
              unless d.type.getAppFn.constName? == mtyHead.constName?
                  && d.type.getAppFn.constName?.isSome do continue
              -- withoutModifyingState, NOT withNewMCtxDepth: the
              -- probe's "match" IS an assignment of the outer data
              -- mvar, which a deeper mctx level forbids (measured:
              -- the depth-guarded probe counts 0 and the else-path
              -- re-grabs the wrong scalar)
              let hit ← withoutModifyingState <| withProbeBudget
                (isDefEqGuarded d.type mty)
              if hit then nMatch := nMatch + 1
            if nMatch ≥ 2 then
              -- MEASURED ambiguity only (the p02r35 two-scalar case)
              -- defers; a unique or unprobed source keeps the
              -- standing grab-first behavior
              deferred := deferred.push marg.mvarId!
            else
              unless ← solveHyp xs marg.mvarId! do
                throwError "round {cand}: hypothesis has no source:\
                  {indentExpr mty}"
          continue
        unless ← solveHyp xs marg.mvarId! do
          throwError "round {cand}: hypothesis has no source:\
            {indentExpr mty}"
        trace[RelSem.segRun.detail] "fillHapp: hole {mty} := \
          {← instantiateMVars marg}"
    let pf := mkAppN (mkConst cand (cinfo.levelParams.map .param)) margs
    return (← mkLambdaFVars xs (← instantiateMVars pf), xs, deferred)

/-- Index of the entry whose FIRST component is `key` in a pair-list
    expression (whnf-driven; sees through `eraseIdx` on literals). -/
private partial def findPairIdx (key : Expr) (lst : Expr)
    (i : Nat := 0) : MetaM Nat := do
  let l ← whnf lst
  if l.isAppOfArity ``List.cons 3 then
    let pair ← whnf l.getAppArgs[1]!
    let k ← if pair.isAppOfArity ``Prod.mk 4 then
        pure pair.getAppArgs[2]!
      else mkAppM ``Prod.fst #[pair]
    if ← withProbeBudget (isDefEqGuarded k key) then
      return i
    findPairIdx key l.getAppArgs[2]! (i + 1)
  else
    throwError "seg_run: entry with key {key} not found in the \
      context list"

/-- The Γ record's components (whnf to the constructor). -/
private def ctxComponents (Γ : Expr) : MetaM (Array Expr) := do
  let Γw ← whnf Γ
  unless Γw.isAppOfArity ``RelSem.Seg.Ctx.mk 6 do
    throwError "seg_run: context is not a literal record:\
      {indentExpr Γ}"
  return Γw.getAppArgs

private def linkConsts : List Name :=
  [``RelSem.Seg.link_ctl, ``RelSem.Seg.link_ctl_env1,
   ``RelSem.Seg.link_ctl_env2, ``RelSem.Seg.link_birth1,
   ``RelSem.Seg.link_birth1_env1, ``RelSem.Seg.link_birth2,
   ``RelSem.Seg.link_load,
   ``RelSem.Seg.link_store, ``RelSem.Seg.link_create,
   ``RelSem.Seg.link_kill, ``RelSem.Seg.link_ctl_sup,
   ``RelSem.Seg.link_ctl_rebind1, ``RelSem.Seg.link_ctl_rebind2]

private structure BuiltLink where
  pf : Expr
  delta : Expr
  /-- Round count consumed by this link (1 for a round link; K for a
      PERF-1 block fact — mechanism B). -/
  n : Nat := 1
  /-- Provenance: true when the link was MINTED from the construct
      package (PERF-2 mechanism C) with no generated supply fact. -/
  minted : Bool := false
  deriving Inhabited

/-- Dispatch one open premise of a link by type shape. Returns true
    on progress. -/
private def dispatchPremise (linkC : Name) (pack0 : Expr) (m : MVarId) :
    MetaM Bool := do
  let ty ← instantiateMVars (← m.getType)
  -- FamShape fam (fam must be resolved)
  if ty.isAppOf ``RelSem.Seg.FamShape then
    if ty.hasExprMVar then return false
    let ci ← getConstInfo ``RelSem.Seg.FamShape.mk
    let (cargs, _, cconcl) ← forallMetaTelescope ci.type
    unless ← isDefEq cconcl ty do
      throwError "seg_run [{linkC}]: FamShape mismatch"
    for ca in cargs do
      let ca ← instantiateMVars ca
      if ca.isMVar then
        let caTy ← instantiateMVars (← ca.mvarId!.getType)
        let pf ← mkRflFun caTy
        unless ← isDefEq ca pf do
          throwError "seg_run [{linkC}]: FamShape field is not rfl:\
            {indentExpr caTy}"
    m.assign (← instantiateMVars (mkAppN
      (mkConst ``RelSem.Seg.FamShape.mk (ci.levelParams.map .param))
      cargs))
    return true
  -- family inversion (concludes ∃ p, σ = fam p)
  let isInv ← forallTelescope ty fun _ body =>
    pure (body.isAppOf ``Exists)
  if isInv then
    if ty.hasExprMVar then return false
    let cands ← forallTelescope ty fun _ body =>
      RelSem.LawRegistry.query `famInv body
    for l in cands do
      let ok ← observing? do
        forallTelescope ty fun xs body => do
          let ci ← getConstInfo l.name
          let (ms, _, cc) ← forallMetaTelescope ci.type
          unless ← withProbeBudget (isDefEq cc body) do failure
          for mm in ms do
            let mm ← instantiateMVars mm
            if mm.isMVar then
              let mmty ← instantiateMVars (← mm.mvarId!.getType)
              unless (← inferType mmty).isProp do continue
              unless ← solveHyp xs mm.mvarId! do failure
          mkLambdaFVars xs (← instantiateMVars (mkAppN
            (mkConst l.name (ci.levelParams.map .param)) ms))
      if let some pf := ok then
        m.assign pf
        return true
    throwError "seg_run [{linkC}]: no registered famInv matches:\
      {indentExpr ty}"
  -- ledger freshness ¬ _ ∈ _
  if ty.isAppOfArity ``Not 1 && ty.appArg!.isAppOf ``Membership.mem then
    if ty.hasExprMVar then return false
    let pf ← mkNotMemProof ty
    m.assign pf
    return true
  -- apartness symNum _ ≠ symNum _
  if ty.isAppOf ``Ne then
    if ty.hasExprMVar then return false
    -- VERIFY the decide before assigning (V3a continuation: MVarId
    -- .assign is unchecked — an unverified decide-proof at a FALSE
    -- apartness reached the kernel as an ill-typed term at the T5
    -- save round; the kernel caught it — this keeps the failure at
    -- the dispatch, where the link falls through loudly)
    let d ← mkDecide ty
    let some r ← kwhnf? d | return false
    unless r.isConstOf ``Bool.true do return false
    m.assign (← mkDecideProof ty)
    return true
  -- index premises: _[i]? = some (k, v)
  if ty.isEq then
    let some (_, lhs, rhs) := ty.eq? | return false
    let lhsFn := lhs.getAppFn
    let isGet := lhsFn.isConstOf ``getElem? ||
      (lhsFn.constName?.map (·.componentsRev.head! == `getElem?)
        |>.getD false)
    if isGet then
      let gargs := lhs.getAppArgs
      let lst := gargs[gargs.size - 2]!
      let idxE ← instantiateMVars gargs[gargs.size - 1]!
      let rhsW ← instantiateMVars rhs
      if lst.hasExprMVar then return false
      unless rhsW.isAppOf ``Option.some do
        throwError "seg_run [{linkC}]: index premise rhs shape:\
          {indentExpr rhsW}"
      let pairE := rhsW.getAppArgs.back!
      let pairW ← whnf pairE
      let key ← if pairW.isAppOfArity ``Prod.mk 4 then
          pure pairW.getAppArgs[2]!
        else mkAppM ``Prod.fst #[pairE]
      -- the KEY must be determined; the VALUE may still be flex (a
      -- branch-valued scalar) — the sides-unification below both
      -- CHECKS the entry and ASSIGNS the flex value (this is what
      -- disambiguates same-key candidates: the branch-arm rounds
      -- differ only in cell VALUES)
      if (← instantiateMVars key).hasExprMVar then return false
      if idxE.isMVar then
        let idx ← findPairIdx key lst
        unless ← isDefEq idxE (mkNatLit idx) do
          throwError "seg_run [{linkC}]: index assignment failed"
      let ty' ← instantiateMVars (← m.getType)
      let some (_, lhs', rhs') := ty'.eq?
        | throwError "seg_run [{linkC}]: index premise shape"
      unless ← withProbeBudget (isDefEqGuarded lhs' rhs') do
        throwError "seg_run [{linkC}]: index premise does not hold \
          (wrong cell value?):{indentExpr ty'}"
      let ty' ← instantiateMVars (← m.getType)
      m.assign (← mkRflHint ty')
      return true
    -- ground equation premises (the memory links' hsz/haddr/hnz
    -- class): closed on both sides — kernel-pin (V3a continuation)
    if !ty.hasExprMVar then
      if (← observing? (kpinEqPremise (Expr.mvar m))).isSome then
        return true
    return false
  -- control transport ∀ p, ctlOf (famO …) = cO
  let isCtl ← forallTelescope ty fun _ body =>
    pure (body.isEq &&
      body.appFn!.appArg!.isAppOf ``ctlOf)
  if isCtl then
    forallTelescope ty fun xs body => do
      let some (_, lhsC, rhsC) := body.eq? | pure ()
      let rhsC ← instantiateMVars rhsC
      if rhsC.isMVar then
        -- anchor the control image at the canonical pack: abstract
        -- the state over the telescope's pack binder, apply at pack0
        let famApp ← instantiateMVars lhsC.appArg!
        let anchorArg := (famApp.abstract xs).instantiateRev
          #[pack0]
        -- ONE cached fvar pass (V3a-continuation): `hasAnyFVar` is an
        -- uncached traversal — exponential on the DAG-shared flat
        -- successor literals (same class as the containsFVar find)
        let fvSt := Lean.collectFVars {} anchorArg
        if xs.any (fun x => fvSt.fvarSet.contains x.fvarId!) then
          throwError "seg_run [{linkC}]: control image depends on \
            the pack in a non-erasable position"
        let anchor ← mkAppM ``ctlOf #[anchorArg]
        unless ← isDefEq rhsC anchor do
          throwError "seg_run [{linkC}]: control anchor assignment \
            failed"
    let ty' ← instantiateMVars (← m.getType)
    if ty'.hasExprMVar then return false
    m.assign (← mkRflFun ty')
    return true
  -- typeclass holes
  if (← isClass? ty).isSome then
    if let .some inst ← trySynthInstance ty then
      m.assign inst
      return true
  return false

/-- Build ONE link for a candidate round equation at context `ΓE`.
    Throws (with the reason) when the candidate/link pair does not
    apply. -/
private def buildLink (gf gs td tid : Expr) (ΓE : Expr) (cand : Name)
    (linkC : Name) : MetaM BuiltLink := do
  let cinfo ← getConstInfo linkC
  let (args, _, concl) ← forallMetaTelescope cinfo.type
  unless concl.isAppOfArity ``RelSem.Seg.SegStep 7 do
    throwError "seg_run: link {linkC} conclusion shape \
      ({concl.getAppNumArgs} args)"
  let cargs := concl.getAppArgs
  unless (← isDefEq cargs[0]! gf) && (← isDefEq cargs[1]! gs)
      && (← isDefEq cargs[2]! td) && (← isDefEq cargs[3]! tid) do
    throwError "seg_run [{linkC}]: instance/program unification failed"
  unless ← isDefEq cargs[cargs.size - 2]! ΓE do
    throwError "seg_run [{linkC}]: entry context does not unify"
  let cI ← instantiateMVars ((← ctxComponents ΓE)[0]!)
  -- telescope the candidate ONCE; pre-pin the link's famI from its
  -- entry state (fun q => σE[pack ↦ q]) so the happ unification is
  -- first-order at the pack binder
  let candInfo ← getConstInfo cand
  let (margs, _, candConcl) ← forallMetaTelescope candInfo.type
  let some (_, clhs, _) := candConcl.eq?
    | throwError "round {cand}: not an equation"
  let σE ← instantiateMVars clhs.appArg!
  let packMetas ← margs.filterM fun ma => do
    let ma ← instantiateMVars ma
    if ma.isMVar then
      -- fixture packs are spelled through the `T1P := Seg.Pack`-style
      -- abbrevs — unfold to the structure before matching
      return (← whnfR (← instantiateMVars
        (← ma.mvarId!.getType))).isConstOf ``RelSem.Seg.Pack
    else
      return false
  unless packMetas.size == 1 do
    throwError "round {cand}: expected exactly one pack binder, \
      found {packMetas.size}"
  let famIExpr ← withLocalDeclD `q (mkConst ``RelSem.Seg.Pack)
    fun q => do
      mkLambdaFVars #[q] (σE.replace fun e =>
        if packMetas.any (fun pm => e == pm) then some q else none)
  -- famO from the candidate's successor: the fam-applied RHS shape
  -- (`fam a tr n packUpd` — the supply's normal form) minus its
  -- final (pack) argument
  let some (_, _, crhs) := candConcl.eq?
    | throwError "round {cand}: not an equation"
  let crhsW ← whnf (← instantiateMVars crhs)
  unless crhsW.isAppOfArity ``Prod.mk 4 do
    throwError "round {cand}: successor pair shape"
  let succE := crhsW.getAppArgs[3]!
  unless succE.isApp do
    throwError "round {cand}: successor is not fam-applied"
  let famOExpr := succE.appFn!
  -- pre-pin the two fam slots (declaration order: famI, famO)
  let mut famPins := #[famIExpr, famOExpr]
  let mut pinIdx := 0
  for a in args do
    if pinIdx ≥ famPins.size then continue
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      let isFamTy := aty.isArrow &&
        aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack &&
        aty.bindingBody!.isConstOf ``driver_state
      if isFamTy then
        unless ← isDefEq a famPins[pinIdx]! do
          throwError "seg_run [{linkC}]: fam slot {pinIdx} pre-pin \
            failed"
        pinIdx := pinIdx + 1
  unless pinIdx == 2 do
    throwError "seg_run [{linkC}]: fam slots not found (pre-pin)"
  -- THE CONTROL PIN: the candidate's scalar parameters (the outer
  -- symbolic inputs) are determined by requiring its entry state's
  -- control image to be cI (pack slot masked by a fresh local so it
  -- cannot be captured by the anchor pack)
  withLocalDeclD `qPin (mkConst ``RelSem.Seg.Pack) fun q => do
    let σE' := σE.replace fun e =>
      if packMetas.any (fun pm => e == pm) then some q else none
    let ctlB ← mkAppM ``ctlOf #[σE']
    unless ← withProbeBudget (isDefEq ctlB cI) do
      throwError "round {cand}: entry control image does not pin"
  -- happ (pins the pack binder, famO, and the class scalars)
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq &&
        body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then
      happIdx := some i
  let some hi := happIdx
    | throwError "seg_run: link {linkC} has no happ premise"
  let happTy ← instantiateMVars (← inferType args[hi]!)
  let (happPf, _happXs, happDeferred) ← fillHapp happTy cand
  trace[RelSem.segRun.detail] "buildLink [{linkC}]: happ filled: \
    {← inferType happPf}"
  trace[RelSem.segRun.detail] "buildLink [{linkC}]: slot type: \
    {← instantiateMVars (← inferType args[hi]!)}"
  unless ← isDefEq args[hi]! happPf do
    throwError "seg_run [{linkC}]: happ assignment failed"
  trace[RelSem.segRun] "buildLink [{linkC}]: happ assigned"
  let pack0 ← mkPack0
  -- premise dispatch to a fixed point
  let mut progress := true
  while progress do
    progress := false
    for a in args do
      let a ← instantiateMVars a
      if a.isMVar then
        let aty ← instantiateMVars (← a.mvarId!.getType)
        trace[RelSem.segRun.detail] "buildLink [{linkC}]: dispatch on \
          {aty}"
        if ← dispatchPremise linkC pack0 a.mvarId! then
          progress := true
  -- deferred happ hypothesis holes: the data is pinned now (the
  -- index premises ran) — outer-context sourcing is unambiguous
  for dm in happDeferred do
    -- the lambda packaging DELAY-ASSIGNS the original hole to a
    -- fresh pi-abstracted mvar applied to the telescope — chase to
    -- the live head before solving
    let cur ← instantiateMVars (Expr.mvar dm)
    let live? := if cur.isMVar then some cur.mvarId!
      else if cur.getAppFn.isMVar then some cur.getAppFn.mvarId!
      else none
    if let some live := live? then
      let dty ← instantiateMVars (← live.getType)
      if dty.hasExprMVar then
        throwError "seg_run [{linkC}]: deferred hypothesis still \
          carries data mvars:{indentExpr dty}"
      -- solve the BODY (now data-pinned, outer-sourced) under the
      -- abstraction and re-wrap
      let pf ← forallTelescope dty fun ys body => do
        let m2 ← mkFreshExprMVar body
        unless ← solveHyp #[] m2.mvarId! do
          throwError "seg_run [{linkC}]: deferred hypothesis has \
            no source:{indentExpr body}"
        mkLambdaFVars ys (← instantiateMVars m2)
      live.assign pf
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      throwError "seg_run [{linkC}]: unfilled premise:\
        {indentExpr (← instantiateMVars (← a.mvarId!.getType))}"
  let concl ← instantiateMVars concl
  let delta := concl.getAppArgs[concl.getAppNumArgs - 1]!
  if delta.hasExprMVar then
    throwError "seg_run [{linkC}]: successor context still open"
  if (← instantiateMVars happPf).hasExprMVar then
    throwError "seg_run [{linkC}]: round equation {cand} has an \
      UNDETERMINED data binder (unused ∀-scalar?) — drop it from \
      the supply statement"
  let pf ← instantiateMVars (mkAppN
    (mkConst linkC (cinfo.levelParams.map .param)) args)
  return { pf, delta }

/-! PERF-1 mechanism B: consume a registered BLOCK FACT
    (`@[seg_block]`, kind `segBlock`) at the current context —
    committed choice, blocks BEFORE per-round links. A block lemma is
    `SegStep td tid K Γᵢ Γₒ` quantified over the context components
    and its data scalars; instantiation = one guarded `isDefEq` of
    its conclusion against the current context (the data binders pin
    through the control term), no premises (pure-control runs carry
    none by construction). -/

/-- The (arena constant, round counter) of a ctl-image spelling
    (`ctlOf (fam AR TR N p)`-class): the cheap syntactic dispatch
    key — both components are literal on both sides, so wrong-
    position candidates never enter unification at all. -/
private def ctlArenaKey? (c : Expr) : Option (Name × Nat) :=
  let c := c.consumeMData
  let inner := if c.isAppOf ``ctlOf then c.appArg! else c
  -- keys exist only for the fam-builder spelling `ctlOf (fam AR TR N p)`
  -- (const head, ≥ 4 args). Anything else — engine-minted successors
  -- (`ctlOf (dnmsBump …)`, beta-redexes over `stateAt`), record
  -- literals — gets NO key: the key filter is an under-approximation
  -- of "cannot match", and a junk key would wrongly reject defeq
  -- cross-vocabulary candidates (V3a mint-path finding).
  if !inner.getAppFn.isConst || inner.getAppNumArgs < 4 then none else
  let args := inner.getAppArgs
  match args[0]? with
  | some a =>
    match a.getAppFn.constName? with
    | some n =>
      -- fam AR TR N p — the ctr is the second-to-last argument
      if h : args.size ≥ 2 then
        match args[args.size - 2]!.rawNatLit? with
        | some k => some (n, k)
        | none => some (n, 0)
      else some (n, 0)
    | none => none
  | none => none

private def tryBlock (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) : MetaM (Option BuiltLink) := do
  let ciS ← getConstInfo ``RelSem.Seg.SegStep
  let us ← ciS.levelParams.mapM fun _ => mkFreshLevelMVar
  let nM ← mkFreshExprMVar (mkConst ``Nat)
  let ΔM ← mkFreshExprMVar (mkConst ``RelSem.Seg.Ctx)
  let queryE := mkAppN (mkConst ciS.name us)
    #[gf, gs, td, tid, nM, ΓE, ΔM]
  -- enumerate the kind directly: the registry's DiscrTree keys come
  -- from `forallMetaTelescopeReducing`, which unfolds `SegStep` into
  -- its entailment form — the SegStep-app query can never tree-match
  -- (PERF-1 finding). Block counts are small (O(cut points));
  -- committed choice by the ARENA-CONSTANT key (cheap syntactic
  -- dispatch — a mismatched ctl defeq falls into the ctl-projection
  -- whnf, the cost class PERF-1 killed). A substitution instantiates
  -- the data VARIABLES inside the arena application, never the arena
  -- constant, so key-matching survives subst; spelling BRIDGES
  -- (e.g. onto the mC-literal supply) happen at per-round anchors
  -- through the round filter, never at blocks.
  let hits ← RelSem.LawRegistry.byKind `segBlock
  if hits.isEmpty then return none
  let curKey := ctlArenaKey? comps[0]!
  trace[RelSem.segRun.detail] "tryBlock: {hits.size} candidates, arena key \
    {curKey} at{indentExpr ΓE}"
  let mut ordered : Array RelSem.LawRegistry.StepLaw := #[]
  for l in hits do
    let lKey ← try
        withProbeBudget do
          let ci ← getConstInfo l.name
          forallTelescope ci.type fun _ body => do
            let bargs := body.getAppArgs
            if h : bargs.size = 7 then
              let Γi ← whnfCore bargs[5]
              if Γi.isAppOfArity ``RelSem.Seg.Ctx.mk 6 then
                pure (ctlArenaKey? Γi.getAppArgs[0]!)
              else pure none
            else pure none
      catch _ => pure none
    if lKey.isSome && lKey == curKey then
      ordered := ordered.push l
  for l in ordered do
    trace[RelSem.segRun] "tryBlock: probing {l.name}"
    let s0 ← saveState
    let res ← try
        let ci ← getConstInfo l.name
        let (args, _, concl) ← forallMetaTelescope ci.type
        -- REDUCIBLE-ONLY: block facts are canonical-spelled by
        -- construction (`ctlOf (fam … pack0)` everywhere); a
        -- default-transparency fallback would re-open the
        -- ctl-projection grind on same-arena/different-position
        -- candidates (measured at blk5/ar70)
        if ← withProbeBudget (withReducible
            (isDefEqGuarded concl queryE)) then
          -- every binder must be pinned by the context unification
          -- (blocks are premise-free pure-control runs by
          -- construction — a loose binder means no honest fit)
          let argsI ← args.mapM instantiateMVars
          if argsI.any (·.hasExprMVar) then
            trace[RelSem.segRun] "tryBlock: {l.name} has an \
              undetermined binder — skipped"
            pure none
          else
            let concl ← instantiateMVars concl
            -- concl = SegStep gf gs td tid K Γi Γo
            let cargs := concl.getAppArgs
            match ← getNatValue? (← whnf cargs[4]!) with
            | some k =>
              let pf ← instantiateMVars (mkAppN
                (mkConst l.name (ci.levelParams.map .param)) argsI)
              pure (some { pf, delta := cargs[6]!, n := k
                : BuiltLink })
            | none => pure none
        else pure none
      catch ex =>
        trace[RelSem.segRun] "tryBlock: {l.name} failed: \
          {ex.toMessageData}"
        pure none
    match res with
    | some b =>
      trace[RelSem.segRun] "tryBlock: consumed {l.name} ({b.n} rounds)"
      return some b
    | none => s0.restore
  return none

/-! ## PERF-2 mechanism C: THE MINT PATH (V3a probe, 2026-08-28).

    Walk rounds with NO generated per-round supply: at the current
    context, the stepper (i) kernel-computes the step DISCOVERY at
    the program-blind state family `stateAt c` over an OPEN pack
    (the `seg_discover` device — `Lean.Kernel.whnf`, re-verified by
    the kernel at declaration add), (ii) classifies the offered
    step's CONSTRUCTOR, and (iii) instantiates the once-proved
    construct characterization (`cstep_tau`/`cstep_eval`/
    `cstep_rs_tau`, RelSem/CStep.lean — the derived relational
    presentation of the interpreter, functional-big-step lineage)
    with the eval payload discharged through the per-construct
    crossings (`stub_defined`, `runEU_aux2_sym`/`_ctor2`) at the
    walk's owned env cells. Per-program content = the pinned Core
    term inside the control image; nothing else. Classes OUTSIDE the
    probed set (births, loads, guards at path conditions, terminals)
    fall back LOUDLY to the registered supply — committed choice
    throughout; every unkeyed shape is a thrown frontier, never an
    iteration. -/




/-- Decompose a term that kernel-computes to
    `Result (Defined z, st')`; returns `(z, st', rebuiltRhs)`. -/
private def resultParts? (e : Expr) : MetaM (Option (Expr × Expr × Expr)) := do
  let some r ← kwhnf? e | return none
  unless r.isAppOfArity ``exceptM.Result 3 do return none
  let some pr ← kwhnf? r.appArg! | return none
  unless pr.isAppOfArity ``Prod.mk 4 do return none
  let z0 := pr.getAppArgs[2]!
  let st' := pr.getAppArgs[3]!
  let some zd ← kwhnf? z0 | return none
  unless zd.isAppOfArity ``t0.Defined 2 do return none
  let pr' := mkApp2 pr.appFn!.appFn! zd st'
  return some (zd.appArg!, st', mkApp r.appFn! pr')

/-- Solve one leaf-lemma premise: a provided cell fact, or a
    kernel-computable ground equation (RHS metas assigned from the
    kernel result; certificate = hinted refl the kernel re-checks). -/
private def mintSolvePremise (cellFVars : Array Expr) (ty : Expr) :
    MetaM (Option Expr) := do
  for h in cellFVars do
    if ← withProbeBudget (isDefEqGuarded (← inferType h) ty) then
      return some h
  if let some (_, lhs, rhs) := ty.eq? then
    if let some r ← kwhnf? lhs then
      if ← withProbeBudget (isDefEqGuarded rhs r) then
        return some (← mkLhsRflHint lhs (← instantiateMVars rhs))
  return none

/-- Apply a leaf crossing lemma (`lem : … → lhsPat = rhsPat`) at
    `lhs`; premises via `mintSolvePremise`. Returns `(rhs, pf)`. -/
private def applyLemmaCross (lem : Name) (cellFVars : Array Expr)
    (lhs : Expr) : MetaM (Expr × Expr) := do
  let ci ← getConstInfo lem
  let (ms, _, cc) ← forallMetaTelescope ci.type
  let some (_, lp, rp) := cc.eq?
    | throwError "mint: crossing lemma {lem} is not an equation"
  unless ← withProbeBudget (isDefEq lp lhs) do
    throwError "mint: {lem} does not match the leaf:{indentExpr lhs}"
  for m in ms do
    let m ← instantiateMVars m
    if m.isMVar then
      let mty ← instantiateMVars (← m.mvarId!.getType)
      unless (← inferType mty).isProp do continue
      let some pf ← mintSolvePremise cellFVars mty
        | throwError "mint: {lem} premise has no source:{indentExpr mty}"
      unless ← isDefEq m pf do
        throwError "mint: {lem} premise assignment failed"
  let pf := mkAppN (mkConst lem (ci.levelParams.map .param))
    (← ms.mapM instantiateMVars)
  return (← instantiateMVars rp, pf)

/-! V3a-continuation (2026-08-28): the DEEP KERNEL PIN + the one-step
    leaf builders for env-consulting call/case payloads whose
    POST-SUBSTITUTION remainder is ground (the m1 arm classes:
    `run ret(conv_loaded_int(sym))`, `pure(case syms of … ground)`).
    Shape: `runEU_aux2_step_then` (the one-step-then-rest skeleton,
    RelSem/CStep.lean) with the step by the registered `se_*`
    construct law at the walk's cell facts and every ground side
    condition kernel-pinned (`seg_discover`'s device: hinted rfl the
    kernel re-checks at declaration add; no ofReduce*). Committed
    choice throughout — an unkeyed element/head is a thrown frontier,
    and a sym-carrying remainder (T5's symbolic rets) refuses the
    kernel and falls back loudly. -/



/-- The Prop-typed premise holes of a telescoped application, in
    declaration order. -/
private def propHoles (ms : Array Expr) : MetaM (Array Expr) := do
  let mut props : Array Expr := #[]
  for m in ms do
    let m ← instantiateMVars m
    if m.isMVar then
      if (← inferType (← instantiateMVars (← m.mvarId!.getType))).isProp
      then props := props.push m
  return props

/-- Chase a list-valued term to its cons/nil spine (committed unfolds
    through `List.map`-style converter wrappers). -/
private def chaseListSpine (e0 : Expr) : MetaM Expr := do
  let mut cur ← whnfCore e0
  let mut fuel := 24
  while fuel > 0 && !(cur.isAppOfArity ``List.cons 3)
      && !(cur.isAppOfArity ``List.nil 1) do
    unless cur.getAppFn.isConst do break
    let some nxt ← withProbeBudget (Meta.unfoldDefinition? cur) | break
    cur ← whnfCore nxt
    fuel := fuel - 1
  return cur

mutual

/-- Build a proof of a `step_eval_pexpr… pe = Result (Defined ?pe')`
    premise, dispatched by the (chased) payload head: closed payloads
    kernel-pin; `PEsym` crosses by `se_sym_hit` at a cell fact;
    `PEctor Ctuple` by `se_ctor_tuple` over the element chain;
    `PEcase` by `se_case_sel` (scrutinee recursively, selection
    kernel-pinned); `PEcall` by `se_call` (argument chain + ground
    inline). -/
private partial def buildSeStep (cellFVars : Array Expr) (m : Expr) :
    MetaM Unit := do
  let ty ← instantiateMVars (← m.mvarId!.getType)
  let some (_, lhs, _) := ty.eq?
    | throwError "mint: se-step premise is not an equation"
  -- closed payload: try the kernel first (observing? restores state
  -- on failure — a partial pin never leaks)
  if (← observing? (kpinEqPremise m)).isSome then
    return
  let lhsW ← whnfCore lhs
  -- the payload = the last pexpr-valued argument
  let mut pe? : Option Expr := none
  for a in lhsW.getAppArgs.reverse do
    if pe?.isNone then
      let aTy ← whnf (← inferType a)
      if aTy.isAppOf ``generic_pexpr then pe? := some a
  let some pe0 := pe?
    | throwError "mint: se-step has no pexpr payload:{indentExpr lhsW}"
  -- chase converter wrappers to the Pexpr constructor
  let mut pe ← whnfCore pe0
  let mut peFuel := 12
  while peFuel > 0 && !pe.isAppOf ``Pexpr do
    unless pe.getAppFn.isConst do break
    let some nxt ← withProbeBudget (Meta.unfoldDefinition? pe) | break
    pe ← whnfCore nxt
    peFuel := peFuel - 1
  unless pe.isAppOf ``Pexpr do
    throwError "mint: se-step payload is not a Pexpr ctor \
      (head {pe.getAppFn})"
  let payload ← whnfCore pe.getAppArgs.back!
  let lem ←
    if payload.isAppOf ``PEsym then pure ``RelSem.Kit.se_sym_hit
    else if payload.isAppOf ``PEctor then pure ``RelSem.Kit.se_ctor_tuple
    else if payload.isAppOf ``PEcase then pure ``RelSem.Kit.se_case_sel
    else if payload.isAppOf ``PEcall then pure ``RelSem.Kit.se_call
    else throwError "mint: unkeyed se-step payload (head \
      {payload.getAppFn}) — outside the construct set"
  let ci ← getConstInfo lem
  let (ms, _, cc) ← forallMetaTelescope ci.type
  let some (_, cl, _) := cc.eq? | throwError "mint: {lem} shape"
  unless ← withProbeBudget (isDefEq cl lhs) do
    throwError "mint: {lem} does not match the se-step:{indentExpr lhs}"
  let props ← propHoles ms
  if lem == ``RelSem.Kit.se_sym_hit then
    -- hext (ground), hlk (cell fact)
    unless props.size == 2 do throwError "mint: se_sym_hit premises"
    kpinEqPremise props[0]!
    let hlkTy ← instantiateMVars (← props[1]!.mvarId!.getType)
    let some pf ← mintSolvePremise cellFVars hlkTy
      | throwError "mint: sym cell fact has no source:{indentExpr hlkTy}"
    unless ← isDefEq props[1]! pf do
      throwError "mint: sym cell fact assignment failed"
  else if lem == ``RelSem.Kit.se_ctor_tuple then
    -- hmap (chain), hvals (ground)
    unless props.size == 2 do throwError "mint: se_ctor_tuple premises"
    buildEumapChain cellFVars props[0]!
    kpinEqPremise props[1]!
  else if lem == ``RelSem.Kit.se_case_sel then
    -- hscrut (recursive se-step), hsel (ground)
    unless props.size == 2 do throwError "mint: se_case_sel premises"
    buildSeStep cellFVars props[0]!
    kpinEqPremise props[1]!
  else
    -- se_call: hmap (chain), hvals, hcall, hpull (ground)
    unless props.size == 4 do throwError "mint: se_call premises"
    buildEumapChain cellFVars props[0]!
    kpinEqPremise props[1]!
    kpinEqPremise props[2]!
    kpinEqPremise props[3]!
  let pf ← instantiateMVars (mkAppN
    (mkConst lem (ci.levelParams.map .param)) ms)
  unless ← isDefEq m pf do
    throwError "mint: se-step assignment failed at {lem}"

/-- Build the element chain of an `exception_undef_mapM` premise:
    closed elements kernel-pin, sym elements cross by `se_sym_hit`
    (via `buildSeStep`), assembled by `eumapM_cons`/`eumapM_nil`. -/
private partial def buildEumapChain (cellFVars : Array Expr)
    (m : Expr) : MetaM Unit := do
  let ty ← instantiateMVars (← m.mvarId!.getType)
  let some (_, lhs, _) := ty.eq?
    | throwError "mint: eumapM premise is not an equation"
  let lhsW ← whnfCore lhs
  unless lhsW.isAppOf ``exception_undef_mapM do
    throwError "mint: not an eumapM premise:{indentExpr lhsW}"
  let args := lhsW.getAppArgs
  let f := args[args.size - 2]!
  let pes := args[args.size - 1]!
  let spine ← chaseListSpine pes
  if spine.isAppOfArity ``List.nil 1 then
    let ci ← getConstInfo ``RelSem.Kit.eumapM_nil
    let (ms, _, cc) ← forallMetaTelescope ci.type
    unless ← withProbeBudget (isDefEq cc ty) do
      throwError "mint: eumapM_nil does not close the chain"
    let pf ← instantiateMVars (mkAppN
      (mkConst ``RelSem.Kit.eumapM_nil (ci.levelParams.map .param)) ms)
    unless ← isDefEq m pf do
      throwError "mint: eumapM_nil assignment failed"
  else if spine.isAppOfArity ``List.cons 3 then
    let ci ← getConstInfo ``RelSem.Kit.eumapM_cons
    let (ms, _, cc) ← forallMetaTelescope ci.type
    let some (_, ccl, _) := cc.eq? | throwError "mint: eumapM_cons shape"
    unless ← withProbeBudget (isDefEq ccl lhs) do
      throwError "mint: eumapM_cons does not match:{indentExpr lhs}"
    let props ← propHoles ms
    unless props.size == 2 do throwError "mint: eumapM_cons premises"
    buildSeStep cellFVars props[0]!
    buildEumapChain cellFVars props[1]!
    let pf ← instantiateMVars (mkAppN
      (mkConst ``RelSem.Kit.eumapM_cons (ci.levelParams.map .param)) ms)
    unless ← isDefEq m pf do
      throwError "mint: eumapM_cons assignment failed"
  else
    throwError "mint: eumapM list did not reach a literal spine:\
      {indentExpr spine}"

end

/-- The step-then leaf (`PEcall`/`PEcase` payloads): ONE registered
    `se_*` step at the cell facts, then the REST of the aux2 loop
    kernel-pinned at the (now ground) remainder. Returns (rhs, pf)
    with `pf : lhs = rhs`, `rhs = runEU (Result (Defined z)) st`. -/
private def mintStepThenLeaf (cellFVars : Array Expr) (lhsW : Expr) :
    MetaM (Expr × Expr) := do
  let ci ← getConstInfo ``RelSem.Seg.runEU_aux2_step_then
  let (ms, _, cc) ← forallMetaTelescope ci.type
  let some (_, lp, rp) := cc.eq?
    | throwError "mint: step_then shape"
  unless ← withProbeBudget (isDefEq lp lhsW) do
    throwError "mint: step_then does not match the leaf:{indentExpr lhsW}"
  let props ← propHoles ms
  unless props.size == 4 do
    throwError "mint: step_then premise count {props.size}"
  -- hspine (ground), hstep (se law), hnv (ground), hrest (ground —
  -- the committed boundary: a sym-carrying remainder throws here)
  kpinEqPremise props[0]!
  buildSeStep cellFVars props[1]!
  kpinEqPremise props[2]!
  kpinEqPremise props[3]!
  let pf ← instantiateMVars (mkAppN
    (mkConst ``RelSem.Seg.runEU_aux2_step_then
      (ci.levelParams.map .param)) ms)
  return (← instantiateMVars rp, pf)

/-! THE EVAL CROSSING: prove `lhs = Result (Defined z, st')` for a
    monadic step applied at a run state, by (a) whole-term kernel
    computation where the step is closed at the fragments (the
    pure-eval class — binops, ctor packs at literal operands), or
    (b) committed structural descent: `stExceptUndef_bind` via
    `stub_defined`, eval entries unfolded to their `runEU (aux2 …)`
    spelling (the `seg_peels` head discipline), and the ONE
    env-consulting leaf (`PEsym`/`Ctuple`-of-syms) crossed by the
    registered per-construct lemma at an owned cell fact. Cheap
    failure everywhere (Lithium's opacity-bounded-failure principle);
    an unkeyed head is a thrown frontier. -/

/-- Payload SAFETY for kernel evaluation (committed classification —
    the r127 lesson at the mint path): a pexpr may be handed to
    `Lean.Kernel.whnf` only when every `PE*` constructor in it lies in
    the safe set — constructs whose evaluation at symbolic data never
    cases on that data (sym reads, values, ctor packs, plain ops).
    Guard chains, conv/call forms, case-splits at symbolic data would
    send the UNBOUNDED, UNINTERRUPTIBLE kernel evaluator into a
    runaway (measured: 16G OOM at P01's verdict round). -/
private def peSafePayload (e : Expr) : Bool :=
  (e.find? (fun s =>
    match s.getAppFn.constName? with
    | some n =>
      let short := n.componentsRev.head!.toString
      short.startsWith "PE"
        && !(["PEsym", "PEval", "PEctor", "PEop"].contains short)
    | none => false)).isNone

/-- The unsafe PE* constructor names occurring in a payload (loud-
    fallback diagnostics: the full entry term renders the whole state
    and is useless in a message; the offender list is the datum). -/
private partial def peUnsafeHeads (e : Expr) (acc : Array Name := #[]) :
    Array Name :=
  let acc := match e.getAppFn.constName? with
    | some n =>
      let short := n.componentsRev.head!.toString
      if short.startsWith "PE"
          && !(["PEsym", "PEval", "PEctor", "PEop"].contains short)
          && !acc.contains n then
        acc.push n
      else acc
    | none => acc
  let acc := e.getAppArgs.foldl (fun a s => peUnsafeHeads s a) acc
  match e with
  | .lam _ _ b _ | .forallE _ _ b _ => peUnsafeHeads b acc
  | .letE _ _ v b _ => peUnsafeHeads b (peUnsafeHeads v acc)
  | .mdata _ b | .proj _ _ b => peUnsafeHeads b acc
  | _ => acc

/-- The eval-entry constants (a pexpr argument rides them into the
    evaluator). -/
private def evalEntryConsts : List Name :=
  [``full_eval_pexpr, ``full_eval_pexpr_lemFuel, ``E.eval_pexpr20,
   ``eval_pexpr_aux2, ``eval_pexpr_aux2_lemFuel]

/-- The pexpr argument of an eval-entry application, if any. -/
private def evalPexprArg? (e : Expr) : MetaM (Option Expr) := do
  for a in e.getAppArgs.reverse do
    let aW ← whnfCore a
    if aW.isAppOf ``Pexpr then return some aW
  return none

/-- Deep AST normalization: per-node KERNEL whnf with constructor-
    head recursion (the extraction probe's `normAst` device, V3a
    continuation). Program syntax as DATA — converter residuals
    (`convert_pexpr` match nests) reduce to constructor spines; the
    evaluator is never applied, so the fuel-runaway guard is
    untouched. Bounded by payload size; the kernel computes these
    normal forms in milliseconds where the elaborator's whnf is the
    measured explosion. -/
private partial def chaseAstDeep (e : Expr) (fuel : Nat := 64) :
    MetaM Expr := do
  match fuel with
  | 0 => return e
  | fuel + 1 =>
    let e' ← match ← kwhnf? e with
      | some r => pure r
      | none => pure e
    let isCtorHead ←
      if e'.getAppFn.isConst then do
        pure (match (← getEnv).find? e'.getAppFn.constName! with
          | some (.ctorInfo _) => true
          | _ => false)
      else pure false
    if isCtorHead then
      let args ← e'.getAppArgs.mapM (chaseAstDeep · fuel)
      return mkAppN e'.getAppFn args
    else
      return e'

/-- ExceptM-level crossing (V3a continuation — the save/run label
    machinery): prove `e = rhs` for an `exceptM`-valued computation
    whose leaves are ground label lookups (kernel-pinned) and
    env-reading pexpr evals (the `aux2_sym_hit` law at the walk's
    cell facts). Matcher residuals step by CONGRUENCE on the
    discriminant (the read is propositional, not defeq). Committed
    choice; unkeyed heads throw. -/
private partial def crossExceptM (cellFVars : Array Expr) (e : Expr)
    (fuel : Nat := 96) : MetaM (Expr × Expr) := do
  match fuel with
  | 0 => throwError "mint: exceptM-crossing depth bound exceeded"
  | fuel + 1 =>
  let eW ← whnfCore e
  let fn := eW.getAppFn
  -- ground leaf: kernel to a Result-headed constructor
  if !(fn.isConstOf ``except_bind) then
    if let some r ← kwhnf? eW then
      if r.isAppOfArity ``exceptM.Result 3 then
        -- kernel-normalize one level in (the t0 wrapper)
        let some inner ← kwhnf? r.appArg! | pure ()
        let r := mkApp r.appFn! ((← kwhnf? r.appArg!).getD r.appArg!)
        let _ := inner
        return (r, ← mkLhsRflHint e r)
  if fn.isConstOf ``except_bind then
    let args := eW.getAppArgs
    unless args.size ≥ 2 do
      throwError "mint: except_bind arity at{indentExpr eW}"
    let m := args[args.size - 2]!
    let k := args[args.size - 1]!
    let (rhs1, pf1) ← crossExceptM cellFVars m fuel
    let reb := mkAppN fn ((args.set! (args.size - 2) rhs1))
    let lam ← withLocalDeclD `x (← inferType m) fun x =>
      mkLambdaFVars #[x] (mkAppN fn (args.set! (args.size - 2) x))
    let pfC ← mkCongrArg lam pf1
    let pfC ← mkExpectedTypeHint pfC (← mkEq eW reb)
    -- force the bind's own reduction at the Result (whnfCore does not
    -- δ-unfold except_bind — the measured self-loop)
    let mut rebR ← whnfCore reb
    if rebR.getAppFn.isConstOf ``except_bind then
      let some u ← withProbeBudget (Meta.unfoldDefinition? rebR)
        | throwError "mint: except_bind did not unfold"
      rebR ← whnfCore u
    let (rhs2, pf2) ← crossExceptM cellFVars rebR fuel
    return (rhs2, ← mkEqTrans pfC pf2)
  if fn.isConst
      && [``eval_pexpr_aux2, ``eval_pexpr_aux2_lemFuel].contains
        fn.constName! then
    -- chase the payload; PEsym crosses by the aux2 sym-hit law
    let mut pe ← whnfCore eW.getAppArgs.back!
    let mut peFuel := 12
    while peFuel > 0 && !pe.isAppOf ``Pexpr do
      unless pe.getAppFn.isConst do break
      let some nxt ← withProbeBudget (Meta.unfoldDefinition? pe) | break
      pe ← whnfCore nxt
      peFuel := peFuel - 1
    unless pe.isAppOf ``Pexpr do
      throwError "mint: exceptM eval payload not a Pexpr ctor"
    let payload ← whnfCore pe.getAppArgs.back!
    unless payload.isAppOf ``PEsym do
      throwError "mint: exceptM eval leaf (payload head \
        {payload.getAppFn}) — outside the construct set"
    let ci ← getConstInfo ``RelSem.Kit.aux2_sym_hit
    let (ms, _, cc) ← forallMetaTelescope ci.type
    let some (_, lp, rp) := cc.eq?
      | throwError "mint: aux2_sym_hit shape"
    unless ← withProbeBudget (isDefEq lp eW) do
      throwError "mint: aux2_sym_hit does not match:{indentExpr eW}"
    for m in ms do
      let m ← instantiateMVars m
      if m.isMVar then
        let mty ← instantiateMVars (← m.mvarId!.getType)
        unless (← inferType mty).isProp do continue
        let some pf ← mintSolvePremise cellFVars mty
          | throwError "mint: aux2_sym_hit premise has no source:\
              {indentExpr mty}"
        unless ← isDefEq m pf do
          throwError "mint: aux2_sym_hit premise assignment failed"
    let pf := mkAppN (mkConst ``RelSem.Kit.aux2_sym_hit
      (ci.levelParams.map .param)) (← ms.mapM instantiateMVars)
    let pf ← mkExpectedTypeHint (← instantiateMVars pf)
      (← mkEq e (← instantiateMVars rp))
    return (← instantiateMVars rp, pf)
  if fn.isConst then
    if let some mi ← Meta.getMatcherInfo? fn.constName! then
      let args := eW.getAppArgs
      let start := mi.numParams + 1
      let mut di : Option Nat := none
      for i in [start : start + mi.numDiscrs] do
        if _h : i < args.size then
          if di.isNone then
            let dW ← whnfCore args[i]!
            unless dW.getAppFn.isConstOf ``exceptM.Result do
              di := some i
      match di with
      | some i =>
        let (rhsD, pfD) ← crossExceptM cellFVars args[i]! fuel
        let reb := mkAppN fn (args.set! i rhsD)
        let lam ← withLocalDeclD `x (← inferType args[i]!) fun x =>
          mkLambdaFVars #[x] (mkAppN fn (args.set! i x))
        let pfC ← mkCongrArg lam pfD
        let pfC ← mkExpectedTypeHint pfC (← mkEq eW reb)
        let (rhs2, pf2) ← crossExceptM cellFVars reb fuel
        return (rhs2, ← mkEqTrans pfC pf2)
      | none =>
        match ← Meta.reduceMatcher? eW with
        | .reduced nxt => return ← crossExceptM cellFVars nxt fuel
        | _ => throwError "mint: exceptM matcher stuck:{indentExpr eW}"
    let some nxt ← withProbeBudget (Meta.unfoldDefinition? eW)
      | throwError "mint: unkeyed exceptM head {fn} — outside the \
          construct set"
    return ← crossExceptM cellFVars nxt fuel
  throwError "mint: non-constant exceptM head at{indentExpr eW}"

private partial def crossToResult (cellFVars : Array Expr) (lhs : Expr)
    (fuel : Nat := 32) : MetaM (Expr × Expr × Expr × Expr) := do
  match fuel with
  | 0 => throwError "mint: eval-crossing depth bound exceeded"
  | fuel + 1 =>
  let lhsW ← whnfCore lhs
  let fn := lhsW.getAppFn
  -- committed kernel-evaluation guard: bind heads always DESCEND
  -- (each inner unit gets its own classification); EVAL-ENTRY heads
  -- go to the kernel only when their REDEX's PE* constructors lie in
  -- the safe set (program syntax carried as DATA — result values,
  -- read continuations — is harmless: only the evaluator applied to
  -- a guard/conv/case redex can run the fuel loop away)
  let isBind := fn.isConstOf ``stExceptUndef_bind
  let isEntry := fn.isConst && evalEntryConsts.contains fn.constName!
  let mut payload? : Option Expr := none
  let safe ←
    if isEntry then do
      -- the redex = the last pexpr-TYPED argument (spellings vary:
      -- bare `Pexpr …` or `convert_pexpr …`; the PE* scan sees
      -- through both)
      let mut pe? : Option Expr := none
      for a in lhsW.getAppArgs.reverse do
        if pe?.isNone then
          let aTy ← whnf (← inferType a)
          if aTy.isAppOf ``generic_pexpr then pe? := some a
      payload? := (← pe?.mapM (chaseAstDeep ·))
      match payload? with
      | some pe =>
        -- V3a-continuation (2026-08-28), the GROUND-REDEX prong of
        -- the kernel-evaluation guard: the banked doctrine forbids
        -- kernel-evaluating a guard/conv/case redex AT SYMBOLIC DATA
        -- — and symbolic data in a redex means FREE VARIABLES (the
        -- walk's Int fvars ride in as `PEval (OVinteger … x)`) or
        -- ENV/MEM consults at the open pack (`PEsym`/`PEmemop`/
        -- `PEcfunction` — a stuck lookup inside the fuel loop is the
        -- measured 16G expansion). A payload that is CLOSED and
        -- consult-free evaluates to completion on ground data (the
        -- PERF-1 "literal value → eval skeleton" regime): the m1
        -- arms' post-branch conv/guard chains at literals. The
        -- syntactic PE* scan stays the rule otherwise (fail-closed:
        -- a converter residual that hides constructors classifies
        -- unsafe, never the reverse).
        -- pe is DEEP-NORMALIZED: the scans see actual program
        -- syntax, never converter-residual match nests (the measured
        -- all-ctors false positive, twice)
        let consults := (pe.find? (fun s =>
          match s.getAppFn.constName? with
          | some n =>
            ["PEsym", "PEmemop", "PEcfunction"].contains
              n.componentsRev.head!.toString
          | none => false)).isSome
        pure (peSafePayload pe
          || (!pe.hasFVar && !pe.hasExprMVar && !consults))
      | none => pure false
    else pure true
  if !isBind && safe then
    if let some (z, st', rhs) ← resultParts? lhsW then
      return (z, st', rhs, ← mkLhsRflHint lhs rhs)
  if isEntry && !safe then
    -- an eval entry whose payload is outside the kernel-safe set:
    -- NEVER kernel-evaluate it (the r127/fuel-runaway guard), and
    -- NEVER descend it through elaborator unfolds either (measured
    -- V3a-continuation: the committed-unfold descent at a converter-
    -- residual payload grinds >10 min where the throw-and-stop walk
    -- is 14 s). Instead: DIRECT LEAF DISPATCH at the entry spelling —
    -- chase the payload to its Pexpr constructor (the residual
    -- reduces there), commit on the head, and apply the registered
    -- leaf lemma/builder whose LHS pattern unifies through the
    -- entry's own unfolding with a concrete target. Unkeyed heads
    -- (guard/conv chains at symbolic data) throw the classification
    -- error with the offender list — the supply/anchor fallback.
    -- CLASSIFY FIRST (V3a-continuation, second measurement): the
    -- payload chase + head keying is cheap and entry-independent, so
    -- unkeyed payloads (guard/conv chains) throw HERE — before any
    -- full_eval unfold. (The doomed guard-round mint attempt on the
    -- post-branch spelling OOM'd inside that unfold; the outcome was
    -- always going to be the supply fallback.)
    let some pe := payload?
      | throwError "mint: eval entry has no payload:{indentExpr lhsW}"
    -- payload? is deep-normalized (chaseAstDeep at classification)
    unless pe.isAppOf ``Pexpr do
      throwError "mint: eval payload did not chase to a Pexpr ctor \
        (head {pe.getAppFn}) — outside the construct set"
    let payload ← whnfCore pe.getAppArgs.back!
    unless payload.isAppOf ``PEsym || payload.isAppOf ``PEctor
        || payload.isAppOf ``PEcall || payload.isAppOf ``PEcase do
      throwError "mint: eval payload outside the construct set \
        (guard/conv/case class; payload head {payload.getAppFn}; \
        offenders: {(peUnsafeHeads pe).toList}) — supply fallback"
    if fn.constName! == ``full_eval_pexpr
        || fn.constName! == ``full_eval_pexpr_lemFuel then
      -- keyed payload behind a full_eval entry: expose the underlying
      -- bind (ONE committed unfold; the bind branch then reaches the
      -- aux2 leaf) — the seg_peels head discipline
      let some nxt ← withProbeBudget (Meta.unfoldDefinition? lhsW)
        | throwError "mint: full_eval entry did not unfold"
      return ← crossToResult cellFVars nxt fuel
    let (rhs, pf) ←
      if payload.isAppOf ``PEsym then
        applyLemmaCross ``RelSem.Seg.runEU_aux2_sym cellFVars lhsW
      else if payload.isAppOf ``PEctor then
        applyLemmaCross ``RelSem.Seg.runEU_aux2_ctor2 cellFVars lhsW
      else
        mintStepThenLeaf cellFVars lhsW
    let (z, st', rhs2, pf2) ← crossToResult cellFVars rhs fuel
    return (z, st', rhs2, ← mkEqTrans pf pf2)
  if isBind then
    let args := lhsW.getAppArgs
    unless args.size ≥ 3 do
      throwError "mint: bind arity at{indentExpr lhsW}"
    let m := args[args.size - 3]!
    let k := args[args.size - 2]!
    let st := args[args.size - 1]!
    let (z1, st1, _, pf1) ← crossToResult cellFVars (mkApp m st) fuel
    -- stub_defined's continuation implicit `f` does not occur in its
    -- premise, so it must be pinned by unifying the CONCLUSION (an
    -- mkAppM would leave it a metavariable — measured probe failure)
    let pfB ← do
      let ci ← getConstInfo ``RelSem.Kit.stub_defined
      let (ms, _, cc) ← forallMetaTelescope ci.type
      let some (_, lp, _) := cc.eq?
        | throwError "mint: stub_defined shape"
      unless ← withProbeBudget (isDefEq lp lhsW) do
        throwError "mint: stub_defined LHS mismatch at{indentExpr lhsW}"
      for mm in ms do
        let mm ← instantiateMVars mm
        if mm.isMVar then
          let mty ← instantiateMVars (← mm.mvarId!.getType)
          unless (← inferType mty).isProp do continue
          unless ← isDefEq mm pf1 do
            throwError "mint: stub_defined premise mismatch"
      instantiateMVars (mkAppN
        (mkConst ``RelSem.Kit.stub_defined (ci.levelParams.map .param))
        (← ms.mapM instantiateMVars))
    let (z2, st2, rhs2, pf2) ← crossToResult cellFVars (mkApp2 k z1 st1) fuel
    -- pfB : bind m k st = k z1 st1; pf2 : k z1 st1 = R — the types
    -- meet definitionally (whnfCore deltas are defeq; the final
    -- consumer re-hints)
    return (z2, st2, rhs2, ← mkEqTrans pfB pf2)
  else if fn.isConstOf ``runEU then
    let args := lhsW.getAppArgs
    unless args.size ≥ 2 do
      throwError "mint: runEU arity at{indentExpr lhsW}"
    let M ← whnfCore args[args.size - 2]!
    let pe0 ←
      if M.isAppOf ``eval_pexpr_aux2 || M.isAppOf ``eval_pexpr_aux2_lemFuel
      then whnfCore M.getAppArgs.back!
      else throwError "mint: runEU inner is not an aux2 entry \
        (head {M.getAppFn})"
    -- chase annotation-conversion wrappers (convert_pexpr spellings)
    -- to the Pexpr constructor
    let mut pe := pe0
    let mut peFuel := 12
    while peFuel > 0 && !pe.isAppOf ``Pexpr do
      unless pe.getAppFn.isConst do break
      let some nxt ← withProbeBudget (Meta.unfoldDefinition? pe)
        | break
      pe ← whnfCore nxt
      peFuel := peFuel - 1
    unless pe.isAppOf ``Pexpr do
      throwError "mint: aux2 argument is not a Pexpr ctor \
        (head {pe.getAppFn})"
    let payload ← whnfCore pe.getAppArgs.back!
    if payload.isAppOf ``PEcall || payload.isAppOf ``PEcase then
      -- V3a-continuation: the one-step-then-ground-rest leaf
      -- (`run ret(conv(sym))` / `pure(case syms of … ground)`)
      let (rhs, pf) ← mintStepThenLeaf cellFVars lhsW
      let (z, st', rhs2, pf2) ← crossToResult cellFVars rhs fuel
      return (z, st', rhs2, ← mkEqTrans pf pf2)
    let lem ←
      if payload.isAppOf ``PEsym then
        pure ``RelSem.Seg.runEU_aux2_sym
      else if payload.isAppOf ``PEctor then
        pure ``RelSem.Seg.runEU_aux2_ctor2
      else
        throwError "mint: unkeyed eval leaf (payload head \
          {payload.getAppFn}) — outside the construct set"
    let (rhs, pf) ← applyLemmaCross lem cellFVars lhsW
    let (z, st', rhs2, pf2) ← crossToResult cellFVars rhs fuel
    return (z, st', rhs2, ← mkEqTrans pf pf2)
  else if fn.isConst then
    -- committed unfold toward a keyed head (the seg_peels discipline)
    match ← withProbeBudget (Meta.unfoldDefinition? lhsW) with
    | some nxt => crossToResult cellFVars nxt fuel
    | none =>
      -- matcher residual (V3a continuation: the save/run label
      -- machinery surfaces `except_bind.match_1`-class matchers whose
      -- discriminants are GROUND label lookups — kernel-force the
      -- discriminants, then reduce the matcher; a genuinely stuck
      -- discriminant stays a loud frontier)
      let some mi ← Meta.getMatcherInfo? fn.constName!
        | throwError "mint: unkeyed head {fn} — outside the construct \
            set:{indentExpr lhsW}"
      let nxt? ← do
        match ← Meta.reduceMatcher? lhsW with
        | .reduced nxt => pure (some nxt)
        | _ =>
          let mut args := lhsW.getAppArgs
          let start := mi.numParams + 1
          for i in [start : start + mi.numDiscrs] do
            if h : i < args.size then
              if let some d ← kwhnf? args[i] then
                args := args.set! i d
          let lhs2 := mkAppN fn args
          match ← Meta.reduceMatcher? lhs2 with
          | .reduced nxt => pure (some nxt)
          | _ => pure none
      match nxt? with
      | some nxt => crossToResult cellFVars nxt fuel
      | none =>
        -- propositional discriminant (an env-reading label-arg eval):
        -- cross it in the except monad and step the matcher by
        -- congruence (V3a continuation, the save/run class)
        let args := lhsW.getAppArgs
        let start := mi.numParams + 1
        let mut di : Option Nat := none
        for i in [start : start + mi.numDiscrs] do
          if _h : i < args.size then
            if di.isNone then
              let dW ← whnfCore args[i]!
              unless dW.getAppFn.isConst
                  && (dW.getAppFn.constName!.componentsRev.head!
                    |>.toString.startsWith "Result") do
                di := some i
        let some i := di
          | throwError "mint: matcher {fn} stuck (no crossable \
              discriminant):{indentExpr lhsW}"
        let (rhsD, pfD) ← crossExceptM cellFVars args[i]!
        let reb := mkAppN fn (args.set! i rhsD)
        let lam ← withLocalDeclD `x (← inferType args[i]!) fun x =>
          mkLambdaFVars #[x] (mkAppN fn (args.set! i x))
        let pfC ← mkCongrArg lam pfD
        let pfC ← mkExpectedTypeHint pfC (← mkEq lhsW reb)
        let (z, st', rhs2, pf2) ← crossToResult cellFVars reb fuel
        return (z, st', rhs2, ← mkEqTrans pfC pf2)
  else
    throwError "mint: non-constant head at{indentExpr lhsW}"

/-- Collect the (sym, value) pairs of the context's env list. -/
private partial def collectEnvPairs (envE : Expr)
    (acc : Array (Expr × Expr) := #[]) :
    MetaM (Array (Expr × Expr)) := do
  let l ← whnf envE
  if l.isAppOfArity ``List.cons 3 then
    let pair ← whnf l.getAppArgs[1]!
    if pair.isAppOfArity ``Prod.mk 4 then
      collectEnvPairs l.getAppArgs[2]!
        (acc.push (pair.getAppArgs[2]!, pair.getAppArgs[3]!))
    else
      throwError "mint: env entry is not a literal pair"
  else if l.isAppOfArity ``List.nil 1 then
    return acc
  else
    throwError "mint: env list did not reduce to a literal"

private inductive MintOut where
  | link (b : BuiltLink)
  | terminal
  | skip (why : MessageData)
  deriving Inhabited

/-- Build the link for a MINTED round: pre-pin `famI := stateAt c`
    and the minted successor family, assign the construct proof into
    the link's `happ` slot, dispatch the remaining premises through
    the standard dispatcher (FamShape by rfl, `stateAt_inv` from the
    famInv registry, cell indexes, the control anchor). -/
private def buildMintedLink (gf gs td tid : Expr) (ΓE : Expr)
    (linkC : Name) (famI famO happLam : Expr)
    (birthPins : Array (Expr × Expr) := #[]) : MetaM BuiltLink := do
  let cinfo ← getConstInfo linkC
  let (args, _, concl) ← forallMetaTelescope cinfo.type
  unless concl.isAppOfArity ``RelSem.Seg.SegStep 7 do
    throwError "mint [{linkC}]: link conclusion shape"
  let cargs := concl.getAppArgs
  unless (← isDefEq cargs[0]! gf) && (← isDefEq cargs[1]! gs)
      && (← isDefEq cargs[2]! td) && (← isDefEq cargs[3]! tid) do
    throwError "mint [{linkC}]: instance/program unification failed"
  unless ← isDefEq cargs[5]! ΓE do
    throwError "mint [{linkC}]: entry context does not unify"
  -- pre-pin the birth slots (x/vNew, outermost first, declaration
  -- order — committed choice; the env1-cell y/vy slots are pinned by
  -- the happ unification afterward)
  if !birthPins.isEmpty then
    let mut symSlots : Array Expr := #[]
    let mut valSlots : Array Expr := #[]
    for a in args do
      let a ← instantiateMVars a
      if a.isMVar then
        let aty ← instantiateMVars (← a.mvarId!.getType)
        if aty.isConstOf ``sym then symSlots := symSlots.push a
        else if aty.isConstOf ``value then valSlots := valSlots.push a
    for i in [0:birthPins.size] do
      if h1 : i < symSlots.size then
        unless ← isDefEq symSlots[i] birthPins[i]!.1 do
          throwError "mint [{linkC}]: birth sym pre-pin failed"
      if h2 : i < valSlots.size then
        unless ← isDefEq valSlots[i] birthPins[i]!.2 do
          throwError "mint [{linkC}]: birth value pre-pin failed"
  -- pre-pin the fam slots (declaration order famI, famO)
  let mut famPins := #[famI, famO]
  let mut pinIdx := 0
  for a in args do
    if pinIdx ≥ famPins.size then continue
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      let isFamTy := aty.isArrow &&
        aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack &&
        aty.bindingBody!.isConstOf ``driver_state
      if isFamTy then
        unless ← isDefEq a famPins[pinIdx]! do
          throwError "mint [{linkC}]: fam slot {pinIdx} pre-pin failed"
        pinIdx := pinIdx + 1
  unless pinIdx == 2 do
    throwError "mint [{linkC}]: fam slots not found"
  -- assign happ
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq && body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then
      happIdx := some i
  let some hi := happIdx
    | throwError "mint [{linkC}]: no happ premise"
  unless ← withProbeBudget (isDefEq args[hi]! happLam) do
    throwError "mint [{linkC}]: minted proof does not fit the happ \
      slot:{indentExpr (← instantiateMVars (← inferType args[hi]!))}"
  let pack0 ← mkPack0
  let mut progress := true
  while progress do
    progress := false
    for a in args do
      let a ← instantiateMVars a
      if a.isMVar then
        if ← dispatchPremise linkC pack0 a.mvarId! then
          progress := true
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      throwError "mint [{linkC}]: unfilled premise:\
        {indentExpr (← instantiateMVars (← a.mvarId!.getType))}"
  let concl ← instantiateMVars concl
  let delta := concl.getAppArgs[concl.getAppNumArgs - 1]!
  if delta.hasExprMVar then
    throwError "mint [{linkC}]: successor context still open"
  let pf ← instantiateMVars (mkAppN
    (mkConst linkC (cinfo.levelParams.map .param)) args)
  return { pf, delta, minted := true }


/-- Wrapper constants the field chase may unfold (state-builder
    layers only — data constants like the arena/labeled bases are
    deliberately NOT here, so the chase stops at them). -/
private def chaseWhitelist : List Name :=
  [``RelSem.Seg.stateAt, ``RelSem.Seg.threadAt, ``ctlOf,
   ``RelSem.Kit.dnmsBump, ``eraseEnvs, ``eraseThreadEnv,
   ``update_thread_state, ``update_core_state, ``List.map]

/-- Chase a field term through the state-builder wrappers to a flat
    subterm (whnfCore + committed whitelist unfolds; stops at
    constructors, data constants, fvars). -/
private partial def chaseField (e0 : Expr) (fuel : Nat := 32) :
    MetaM Expr := do
  let mut cur ← whnfCore e0
  let mut fuel := fuel
  while fuel > 0 do
    let fn := cur.getAppFn
    let isSegCtlAux := fn.isConst
      && (fn.constName!.toString.splitOn "segCtl").length > 1
    if fn.isConst
        && (chaseWhitelist.contains fn.constName! || isSegCtlAux) then
      let some nxt ← withProbeBudget (Meta.unfoldDefinition? cur)
        | return cur
      cur ← whnfCore nxt
    else if fn.isConst && cur.getAppNumArgs ≥ 1
        && ((← getEnv).getProjectionFnInfo? fn.constName!).isSome then
      -- a stuck projection: chase its STRUCT argument (the builder
      -- layers live there), rebuild, and reduce again
      let inner ← chaseField cur.appArg! fuel
      if inner == cur.appArg! then return cur
      cur ← whnfCore (mkApp cur.appFn! inner)
    else
      return cur
    fuel := fuel - 1
  return cur

/-- Chase to a specific constructor (record spines; unfolds ANY
    constant head — records only, bounded). -/
private def chaseToCtor (e0 : Expr) (ctor : Name) (arity : Nat)
    (fuel : Nat := 32) : MetaM Expr := do
  let mut cur ← whnfCore e0
  let mut fuel := fuel
  while fuel > 0 && !cur.isAppOfArity ctor arity do
    unless cur.getAppFn.isConst do break
    let some nxt ← withProbeBudget (Meta.unfoldDefinition? cur)
      | break
    cur ← whnfCore nxt
    fuel := fuel - 1
  unless cur.isAppOfArity ctor arity do
    throwError "seg_run compact: could not flatten to {ctor}:\
      {indentExpr e0}"
  return cur

/-- Nat fields (counters/supplies): kernel-evaluate to literals. -/
private def chaseNat (e : Expr) : MetaM Expr := do
  match ← kwhnf? e with
  | some r => pure r
  | none => pure e

/-- Flatten a driver_state CONTROL IMAGE to a record literal (defeq-
    preserving; bounded by program size). -/
private def flattenCtl (e : Expr) : MetaM Expr := do
  let ds ← chaseToCtor e ``driver_state.mk 11
  let mut f := ds.getAppArgs
  -- core_state0
  let cs ← chaseToCtor f[2]! ``core_state.mk 2
  let mut csf := cs.getAppArgs
  -- thread_states: single-thread spine
  let ths ← chaseToCtor csf[0]! ``List.cons 3
  let mut thsA := ths.getAppArgs
  let pair ← chaseToCtor thsA[1]! ``Prod.mk 4
  let mut pairA := pair.getAppArgs
  let inner ← chaseToCtor pairA[3]! ``Prod.mk 4
  let mut innerA := inner.getAppArgs
  let th ← chaseToCtor innerA[3]! ``thread_state.mk 7
  let mut thA := th.getAppArgs
  for i in [0:7] do
    if i == 3 then
      -- the env spine (erased frames)
      thA := thA.set! 3 (← chaseField thA[3]! (fuel := 48))
    else
      thA := thA.set! i (← chaseField thA[i]!)
  innerA := innerA.set! 3 (mkAppN th.getAppFn thA)
  pairA := pairA.set! 2 (← chaseField pairA[2]!)
  pairA := pairA.set! 3 (mkAppN inner.getAppFn innerA)
  thsA := thsA.set! 1 (mkAppN pair.getAppFn pairA)
  thsA := thsA.set! 2 (← chaseField thsA[2]!)
  csf := csf.set! 0 (mkAppN ths.getAppFn thsA)
  csf := csf.set! 1 (← chaseField csf[1]!)
  f := f.set! 2 (mkAppN cs.getAppFn csf)
  -- core_run_state0: supplies to literals, labeled chased-not-expanded
  let crs ← chaseToCtor f[3]! ``core_run_state.mk 5
  let mut crsA := crs.getAppArgs
  for i in [0:4] do
    crsA := crsA.set! i (← chaseNat crsA[i]!)
  crsA := crsA.set! 4 (← chaseField crsA[4]!)
  f := f.set! 3 (mkAppN crs.getAppFn crsA)
  -- the remaining fields
  for i in [0:11] do
    if i == 2 || i == 3 then continue
    if i == 10 then
      f := f.set! i (← chaseNat f[i]!)   -- dr_step_counter
    else
      f := f.set! i (← chaseField f[i]!)
  return mkAppN ds.getAppFn f

/-- Find the VALUE paired with `key` in a literal pair-list. -/
private partial def findPairVal (key : Expr) (lst : Expr) :
    MetaM Expr := do
  let l ← whnf lst
  if l.isAppOfArity ``List.cons 3 then
    let pair ← whnf l.getAppArgs[1]!
    if pair.isAppOfArity ``Prod.mk 4 then
      if ← withProbeBudget (isDefEqGuarded pair.getAppArgs[2]! key) then
        return pair.getAppArgs[3]!
    findPairVal key l.getAppArgs[2]!
  else
    throwError "mint: no entry with key {key} in the context list"

/-- Apply the remaining PREMISE arguments of a partial application:
    each Prop-typed (autoParam-stripped) argument is closed through
    `solveHyp` at the given locals. -/
private def applyWithPremises (fn : Expr) (locals : Array Expr) :
    MetaM Expr := do
  let mut cur := fn
  let mut fuel := 16
  while fuel > 0 do
    let ty ← whnf (← inferType cur)
    unless ty.isForall do return cur
    let dom := ty.bindingDomain!.cleanupAnnotations
    let m ← mkFreshExprMVar dom
    unless ← solveHyp locals m.mvarId! do
      throwError "mint: premise has no source:{indentExpr dom}"
    cur := mkApp cur (← instantiateMVars m)
    fuel := fuel - 1
  return cur

/-- LOAD-round minting (the ACTION[LoadRequest] class): the request
    draw is a `return` (state-preserving; kernel-pinned), the perform
    composes the once-proved `perform_load` over the loc-generic
    int-load block (`intLoad_facts_loc`, resolved at run time) at
    the link's own footprint premises; the round lands as ONE
    `link_load`. -/
private def tryMintLoad (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) (cE : Expr) (stepI : Expr) :
    MetaM BuiltLink := do
  let stepArgs := stepI.getAppArgs
  let mReq0 ← whnfCore stepArgs[stepArgs.size - 1]!
  unless mReq0.isAppOf ``stExceptUndef_return do
    throwError "mint: action request is not a return draw \
      (head {mReq0.getAppFn}) — outside the construct set"
  let some req0 ← kwhnf? mReq0.getAppArgs.back!
    | throwError "mint: request payload did not compute"
  unless req0.isAppOf ``LoadRequest2 do
    throwError "mint: request class {req0.getAppFn} — outside the \
      construct set"
  let some ptr0 ← kwhnf? req0.getAppArgs[req0.getAppNumArgs - 2]!
    | throwError "mint: load pointer did not compute"
  -- PV (Prov_some aid) (PVconcrete none addr)
  unless ptr0.getAppNumArgs ≥ 2 do
    throwError "mint: load pointer shape{indentExpr ptr0}"
  let some prov ← kwhnf? ptr0.getAppArgs[ptr0.getAppNumArgs - 2]!
    | throwError "mint: load provenance did not compute"
  let some pvc ← kwhnf? ptr0.getAppArgs[ptr0.getAppNumArgs - 1]!
    | throwError "mint: load address did not compute"
  unless prov.getAppNumArgs ≥ 1 && pvc.getAppNumArgs ≥ 1 do
    throwError "mint: load pointer parts shape"
  let aidE := prov.getAppArgs.back!
  let addrE := pvc.getAppArgs.back!
  let alcE ← findPairVal aidE comps[4]!
  let bytesE ← findPairVal addrE comps[5]!
  -- the link
  let linkC := ``RelSem.Seg.link_load
  let cinfo ← getConstInfo linkC
  let (args, _, concl) ← forallMetaTelescope cinfo.type
  unless concl.isAppOfArity ``RelSem.Seg.SegStep 7 do
    throwError "mint [{linkC}]: link conclusion shape"
  let cargs := concl.getAppArgs
  unless (← isDefEq cargs[0]! gf) && (← isDefEq cargs[1]! gs)
      && (← isDefEq cargs[2]! td) && (← isDefEq cargs[3]! tid) do
    throwError "mint [{linkC}]: instance/program unification failed"
  unless ← isDefEq cargs[5]! ΓE do
    throwError "mint [{linkC}]: entry context does not unify"
  -- pre-pin famI and the data slots (aid, addr : Int in declaration
  -- order; alc; bytes) — committed choice
  let famI ← mkAppM ``RelSem.Seg.stateAt #[cE]
  let mut famPinned := false
  let mut intPins := #[aidE, addrE]
  let mut intIdx := 0
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if !famPinned && aty.isArrow
          && aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack
          && aty.bindingBody!.isConstOf ``driver_state then
        unless ← isDefEq a famI do
          throwError "mint [{linkC}]: famI pre-pin failed"
        famPinned := true
      else if aty.isConstOf ``Int && intIdx < intPins.size then
        unless ← isDefEq a intPins[intIdx]! do
          throwError "mint [{linkC}]: Int slot pre-pin failed"
        intIdx := intIdx + 1
      else if aty.isConstOf ``CerbMem.Allocation then
        unless ← isDefEq a alcE do
          throwError "mint [{linkC}]: alloc slot pre-pin failed"
      else if aty.isAppOf ``List
          && aty.appArg!.isConstOf ``CerbMem.AbsByte then
        unless ← isDefEq a bytesE do
          throwError "mint [{linkC}]: bytes slot pre-pin failed"
  -- the happ slot
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq && body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then
      happIdx := some i
  let some hi := happIdx
    | throwError "mint [{linkC}]: no happ premise"
  let happTy ← instantiateMVars (← inferType args[hi]!)
  -- the loaded value, read off the byte range's canonical spelling
  let vE ←
    if bytesE.isAppOf `RelSem.T1.xBytes then
      pure bytesE.appArg!
    else
      throwError "mint: byte range is not int-cell spelled \
        ({bytesE.getAppFn}) — outside the construct set"
  let (happLam, succ0) ← forallTelescope happTy fun xs _body => do
    let p := xs[0]!
    let σp := mkApp famI p
    -- the discovery at the telescope's pack
    let discE ← mkAppM ``find_can_advance
      #[← mkAppM ``RelSem.Cerb.dnmsDiscover #[td, tid, σp]]
    let some stepOp ← kwhnf? discE
      | throwError "mint: discovery did not compute at the happ pack"
    unless stepOp.isAppOfArity ``Option.some 2 do
      throwError "mint: discovery shape at the happ pack"
    let some stepIp ← kwhnf? stepOp.appArg!
      | throwError "mint: step body did not compute at the happ pack"
    let hfindP ← mkLhsRflHint discE (mkApp stepOp.appFn! stepIp)
    let spArgs := stepIp.getAppArgs
    unless spArgs.size ≥ 5 do
      throwError "mint: action step arity at the happ pack"
    let dbgE := spArgs[spArgs.size - 5]!
    let locE := spArgs[spArgs.size - 4]!
    let mReqP := spArgs[spArgs.size - 1]!
    -- the request draw (a return: state-preserving, kernel-pinned)
    let reqApp ← mkAppM ``app
      #[← mkAppM ``liftCore_run #[mReqP], σp]
    let some reqPair ← kwhnf? reqApp
      | throwError "mint: request draw did not compute"
    unless reqPair.isAppOfArity ``Prod.mk 4 do
      throwError "mint: request draw shape{indentExpr reqPair}"
    let some ndv ← kwhnf? reqPair.getAppArgs[2]!
      | throwError "mint: request value did not compute"
    let reqPair := mkAppN reqPair.getAppFn
      (reqPair.getAppArgs.set! 2 ndv)
    let hreq ← mkLhsRflHint reqApp reqPair
    -- the perform, through the loc-generic int-load block
    let lsE ← mkAppM ``driver_state.layout_state #[σp]
    let hmemFn ← mkAppM `RelSem.Seg.intLoad_facts_loc
      #[locE, vE, addrE, aidE, alcE, lsE]
    let hmem ← applyWithPremises hmemFn xs
    let some ptrP ← kwhnf? ndv.getAppArgs.back! |
      throwError "mint: request ctor did not compute"
    unless ptrP.isAppOf ``LoadRequest2 && ptrP.getAppNumArgs ≥ 4 do
      throwError "mint: request is not a LoadRequest at the happ pack"
    let ptrE' := ptrP.getAppArgs[ptrP.getAppNumArgs - 2]!
    let hpref ← mkAppOptM ``RelSem.Kit.mem_prefix_block
      #[some ptrE', some lsE]
    -- perform_load, conclusion-unified (pins mo/mk/tid'/σ)
    let hperf ← do
      let ci ← getConstInfo ``RelSem.Kit.perform_load
      let (ms, _, cc) ← forallMetaTelescope ci.type
      let mut props : Array Expr := #[]
      for m in ms do
        let m ← instantiateMVars m
        if m.isMVar then
          if (← inferType (← instantiateMVars
              (← m.mvarId!.getType))).isProp then
            props := props.push m
      unless props.size == 2 do
        throwError "mint: perform_load premise count {props.size}"
      unless ← isDefEq props[0]! hmem do
        throwError "mint: perform_load hmem assignment failed"
      unless ← isDefEq props[1]! hpref do
        throwError "mint: perform_load hpref assignment failed"
      -- pin the request continuation by unifying the conclusion's
      -- request against the drawn one
      let some (_, lhsP, _) := (← instantiateMVars cc).eq?
        | throwError "mint: perform_load conclusion shape"
      let reqArg := lhsP.appFn!.appArg!.getAppArgs.back!
      let _ ← isDefEq lhsP.appFn!.appArg! (← whnfCore
        lhsP.appFn!.appArg!)
      let _ := reqArg
      unless ← withProbeBudget (isDefEq lhsP
          (← mkAppM ``app #[← mkAppM ``perform_action_request2
            #[mkConst ``Bool.false, locE,
              spArgs[spArgs.size - 3]!, ndv.getAppArgs.back!], σp]))
        do
        throwError "mint: perform_load conclusion does not match the \
          drawn request"
      instantiateMVars (mkAppN
        (mkConst ``RelSem.Kit.perform_load (ci.levelParams.map .param))
        (← ms.mapM instantiateMVars))
    -- the advance, conclusion-unified (pins dbg/loc/tid'/m_request)
    let hadv ← do
      let ci ← getConstInfo ``RelSem.Kit.advance_action_request
      let (ms, _, cc) ← forallMetaTelescope ci.type
      let some (_, lhsA, _) := (← instantiateMVars cc).eq?
        | throwError "mint: advance_action_request conclusion shape"
      let tgt ← mkAppM ``app
        #[← mkAppM ``advance_step #[td, tid, stepIp], σp]
      unless ← withProbeBudget (isDefEq lhsA tgt) do
        throwError "mint: advance_action_request LHS mismatch"
      let mut props : Array Expr := #[]
      for m in ms do
        let m ← instantiateMVars m
        if m.isMVar then
          if (← inferType (← instantiateMVars
              (← m.mvarId!.getType))).isProp then
            props := props.push m
      unless props.size == 2 do
        throwError "mint: advance premise count {props.size}"
      unless ← isDefEq props[0]! hreq do
        throwError "mint: advance hreq assignment failed"
      unless ← isDefEq props[1]! hperf do
        throwError "mint: advance hperf assignment failed"
      instantiateMVars (mkAppN (mkConst ``RelSem.Kit.advance_action_request
        (ci.levelParams.map .param)) (← ms.mapM instantiateMVars))
    let body ← mkAppM ``RelSem.Cerb.dnmsRoundM_adv #[hfindP, hadv]
    let some (_, _, rhs) := (← inferType body).eq?
      | throwError "mint: load round conclusion shape"
    let rhsW ← whnfCore rhs
    unless rhsW.isAppOfArity ``Prod.mk 4 do
      throwError "mint: load successor pair shape"
    let succ := rhsW.getAppArgs[3]!
    let succ0 := succ.replaceFVar p (← mkPack0)
    pure (← mkLambdaFVars xs body, succ0)
  -- famO := the program-blind rebuild at the successor's control
  -- image (cheap now: the entry image is flat/named, so the pack0
  -- substitution reduces by shallow projections only)
  let famO ← mkAppM ``RelSem.Seg.stateAt
    #[← flattenCtl (← mkAppM ``ctlOf #[succ0])]
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isArrow && aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack
          && aty.bindingBody!.isConstOf ``driver_state then
        unless ← isDefEq a famO do
          throwError "mint [{linkC}]: famO pre-pin failed"
  unless ← withProbeBudget (isDefEq args[hi]! happLam) do
    throwError "mint [{linkC}]: minted load proof does not fit the \
      happ slot"
  let pack0 ← mkPack0
  let mut progress := true
  while progress do
    progress := false
    for a in args do
      let a ← instantiateMVars a
      if a.isMVar then
        if ← dispatchPremise linkC pack0 a.mvarId! then
          progress := true
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      throwError "mint [{linkC}]: unfilled premise:\
        {indentExpr (← instantiateMVars (← a.mvarId!.getType))}"
  let concl ← instantiateMVars concl
  let delta := concl.getAppArgs[concl.getAppNumArgs - 1]!
  if delta.hasExprMVar then
    throwError "mint [{linkC}]: successor context still open"
  let pf ← instantiateMVars (mkAppN
    (mkConst linkC (cinfo.levelParams.map .param)) args)
  return { pf, delta, minted := true }

/-- Parse a return-drawn action request; give back the (kernel-
    computed) request constructor application. -/
private def mintReqOf (stepI : Expr) : MetaM Expr := do
  let stepArgs := stepI.getAppArgs
  let mReq0 ← whnfCore stepArgs[stepArgs.size - 1]!
  unless mReq0.isAppOf ``stExceptUndef_return do
    throwError "mint: action request is not a return draw \
      (head {mReq0.getAppFn}) — outside the construct set"
  let some req0 ← kwhnf? mReq0.getAppArgs.back!
    | throwError "mint: request payload did not compute"
  return req0

/-- Decompose a concrete `PV (Prov_some aid) (PVconcrete _ addr)`
    pointer into (aid, addr). -/
private def mintPtrParts (ptrE : Expr) : MetaM (Expr × Expr) := do
  let some ptr0 ← kwhnf? ptrE
    | throwError "mint: pointer did not compute"
  unless ptr0.getAppNumArgs ≥ 2 do
    throwError "mint: pointer shape{indentExpr ptr0}"
  let some prov ← kwhnf? ptr0.getAppArgs[ptr0.getAppNumArgs - 2]!
    | throwError "mint: provenance did not compute"
  let some pvc ← kwhnf? ptr0.getAppArgs[ptr0.getAppNumArgs - 1]!
    | throwError "mint: address did not compute"
  unless prov.getAppNumArgs ≥ 1 && pvc.getAppNumArgs ≥ 1 do
    throwError "mint: pointer parts shape"
  return (prov.getAppArgs.back!, pvc.getAppArgs.back!)

/-- Build the happ premise of a memory link by conclusion-unifying
    the standard chain (discovery pin → advance_action_request →
    perform_* → the per-class memory block), with the block's own
    premises solved from the telescope's hypotheses and deep kernel
    pins. Returns (happLam, succ0). Shared by the create/store/kill
    minters (the load minter predates it and keeps its own body). -/
private def mintMemHapp (td tid : Expr) (famI happTy : Expr)
    (performC : Name)
    (mkBlock : Array Expr → Expr → Expr → Expr → MetaM Expr) :
    MetaM (Expr × Expr) := do
  forallTelescope happTy fun xs _body => do
    let p := xs[0]!
    let σp := mkApp famI p
    let discE ← mkAppM ``find_can_advance
      #[← mkAppM ``RelSem.Cerb.dnmsDiscover #[td, tid, σp]]
    let some stepOp ← kwhnf? discE
      | throwError "mint: discovery did not compute at the happ pack"
    unless stepOp.isAppOfArity ``Option.some 2 do
      throwError "mint: discovery shape at the happ pack"
    let some stepIp ← kwhnf? stepOp.appArg!
      | throwError "mint: step body did not compute at the happ pack"
    let hfindP ← mkLhsRflHint discE (mkApp stepOp.appFn! stepIp)
    let spArgs := stepIp.getAppArgs
    unless spArgs.size ≥ 5 do
      throwError "mint: action step arity at the happ pack"
    let locE := spArgs[spArgs.size - 4]!
    let mReqP := spArgs[spArgs.size - 1]!
    -- the request draw (a return: state-preserving, kernel-pinned)
    let reqApp ← mkAppM ``app
      #[← mkAppM ``liftCore_run #[mReqP], σp]
    let some reqPair ← kwhnf? reqApp
      | throwError "mint: request draw did not compute"
    unless reqPair.isAppOfArity ``Prod.mk 4 do
      throwError "mint: request draw shape{indentExpr reqPair}"
    let some ndv ← kwhnf? reqPair.getAppArgs[2]!
      | throwError "mint: request value did not compute"
    let reqPair := mkAppN reqPair.getAppFn
      (reqPair.getAppArgs.set! 2 ndv)
    let hreq ← mkLhsRflHint reqApp reqPair
    let lsE ← mkAppM ``driver_state.layout_state #[σp]
    let some reqP ← kwhnf? ndv.getAppArgs.back!
      | throwError "mint: request ctor did not compute at the pack"
    -- the memory block (per class)
    let hmem ← mkBlock xs lsE locE reqP
    -- perform_*, conclusion-unified
    let hperf ← do
      let ci ← getConstInfo performC
      let (ms, _, cc) ← forallMetaTelescope ci.type
      let some (_, lhsP, _) := (← instantiateMVars cc).eq?
        | throwError "mint: {performC} conclusion shape"
      unless ← withProbeBudget (isDefEq lhsP
          (← mkAppM ``app #[← mkAppM ``perform_action_request2
            #[mkConst ``Bool.false, locE,
              spArgs[spArgs.size - 3]!, reqP], σp])) do
        throwError "mint: {performC} conclusion does not match the \
          drawn request"
      let props ← propHoles ms
      -- premises in order: hmem first; any residual premise closed
      -- from the telescope/kernel
      unless props.size ≥ 1 do
        throwError "mint: {performC} premise count"
      unless ← isDefEq props[0]! hmem do
        throwError "mint: {performC} hmem assignment failed"
      for i in [1:props.size] do
        let m ← instantiateMVars props[i]!
        if m.isMVar then
          let mty ← instantiateMVars (← m.mvarId!.getType)
          let some pf ← mintSolvePremise xs mty
            | throwError "mint: {performC} residual premise has no \
                source:{indentExpr mty}"
          unless ← isDefEq m pf do
            throwError "mint: {performC} residual assignment failed"
      instantiateMVars (mkAppN
        (mkConst performC (ci.levelParams.map .param))
        (← ms.mapM instantiateMVars))
    -- the advance, conclusion-unified
    let hadv ← do
      let ci ← getConstInfo ``RelSem.Kit.advance_action_request
      let (ms, _, cc) ← forallMetaTelescope ci.type
      let some (_, lhsA, _) := (← instantiateMVars cc).eq?
        | throwError "mint: advance_action_request conclusion shape"
      let tgt ← mkAppM ``app
        #[← mkAppM ``advance_step #[td, tid, stepIp], σp]
      unless ← withProbeBudget (isDefEq lhsA tgt) do
        throwError "mint: advance_action_request LHS mismatch"
      let props ← propHoles ms
      unless props.size == 2 do
        throwError "mint: advance premise count {props.size}"
      unless ← isDefEq props[0]! hreq do
        throwError "mint: advance hreq assignment failed"
      unless ← isDefEq props[1]! hperf do
        throwError "mint: advance hperf assignment failed"
      instantiateMVars (mkAppN
        (mkConst ``RelSem.Kit.advance_action_request
          (ci.levelParams.map .param)) (← ms.mapM instantiateMVars))
    let body ← mkAppM ``RelSem.Cerb.dnmsRoundM_adv #[hfindP, hadv]
    let some (_, _, rhs) := (← inferType body).eq?
      | throwError "mint: memory round conclusion shape"
    let rhsW ← whnfCore rhs
    unless rhsW.isAppOfArity ``Prod.mk 4 do
      throwError "mint: memory round successor pair shape"
    let succ := rhsW.getAppArgs[3]!
    let succ0 := succ.replaceFVar p (← mkPack0)
    pure (← mkLambdaFVars xs body, succ0)

/-- The shared tail of the memory minters: pre-pin famI/famO and the
    happ lambda into `linkC`'s telescope, dispatch the residual
    premises, return the link. -/
private def mintMemFinish (gf gs td tid : Expr) (ΓE : Expr)
    (linkC : Name) (args : Array Expr) (concl : Expr)
    (cinfo : ConstantInfo) (famI happLam succ0 : Expr) :
    MetaM BuiltLink := do
  let famO ← mkAppM ``RelSem.Seg.stateAt
    #[← flattenCtl (← mkAppM ``ctlOf #[succ0])]
  -- famI was pinned by the caller; every REMAINING fam-typed hole is
  -- the successor family
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isArrow && aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack
          && aty.bindingBody!.isConstOf ``driver_state then
        unless ← isDefEq a famO do
          throwError "mint [{linkC}]: famO pre-pin failed"
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq && body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then
      happIdx := some i
  let some hi := happIdx
    | throwError "mint [{linkC}]: no happ premise"
  unless ← withProbeBudget (isDefEq args[hi]! happLam) do
    throwError "mint [{linkC}]: minted proof does not fit the happ \
      slot; slot:{indentExpr (← instantiateMVars (← inferType args[hi]!))}\nbuilt:{indentExpr (← inferType happLam)}"
  let pack0 ← mkPack0
  let mut progress := true
  while progress do
    progress := false
    for a in args do
      let a ← instantiateMVars a
      if a.isMVar then
        if ← dispatchPremise linkC pack0 a.mvarId! then
          progress := true
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      throwError "mint [{linkC}]: unfilled premise:\
        {indentExpr (← instantiateMVars (← a.mvarId!.getType))}"
  let concl ← instantiateMVars concl
  let delta := concl.getAppArgs[concl.getAppNumArgs - 1]!
  if delta.hasExprMVar then
    throwError "mint [{linkC}]: successor context still open"
  let pf ← instantiateMVars (mkAppN
    (mkConst linkC (cinfo.levelParams.map .param)) args)
  return { pf, delta, minted := true }

/-- CREATE-round minting: `link_create` at kernel-computed ground
    data (sizeof/alignDown/base address off the context's `mr`), the
    memory block `alloc_block_mr` (identity data rerouted through the
    residual — open packs). -/
private def tryMintCreate (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) (cE : Expr) (stepI : Expr) :
    MetaM BuiltLink := do
  let req0 ← mintReqOf stepI
  let rArgs := req0.getAppArgs
  unless req0.isAppOf ``CreateRequest2 && rArgs.size ≥ 6 do
    throwError "mint: create request shape"
  let prefE := rArgs[rArgs.size - 6]!
  let some alignE ← kwhnf? rArgs[rArgs.size - 5]!
    | throwError "mint: create align did not compute"
  unless alignE.getAppNumArgs ≥ 2 do
    throwError "mint: create align shape"
  let alignNE := alignE.getAppArgs.back!
  let pvE := alignE.getAppArgs[alignE.getAppNumArgs - 2]!
  let tyE := rArgs[rArgs.size - 4]!
  let mrE := comps[3]!
  let some szE ← kwhnf? (← mkAppM ``Nat.max
      #[← mkAppM ``CerbMem.sizeofCtype #[tyE], mkNatLit 1])
    | throwError "mint: sizeof did not compute"
  let some aNewE ← kwhnf? (← mkAppM ``Int.ofNat
      #[← mkAppM ``CerbMem.alignDown
        #[← mkAppM ``Int.toNat
          #[← mkAppM ``HSub.hSub
            #[← mkAppM ``CerbMem.MemState.lastAddress #[mrE],
              ← mkAppM ``Int.ofNat #[szE]]],
          ← mkAppM ``Nat.max
            #[← mkAppM ``Int.toNat #[alignNE], mkNatLit 1]]])
    | throwError "mint: create address did not compute"
  let linkC := ``RelSem.Seg.link_create
  let cinfo ← getConstInfo linkC
  let (args, _, concl) ← forallMetaTelescope cinfo.type
  unless concl.isAppOfArity ``RelSem.Seg.SegStep 7 do
    throwError "mint [{linkC}]: link conclusion shape"
  let cargs := concl.getAppArgs
  unless (← isDefEq cargs[0]! gf) && (← isDefEq cargs[1]! gs)
      && (← isDefEq cargs[2]! td) && (← isDefEq cargs[3]! tid) do
    throwError "mint [{linkC}]: instance/program unification failed"
  unless ← isDefEq cargs[5]! ΓE do
    throwError "mint [{linkC}]: entry context does not unify"
  -- pin the ground data slots by TYPE (declaration order:
  -- {ty : ctype} {pref : prefix0} {alignN : Int} {sz : Nat}
  -- {aNew : Int})
  let mut intPins := #[alignNE, aNewE]
  let mut intIdx := 0
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isConstOf ``ctype then
        unless ← isDefEq a tyE do
          throwError "mint [{linkC}]: ty pre-pin failed"
      else if aty.isConstOf ``prefix0 then
        unless ← isDefEq a prefE do
          throwError "mint [{linkC}]: pref pre-pin failed"
      else if aty.isConstOf ``Int && intIdx < intPins.size then
        unless ← isDefEq a intPins[intIdx]! do
          throwError "mint [{linkC}]: Int slot pre-pin failed"
        intIdx := intIdx + 1
      else if aty.isConstOf ``Nat then
        -- the sz slot (tid was pinned by the conclusion)
        unless ← isDefEq a szE do
          throwError "mint [{linkC}]: sz pre-pin failed"
  let famI ← mkAppM ``RelSem.Seg.stateAt #[cE]
  -- the happ slot's TYPE (after the pins)
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq && body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then happIdx := some i
  let some hi := happIdx
    | throwError "mint [{linkC}]: no happ premise"
  -- famI must be pinned before the happ telescope is taken
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isArrow && aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack
          && aty.bindingBody!.isConstOf ``driver_state then
        unless ← isDefEq a famI do
          throwError "mint [{linkC}]: famI pre-pin failed"
        break
  let happTy ← instantiateMVars (← inferType args[hi]!)
  let (happLam, succ0) ← mintMemHapp td tid famI happTy
    ``RelSem.Kit.perform_create
    (fun xs lsE _locE _reqP => do
      let fn ← mkAppOptM ``RelSem.Kit.alloc_block_mr
        #[some tid, some prefE, some pvE, some alignNE, some tyE,
          some lsE, some mrE, some szE, some aNewE]
      applyWithPremises fn xs)
  mintMemFinish gf gs td tid ΓE linkC args concl cinfo famI happLam
    succ0

/-- STORE-round minting: `link_store` at the request's concrete
    pointer, the new bytes kernel-computed from the stored value, the
    memory block `mem_store_block` at the link's footprint facts. -/
private def tryMintStore (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) (cE : Expr) (stepI : Expr) :
    MetaM BuiltLink := do
  let req0 ← mintReqOf stepI
  let rArgs := req0.getAppArgs
  unless req0.isAppOf ``StoreRequest2 && rArgs.size ≥ 6 do
    throwError "mint: store request shape"
  let ptrE := rArgs[rArgs.size - 3]!
  let mvalE := rArgs[rArgs.size - 2]!
  let (aidE, addrE) ← mintPtrParts ptrE
  let alcE ← findPairVal aidE comps[4]!
  let oldE ← findPairVal addrE comps[5]!
  -- the new bytes: memValueToBytes at the (data) funptrmap []
  -- the new bytes in the CANONICAL int-cell spelling (T1.xBytes v —
  -- definitionally the serializer's output; keeps the context's byte
  -- cells mintable by the LOAD class downstream)
  let some mval0 ← kwhnf? mvalE
    | throwError "mint: store value did not compute"
  unless mval0.isAppOf ``CerbMem.MemValue.MVinteger
      && mval0.getAppNumArgs ≥ 2 do
    throwError "mint: store value class {mval0.getAppFn} — outside \
      the construct set"
  let some iv0 ← kwhnf? mval0.getAppArgs.back!
    | throwError "mint: store integer value did not compute"
  unless iv0.getAppNumArgs ≥ 1 do
    throwError "mint: store integer shape"
  let vE := iv0.getAppArgs.back!
  let newE ← mkAppM `RelSem.T1.xBytes #[vE]
  let linkC := ``RelSem.Seg.link_store
  let cinfo ← getConstInfo linkC
  let (args, _, concl) ← forallMetaTelescope cinfo.type
  unless concl.isAppOfArity ``RelSem.Seg.SegStep 7 do
    throwError "mint [{linkC}]: link conclusion shape"
  let cargs := concl.getAppArgs
  unless (← isDefEq cargs[0]! gf) && (← isDefEq cargs[1]! gs)
      && (← isDefEq cargs[2]! td) && (← isDefEq cargs[3]! tid) do
    throwError "mint [{linkC}]: instance/program unification failed"
  unless ← isDefEq cargs[5]! ΓE do
    throwError "mint [{linkC}]: entry context does not unify"
  -- data pins: {aid : Int} {alc} {addr : Int} {old new : List AbsByte}
  let mut intPins := #[aidE, addrE]
  let mut intIdx := 0
  let mut listPins := #[oldE, newE]
  let mut listIdx := 0
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isConstOf ``Int && intIdx < intPins.size then
        unless ← isDefEq a intPins[intIdx]! do
          throwError "mint [{linkC}]: Int slot pre-pin failed"
        intIdx := intIdx + 1
      else if aty.isConstOf ``CerbMem.Allocation then
        unless ← isDefEq a alcE do
          throwError "mint [{linkC}]: alloc slot pre-pin failed"
      else if aty.isAppOf ``List
          && aty.appArg!.isConstOf ``CerbMem.AbsByte
          && listIdx < listPins.size then
        unless ← isDefEq a listPins[listIdx]! do
          throwError "mint [{linkC}]: byte slot pre-pin failed"
        listIdx := listIdx + 1
  let famI ← mkAppM ``RelSem.Seg.stateAt #[cE]
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isArrow && aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack
          && aty.bindingBody!.isConstOf ``driver_state then
        unless ← isDefEq a famI do
          throwError "mint [{linkC}]: famI pre-pin failed"
        break
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq && body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then happIdx := some i
  let some hi := happIdx
    | throwError "mint [{linkC}]: no happ premise"
  let happTy ← instantiateMVars (← inferType args[hi]!)
  let (happLam, succ0) ← mintMemHapp td tid famI happTy
    ``RelSem.Kit.perform_store
    (fun xs lsE locE reqP => do
      -- StoreRequest2 mo ty isLocking ptr mval mk
      let rA := reqP.getAppArgs
      let tyS := rA[rA.size - 5]!
      let fpmE ← mkAppM ``CerbMem.MemState.funptrmap #[lsE]
      let fn ← mkAppOptM ``RelSem.Kit.mem_store_block
        #[some locE, some tyS, some aidE, some addrE, some alcE,
          some lsE, some mvalE, some fpmE, some newE]
      applyWithPremises fn xs)
  mintMemFinish gf gs td tid ΓE linkC args concl cinfo famI happLam
    succ0

/-- KILL-round minting: `link_kill` at the request's concrete
    pointer; the block's dead-list premise from the walk's `MemInv`
    (contains_dead_false at the alloc fact). -/
private def tryMintKill (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) (cE : Expr) (stepI : Expr) :
    MetaM BuiltLink := do
  let req0 ← mintReqOf stepI
  let rArgs := req0.getAppArgs
  unless req0.isAppOf ``KillRequest2 && rArgs.size ≥ 3 do
    throwError "mint: kill request shape"
  let ptrE := rArgs[rArgs.size - 2]!
  let (aidE, addrE) ← mintPtrParts ptrE
  let alcE ← findPairVal aidE comps[4]!
  let linkC := ``RelSem.Seg.link_kill
  let cinfo ← getConstInfo linkC
  let (args, _, concl) ← forallMetaTelescope cinfo.type
  unless concl.isAppOfArity ``RelSem.Seg.SegStep 7 do
    throwError "mint [{linkC}]: link conclusion shape"
  let cargs := concl.getAppArgs
  unless (← isDefEq cargs[0]! gf) && (← isDefEq cargs[1]! gs)
      && (← isDefEq cargs[2]! td) && (← isDefEq cargs[3]! tid) do
    throwError "mint [{linkC}]: instance/program unification failed"
  unless ← isDefEq cargs[5]! ΓE do
    throwError "mint [{linkC}]: entry context does not unify"
  let mut intIdx := 0
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isConstOf ``Int && intIdx == 0 then
        unless ← isDefEq a aidE do
          throwError "mint [{linkC}]: aid pre-pin failed"
        intIdx := 1
      else if aty.isConstOf ``CerbMem.Allocation then
        unless ← isDefEq a alcE do
          throwError "mint [{linkC}]: alloc slot pre-pin failed"
  let famI ← mkAppM ``RelSem.Seg.stateAt #[cE]
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      let aty ← instantiateMVars (← a.mvarId!.getType)
      if aty.isArrow && aty.bindingDomain!.isConstOf ``RelSem.Seg.Pack
          && aty.bindingBody!.isConstOf ``driver_state then
        unless ← isDefEq a famI do
          throwError "mint [{linkC}]: famI pre-pin failed"
        break
  let mut happIdx : Option Nat := none
  for i in [0:args.size] do
    let ty ← instantiateMVars (← inferType args[i]!)
    let isHapp ← forallTelescope ty fun _ body =>
      pure (body.isEq && body.appFn!.appArg!.isAppOf ``app)
    if isHapp && happIdx.isNone then happIdx := some i
  let some hi := happIdx
    | throwError "mint [{linkC}]: no happ premise"
  let happTy ← instantiateMVars (← inferType args[hi]!)
  let (happLam, succ0) ← mintMemHapp td tid famI happTy
    ``RelSem.Kit.perform_kill
    (fun xs lsE locE _reqP => do
      -- hdead from MemInv.contains_dead_false at the alloc fact
      let hgetTy ← mkEq
        (← mkAppM ``Std.TreeMap.get?
          #[← mkAppM ``CerbMem.MemState.allocations #[lsE], aidE])
        (← mkAppM ``Option.some #[alcE])
      let some hget ← mintSolvePremise xs hgetTy
        | throwError "mint: kill alloc fact has no source"
      let mut hinv? : Option Expr := none
      for h in xs do
        if (← instantiateMVars (← inferType h)).isAppOf ``MemInv then
          hinv? := some h
      let some hinv := hinv?
        | throwError "mint: kill MemInv hypothesis missing"
      let hdead ← mkAppM ``MemInv.contains_dead_false #[hinv, hget]
      let fn ← mkAppOptM ``RelSem.Kit.mem_kill_block
        #[some locE, some aidE, some addrE, none, some alcE, some lsE,
          some hdead, some hget]
      applyWithPremises fn xs)
  mintMemFinish gf gs td tid ΓE linkC args concl cinfo famI happLam
    succ0

private def tryMintCore (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) : MetaM MintOut := do
  try
    let cE ← instantiateMVars comps[0]!
    let envE ← instantiateMVars comps[2]!
    let cells ← collectEnvPairs envE
    let packC := mkConst ``RelSem.Seg.Pack
    withLocalDeclD `q packC fun q => do
    let f1q ← mkAppM ``RelSem.Seg.Pack.f₁ #[q]
    let hwfTy ← mkAppM ``EnvWfFrame #[f1q]
    withLocalDeclD `hwf hwfTy fun hwf => do
    let frameTy ← inferType f1q
    let spineE ← mkListLit frameTy [f1q]
    -- the birth links' domain-ledger premise (unused by the construct
    -- proofs themselves; bound to match the birth happ telescopes)
    let hdomTy ← do
      let domE ← mkAppM ``RelSem.Seg.domOf #[envE]
      withLocalDeclD `z (mkConst ``sym) fun z => do
      withLocalDeclD `v' (mkConst ``value) fun v' => do
        let lk ← mkAppM ``lookup_env #[z, spineE]
        let prem ← mkEq lk (← mkAppM ``Option.some #[v'])
        let concl ← mkAppM ``Membership.mem
          #[domE, ← mkAppM ``RelSem.CerbSt.symNum #[z]]
        mkForallFVars #[z, v'] (← mkArrow prem concl)
    withLocalDeclD `hdom hdomTy fun hdom => do
    let cellTys ← cells.mapM fun (s, v) => do
      mkEq (← mkAppM ``lookup_env #[s, spineE])
        (← mkAppM ``Option.some #[v])
    let decls : Array (Name × (Array Expr → MetaM Expr)) :=
      cellTys.mapIdx fun i ty => (Name.mkSimple s!"hlk{i}", fun _ => pure ty)
    withLocalDeclsD decls fun cellFVars => do
    -- the kernel-computed discovery at the OPEN pack
    let famI ← mkAppM ``RelSem.Seg.stateAt #[cE]
    let σq := mkApp famI q
    let discE ← mkAppM ``find_can_advance
      #[← mkAppM ``RelSem.Cerb.dnmsDiscover #[td, tid, σq]]
    let some stepO ← kwhnf? discE
      | return MintOut.skip m!"kernel whnf failed on the discovery"
    if stepO.isAppOfArity ``Option.none 1 then
      return MintOut.terminal
    unless stepO.isAppOfArity ``Option.some 2 do
      return MintOut.skip
        m!"discovery did not commit (head {stepO.getAppFn})"
    let some stepI ← kwhnf? stepO.appArg!
      | return MintOut.skip m!"kernel whnf failed on the step body"
    let stepArgs := stepI.getAppArgs
    let (pfBody, th') ←
      if stepI.isAppOf ``Step_tau2 && stepArgs.size ≥ 3 then do
        let tsk ← whnfCore stepArgs[stepArgs.size - 2]!
        unless tsk.isConstOf ``TSK_Misc do
          throwError "mint: non-Misc tau kind"
        let th' := stepArgs[stepArgs.size - 1]!
        let stepI' := mkAppN stepI.getAppFn
          (stepArgs.set! (stepArgs.size - 2) tsk)
        let hfindPf ← mkLhsRflHint discE (mkApp stepO.appFn! stepI')
        pure (← mkAppM ``RelSem.Seg.cstep_tau #[hfindPf], th')
      else if stepI.isAppOf ``Step_with_runstate2 && stepArgs.size ≥ 2
      then do
        let kindE ← whnfCore stepArgs[stepArgs.size - 2]!
        let stepM := stepArgs[stepArgs.size - 1]!
        let lemN ←
          if kindE.isAppOf ``RSK_eval then
            pure ``RelSem.Seg.cstep_eval
          else if kindE.isAppOf ``RSK_tau then do
            let t ← whnfCore kindE.getAppArgs.back!
            unless t.isConstOf ``TSK_Misc do
              throwError "mint: non-Misc RSK_tau kind"
            pure ``RelSem.Seg.cstep_rs_tau
          else
            throwError "mint: unkeyed runstate kind \
              (head {kindE.getAppFn})"
        let stepI' := mkAppN stepI.getAppFn
          (stepArgs.set! (stepArgs.size - 2) kindE)
        let hfindPf ← mkLhsRflHint discE (mkApp stepO.appFn! stepI')
        let rsq ← mkAppM ``driver_state.core_run_state0 #[σq]
        let (th', _rs', rhsR, pfHm) ←
          crossToResult cellFVars (mkApp stepM rsq)
        let pfHm ← mkExpectedTypeHint pfHm
          (← mkEq (mkApp stepM rsq) rhsR)
        pure (← mkAppM lemN #[hfindPf, pfHm], th')
      else if stepI.isAppOf ``Step_action_request2 then do
        -- memory-action rounds mint through their own links
        -- (V3a continuation: the full load/store/create/kill set)
        let req0 ← mintReqOf stepI
        let b ←
          if req0.isAppOf ``LoadRequest2 then
            tryMintLoad gf gs td tid ΓE comps cE stepI
          else if req0.isAppOf ``StoreRequest2 then
            tryMintStore gf gs td tid ΓE comps cE stepI
          else if req0.isAppOf ``CreateRequest2 then
            tryMintCreate gf gs td tid ΓE comps cE stepI
          else if req0.isAppOf ``KillRequest2 then
            tryMintKill gf gs td tid ΓE comps cE stepI
          else
            throwError "mint: request class {req0.getAppFn} — \
              outside the construct set"
        trace[RelSem.segRun] "mint: consumed one memory-action round"
        return MintOut.link b
      else
        throwError "mint: step class outside the construct set \
          (head {stepI.getAppFn})"
    -- ENV-SHAPE classification of the successor thread: the unchanged
    -- open frame (pure), or one/two fresh binds over it (the BIRTH
    -- classes — the `ins`/fmapAddBy spelling is preserved: committed
    -- unfolds stop at `fmapAddBy` heads). Anything else is a thrown
    -- frontier.
    let reduceEnvHead (e0 : Expr) : MetaM Expr := do
      let mut cur ← whnfCore e0
      let mut fuel := 24
      while fuel > 0 do
        if cur == f1q || cur.getAppFn.isConstOf ``fmapAddBy then
          return cur
        unless cur.getAppFn.isConst do return cur
        let some nxt ← withProbeBudget (Meta.unfoldDefinition? cur)
          | return cur
        cur ← whnfCore nxt
        fuel := fuel - 1
      return cur
    let reduceToCons (e0 : Expr) : MetaM Expr := do
      let mut cur ← whnfCore e0
      let mut fuel := 24
      while fuel > 0 && !(cur.isAppOfArity ``List.cons 3)
          && !(cur.isAppOfArity ``List.nil 1) do
        unless cur.getAppFn.isConst do return cur
        let some nxt ← withProbeBudget (Meta.unfoldDefinition? cur)
          | return cur
        cur ← whnfCore nxt
        fuel := fuel - 1
      return cur
    let births ← do
      let envProj ← mkAppM ``thread_state.env #[th']
      let envList ← reduceToCons envProj
      unless envList.isAppOfArity ``List.cons 3 do
        throwError "mint: successor env spine shape{indentExpr envList}"
      let tail ← whnfCore envList.getAppArgs[2]!
      unless tail.isAppOfArity ``List.nil 1 do
        throwError "mint: successor env is not single-frame"
      let mut head := envList.getAppArgs[1]!
      let mut acc : Array (Expr × Expr) := #[]
      let mut done := false
      for _ in [0:3] do
        unless !done do continue
        head ← reduceEnvHead head
        if head == f1q then
          done := true
        else if head.getAppFn.isConstOf ``fmapAddBy
            && head.getAppNumArgs ≥ 4 then
          let hargs := head.getAppArgs
          acc := acc.push (hargs[hargs.size - 3]!, hargs[hargs.size - 2]!)
          head := hargs[hargs.size - 1]!
        else
          throwError "mint: successor env head outside the construct \
            set{indentExpr head}"
      unless done do
        throwError "mint: successor env bind depth > 2"
      pure acc
    -- keep only the cell binders the proof actually consumed.
    -- ONE cached collectFVars pass (V3a-continuation): per-fvar
    -- `containsFVar` re-traverses the proof term per cell with no
    -- visited set — measured EXPONENTIAL blowup on the DAG-shared
    -- kernel-expanded terms of the Ecase-scrutinee round (>3 min at
    -- round 9 vs 14 s whole-walk baseline); collectFVars visits each
    -- shared node once.
    let fvSt := Lean.collectFVars {} pfBody
    let used := cellFVars.filter fun h => fvSt.fvarSet.contains h.fvarId!
    -- the successor family, read off the proof's own conclusion
    let concl ← inferType pfBody
    let some (_, _, rhsPair) := concl.eq?
      | throwError "mint: proof conclusion shape"
    let rhsPair ← whnfCore rhsPair
    unless rhsPair.isAppOfArity ``Prod.mk 4 do
      throwError "mint: successor pair shape"
    let succ := rhsPair.getAppArgs[3]!
    -- THE BIRTH SUCCESSOR FAMILY, by env-slot surgery: rebuild the
    -- successor with the thread's env field literally `[p.f₁]`, so
    -- `famO {p with f₁ := ins x v p.f₁}` matches the step's successor
    -- by SHALLOW projection reduction only. (A pack0-substituted twin
    -- instead forces arena-deep defeq — measured 2M blowout at P01's
    -- arena sizes.)
    let mkBirthFamO : MetaM Expr := do
      unless succ.isAppOf ``RelSem.Kit.dnmsBump
          && succ.getAppNumArgs == 3 do
        throwError "mint: birth successor is not dnmsBump-formed:\
          {indentExpr succ}"
      let sargs := succ.getAppArgs
      -- reduce the successor thread to constructor form
      let mut thMk ← whnfCore sargs[1]!
      let mut fuel := 24
      while fuel > 0 && !(thMk.isAppOfArity ``thread_state.mk 7) do
        unless thMk.getAppFn.isConst do break
        let some nxt ← withProbeBudget (Meta.unfoldDefinition? thMk)
          | break
        thMk ← whnfCore nxt
        fuel := fuel - 1
      unless thMk.isAppOfArity ``thread_state.mk 7 do
        throwError "mint: birth thread did not reach constructor \
          form{indentExpr thMk}"
      -- env is field 3 (arena, stack0, errno, env, proc, exec, loc)
      let thNew := mkAppN thMk.getAppFn (thMk.getAppArgs.set! 3 spineE)
      let succNew := mkApp3 succ.getAppFn sargs[0]! thNew sargs[2]!
      mkLambdaFVars #[q] succNew
    -- the pure-control successor family: PROGRAM-BLIND stateAt at the
    -- FLATTENED successor control image (the tryMintLoad shape; V3a-
    -- continuation fix — a lazily-spelled `mkLambdaFVars [q] succ`
    -- famO sends every link premise dispatch through Meta-whnf of the
    -- unflattened wrapper nest: measured multi-minute grind at the
    -- Ecase-scrutinee round vs the flat image's shallow projections)
    let mkCtlFamO : MetaM Expr := do
      let succ0 := succ.replaceFVar q (← mkPack0)
      mkAppM ``RelSem.Seg.stateAt
        #[← flattenCtl (← mkAppM ``ctlOf #[succ0])]
    -- REBIND detection FIRST (V3a continuation): a "birth" whose
    -- keys are all already bound at the SAME values is the label-
    -- jump respell class — it must not enter the birth arms (their
    -- freshness premises are false there, loudly)
    let mut rebindHlks : Option (Array Expr) := none
    if births.size == 1 || births.size == 2 then do
      let envList := comps[2]!
      let mut hlks : Array Expr := #[]
      let mut ok := true
      for bi in births do
        if ok then
          match ← observing? (findPairVal bi.1 envList) with
          | some vcell =>
            unless ← withProbeBudget (isDefEqGuarded bi.2 vcell) do
              ok := false
            let mut found := false
            for j in [0:cells.size] do
              if !found then
                if ← withProbeBudget
                    (isDefEqGuarded cells[j]!.1 bi.1) then
                  hlks := hlks.push cellFVars[j]!
                  found := true
            unless found do ok := false
          | none => ok := false
      if ok then rebindHlks := some hlks
    let (linkC, happLam, famO) ←
      match rebindHlks with
      | some hlks =>
        pure ((if births.size == 1 then ``RelSem.Seg.link_ctl_rebind1
            else ``RelSem.Seg.link_ctl_rebind2),
          ← mkLambdaFVars (#[q, hwf] ++ hlks) pfBody,
          ← mkBirthFamO)
      | none =>
      match births.size, used.size with
      | 0, 0 => pure (``RelSem.Seg.link_ctl,
          ← mkLambdaFVars (#[q, hwf]) pfBody,
          ← mkCtlFamO)
      | 0, 1 => pure (``RelSem.Seg.link_ctl_env1,
          ← mkLambdaFVars (#[q, hwf] ++ used) pfBody,
          ← mkCtlFamO)
      | 0, 2 => pure (``RelSem.Seg.link_ctl_env2,
          ← mkLambdaFVars (#[q, hwf] ++ used) pfBody,
          ← mkCtlFamO)
      | 1, 0 => pure (``RelSem.Seg.link_birth1,
          ← mkLambdaFVars (#[q, hwf, hdom]) pfBody, ← mkBirthFamO)
      | 1, 1 => pure (``RelSem.Seg.link_birth1_env1,
          ← mkLambdaFVars (#[q, hwf, hdom] ++ used) pfBody,
          ← mkBirthFamO)
      | 2, 0 => pure (``RelSem.Seg.link_birth2,
          ← mkLambdaFVars (#[q, hwf, hdom]) pfBody, ← mkBirthFamO)
      | nb, nc => throwError
          "mint: {nb} births × {nc} cell reads — no matching link"
    let b ← buildMintedLink gf gs td tid ΓE linkC famI famO happLam
      births
    trace[RelSem.segRun] "mint: consumed one {linkC} round \
      ({births.size} births, {used.size} cells)"
    return MintOut.link b
  catch ex =>
    return .skip ex.toMessageData

/-- THE MINT ATTEMPT at the current context. Every failure — ordinary
    OR runtime (a deterministic-timeout inside a defeq probe) — is a
    traced skip to the registered-supply path, never an escape. -/
private def tryMint (gf gs td tid : Expr) (ΓE : Expr)
    (comps : Array Expr) : MetaM MintOut :=
  tryCatchRuntimeEx (tryMintCore gf gs td tid ΓE comps)
    (fun ex => return .skip m!"runtime: {ex.toMessageData}")

/-! NAMED-STATE COMPACTION of minted successors (the [USER
    2026-08-24] S3 ruling applied mid-walk: giant terms in goals are
    a representation smell — reflect the state ONCE into a named
    constant and reference it by name, the `derive_state`
    discipline). Two halves, both required (measured):
    * FLATTEN the control image to a record LITERAL — the successor
      otherwise spells "ctlOf (dnmsBump … (stateAt cPrev …))", and
      every later kernel/elaborator computation re-reduces the whole
      chain from round 0 (measured: 16-48G OOM by P01's else arm).
      Flattening is pure whnf/committed-unfold — defeq-preserving —
      and its work is bounded by PROGRAM size, not walk length: the
      new arena is `apply_ctx` over pieces of the previous FLAT
      arena (shared subterms), exactly the generated supply's
      normal form.
    * NAME the flat image as an auxiliary definition (kernel-checked,
      fvar-closed, uncompiled), so goals carry a small constant. -/

private def compactLink (base : Name) (b : BuiltLink) :
    MetaM BuiltLink := do
  let Δw ← whnfCore b.delta
  unless Δw.isAppOfArity ``RelSem.Seg.Ctx.mk 6 do return b
  let comps := Δw.getAppArgs
  let c ← instantiateMVars comps[0]!
  -- already small = a fam-builder/aux-constant spelling; a ctlOf-app
  -- is NOT small (its argument nests the walk — the measured
  -- chain-growth hole: ctlOf (famO pack0) is a 1-arg const app)
  if c.getAppFn.isConst && !(c.isAppOf ``ctlOf)
      && c.getAppNumArgs ≤ 4 then return b
  let cFlat ← flattenCtl c
  let n ← mkAuxDeclName (kind := base.componentsRev.head! ++ `segCtl)
  let cAux ← mkAuxDefinition n (mkConst ``driver_state) cFlat
    (compile := false)
  let delta := mkAppN (mkConst ``RelSem.Seg.Ctx.mk) (comps.set! 0 cAux)
  return { b with delta }

/-- Parse the seg_run goal:
    `Ctx.interp Γ ⊢ WP (dnmsK td F acc tid xs' k) @ s ; E {{Φ}}`. -/
private structure GoalParts where
  gf : Expr
  gs : Expr        -- CerbStGS instance
  Γ : Expr
  td : Expr
  F : Nat
  acc : Expr
  tid : Expr
  xs' : Expr
  k : Expr
  wpRhs : Expr

private def parseGoal (goal : Expr) : MetaM GoalParts := do
  let goal := (← instantiateMVars goal).consumeMData
  unless goal.isAppOfArity ``Iris.BI.BIBase.Entails 4 do
    throwError "seg_run: goal is not an entailment \
      (expected `Ctx.interp Γ ⊢ WP (dnmsK …) …`):{indentExpr goal}"
  let lhs := goal.getAppArgs[2]!
  let rhs := goal.getAppArgs[3]!
  unless lhs.isAppOfArity ``RelSem.Seg.Ctx.interp 3 do
    throwError "seg_run: entailment LHS is not `Ctx.interp Γ`:\
      {indentExpr lhs}"
  let gf := lhs.getAppArgs[0]!
  let gs := lhs.getAppArgs[1]!
  let Γ := lhs.getAppArgs[2]!
  let some dk := rhs.find? (·.isAppOfArity ``dnmsK 6)
    | throwError "seg_run: no `dnmsK` application in the WP \
        expression:{indentExpr rhs}"
  let dargs := dk.getAppArgs
  let some F ← getNatValue? dargs[1]!
    | throwError "seg_run: dnmsK fuel is not a literal:\
        {indentExpr dargs[1]!}"
  return { gf, gs, Γ, td := dargs[0]!, F, acc := dargs[2]!,
           tid := dargs[3]!, xs' := dargs[4]!, k := dargs[5]!,
           wpRhs := rhs }

/-- Candidate round equations at the current context: query the
    registry with `app (dnmsRoundM td tid) ?σ`, then filter by
    control-image agreement with Γ.c. -/
private def roundCandidates (td tid c : Expr) :
    MetaM (Array RelSem.LawRegistry.StepLaw) := do
  let roundM ← mkAppM ``dnmsRoundM #[td, tid]
  let σm ← mkFreshExprMVar (mkConst ``driver_state)
  let queryE ← mkAppM ``app #[roundM, σm]
  let hits ← RelSem.LawRegistry.query `roundEq queryE
    (unifyFallback := true)
  trace[RelSem.segRun] "roundCandidates: {hits.size} tree/unify hits \
    for{indentExpr queryE}"
  let mut out := #[]
  for l in hits do
    let ok ← withProbeBudget <| tryCatchRuntimeEx
      (observing? do
        withoutModifyingState do
          let ci ← getConstInfo l.name
          let (_, _, cc) ← forallMetaTelescope ci.type
          let some (_, lhsE, _) := cc.eq? | failure
          unless ← isDefEq lhsE queryE do failure
          -- control-image agreement, PERF-1 discipline: (1) a cheap
          -- syntactic ARENA-KEY comparison rejects cross-fixture /
          -- cross-position candidates with NO defeq at all (the
          -- default-transparency head-mismatch against a block-link
          -- p02CtlAt spelling can fall into the ctl-projection whnf
          -- — measured 2M grinds); (2) key matches try REDUCIBLE
          -- defeq first (the generated spellings are reducible by
          -- construction), then the standing default-transparency
          -- check (the T1/P01-class spellings)
          let σE := lhsE.appArg!
          let cKey := ctlArenaKey? c
          if let some (cArena, _) := cKey then
            let candKey := match σE.getAppArgs[0]? with
              | some a => a.getAppFn.constName?
              | none => none
            if candKey.isSome && candKey != some cArena then failure
          let ctl ← mkAppM ``ctlOf #[σE]
          -- two-stage: REDUCIBLE first (congruence assigns the pack
          -- mvar; a wrong same-arena candidate fails fast at the
          -- ctr/trace literals without the ctl-projection whnf),
          -- then the standing default check (entry-ctl spellings)
          let fast ← withoutModifyingState <|
            withReducible (isDefEqGuarded ctl c)
          let ok ← if fast then withReducible (isDefEq ctl c)
            else isDefEq ctl c
          unless ok do failure
          pure true)
      (fun ex => do
        trace[RelSem.segRun] "roundCandidates: {l.name} runtime-ex: \
          {ex.toMessageData}"
        pure none)
    if ok.isSome then out := out.push l
    else trace[RelSem.segRun] "roundCandidates: {l.name} filtered \
      (LHS/ctl disagreement)"
  return out

/-- Is a candidate's step TERMINAL (the RHS action is `Sum.inr …`)? -/
private def isTerminalCand (cand : Name) : MetaM Bool := do
  withoutModifyingState do
    let ci ← getConstInfo cand
    let (_, _, cc) ← forallMetaTelescope ci.type
    let some (_, _, rhs) := cc.eq? | return false
    let rhsW ← whnf rhs
    unless rhsW.isAppOfArity ``Prod.mk 4 do return false
    let vW ← whnf rhsW.getAppArgs[2]!
    -- NDactive (Sum.inr _)
    if vW.getAppNumArgs ≥ 1 then
      let inner ← whnf vW.getAppArgs[vW.getAppNumArgs - 1]!
      return inner.isAppOf ``Sum.inr
    return false

/-- THE STEPPER (core; `mint` = PERF-2 mechanism C mint-first mode:
    construct-package rounds are minted BEFORE any registered supply
    is consulted, so probed classes ride zero generated facts;
    unmintable classes fall back to blocks/rounds as ever). -/
private def segRunCore (mint : Bool) : TacticM Unit := do
  let mvarId ← getMainGoal
  mvarId.withContext do
  let parts ← parseGoal (← mvarId.getType)
  let mut ΓE := parts.Γ
  let mut links : Array BuiltLink := #[]
  let mut stopMsg : MessageData := m!""
  let mut running := true
  while running do
    -- PER-ROUND BUDGET ISOLATION (the R4 discipline, one level up):
    -- each round's whole dispatch gets a fresh heartbeat count, so
    -- the walk's total cost scales with the ROUND COUNT and a long
    -- straight-line run cannot exhaust one declaration budget. No
    -- global raise: each round stays under the ambient allowance.
    let stepRes ← Core.withCurrHeartbeats do
      let comps ← ctxComponents ΓE
      let c := comps[0]!
      -- PERF-2 mechanism C: mint-first (probe mode)
      if mint then
        match ← tryMint parts.gf parts.gs parts.td parts.tid ΓE comps
        with
        | .link b => return Sum.inl b
        | .terminal => return Sum.inr m!"terminal offer round reached \
            (apply `Seg.seg_done`)"
        | .skip why =>
          trace[RelSem.segRun] "mint skipped (falling back to the \
            registered supply): {why}"
      -- PERF-1 mechanism B: block facts FIRST (committed choice —
      -- the block-granular default supply; per-round links are the
      -- anchor path)
      if let some b ← tryBlock parts.gf parts.gs parts.td
          parts.tid ΓE comps then
        return Sum.inl b
      let cands ← roundCandidates parts.td parts.tid c
      if cands.isEmpty then
        return Sum.inr m!"no registered round equation matches the \
          control point{indentExpr c}"
      let mut term := false
      for l in cands do
        if ← isTerminalCand l.name then term := true
      if term then
        return Sum.inr m!"terminal offer round reached (apply \
          `Seg.seg_done`)"
      let mut built : Option BuiltLink := none
      let mut failures : Array MessageData := #[]
      for l in cands do
        if built.isSome then continue
        for linkC in linkConsts do
          if built.isSome then continue
          let s0 ← saveState
          try
            built := some (← Core.withCurrHeartbeats
              (buildLink parts.gf parts.gs parts.td
                parts.tid ΓE l.name linkC))
          catch ex =>
            s0.restore
            failures := failures.push
              m!"[{l.name} × {linkC}] {ex.toMessageData}"
      match built with
      | some b => return Sum.inl b
      | none =>
        -- the context/failure DETAILS render giant mint-spelled
        -- terms (measured 48G OOM at trace time) — they live behind
        -- the detail class; the standing message stays cheap
        trace[RelSem.segRun.detail] "no link applies at\
          {indentExpr c}\n{failures}"
        return Sum.inr m!"no link applies at Γ = \
          {ΓE} \
          ({cands.size} round candidates; enable \
          trace.RelSem.segRun.detail for the per-candidate reasons) \
          — if two candidates differ only in a path condition, \
          case-split first: this is a BRANCH cut point"
    match stepRes with
    | Sum.inl b =>
      let b ← if b.minted then do
          let base := (← Elab.Term.getDeclName?).getD `segRun
          let r ← compactLink base b
          pure r
        else pure b
      links := links.push b
      ΓE := b.delta
      trace[RelSem.segRun] "link {links.size}: +{b.n} round(s)\
        {if b.minted then " (minted)" else ""}"
      trace[RelSem.segRun.detail] "link {links.size}: → {b.delta}"
    | Sum.inr msg =>
      stopMsg := msg
      running := false
  if links.isEmpty then
    throwError "seg_run: could not take a single step — {stopMsg}"
  -- assemble the chain (right-nested trans with explicit counts;
  -- n = TOTAL ROUNDS — block links carry their own counts)
  let n := links.foldl (fun acc b => acc + b.n) 0
  let nL := links.size
  let mut chain := links[nL - 1]!.pf
  for i in [1:nL] do
    let idx := nL - 1 - i
    chain ← mkAppM ``RelSem.Seg.SegStep.trans #[links[idx]!.pf, chain]
  -- consume at the goal: telescope `SegStep.consume`, pin everything
  -- against the goal, the chain, and the literal fuel split; the
  -- `hcont` slot becomes the next goal
  let ci ← getConstInfo ``RelSem.Seg.SegStep.consume
  Core.withCurrHeartbeats do
  let (cargs2, _, cc) ← forallMetaTelescope ci.type
  unless ← isDefEq cc (← mvarId.getType) do
    throwError "seg_run: consume conclusion does not match the goal"
  -- h (the chain) is the first Prop-valued explicit of SegStep type
  let mut hSlot : Option Expr := none
  let mut hFSlot : Option Expr := none
  let mut hcontSlot : Option Expr := none
  for a in cargs2 do
    let a ← instantiateMVars a
    unless a.isMVar do continue
    let aty ← instantiateMVars (← a.mvarId!.getType)
    if aty.isAppOf ``RelSem.Seg.SegStep then
      hSlot := some a
    else if aty.isEq && !aty.isAppOf ``Iris.BI.BIBase.Entails then
      hFSlot := some a
    else if aty.isAppOf ``Iris.BI.BIBase.Entails then
      hcontSlot := some a
  let some hS := hSlot | throwError "seg_run: no chain slot"
  unless ← isDefEq hS chain do
    throwError "seg_run: chain does not fit the consume slot:\
      {indentExpr (← instantiateMVars (← hS.mvarId!.getType))}"
  let some hFS := hFSlot | throwError "seg_run: no fuel-split slot"
  let hFTy ← instantiateMVars (← hFS.mvarId!.getType)
  -- hF : F = ?f + n — pin ?f to the literal, close by hinted rfl
  let some (_, _, rhsF) := hFTy.eq? | throwError "seg_run: hF shape"
  let fLit := mkNatLit (parts.F - n)
  if rhsF.getAppNumArgs ≥ 2 then
    let fArg ← instantiateMVars rhsF.getAppArgs[rhsF.getAppNumArgs - 2]!
    if fArg.isMVar then
      let _ ← isDefEq fArg fLit
  let hFTy ← instantiateMVars (← hFS.mvarId!.getType)
  hFS.mvarId!.assign (← mkRflHint hFTy)
  let some hC := hcontSlot | throwError "seg_run: no hcont slot"
  mvarId.assign (← instantiateMVars (mkAppN
    (mkConst ``RelSem.Seg.SegStep.consume (ci.levelParams.map .param))
    cargs2))
  let hcontM := (← instantiateMVars hC).mvarId!
  replaceMainGoal [hcontM]
  let nMinted := links.foldl (fun acc b => if b.minted then acc + b.n
    else acc) 0
  trace[RelSem.segRun] "seg_run: consumed {n} round(s) \
    ({nMinted} minted, {n - nMinted} from supply); stopped: {stopMsg}"

/-- THE STEPPER (registered-supply mode: blocks first, per-round
    anchors second — PERF-1 behavior, unchanged). -/
elab "seg_run" : tactic => segRunCore false

/-- THE STEPPER, MINT-FIRST (PERF-2 mechanism C probe face): rounds
    in the probed construct classes are proved from the once-proved
    construct characterizations + the program's pinned Core term —
    ZERO generated per-round supply; other classes fall back. -/
elab "seg_run_c" : tactic => segRunCore true

end RelSem.Seg.Stepper
