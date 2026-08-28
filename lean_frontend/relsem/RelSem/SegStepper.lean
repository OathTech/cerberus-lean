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

set_option autoImplicit false

open Lean Elab Meta Tactic
open RelSem RelSem.Cerb RelSem.CerbSt

namespace RelSem.Seg.Stepper

initialize registerTraceClass `RelSem.segRun

/-- Speculative-probe heartbeat isolation (the R4 move). -/
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
    let neP ← mkDecideProof (← mkAppM ``Ne #[a, b])
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

/-- Close a hypothesis hole from: the premise telescope's locals, the
    outer local context, the memory-residual gadgets, hinted `rfl`. -/
private def solveHyp (locals : Array Expr) (m : MVarId) :
    MetaM Bool := do
  let ty ← instantiateMVars (← m.getType)
  for src in locals do
    if ← withProbeBudget (isDefEqGuarded (← inferType src) ty) then
      m.assign src
      return true
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
  return false

/-- Fill a link's `happ` premise from the (pre-telescoped) round
    equation: unify sides left-to-right, close the hypothesis holes,
    package the lambda. -/
private def fillHapp (happTy : Expr) (cand : Name) : MetaM Expr := do
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
    for marg in margs do
      let marg ← instantiateMVars marg
      if marg.isMVar then
        unless ← solveHyp xs marg.mvarId! do
          throwError "round {cand}: hypothesis has no source:\
            {indentExpr (← instantiateMVars (← marg.mvarId!.getType))}"
    let pf := mkAppN (mkConst cand (cinfo.levelParams.map .param)) margs
    mkLambdaFVars xs (← instantiateMVars pf)

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
   ``RelSem.Seg.link_load]

private structure BuiltLink where
  pf : Expr
  delta : Expr
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
      if rhsW.hasExprMVar || lst.hasExprMVar then return false
      unless rhsW.isAppOf ``Option.some do
        throwError "seg_run [{linkC}]: index premise rhs shape:\
          {indentExpr rhsW}"
      let pairE := rhsW.getAppArgs.back!
      let pairW ← whnf pairE
      let key ← if pairW.isAppOfArity ``Prod.mk 4 then
          pure pairW.getAppArgs[2]!
        else mkAppM ``Prod.fst #[pairE]
      if idxE.isMVar then
        let idx ← findPairIdx key lst
        unless ← isDefEq idxE (mkNatLit idx) do
          throwError "seg_run [{linkC}]: index assignment failed"
      let ty' ← instantiateMVars (← m.getType)
      m.assign (← mkRflHint ty')
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
        if anchorArg.hasAnyFVar (fun f => xs.any (·.fvarId! == f)) then
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
  let happPf ← fillHapp happTy cand
  trace[RelSem.segRun] "buildLink [{linkC}]: happ filled: \
    {← inferType happPf}"
  trace[RelSem.segRun] "buildLink [{linkC}]: slot type: \
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
        trace[RelSem.segRun] "buildLink [{linkC}]: dispatch on \
          {aty}"
        if ← dispatchPremise linkC pack0 a.mvarId! then
          progress := true
  for a in args do
    let a ← instantiateMVars a
    if a.isMVar then
      throwError "seg_run [{linkC}]: unfilled premise:\
        {indentExpr (← instantiateMVars (← a.mvarId!.getType))}"
  let concl ← instantiateMVars concl
  let delta := concl.getAppArgs[concl.getAppNumArgs - 1]!
  if delta.hasExprMVar then
    throwError "seg_run [{linkC}]: successor context still open"
  let pf ← instantiateMVars (mkAppN
    (mkConst linkC (cinfo.levelParams.map .param)) args)
  return { pf, delta }

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
  let goal ← instantiateMVars goal
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
    let ok ← withProbeBudget <| observing? do
      withoutModifyingState do
        let ci ← getConstInfo l.name
        let (_, _, cc) ← forallMetaTelescope ci.type
        let some (_, lhsE, _) := cc.eq? | failure
        unless ← isDefEq lhsE queryE do failure
        -- control-image agreement: ctlOf of the equation's state
        let σE := lhsE.appArg!
        let ctl ← mkAppM ``ctlOf #[σE]
        unless ← isDefEq ctl c do failure
        pure true
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

/-- THE STEPPER. -/
elab "seg_run" : tactic => do
  let mvarId ← getMainGoal
  mvarId.withContext do
  let parts ← parseGoal (← mvarId.getType)
  let mut ΓE := parts.Γ
  let mut links : Array BuiltLink := #[]
  let mut stopMsg : MessageData := m!""
  let mut running := true
  while running do
    let comps ← ctxComponents ΓE
    let c := comps[0]!
    let cands ← roundCandidates parts.td parts.tid c
    if cands.isEmpty then
      stopMsg := m!"no registered round equation matches the \
        control point{indentExpr c}"
      running := false
      continue
    -- terminal?
    let mut term := false
    for l in cands do
      if ← isTerminalCand l.name then term := true
    if term then
      stopMsg := m!"terminal offer round reached (apply \
        `Seg.seg_done`)"
      running := false
      continue
    -- try candidates × links
    let mut built : Option BuiltLink := none
    let mut failures : Array MessageData := #[]
    for l in cands do
      if built.isSome then continue
      for linkC in linkConsts do
        if built.isSome then continue
        let s0 ← saveState
        try
          built := some (← buildLink parts.gf parts.gs parts.td
            parts.tid ΓE l.name linkC)
        catch ex =>
          s0.restore
          failures := failures.push
            m!"[{l.name} × {linkC}] {ex.toMessageData}"
    match built with
    | some b =>
      links := links.push b
      ΓE := b.delta
      trace[RelSem.segRun] "link {links.size}: → {b.delta}"
    | none =>
      stopMsg := m!"no link applies at{indentExpr c}\n\
        {failures}\n(if two candidates differ only in a \
        path condition, case-split first — this is a BRANCH cut \
        point)"
      running := false
  if links.isEmpty then
    throwError "seg_run: could not take a single step — {stopMsg}"
  -- assemble the chain (right-nested trans with explicit counts)
  let n := links.size
  let mut chain := links[n - 1]!.pf
  for i in [1:n] do
    let idx := n - 1 - i
    chain ← mkAppM ``RelSem.Seg.SegStep.trans #[links[idx]!.pf, chain]
  -- consume at the goal: telescope `SegStep.consume`, pin everything
  -- against the goal, the chain, and the literal fuel split; the
  -- `hcont` slot becomes the next goal
  let ci ← getConstInfo ``RelSem.Seg.SegStep.consume
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
  trace[RelSem.segRun] "seg_run: consumed {n} round(s); stopped: \
    {stopMsg}"

end RelSem.Seg.Stepper
