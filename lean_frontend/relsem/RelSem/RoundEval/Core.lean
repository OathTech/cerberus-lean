/-
  RelSem.RoundEval.Core — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: expression navigation + ground normalization
  primitives and the engine's shared mutable hooks — flattenState,
  the phase-scoped budget helpers (whnfU/mkAppMU/mkAppOptMU/toStxU),
  the dig/fence/builder hooks, groundNorm/evalGround, substGround,
  normalizeThreads. NO semantic knowledge lives here (the
  engine-to-law rule, contracts doc §3b): everything in this module
  is elaborator handling over opaque terms.

  Split from the monolithic RoundEval.lean (3,586 lines at
  decomposition); code carried VERBATIM apart from `private` removed
  where a definition crossed the new module boundary. Module doc +
  lineage: RoundEval.lean (the umbrella).

  House rules: no sorry, no axioms; meta code only.
-/
import Lean
import RelSem.Machine
import RelSem.Cerberus
import RelSem.DeriveState
import RelSem.LawRegistry

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
  withCurrHeartbeats <| Core.transform e (post := fun node => do
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

/-! ## Phase-level budget scoping (arc-17 S3)

    The S2 design scoped ONE default heartbeat budget per ROUND. The
    minter's arrival breaks that granularity: a hypothesis round now
    runs a VARIABLE number of normalize/substitute/mint passes (one
    per stuck comparison tower), each already scoped at the default —
    but the global heartbeat counter is monotone, so the ROUND-level
    scope still sees their sum and dies after ~3 passes regardless.
    The unit of work is therefore one META-OPERATION on one term
    (a whnf, a law-chain elaboration, a normalization pass, an
    anchoring), each scoped at the DEFAULT value — budget SCOPING,
    not a raise: any single operation exceeding the default still
    fails loudly, and no maxHeartbeats value anywhere changes. -/

/-- whnf as its own scoped unit (see the phase-scoping note). -/
def whnfU (e : Expr) : MetaM Expr :=
  withCurrHeartbeats (whnf e)


/-- Scoped-glue helpers (phase-scoping note): after a self-scoped
    heavy segment the ENCLOSING budget is spent, so even trivial glue
    (an instance synthesis inside `mkAppM`, a syntax quotation) dies
    at its first heartbeat check. Every glue op therefore carries its
    own default-value base. -/
def mkAppMU (f : Name) (args : Array Expr) : MetaM Expr :=
  withCurrHeartbeats (mkAppM f args)

def mkAppOptMU (f : Name) (args : Array (Option Expr)) :
    MetaM Expr :=
  withCurrHeartbeats (mkAppOptM f args)

def toStxU (e : Expr) : TermElabM Term :=
  withCurrHeartbeats (Term.exprToSyntax e)

/-- Forward hook + memo for the hyp-mode `.all` DIG (populated after
    the minter definitions — see `digStuck` for the design note). -/
initialize digHook : IO.Ref (Expr → MetaM (Option Expr)) ←
  IO.mkRef (fun _ => return none)

initialize digCache : IO.Ref (Std.HashMap Expr Expr) ← IO.mkRef {}

/-- The active drive's BASE pattern-head fence set (for groundNorm's
    fenced-head ground escape; set/cleared by the command). -/
initialize baseFenceHeads : IO.Ref NameSet ← IO.mkRef {}

/-- BUILDER MODE (arc-17 S3): set by `derive_rounds … builder` for
    walks from a BUILDER state (free component binders). Gates the
    mechanisms that builder walks need and materialized-state drives
    must not see (measured regressions both ways): the fenced-head
    ground escape, the position-safe minted substitution, and the
    exactness-bridged proof chains. -/
initialize builderMode : IO.Ref Bool ← IO.mkRef false

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
  -- MEMOIZED (arc-17 S2b — the S2-registered load-cost item): the
  -- naive recursion re-normalized shared subterms per occurrence, so
  -- deep writeBytesTo ladders (T4: 7 layers) crossed the round
  -- heartbeat budget. Expr hashing is cached; the memo exploits the
  -- DAG sharing the whole evaluator maintains.
  let cache ← IO.mkRef ({} : Std.HashMap Expr Expr)
  let rec norm (fuel : Nat) (e : Expr) : MetaM Expr := do
    match fuel with
    | 0 => throwError "groundNorm: normalization fuel exhausted on {what}"
    | fuel + 1 =>
      if let some r := (← cache.get).get? e then return r
      -- proofs are opaque data here: normalizing them buys nothing
      -- and can be arbitrarily expensive (tree-map WF certificates).
      -- isProofQuick first (arc-17 S2b): the full isProof runs
      -- inferType on EVERY node — measured as the dominant cost of
      -- materializing tree-map-carrying records.
      match ← Meta.isProofQuick e with
      | .true => return e
      | .false => pure ()
      | .undef => if ← Meta.isProof e then return e
      let e0 := e
      -- per-whnf scoping (phase note): the fixpoint's step count
      -- scales with the term, so each head reduction is its own unit.
      -- writeBytesTo ladders skip the head whnf: reducing the top
      -- layer forces EVERY layer below in one whnf unit (the S2b
      -- one-shot-materialization cost, measured again at the T5
      -- body-walk start); args-first normalization materializes
      -- layer by layer, each under its own budget.
      let e ← if e.isAppOfArity ``CerbMem.writeBytesTo 3 then pure e
              else withCurrHeartbeats (whnf e)
      let r ← do
        if e.isApp then
          let f := e.getAppFn
          -- INERT-FIELD RULE (arc-17 S2b, measured): a run state's
          -- labeled-continuation table is program TEXT (materializing
          -- it = normalizing the whole stdlib's converted bodies —
          -- transform-timeout scale); supplies normalize, the table
          -- stays as spelled.
          if e.isAppOfArity ``core_run_state.mk 5 then
            let args := e.getAppArgs
            let mut args' := args
            for i in [0:4] do
              args' := args'.set! i (← norm fuel args[i]!)
            pure (mkAppN f args')
          else
            let mut args ← e.getAppArgs.mapM (norm fuel)
            -- Fin-literal PROOF SCRUB (arc-17 S3): a byte value's
            -- `Fin.mk` certificate quotes the UNNORMALIZED value
            -- spelling (proofs are opaque to this normalizer), which
            -- can embed minted-verdict references and their pack
            -- binders — a leak into successor defs. At literal
            -- index/bound the canonical kernel-decide proof replaces
            -- it (same Prop after normalization; defeq-preserving).
            if false then pure () -- Fin scrub RETIRED (arc-17 S3):
              -- the proof-position substitution skip makes it
              -- redundant, and its canonical proofs mis-typed at one
              -- measured byte site
            let e' := mkAppN f args
            let e'' ← withCurrHeartbeats (whnf e')
            if e'' == e' then do
              -- FENCED-HEAD GROUND ESCAPE (arc-17 S3): the attribute
              -- fence exists to keep pack-pattern SPELLINGS visible;
              -- a fully-CLOSED application of a fenced head is plain
              -- ground computation and must still reduce (measured:
              -- a lookup-fact pack fences `fmapLookupBy`, freezing
              -- the ground extern-resolve wrapper inside every PEsym
              -- eval). `.all` is attribute-blind; the kernel
              -- re-checks everything downstream.
              let escaped? ← (do
                unless ← (builderMode.get : BaseIO _) do return none
                if e'.hasFVar || e'.hasExprMVar then return none
                let .const c _ := f | return none
                unless (← (baseFenceHeads.get : BaseIO _)).contains c do
                  return none
                let r ← (try
                    withCurrHeartbeats (withTransparency .all (whnf e'))
                  catch _ => pure e')
                return if r == e' then none else some r)
              match escaped? with
              | some r => norm fuel r
              | none =>
                match ← (← digHook.get) e' with
                | some r => norm fuel r
                | none => pure e'
            else norm fuel e''
        else pure e
      cache.modify (·.insert e0 r)
      return r
  -- own scoped unit (phase-scoping note)
  withCurrHeartbeats <| withTransparency .default <| norm 512 e

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
  withCurrHeartbeats <| Core.transform e (post := fun node => do
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
  let r ← withCurrHeartbeats <| Core.transform e (post := fun node => do
    if node.isAppOfArity ``thread_state.mk 7 && !node.hasLooseBVars then
      count.modify (· + 1)
      return .done (← groundNorm "thread payload" node)
    return .done node)
  trace[RelSem.roundEval] "normalizeThreads: {← count.get} thread payloads normalized"
  return r

/-! ## Registry dispatch (arc-18 C1 — the R4 contract made
    mechanical) -/

/-- A query STAR: a fresh metavariable keys as a DiscrTree wildcard
    and is never reduced. Dispatch goals are SKELETONS — only the
    DISCRIMINATING positions are concrete; every other position is a
    star (measured necessity: `getMatchLoop` key-reduces EVERY
    position, star edges included, so live states/payloads in a query
    ran whnfCore over execution spellings — the T4 round-18
    timeout). -/
def qStar : TermElabM Expr := do
  mkFreshExprMVar none

/-- Skeletonize an `app`-rooted dispatch goal: `goal0` is BUILT from
    the live pieces (the typed construction supplies the correct
    implicit type-argument keys), then the computation's arguments
    are REPLACED by the caller's skeleton `mArgs'` (stars everywhere
    but the discriminating positions) and the state is starred. Raw
    `mkAppN` replacement — `mkAppM` runs at a fresh MCtx depth and
    cannot take outer star mvars. -/
def appGoalSkeleton (goal0 : Expr) (mArgs' : Array Expr) :
    TermElabM Expr := do
  let gargs := goal0.getAppArgs
  let m0 := gargs[gargs.size - 2]!
  return mkAppN goal0.getAppFn
    ((gargs.set! (gargs.size - 2) (mkAppN m0.getAppFn mArgs')).set!
      (gargs.size - 1) (← qStar))

/-- THE DISPATCH QUERY: the unique registered law of `kind`
    (/`variant`) whose goal-form key matches `goal`
    (RelSem.LawRegistry.queryUnique). A miss or an ambiguity surfaces
    as a FAIL-CLOSED FRONTIER naming the joint — the lane's "no
    registered law" error, now produced by the registry instead of a
    hardcoded head check. Hardcoded law-NAME dispatch in the engine is
    retired in favor of this query; the engine keeps only slot
    PREPARATION (ground literals, spellings — elaborator handling per
    the entry's declared trace schema). -/
def queryLaw (kind : Name) (goal : Expr) (variant : Name := .anonymous)
    (what : String := "") : TermElabM RelSem.LawRegistry.StepLaw := do
  try
    let law ← RelSem.LawRegistry.queryUnique kind goal variant
    trace[RelSem.roundEval] "queryLaw: {law.name} ({what})"
    return law
  catch ex =>
    throwFrontier m!"derive_rounds: registry dispatch ({what}): \
      {ex.toMessageData}"

end RoundEval
end RelSem
