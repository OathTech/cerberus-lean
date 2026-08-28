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
        trace[RelSem.segRun] "fillHapp: hole {mty} := \
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
   ``RelSem.Seg.link_load]

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
  let (happPf, _happXs, happDeferred) ← fillHapp happTy cand
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
  trace[RelSem.segRun] "tryBlock: {hits.size} candidates, arena key \
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

private def kwhnf? (e : Expr) : MetaM (Option Expr) := do
  match Lean.Kernel.whnf (← getEnv) (← getLCtx) e with
  | .ok r => pure (some r)
  | .error _ => pure none

/-- Hinted refl at the LHS (the discovery-pin device: the kernel
    re-checks `lhs ≡ rhs` at declaration add — fail-closed). -/
private def mkLhsRflHint (lhs rhs : Expr) : MetaM Expr := do
  mkExpectedTypeHint (← mkEqRefl lhs) (← mkEq lhs rhs)

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

/-- THE EVAL CROSSING: prove `lhs = Result (Defined z, st')` for a
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
private partial def crossToResult (cellFVars : Array Expr) (lhs : Expr)
    (fuel : Nat := 32) : MetaM (Expr × Expr × Expr × Expr) := do
  match fuel with
  | 0 => throwError "mint: eval-crossing depth bound exceeded"
  | fuel + 1 =>
  if let some (z, st', rhs) ← resultParts? lhs then
    return (z, st', rhs, ← mkLhsRflHint lhs rhs)
  let lhsW ← whnfCore lhs
  let fn := lhsW.getAppFn
  if fn.isConstOf ``stExceptUndef_bind then
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
    let pe ←
      if M.isAppOf ``eval_pexpr_aux2 || M.isAppOf ``eval_pexpr_aux2_lemFuel
      then whnfCore M.getAppArgs.back!
      else throwError "mint: runEU inner is not an aux2 entry \
        (head {M.getAppFn})"
    unless pe.isAppOf ``Pexpr do
      throwError "mint: aux2 argument is not a Pexpr ctor"
    let payload ← whnfCore pe.getAppArgs.back!
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
    let some nxt ← withProbeBudget (Meta.unfoldDefinition? lhsW)
      | throwError "mint: unkeyed head {fn} — outside the construct set"
    crossToResult cellFVars nxt fuel
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
    (linkC : Name) (famI famO happLam : Expr) : MetaM BuiltLink := do
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

/-- THE MINT ATTEMPT at the current context. -/
private def tryMint (gf gs td tid : Expr) (ΓE : Expr)
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
    -- purity check helper: the successor thread's env must still be
    -- the unchanged single open frame (env-writing steps — births —
    -- are outside the mint set and fall back to the supply)
    let checkPureEnv (th' : Expr) : MetaM Unit := do
      let some envThW ← kwhnf? (← mkAppM ``thread_state.env #[th'])
        | throwError "mint: successor env did not compute"
      unless envThW.isAppOfArity ``List.cons 3 do
        throwError "mint: successor env shape{indentExpr envThW}"
      let head ← instantiateMVars envThW.getAppArgs[1]!
      unless head == f1q do
        throwError "mint: env-writing step (birth class) — outside \
          the probe set"
    let pfBody ←
      if stepI.isAppOf ``Step_tau2 && stepArgs.size ≥ 3 then do
        let tsk ← whnfCore stepArgs[stepArgs.size - 2]!
        unless tsk.isConstOf ``TSK_Misc do
          throwError "mint: non-Misc tau kind"
        let th' := stepArgs[stepArgs.size - 1]!
        checkPureEnv th'
        let stepI' := mkAppN stepI.getAppFn
          (stepArgs.set! (stepArgs.size - 2) tsk)
        let hfindPf ← mkLhsRflHint discE (mkApp stepO.appFn! stepI')
        mkAppM ``RelSem.Seg.cstep_tau #[hfindPf]
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
        checkPureEnv th'
        let pfHm ← mkExpectedTypeHint pfHm
          (← mkEq (mkApp stepM rsq) rhsR)
        mkAppM lemN #[hfindPf, pfHm]
      else
        throwError "mint: step class outside the construct set \
          (head {stepI.getAppFn})"
    -- keep only the cell binders the proof actually consumed
    let used := cellFVars.filter fun h => pfBody.containsFVar h.fvarId!
    let happLam ← mkLambdaFVars (#[q, hwf] ++ used) pfBody
    -- the successor family, read off the proof's own conclusion
    let concl ← inferType pfBody
    let some (_, _, rhsPair) := concl.eq?
      | throwError "mint: proof conclusion shape"
    let rhsPair ← whnfCore rhsPair
    unless rhsPair.isAppOfArity ``Prod.mk 4 do
      throwError "mint: successor pair shape"
    let succ := rhsPair.getAppArgs[3]!
    let famO ← mkLambdaFVars #[q] succ
    let linkC ←
      match used.size with
      | 0 => pure ``RelSem.Seg.link_ctl
      | 1 => pure ``RelSem.Seg.link_ctl_env1
      | 2 => pure ``RelSem.Seg.link_ctl_env2
      | n => throwError "mint: {n} cell reads — no matching link"
    let b ← buildMintedLink gf gs td tid ΓE linkC famI famO happLam
    trace[RelSem.segRun] "mint: consumed one {linkC} round \
      ({used.size} cells)"
    return MintOut.link b
  catch ex =>
    return .skip ex.toMessageData

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
        return Sum.inr m!"no link applies at{indentExpr c}\n\
          {failures}\n(if two candidates differ only in a \
          path condition, case-split first — this is a BRANCH cut \
          point)"
    match stepRes with
    | Sum.inl b =>
      links := links.push b
      ΓE := b.delta
      trace[RelSem.segRun] "link {links.size}: → {b.delta}"
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
