/-
  RelSem.RoundEval.Mint — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: MINTING PRIMITIVES — the anchor discipline (Anchor:
  constant-depth successor spellings over tracked driver-state
  components) and the kernel-facing emitters (emitFlatDef/emitThm/
  emitKernelFact: fail-closed addDecl with mvar/fvar/sorry checks and
  failure localization). The kernel recomputes and checks everything
  emitted here (the S0 donor contract); the meta layer only shapes
  claims.

  Split from RoundEval.lean; code carried VERBATIM apart from
  `private` removed on the emitters (now consumed by the lane and
  assembly modules).

  House rules: no sorry, no axioms; meta code only.
-/
import RelSem.RoundEval.Core

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

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
  /-- MATERIALIZED memory twin (hyp mode; arc-17 S2b): `mem` is the
      writeBytesTo-SPELLING the equations state; `memMat` is its
      ground normal form, maintained INCREMENTALLY (one delta-layer
      groundNorm per memory round, ~4 ms — measured 350x cheaper than
      re-materializing the ladder, which crossed the round heartbeat
      budget at T4's depth). Load-round value computations ride the
      twin; the law side conditions still state the spelling. In
      ground mode this is just `mem` (unused). -/
  memMat : Expr
  tr    : Expr  -- trace
  ctr   : Expr  -- dr_step_counter
  /-- fixed fields, projections of the from-state (in `driver_state`
      field order: core_file, core_extern, concurrency_state,
      fs_state0, symbolic_assoc, blocked). -/
  fixed : Array Expr

/-- Initial components: plain projections of the from-state. -/
def Anchor.init (σ0 : Expr) : TermElabM Anchor := do
  let p (f : Name) : TermElabM Expr := mkAppMU f #[σ0]
  let memP ← p ``driver_state.layout_state
  return { cs := ← p ``driver_state.core_state0,
           rs := ← p ``driver_state.core_run_state0,
           mem := memP,
           memMat := memP,
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
  let p (f : Name) : TermElabM Expr := mkAppMU f #[σprev]
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
  /-- The pack-proved DISCOVERY equation's theorem name (glue rounds
      only, arc-18 C3): `find_can_advance (step_ctx …σ…) = some
      (stepAt …σ)` — chain pieces consume it where a kernel-deferred
      refl cannot re-run a pack-dependent discovery. -/
  hfindName : Option Name := none
  deriving Inhabited

/-- Default any leftover UNCONSTRAINED level metavariables to zero
    (arc-17 S3): law elaboration at a builder-state σ0 can leave a
    payload's container universes unconstrained (`List.{?u}` in
    quoted AST data — all Type-0 data here); the kernel re-checks the
    defaulted result at addDecl. -/
private def defaultLevelMVars (e : Expr) : MetaM Expr := do
  let e ← instantiateMVars e
  unless e.hasLevelMVar do return e
  let st := collectLevelMVars {} e
  for id in st.result do
    assignLevelMVar id .zero
  instantiateMVars e

/-- Shared declaration emitter: `def name bs := value` (abbrev hints +
    realizations, like the S0 emitter) plus optionally nothing else. -/
def emitFlatDef (declName : Name) (fvars : Array Expr)
    (value : Expr) (doc : String) : TermElabM Unit := do
  let value ← instantiateMVars value
  let type ← defaultLevelMVars (← mkForallFVars fvars (← inferType value))
  let val ← defaultLevelMVars (← mkLambdaFVars fvars value)
  if val.hasLevelMVar || type.hasLevelMVar then
    let mut path : Array MessageData := #[]
    let mut cur := if val.hasLevelMVar then val else type
    for _ in [0:64] do
      let children : Array Expr := match cur with
        | .app .. => cur.getAppArgs.push cur.getAppFn
        | .lam _ t b _ => #[t, b]
        | .forallE _ t b _ => #[t, b]
        | .letE _ t v b _ => #[t, v, b]
        | .mdata _ b => #[b]
        | .proj _ _ b => #[b]
        | _ => #[]
      match children.find? (·.hasLevelMVar) with
      | some nx =>
        path := path.push m!"{cur.getAppFn}"
        cur := nx
      | none =>
        path := path.push m!"LEAF {cur}"
        break
    throwError "derive_rounds: emitted {declName} has LEVEL \
      metavariables; descent: {path.toList}"
  if val.hasFVar then
    -- diagnostic (fail-closed either way — addDecl would reject):
    -- name the leftover fvars and the smallest app subterm carrying
    -- the first one
    let bad := (collectFVars {} val).fvarIds
    let mut path : Array MessageData := #[]
    if let some fv0 := bad[0]? then
      let mut cur := val
      for _ in [0:64] do
        let children : Array Expr := match cur with
          | .app .. => cur.getAppArgs.push cur.getAppFn
          | .lam _ t b _ => #[t, b]
          | .forallE _ t b _ => #[t, b]
          | .letE _ t v b _ => #[t, v, b]
          | .mdata _ b => #[b]
          | .proj _ _ b => #[b]
          | _ => #[]
        let next? := children.find? (·.hasAnyFVar (· == fv0))
        match next? with
        | some nx =>
          path := path.push m!"{cur.getAppFn}"
          cur := nx
        | none =>
          path := path.push m!"LEAF {cur}"
          break
    let names ← bad.mapM (fun fv => do
      match (← getLCtx).find? fv with
      | some d => pure d.userName
      | none => pure fv.name)
    throwError "derive_rounds: emitted {declName} has leftover free \
      variables {names}; descent path heads: {path.toList}"
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

def emitThm (thmName : Name) (fvars : Array Expr)
    (stmt proof : Expr) (doc : String) : TermElabM Unit := do
  let type ← defaultLevelMVars (← mkForallFVars fvars stmt)
  let value ← defaultLevelMVars (← mkLambdaFVars fvars proof)
  if type.hasExprMVar || value.hasExprMVar then
    -- diagnostic (arc-18 C3b): name the side and the mvar types
    let side := if type.hasExprMVar then "TYPE" else "VALUE"
    let carrier := if type.hasExprMVar then type else value
    let st := carrier.collectMVars {}
    let mut infos : Array MessageData := #[]
    for mv in st.result do
      let ty ← instantiateMVars (← mv.getType)
      infos := infos.push m!"?{mv.name} : {ty}"
    throwError "derive_rounds: emitted {thmName} has metavariables \
      ({side}): {infos.toList}"
  if type.hasLevelMVar then
    throwError "derive_rounds: emitted {thmName} TYPE has level \
      metavariables:{indentExpr type}"
  if value.hasLevelMVar then
    throwError "derive_rounds: emitted {thmName} VALUE has level \
      metavariables (proof elided)"
  -- fail-closed: a failed postponed tactic inside an elaborated law
  -- chain surfaces as sorryAx — never let it reach addDecl
  if type.hasSorry || value.hasSorry then
    throwError "derive_rounds: emitted {thmName} contains sorry (a \
      side condition failed — see the errors above)"
  try
    addDecl <| .thmDecl { name := thmName, levelParams := [], type, value }
  catch ex =>
    -- failure localization: the elaborator check's error pretty-
    -- prints where the kernel's often cannot
    let checkMsg ← (try
        withCurrHeartbeats (check value)
        pure m!"(elaborator check PASSES)"
      catch ex2 => pure m!"elaborator check says: {ex2.toMessageData}")
    throwError "derive_rounds: addDecl of {thmName} FAILED: \
      {ex.toMessageData}\n--- {checkMsg}"
  addDocStringCore thmName doc

/-- Emit a kernel-certified ground fact `∀ bs, stmt` with proof
    `Eq.refl rhs`: the KERNEL's defeq (which forces literal operands of
    accelerated Nat/Int ops) certifies what the elaborator's lazy defeq
    wedges on (measured this slice: alignDown's div/mul over compound
    literal arguments). The donor recompute-and-check contract, taken
    to the kernel. -/
def emitKernelFact (factName : Name) (fvars : Array Expr)
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

end RoundEval
end RelSem
