/-
  RelSem.RoundEval.Rounds — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: THE PER-HEAD ROUND LANES — law-chain elaboration
  against the round equation with the successor a metavariable
  (elabLawChain, direct face + discovered-step glue), successor
  anchoring (anchorSucc + emitLawRound: flat records over base
  names, the mkDr idiom mechanized), and the per-class mints
  (mintLawPure: tau/runstate via the Kit advance laws; mintMemRound:
  the action-request classes via the perform + mem-block laws) plus
  the terminal-offer reader (terminalValue). Which law fires is the
  REGISTRY's knowledge; this module prepares each law's declared
  slots (ground literals, spellings) — elaborator handling.

  Split from RoundEval.lean; code carried VERBATIM apart from
  `private` removed where the assembly module consumes a definition.

  House rules: no sorry, no axioms; meta code only.
-/
import RelSem.RoundEval.Hyp
import RelSem.RoundEval.Mint
import RelSem.ConstructLaws
import RelSem.Kit.Round
import RelSem.Kit.Map

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

/-- Set when the last `elabLawChain` used the DISCOVERY GLUE (the
    stepAt face required a pack-proved discovery equation, arc-18 C3):
    `emitLawRound` then emits the round's `_hfind` theorem for the
    chain assembler (a kernel-deferred refl cannot re-run a
    pack-dependent discovery). -/
initialize lastGlueUsed : IO.Ref Bool ← IO.mkRef false

/-- Set by the loop's CLASSIFICATION when the step discovery needed
    the hypothesis pack (hyp-aware classification — arc-18 C3b): the
    direct face's `stepAt` unification would re-run that discovery
    WITHOUT the pack (measured: the round-68 post-store tau — a
    200k-heartbeat whnf abort the elaborator logs uncatchably), so
    `elabLawChain` goes straight to the discovered-step glue. -/
initialize classifyUsedHypNorm : IO.Ref Bool ← IO.mkRef false

/-- Build `app (advance_step td tid (Laws.stepAt td tid σ)) σ`. -/
def mkRoundLhs (td tid σ : Expr) : TermElabM Expr := do
  let stepAtE ← mkAppMU ``RelSem.Laws.stepAt #[td, tid, σ]
  let advE ← mkAppMU ``advance_step #[td, tid, stepAtE]
  mkAppMU ``RelSem.app #[advE, σ]

/-- The action/state component types of `app m σ`'s pair type. -/
private def pairComponentTys (lhs : Expr) : TermElabM (Expr × Expr) := do
  let pairTy ← whnfU (← inferType lhs)
  let some (aTy, sTy) := pairTy.app2? ``Prod
    | throwError "derive_rounds: `app` type is not a pair:{indentExpr pairTy}"
  return (aTy, sTy)

/-- `NDactive NOWAKEUP` at the action type of `app m σ` (the
    `nd_action` phantom parameters are read off the pair type). -/
private def mkNDactiveNowakeup (lhs : Expr) : TermElabM Expr := do
  let (aTy, _) ← pairComponentTys lhs
  let aTyW ← whnfU aTy
  unless aTyW.isAppOfArity ``nd_action 5 do
    throwError "derive_rounds: action type is not nd_action:{indentExpr aTyW}"
  let ps := aTyW.getAppArgs
  mkAppOptMU ``nd_action.NDactive
    #[some ps[0]!, some ps[1]!, some ps[2]!, some ps[3]!, some ps[4]!,
      some (mkConst ``advance_info.NOWAKEUP)]

/-- Elaborate a law-chain proof against the round equation with the
    successor a METAVARIABLE and return (proof, raw successor). The
    raw successor (the law's computed-RHS shape at the predecessor
    name) is then ANCHORED by `anchorSucc`. -/
private def elabLawChain (td tid σ stepE lhs : Expr) (roundIdx : Nat)
    (proofStx : Term) : TermElabM (Expr × Expr) := withCurrHeartbeats do
  -- Try the DIRECT face first (eqTy at the `stepAt` spelling — the
  -- committed S2b behavior, correct for materialized-state drives);
  -- on failure, elaborate against the DISCOVERED step and glue back
  -- through a kernel-deferred (or pack-proved) discovery equation
  -- (arc-17 S3 — at a builder-state σ0 the elaborator's stepAt
  -- unification wedges where both classification's whnf and the
  -- kernel succeed).
  lastGlueUsed.set false
  let elabAt (theLhs : Expr) : TermElabM (Expr × Expr) := do
    let (_, sTy) ← pairComponentTys theLhs
    let succMVar ← mkFreshExprMVar (some sTy)
    let nowakeup ← mkNDactiveNowakeup theLhs
    let rhs ← mkAppMU ``Prod.mk #[nowakeup, succMVar]
    let eqTy ← mkEq theLhs rhs
    trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: elaborating"
    let pf ← withCurrHeartbeats do
      let pf ← Term.elabTermEnsuringType proofStx eqTy
      Term.synthesizeSyntheticMVarsNoPostponing
      pure pf
    trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: done"
    let pf ← instantiateMVars pf
    if pf.hasSorry then
      throwError "derive_rounds: round {roundIdx} law-chain \
        elaboration produced sorry (a side condition failed — see \
        the errors above)"
    let succ ← instantiateMVars succMVar
    if succ.hasExprMVar then
      throwError "derive_rounds: round {roundIdx} successor still \
        has metavariables after law elaboration"
    return (pf, succ)
  let doGlue : TermElabM (Expr × Expr) := do
    let advE ← mkAppMU ``advance_step #[td, tid, stepE]
    let lhsD ← mkAppMU ``RelSem.app #[advE, σ]
    let (pf, succ) ← elabAt lhsD
    trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: glue elab done"
    let stepAtE ← mkAppMU ``RelSem.Laws.stepAt #[td, tid, σ]
    let hstep ← withCurrHeartbeats (do
      match ← (activeHypPack.get : BaseIO _) with
      | some hp => proveHypEq hp stepAtE stepE
      | none =>
        mkExpectedTypeHint (← mkEqRefl stepE) (← mkEq stepAtE stepE))
    trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: glue hstep done"
    -- per-phase scope (arc-18 C3): inferType/congr over the
    -- race-analyzed round-44-class step spellings is its own unit
    withCurrHeartbeats do
    let motive ← withLocalDeclD `s (← inferType stepE) fun sv => do
      mkLambdaFVars #[sv]
        (← mkAppMU ``RelSem.app
          #[← mkAppMU ``advance_step #[td, tid, sv], σ])
    let glue ← mkCongrArg motive hstep
    lastGlueUsed.set true
    return (← mkEqTrans glue pf, succ)
  -- GLUE-FIRST for hyp-classified BUILDER rounds (arc-18 C3b): when
  -- the discovery itself needed the pack, the direct face's stepAt
  -- unification re-runs it packless — round 44 failed fast, round 68
  -- ABORTED (an uncatchable logged 200k-whnf timeout inside term
  -- elaboration). The doomed attempt is skipped, not survived.
  -- BUILDER-GATED: materialized hyp drives (T4's committed rT) also
  -- hyp-classify some rounds but their direct faces SUCCEED — the
  -- gate keeps their emissions byte-identical (measured: ungated,
  -- the T4 drive emitted +16 glue artifacts).
  if (← classifyUsedHypNorm.get) && (← builderMode.get) then
    let advE ← mkAppMU ``advance_step #[td, tid, stepE]
    let lhsD ← mkAppMU ``RelSem.app #[advE, σ]
    unless lhs == lhsD do
      trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: hyp-classified \
        round — glue-first"
      return ← doGlue
  try
    elabAt lhs
  catch exDirect =>
    let advE ← mkAppMU ``advance_step #[td, tid, stepE]
    let lhsD ← mkAppMU ``RelSem.app #[advE, σ]
    if lhs == lhsD then throw exDirect
    trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: direct face \
      failed ({exDirect.toMessageData}); retrying at the discovered \
      step with glue"
    doGlue

/-- Unfold definition heads (dnmsBump and friends) until the record
    constructor is exposed (bounded; beta after each unfold). -/
def unfoldToRecord (e : Expr) : TermElabM Expr := withCurrHeartbeats do
  let mut e := e.headBeta
  for _ in [0 : 8] do
    if let .letE _ _ v b _ := e then
      e := (b.instantiate1 v).headBeta
      continue
    if e.isAppOfArity ``driver_state.mk 11 then return e
    let some e' ← unfoldDefinition? e | return e
    e := e'.headBeta
  return e

/-- Anchor a raw law successor (see the anchor-discipline note):
    flatten, substitute predecessor projections for the tracked
    components, normalize the thread-table update and scalar fields,
    and demand the result is a flat `driver_state.mk` record with NO
    residual reference to the predecessor constant (fail-closed).
    Returns the anchored record and the updated component set. -/
private def anchorSucc (a : Anchor) (σprev succRaw : Expr)
    (roundIdx : Nat) : TermElabM (Expr × Anchor) := do
  trace[RelSem.roundEval] "anchorSucc[{roundIdx}]: enter"
  let u ← unfoldToRecord succRaw
  trace[RelSem.roundEval] "anchorSucc[{roundIdx}]: unfolded"
  let s1 ← flattenState u
  trace[RelSem.roundEval] "anchorSucc[{roundIdx}]: flattened"

  let s2 ← substGround s1 (← withCurrHeartbeats (a.substPairs σprev))
  trace[RelSem.roundEval] "anchorSucc[{roundIdx}]: substituted"
  let s4 ← flattenState s2
  unless s4.isAppOfArity ``driver_state.mk 11 do
    throwFrontier m!"derive_rounds: round {roundIdx} successor did not \
      anchor to a flat driver_state record:{indentExpr s4}"
  let mut args := s4.getAppArgs
  -- Normalize the WHOLE core-state field: the thread-table update
  -- rides an `assoc_adjust` application whose spine otherwise chains
  -- through every predecessor (measured this slice: +1 embedded
  -- thread record per round and per-round cost DOUBLING through four
  -- successive spelling architectures — the table spine was the
  -- accretion all along).
  args := args.set! 2 (← groundNorm "core state" args[2]!)
  -- … and the scalar fields (counter; run-state supplies)
  let ctr' ← groundNorm "step counter" args[10]!
  let rs' ← do
    let rsW ← flattenState (← whnfU args[3]!)
    if rsW.isAppOfArity ``core_run_state.mk 5 then
      let ra := rsW.getAppArgs
      let tid' ← groundNorm "tid_supply" ra[0]!
      let aid' ← groundNorm "aid_supply" ra[1]!
      let exc' ← groundNorm "excluded_supply" ra[2]!
      let sym' ← groundNorm "sym_supply" ra[3]!
      pure (mkAppN rsW.getAppFn #[tid', aid', exc', sym', ra[4]!])
    else pure args[3]!
  let succE := mkAppN s4.getAppFn ((args.set! 10 ctr').set! 3 rs')
  -- fail-closed: the anchored body must not mention the predecessor
  -- ROUND constant (references to the BASE from-state are the anchor
  -- discipline itself — round 1's predecessor is the base)
  if roundIdx > 1 then
    if let .const prevName _ := σprev.getAppFn then
      if (succE.find? (fun sub => sub.isConstOf prevName)).isSome then
        throwFrontier m!"derive_rounds: round {roundIdx} anchored \
          successor still references {prevName} — anchoring incomplete"
  let sargs := succE.getAppArgs
  let a' : Anchor :=
    { a with cs := sargs[2]!, rs := rs', mem := sargs[4]!,
             tr := sargs[7]!, ctr := ctr' }
  return (succE, a')  -- memMat updated by emitLawRound (delta pass)

/-- Emit the anchored successor def + `_app` law equation (shared
    tail of every law-driven mint). -/
private def emitLawRound (declName : Name) (fvars : Array Expr)
    (a : Anchor) (td tid σprev lhs pf succRaw : Expr) (roundIdx : Nat)
    (cls : String) : TermElabM (MintedRound × Anchor) := do
  let glueUsed ← lastGlueUsed.get
  let (succE, a') ← anchorSucc a σprev succRaw roundIdx
  -- hypothesis mode: successor DEFS close over the value binders only
  -- (a Prop binder leaking into the spelling is caught by the
  -- emitters' fvar checks, fail-closed)
  let hpOpt ← activeHypPack.get
  let dataFVars := match hpOpt with
    | some hp => hp.valueFVars
    | none => fvars
  -- THE RESPELL BRIDGE (hyp mode): registered substitutions applied
  -- to the anchored successor are PROPOSITIONAL, so the emitted
  -- equation glues the law proof to the respelled successor through
  -- a proved congrArg chain (proveSubstEq) — the kernel never needs
  -- a non-defeq bridge. Substitution-only (no normalization): byte
  -- maps stay symbolic.
  let mut succF := succE
  let mut bridge : Option Expr := none
  if let some hp := hpOpt then
    let respelled ← hypSubstFix hp succE
    if respelled != succE then
      unless respelled.isAppOfArity ``driver_state.mk 11 do
        throwFrontier m!"derive_rounds: round {roundIdx} respelled \
          successor is not a flat record:{indentExpr respelled}"
      bridge := some (← proveSubstEq hp succE respelled)
      succF := respelled
  -- re-anchor on the spelling the def will actually carry
  let a'' ← if succF == succE then pure a' else do
    let sargs := succF.getAppArgs
    pure { a' with cs := sargs[2]!, rs := sargs[3]!, mem := sargs[4]!,
                   tr := sargs[7]!, ctr := sargs[10]! }
  -- maintain the materialized-memory twin (hyp mode, memory rounds)
  let a'' ← do
    if hpOpt.isNone || a''.mem == a.mem then pure a''
    else do
      let delta ← substGround a''.mem #[(a.mem, a.memMat)]
      let mat ← groundNorm "memMat delta" delta
      if let some hp := hpOpt then
        hp.defeqSubst.modify (·.push (a''.mem, mat))
      pure { a'' with memMat := mat }
  -- emission tail under a fresh base (phase-scoping note): the heavy
  -- calls above are self-scoped and consumed any enclosing budget
  withCurrHeartbeats do
  emitFlatDef declName dataFVars succF
    s!"Round {roundIdx} successor ({cls} class; law-minted, ANCHORED \
       — flat record over base names, the mkDr idiom mechanized). \
       {provenanceNote "derive_rounds"}"
  let succ := mkAppN (mkConst declName) dataFVars
  -- register the successor's layout-state PROJECTION as a defeq route
  -- to the materialized twin (side-condition goals quote the
  -- projection spelling, not the anchored chain)
  if let some hp := hpOpt then
    hp.defeqSubst.modify
      (·.push (← mkAppMU ``driver_state.layout_state #[succ],
               a''.memMat))
    -- the raw projection NODE form too (law-RHS spellings use
    -- Expr.proj, which is ≠ the projection-function application to
    -- the syntactic matcher)
    if let some pinfo := (← getEnv).getProjectionFnInfo?
        ``driver_state.layout_state then
      hp.defeqSubst.modify
        (·.push (Lean.mkProj ``driver_state pinfo.i succ, a''.memMat))
  let nowakeup ← mkNDactiveNowakeup lhs
  let rhs ← mkAppMU ``Prod.mk #[nowakeup, succ]
  let pf' ← match bridge with
    | none => pure pf
    | some br => do
      let (_, sTy) ← pairComponentTys lhs
      let pairLam ← withLocalDeclD `st sTy fun st => do
        mkLambdaFVars #[st] (← mkAppMU ``Prod.mk #[nowakeup, st])
      mkEqTrans pf (← mkCongrArg pairLam br)
  let eqName := declName.appendAfter "_app"
  emitThm eqName fvars (← mkEq lhs rhs) pf'
    s!"Round {roundIdx} step equation ({cls} class; proof = the Kit \
       advance-law application, side conditions rfl/decide/hyp-pack; \
       respell bridge: {bridge.isSome}). \
       {provenanceNote "derive_rounds"}"
  -- glue rounds: the pack-proved DISCOVERY equation as a named
  -- theorem (the chain assembler's hfind premise; arc-18 C3)
  let mut hfindName : Option Name := none
  if glueUsed then
    if let some hp ← activeHypPack.get then
      let hfName := declName.appendAfter "_hfind"
      let lookupE ← mkAppMU ``Lem_List.lookupBy
        #[← withLocalDeclD `x (mkConst ``Nat) fun x =>
            withLocalDeclD `y (mkConst ``Nat) fun y => do
              mkLambdaFVars #[x, y] (← mkAppM ``BEq.beq #[x, y]),
          tid,
          ← mkAppMU ``core_state.thread_states
            #[← mkAppMU ``driver_state.core_state0 #[σprev]]]
      let lookTy ← whnfU (← inferType lookupE)
      let some elemTy := lookTy.app1? ``Option
        | throwError "derive_rounds: _hfind lookup type"
      let thInfoE ← mkAppOptMU ``Option.getD
        #[some elemTy, some lookupE,
          some (← mkAppOptMU ``default #[some elemTy, none])]
      let lhsF ← mkAppMU ``find_can_advance
        #[← mkAppMU ``step_ctx
          #[td, ← mkAppMU ``driver_state.layout_state #[σprev],
            ← mkAppMU ``driver_state.core_file #[σprev],
            ← mkAppMU ``driver_state.core_extern #[σprev],
            tid, thInfoE]]
      let stepAtE ← mkAppMU ``RelSem.Laws.stepAt #[td, tid, σprev]
      let rhsF ← mkAppMU ``Option.some #[stepAtE]
      -- the payload-blind route (see option_eq_some_getD): prove
      -- isSome-ness forward through the pack (the endpoint `true`
      -- discards the verdict-substituted payload), then the getD
      -- bridge + a delta-refl cast onto the stepAt face
      let isSomeE ← mkAppMU ``Option.isSome #[lhsF]
      let pfSome ← withCurrHeartbeats
        (proveHypEq hp isSomeE (mkConst ``Bool.true))
      let blockedE := mkConst ``core_step2.Step_blocked2
      let lemmaPf ← mkAppM ``RelSem.RoundEval.option_eq_some_getD
        #[lhsF, blockedE, pfSome]
      let getDE ← mkAppMU ``Option.getD #[lhsF, blockedE]
      let someGetDE ← mkAppMU ``Option.some #[getDE]
      let castPf ← mkExpectedTypeHint (← mkEqRefl someGetDE)
        (← mkEq someGetDE rhsF)
      let pfF ← mkEqTrans lemmaPf castPf
      withCurrHeartbeats (emitThm hfName fvars (← mkEq lhsF rhsF) pfF
        s!"Round {roundIdx} pack-proved discovery equation (glue \
           round; the chain assembler's hfind premise). \
           {provenanceNote "derive_rounds"}")
      hfindName := some hfName
  return ({ succ, eqName, cls, hfindName }, a'')

/-- PURE-ROUND MINT, LAW-DRIVEN (arc-17 S2 second iteration): tau and
    runstate rounds go through their Kit advance laws exactly like
    memory rounds — the successor is the law's computed-RHS `dnmsBump`
    shape at the NAMED predecessor with only the NEW thread payload
    materialized. (The first iteration's raw-whnf mint inlined the
    whole state history: round k's body carried k thread records and
    per-round cost DOUBLED — measured 26 ms → 2.2 s by round 11,
    heartbeat wall at 12. The named-state discipline applied per
    round kills the accretion.) -/
def mintLawPure (declName : Name) (fvars : Array Expr)
    (a : Anchor) (td tid σ lhs stepE : Expr) (roundIdx : Nat) :
    TermElabM (MintedRound × Anchor) := do
  -- expose + normalize a thread payload (arena/stack are first-order
  -- data; env/errno stay as the step spelled them)
  let thNorm (th : Expr) : TermElabM Expr := do
    -- per-phase scope (arc-18 C3: the round-44 race-analyzed payload
    -- is a single whnf unit — the default budget is its own scope)
    let w ← withCurrHeartbeats (whnfU th)
    match ← activeHypPack.get with
    | some hp => hypNorm hp "thread payload" w
    | none => normalizeThreads w
  -- Payload-spelling retry (arc-17 S3): materialized-state drives
  -- (T4/T6) NEED the normalized payload (the S2 accretion lesson —
  -- verbatim payloads re-open the per-round cost doubling), while
  -- builder-state drives (free component binders) need the VERBATIM
  -- payload (pack substitution makes the normalized spelling
  -- propositionally different from the classified step's, and even
  -- `.all`/dig reductions are ones the elaborator's smart-unfolding
  -- defeq refuses to retrace — measured both ways). The law is
  -- elaborated with the normalized payload first and retried
  -- verbatim on failure.
  if stepE.isAppOfArity ``core_step2.Step_tau2 3 then
    let kindE ← whnfU stepE.getAppArgs[1]!
    -- REGISTRY DISPATCH (arc-18 C1, the R4 contract): the advance law
    -- by goal-form key at the kind-normalized step (defeq respell for
    -- the QUERY only; the proof still elaborates at the classified
    -- stepE). An unregistered tau kind is a registry-miss frontier —
    -- the old hardcoded TSK_Misc check, now the key's job.
    let stepQ := mkApp3 stepE.getAppFn (← qStar) kindE (← qStar)
    let goal0 ← mkAppMU ``RelSem.app
      #[← mkAppMU ``advance_step #[td, tid, stepE], σ]
    let law ← queryLaw `advance
      (← appGoalSkeleton goal0 #[← qStar, ← qStar, stepQ])
      (what := s!"round {roundIdx} tau advance")
    let mkStx (th : Expr) : TermElabM Term := do
      let thS ← toStxU th
      `($(mkCIdent law.name) (th' := $thS))
    let (pf, succRaw) ← (try
        elabLawChain td tid σ stepE lhs roundIdx
          (← mkStx (← thNorm stepE.getAppArgs[2]!))
      catch _ =>
        elabLawChain td tid σ stepE lhs roundIdx
          (← mkStx (← withCurrHeartbeats (whnfU stepE.getAppArgs[2]!))))
    emitLawRound declName fvars a td tid σ lhs pf succRaw roundIdx "tau"
  else if stepE.isAppOfArity ``core_step2.Step_with_runstate2 2 then
    let kindE ← whnfU stepE.getAppArgs[0]!
    trace[RelSem.roundEval] "round {roundIdx} runstate kind: {kindE}"
    let stepM := stepE.getAppArgs[1]!
    -- run the runstate step once (meta) to canonicalize its outputs
    -- (at the ANCHORED run-state component, not the projection —
    -- constant-depth evaluation)
    let rsProj := a.rs
    let resE ← (do
      try
        hypWhnfCheck "runstate result" (mkApp stepM rsProj)
          (·.isAppOfArity ``exceptM.Result 3)
      catch ex =>
        throwError "derive_rounds: round {roundIdx} runstate RESULT \
          normalization failed/timed out: {ex.toMessageData}")
    unless resE.isAppOfArity ``exceptM.Result 3 do
      throwFrontier m!"derive_rounds: round {roundIdx} runstate step \
        did not produce Result (UB/failure path — no law):{indentExpr resE}"
    let pairE ← hypWhnfCheck "runstate pair" resE.getAppArgs[2]!
      (·.isAppOfArity ``Prod.mk 4)
    unless pairE.isAppOfArity ``Prod.mk 4 do
      throwFrontier m!"derive_rounds: round {roundIdx} runstate pair \
        did not compute:{indentExpr pairE}"
    let verdictE ← hypWhnfCheck "runstate verdict" pairE.getAppArgs[2]!
      (·.isAppOfArity ``t0.Defined 2)
    unless verdictE.isAppOfArity ``t0.Defined 2 do
      throwFrontier m!"derive_rounds: round {roundIdx} runstate verdict \
        is not Defined (UB path — no law):{indentExpr verdictE}"
    let thN ← thNorm verdictE.getAppArgs[1]!
    trace[RelSem.roundEval] "round {roundIdx}: thNorm done"
    let rsN ← flattenState pairE.getAppArgs[3]!
    trace[RelSem.roundEval] "round {roundIdx}: rs flatten done"
    -- glue under a fresh base (phase-scoping note): the heavy calls
    -- above consumed whatever enclosing budget existed
    let (thS, rsS) ← withCurrHeartbeats do
      pure (← toStxU thN, ← toStxU rsN)
    trace[RelSem.roundEval] "round {roundIdx}: syntax built"
    let proofStx ← do
      -- dbg/step_m supplied EXPLICITLY (arc-17 S3): at a
      -- builder-state σ0 (free component binders) the elaborator's
      -- own stepAt unification wedges where classification's plain
      -- whnf succeeded — the mintMemRound explicit-decomposition
      -- lesson, applied to the pure branches.
      -- REGISTRY DISPATCH (arc-18 C1): the runstate advance laws
      -- share their slot names, so ONE splice serves whichever law
      -- the goal-form key selects (kind-normalized for the query;
      -- an unregistered kind is a registry-miss frontier — the old
      -- hardcoded RSK_eval/RSK_tau-Misc branch, now the key's job).
      let kindQ ← (do
        if kindE.isAppOfArity ``runstate_step_kind.RSK_tau 2 then
          let tkW ← whnfU kindE.getAppArgs[1]!
          pure (mkApp2 kindE.getAppFn (← qStar) tkW)
        else if kindE.isApp then
          pure (mkAppN kindE.getAppFn
            (← kindE.getAppArgs.mapM (fun _ => qStar)))
        else pure kindE)
      let stepQ := mkApp2 stepE.getAppFn kindQ (← qStar)
      let goal0 ← mkAppMU ``RelSem.app
        #[← mkAppMU ``advance_step #[td, tid, stepE], σ]
      let law ← queryLaw `advance
        (← appGoalSkeleton goal0 #[← qStar, ← qStar, stepQ])
        (what := s!"round {roundIdx} runstate advance")
      unless kindE.getAppNumArgs ≥ 1 do
        throwFrontier m!"derive_rounds: round {roundIdx} runstate kind \
          has no registered law:{indentExpr kindE}"
      let dbgS ← toStxU kindE.getAppArgs[0]!
      let stepmS ← toStxU stepM
      `($(mkCIdent law.name) (dbg := $dbgS)
          (step_m := $stepmS) (th' := $thS) (rs' := $rsS)
          (hm := by first | exact rfl | hyp_norm_side))
    let (pf, succRaw) ← elabLawChain td tid σ stepE lhs roundIdx proofStx
    emitLawRound declName fvars a td tid σ lhs pf succRaw roundIdx "runstate"
  else
    throwFrontier m!"derive_rounds: round {roundIdx} step class has no \
      registered law:{indentExpr stepE}"

/-- MEMOP-ROUND MINT (arc-18 C4): `Step_memop_request2`, sequential —
    the Ememop surface, first demanded by the divmod drive walk. THIN
    registry dispatcher (the engine-to-law rule): the ADVANCE and
    PERFORM laws are selected by goal form from the one registry;
    every law hypothesis discharges through the standard side triple
    (the PtrValidForDeref class's memory fact is state-preserving and
    reduces by kernel rfl at the anchored ground memory: liveness +
    alignment arithmetic). An unregistered memop shape is a
    registry-miss frontier, never an engine branch. -/
def mintMemopRound (declName : Name) (fvars : Array Expr)
    (a : Anchor) (td tid σ lhs stepE : Expr) (roundIdx : Nat) :
    TermElabM (MintedRound × Anchor) := do
  let stepArgs := stepE.getAppArgs -- loc memop cvals tid' unseq mk
  unless stepArgs.size == 6 do
    throwError "derive_rounds: Step_memop_request2 arity {stepArgs.size}"
  let unseqE ← whnfU stepArgs[4]!
  unless unseqE.isConstOf ``Bool.false do
    throwFrontier m!"derive_rounds: round {roundIdx} is an \
      unseq-with-ccall memop request (no law registered)"
  let memopE ← whnfU stepArgs[1]!
  -- the memop ctor is passed CONCRETE (its only argument is the `sym`
  -- type parameter — starring it would put a query star against the
  -- pattern's concrete key and kill the match)
  let memopQ := memopE
  -- ADVANCE law by goal form (keyed on the step head + memop ctor)
  let stepQ := mkAppN stepE.getAppFn
    #[← qStar, memopQ, ← qStar, ← qStar, unseqE, ← qStar]
  let advGoal0 ← mkAppMU ``RelSem.app
    #[← mkAppMU ``advance_step #[td, tid, stepE], σ]
  let advLaw ← queryLaw `advance
    (← appGoalSkeleton advGoal0 #[← qStar, ← qStar, stepQ])
    (what := s!"round {roundIdx} memop advance")
  -- PERFORM law by goal form (keyed on the memop ctor + the operand
  -- list's live spelling — the law patterns discriminate the arm)
  let cvalsE ← whnfU stepArgs[2]!
  let perfGoal0 ← mkAppMU ``RelSem.app
    #[← mkAppMU ``perform_memop_request2
        #[td, stepArgs[0]!, memopE, cvalsE, stepArgs[3]!, stepArgs[5]!],
      σ]
  let perfLaw ← queryLaw `perform
    (← appGoalSkeleton perfGoal0
      #[← qStar, ← qStar, memopQ, cvalsE, ← qStar, ← qStar])
    (what := s!"round {roundIdx} memop perform")
  let proofStx ← `($(mkCIdent advLaw.name)
    (hperf := $(mkCIdent perfLaw.name)
      (hmem := by first
        | exact rfl
        | decide
        -- arc-18 R6 batch 3 (the array lane): the pvfd memory fact
        -- at OPEN builder memory — liveness through the component
        -- lane, alignment left closed for the ground escape.
        | exact RelSem.Kit.mem_pvfd_block
            (by first | exact rfl | hyp_norm_side) rfl
        | hyp_norm_side)))
  let (pf, succRaw) ← elabLawChain td tid σ stepE lhs roundIdx proofStx
  emitLawRound declName fvars a td tid σ lhs pf succRaw roundIdx "memop"

/-- MEMORY-ROUND MINT: law-chain elaboration (see module header).
    `stepE` is the whnf'd `Step_action_request2` application. -/
def mintMemRound (declName : Name) (fvars : Array Expr)
    (a : Anchor) (td tid σ lhs stepE : Expr) (roundIdx : Nat) :
    TermElabM (MintedRound × Anchor) := do
  let stepArgs := stepE.getAppArgs -- dbg loc tid' unseq m_request
  unless stepArgs.size == 5 do
    throwError "derive_rounds: Step_action_request2 arity {stepArgs.size}"
  let unseqE ← whnfU stepArgs[3]!
  unless unseqE.isConstOf ``Bool.false do
    throwFrontier m!"derive_rounds: round {roundIdx} is an \
      unseq-with-ccall action request (no law registered)"
  let mReq := stepArgs[4]!
  -- The request draw (state-preserving demanded; the request-draw
  -- state change of RMW-class rounds is a frontier until its law).
  let drawLhs ← mkAppMU ``RelSem.app #[← mkAppMU ``liftCore_run #[mReq], σ]
  let drawPair ← withCurrHeartbeats (whnf drawLhs)
  unless drawPair.isAppOfArity ``Prod.mk 4 do
    throwFrontier m!"derive_rounds: round {roundIdx} request draw did \
      not compute:{indentExpr drawPair}"
  let drawHead ← whnfU drawPair.getAppArgs[2]!
  unless drawHead.isAppOf ``nd_action.NDactive do
    throwFrontier m!"derive_rounds: round {roundIdx} request draw head \
      is not NDactive:{indentExpr drawHead}"
  let σ1 := drawPair.getAppArgs[3]!
  unless (σ1 == σ) || (← isDefEq σ1 σ) do
    throwFrontier m!"derive_rounds: round {roundIdx} request draw is \
      not state-preserving (RMW-class supply draw?):{indentExpr σ1}"
  let reqE ← whnfU drawHead.getAppArgs.back!
  -- ANCHORED components: every ground computation below walks
  -- constant-depth spellings, never the predecessor chain
  let memE := a.mem
  let aidE ← evalGroundA "aid_supply" <|
    ← mkAppMU ``core_run_state.aid_supply #[a.rs]
  -- Destructure a ground pointer to (allocId, addr) literals.
  let destructPtr (ptr : Expr) : TermElabM (Expr × Expr × Expr) := do
    let ptrE ← evalGroundA s!"round {roundIdx} pointer" ptr
    let some (provE, pvbE) := ptrE.app2? ``CerbMem.PointerValue.PV
      | throwFrontier m!"derive_rounds: round {roundIdx} pointer is not \
          PV:{indentExpr ptrE}"
    let some idE := provE.app1? ``CerbMem.Provenance.Prov_some
      | throwFrontier m!"derive_rounds: round {roundIdx} pointer \
          provenance is not Prov_some:{indentExpr provE}"
    let some (umE, addrE) := pvbE.app2? ``CerbMem.PointerValueBase.PVconcrete
      | throwFrontier m!"derive_rounds: round {roundIdx} pointer base is \
          not PVconcrete:{indentExpr pvbE}"
    unless umE.isAppOf ``Option.none do
      throwFrontier m!"derive_rounds: round {roundIdx} pointer carries a \
        union-member tag (no law path):{indentExpr umE}"
    return (ptrE, idE, addrE)
  -- Ground allocation-record lookup.
  let lookupAlloc (idE : Expr) : TermElabM Expr := do
    let allocsE ← mkAppMU ``CerbMem.MemState.allocations #[memE]
    let gotE ← evalGroundA s!"round {roundIdx} allocation record" <|
      ← mkAppMU ``Std.TreeMap.get? #[allocsE, idE]
    unless gotE.isAppOfArity ``Option.some 2 do
      throwFrontier m!"derive_rounds: round {roundIdx} allocation \
          lookup did not reduce to some:{indentExpr gotE}"
    return gotE.appArg!
  let fn := reqE.getAppFn
  let .const reqCtor _ := fn
    | throwFrontier m!"derive_rounds: round {roundIdx} request head is \
        not a constructor:{indentExpr reqE}"
  -- Supply the step decomposition EXPLICITLY (mvar-free goals for the
  -- postponed side-condition tactics; the elaborator's own stepAt
  -- unfolding can postpone and starve them — measured this slice).
  let dbgS ← toStxU stepArgs[0]!
  let locS ← toStxU stepArgs[1]!
  let tid'S ← toStxU stepArgs[2]!
  let mReqS ← toStxU mReq
  let reqS ← toStxU reqE
  let σS ← toStxU σ
  -- REGISTRY DISPATCH (arc-18 C1, the R4 contract): the three law
  -- tiers of an action round — ADVANCE / PERFORM / MEM-BLOCK — each
  -- selected by goal-form key from the one registry; the per-request
  -- branches below prepare each law's declared SLOTS (ground
  -- literals, spellings — elaborator handling) and splice the
  -- QUERIED names. An unregistered request shape is a registry-miss
  -- frontier (the old hardcoded reqCtor branch, now the key's job).
  let stepQ := mkAppN stepE.getAppFn
    #[← qStar, ← qStar, ← qStar, unseqE, ← qStar]
  let advGoal0 ← mkAppMU ``RelSem.app
    #[← mkAppMU ``advance_step #[td, tid, stepE], σ]
  let advLaw ← queryLaw `advance
    (← appGoalSkeleton advGoal0 #[← qStar, ← qStar, stepQ])
    (what := s!"round {roundIdx} action advance")
  -- request-arg skeleton: concrete only where CHEAP and closed (the
  -- discriminating positions — e.g. perform_create's
  -- `initOpt = none` — are small nullary spellings); pack-stuck or
  -- large args star (the pattern side is a wildcard there anyway,
  -- and key-reduction over live spellings is the measured timeout).
  let reqQ := mkAppN reqE.getAppFn
    (← reqE.getAppArgs.mapM (fun e => do
      if e.hasFVar then qStar
      else
        let w ← whnfU e
        if (← w.numObjs) ≤ 64 then pure w else qStar))
  let perfGoal0 ← mkAppMU ``RelSem.app
    #[← mkAppMU ``perform_action_request2
        #[unseqE, stepArgs[1]!, stepArgs[2]!, reqE], σ]
  let perfLaw ← queryLaw `perform
    (← appGoalSkeleton perfGoal0 #[unseqE, ← qStar, ← qStar, reqQ])
    (what := s!"round {roundIdx} perform ({reqCtor})")
  let advS := mkCIdent advLaw.name
  let perfS := mkCIdent perfLaw.name
  -- the mem-block goal builder: typed construction from the live
  -- pieces, then the skeleton m-args + starred state
  let blockLaw (mk : TermElabM Expr) (mArgs' : Array Expr)
      (what : String) : TermElabM Ident := do
    let goal0 ← mkAppMU ``RelSem.app #[← mk, memE]
    return mkCIdent
      (← queryLaw `memBlock (← appGoalSkeleton goal0 mArgs')
        (what := what)).name
  let mut subs : Array (Expr × Expr) := #[]
  let mut pfSucc : Expr × Expr := (default, default)
  let mut cls := ""
  if reqCtor == ``action_request2.StoreRequest2 then
    -- StoreRequest2 mo ty lk ptr mval mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 5]!
    let lkW ← (let e := rargs[rargs.size - 4]!
               if e.hasFVar then pure e else whnfU e)
    let (ptrE, idE, addrE) ← destructPtr rargs[rargs.size - 3]!
    let mvalE ← evalGroundA s!"round {roundIdx} stored value"
      rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let fpmE ← evalGroundA s!"round {roundIdx} funptrmap" <|
      ← mkAppMU ``CerbMem.MemState.funptrmap #[memE]
    let bytesPairE ← evalGroundA s!"round {roundIdx} store bytes" <|
      ← mkAppMU ``CerbMem.memValueToBytes #[fpmE, mvalE]
    unless bytesPairE.isAppOfArity ``Prod.mk 4 do
      throwFrontier m!"derive_rounds: memValueToBytes did not reduce \
          to a pair:{indentExpr bytesPairE}"
    let fpmE' := bytesPairE.getAppArgs[2]!
    let bytesE := bytesPairE.getAppArgs[3]!
    let szE ← evalGroundA s!"round {roundIdx} store size" <|
      ← mkAppMU ``CerbMem.sizeofCtype #[tyE]
    -- the sizeof spelling substitution is DEFEQ only in ground mode;
    -- in hyp mode the respell bridge (emitLawRound) carries it
    if (← activeHypPack.get).isNone then
      subs := #[((← mkAppMU ``CerbMem.sizeofCtype #[tyE]), szE)]
    let blkS ← blockLaw
      (mkAppMU ``CerbMem.storeM
        #[stepArgs[1]!, tyE, lkW, ptrE, mvalE])
      #[← qStar, ← qStar, lkW, ptrE, ← qStar]
      s!"round {roundIdx} store block"
    let prefS ← blockLaw
      (mkAppMU ``CerbMem.prefixOfPointer #[ptrE])
      #[← qStar]
      s!"round {roundIdx} prefix block"
    let proofStx ← `($advS (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := $perfS
        (ptr := $(← toStxU ptrE))
        (mval := $(← toStxU mvalE))
        (hmem := $blkS
          (allocId := $(← toStxU idE))
          (addr := $(← toStxU addrE))
          (alloc := $(← toStxU allocE))
          (fpm := $(← toStxU fpmE'))
          (bytes := $(← toStxU bytesE))
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side)
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side))
        (hpref := $prefS)))
    pfSucc ← elabLawChain td tid σ stepE lhs roundIdx proofStx
    cls := "store"
  else if reqCtor == ``action_request2.CreateRequest2 then
    -- CreateRequest2 pref align ty addrOpt initOpt mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 4]!
    let initOptE ← whnfU rargs[rargs.size - 2]!
    unless initOptE.isAppOf ``Option.none do
      throwFrontier m!"derive_rounds: round {roundIdx} create carries an \
        initialisation value (no law path):{indentExpr initOptE}"
    let alignE ← evalGroundA s!"round {roundIdx} alignment"
      rargs[rargs.size - 5]!
    let some (_, alignNE) := alignE.app2? ``CerbMem.IntegerValue.IV
      | throwFrontier m!"derive_rounds: round {roundIdx} alignment is \
          not IV:{indentExpr alignE}"
    let tyS ← toStxU tyE
    let alignNS ← toStxU alignNE
    let memS ← toStxU memE
    -- The block's own arithmetic spellings (mem_alloc_block hsz/haddr),
    -- ground-evaluated to literals.
    let szE ← evalGroundA s!"round {roundIdx} create size" <|
      ← elabClosed (← `((CerbMem.sizeofCtype $tyS).max 1))
    let szS ← toStxU szE
    let aE ← evalGroundA s!"round {roundIdx} allocation address" <|
      ← elabClosed (← `(((CerbMem.alignDown
          (($memS).lastAddress - ($szS : Int)).toNat
          (($alignNS : Int).toNat.max 1) : Nat) : Int)))
    let nextIdProj ← elabClosed (← `(($memS).nextAllocId))
    let nextIdE ← evalGroundA "nextAllocId" nextIdProj
    subs := #[(nextIdProj, nextIdE)]
    let aS ← toStxU aE
    -- The mem_alloc_block haddr fact: BOTH the meta defeq and plain
    -- kernel rfl wedge on alignDown's div/mul over a compound operand
    -- chain (measured this slice: elaborator type-mismatch, then
    -- kernel deep recursion at ~65 s). The working discharge is the
    -- arc-9 fixture recipe made mechanical: rewrite the (cheap,
    -- match-forced) lastAddress projection to its literal, then
    -- kernel `decide` on the CLOSED literal arithmetic.
    let lastLitS ← toStxU
      (← evalGroundA s!"round {roundIdx} lastAddress" <|
        ← elabClosed (← `(($memS).lastAddress)))
    let haddrStmt ← elabClosed (← `((((CerbMem.alignDown
        (($memS).lastAddress - ($szS : Int)).toNat
        (($alignNS : Int).toNat.max 1) : Nat) : Int) = $aS)))
    -- the projection rewrite's witness: plain rfl at ground states;
    -- at a fenced builder ladder the elaborator's rfl is blocked and
    -- the equation routes through the pack machinery (arc-18 C3b —
    -- measured at the entry walk's create-i over the s-write ladder)
    let haddrPf ← Term.elabTermEnsuringType
      (← `((by rw [show ($memS).lastAddress = $lastLitS from
              by first | exact rfl | hyp_norm_side]; decide)))
      haddrStmt
    Term.synthesizeSyntheticMVarsNoPostponing
    let haddrPf ← instantiateMVars haddrPf
    let haddrName := declName.appendAfter "_addr"
    emitThm haddrName fvars haddrStmt haddrPf
      s!"Create-round address fact (projection rewrite + kernel \
         decide on the closed literal arithmetic). \
         {provenanceNote "derive_rounds"}"
    let haddrS ← toStxU (mkAppN (mkConst haddrName) fvars)
    let blkS ← blockLaw
      (mkAppMU ``CerbMem.allocateObject
        #[stepArgs[2]!, rargs[rargs.size - 6]!, alignE, tyE,
          rargs[rargs.size - 3]!, initOptE])
      #[← qStar, ← qStar, alignE, ← qStar, ← qStar, initOptE]
      s!"round {roundIdx} alloc block"
    let proofStx ← `($advS (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := $perfS
        (hmem := $blkS
          (sz := $szS)
          (a := $aS)
          (by first | exact rfl | decide | hyp_norm_side) $haddrS (by first | exact rfl | decide | hyp_norm_side))))
    pfSucc ← elabLawChain td tid σ stepE lhs roundIdx proofStx
    cls := "create"
  else if reqCtor == ``action_request2.LoadRequest2 then
    -- LoadRequest2 mo ty ptr mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 3]!
    let (ptrE, idE, addrE) ← destructPtr rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let szE ← evalGroundA s!"round {roundIdx} load size" <|
      ← mkAppMU ``CerbMem.sizeofCtype #[tyE]
    -- Ride the anchored MATERIALIZED twin for this round's value
    -- queries (the S2 registered load-cost item; see Anchor.memMat).
    -- The law side conditions still state the SPELLING form (memE);
    -- only the meta-computed values use the twin (defeq).
    let memMatE ← do
      if (← activeHypPack.get).isSome then pure a.memMat else pure memE
    let bytesE ← evalGroundA s!"round {roundIdx} loaded bytes" <|
      ← mkAppMU ``CerbMem.readBytesFrom #[memMatE, addrE, szE]
    let mvE ← evalGroundA s!"round {roundIdx} loaded value" <|
      ← mkAppMU ``CerbMem.reconstructValue
        #[← mkAppMU ``CerbMem.MemState.lastUsedUnionMembers #[memMatE],
          ← mkAppMU ``CerbMem.MemState.funptrmap #[memMatE],
          addrE, tyE, bytesE]
    if (← activeHypPack.get).isNone then
      subs := #[((← mkAppMU ``CerbMem.sizeofCtype #[tyE]), szE)]
    let blkS ← blockLaw
      (mkAppMU ``CerbMem.loadM #[stepArgs[1]!, tyE, ptrE])
      #[← qStar, ← qStar, ptrE]
      s!"round {roundIdx} load block"
    let prefS ← blockLaw
      (mkAppMU ``CerbMem.prefixOfPointer #[ptrE])
      #[← qStar]
      s!"round {roundIdx} prefix block"
    let proofStx ← `($advS (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := $perfS
        (ptr := $(← toStxU ptrE))
        (hmem := $blkS
          (allocId := $(← toStxU idE))
          (addr := $(← toStxU addrE))
          (alloc := $(← toStxU allocE))
          (bytes := $(← toStxU bytesE))
          (mv := $(← toStxU mvE))
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side)
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side))
        (hpref := $prefS)))
    pfSucc ← elabLawChain td tid σ stepE lhs roundIdx proofStx
    cls := "load"
  else if reqCtor == ``action_request2.KillRequest2 then
    -- KillRequest2 isDyn ptr mk
    let rargs := reqE.getAppArgs
    let isDynW ← (let e := rargs[rargs.size - 3]!
                  if e.hasFVar then pure e else whnfU e)
    let (ptrE, idE, _) ← destructPtr rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let blkS ← blockLaw
      (mkAppMU ``CerbMem.killM #[stepArgs[1]!, isDynW, ptrE])
      #[← qStar, isDynW, ptrE]
      s!"round {roundIdx} kill block"
    let proofStx ← `($advS (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := $perfS
        (ptr := $(← toStxU ptrE))
        (hmem := $blkS
          (allocId := $(← toStxU idE))
          (alloc := $(← toStxU allocE))
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side))))
    pfSucc ← elabLawChain td tid σ stepE lhs roundIdx proofStx
    cls := "kill"
  else
    throwFrontier m!"derive_rounds: round {roundIdx} request \
      `{reqCtor}` has no registered law path (SeqRMW is the S2 T4 \
      lane; Alloc/memop are registered gaps)"
  let (pf, succRaw) := pfSucc
  -- per-class ground substitutions (sizeof spellings etc.), then the
  -- shared anchored emit
  let aidProj ← mkAppMU ``core_run_state.aid_supply #[a.rs]
  let subsAll := subs.push (aidProj, aidE)
  let succSub ← substGround succRaw subsAll
  emitLawRound declName fvars a td tid σ lhs pf succSub roundIdx cls

/-! ## The terminal artifacts -/

/-- At the terminal round: `steps` must be the singleton done offer.
    Returns the offered value. -/
def terminalValue (stepsE : Expr) (roundIdx : Nat) :
    TermElabM Expr := do
  unless stepsE.isAppOfArity ``List.cons 3 do
    throwFrontier m!"derive_rounds: terminal round {roundIdx} offer \
        is not a cons:{indentExpr stepsE}"
  let hd := stepsE.getAppArgs[1]!
  let tl := stepsE.getAppArgs[2]!
  unless tl.isAppOf ``List.nil do
    throwFrontier m!"derive_rounds: terminal round {roundIdx} offers \
      more than one step:{indentExpr stepsE}"
  let some v := hd.app1? ``core_step2.Step_done2
    | throwFrontier m!"derive_rounds: terminal round {roundIdx} single \
        offer is not Step_done2:{indentExpr hd}"
  return v

end RoundEval
end RelSem
