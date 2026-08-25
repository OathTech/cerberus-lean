/-
  RelSem.RoundEval — arc-17 S2 (2026-08-25): THE LAW-DRIVEN ROUND
  EVALUATOR (the S1-registered input #1; charter S2 deliverable 1).

  WHAT THIS FIXES (measured, S1 record §4.2): minting a MEMORY round's
  successor by raw meta `whnf` allocates past the 64 G blast-radius cap
  — unfolding the byte-map's balanced-tree operations degrades DAG
  sharing. The fix is never materializing what the laws can navigate:
  memory-round successors are computed by applying the Kit
  `mem_*_block` / `perform_*` / `advance_action_request` equations
  SYMBOLICALLY — the law chain is elaborated against the round
  equation with the successor as a metavariable, so the successor
  STATE is assembled from the laws' computed-RHS shapes
  (`writeBytesTo`-form memory, named-state field references), and the
  equation is proved by the law-composition term whose leaves are
  small kernel-checked `rfl` ground facts. The kernel recomputes and
  checks everything at `addDecl` (the S0 donor contract); the meta
  layer's whnf/reduce results are never trusted, they only shape the
  recorded claim.

  *Lineage (canon-first, charter-named)*: HeapLang-ProofMode symbolic
  stepping — successor states are computed once in the meta layer and
  goals ride state NAMES (arc-16 S3 §7; the S0 `derive_state` emitter
  is the naming substrate); the per-shape dispatch consumes the
  arc-17 S1 construct-law registry and the arc-9 Kit memory blocks —
  law-application at the meta level, one registered rule per
  discovered head (the Lithium-fragment discipline, S1 record §5).

  GROUND-LITERAL DISCIPLINE (the probe-A lesson, this slice): free
  unification assigns UNREDUCED whnf leftovers to law arguments
  (giant projection cascades in alloc bases, lazy byte lists), which
  poisons every later round's side facts. So every scalar the
  successor spelling carries — addresses, allocation ids, byte lists,
  loaded values, supply counters — is ground-evaluated to a LITERAL
  at the meta level and supplied to the law explicitly; the
  elaborator then CHECKS raw-vs-literal defeq (small) instead of
  assigning raw. Residual open terms in a ground position are a
  TAGGED frontier (fail-closed — that is the env-algebra/apartness
  boundary, not a silent skip).

  Commands:

  * `derive_rounds id (bs…) using td tid from σ0 [upto N]` — the round
    LOOP: classify each round's discovered step (cheap whnf of
    `Laws.stepAt`), mint `id1`, `id2`, … named successors plus
    `idK_app` step equations (pure rounds via the S0 whnf path, memory
    rounds via the law chain), and at the TERMINAL round (done-thread
    offer) emit the whole-run artifacts: `id_chain` (the dnms run),
    `id_ndct` (the scheduler offer, via `Laws.ndct_offer1`),
    `id_fin` (the named final driver state) and `id_driver` (one
    driver2 iteration, via `Laws.driver2_done`). With `upto N` the
    loop stops after N rounds without demanding a terminal (the
    partial mode T4-class fixtures drive law-by-law from).

  House rules: no sorry, no axioms; meta code only — every emitted
  object is an ordinary kernel-checked declaration. Frontier errors
  carry the S0 `frontierTag`.
-/

import Lean
import RelSem.Machine
import RelSem.Cerberus
import RelSem.DeriveState
import RelSem.ConstructLaws
import RelSem.Kit.Round

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

/-- Per-round mint trace (class + wall ms); an instrument, off by
    default (`set_option trace.RelSem.roundEval true`). -/
initialize registerTraceClass `RelSem.roundEval

/-! ## Expr utilities -/

/-- Structure-flatten an emitted successor spelling: beta-reduce and
    reduce projection-of-constructor nodes everywhere (sharing
    preserved via `Core.transform`). This turns the law RHS's
    `(fun σm => {σm with …}) {σ with …}` composition into one flat
    record spelling whose unchanged fields are projections of the
    NAMED predecessor — the compact form the fixtures write by hand.
    Defeq-preserving by construction (beta + proj only). -/
def flattenState (e : Expr) : MetaM Expr := do
  let env ← getEnv
  Core.transform e (post := fun node => do
    -- zeta: `have`/`let` bindings from record-update elaboration
    -- (proj-of-mk collapses the duplication right back)
    if let .letE _ _ v b _ := node then
      return .visit (b.instantiate1 v)
    let node' := node.headBeta
    let fn := node'.getAppFn
    if let .const fname _ := fn then
      if let some pinfo := env.getProjectionFnInfo? fname then
        let args := node'.getAppArgs
        if pinfo.numParams < args.size then
          let major := args[pinfo.numParams]!
          let mfn := major.getAppFn
          if let .const mctor _ := mfn then
            if mctor == pinfo.ctorName then
              let margs := major.getAppArgs
              let fieldIdx := pinfo.numParams + pinfo.i
              if fieldIdx < margs.size then
                let r := mkAppN margs[fieldIdx]!
                  (args.extract (pinfo.numParams + 1) args.size)
                return .visit r
    if node' != node then return .visit node'
    return .done node')

/-- Fixpoint normalizer for first-order ground data: whnf the head,
    normalize the arguments, then RE-whnf — literal arithmetic
    (reduceNat/reduceBin) only fires once the arguments are literals,
    which plain `Meta.reduce`'s single top-down pass misses (measured
    this slice: alignDown left as an unreduced add/div tree). Stuck
    (fvar-dependent) subterms are left in place — closedness is the
    CALLER's check (`evalGround`). -/
def groundNorm (what : String) (e : Expr) : MetaM Expr := do
  -- loose bound variables (a node under a binder): not normalizable
  -- in isolation — leave in place
  if e.hasLooseBVars then return e
  let rec norm (fuel : Nat) (e : Expr) : MetaM Expr := do
    match fuel with
    | 0 => throwError "groundNorm: normalization fuel exhausted on {what}"
    | fuel + 1 =>
      -- proofs are opaque data here: normalizing them buys nothing
      -- and can be arbitrarily expensive (tree-map WF certificates)
      if ← Meta.isProof e then return e
      let e ← whnf e
      if e.isApp then
        let f := e.getAppFn
        let args ← e.getAppArgs.mapM (norm fuel)
        let e' := mkAppN f args
        let e'' ← whnf e'
        if e'' == e' then return e' else norm fuel e''
      else pure e
  withTransparency .default <| norm 512 e

/-- Ground-evaluate a small closed term to its literal normal form.
    Fail-closed: a residual free variable or metavariable means the
    value is NOT ground (an open seed reached a ground position — the
    env-algebra/apartness boundary) — tagged frontier. -/
def evalGround (what : String) (e : Expr) : TermElabM Expr := do
  let r ← groundNorm what e
  if r.hasExprMVar then
    throwFrontier m!"derive_rounds: ground evaluation of {what} left \
      metavariables:{indentExpr r}"
  if r.hasFVar then
    throwFrontier m!"derive_rounds: ground evaluation of {what} is not \
      closed — an open binder reached a ground position (env-algebra / \
      seed-apartness territory):{indentExpr r}"
  return r

/-- Elaborate a term in the current (binder) scope, synthesize and
    instantiate metavariables. -/
def elabClosed (stx : Term) : TermElabM Expr := do
  let e ← Lean.Elab.Term.elabTerm stx none
  Lean.Elab.Term.synthesizeSyntheticMVarsNoPostponing
  instantiateMVars e

/-- Post-pass substitutions on a successor spelling: replace each
    (defeq) `pattern` occurrence by its ground literal. Used for the
    supply projections (`….aid_supply`, `….nextAllocId`) and
    `sizeofCtype ty` spellings the law RHSs carry. Syntactic match
    (the patterns are exact subterms of the law instantiation). -/
def substGround (e : Expr) (subs : Array (Expr × Expr)) : CoreM Expr :=
  Core.transform e (post := fun node => do
    for (pat, lit) in subs do
      if node == pat then return .done lit
    return .done node)

/-- Ground-normalize the thread-state PAYLOADS (arena + stack) inside
    a successor spelling: raw-whnf successors carry the arena as
    unreduced context/conversion machinery (`apply_ctx …
    (convert_expr_lemFuel …)`), and each further round's step
    discovery re-forces every accreted layer — measured this slice as
    per-round cost DOUBLING (26 ms → 2.2 s by round 11, heartbeat
    wall at 12). Arenas and stacks are first-order constructor data,
    so normalizing them once per mint makes every later round's
    discovery work on materialized data. env/memory fields are
    deliberately NOT normalized (comparator closures, byte-map
    innards — the symbolic-navigation discipline). -/
def normalizeThreads (e : Expr) : MetaM Expr := do
  let count ← IO.mkRef (0 : Nat)
  let r ← Core.transform e (post := fun node => do
    if node.isAppOfArity ``thread_state.mk 7 && !node.hasLooseBVars then
      count.modify (· + 1)
      return .done (← groundNorm "thread payload" node)
    return .done node)
  trace[RelSem.roundEval] "normalizeThreads: {← count.get} thread payloads normalized"
  return r

/-! ## The anchor discipline (arc-17 S2, third iteration)

    Successor spellings must be CONSTANT-DEPTH over base names — the
    committed fixtures' `mkDr` idiom, mechanized. Law-RHS successors
    reference the predecessor CONSTANT (`dnmsBump th' (r⟨k-1⟩ …)`),
    and evaluating round k through that chain re-forces every layer:
    measured cost DOUBLED per round (classification whnf alone: 9 ms
    → 1.1 s by round 11) even with compact bodies. The fix: the loop
    tracks the driver-state COMPONNETS as exprs (thread table,
    run-state, memory, trace, counter — everything else is a fixed
    projection of the from-state), and each minted body is the flat
    11-field `driver_state.mk` record over those components. The law
    application is then elaborated AGAINST the anchored constant, one
    bounded defeq per round. -/

/-- The tracked driver-state components (each an anchored Expr). -/
structure Anchor where
  cs    : Expr  -- core_state0
  rs    : Expr  -- core_run_state0
  mem   : Expr  -- layout_state
  tr    : Expr  -- trace
  ctr   : Expr  -- dr_step_counter
  /-- fixed fields, projections of the from-state (in `driver_state`
      field order: core_file, core_extern, concurrency_state,
      fs_state0, symbolic_assoc, blocked). -/
  fixed : Array Expr

/-- Initial components: plain projections of the from-state. -/
def Anchor.init (σ0 : Expr) : TermElabM Anchor := do
  let p (f : Name) : TermElabM Expr := mkAppM f #[σ0]
  return { cs := ← p ``driver_state.core_state0,
           rs := ← p ``driver_state.core_run_state0,
           mem := ← p ``driver_state.layout_state,
           tr := ← p ``driver_state.trace,
           ctr := ← p ``driver_state.dr_step_counter,
           fixed := #[← p ``driver_state.core_file,
                      ← p ``driver_state.core_extern,
                      ← p ``driver_state.concurrency_state,
                      ← p ``driver_state.fs_state0,
                      ← p ``driver_state.symbolic_assoc,
                      ← p ``driver_state.blocked] }

/-- The projection→component substitution pairs for a predecessor. -/
def Anchor.substPairs (a : Anchor) (σprev : Expr) :
    TermElabM (Array (Expr × Expr)) := do
  let p (f : Name) : TermElabM Expr := mkAppM f #[σprev]
  return #[(← p ``driver_state.core_state0, a.cs),
           (← p ``driver_state.core_run_state0, a.rs),
           (← p ``driver_state.layout_state, a.mem),
           (← p ``driver_state.trace, a.tr),
           (← p ``driver_state.dr_step_counter, a.ctr),
           (← p ``driver_state.core_file, a.fixed[0]!),
           (← p ``driver_state.core_extern, a.fixed[1]!),
           (← p ``driver_state.concurrency_state, a.fixed[2]!),
           (← p ``driver_state.fs_state0, a.fixed[3]!),
           (← p ``driver_state.symbolic_assoc, a.fixed[4]!),
           (← p ``driver_state.blocked, a.fixed[5]!)]

/-! ## The per-round mint core -/

/-- What a minted round records. -/
structure MintedRound where
  /-- The successor constant (fully applied to the loop binders). -/
  succ : Expr
  /-- The step-equation constant name (`…_app`). -/
  eqName : Name
  /-- Round class, for the summary line (trace-format §3.3 level 1). -/
  cls : String
  deriving Inhabited

/-- Shared declaration emitter: `def name bs := value` (abbrev hints +
    realizations, like the S0 emitter) plus optionally nothing else. -/
private def emitFlatDef (declName : Name) (fvars : Array Expr)
    (value : Expr) (doc : String) : TermElabM Unit := do
  let type ← mkForallFVars fvars (← inferType value)
  let val ← mkLambdaFVars fvars value
  if type.hasExprMVar || val.hasExprMVar then
    throwError "derive_rounds: emitted {declName} has metavariables"
  if type.hasSorry || val.hasSorry then
    throwError "derive_rounds: emitted {declName} contains sorry"
  -- Plain addDecl, no compilation: round successors are PROOF-LAYER
  -- names (never executed); compiling a store round's continuation
  -- closure hit the LCNF heartbeat budget (measured this slice) and
  -- buys nothing. (The S0 derive_state keeps addAndCompile for the
  -- exe-referenced fixture states — different consumers.)
  try
    addDecl <| .defnDecl
      { name := declName, levelParams := [], type, value := val,
        hints := .abbrev, safety := .safe }
  catch ex =>
    throwError "derive_rounds: addDecl of {declName} FAILED: {ex.toMessageData}"
  enableRealizationsForConst declName
  addDocStringCore declName doc

private def emitThm (thmName : Name) (fvars : Array Expr)
    (stmt proof : Expr) (doc : String) : TermElabM Unit := do
  let type ← mkForallFVars fvars stmt
  let value ← mkLambdaFVars fvars proof
  if type.hasExprMVar || value.hasExprMVar then
    throwError "derive_rounds: emitted {thmName} has metavariables"
  -- fail-closed: a failed postponed tactic inside an elaborated law
  -- chain surfaces as sorryAx — never let it reach addDecl
  if type.hasSorry || value.hasSorry then
    throwError "derive_rounds: emitted {thmName} contains sorry (a \
      side condition failed — see the errors above)"
  try
    addDecl <| .thmDecl { name := thmName, levelParams := [], type, value }
  catch ex =>
    throwError "derive_rounds: addDecl of {thmName} FAILED: {ex.toMessageData}"
  addDocStringCore thmName doc

/-- Emit a kernel-certified ground fact `∀ bs, stmt` with proof
    `Eq.refl rhs`: the KERNEL's defeq (which forces literal operands of
    accelerated Nat/Int ops) certifies what the elaborator's lazy defeq
    wedges on (measured this slice: alignDown's div/mul over compound
    literal arguments). The donor recompute-and-check contract, taken
    to the kernel. -/
private def emitKernelFact (factName : Name) (fvars : Array Expr)
    (stmt rhs : Expr) (doc : String) : TermElabM Unit := do
  let type ← mkForallFVars fvars stmt
  let value ← mkLambdaFVars fvars (← mkEqRefl rhs)
  if type.hasExprMVar || value.hasExprMVar || type.hasSorry then
    throwError "derive_rounds: emitted fact {factName} is not closed"
  try
    addDecl <| .thmDecl { name := factName, levelParams := [], type, value }
  catch ex =>
    throwError "derive_rounds: addDecl of {factName} FAILED: {ex.toMessageData}"
  addDocStringCore factName doc

/-- Build `app (advance_step td tid (Laws.stepAt td tid σ)) σ`. -/
private def mkRoundLhs (td tid σ : Expr) : TermElabM Expr := do
  let stepAtE ← mkAppM ``RelSem.Laws.stepAt #[td, tid, σ]
  let advE ← mkAppM ``advance_step #[td, tid, stepAtE]
  mkAppM ``RelSem.app #[advE, σ]

/-- The action/state component types of `app m σ`'s pair type. -/
private def pairComponentTys (lhs : Expr) : TermElabM (Expr × Expr) := do
  let pairTy ← whnf (← inferType lhs)
  let some (aTy, sTy) := pairTy.app2? ``Prod
    | throwError "derive_rounds: `app` type is not a pair:{indentExpr pairTy}"
  return (aTy, sTy)

/-- `NDactive NOWAKEUP` at the action type of `app m σ` (the
    `nd_action` phantom parameters are read off the pair type). -/
private def mkNDactiveNowakeup (lhs : Expr) : TermElabM Expr := do
  let (aTy, _) ← pairComponentTys lhs
  let aTyW ← whnf aTy
  unless aTyW.isAppOfArity ``nd_action 5 do
    throwError "derive_rounds: action type is not nd_action:{indentExpr aTyW}"
  let ps := aTyW.getAppArgs
  mkAppOptM ``nd_action.NDactive
    #[some ps[0]!, some ps[1]!, some ps[2]!, some ps[3]!, some ps[4]!,
      some (mkConst ``advance_info.NOWAKEUP)]

/-- Elaborate a law-chain proof against the round equation with the
    successor a METAVARIABLE and return (proof, raw successor). The
    raw successor (the law's computed-RHS shape at the predecessor
    name) is then ANCHORED by `anchorSucc`. -/
private def elabLawChain (lhs : Expr) (roundIdx : Nat)
    (proofStx : Term) : TermElabM (Expr × Expr) := do
  let (_, sTy) ← pairComponentTys lhs
  let succMVar ← mkFreshExprMVar (some sTy)
  let nowakeup ← mkNDactiveNowakeup lhs
  let rhs ← mkAppM ``Prod.mk #[nowakeup, succMVar]
  let eqTy ← mkEq lhs rhs
  let pf ← Term.elabTermEnsuringType proofStx eqTy
  Term.synthesizeSyntheticMVarsNoPostponing
  let pf ← instantiateMVars pf
  if pf.hasSorry then
    throwError "derive_rounds: round {roundIdx} law-chain elaboration \
      produced sorry (a side condition failed — see the errors above)"
  let succ ← instantiateMVars succMVar
  if succ.hasExprMVar then
    throwError "derive_rounds: round {roundIdx} successor still has \
      metavariables after law elaboration"
  return (pf, succ)

/-- Unfold definition heads (dnmsBump and friends) until the record
    constructor is exposed (bounded; beta after each unfold). -/
private def unfoldToRecord (e : Expr) : TermElabM Expr := do
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
  let s1 ← flattenState (← unfoldToRecord succRaw)
  let s2 ← substGround s1 (← a.substPairs σprev)
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
    let rsW ← flattenState (← whnf args[3]!)
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
  return (succE, a')

/-- Emit the anchored successor def + `_app` law equation (shared
    tail of every law-driven mint). -/
private def emitLawRound (declName : Name) (fvars : Array Expr)
    (a : Anchor) (σprev lhs pf succRaw : Expr) (roundIdx : Nat)
    (cls : String) : TermElabM (MintedRound × Anchor) := do
  let (succE, a') ← anchorSucc a σprev succRaw roundIdx
  emitFlatDef declName fvars succE
    s!"Round {roundIdx} successor ({cls} class; law-minted, ANCHORED \
       — flat record over base names, the mkDr idiom mechanized). \
       {provenanceNote "derive_rounds"}"
  let succ := mkAppN (mkConst declName) fvars
  let nowakeup ← mkNDactiveNowakeup lhs
  let rhs ← mkAppM ``Prod.mk #[nowakeup, succ]
  let eqName := declName.appendAfter "_app"
  emitThm eqName fvars (← mkEq lhs rhs) pf
    s!"Round {roundIdx} step equation ({cls} class; proof = the Kit \
       advance-law application, side conditions rfl/decide). \
       {provenanceNote "derive_rounds"}"
  return ({ succ, eqName, cls }, a')

/-- PURE-ROUND MINT, LAW-DRIVEN (arc-17 S2 second iteration): tau and
    runstate rounds go through their Kit advance laws exactly like
    memory rounds — the successor is the law's computed-RHS `dnmsBump`
    shape at the NAMED predecessor with only the NEW thread payload
    materialized. (The first iteration's raw-whnf mint inlined the
    whole state history: round k's body carried k thread records and
    per-round cost DOUBLED — measured 26 ms → 2.2 s by round 11,
    heartbeat wall at 12. The named-state discipline applied per
    round kills the accretion.) -/
private def mintLawPure (declName : Name) (fvars : Array Expr)
    (a : Anchor) (σ lhs stepE : Expr) (roundIdx : Nat) :
    TermElabM (MintedRound × Anchor) := do
  -- expose + normalize a thread payload (arena/stack are first-order
  -- data; env/errno stay as the step spelled them)
  let thNorm (th : Expr) : TermElabM Expr := do
    normalizeThreads (← whnf th)
  if stepE.isAppOfArity ``core_step2.Step_tau2 3 then
    let kindE ← whnf stepE.getAppArgs[1]!
    unless kindE.isConstOf ``core_tau_step_kind.TSK_Misc do
      throwFrontier m!"derive_rounds: round {roundIdx} tau kind has no \
        registered law:{indentExpr kindE}"
    let thS ← Term.exprToSyntax (← thNorm stepE.getAppArgs[2]!)
    let proofStx ← `(RelSem.Kit.advance_tau_misc (th' := $thS))
    let (pf, succRaw) ← elabLawChain lhs roundIdx proofStx
    emitLawRound declName fvars a σ lhs pf succRaw roundIdx "tau"
  else if stepE.isAppOfArity ``core_step2.Step_with_runstate2 2 then
    let kindE ← whnf stepE.getAppArgs[0]!
    let stepM := stepE.getAppArgs[1]!
    -- run the runstate step once (meta) to canonicalize its outputs
    -- (at the ANCHORED run-state component, not the projection —
    -- constant-depth evaluation)
    let rsProj := a.rs
    let resE ← whnf (mkApp stepM rsProj)
    unless resE.isAppOfArity ``exceptM.Result 3 do
      throwFrontier m!"derive_rounds: round {roundIdx} runstate step \
        did not produce Result (UB/failure path — no law):{indentExpr resE}"
    let pairE ← whnf resE.getAppArgs[2]!
    unless pairE.isAppOfArity ``Prod.mk 4 do
      throwFrontier m!"derive_rounds: round {roundIdx} runstate pair \
        did not compute:{indentExpr pairE}"
    let verdictE ← whnf pairE.getAppArgs[2]!
    unless verdictE.isAppOfArity ``t0.Defined 2 do
      throwFrontier m!"derive_rounds: round {roundIdx} runstate verdict \
        is not Defined (UB path — no law):{indentExpr verdictE}"
    let thS ← Term.exprToSyntax (← thNorm verdictE.getAppArgs[1]!)
    let rsS ← Term.exprToSyntax (← flattenState pairE.getAppArgs[3]!)
    let proofStx ←
      if kindE.isAppOfArity ``runstate_step_kind.RSK_eval 1 then
        `(RelSem.Kit.advance_runstate_eval (th' := $thS) (rs' := $rsS)
            (hm := by exact rfl))
      else if kindE.isAppOfArity ``runstate_step_kind.RSK_tau 2 then do
        let tkE ← whnf kindE.getAppArgs[1]!
        unless tkE.isConstOf ``core_tau_step_kind.TSK_Misc do
          throwFrontier m!"derive_rounds: round {roundIdx} RSK_tau kind \
            has no registered law:{indentExpr tkE}"
        `(RelSem.Kit.advance_runstate_tau_misc (th' := $thS)
            (rs' := $rsS) (hm := by exact rfl))
      else
        throwFrontier m!"derive_rounds: round {roundIdx} runstate kind \
          has no registered law:{indentExpr kindE}"
    let (pf, succRaw) ← elabLawChain lhs roundIdx proofStx
    emitLawRound declName fvars a σ lhs pf succRaw roundIdx "runstate"
  else
    throwFrontier m!"derive_rounds: round {roundIdx} step class has no \
      registered law:{indentExpr stepE}"

/-- MEMORY-ROUND MINT: law-chain elaboration (see module header).
    `stepE` is the whnf'd `Step_action_request2` application. -/
private def mintMemRound (declName : Name) (fvars : Array Expr)
    (a : Anchor) (td tid σ lhs stepE : Expr) (roundIdx : Nat) :
    TermElabM (MintedRound × Anchor) := do
  let stepArgs := stepE.getAppArgs -- dbg loc tid' unseq m_request
  unless stepArgs.size == 5 do
    throwError "derive_rounds: Step_action_request2 arity {stepArgs.size}"
  let unseqE ← whnf stepArgs[3]!
  unless unseqE.isConstOf ``Bool.false do
    throwFrontier m!"derive_rounds: round {roundIdx} is an \
      unseq-with-ccall action request (no law registered)"
  let mReq := stepArgs[4]!
  -- The request draw (state-preserving demanded; the request-draw
  -- state change of RMW-class rounds is a frontier until its law).
  let drawLhs ← mkAppM ``RelSem.app #[← mkAppM ``liftCore_run #[mReq], σ]
  let drawPair ← whnf drawLhs
  unless drawPair.isAppOfArity ``Prod.mk 4 do
    throwFrontier m!"derive_rounds: round {roundIdx} request draw did \
      not compute:{indentExpr drawPair}"
  let drawHead ← whnf drawPair.getAppArgs[2]!
  unless drawHead.isAppOf ``nd_action.NDactive do
    throwFrontier m!"derive_rounds: round {roundIdx} request draw head \
      is not NDactive:{indentExpr drawHead}"
  let σ1 := drawPair.getAppArgs[3]!
  unless (σ1 == σ) || (← isDefEq σ1 σ) do
    throwFrontier m!"derive_rounds: round {roundIdx} request draw is \
      not state-preserving (RMW-class supply draw?):{indentExpr σ1}"
  let reqE ← whnf drawHead.getAppArgs.back!
  -- ANCHORED components: every ground computation below walks
  -- constant-depth spellings, never the predecessor chain
  let memE := a.mem
  let aidE ← evalGround "aid_supply" <|
    ← mkAppM ``core_run_state.aid_supply #[a.rs]
  -- Destructure a ground pointer to (allocId, addr) literals.
  let destructPtr (ptr : Expr) : TermElabM (Expr × Expr × Expr) := do
    let ptrE ← evalGround s!"round {roundIdx} pointer" ptr
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
    let allocsE ← mkAppM ``CerbMem.MemState.allocations #[memE]
    let gotE ← evalGround s!"round {roundIdx} allocation record" <|
      ← mkAppM ``Std.TreeMap.get? #[allocsE, idE]
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
  let dbgS ← Term.exprToSyntax stepArgs[0]!
  let locS ← Term.exprToSyntax stepArgs[1]!
  let tid'S ← Term.exprToSyntax stepArgs[2]!
  let mReqS ← Term.exprToSyntax mReq
  let reqS ← Term.exprToSyntax reqE
  let σS ← Term.exprToSyntax σ
  let mut subs : Array (Expr × Expr) := #[]
  let mut pfSucc : Expr × Expr := (default, default)
  let mut cls := ""
  if reqCtor == ``action_request2.StoreRequest2 then
    -- StoreRequest2 mo ty lk ptr mval mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 5]!
    let (ptrE, idE, addrE) ← destructPtr rargs[rargs.size - 3]!
    let mvalE ← evalGround s!"round {roundIdx} stored value"
      rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let fpmE ← evalGround s!"round {roundIdx} funptrmap" <|
      ← mkAppM ``CerbMem.MemState.funptrmap #[memE]
    let bytesPairE ← evalGround s!"round {roundIdx} store bytes" <|
      ← mkAppM ``CerbMem.memValueToBytes #[fpmE, mvalE]
    unless bytesPairE.isAppOfArity ``Prod.mk 4 do
      throwFrontier m!"derive_rounds: memValueToBytes did not reduce \
          to a pair:{indentExpr bytesPairE}"
    let fpmE' := bytesPairE.getAppArgs[2]!
    let bytesE := bytesPairE.getAppArgs[3]!
    let szE ← evalGround s!"round {roundIdx} store size" <|
      ← mkAppM ``CerbMem.sizeofCtype #[tyE]
    subs := #[((← mkAppM ``CerbMem.sizeofCtype #[tyE]), szE)]
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by exact rfl)
      (hperf := RelSem.Kit.perform_store
        (ptr := $(← Term.exprToSyntax ptrE))
        (mval := $(← Term.exprToSyntax mvalE))
        (hmem := RelSem.Kit.mem_store_block
          (allocId := $(← Term.exprToSyntax idE))
          (addr := $(← Term.exprToSyntax addrE))
          (alloc := $(← Term.exprToSyntax allocE))
          (fpm := $(← Term.exprToSyntax fpmE'))
          (bytes := $(← Term.exprToSyntax bytesE))
          (by first | exact rfl | decide) (by first | exact rfl | decide) (by first | exact rfl | decide) (by first | exact rfl | decide)
          (by first | exact rfl | decide) (by first | exact rfl | decide))
        (hpref := RelSem.Kit.mem_prefix_block)))
    pfSucc ← elabLawChain lhs roundIdx proofStx
    cls := "store"
  else if reqCtor == ``action_request2.CreateRequest2 then
    -- CreateRequest2 pref align ty addrOpt initOpt mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 4]!
    let initOptE ← whnf rargs[rargs.size - 2]!
    unless initOptE.isAppOf ``Option.none do
      throwFrontier m!"derive_rounds: round {roundIdx} create carries an \
        initialisation value (no law path):{indentExpr initOptE}"
    let alignE ← evalGround s!"round {roundIdx} alignment"
      rargs[rargs.size - 5]!
    let some (_, alignNE) := alignE.app2? ``CerbMem.IntegerValue.IV
      | throwFrontier m!"derive_rounds: round {roundIdx} alignment is \
          not IV:{indentExpr alignE}"
    let tyS ← Term.exprToSyntax tyE
    let alignNS ← Term.exprToSyntax alignNE
    let memS ← Term.exprToSyntax memE
    -- The block's own arithmetic spellings (mem_alloc_block hsz/haddr),
    -- ground-evaluated to literals.
    let szE ← evalGround s!"round {roundIdx} create size" <|
      ← elabClosed (← `((CerbMem.sizeofCtype $tyS).max 1))
    let szS ← Term.exprToSyntax szE
    let aE ← evalGround s!"round {roundIdx} allocation address" <|
      ← elabClosed (← `(((CerbMem.alignDown
          (($memS).lastAddress - ($szS : Int)).toNat
          (($alignNS : Int).toNat.max 1) : Nat) : Int)))
    let nextIdProj ← elabClosed (← `(($memS).nextAllocId))
    let nextIdE ← evalGround "nextAllocId" nextIdProj
    subs := #[(nextIdProj, nextIdE)]
    let aS ← Term.exprToSyntax aE
    -- The mem_alloc_block haddr fact: BOTH the meta defeq and plain
    -- kernel rfl wedge on alignDown's div/mul over a compound operand
    -- chain (measured this slice: elaborator type-mismatch, then
    -- kernel deep recursion at ~65 s). The working discharge is the
    -- arc-9 fixture recipe made mechanical: rewrite the (cheap,
    -- match-forced) lastAddress projection to its literal, then
    -- kernel `decide` on the CLOSED literal arithmetic.
    let lastLitS ← Term.exprToSyntax
      (← evalGround s!"round {roundIdx} lastAddress" <|
        ← elabClosed (← `(($memS).lastAddress)))
    let haddrStmt ← elabClosed (← `((((CerbMem.alignDown
        (($memS).lastAddress - ($szS : Int)).toNat
        (($alignNS : Int).toNat.max 1) : Nat) : Int) = $aS)))
    let haddrPf ← Term.elabTermEnsuringType
      (← `((by rw [show ($memS).lastAddress = $lastLitS from rfl]; decide)))
      haddrStmt
    Term.synthesizeSyntheticMVarsNoPostponing
    let haddrPf ← instantiateMVars haddrPf
    let haddrName := declName.appendAfter "_addr"
    emitThm haddrName fvars haddrStmt haddrPf
      s!"Create-round address fact (projection rewrite + kernel \
         decide on the closed literal arithmetic). \
         {provenanceNote "derive_rounds"}"
    let haddrS ← Term.exprToSyntax (mkAppN (mkConst haddrName) fvars)
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by exact rfl)
      (hperf := RelSem.Kit.perform_create
        (hmem := RelSem.Kit.mem_alloc_block
          (sz := $szS)
          (a := $aS)
          (by first | exact rfl | decide) $haddrS (by first | exact rfl | decide))))
    pfSucc ← elabLawChain lhs roundIdx proofStx
    cls := "create"
  else if reqCtor == ``action_request2.LoadRequest2 then
    -- LoadRequest2 mo ty ptr mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 3]!
    let (ptrE, idE, addrE) ← destructPtr rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let szE ← evalGround s!"round {roundIdx} load size" <|
      ← mkAppM ``CerbMem.sizeofCtype #[tyE]
    let bytesE ← evalGround s!"round {roundIdx} loaded bytes" <|
      ← mkAppM ``CerbMem.readBytesFrom #[memE, addrE, szE]
    let mvE ← evalGround s!"round {roundIdx} loaded value" <|
      ← mkAppM ``CerbMem.reconstructValue
        #[← mkAppM ``CerbMem.MemState.lastUsedUnionMembers #[memE],
          ← mkAppM ``CerbMem.MemState.funptrmap #[memE],
          addrE, tyE, bytesE]
    subs := #[((← mkAppM ``CerbMem.sizeofCtype #[tyE]), szE)]
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by exact rfl)
      (hperf := RelSem.Kit.perform_load
        (ptr := $(← Term.exprToSyntax ptrE))
        (hmem := RelSem.Kit.mem_load_block
          (allocId := $(← Term.exprToSyntax idE))
          (addr := $(← Term.exprToSyntax addrE))
          (alloc := $(← Term.exprToSyntax allocE))
          (bytes := $(← Term.exprToSyntax bytesE))
          (mv := $(← Term.exprToSyntax mvE))
          (by first | exact rfl | decide) (by first | exact rfl | decide) (by first | exact rfl | decide) (by first | exact rfl | decide)
          (by first | exact rfl | decide) (by first | exact rfl | decide) (by first | exact rfl | decide))
        (hpref := RelSem.Kit.mem_prefix_block)))
    pfSucc ← elabLawChain lhs roundIdx proofStx
    cls := "load"
  else if reqCtor == ``action_request2.KillRequest2 then
    -- KillRequest2 isDyn ptr mk
    let rargs := reqE.getAppArgs
    let (ptrE, idE, _) ← destructPtr rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by exact rfl)
      (hperf := RelSem.Kit.perform_kill
        (ptr := $(← Term.exprToSyntax ptrE))
        (hmem := RelSem.Kit.mem_kill_block
          (allocId := $(← Term.exprToSyntax idE))
          (alloc := $(← Term.exprToSyntax allocE))
          (by first | exact rfl | decide) (by first | exact rfl | decide) (by first | exact rfl | decide))))
    pfSucc ← elabLawChain lhs roundIdx proofStx
    cls := "kill"
  else
    throwFrontier m!"derive_rounds: round {roundIdx} request \
      `{reqCtor}` has no registered law path (SeqRMW is the S2 T4 \
      lane; Alloc/memop are registered gaps)"
  let (pf, succRaw) := pfSucc
  -- per-class ground substitutions (sizeof spellings etc.), then the
  -- shared anchored emit
  let aidProj ← mkAppM ``core_run_state.aid_supply #[a.rs]
  let subsAll := subs.push (aidProj, aidE)
  let succSub ← substGround succRaw subsAll
  emitLawRound declName fvars a σ lhs pf succSub roundIdx cls

/-! ## The terminal artifacts -/

/-- At the terminal round: `steps` must be the singleton done offer.
    Returns the offered value. -/
private def terminalValue (stepsE : Expr) (roundIdx : Nat) :
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

/-! ## The loop command -/

/-- `derive_rounds id (bs…) using td tid from σ0 [upto N]` — see the
    module header. -/
syntax roundsUpto := " upto " num

elab "derive_rounds " id:ident bs:bracketedBinder* " using " td:term:max tid:term:max " from " σ0:term upto:(roundsUpto)? : command => do
  let ns ← getCurrNamespace
  let baseName := ns ++ id.getId
  let maxRounds := match upto with
    | some u => (u.raw[1].isNatLit?).getD 256
    | none => 256
  let demandTerminal := upto.isNone
  runTermElabM fun _ => do
    Term.elabBinders bs fun fvars => do
      let tdE ← Term.elabTerm td none
      let tidE ← Term.elabTerm tid (some (mkConst ``Nat))
      let σ0E ← Term.elabTerm σ0 none
      Term.synthesizeSyntheticMVarsNoPostponing
      let tdE ← instantiateMVars tdE
      let tidE ← instantiateMVars tidE
      let σ0E ← instantiateMVars σ0E
      let tdS ← Term.exprToSyntax tdE
      let tidS ← Term.exprToSyntax tidE
      let mut σ := σ0E
      let mut anchor ← Anchor.init σ0E
      let mut rounds : Array MintedRound := #[]
      let mut terminal : Option Expr := none  -- the offered steps list
      -- One round's mint, under its OWN default heartbeat budget
      -- (`withCurrHeartbeats`): the loop is sugar for one command per
      -- round, and a shared per-command budget would make capacity
      -- depend on how many rounds a program happens to run — NOT a
      -- budget raise (each unit keeps the default; a single round
      -- exceeding it still fails loudly).
      let mintOne := fun (k : Nat) (σ : Expr) (anchor : Anchor) =>
        withCurrHeartbeats (do
        let t0 ← IO.monoMsNow
        let stepAtE ← mkAppM ``RelSem.Laws.stepAt #[tdE, tidE, σ]
        let stepE ← whnf stepAtE
        trace[RelSem.roundEval] "round {k}: classify {(← IO.monoMsNow) - t0} ms"
        let declName := baseName.appendAfter (toString k)
        if stepE.isAppOf ``core_step2.Step_action_request2 then
          let lhs ← mkRoundLhs tdE tidE σ
          let (r, a') ← mintMemRound declName fvars anchor tdE tidE σ lhs stepE k
          trace[RelSem.roundEval] "round {k}: {r.cls} ({(← IO.monoMsNow) - t0} ms)"
          return Sum.inl (r, a')
        else if stepE.isAppOf ``core_step2.Step_blocked2 then
          -- No advancing step: the terminal offer (or a genuine block).
          let σS ← Term.exprToSyntax σ
          let stepsE ← evalGround s!"terminal offer (round {k})" <|
            ← elabClosed (← `(step_ctx $tdS
              (driver_state.layout_state $σS)
              (driver_state.core_file $σS)
              (driver_state.core_extern $σS) $tidS
              ((Lem_List.lookupBy (fun (x y : Nat) => x == y) $tidS
                (core_state.thread_states
                  (driver_state.core_state0 $σS))).getD default)))
          return Sum.inr stepsE
        else
          let lhs ← mkRoundLhs tdE tidE σ
          let (r, a') ← mintLawPure declName fvars anchor σ lhs stepE k
          trace[RelSem.roundEval] "round {k}: {r.cls} ({(← IO.monoMsNow) - t0} ms)"
          return Sum.inl (r, a') :
          TermElabM (Sum (MintedRound × Anchor) Expr))
      for k in [1 : maxRounds + 1] do
        match ← mintOne k σ anchor with
        | .inl (r, a') =>
          rounds := rounds.push r
          σ := r.succ
          anchor := a'
        | .inr stepsE =>
          terminal := some stepsE
          break
      let classes := rounds.map (·.cls)
      logInfo m!"derive_rounds {baseName}: {rounds.size} advancing \
        rounds minted; classes: {classes}"
      match terminal with
      | none =>
        if demandTerminal then
          throwFrontier m!"derive_rounds: no terminal within \
            {maxRounds} rounds (partial mode requires `upto`)"
      | some stepsE => withCurrHeartbeats do
        -- The whole-run chain, the scheduler offer, the driver
        -- iteration (own budget scope, same rationale as per-round).
        let n := rounds.size
        let vE ← terminalValue stepsE n
        let accS ← `(fmapEmpty)
        let σ0S ← Term.exprToSyntax σ0E
        let stepsS ← Term.exprToSyntax stepsE
        -- chain statement:
        --   app (dnms lemDefaultFuel td fmapEmpty [tid]) σ0
        --     = (NDactive (fmapAddBy defaultCompare tid steps fmapEmpty),
        --        rN)
        let succS ← Term.exprToSyntax σ  -- final advancing state (rN)
        let chainStmtStx ← `(RelSem.app
          (drive_nonmemory_steps_aux2_lemFuel lemDefaultFuel $tdS
            $accS [$tidS]) $σ0S
          = (NDactive (fmapAddBy defaultCompare $tidS $stepsS fmapEmpty),
             $succS))
        -- chain proof: dnms_round per round (descending fuel literals),
        -- dnms_terminal at the end.
        let fuel0E ← withTransparency .all <|
          whnf (← evalGround "lemDefaultFuel" (mkConst ``lemDefaultFuel))
        let some fuel0 := fuel0E.rawNatLit? <|> fuel0E.nat?
          | throwError "derive_rounds: lemDefaultFuel did not reduce to \
              a literal:{indentExpr fuel0E}"
        let mut proofStx : Term ← do
          let fS := Syntax.mkNatLit (fuel0 - n)
          let f2S := Syntax.mkNatLit (fuel0 - n - 2)
          `(RelSem.Kit.dnms_terminal (fuelS := $fS) (fuel := $f2S)
              (steps := $stepsS) rfl rfl rfl rfl)
        for i in [0 : n] do
          let k := n - 1 - i
          let fS := Syntax.mkNatLit (fuel0 - k)
          let f1S := Syntax.mkNatLit (fuel0 - k - 1)
          let hadvS ← Term.exprToSyntax
            (mkAppN (mkConst rounds[k]!.eqName) fvars)
          proofStx ← `((RelSem.Kit.dnms_round (fuelS := $fS)
            (fuel := $f1S) rfl rfl rfl rfl $hadvS).trans $proofStx)
        let chainStmt ← Term.elabType chainStmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let chainStmt ← instantiateMVars chainStmt
        let chainPf ← Term.elabTermEnsuringType proofStx chainStmt
        Term.synthesizeSyntheticMVarsNoPostponing
        let chainName := baseName.appendAfter "_chain"
        emitThm chainName fvars chainStmt (← instantiateMVars chainPf)
          s!"The whole dnms run ({n} law/mint rounds + terminal). \
             {provenanceNote "derive_rounds"}"
        -- scheduler offer via ndct_offer1
        let vS ← Term.exprToSyntax vE
        let chainS ← Term.exprToSyntax (mkAppN (mkConst chainName) fvars)
        let ndctStmtStx ← `(RelSem.app
          (new_drive_core_threads $tdS ()) $σ0S
          = (NDactive [($tidS, some (Step_done2 $vS))], $succS))
        let ndctPfStx ← `(RelSem.Laws.ndct_offer1 rfl $chainS)
        let ndctStmt ← Term.elabType ndctStmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let ndctPf ← Term.elabTermEnsuringType ndctPfStx
          (← instantiateMVars ndctStmt)
        Term.synthesizeSyntheticMVarsNoPostponing
        let ndctName := baseName.appendAfter "_ndct"
        emitThm ndctName fvars (← instantiateMVars ndctStmt)
          (← instantiateMVars ndctPf)
          s!"The scheduler sees exactly the done offer (via \
             Laws.ndct_offer1). {provenanceNote "derive_rounds"}"
        -- final driver state + one driver2 iteration via driver2_done
        let finStx ← `({ $succS with
          core_state0 := prepare_exit
            (driver_state.core_state0 $succS) $vS })
        let finE ← Term.elabTerm finStx none
        Term.synthesizeSyntheticMVarsNoPostponing
        let finName := baseName.appendAfter "_fin"
        emitFlatDef finName fvars (← instantiateMVars finE)
          s!"The final driver state (post prepare_exit). \
             {provenanceNote "derive_rounds"}"
        let finS ← Term.exprToSyntax (mkAppN (mkConst finName) fvars)
        let ndctS ← Term.exprToSyntax (mkAppN (mkConst ndctName) fvars)
        let fm1S := Syntax.mkNatLit (fuel0 - 1)
        let drvStmtStx ← `(RelSem.app (driver2 $tdS false) $σ0S
          = (NDactive (), $finS))
        let drvPfStx ← `(RelSem.Laws.driver2_done (fuel := $fm1S)
          $ndctS rfl)
        let drvStmt ← Term.elabType drvStmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let drvPf ← Term.elabTermEnsuringType drvPfStx
          (← instantiateMVars drvStmt)
        Term.synthesizeSyntheticMVarsNoPostponing
        let drvName := baseName.appendAfter "_driver"
        emitThm drvName fvars (← instantiateMVars drvStmt)
          (← instantiateMVars drvPf)
          s!"One driver2 iteration is the whole run (via \
             Laws.driver2_done). {provenanceNote "derive_rounds"}"
        logInfo m!"derive_rounds {baseName}: terminal reached after \
          {n} rounds; emitted {chainName}, {ndctName}, {finName}, \
          {drvName}"

end RoundEval
end RelSem
