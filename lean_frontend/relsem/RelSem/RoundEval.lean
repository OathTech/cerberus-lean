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
import RelSem.Kit.Map

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
private def whnfU (e : Expr) : MetaM Expr :=
  withCurrHeartbeats (whnf e)


/-- Scoped-glue helpers (phase-scoping note): after a self-scoped
    heavy segment the ENCLOSING budget is spent, so even trivial glue
    (an instance synthesis inside `mkAppM`, a syntax quotation) dies
    at its first heartbeat check. Every glue op therefore carries its
    own default-value base. -/
private def mkAppMU (f : Name) (args : Array Expr) : MetaM Expr :=
  withCurrHeartbeats (mkAppM f args)

private def mkAppOptMU (f : Name) (args : Array (Option Expr)) :
    MetaM Expr :=
  withCurrHeartbeats (mkAppOptM f args)

private def toStxU (e : Expr) : TermElabM Term :=
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

/-! ## THE HYPOTHESIS-THREADING MODE (arc-17 S2b — the S2-registered
    M item, §3.2 item 1 of the S2 record)

    `derive_rounds id (bs…) assuming h₁ … hₙ using …` — the named
    binders become a HYPOTHESIS PACK the mints may consume, turning
    conditional rounds into CONDITIONAL EQUATIONS (∀-closed over the
    binders, hypotheses included):

    * an `a = b`-typed hypothesis (e.g. `htags : CerbTags.tagDefs ()
      = t4File.tagDefs`, `hdig : CerberusFresh.digest () = ""`)
      registers a REWRITE: ground evaluation substitutes `b` for the
      kernel-stuck `a` wherever normalization exposes it, and the
      emitted proofs carry the corresponding `congrArg` step (the
      arc-9 "rewrite the stuck projection, then compute" recipe made
      mechanical);
    * any other Prop hypothesis (e.g. the seed-apartness guard) is
      held for the STUCK-COMPARISON fact minter: comparisons of a
      hypothesis-bounded binder against ground literals are minted as
      named conditional facts (proved from the pack by `omega`-class
      discharge) and join the rewrite set.

    Emission discipline: successor DEFS close over the VALUE binders
    only (a proof leaking into a data spelling is a fail-closed
    frontier); the `_app` equations and all facts close over the full
    binder telescope. With no `assuming` clause the evaluator is
    byte-identical to its S2 behavior (empty pack, closedness
    demanded — the t6 probe path is unchanged).

    *Lineage*: rewriting-modulo-hypotheses is ordinary conditional
    rewriting (simp-with-hypotheses); it is implemented DIRECTED
    (whnf-normalize, substitute at stuck sites, `congrArg`/`Eq.trans`
    chain) because the terms are execution states where undirected
    simp unfolding is unaffordable — same reason `groundNorm` exists.
    Forward-design note (the doctrine constraint): nothing here bakes
    the ambient reads in — when the effect state moves inside the
    machine state, the eq-hypotheses simply disappear from the packs
    and the mode degenerates to the hypothesis-free evaluator. -/

/-- One registered rewrite: (stuck lhs, replacement rhs, proof term
    `lhs = rhs` valid in the command's binder scope). `syntactic`
    marks MINTED patterns (arith-minter verdicts): they are harvested
    from the very term being rewritten, so occurrence matching is
    structural `==` — kabstract's defeq walks on tower-sized patterns
    were the measured budget hole (round-18 probe, this slice). -/
structure HypRw where
  lhs : Expr
  rhs : Expr
  prf : Expr
  syntactic : Bool := false

/-- The hypothesis pack (per-command; also exposed to the
    `hyp_norm_side` tactic through `activeHypPack` for the law
    side conditions elaborated inside the command). -/
structure HypPack where
  /-- eq-typed hypotheses, as given. -/
  baseRw : Array HypRw
  /-- non-eq Prop hypothesis fvars (the fact minter's ammunition). -/
  arith : Array Expr
  /-- minted comparison facts (grows during the drive). -/
  minted : IO.Ref (Array HypRw)
  /-- DEFEQ substitutions (no proof piece needed — kernel bridges):
      memory SPELLING → materialized twin, one entry per memory
      round. Keeps the elaborator off one-shot ladder walks in side
      conditions (the measured 350x item). -/
  defeqSubst : IO.Ref (Array (Expr × Expr))
  /-- name generator for minted facts. -/
  mintIdx : IO.Ref Nat
  /-- base name for minted facts (`<cmd base>_hf<i>`). -/
  baseName : Name
  /-- the command's full binder telescope. -/
  fvars : Array Expr
  /-- the value (non-Prop) binders — the def-closure telescope. -/
  valueFVars : Array Expr
  /-- THE REDUCIBILITY FENCE (measured, this slice): whnf-unfolding a
      function whose body reads a kernel-stuck extern EXPLODES the
      spelling through recursor branches and Decidable-instance
      PROOFS — and substitution into those dependent positions
      produces ill-typed stuck junk (probe: post-substitution
      `isDefEq _ 8 = false`). So hyp-mode normalization REFUSES to
      unfold the pack's pattern-head constants: stuck points then
      arise exactly at the tidy curated spellings, where substitution
      is a well-typed data-position rewrite. Derived automatically
      from the registered patterns' heads. -/
  fence : NameSet

/-- The empty pack (hypothesis-free mode — S2 behavior). -/
def HypPack.mk0 : BaseIO HypPack := do
  return { baseRw := #[], arith := #[], minted := ← IO.mkRef #[],
           mintIdx := ← IO.mkRef 0, baseName := .anonymous,
           fvars := #[], valueFVars := #[], fence := {},
           defeqSubst := ← IO.mkRef #[] }

def HypPack.isEmpty (hp : HypPack) : Bool :=
  hp.baseRw.isEmpty && hp.arith.isEmpty

/-- All active rewrites (base + minted). -/
def HypPack.pairs (hp : HypPack) : BaseIO (Array HypRw) :=
  return hp.baseRw ++ (← hp.minted.get)

/-- The active pack for side-condition tactics elaborated inside the
    command (`hyp_norm_side`); none outside a hypothesis-mode
    command. -/
initialize activeHypPack : IO.Ref (Option HypPack) ← IO.mkRef none

/-- kabstract-based single-pattern substitution (head-keyed, up-to-
    defeq occurrence matching — arena spellings carry EXPANDED symbol
    literals where the fixture facts name defs, so plain syntactic
    `==` misses; kabstract's head-const keying + defeq check is the
    right matcher and only pays at candidate heads). Returns none if
    no occurrence. -/
def substPattern (e lhs rhs : Expr) : MetaM (Option Expr) := do
  let quick := match lhs.getAppFn with
    | .const c _ => (e.find? (fun sub => sub.isConstOf c)).isSome
    | _ => true
  unless quick do return none
  let abst ← kabstract e lhs
  if abst.hasLooseBVars then
    return some (abst.instantiate1 rhs)
  else
    return none

/-- STRUCTURAL abstraction of a CLOSED pattern (the minted-pattern
    fast path — see `HypRw.syntactic`): every `==`-occurrence of
    `pat` is abstracted; same contract as `kabstract` (loose bvar 0,
    caller `instantiate1`s). Implementation: `Core.transform`
    (share-cached) replaces occurrences by a scratch fvar, then
    `Expr.abstract` does the binder-lifting bookkeeping — a
    hand-rolled depth-indexed walk measured 20 s on a round-18 term
    (per-depth cache misses on shared subterms); this shape is
    sub-second. -/
def abstractExact (root pat : Expr) : MetaM Expr := do
  let ty ← inferType pat
  withLocalDeclD `x ty fun fv => do
    let e' ← Core.transform root (post := fun n => do
      if n == pat then return .done fv
      return .done n)
    return e'.abstract #[fv]

/-- STRUCTURAL POSITION SAFETY for minted-verdict substitution
    (arc-17 S3): a verdict is propositionally-not-definitionally
    equal to its tower, so replacing an occurrence is type-safe only
    where the surrounding application cannot see the difference —
    the MAJOR/discriminant of an eliminator whose motive is a
    NON-DEPENDENT lambda (iota then collapses it), or the instance
    argument of `ite`/`dite`/`decide`. Everything else is refused
    (the enclosing-cluster lanes mint those atomically). The earlier
    `Meta.check` guard was elaborator-lenient where the kernel is
    not (measured: the T4 round-5 offsetsof cluster). -/
private def motiveNonDep (m : Expr) : Bool :=
  match m with
  | .lam _ _ b _ => !b.hasLooseBVars
  | _ => false

private partial def substDecSafeCore (root pat rhs : Expr)
    (found : IO.Ref Bool) : MetaM Expr := do
  let env ← getEnv
  let cache ← IO.mkRef ({} : Std.HashMap Expr Expr)
  let rec go (e : Expr) : MetaM Expr := do
    unless e.isApp || e.isLambda || e.isForall || e.isLet
        || e.isMData || e.isProj do return e
    if let some r := (← cache.get).get? e then return r
    let r ← (do
      match e with
      | .app .. => do
        let fn := e.getAppFn
        let args := e.getAppArgs
        -- which positions may take the verdict directly?
        let safeIdx : Array Nat ← (do
          match fn with
          | .const c _ =>
            if c == ``ite || c == ``dite then
              return #[2]
            else if c == ``decide then
              return #[1]
            else if c == ``Decidable.rec then
              -- @Decidable.rec p motive hf ht major : 5 args
              if args.size == 5 && motiveNonDep args[1]! then
                return #[4]
              return #[]
            else if isMatcherAppCore env e then
              if let some ma ← Lean.Meta.matchMatcherApp? e then
                if motiveNonDep ma.motive then
                  let base := ma.params.size + 1
                  return (Array.range ma.discrs.size).map (base + ·)
              return #[]
            else if (env.find? c).isSome
                && (env.find? c matches some (.recInfo _)) then
              return #[]
            else return #[]
          | _ => return #[])
        let mut newArgs := args
        for i in [0:args.size] do
          if args[i]! == pat && safeIdx.contains i then
            newArgs := newArgs.set! i rhs
            found.set true
          else
            newArgs := newArgs.set! i (← go args[i]!)
        return mkAppN (← go fn) newArgs
      | .lam n t b i => return .lam n (← go t) (← go b) i
      | .forallE n t b i => return .forallE n (← go t) (← go b) i
      | .letE n t v b nd =>
        return .letE n (← go t) (← go v) (← go b) nd
      | .mdata m b => return .mdata m (← go b)
      | .proj sN i b => return .proj sN i (← go b)
      | e => return e)
    cache.modify (·.insert e r)
    return r
  go root

def substPatternExact (e lhs rhs : Expr) : MetaM (Option Expr) := do
  let quick := match lhs.getAppFn with
    | .const c _ => (e.find? (fun sub => sub.isConstOf c)).isSome
    | _ => true
  unless quick do return none
  if ← (builderMode.get : BaseIO _) then
    -- builder mode: STRUCTURAL position safety
    let found ← IO.mkRef false
    let e' ← substDecSafeCore e lhs rhs found
    if ← found.get then return some e' else return none
  -- materialized-state mode (the committed S2b/minter behavior):
  -- full structural replacement, proof-subterms skipped, type-check
  -- guarded
  let found ← IO.mkRef false
  let e' ← Meta.transform e
    (pre := fun n => do
      if (← Meta.isProofQuick n) matches .true then
        return .done n
      return .continue)
    (post := fun n => do
      if n == lhs then
        found.set true
        return .done rhs
      return .done n)
  unless ← found.get do return none
  try
    withCurrHeartbeats <| check e'
    return some e'
  catch _ =>
    trace[RelSem.roundEval] "substPatternExact: substitution refused \
      (result fails type check — dependent-position variant mixing)"
    return none

/-- `abstractExact` under the SAME structural position discipline as
    `substPatternExact` (the proof-path variant): only safe
    occurrences are abstracted. -/
def abstractExactChecked (e lhs rhs : Expr) : MetaM (Option Expr) := do
  if ← (builderMode.get : BaseIO _) then
    let ty ← inferType lhs
    return ← withLocalDeclD `x ty fun fv => do
      let found ← IO.mkRef false
      let e' ← substDecSafeCore e lhs fv found
      unless ← found.get do return none
      return some (e'.abstract #[fv])
  let abst ← abstractExact e lhs
  unless abst.hasLooseBVars do return none
  try
    withCurrHeartbeats <| check (abst.instantiate1 rhs)
    return some abst
  catch _ =>
    trace[RelSem.roundEval] "abstractExactChecked: substitution refused"
    return none

/-- Substitute every registered rewrite occurrence. Returns none if
    nothing matched. -/
def hypSubst (hp : HypPack) (e : Expr) (withDefeq : Bool := true) :
    MetaM (Option Expr) := do
  let pairs ← hp.pairs
  let dq ← if withDefeq then hp.defeqSubst.get else pure #[]
  if pairs.isEmpty && dq.isEmpty then return none
  let mut cur := e
  let mut changed := false
  for r in pairs do
    let tR ← IO.monoMsNow
    -- Per-ATTEMPT budget scoping (arc-17 S3): one pattern-match
    -- attempt on one term is the unit of work — a pass batches
    -- #patterns attempts and the batch size scales with the pack, so
    -- a shared budget made capacity depend on how many facts a
    -- fixture curates. Scoped at the default value (a single attempt
    -- exceeding it still fails loudly); the S2 per-round note is the
    -- governing rationale.
    let res ← withCurrHeartbeats
      (if r.syntactic then substPatternExact cur r.lhs r.rhs
       else substPattern cur r.lhs r.rhs)
    let dt := (← IO.monoMsNow) - tR
    if dt > 200 then
      trace[RelSem.roundEval] "hypSubst: slow pattern ({dt} ms, syntactic={r.syntactic}, head {r.lhs.getAppFn})"
    if let some cur' := res then
      trace[RelSem.roundEval] "hypSubst: HIT (syntactic={r.syntactic}, head {r.lhs.getAppFn})"
      cur := cur'
      changed := true
  -- defeq pairs: syntactic replacement is enough (and cheap — these
  -- are big ladder spellings, kabstract's defeq matching would defeat
  -- the purpose). ONE batched transform pass (a per-pair loop meant
  -- |dq| full traversals of the term — measured as a transform
  -- timeout at round 18's result size).
  if !dq.isEmpty then
    let cur' ← substGround cur dq
    if cur' != cur then
      cur := cur'
      changed := true
  return if changed then some cur else none

/-- Substitution-only fixpoint (NO normalization — safe on state
    records whose byte maps must never be materialized). -/
def hypSubstFix (hp : HypPack) (e : Expr) : MetaM Expr := do
  -- successor-respell tool: PROPOSITIONAL pairs only (the def must
  -- keep the writeBytesTo SPELLING, never the materialized twin)
  let mut cur := e
  for _ in [0:16] do
    match ← hypSubst hp cur (withDefeq := false) with
    | some c => cur := c
    | none => return cur
  return cur

/-- Substitution-only equality proof: `lhs = rhs` where `rhs` is
    `lhs` after registered substitutions (a `congrArg` chain; NO
    normalization anywhere — the respell-bridge prover for successor
    spellings). -/
def proveSubstEq (hp : HypPack) (lhs rhs : Expr) : TermElabM Expr := withCurrHeartbeats do
  let mut cur := lhs
  let mut pf : Option Expr := none
  for _ in [0:64] do
    if cur == rhs then break
    let pairs ← hp.pairs
    let mut found : Option (HypRw × Expr) := none
    for r in pairs do
      if found.isNone then
        -- head-const quick filter before kabstract (a kabstract scan
        -- over twin-carrying goals measured ~1.2 s; the filter is a
        -- pure traversal)
        let quick := match r.lhs.getAppFn with
          | .const c _ => (cur.find? (·.isConstOf c)).isSome
          | _ => true
        if quick then
          if r.syntactic then
            if let some abst ← abstractExactChecked cur r.lhs r.rhs then
              found := some (r, abst)
          else
            let abst ← kabstract cur r.lhs
            if abst.hasLooseBVars then found := some (r, abst)
    match found with
    | some (r, abst) =>
      let motive := Lean.mkLambda `x .default (← inferType r.lhs) abst
      let piece ← mkCongrArg motive r.prf
      pf := some (← match pf with
        | none => pure piece
        | some p => mkEqTrans p piece)
      cur := abst.instantiate1 r.rhs
    | none => break
  unless cur == rhs do
    throwFrontier m!"proveSubstEq: substitution chain did not reach \
      the respelled form:{indentExpr cur}\nvs:{indentExpr rhs}"
  match pf with
  | some p => return p
  | none => mkEqRefl rhs


/-- THE STUCK-COMPARISON FACT MINTER (v1 registry; grown empirically,
    fail-closed — an unregistered stuck shape simply mints nothing and
    the consumer's frontier fires with the term printed). Scans `e`
    for stuck comparison applications whose arguments mix a
    pack-bounded binder with ground literals, mints
    `∀ bs, <cmp> = <verdict>` (proved from the pack by the registered
    discharge), and registers the rewrite. Returns true if anything
    was minted. Populated by `mintCmpFact?` below (defined after the
    emitters it needs); this hook is replaced there. -/
initialize mintHook :
    IO.Ref (HypPack → Expr → TermElabM Bool) ←
  IO.mkRef (fun _ _ => return false)

/-- `groundNorm` under the pack's reducibility fence (see
    `HypPack.fence`). -/
def groundNormFenced (hp : HypPack) (what : String) (e : Expr) :
    MetaM Expr := do
  if hp.fence.isEmpty then
    groundNorm what e
  else
    -- IMPORTANT (measured): setting `canUnfold?` REPLACES the default
    -- transparency logic entirely — a naive `!fence.contains` pred
    -- unfolds normally-irreducible constants and the 200k-heartbeat
    -- budget dies inside whnf. Mirror the default rule, minus the
    -- fence.
    withReader (fun ctx => { ctx with
      canUnfold? := some fun cfg ci => do
        if hp.fence.contains ci.name then
          return false
        match cfg.transparency with
        | .all => return true
        | _ =>
          return (getReducibilityStatusCore (← getEnv) ci.name)
            != .irreducible }) do
      groundNorm what e

/-- Hypothesis-aware ground normalization: substitute-first at the
    tidy spellings, normalize UNDER THE FENCE, loop to fixpoint; then
    one final UNFENCED pass (fenced heads with no registered pattern
    are ordinary computations — e.g. byte codecs on concrete
    integers — and must be allowed to finish). When no rewrite
    applies, offer the stuck form to the fact minter and loop if it
    produced new rewrites. -/
def hypNorm (hp : HypPack) (what : String) (e : Expr) :
    TermElabM Expr := do
  -- SUBSTITUTE-FIRST ordering (measured, this slice): whnf on a stuck
  -- operand EXPLODES it through recursor branches (`max X 1` with X
  -- stuck became a Decidable.rec tree with the redex smeared into
  -- branch lambdas, where per-arg normalization cannot reach it), so
  -- registered patterns must be replaced BEFORE normalization at
  -- every iteration. The fixture therefore registers its rewrite
  -- facts at the SPELLINGS THAT OCCUR (the arena/request vocabulary
  -- — exactly the ambient fixture-fact discipline).
  let mut cur := e
  for i in [0:64] do
    -- Each subst+norm(+mint) pass under its OWN default heartbeat
    -- budget (arc-17 S3): a mint unblocks one stuck match and the
    -- term must be re-normalized — the pass count scales with the
    -- fixture's tower population, so a shared per-round budget would
    -- make capacity depend on how many comparisons a round happens
    -- to contain. Budget SCOPING at the default value, not a raise
    -- (the S2 per-round rationale, one level down; a single pass
    -- exceeding the default still fails loudly).
    let (done?, cur') ← withCurrHeartbeats (do
      let t0 ← IO.monoMsNow
      trace[RelSem.roundEval] "hypNorm[{i}] {what}: term {← cur.numObjs} objs"
      let cur' := (← hypSubst hp cur).getD cur
      let n ← groundNormFenced hp what cur'
      trace[RelSem.roundEval] "hypNorm[{i}] {what}: fenced pass {(← IO.monoMsNow) - t0} ms; {← n.numObjs} objs"
      let tS ← IO.monoMsNow
      let subRes ← hypSubst hp n
      trace[RelSem.roundEval] "hypNorm[{i}] {what}: subst pass {(← IO.monoMsNow) - tS} ms (changed={subRes.isSome})"
      match subRes with
      | some s => return (none, s)
      | none =>
        if hp.isEmpty then return (some n, n)
        let mint ← mintHook.get
        if ← mint hp n then
          return (none, n)
        -- (the old per-call "unfenced final pass" is DEAD under the
        -- attribute fence — reducibility is env-global for the
        -- drive's extent, so re-running groundNorm cannot see more)
        return (some n, n) :
        TermElabM (Option Expr × Expr))
    match done? with
    | some n => return n
    | none => cur := cur'
  throwError "hypNorm: rewrite fuel exhausted on {what}"

/-- Build a proof of `lhs = rhs` by the directed chain: normalize
    (defeq, free), substitute one registered rewrite via
    `kabstract`+`congrArg`, repeat; finish with `rfl` (elaborator
    defeq) or kernel `decide`. Every step is an ordinary term the
    kernel re-checks at addDecl (the S0 donor contract). -/
def proveHypEqMat (hp : HypPack) (lhs rhs : Expr) : TermElabM Expr := do
  let mut cur := lhs
  let mut pf : Option Expr := none
  -- One subst/norm/mint pass; returns (continue?, cur', pf'). Runs
  -- under its OWN default heartbeat budget (arc-17 S3 — the mint loop
  -- re-normalizes the term once per unblocked tower, so the pass
  -- count scales with the round's comparison population; budget
  -- SCOPING at the default value, not a raise — the hypNorm note).
  let step := fun (it : Nat) (cur : Expr) (pf : Option Expr) =>
    withCurrHeartbeats (do
    let tIt ← IO.monoMsNow
    -- NOTE (measured): the materialized twin must NEVER be
    -- substituted into a GOAL — its accumulated tree-WF proof terms
    -- make every later kabstract traversal ~1.2 s. The twin serves
    -- VALUE derivation (hypNorm/evalGround) only; goals keep the
    -- spelling and the kernel-deferred finisher walks it
    -- heartbeat-free.
    -- substitute-first (see hypNorm): find a registered pattern in
    -- the CURRENT spelling before normalization explodes it; only
    -- normalize when nothing matches.
    let pairs ← hp.pairs
    let mut found : Option (HypRw × Expr) := none
    for r in pairs do
      if found.isNone then
        let quick := match r.lhs.getAppFn with
          | .const c _ => (cur.find? (·.isConstOf c)).isSome
          | _ => true
        if quick then
          if r.syntactic then
            if let some abst ← abstractExactChecked cur r.lhs r.rhs then
              found := some (r, abst)
          else
            let abst ← kabstract cur r.lhs
            if abst.hasLooseBVars then found := some (r, abst)
    trace[RelSem.roundEval] "proveHypEq[{it}] pattern scan done {(← IO.monoMsNow) - tIt} ms; found={found.isSome}"
    -- exposure normalization ONLY while nothing has been substituted
    -- yet (the hidden-pattern class, e.g. an eval step whose payload
    -- exposes a fenced head after one unfold burst). Once the chain
    -- has a substitution and no pattern remains, the kernel finisher
    -- takes over — deep-normalizing ladder goals here was the
    -- measured budget killer.
    if found.isNone && pf.isSome then return (false, cur, pf)
    let n ← match found with
      | some _ => pure cur
      | none => groundNormFenced hp "proveHypEq" cur
    trace[RelSem.roundEval] "proveHypEq[{it}] norm done {(← IO.monoMsNow) - tIt} ms"
    if found.isNone && n != cur then
      -- re-scan the normalized spelling
      for r in pairs do
        if found.isNone then
          let quick := match r.lhs.getAppFn with
            | .const c _ => (n.find? (·.isConstOf c)).isSome
            | _ => true
          if quick then
            if r.syntactic then
              if let some abst ← abstractExactChecked n r.lhs r.rhs then
                found := some (r, abst)
            else
              let abst ← kabstract n r.lhs
              if abst.hasLooseBVars then found := some (r, abst)
    match found with
    | some (r, abst) =>
      let motive := Lean.mkLambda `x .default (← inferType r.lhs) abst
      let piece ← mkCongrArg motive r.prf
      -- piece : n = n[rhs]; glue (defeq bridges cur ≟ n)
      let pf' := some (← match pf with
        | none => pure piece
        | some p => mkEqTrans p piece)
      return (true, abst.instantiate1 r.rhs, pf')
    | none =>
      let mint ← mintHook.get
      if ← mint hp n then
        return (true, n, pf)
      return (false, n, pf) :
    TermElabM (Bool × Expr × Option Expr))
  for it in [0:64] do
    if cur == rhs then break
    let (cont, cur', pf') ← step it cur pf
    cur := cur'
    pf := pf'
    unless cont do break
  trace[RelSem.roundEval] "proveHypEq: chain built, finishing"
  -- KERNEL-DEFERRED finisher (arc-17 S2b, measured): the elaborator's
  -- lazy defeq on ladder-walking residuals is the budget burn point
  -- (t4 load rounds: >200k heartbeats), while the KERNEL recomputes
  -- the same facts heartbeat-free at the round's addDecl (the S0
  -- recompute-and-check contract — a wrong residual is a LOUD addDecl
  -- failure naming the round, never a silent pass). So the finisher
  -- emits `Eq.refl rhs` and lets the kernel judge; syntactic equality
  -- short-circuits the common case.
  let fin ← mkEqRefl rhs
  match pf with
  | none => return fin
  | some p => mkEqTrans p fin

/-- Build a proof of `lhs = rhs` by the directed chain: normalize
    (defeq, free), substitute one registered rewrite via
    `kabstract`+`congrArg`, repeat; finish with `rfl` (elaborator
    defeq) or kernel `decide`. Every step is an ordinary term the
    kernel re-checks at addDecl (the S0 donor contract). -/
def proveHypEqBld (hp : HypPack) (lhs rhs : Expr) : TermElabM Expr := do
  let mut cur := lhs
  let mut pf : Option Expr := none
  -- One subst/norm/mint pass; returns (continue?, cur', pf'). Runs
  -- under its OWN default heartbeat budget (arc-17 S3 — the mint loop
  -- re-normalizes the term once per unblocked tower, so the pass
  -- count scales with the round's comparison population; budget
  -- SCOPING at the default value, not a raise — the hypNorm note).
  let step := fun (it : Nat) (cur : Expr) (pf : Option Expr) =>
    withCurrHeartbeats (do
    let tIt ← IO.monoMsNow
    -- NOTE (measured): the materialized twin must NEVER be
    -- substituted into a GOAL — its accumulated tree-WF proof terms
    -- make every later kabstract traversal ~1.2 s. The twin serves
    -- VALUE derivation (hypNorm/evalGround) only; goals keep the
    -- spelling and the kernel-deferred finisher walks it
    -- heartbeat-free.
    -- substitute-first (see hypNorm): find a registered pattern in
    -- the CURRENT spelling before normalization explodes it; only
    -- normalize when nothing matches.
    let pairs ← hp.pairs
    let mut found : Option (HypRw × Expr) := none
    for r in pairs do
      if found.isNone then
        let quick := match r.lhs.getAppFn with
          | .const c _ => (cur.find? (·.isConstOf c)).isSome
          | _ => true
        if quick then
          if r.syntactic then
            if let some abst ← abstractExactChecked cur r.lhs r.rhs then
              found := some (r, abst)
          else
            let abst ← kabstract cur r.lhs
            if abst.hasLooseBVars then found := some (r, abst)
    trace[RelSem.roundEval] "proveHypEq[{it}] pattern scan done {(← IO.monoMsNow) - tIt} ms; found={found.isSome}"
    -- exposure normalization ONLY while nothing has been substituted
    -- yet (the hidden-pattern class, e.g. an eval step whose payload
    -- exposes a fenced head after one unfold burst). Once the chain
    -- has a substitution and no pattern remains, the kernel finisher
    -- takes over — deep-normalizing ladder goals here was the
    -- measured budget killer.
    -- (the S2b-era early break on pf.isSome is GONE, arc-17 S3: at a
    -- builder state later stuck sites surface only after further
    -- normalization, and every hop is now bridged EXACTLY, so full
    -- subst/normalize alternation is both needed and sound; per-hop
    -- budget scoping keeps it affordable)
    let n ← match found with
      | some _ => pure cur
      | none => groundNormFenced hp "proveHypEq" cur
    trace[RelSem.roundEval] "proveHypEq[{it}] norm done {(← IO.monoMsNow) - tIt} ms"
    if found.isNone && n != cur then
      -- re-scan the normalized spelling
      for r in pairs do
        if found.isNone then
          let quick := match r.lhs.getAppFn with
            | .const c _ => (n.find? (·.isConstOf c)).isSome
            | _ => true
          if quick then
            if r.syntactic then
              if let some abst ← abstractExactChecked n r.lhs r.rhs then
                found := some (r, abst)
            else
              let abst ← kabstract n r.lhs
              if abst.hasLooseBVars then found := some (r, abst)
    match found with
    | some (r, abst) =>
      -- CHAIN EXACTNESS (arc-17 S3): the chain invariant is
      -- `pf : lhs = cur` with a SYNTACTIC cur — every normalization
      -- hop is carried by its own kernel-deferred bridge
      -- (`Eq.refl` type-hinted at `cur = n`), never by mkEqTrans's
      -- implicit midpoint unification (measured: a builder-state
      -- midpoint the elaborator glued and the kernel rejected).
      let src := if found.isSome && n != cur then n else cur
      let mut pf := pf
      if src != cur then
        let bridge ← mkExpectedTypeHint (← mkEqRefl src)
          (← mkEq cur src)
        pf := some (← match pf with
          | none => pure bridge
          | some p => mkEqTrans p bridge)
      let motive := Lean.mkLambda `x .default (← inferType r.lhs) abst
      let piece0 ← mkCongrArg motive r.prf
      -- hint the piece at the SYNTACTIC endpoints (beta-reduced)
      let src' := abst.instantiate1 r.rhs
      let piece ← mkExpectedTypeHint piece0 (← mkEq src src')
      let pf' := some (← match pf with
        | none => pure piece
        | some p => mkEqTrans p piece)
      return (true, src', pf')
    | none =>
      let mint ← mintHook.get
      if ← mint hp n then
        -- normalization hop bridged explicitly (see above)
        let mut pf := pf
        if n != cur then
          let bridge ← mkExpectedTypeHint (← mkEqRefl n) (← mkEq cur n)
          pf := some (← match pf with
            | none => pure bridge
            | some p => mkEqTrans p bridge)
        return (true, n, pf)
      return (false, n, pf) :
    TermElabM (Bool × Expr × Option Expr))
  for it in [0:64] do
    if cur == rhs then break
    let (cont, cur', pf') ← step it cur pf
    cur := cur'
    pf := pf'
    unless cont do break
  trace[RelSem.roundEval] "proveHypEq: chain built, finishing"
  -- KERNEL-DEFERRED finisher (arc-17 S2b, measured): the elaborator's
  -- lazy defeq on ladder-walking residuals is the budget burn point
  -- (t4 load rounds: >200k heartbeats), while the KERNEL recomputes
  -- the same facts heartbeat-free at the round's addDecl (the S0
  -- recompute-and-check contract — a wrong residual is a LOUD addDecl
  -- failure naming the round, never a silent pass). So the finisher
  -- emits `Eq.refl rhs` and lets the kernel judge; syntactic equality
  -- short-circuits the common case.
  match pf with
  | none => return ← mkExpectedTypeHint (← mkEqRefl rhs) (← mkEq lhs rhs)
  | some p => do
    -- the final hop, hinted at the exact endpoints
    let curFinal ← (do
      let ty ← instantiateMVars (← inferType p)
      match ty.eq? with
      | some (_, _, r) => pure r
      | none => pure rhs)
    let fin ← mkExpectedTypeHint (← mkEqRefl rhs) (← mkEq curFinal rhs)
    mkEqTrans p fin


/-- Mode dispatcher (see `builderMode`). -/
def proveHypEq (hp : HypPack) (lhs rhs : Expr) : TermElabM Expr := do
  if ← (builderMode.get : BaseIO _) then proveHypEqBld hp lhs rhs
  else proveHypEqMat hp lhs rhs

/-- `hyp_norm_side`: the law side-condition tactic of hypothesis mode
    — proves `lhs = rhs` goals via `proveHypEq` against the active
    pack. Only meaningful inside a `derive_rounds … assuming …`
    elaboration. -/
elab "hyp_norm_side" : tactic => do
  let some hp ← activeHypPack.get
    | throwError "hyp_norm_side: no active hypothesis pack (only \
        usable inside derive_rounds' hypothesis mode)"
  let g ← Lean.Elab.Tactic.getMainGoal
  let ty ← instantiateMVars (← g.getType)
  let some (_, l, r) := ty.eq?
    | throwError "hyp_norm_side: goal is not an equation: {ty}"
  -- whole-state goals (the request-draw class) are rfl's territory:
  -- lazy elaborator defeq is CHEAPER there than this engine's
  -- normalization (measured: 436 ms scan + budget-killing norm vs a
  -- cheap rfl); fail fast so `first` falls through.
  if l.isAppOf ``RelSem.app then
    throwError "hyp_norm_side: whole-state app goal (rfl's territory)"
  trace[RelSem.roundEval] "hyp_norm_side ENTER: lhs head {l.getAppFn}, rhs head {r.getAppFn}"
  let t0 ← IO.monoMsNow
  let pf ← proveHypEq hp l r
  trace[RelSem.roundEval] "hyp_norm_side: {(← IO.monoMsNow) - t0} ms"
  g.assign pf
  Lean.Elab.Tactic.replaceMainGoal []

/-- Free DATA variables of a term: fvars occurring outside PROOF
    subterms (arc-17 S3 — a minted-fact reference inside a Fin/
    tree-WF certificate is proof content, data-irrelevant by proof
    irrelevance, and must not trip the closedness frontier). -/
private partial def collectDataFVars (e : Expr) : MetaM (Array FVarId) := do
  let seen ← IO.mkRef ({} : Std.HashSet Expr)
  let out ← IO.mkRef (#[] : Array FVarId)
  let rec go (e : Expr) : MetaM Unit := do
    unless e.hasFVar do return
    if (← seen.get).contains e then return
    seen.modify (·.insert e)
    match ← Meta.isProofQuick e with
    | .true => return
    | _ => pure ()
    match e with
    | .fvar id =>
      unless (← out.get).contains id do out.modify (·.push id)
    | .app f a => go f; go a
    | .lam _ t b _ => go t; go b
    | .forallE _ t b _ => go t; go b
    | .letE _ t v b _ => go t; go v; go b
    | .mdata _ b => go b
    | .proj _ _ b => go b
    | _ => pure ()
  go e
  out.get

/-- Hypothesis-aware `evalGround`: normalization through the pack;
    metavariables always reject; free variables must be the command's
    VALUE binders (open data like `seed + 2` is legal in hypothesis
    mode), and a PROP binder in a data position is a fail-closed
    frontier. With an empty pack this is exactly `evalGround`. -/
def evalGroundH (hp : HypPack) (what : String) (e : Expr) :
    TermElabM Expr := do
  if hp.isEmpty then
    return ← evalGround what e
  let r ← hypNorm hp what e
  if r.hasExprMVar then
    throwFrontier m!"derive_rounds: ground evaluation of {what} left \
      metavariables:{indentExpr r}"
  let mut bad : Array Expr := #[]
  for fv in (← collectDataFVars r) do
    let fe := Expr.fvar fv
    if hp.valueFVars.contains fe then continue
    bad := bad.push fe
  unless bad.isEmpty do
    throwFrontier m!"derive_rounds: ground evaluation of {what} \
      mentions non-value free variables {bad} (a Prop binder or a \
      foreign fvar reached a data position):{indentExpr r}"
  return r

/-- Ambient-pack `groundNorm`: hypothesis-aware iff a pack is active
    (byte-identical to `groundNorm` otherwise). -/
def hypNormA (what : String) (e : Expr) : TermElabM Expr := do
  match ← activeHypPack.get with
  | some hp => hypNorm hp what e
  | none => groundNorm what e

/-- Ambient-pack `evalGround` (see `evalGroundH`). -/
def evalGroundA (what : String) (e : Expr) : TermElabM Expr := do
  match ← activeHypPack.get with
  | some hp => evalGroundH hp what e
  | none => evalGround what e

/-- whnf, falling back to the deep hypothesis-aware normalizer when
    the plain whnf result does not satisfy the caller's shape check
    (open positions block whnf inside scrutinees; the deep pass
    exposes and rewrites them). -/
def hypWhnfCheck (what : String) (e : Expr) (p : Expr → Bool) :
    TermElabM Expr := do
  let r ← whnfU e
  if p r then return r
  match ← activeHypPack.get with
  | none => return r
  | some hp =>
    let r' ← hypNorm hp what r
    return r'

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
private def emitFlatDef (declName : Name) (fvars : Array Expr)
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

private def emitThm (thmName : Name) (fvars : Array Expr)
    (stmt proof : Expr) (doc : String) : TermElabM Unit := do
  let type ← defaultLevelMVars (← mkForallFVars fvars stmt)
  let value ← defaultLevelMVars (← mkLambdaFVars fvars proof)
  if type.hasExprMVar || value.hasExprMVar then
    throwError "derive_rounds: emitted {thmName} has metavariables"
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

/-! ## THE ARITH MINTER (arc-17 S3 — the S2b §5-identified recipe)

    The measured T4 frontier (S2b record §5): evaluation sticks on
    Int/Nat COMPARISON DECIDABLE TOWERS over pack-bounded binders
    (`match x + 2147483648 with | ofNat _ => isTrue … | negSucc _ =>
    isFalse …` — the inlined stdlib conv body), and a REWRITE cannot
    fix a stuck constructor-match. The minter turns each stuck tower
    into a registered verdict rewrite:

    * DECIDABLE lane: any stuck subterm `d` whose type is
      `Decidable p` is minted to `d = isTrue h` / `d = isFalse h` —
      the verdict bridge is proof irrelevance (`dec_eq_isTrue/False`
      below: every inhabitant of `Decidable p` equals the one the
      side fact dictates), the side fact `h : p`/`¬p` comes from
      OMEGA over the pack's range/apartness hypotheses (open case)
      or from the S0 discharger's kernel-decide contract
      (`of_decide_eq_true` + `Eq.refl`, ground case).
    * BOOL lane: stuck `Nat.ble/blt/beq` applications (the spellings
      Symbol-comparator/`symbolEquality` chains bottom out in when a
      seed-symbolic number meets a static hash) minted to their
      `true`/`false` verdicts through the registered bridge lemmas,
      side facts omega-backed the same way.

    Candidates are collected INNERMOST-FIRST (post-order) so the
    registered patterns stay small (kabstract-cheap); every minted
    fact is an ordinary named theorem (`<base>_hf<i>`, ∀-closed over
    the command telescope) the kernel re-checks at addDecl. The
    registry is grown empirically and FAIL-CLOSED: an unminted stuck
    shape leaves the consumer's frontier to fire with the term
    printed.

    *Lineage (canon-first)*: decision procedures at the leaves —
    omega is the canonical Presburger engine, kernel-decide is the S0
    ACL2Lean-donor contract; the verdict-rewrite framing is ordinary
    conditional rewriting (the hypothesis-mode design), not a new
    proof method. -/

/-- Verdict bridge, positive: every `Decidable p` inhabitant is
    `isTrue h` once `h : p` is in hand (proof irrelevance makes the
    isTrue arm `rfl`). -/
theorem dec_eq_isTrue {p : Prop} (h : p) :
    ∀ d : Decidable p, d = .isTrue h
  | .isTrue _ => rfl
  | .isFalse hn => absurd h hn

/-- Verdict bridge, negative. -/
theorem dec_eq_isFalse {p : Prop} (h : ¬p) :
    ∀ d : Decidable p, d = .isFalse h
  | .isTrue hp => absurd hp h
  | .isFalse _ => rfl

/-! Bool-lane bridges (kernel-cheap; stated at the exact stuck
    spellings `Nat.ble/blt/beq`). -/

theorem nat_ble_true {a b : Nat} (h : a ≤ b) : Nat.ble a b = true :=
  Nat.ble_eq.mpr h

theorem nat_ble_false {a b : Nat} (h : ¬ a ≤ b) : Nat.ble a b = false := by
  cases hb : Nat.ble a b with
  | true => exact absurd (Nat.ble_eq.mp hb) h
  | false => rfl

theorem nat_blt_true {a b : Nat} (h : a < b) : Nat.blt a b = true :=
  Nat.blt_eq.mpr h

theorem nat_blt_false {a b : Nat} (h : ¬ a < b) : Nat.blt a b = false := by
  cases hb : Nat.blt a b with
  | true => exact absurd (Nat.blt_eq.mp hb) h
  | false => rfl

theorem nat_beq_true {a b : Nat} (h : a = b) : Nat.beq a b = true := by
  subst h; simp [Nat.beq_refl]

theorem nat_beq_false {a b : Nat} (h : ¬ a = b) : Nat.beq a b = false := by
  cases hb : Nat.beq a b with
  | true => exact absurd (Nat.eq_of_beq_eq_true hb) h
  | false => rfl

/-! Lem Bool-comparator bridges (`natLtb`-family: `Bool := a < b`
    decide-coercions; proofs are `decide_eq_true/false` at the folded
    spelling). -/

theorem natLtb_true {a b : Nat} (h : a < b) : natLtb a b = true := decide_eq_true h
theorem natLtb_false {a b : Nat} (h : ¬ a < b) : natLtb a b = false := decide_eq_false h
theorem natLteb_true {a b : Nat} (h : a ≤ b) : natLteb a b = true := decide_eq_true h
theorem natLteb_false {a b : Nat} (h : ¬ a ≤ b) : natLteb a b = false := decide_eq_false h
theorem natGteb_true {a b : Nat} (h : a ≥ b) : natGteb a b = true := decide_eq_true h
theorem natGteb_false {a b : Nat} (h : ¬ a ≥ b) : natGteb a b = false := decide_eq_false h
theorem intLtb_true {a b : Int} (h : a < b) : intLtb a b = true := decide_eq_true h
theorem intLtb_false {a b : Int} (h : ¬ a < b) : intLtb a b = false := decide_eq_false h
theorem intLteb_true {a b : Int} (h : a ≤ b) : intLteb a b = true := decide_eq_true h
theorem intLteb_false {a b : Int} (h : ¬ a ≤ b) : intLteb a b = false := decide_eq_false h
theorem intGtb_true {a b : Int} (h : a > b) : intGtb a b = true := decide_eq_true h
theorem intGtb_false {a b : Int} (h : ¬ a > b) : intGtb a b = false := decide_eq_false h
theorem intGteb_true {a b : Int} (h : a ≥ b) : intGteb a b = true := decide_eq_true h
theorem intGteb_false {a b : Int} (h : ¬ a ≥ b) : intGteb a b = false := decide_eq_false h

theorem verdict_transfer_true {p q : Prop} (h : p = q) (hq : q) : p :=
  h ▸ hq
theorem verdict_transfer_false {p q : Prop} (h : p = q) (hnq : ¬q) :
    ¬p := h ▸ hnq

theorem bool_ne_false_of_true {b : Bool} (h : b = true) :
    ¬ b = false := by simp [h]
theorem bool_ne_true_of_false {b : Bool} (h : b = false) :
    ¬ b = true := by simp [h]

/-! decide-shape bridges (the outer-tower lane). -/

theorem decide_not_false {p : Prop} [Decidable p] (h : p) :
    ¬ (decide p = false) := by simp [decide_eq_true h]

theorem decide_not_true {p : Prop} [Decidable p] (h : ¬p) :
    ¬ (decide p = true) := by simp [decide_eq_false h]

/-! Symbol-comparator bridges (the env-lookup lane; the captured
    comparator is Kit/Map's `symCmpO`). -/

theorem symCmpO_ne_num {d1 d2 : String} {n1 n2 : Nat}
    {sd1 sd2 : symbol_description} (hd : d1 = d2) (h : n1 ≠ n2) :
    ¬ RelSem.Kit.symCmpO (Symbol d1 n1 sd1) (Symbol d2 n2 sd2)
      = .eq := by
  subst hd
  exact fun hc =>
    h ((RelSem.Kit.symCmpO_eq_iff d1 d1 n1 n2 sd1 sd2).mp hc).2

theorem symCmpO_eq_same (d : String) (n : Nat)
    (sd1 sd2 : symbol_description) :
    RelSem.Kit.symCmpO (Symbol d n sd1) (Symbol d n sd2) = .eq :=
  (RelSem.Kit.symCmpO_eq_iff d d n n sd1 sd2).mpr ⟨rfl, rfl⟩

/-! `Int.NonNeg` bridges (omega treats `NonNeg` as an opaque atom —
    measured; route through `0 ≤ a`, which is `NonNeg (a - 0)`
    definitionally). -/

theorem int_nonneg_of_le {a : Int} (h : 0 ≤ a) : a.NonNeg := by
  have h' : Int.NonNeg (a - 0) := h
  simpa using h'

theorem int_not_nonneg_of_lt {a : Int} (h : a < 0) : ¬ a.NonNeg :=
  fun hn => by
    have h' : (0 : Int) ≤ a := by
      have : Int.NonNeg (a - 0) := by simpa using hn
      exact this
    omega

/-- Bool-lane registry (v1; grown empirically, fail-closed). -/
private def registryBoolHead (c : Name) : Bool :=
  c == ``Nat.ble || c == ``Nat.blt || c == ``Nat.beq ||
  c == ``natLtb || c == ``natLteb || c == ``natGteb ||
  c == ``intLtb || c == ``intLteb || c == ``intGtb || c == ``intGteb

/-- Decidable-instance heads worth testing BEFORE whnf explodes them
    (post-explosion towers are caught by the matcher filter). -/
private def registryDecHead (c : Name) : Bool :=
  c == ``Nat.decLt || c == ``Nat.decLe || c == ``Nat.decEq ||
  c == ``Int.decLt || c == ``Int.decLe || c == ``Int.decEq ||
  c == ``Int.decNonneg ||
  c == ``instDecidableEqNat || c == ``Int.instDecidableEq ||
  c == ``instDecidableEqBool

/-- Recursor-like heads: whnf's smart unfolding leaves stuck towers
    as raw `rec`/`casesOn` applications (the S2b "raw Acc.rec towers"
    observation), not just matcher auxiliaries. -/
private def recLikeHead (env : Environment) (c : Name) : Bool :=
  match env.find? c with
  | some (.recInfo _) => true
  | _ => c.isStr &&
      (c.getString! == "casesOn" || c.getString! == "recOn")

/-- Candidate collection: post-order (children before parents, so the
    INNERMOST stuck tower is minted first and patterns stay small),
    share-deduped; `inferType` is gated behind the syntactic filter
    (matcher/recursor apps + registry heads). -/
private partial def collectMintCands (root : Expr) :
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

/-- Speculative tactic proof of `goal` (omega); state fully restored
    on failure (messages included — a failed attempt must not poison
    the log). -/
private def tryOmegaProof (goal : Expr) : TermElabM (Option Expr) := do
  let s ← saveState
  try
    let pf ← Term.withoutErrToSorry do
      let pf ← Term.elabTermEnsuringType (← `(by omega)) goal
      Term.synthesizeSyntheticMVarsNoPostponing
      instantiateMVars pf
    if pf.hasSorry || pf.hasExprMVar then
      s.restore
      return none
    return some pf
  catch _ =>
    s.restore
    return none

/-- Ground verdict by the S0 kernel-decide contract (donor pattern:
    synthesize, whnf at `.all` — attribute-blind, so fence-stuck
    ground comparisons resolve here — demand a literal, emit
    `of_decide_eq_true/false` + `Eq.refl`; the kernel recomputes at
    addDecl). -/
private def kernelVerdict (p : Expr) : TermElabM (Option (Bool × Expr)) := do
  try
    let inst ← synthInstance (mkApp (mkConst ``Decidable) p)
    let r ← withTransparency .all <| whnf (mkApp2 (mkConst ``decide) p inst)
    if r.isConstOf ``Bool.true then
      return some (true, mkApp3 (mkConst ``of_decide_eq_true) p inst
        (mkApp2 (mkConst ``Eq.refl [1]) (mkConst ``Bool) (mkConst ``Bool.true)))
    if r.isConstOf ``Bool.false then
      return some (false, mkApp3 (mkConst ``of_decide_eq_false) p inst
        (mkApp2 (mkConst ``Eq.refl [1]) (mkConst ``Bool) (mkConst ``Bool.false)))
    return none
  catch _ => return none

/-- DEFEQ-PRESERVING refold of Int-primitive spellings into the
    notation vocabulary omega reads (measured: omega atomizes the raw
    op spellings — `Int.add x c > 0` fails where `x + c > 0`
    succeeds). Two folding layers, both definitional so a proof of
    the folded Prop kernel-checks at the original spelling:

    * op-constant spellings (`Int.add a b` → `a + b`; `subNatNat m n`
      ≡ `(↑m) - (↑n)` by delta/iota);
    * MATCHER spellings — whnf on a stuck operand smears an Int op
      through its constructor match (the round-18 dump: `match x,
      Int.ofNat c with | ofNat m, ofNat n => ofNat (m+n) | …`); a
      matcher app whose type is Int is probed by `isDefEq` against
      the candidate ops at its own scrutinees (both sides unfold to
      the same match, so the probe is cheap and exact). Post-order:
      scrutinees are already folded when the probe fires. -/
private def foldArith (e : Expr) : MetaM Expr :=
  Core.transform e (post := fun n => do
    -- nodes under binders carry loose bvars — type inference (mkAppM)
    -- cannot run there; leave them as spelled
    if n.hasLooseBVars then return .done n
    let fn := n.getAppFn
    let .const c _ := fn | return .done n
    let args := n.getAppArgs
    let fold2 (f : Name) : MetaM TransformStep := do
      if args.size == 2 then
        return .done (← mkAppMU f #[args[0]!, args[1]!])
      return .done n
    if c == ``Int.ofNat && args.size == 1 then
      -- omega atomizes raw `Int.ofNat` (measured: literal AND cast
      -- forms); refold to the OfNat/Nat.cast notation it reads
      match args[0]! with
      | .lit (.natVal _) =>
        return .done (← mkAppOptMU ``OfNat.ofNat
          #[some (mkConst ``Int), some args[0]!, none])
      | _ =>
        return .done (← mkAppOptMU ``Nat.cast
          #[some (mkConst ``Int), none, some args[0]!])
    else if c == ``Int.add then fold2 ``HAdd.hAdd
    else if c == ``Int.sub then fold2 ``HSub.hSub
    else if c == ``Int.mul then fold2 ``HMul.hMul
    else if c == ``Int.ediv then fold2 ``HDiv.hDiv
    else if c == ``Int.emod then fold2 ``HMod.hMod
    else if c == ``Int.lt then fold2 ``LT.lt
    else if c == ``Int.le then fold2 ``LE.le
    else if c == ``Nat.lt then fold2 ``LT.lt
    else if c == ``Nat.le then fold2 ``LE.le
    else if c == ``Int.neg && args.size == 1 then
      return .done (← mkAppMU ``Neg.neg #[args[0]!])
    else if c == ``Int.negOfNat && args.size == 1 then
      return .done (← mkAppMU ``Neg.neg
        #[mkApp (mkConst ``Int.ofNat) args[0]!])
    else if c == ``Int.subNatNat && args.size == 2 then
      return .done (← mkAppMU ``HSub.hSub
        #[mkApp (mkConst ``Int.ofNat) args[0]!,
          mkApp (mkConst ``Int.ofNat) args[1]!])
    else if isMatcherAppCore (← getEnv) n then
      -- matcher refold: probe Int-typed matcher apps against the op
      -- table at their own scrutinees
      let ty ← whnf (← inferType n)
      unless ty.isConstOf ``Int do return .done n
      let some ma ← Lean.Meta.matchMatcherApp? n | return .done n
      let discrs := ma.discrs
      let mut allInt := true
      for dsc in discrs do
        unless (← whnf (← inferType dsc)).isConstOf ``Int do
          allInt := false
      unless allInt do return .done n
      let cands : Array Expr ← do
        if discrs.size == 2 then
          pure #[← mkAppMU ``HAdd.hAdd #[discrs[0]!, discrs[1]!],
                 ← mkAppMU ``HSub.hSub #[discrs[0]!, discrs[1]!],
                 ← mkAppMU ``HMul.hMul #[discrs[0]!, discrs[1]!]]
        else if discrs.size == 1 then
          pure #[← mkAppMU ``Neg.neg #[discrs[0]!]]
        else pure #[]
      for cand in cands do
        if ← withNewMCtxDepth (isDefEq n cand) then
          return .done cand
      return .done n
    else return .done n)

/-- Open-case verdict: omega on `p`, then on `¬p`. -/
private def openVerdict (p : Expr) : TermElabM (Option (Bool × Expr)) := do
  if let some pf ← tryOmegaProof p then return some (true, pf)
  if let some pf ← tryOmegaProof (mkApp (mkConst ``Not) p) then
    return some (false, pf)
  return none

/-- Emit a minted SIDE FACT (`<base>_hs<i>`: the omega/kernel-decided
    Prop, ∀-closed) and return the NAMED reference applied to the
    telescope. The raw proof term must NEVER be inlined into the
    verdict rhs: an omega certificate can itself contain the stuck
    comparison spelling (measured this slice — the substitution then
    re-inserts its own pattern every pass, an unbounded drip), and
    the named constant keeps the substituted states small. -/
private def mintEmitSide (hp : HypPack) (stmt pf : Expr) (what : String) :
    TermElabM Expr := do
  let idx ← hp.mintIdx.get
  hp.mintIdx.set (idx + 1)
  let name := (hp.baseName.appendAfter "s").appendAfter (toString idx)
  -- close over (and reference with) only the binders the fact
  -- actually uses — a GROUND fact referenced with the full telescope
  -- drags the Prop binders into every substitution site (measured:
  -- the T5 entry probe's successor-def fvar leak)
  let used := hp.fvars.filter (fun fv =>
    stmt.containsFVar fv.fvarId! || pf.containsFVar fv.fvarId!)
  emitThm name used stmt pf
    s!"Arith-minter side fact ({what}). {provenanceNote "derive_rounds"}"
  return mkAppN (mkConst name) used

/-- Emit a minted verdict fact (`<base>_hf<i>`, ∀-closed over the
    telescope, kernel-checked) and register its rewrite. Fail-closed:
    the rhs must not contain the pattern (the self-insertion drip). -/
private def mintEmit (hp : HypPack) (d rhs prf : Expr) (what : String) :
    TermElabM Unit := do
  if (rhs.find? (· == d)).isSome then
    throwError "derive_rounds: arith-minter verdict rhs contains its \
      own pattern (self-inserting rewrite):{indentExpr rhs}"
  let idx ← hp.mintIdx.get
  hp.mintIdx.set (idx + 1)
  let name := hp.baseName.appendAfter (toString idx)
  let stmt ← mkEq d rhs
  let used := hp.fvars.filter (fun fv =>
    stmt.containsFVar fv.fvarId! || prf.containsFVar fv.fvarId!)
  emitThm name used stmt prf
    s!"Arith-minter fact ({what}). {provenanceNote "derive_rounds"}"
  let rw : HypRw :=
    { lhs := d, rhs := rhs, prf := mkAppN (mkConst name) used,
      syntactic := true }
  hp.minted.modify (·.push rw)
  trace[RelSem.roundEval] "arith minter: {name} ({what})"

/-- The Bool-head prop table (shared by the Bool lane and the
    decide-shape lane's registry-scrutinee case): head constant ↦
    (relational Prop, true-bridge, false-bridge). -/
private def boolHeadProp? (c : Name) (a b : Expr) :
    TermElabM (Option (Expr × Name × Name)) := do
  if c == ``Nat.ble then
    return some (← mkAppMU ``LE.le #[a, b],
      ``RelSem.RoundEval.nat_ble_true, ``RelSem.RoundEval.nat_ble_false)
  else if c == ``Nat.blt then
    return some (← mkAppMU ``LT.lt #[a, b],
      ``RelSem.RoundEval.nat_blt_true, ``RelSem.RoundEval.nat_blt_false)
  else if c == ``Nat.beq then
    return some (← mkAppMU ``Eq #[a, b],
      ``RelSem.RoundEval.nat_beq_true, ``RelSem.RoundEval.nat_beq_false)
  else if c == ``natLtb then
    return some (← mkAppMU ``LT.lt #[a, b],
      ``RelSem.RoundEval.natLtb_true, ``RelSem.RoundEval.natLtb_false)
  else if c == ``natLteb then
    return some (← mkAppMU ``LE.le #[a, b],
      ``RelSem.RoundEval.natLteb_true, ``RelSem.RoundEval.natLteb_false)
  else if c == ``natGteb then
    return some (← mkAppMU ``GE.ge #[a, b],
      ``RelSem.RoundEval.natGteb_true, ``RelSem.RoundEval.natGteb_false)
  else if c == ``intLtb then
    return some (← mkAppMU ``LT.lt #[a, b],
      ``RelSem.RoundEval.intLtb_true, ``RelSem.RoundEval.intLtb_false)
  else if c == ``intLteb then
    return some (← mkAppMU ``LE.le #[a, b],
      ``RelSem.RoundEval.intLteb_true, ``RelSem.RoundEval.intLteb_false)
  else if c == ``intGtb then
    return some (← mkAppMU ``GT.gt #[a, b],
      ``RelSem.RoundEval.intGtb_true, ``RelSem.RoundEval.intGtb_false)
  else if c == ``intGteb then
    return some (← mkAppMU ``GE.ge #[a, b],
      ``RelSem.RoundEval.intGteb_true, ``RelSem.RoundEval.intGteb_false)
  else return none

/-- ITERATIVE BOOL-TOWER CLOSER (arc-17 S3): drive a stuck Bool term
    to a literal by alternating (scoped) whnf hops — bridged by
    kernel-deferred refls — with inner-decidable verdict
    substitutions — bridged by congrArg over the proof-irrelevance
    verdict — until a literal falls out. Returns `(lit, h : b = lit)`.
    The verdict search is passed in (breaks the mutual recursion with
    `propVerdict`). -/
private partial def closeBoolTower
    (verdict : Expr → TermElabM (Option (Bool × Expr)))
    (b0 : Expr) (cdepth : Nat := 0) :
    TermElabM (Option (Expr × Expr)) := do
  if cdepth > 10 then return none
  let mut bCur := b0
  let mut chain : Option Expr := none   -- : b0 = bCur (syntactic)
  for _ in [0:32] do
    let bv ← (try withCurrHeartbeats (whnf bCur) catch _ => pure bCur)
    if bv != bCur then
      let br ← mkExpectedTypeHint (← mkEqRefl bv) (← mkEq bCur bv)
      chain := some (← match chain with
        | none => pure br
        | some c => mkEqTrans c br)
      bCur := bv
    if bCur.isConstOf ``Bool.true || bCur.isConstOf ``Bool.false then
      let hFin ← match chain with
        | some c => pure c
        | none => mkExpectedTypeHint (← mkEqRefl bCur) (← mkEq b0 bCur)
      return some (bCur, hFin)
    -- registry-headed towers close directly through the bridges
    -- (`BEq.beq` at Nat routes through the Nat.beq bridges — the
    -- conclusions are defeq, carried by the type hint below)
    let regArgs? : Option (Name × Expr × Expr) :=
      match bCur.getAppFn with
      | .const bc _ =>
        let args := bCur.getAppArgs
        if args.size == 2 then some (bc, args[0]!, args[1]!)
        else if bc == ``BEq.beq && args.size == 4
            && args[0]!.isConstOf ``Nat then
          some (``Nat.beq, args[2]!, args[3]!)
        else none
      | _ => none
    if let some (bc, aA, aB) := regArgs? then
        if let some (q0, brTrue, brFalse) ← boolHeadProp? bc aA aB then
          let q ← foldArith q0
          if let some (polq, pfq) ← verdict q then
            let hV ← if polq then mkAppMU brTrue #[pfq]
                     else mkAppMU brFalse #[pfq]
            let litE := if polq then mkConst ``Bool.true
                        else mkConst ``Bool.false
            let hV ← mkExpectedTypeHint hV (← mkEq bCur litE)
            let hFin ← match chain with
              | some c => mkEqTrans c hV
              | none => pure hV
            return some (litE, hFin)
          return none
    let mut progressed := false
    -- Bool.rec / Bool-matcher over a stuck scrutinee: close the
    -- scrutinee recursively and substitute (the race-check
    -- `Bool.rec (…) (…) ((fun x => …) (DA_pos …))` shape)
    let major? : Option Expr ← (do
      if bCur.isAppOf ``Bool.rec && bCur.getAppArgs.size ≥ 1 then
        return some bCur.getAppArgs.back!
      if let some ma ← Lean.Meta.matchMatcherApp? bCur then
        if ma.discrs.size ≥ 1 then
          let dsc := ma.discrs[0]!
          let tyD ← whnfU (← inferType dsc)
          if tyD.isConstOf ``Bool then return some dsc
      return none)
    if let some major := major? then
      unless major.isConstOf ``Bool.true
          || major.isConstOf ``Bool.false do
        let step? ← (try
          (do
            let some (lit', hSub) ←
                closeBoolTower verdict major (cdepth + 1) | return none
            let abst ← abstractExact bCur major
            unless abst.hasLooseBVars do return none
            let bNext := abst.instantiate1 lit'
            let motive := Lean.mkLambda `x .default
              (← inferType major) abst
            let piece ← mkExpectedTypeHint (← mkCongrArg motive hSub)
              (← mkEq bCur bNext)
            return some (bNext, piece)
            : TermElabM (Option (Expr × Expr)))
          catch _ => pure none)
        if let some (bNext, piece) := step? then
          chain := some (← match chain with
            | none => pure piece
            | some c => mkEqTrans c piece)
          bCur := bNext
          progressed := true
    -- find an inner stuck decidable and substitute its verdict
    let inners ← collectMintCands bCur
    for d' in inners do
      if progressed then continue
      if d' == bCur then continue
      if d'.isAppOf ``Decidable.isTrue
          || d'.isAppOf ``Decidable.isFalse then continue
      let step? ← (try
        (do
          let tyW' ← whnfU (← inferType d')
          let mut sub? : Option (Expr × Expr) := none  -- (vTerm, hIn)
          if tyW'.isAppOfArity ``Decidable 1 then
            let q' ← foldArith (← withCurrHeartbeats
              (groundNorm "inner prop" tyW'.appArg!))
            if !(q'.hasExprMVar || q'.hasLooseBVars) then
            if let some (polq, pfq) ← verdict q' then
              let vTerm := if polq then
                  mkApp2 (mkConst ``Decidable.isTrue) q' pfq
                else mkApp2 (mkConst ``Decidable.isFalse) q' pfq
              let hIn := if polq then
                  mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isTrue)
                    q' pfq d'
                else mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isFalse)
                    q' pfq d'
              sub? := some (vTerm, hIn)
          else if tyW'.isConstOf ``Bool && d'.isApp then
            -- Bool-typed inner tower: close recursively
            if let some (lit', hSub) ←
                closeBoolTower verdict d' (cdepth + 1) then
              sub? := some (lit', hSub)
          if sub?.isNone then
            trace[RelSem.roundEval] "closeBoolTower: inner {d'.getAppFn} no verdict"
          let some (vTerm, hIn) := sub? | return none
          -- self-insertion guard (the mintEmit drip lesson)
          if (vTerm.find? (· == d')).isSome then return none
          let abst ← abstractExact bCur d'
          unless abst.hasLooseBVars do return none
          let bNext := abst.instantiate1 vTerm
          let motive := Lean.mkLambda `x .default (← inferType d') abst
          let piece ← mkExpectedTypeHint (← mkCongrArg motive hIn)
            (← mkEq bCur bNext)
          return some (bNext, piece)
          : TermElabM (Option (Expr × Expr)))
        catch ex => (do
          trace[RelSem.roundEval] "closeBoolTower: inner {d'.getAppFn} threw: {ex.toMessageData}"
          pure none))
      if let some (bNext, piece) := step? then
        trace[RelSem.roundEval] "closeBoolTower: subst {d'.getAppFn} ({← bCur.numObjs} → {← bNext.numObjs} objs)"
        chain := some (← match chain with
          | none => pure piece
          | some c => mkEqTrans c piece)
        bCur := bNext
        progressed := true
    unless progressed do
      -- last resort: the DIG hop (smart-unfolding-off `.all` whnf)
      -- exposes towers hidden inside folded definitions; a defeq hop
      let r ← (try
          withCurrHeartbeats <|
            withOptions (fun o => o.set `smartUnfolding false) <|
              withTransparency .all (whnf bCur)
        catch _ => pure bCur)
      if r != bCur then
        let br ← mkExpectedTypeHint (← mkEqRefl r) (← mkEq bCur r)
        chain := some (← match chain with
          | none => pure br
          | some c => mkEqTrans c br)
        bCur := r
      else
        trace[RelSem.roundEval] "closeBoolTower: stuck ({← bCur.numObjs} objs, head {bCur.getAppFn}):{indentExpr bCur}"
        return none
  trace[RelSem.roundEval] "closeBoolTower: fuel out"
  return none

/-- THE PROP-VERDICT SEARCH (shared by the decidable and decide-shape
    lanes; recursion depth-capped). Lanes: `Int.NonNeg` (omega-opaque;
    bridged through `0 ≤ a`); `decide q = true/false` (the tower
    OVER a decide — its truth reduces to `q`'s, and minting it
    substitutes the whole dependent cluster ATOMICALLY, which the
    type-check guard demands); open omega; ground kernel decide. -/
private partial def propVerdict (p : Expr) (depth : Nat := 0) :
    TermElabM (Option (Bool × Expr)) := do
  if depth > 10 then return none
  -- syntactic-refl fast path (a = a): omega's certificate for a
  -- reflexive equality can embed the enclosing tower (measured drip);
  -- Eq.refl is the clean witness
  if let some (_, a, b) := p.eq? then
    if a == b then
      return some (true, ← mkEqRefl a)
  -- Int.NonNeg face
  if p.isAppOfArity ``Int.NonNeg 1 then
    let a := p.appArg!
    let zero ← mkAppOptMU ``OfNat.ofNat
      #[some (mkConst ``Int), some (mkRawNatLit 0), none]
    if let some pf ← tryOmegaProof (← mkAppMU ``LE.le #[zero, a]) then
      return some (true,
        ← mkAppMU ``RelSem.RoundEval.int_nonneg_of_le #[pf])
    if let some pf ← tryOmegaProof (← mkAppMU ``LT.lt #[a, zero]) then
      return some (false,
        ← mkAppMU ``RelSem.RoundEval.int_not_nonneg_of_lt #[pf])
    return none
  -- decide-shape face: p = (decide q inst = lit) with the decide
  -- possibly in its unfolded Decidable.rec spelling
  if p.isAppOfArity ``Eq 3 then
    let args := p.getAppArgs
    if args[0]!.isConstOf ``Bool then
      let b := args[1]!
      let lit := args[2]!
      let litT := lit.isConstOf ``Bool.true
      let litF := lit.isConstOf ``Bool.false
      -- closed props go to the kernel lane below
      if (litT || litF) && p.hasFVar then
        -- unwrap IDENTITY matcher debris (`match X with | false =>
        -- false | true => true` from unfolded decide towers): a
        -- single-discr matcher defeq to its own discriminant IS its
        -- discriminant (isDefEq-probed, exact)
        let mut b := b
        for _ in [0:4] do
          let stop ← (do
            if let some ma ← Lean.Meta.matchMatcherApp? b then
              if ma.discrs.size == 1 then
                if ← withNewMCtxDepth
                    (withCurrHeartbeats (isDefEq b ma.discrs[0]!)) then
                  return some ma.discrs[0]!
            return none)
          match stop with
          | some d' => b := d'
          | none => break
        -- registry-headed scrutinee: `(intLteb a b) = lit`-class
        if let .const bc _ := b.getAppFn then
          if b.getAppArgs.size == 2 then
            if let some (q0, brTrue, brFalse) ← boolHeadProp? bc
                b.getAppArgs[0]! b.getAppArgs[1]! then
              let q ← foldArith q0
              if let some (polq, pfq) ← propVerdict q (depth + 1) then
                if polq then
                  let hbt ← mkAppMU brTrue #[pfq]  -- b = true
                  if litT then return some (true, hbt)
                  else return some (false, ← mkAppMU
                    ``RelSem.RoundEval.bool_ne_false_of_true #[hbt])
                else
                  let hbf ← mkAppMU brFalse #[pfq]  -- b = false
                  if litF then return some (true, hbf)
                  else return some (false, ← mkAppMU
                    ``RelSem.RoundEval.bool_ne_true_of_false #[hbf])
              return none
        let qi? : Option (Expr × Expr) ← (do
          if b.isAppOfArity ``decide 2 then
            return some (b.getAppArgs[0]!, b.getAppArgs[1]!)
          if b.isAppOf ``Decidable.rec && b.getAppArgs.size ≥ 1 then
            let major := b.getAppArgs.back!
            let mty ← whnfU (← inferType major)
            if mty.isAppOfArity ``Decidable 1 then
              return some (mty.appArg!, major)
          return none)
        if let some (q0, inst) := qi? then
          let q ← foldArith q0
          if let some (polq, pfq) ← propVerdict q (depth + 1) then
            -- b = true iff q; combine with the literal
            let mk (f : Name) (pf : Expr) : TermElabM Expr :=
              mkAppOptMU f #[some q, some inst, some pf]
            if polq && litT then
              return some (true, ← mk ``decide_eq_true pfq)
            if polq && litF then
              return some (false,
                ← mk ``RelSem.RoundEval.decide_not_false pfq)
            if !polq && litT then
              return some (false,
                ← mk ``RelSem.RoundEval.decide_not_true pfq)
            if !polq && litF then
              return some (true, ← mk ``decide_eq_false pfq)
          return none
        -- ITERATIVE TOWER CLOSURE (arc-17 S3): drive b to a literal
        match ← closeBoolTower (fun q => propVerdict q (depth + 1)) b with
        | some (litE, hFull) =>
          let ok ← (try
              withCurrHeartbeats (check hFull)
              pure true
            catch _ => pure false)
          if ok then
            let bvT := litE.isConstOf ``Bool.true
            if bvT == litT then
              return some (true, hFull)
            else if litT then
              return some (false, ← mkAppMU
                ``RelSem.RoundEval.bool_ne_true_of_false #[hFull])
            else
              return some (false, ← mkAppMU
                ``RelSem.RoundEval.bool_ne_false_of_true #[hFull])
        | none => pure ()
        return none
  match ← (if p.hasFVar then openVerdict p else kernelVerdict p) with
  | some r => return some r
  | none =>
  -- GENERALIZED INNER-VERDICT LANE (arc-17 S3): substitute the
  -- innermost stuck decidable's verdict INTO THE PROP, recurse, and
  -- transfer through the congrArg equality (`p = p[d' := verdict]`)
  -- — the discovery's mixed race-check towers land here.
  if depth ≥ 8 then return none
  unless p.hasFVar do return none
  let inners ← collectMintCands p
  for d' in inners do
    if d'.isAppOf ``Decidable.isTrue
        || d'.isAppOf ``Decidable.isFalse then continue
    if d' == p then continue
    let r? ← (try
      (do
        let tyW' ← whnfU (← inferType d')
        unless tyW'.isAppOfArity ``Decidable 1 do return none
        let q' ← foldArith (← withCurrHeartbeats
          (groundNorm "inner prop" tyW'.appArg!))
        if q'.hasExprMVar || q'.hasLooseBVars then return none
        let some (polq, pfq) ← propVerdict q' (depth + 1) | return none
        let vTerm := if polq then
            mkApp2 (mkConst ``Decidable.isTrue) q' pfq
          else mkApp2 (mkConst ``Decidable.isFalse) q' pfq
        let abst ← abstractExact p d'
        unless abst.hasLooseBVars do return none
        let p' := abst.instantiate1 vTerm
        let hIn := if polq then
            mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isTrue) q' pfq d'
          else mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isFalse) q' pfq d'
        let motive := Lean.mkLambda `x .default (← inferType d') abst
        let hEq ← mkExpectedTypeHint (← mkCongrArg motive hIn)
          (← mkEq p p')
        let pNorm ← foldArith (← withCurrHeartbeats
          (groundNorm "subst prop" p'))
        let some (pol', pf') ← propVerdict pNorm (depth + 1)
          | return none
        withCurrHeartbeats (check hEq)
        if pol' then
          return some (true, ← mkAppOptMU
            ``RelSem.RoundEval.verdict_transfer_true
            #[some p, some p', some hEq, some pf'])
        else
          return some (false, ← mkAppOptMU
            ``RelSem.RoundEval.verdict_transfer_false
            #[some p, some p', some hEq, some pf'])
        : TermElabM (Option (Bool × Expr)))
      catch _ => pure none)
    if let some r := r? then return some r
  return none

/-- Decidable lane. -/
private def mintDecidable (hp : HypPack) (d : Expr) : TermElabM Bool := do
  let tyW ← whnf (← instantiateMVars (← inferType d))
  unless tyW.isAppOfArity ``Decidable 1 do return false
  -- the Prop quotes the TYPE-level spelling, which may carry
  -- unreduced ground subterms (a minIval match over a constructor);
  -- normalize before folding so omega sees literals
  let p0 ← instantiateMVars tyW.appArg!
  let p ← foldArith (← withCurrHeartbeats (groundNorm "mint prop" p0))
  if p.hasExprMVar || p.hasLooseBVars then return false
  let v? ← propVerdict p
  let some (pol, pf) := v?
    | (do trace[RelSem.roundEval] "arith minter: no verdict ({← p.numObjs} objs, head {p.getAppFn}) for{indentExpr p}"
          return false)
  if pol then
    let href ← mintEmitSide hp p pf "decidable/isTrue side"
    mintEmit hp d (mkApp2 (mkConst ``Decidable.isTrue) p href)
      (mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isTrue) p href d)
      "decidable → isTrue"
  else
    let href ← mintEmitSide hp (mkApp (mkConst ``Not) p) pf
      "decidable/isFalse side"
    mintEmit hp d (mkApp2 (mkConst ``Decidable.isFalse) p href)
      (mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isFalse) p href d)
      "decidable → isFalse"
  return true

/-- Bool lane (registry heads only). -/
private def mintBool (hp : HypPack) (d : Expr) : TermElabM Bool := do
  let .const c _ := d.getAppFn | return false
  let args := d.getAppArgs
  unless args.size == 2 do return false
  -- normalize the ARGS (ground matches reduce; the relation head
  -- itself must stay folded — normalizing the whole Prop unfolds
  -- `≤` into `NonNeg` and breaks the bridge shape, measured)
  let a ← withCurrHeartbeats (groundNorm "mint arg" args[0]!)
  let b ← withCurrHeartbeats (groundNorm "mint arg" args[1]!)
  let some (p, brTrue, brFalse) ← boolHeadProp? c a b | return false
  if p.hasExprMVar || p.hasLooseBVars then return false
  let p ← foldArith p
  let v? ← propVerdict p
  let some (pol, pf) := v? | return false
  if pol then
    let href ← mintEmitSide hp p pf s!"{c}/true side"
    mintEmit hp d (mkConst ``Bool.true) (← mkAppMU brTrue #[href])
      s!"{c} → true"
  else
    let href ← mintEmitSide hp (mkApp (mkConst ``Not) p) pf
      s!"{c}/false side"
    mintEmit hp d (mkConst ``Bool.false) (← mkAppMU brFalse #[href])
      s!"{c} → false"
  return true

/-- BOOL-TOWER LANE (arc-17 S3): a Bool-typed stuck matcher/recursor
    tower (a `cond` scrutinee, a race-check conjunction) closes by
    verdicting an inner stuck decidable, substituting INSIDE the
    tower only, and letting the kernel reduce the result to a
    literal — minted as an atomic `tower = lit` rewrite (the
    dependent-cluster-safe move the type-check guard demands). -/
private def mintBoolTower (hp : HypPack) (d : Expr) : TermElabM Bool := do
  let env ← getEnv
  let .const c _ := d.getAppFn | return false
  unless isMatcherAppCore env d || recLikeHead env c
    || c == ``cond do return false
  let ty ← whnfU (← inferType d)
  unless ty.isConstOf ``Bool do return false
  match ← closeBoolTower (fun q => propVerdict q 1) d with
  | some (litE, hFull) =>
    let ok ← (try
        withCurrHeartbeats (check hFull)
        pure true
      catch _ => pure false)
    unless ok do return false
    mintEmit hp d litE hFull "bool tower"
    return true
  | none => return false

/-- Symbol-constructor destructuring. -/
private def symParts? (e : Expr) : Option (Expr × Expr × Expr) :=
  if e.isAppOfArity ``Symbol 3 then
    let a := e.getAppArgs
    some (a[0]!, a[1]!, a[2]!)
  else none

/-- Built-ness prover for env-map spellings: recurse through
    `fmapAddBy` layers to an `Fmap.mk`-materialized base (captured
    comparator defeq `symCmpO` — rfl-grade). -/
private partial def proveBuilt (m : Expr) : TermElabM (Option Expr) := do
  if m.isAppOf ``fmapAddBy && m.getAppArgs.size == 7 then
    let a := m.getAppArgs
    let some hInner ← proveBuilt a[6]! | return none
    return some (← mkAppOptMU ``RelSem.Kit.fmapAddBy_built
      #[some a[0]!, some a[1]!, some a[2]!, none, some a[3]!,
        some a[4]!, some a[5]!, some a[6]!, some hInner])
  let stmt ← mkAppMU ``RelSem.Kit.FmapBuilt
    #[mkConst ``RelSem.Kit.symCmpO, m]
  -- pack-hypothesis base (free env binders: built-ness is a curated
  -- hypothesis, e.g. `hbuilt : FmapBuilt symCmpO env`)
  if let some hp ← (activeHypPack.get : BaseIO _) then
    for h in hp.arith do
      if (← instantiateMVars (← inferType h)) == stmt then
        return some h
  try
    withCurrHeartbeats <| Term.withoutErrToSorry do
      let pf ← Term.elabTermEnsuringType (← `(rfl)) stmt
      Term.synthesizeSyntheticMVarsNoPostponing
      let pf ← instantiateMVars pf
      if pf.hasSorry then throwError "sorry"
      return some pf
  catch _ => return none

/-- THE ENV-LOOKUP LANE (arc-17 S3 — the S2b-enumerated "anon-env
    rounds" subsystem): a stuck `fmapLookupBy cmp k (fmapAddBy cmp'
    k' v m)` (kept law-shaped by the env fence) is minted through
    Kit/Map's captured-comparator lookup laws — hit
    (`fmapLookupBy_addBy_eq`) when the keys agree syntactically, skip
    (`fmapLookupBy_addBy_ne`) when the same-digest numbers are apart
    (omega from the pack's seed-apartness hypothesis); built-ness of
    the underlying chain is derived mechanically. Fully-ground
    lookups never reach here (the `.all` escape computes them). -/
private def mintEnvLookup (hp : HypPack) (d : Expr) : TermElabM Bool := do
  unless d.isAppOf ``fmapLookupBy do return false
  let dArgs := d.getAppArgs
  unless dArgs.size == 5 do return false
  let key := dArgs[3]!
  let m := dArgs[4]!
  unless m.isAppOf ``fmapAddBy && m.getAppArgs.size == 7 do return false
  let mArgs := m.getAppArgs
  let k' := mArgs[4]!
  let v := mArgs[5]!
  let inner := mArgs[6]!
  let some hm ← proveBuilt inner
    | (do trace[RelSem.roundEval] "env lane: no built-ness for inner map"
          return false)
  let beqInst := mArgs[2]!
  let pcmp := mArgs[3]!
  let pcmp' := dArgs[2]!
  let symCmpOE := mkConst ``RelSem.Kit.symCmpO
  -- instances supplied from the TERM's own spelling (the R-S2-1
  -- instance-implicit-divergence lesson: synthesis picks a different
  -- BEq than the generated call site captured)
  let mkLaw (law : Name) (hk : Expr) (rhs : Expr) :
      TermElabM (Option Expr) := do
    let eqTy ← mkEq d rhs
    try
      withCurrHeartbeats <| Term.withoutErrToSorry do
        let pf ← mkAppOptMU law
          #[some (mkConst ``sym), none, some beqInst, some symCmpOE,
            none, some pcmp, some pcmp', some k', some key, some v,
            some inner, some hm, some hk]
        let pfTy ← instantiateMVars (← inferType pf)
        unless ← withCurrHeartbeats (isDefEq pfTy eqTy) do
          trace[RelSem.roundEval] "env lane: law type mismatch:{indentExpr pfTy}\nvs{indentExpr eqTy}"
          return none
        return some (← instantiateMVars pf)
    catch ex => (do
      trace[RelSem.roundEval] "env lane: law build failed: {ex.toMessageData}"
      return none)
  if k' == key then
    -- HIT: the just-inserted key reads back its value
    let some (dg, n, sd) := symParts? key | return false
    let hk ← mkAppMU ``RelSem.RoundEval.symCmpO_eq_same #[dg, n, sd, sd]
    let rhs ← mkAppMU ``Option.some #[v]
    let some pf ← mkLaw ``RelSem.Kit.fmapLookupBy_addBy_eq hk rhs
      | return false
    mintEmit hp d rhs pf "env lookup hit"
    return true
  -- SKIP: apartness of the two keys
  let some (dg1, n1, sd1) := symParts? k' | return false
  let some (dg2, n2, sd2) := symParts? key | return false
  unless dg1 == dg2 do return false
  let neStmt ← mkAppMU ``Ne #[← foldArith n1, ← foldArith n2]
  let pfNe? ← (do
    match ← propVerdict neStmt with
    | some (true, pf) => return some pf
    | _ => tryOmegaProof neStmt)
  let some pfNe := pfNe? | (do
    trace[RelSem.roundEval] "env lane: apartness unprovable: {neStmt}"
    return false)
  let hrefNe ← mintEmitSide hp neStmt pfNe "env-key apartness"
  let hk ← mkAppOptMU ``RelSem.RoundEval.symCmpO_ne_num
    #[some dg1, some dg2, some n1, some n2, some sd1, some sd2,
      some (← mkEqRefl dg1), some hrefNe]
  let rhs := mkAppN d.getAppFn (dArgs.set! 4 inner)
  let some pf ← mkLaw ``RelSem.Kit.fmapLookupBy_addBy_ne hk rhs
    | return false
  mintEmit hp d rhs pf "env lookup skip"
  return true

/-- Int-literal extraction at kernel reduction strength (closed
    ground spellings only). -/
private def groundIntLit? (e : Expr) : MetaM (Option Int) := do
  if e.hasFVar then return none
  let e ← withOptions (smartUnfolding.set · false) <|
    withTransparency .all <| whnf e
  match_expr e with
  | Int.ofNat n =>
    let n ← withOptions (smartUnfolding.set · false) <|
      withTransparency .all <| whnf n
    return (n.rawNatLit? <|> n.nat?).map Int.ofNat
  | Int.negSucc n =>
    let n ← withOptions (smartUnfolding.set · false) <|
      withTransparency .all <| whnf n
    return (n.rawNatLit? <|> n.nat?).map Int.negSucc
  | _ => return none

/-- List-literal spine length (syntactic `List.cons` chain). -/
private partial def listSpineLen? (e : Expr) : Option Nat :=
  if e.isAppOfArity ``List.cons 3 then
    (listSpineLen? e.appArg!).map (· + 1)
  else if e.isAppOfArity ``List.nil 1 then some 0
  else none

/-- THE MEM READ-OVER-WRITE LANE (arc-17 S3 salvage, arc-18 C1): under
    the `writeBytesTo` fence, store rounds keep the byte write FOLDED;
    stuck reads and MemState projections over it mint through
    Kit/Mem's footprint laws — `readBytesFrom_writeBytesTo_hit`
    (exact footprint readback), `readBytesFrom_writeBytesTo_disjoint`
    (the frame law; ground address arithmetic decides the disjunct),
    and the `writeBytesTo_*` projection laws (the write touches only
    the bytemap). Iterative peeling handles write towers (one layer
    per mint). *Lineage (canon-first)*: separation-logic read-over-
    write/frame reasoning at the byte level — the footprint laws are
    the equation-calculus face of load-over-store small-footprint
    axioms (Burstall/Bornat's independent-cell reasoning; the same
    laws the heap-RA rules state resource-wise). -/
private def mintMemRW (hp : HypPack) (d : Expr) : TermElabM Bool := do
  -- raw-projection spelling (whnf reduces the accessor const to
  -- `Expr.proj` when the record argument is not a constructor app)
  if let .proj sName idx b := d then
    unless sName == ``CerbMem.MemState
        && b.isAppOfArity ``CerbMem.writeBytesTo 3 do return false
    -- MemState field order: 3 = allocations, 5 = funptrmap,
    -- 9 = lastUsedUnionMembers, 10 = deadAllocations
    let law? : Option Name :=
      if idx == 3 then some ``RelSem.Kit.writeBytesTo_allocations
      else if idx == 5 then some ``RelSem.Kit.writeBytesTo_funptrmap
      else if idx == 9 then
        some ``RelSem.Kit.writeBytesTo_lastUsedUnionMembers
      else if idx == 10 then
        some ``RelSem.Kit.writeBytesTo_deadAllocations
      else none
    if law?.isNone then
      trace[RelSem.roundEval] "mem lane: unhandled projection idx \
        {idx} over writeBytesTo"
    let some law := law? | return false
    let wa := b.getAppArgs
    let rhs := Expr.proj sName idx wa[0]!
    let pf ← mkAppOptMU law #[some wa[0]!, some wa[1]!, some wa[2]!]
    -- restate at the proj spelling (defeq; kernel rechecks)
    let pf ← mkExpectedTypeHint pf (← mkEq d rhs)
    mintEmit hp d rhs pf "mem write projection (proj)"
    return true
  let .const c _ := d.getAppFn | return false
  let args := d.getAppArgs
  -- projection lane
  let projLaw? : Option Name :=
    if c == ``CerbMem.MemState.allocations then
      some ``RelSem.Kit.writeBytesTo_allocations
    else if c == ``CerbMem.MemState.deadAllocations then
      some ``RelSem.Kit.writeBytesTo_deadAllocations
    else if c == ``CerbMem.MemState.funptrmap then
      some ``RelSem.Kit.writeBytesTo_funptrmap
    else if c == ``CerbMem.MemState.lastUsedUnionMembers then
      some ``RelSem.Kit.writeBytesTo_lastUsedUnionMembers
    else none
  if let some law := projLaw? then
    unless args.size == 1 do return false
    let m' := args[0]!
    if m'.isAppOfArity ``CerbMem.writeBytesTo 3 then
      let wa := m'.getAppArgs
      let rhs := mkApp d.getAppFn wa[0]!
      let pf ← mkAppOptMU law
        #[some wa[0]!, some wa[1]!, some wa[2]!]
      mintEmit hp d rhs pf "mem write projection"
      return true
    -- fall through: the accessor may sit over a literal record
    -- (the fenced-accessor iota below)
  -- FENCED-ACCESSOR IOTA (arc-17 S3): a pack-hypothesis head fence
  -- freezes the accessor CONST, so `accessor {mk-record}` cannot
  -- delta-iota even though the reduction is fence-irrelevant. Mint
  -- the field value with a kernel-deferred refl bridge.
  let fieldIdx? : Option Nat :=
    if c == ``CerbMem.MemState.funptrmap then some 5
    else if c == ``CerbMem.MemState.lastUsedUnionMembers then some 9
    else if c == ``CerbMem.MemState.bytemap then some 8
    else if c == ``CerbMem.MemState.allocations then some 3
    else if c == ``CerbMem.MemState.deadAllocations then some 10
    else none
  if let some idx := fieldIdx? then
    unless args.size == 1 do return false
    let m' := args[0]!
    unless m'.isAppOfArity ``CerbMem.MemState.mk 14 do return false
    let rhs := m'.getAppArgs[idx]!
    let pf ← mkExpectedTypeHint (← mkEqRefl rhs) (← mkEq d rhs)
    mintEmit hp d rhs pf "fenced-accessor iota"
    return true
  unless c == ``CerbMem.readBytesFrom && args.size == 3 do
    return false
  let m' := args[0]!
  let a' := args[1]!
  let nE := args[2]!
  -- RECORD-RESPELLING bridge: a read at an anchored `MemState.mk`
  -- record whose bytemap field projects a base state = the read at
  -- the base (readBytesFrom_congr_bytemap; the h is rfl-grade)
  if m'.isAppOfArity ``CerbMem.MemState.mk 14 then
    let bmArg := m'.getAppArgs[8]!
    let base? : Option Expr :=
      match bmArg with
      | .proj sN 8 b => if sN == ``CerbMem.MemState then some b else none
      | _ =>
        if bmArg.isAppOfArity ``CerbMem.MemState.bytemap 1 then
          some bmArg.appArg!
        else none
    if base?.isNone then
      trace[RelSem.roundEval] "mem lane: record read, bytemap field \
        not a base projection"
    let some base := base? | return false
    let hTy ← mkEq (Expr.proj ``CerbMem.MemState 8 m')
      (Expr.proj ``CerbMem.MemState 8 base)
    let h ← mkExpectedTypeHint
      (← mkEqRefl (Expr.proj ``CerbMem.MemState 8 base)) hTy
    let rhs := mkAppN d.getAppFn #[base, a', nE]
    let pf ← mkAppOptMU ``RelSem.Kit.readBytesFrom_congr_bytemap
      #[some m', some base, some a', some nE, some h]
    mintEmit hp d rhs pf "mem read record-respelling"
    return true
  unless m'.isAppOfArity ``CerbMem.writeBytesTo 3 do return false
  let wa := m'.getAppArgs
  let m := wa[0]!; let a := wa[1]!; let bs := wa[2]!
  let some av ← groundIntLit? a
    | (do trace[RelSem.roundEval] "mem lane: write addr not ground {a}"
          return false)
  let some av' ← groundIntLit? a'
    | (do trace[RelSem.roundEval] "mem lane: read addr not ground {a'}"
          return false)
  let some blen := listSpineLen? bs
    | (do trace[RelSem.roundEval] "mem lane: bytes not a literal spine"
          return false)
  let nW ← withOptions (smartUnfolding.set · false) <|
    withTransparency .all <| whnf nE
  let some nv := nW.rawNatLit? <|> nW.nat?
    | (do trace[RelSem.roundEval] "mem lane: read size not ground {nE}"
          return false)
  if av' == av && nv == blen then
    -- HIT: exact-footprint readback
    let hn ← mkExpectedTypeHint (← mkEqRefl nE)
      (← mkEq nE (← mkAppMU ``List.length #[bs]))
    let pf ← mkAppOptMU ``RelSem.Kit.readBytesFrom_writeBytesTo_hit
      #[some m, some a, some bs, some nE, some hn]
    mintEmit hp d bs pf "mem read-over-write hit"
    return true
  if av + blen ≤ av' || av' + nv ≤ av then
    -- DISJOINT: the frame law; decide the disjunct at ground values
    let lenE ← mkAppMU ``Int.ofNat #[← mkAppMU ``List.length #[bs]]
    let disjL ← mkAppMU ``LE.le #[← mkAppMU ``HAdd.hAdd #[a, lenE], a']
    let disjR ← mkAppMU ``LE.le
      #[← mkAppMU ``HAdd.hAdd #[a', ← mkAppMU ``Int.ofNat #[nE]], a]
    let hdisj ← (do
      if av + blen ≤ av' then
        let some (true, pfL) ← kernelVerdict disjL
          | throwError "mem lane: ground disjunct failed (L)"
        mkAppOptMU ``Or.inl #[some disjL, some disjR, some pfL]
      else
        let some (true, pfR) ← kernelVerdict disjR
          | throwError "mem lane: ground disjunct failed (R)"
        mkAppOptMU ``Or.inr #[some disjL, some disjR, some pfR])
    let rhs := mkAppN d.getAppFn #[m, a', nE]
    let pf ← mkAppOptMU ``RelSem.Kit.readBytesFrom_writeBytesTo_disjoint
      #[some m, some a, some a', some bs, some nE, some hdisj]
    mintEmit hp d rhs pf "mem read-over-write frame"
    return true
  trace[RelSem.roundEval] "mem lane: OVERLAPPING non-exact read \
    (write [{av}, {av + blen}), read [{av'}, {av' + nv})) — unsupported"
  return false

/-- THE MINTER (the `mintHook` implementation): scan the stuck term
    for candidate towers, mint the first that yields a verdict.
    Returns true iff a rewrite was registered (the caller loops).
    Budget-guarded LOUDLY (a runaway mint population is a design
    smell, never silently absorbed). -/
def mintCmpFact? (hp : HypPack) (e : Expr) : TermElabM Bool := do
  if hp.isEmpty then return false
  if (← hp.mintIdx.get) ≥ 512 then
    throwError "derive_rounds: arith-minter budget exceeded \
      (512 facts) — a runaway population is a design smell"
  let t0 ← IO.monoMsNow
  let cands ← collectMintCands e
  let pairs ← hp.pairs
  for d in cands do
    if pairs.any (fun r => r.lhs == d) then continue
    if d.isAppOf ``Decidable.isTrue || d.isAppOf ``Decidable.isFalse then
      continue
    -- each candidate attempt is its own scoped unit (phase note)
    if ← withCurrHeartbeats (mintEnvLookup hp d) then
      trace[RelSem.roundEval] "arith minter: hit after {(← IO.monoMsNow) - t0} ms ({cands.size} candidates)"
      return true
    if ← withCurrHeartbeats (mintMemRW hp d) then
      trace[RelSem.roundEval] "arith minter: hit after {(← IO.monoMsNow) - t0} ms ({cands.size} candidates)"
      return true
    if ← withCurrHeartbeats (mintBool hp d) then
      trace[RelSem.roundEval] "arith minter: hit after {(← IO.monoMsNow) - t0} ms ({cands.size} candidates)"
      return true
    if ← withCurrHeartbeats (mintDecidable hp d) then
      trace[RelSem.roundEval] "arith minter: hit after {(← IO.monoMsNow) - t0} ms ({cands.size} candidates)"
      return true
    if ← withCurrHeartbeats (mintBoolTower hp d) then
      trace[RelSem.roundEval] "arith minter: hit after {(← IO.monoMsNow) - t0} ms ({cands.size} candidates)"
      return true
  if !cands.isEmpty then
    let heads := cands.map (fun d => match d.getAppFn with
      | .const c _ => c | _ => Name.anonymous)
    trace[RelSem.roundEval] "arith minter: no mint; candidate heads: {heads.toList.eraseDups}"
  trace[RelSem.roundEval] "arith minter: no mint ({cands.size} candidates, {(← IO.monoMsNow) - t0} ms)"
  return false

initialize mintHook.set mintCmpFact?

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

/-- Build `app (advance_step td tid (Laws.stepAt td tid σ)) σ`. -/
private def mkRoundLhs (td tid σ : Expr) : TermElabM Expr := do
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
  try
    elabAt lhs
  catch exDirect =>
    let advE ← mkAppMU ``advance_step #[td, tid, stepE]
    let lhsD ← mkAppMU ``RelSem.app #[advE, σ]
    if lhs == lhsD then throw exDirect
    trace[RelSem.roundEval] "elabLawChain[{roundIdx}]: direct face \
      failed ({exDirect.toMessageData}); retrying at the discovered \
      step with glue"
    let (pf, succ) ← elabAt lhsD
    let stepAtE ← mkAppMU ``RelSem.Laws.stepAt #[td, tid, σ]
    let hstep ← (do
      match ← (activeHypPack.get : BaseIO _) with
      | some hp => proveHypEq hp stepAtE stepE
      | none =>
        mkExpectedTypeHint (← mkEqRefl stepE) (← mkEq stepAtE stepE))
    let motive ← withLocalDeclD `s (← inferType stepE) fun sv => do
      mkLambdaFVars #[sv]
        (← mkAppMU ``RelSem.app
          #[← mkAppMU ``advance_step #[td, tid, sv], σ])
    let glue ← mkCongrArg motive hstep
    return (← mkEqTrans glue pf, succ)

/-- Unfold definition heads (dnmsBump and friends) until the record
    constructor is exposed (bounded; beta after each unfold). -/
private def unfoldToRecord (e : Expr) : TermElabM Expr := withCurrHeartbeats do
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
    (a : Anchor) (σprev lhs pf succRaw : Expr) (roundIdx : Nat)
    (cls : String) : TermElabM (MintedRound × Anchor) := do
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
  return ({ succ, eqName, cls }, a'')

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
    (a : Anchor) (td tid σ lhs stepE : Expr) (roundIdx : Nat) :
    TermElabM (MintedRound × Anchor) := do
  -- expose + normalize a thread payload (arena/stack are first-order
  -- data; env/errno stay as the step spelled them)
  let thNorm (th : Expr) : TermElabM Expr := do
    let w ← whnfU th
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
    unless kindE.isConstOf ``core_tau_step_kind.TSK_Misc do
      throwFrontier m!"derive_rounds: round {roundIdx} tau kind has no \
        registered law:{indentExpr kindE}"
    let mkStx (th : Expr) : TermElabM Term := do
      let thS ← toStxU th
      `(RelSem.Kit.advance_tau_misc (th' := $thS))
    let (pf, succRaw) ← (try
        elabLawChain td tid σ stepE lhs roundIdx
          (← mkStx (← thNorm stepE.getAppArgs[2]!))
      catch _ =>
        elabLawChain td tid σ stepE lhs roundIdx
          (← mkStx (← whnfU stepE.getAppArgs[2]!)))
    emitLawRound declName fvars a σ lhs pf succRaw roundIdx "tau"
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
    let proofStx ←
      -- dbg/step_m supplied EXPLICITLY (arc-17 S3): at a
      -- builder-state σ0 (free component binders) the elaborator's
      -- own stepAt unification wedges where classification's plain
      -- whnf succeeded — the mintMemRound explicit-decomposition
      -- lesson, applied to the pure branches
      if kindE.isAppOfArity ``runstate_step_kind.RSK_eval 1 then do
        let dbgS ← toStxU kindE.getAppArgs[0]!
        let stepmS ← toStxU stepM
        `(RelSem.Kit.advance_runstate_eval (dbg := $dbgS)
            (step_m := $stepmS) (th' := $thS) (rs' := $rsS)
            (hm := by first | exact rfl | hyp_norm_side))
      else if kindE.isAppOfArity ``runstate_step_kind.RSK_tau 2 then do
        let tkE ← whnfU kindE.getAppArgs[1]!
        unless tkE.isConstOf ``core_tau_step_kind.TSK_Misc do
          throwFrontier m!"derive_rounds: round {roundIdx} RSK_tau kind \
            has no registered law:{indentExpr tkE}"
        let dbgS ← toStxU kindE.getAppArgs[0]!
        let stepmS ← toStxU stepM
        `(RelSem.Kit.advance_runstate_tau_misc (dbg := $dbgS)
            (step_m := $stepmS) (th' := $thS)
            (rs' := $rsS) (hm := by first | exact rfl | hyp_norm_side))
      else
        throwFrontier m!"derive_rounds: round {roundIdx} runstate kind \
          has no registered law:{indentExpr kindE}"
    let (pf, succRaw) ← elabLawChain td tid σ stepE lhs roundIdx proofStx
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
  let mut subs : Array (Expr × Expr) := #[]
  let mut pfSucc : Expr × Expr := (default, default)
  let mut cls := ""
  if reqCtor == ``action_request2.StoreRequest2 then
    -- StoreRequest2 mo ty lk ptr mval mk
    let rargs := reqE.getAppArgs
    let tyE := rargs[rargs.size - 5]!
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
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := RelSem.Kit.perform_store
        (ptr := $(← toStxU ptrE))
        (mval := $(← toStxU mvalE))
        (hmem := RelSem.Kit.mem_store_block
          (allocId := $(← toStxU idE))
          (addr := $(← toStxU addrE))
          (alloc := $(← toStxU allocE))
          (fpm := $(← toStxU fpmE'))
          (bytes := $(← toStxU bytesE))
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side)
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side))
        (hpref := RelSem.Kit.mem_prefix_block)))
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
    let haddrS ← toStxU (mkAppN (mkConst haddrName) fvars)
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := RelSem.Kit.perform_create
        (hmem := RelSem.Kit.mem_alloc_block
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
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := RelSem.Kit.perform_load
        (ptr := $(← toStxU ptrE))
        (hmem := RelSem.Kit.mem_load_block
          (allocId := $(← toStxU idE))
          (addr := $(← toStxU addrE))
          (alloc := $(← toStxU allocE))
          (bytes := $(← toStxU bytesE))
          (mv := $(← toStxU mvE))
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side)
          (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side) (by first | exact rfl | decide | hyp_norm_side))
        (hpref := RelSem.Kit.mem_prefix_block)))
    pfSucc ← elabLawChain td tid σ stepE lhs roundIdx proofStx
    cls := "load"
  else if reqCtor == ``action_request2.KillRequest2 then
    -- KillRequest2 isDyn ptr mk
    let rargs := reqE.getAppArgs
    let (ptrE, idE, _) ← destructPtr rargs[rargs.size - 2]!
    let allocE ← lookupAlloc idE
    let proofStx ← `(RelSem.Kit.advance_action_request (dbg := $dbgS) (loc := $locS)
      (tid' := $tid'S) (m_request := $mReqS) (request := $reqS)
      (σ := $σS) (σ₁ := $σS) (hreq := by first | exact rfl | decide | hyp_norm_side)
      (hperf := RelSem.Kit.perform_kill
        (ptr := $(← toStxU ptrE))
        (hmem := RelSem.Kit.mem_kill_block
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
syntax roundsAssuming := " assuming " ident+
syntax roundsChain := " chain"
syntax roundsBuilder := " builder"
syntax roundsFencing := " fencing " ident+

elab "derive_rounds " id:ident bs:bracketedBinder* assum:(roundsAssuming)? fenc:(roundsFencing)? " using " td:term:max tid:term:max " from " σ0:term upto:(roundsUpto)? chainTk:(roundsChain)? builderTk:(roundsBuilder)? : command => do
  let ns ← getCurrNamespace
  let baseName := ns ++ id.getId
  let maxRounds := match upto with
    | some u => (u.raw[1].isNatLit?).getD 256
    | none => 256
  let demandTerminal := upto.isNone
  let emitChainRel := chainTk.isSome
  builderMode.set builderTk.isSome
  runTermElabM fun _ => do
    Term.elabBinders bs fun fvars => do
      -- hypothesis mode: build the pack from the named binders
      let hypIdents : Array Syntax := match assum with
        | some a => a.raw[1].getArgs
        | none => #[]
      let mut baseRw : Array HypRw := #[]
      let mut arith : Array Expr := #[]
      let mut hypFVars : Array Expr := #[]
      for hid in hypIdents do
        let uname := hid.getId
        let some decl := (← getLCtx).findFromUserName? uname
          | throwError "derive_rounds: assuming-hypothesis {uname} is \
              not a binder of this command"
        let fv := decl.toExpr
        hypFVars := hypFVars.push fv
        let ty ← instantiateMVars decl.type
        unless ← Meta.isProp ty do
          throwError "derive_rounds: assuming-hypothesis {uname} is \
              not a Prop binder ({ty})"
        match ty.eq? with
        | some (_, l, r) => baseRw := baseRw.push { lhs := l, rhs := r, prf := fv }
        | none => arith := arith.push fv
      let mut valueFVars : Array Expr := #[]
      for fv in fvars do
        if ← Meta.isProp (← inferType fv) then
          unless hypFVars.contains fv do
            throwError "derive_rounds: Prop binder \
              {← Lean.Meta.ppExpr fv} is not named in the assuming \
              clause (every hypothesis must be declared)"
        else
          valueFVars := valueFVars.push fv
      -- THE ATTRIBUTE FENCE (measured, this slice; three iterations):
      -- whnf-unfolding a function whose body reads a kernel-stuck
      -- extern EXPLODES the spelling through recursor branches and
      -- Decidable-instance PROOFS, and substituting inside those
      -- dependent positions builds ILL-TYPED terms (kernel
      -- application-type-mismatch at addDecl; probe: post-subst
      -- isDefEq _ 8 = false). A canUnfold?-hook fence cannot mirror
      -- default unfolding (smart-unfolding/WF gating lives outside
      -- it — 200k-heartbeat death in raw Acc.rec towers). The working
      -- fence: TEMPORARY @[irreducible] status on the pack's
      -- pattern-head constants for the drive's extent (restored at
      -- every exit — success paths restore before the env is
      -- serialized; a failed drive fails the module anyway). The
      -- elaborator then stops at the TIDY curated spellings, where
      -- substitution is a well-typed data-position rewrite; the
      -- KERNEL is attribute-blind, so emitted proofs check exactly
      -- as before.
      let fence : NameSet := {}
      let mut fenceSaved : Array (Name × ReducibilityStatus) := #[]
      let mut fenceHeadSet : NameSet := {}
      for r in baseRw do
        if let .const c _ := r.lhs.getAppFn then
          fenceHeadSet := fenceHeadSet.insert c
          unless fenceSaved.any (·.1 == c) do
            fenceSaved := fenceSaved.push (c, ← getReducibilityStatus c)
            setReducibilityStatus c .irreducible
      -- explicit `fencing f g …` heads (arc-17 S3): spelling
      -- preservation for constructs the pack reasons about by LAW
      -- rather than rewrite (e.g. `fmapAddBy` chains over a free env
      -- binder, consumed by the env-lookup lane); ground occurrences
      -- still compute via the fenced-head ground escape.
      if let some ftk := fenc then
        for fid in ftk.raw[1].getArgs do
          let cs ← realizeGlobalConstNoOverload fid
          fenceHeadSet := fenceHeadSet.insert cs
          unless fenceSaved.any (·.1 == cs) do
            fenceSaved := fenceSaved.push (cs, ← getReducibilityStatus cs)
            setReducibilityStatus cs .irreducible
      baseFenceHeads.set fenceHeadSet
      let hp : HypPack :=
        { baseRw, arith, minted := ← IO.mkRef #[],
          mintIdx := ← IO.mkRef 0,
          baseName := baseName.appendAfter "_hf",
          fvars, valueFVars, fence,
          defeqSubst := ← IO.mkRef #[] }
      -- ref hygiene: the pack is SET unconditionally at every command
      -- start (a failed prior command cannot leak a stale pack into
      -- this one) and cleared at the exits below; a module abort
      -- between the two fails the build anyway.
      if hypIdents.isEmpty then
        activeHypPack.set none
      else
        activeHypPack.set (some hp)
      let tdE ← Term.elabTerm td none
      let tidE ← Term.elabTerm tid (some (mkConst ``Nat))
      let σ0E ← Term.elabTerm σ0 none
      Term.synthesizeSyntheticMVarsNoPostponing
      let tdE ← instantiateMVars tdE
      let tidE ← instantiateMVars tidE
      let σ0E ← instantiateMVars σ0E
      let tdS ← toStxU tdE
      let tidS ← toStxU tidE
      let mut σ := σ0E
      -- anchor on the LITERAL record fields when σ0 unfolds to one
      -- (arc-17 S3): projection-spelled components re-force the
      -- whole state per use — for a ladder-carrying memory field the
      -- head whnf then chains through every layer in one unit
      -- (measured: the T5 body walk's memMat initialization)
      let σ0R ← unfoldToRecord σ0E
      let mut anchor ←
        (if σ0R.isAppOfArity ``driver_state.mk 11 then do
          let a := σ0R.getAppArgs
          pure { cs := a[2]!, rs := a[3]!, mem := a[4]!,
                 memMat := a[4]!, tr := a[7]!, ctr := a[10]!,
                 fixed := #[a[0]!, a[1]!, a[5]!, a[6]!, a[8]!, a[9]!] }
        else Anchor.init σ0E)
      -- hyp mode: materialize the initial memory ONCE (the twin's
      -- base; ~1.4 s at T4's 4-layer ready ladder — measured within
      -- the default budget; every later update is a delta pass)
      if !hypIdents.isEmpty then
        trace[RelSem.roundEval] "memMat init: start"
        let mat ← withCurrHeartbeats
          (groundNorm "initial memMat" anchor.mem)
        trace[RelSem.roundEval] "memMat init: done ({← mat.numObjs} objs)"
        hp.defeqSubst.modify (·.push (anchor.mem, mat))
        anchor := { anchor with memMat := mat }
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
        let stepAtE ← mkAppMU ``RelSem.Laws.stepAt #[tdE, tidE, σ]
        -- classification is DEFEQ-PURE by design (hyp mode included):
        -- the discovered step's spelling enters the round equation's
        -- conclusion through the law's m_request argument, so any
        -- hypothesis substitution here would break the kernel's defeq
        -- bridge (measured this slice: rT5 kernel type mismatch).
        -- Stuck data inside a state never reaches classification —
        -- the PRODUCING round's respell bridge (emitLawRound) cleans
        -- it before the successor is named.
        trace[RelSem.roundEval] "round {k}: classifying"
        let stepE ← (do
          try
            let r ← whnf stepAtE
            -- fence fallback (arc-17 S3): classification is
            -- DEFEQ-PURE by design, so when the default-transparency
            -- whnf is blocked by the hyp-mode fences (a ground
            -- lookup inside step discovery), re-classify at `.all`
            -- (attribute-blind) — the pre-fence behavior exactly
            let isStep (e : Expr) : Bool :=
              e.isAppOf ``core_step2.Step_action_request2
                || e.isAppOf ``core_step2.Step_blocked2
                || e.isAppOf ``core_step2.Step_tau2
                || e.isAppOf ``core_step2.Step_with_runstate2
            if isStep r then
              pure r
            else
              let r2 ← withCurrHeartbeats
                (withTransparency .all (whnf stepAtE))
              if isStep r2 then
                pure r2
              else
                -- HYP-AWARE classification (arc-17 S3): at a
                -- builder-state σ0 the discovery itself can consult
                -- the free components (step_ctx reads layout_state —
                -- the S3-record open question, measured at the T5
                -- body's post-store round); the pack normalizes it,
                -- and the discovery GLUE (elabLawChain) carries the
                -- matching PROVED equation instead of a refl hint.
                hypNormA "classification" r
          catch ex =>
            throwError "derive_rounds: round {k} CLASSIFICATION \
              failed/timed out: {ex.toMessageData}")
        trace[RelSem.roundEval] "round {k}: classify {(← IO.monoMsNow) - t0} ms"
        let declName := baseName.appendAfter (toString k)
        if stepE.isAppOf ``core_step2.Step_action_request2 then
          let lhs ← mkRoundLhs tdE tidE σ
          let (r, a') ← mintMemRound declName fvars anchor tdE tidE σ lhs stepE k
          trace[RelSem.roundEval] "round {k}: {r.cls} ({(← IO.monoMsNow) - t0} ms)"
          return Sum.inl (r, a')
        else if stepE.isAppOf ``core_step2.Step_blocked2 then
          -- No advancing step: the terminal offer (or a genuine block).
          let σS ← toStxU σ
          let stepsE ← evalGroundA s!"terminal offer (round {k})" <|
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
          let (r, a') ← mintLawPure declName fvars anchor tdE tidE σ lhs stepE k
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
      -- THE RELATIVE CHAIN (arc-17 S3, opt-in `chain` token): the
      -- iter_compose feed — a ∀-fuel composable block equation. The
      -- dnms laws are already fuel-relative (`hfuel : fuelS = fuel+1`
      -- discharges by rfl at `fuel + m ≟ (fuel + (m-1)) + 1`), so the
      -- chain states
      --   ∀ fuel, app (dnms (fuel + N) …) σ0 = app (dnms fuel …) σN
      -- (partial mode), or, when the terminal offer was reached,
      --   ∀ fuel, app (dnms (fuel + N + 2) …) σ0 = (NDactive offer, σN)
      -- — the shapes T5-by-invariant's loop composition consumes.
      if emitChainRel then withCurrHeartbeats do
        let n := rounds.size
        let σ0S ← toStxU σ0E
        let succS ← toStxU σ
        let accS ← `(fmapEmpty)
        let fuelId := mkIdent `fuel
        let mkF (m : Nat) : TermElabM Term :=
          if m == 0 then pure fuelId
          else `($fuelId + $(Syntax.mkNatLit m))
        let off := if terminal.isSome then 2 else 0
        let mut pf? : Option Term := none
        for j in [0 : n] do
          let fS ← mkF (n + off - j)
          let f1S ← mkF (n + off - j - 1)
          let hadvS ← toStxU (mkAppN (mkConst rounds[j]!.eqName) fvars)
          let step ← `(RelSem.Kit.dnms_round (fuelS := $fS)
            (fuel := $f1S) rfl rfl rfl rfl $hadvS)
          pf? := some (← match pf? with
            | none => pure step
            | some p => `(($p).trans $step))
        let (stmtStx, pfStx) ← (do
          match terminal with
          | none =>
            let stmtStx ← `(∀ ($fuelId : Nat), RelSem.app
                (drive_nonmemory_steps_aux2_lemFuel
                  ($fuelId + $(Syntax.mkNatLit n)) $tdS $accS [$tidS]) $σ0S
              = RelSem.app (drive_nonmemory_steps_aux2_lemFuel $fuelId
                  $tdS $accS [$tidS]) $succS)
            let body := pf?.get!
            pure (stmtStx, ← `(fun ($fuelId : Nat) => $body))
          | some stepsE =>
            let stepsS ← toStxU stepsE
            let termS ← `(RelSem.Kit.dnms_terminal
              (fuelS := $(← mkF 2)) (fuel := $fuelId)
              (steps := $stepsS) rfl rfl rfl rfl)
            let whole ← match pf? with
              | none => pure termS
              | some p => `(($p).trans $termS)
            let stmtStx ← `(∀ ($fuelId : Nat), RelSem.app
                (drive_nonmemory_steps_aux2_lemFuel
                  ($fuelId + $(Syntax.mkNatLit (n + 2))) $tdS $accS
                  [$tidS]) $σ0S
              = (NDactive (fmapAddBy defaultCompare $tidS $stepsS
                  fmapEmpty), $succS))
            pure (stmtStx, ← `(fun ($fuelId : Nat) => $whole)))
        let stmt ← Term.elabType stmtStx
        Term.synthesizeSyntheticMVarsNoPostponing
        let stmt ← instantiateMVars stmt
        let pf ← Term.elabTermEnsuringType pfStx stmt
        Term.synthesizeSyntheticMVarsNoPostponing
        let chainName := baseName.appendAfter "_chainrel"
        emitThm chainName fvars stmt (← instantiateMVars pf)
          s!"RELATIVE {if terminal.isSome then "terminal " else ""}chain \
             ({rounds.size} rounds{if terminal.isSome then " + terminal" else ""}, \
             ∀-fuel — the iter_compose feed). \
             {provenanceNote "derive_rounds"}"
        logInfo m!"derive_rounds {baseName}: relative chain {chainName} \
          emitted ({rounds.size} rounds, terminal={terminal.isSome})"
      match terminal with
      | none =>
        activeHypPack.set none
        builderMode.set false
        baseFenceHeads.set {}
        for (c, st) in fenceSaved do
          setReducibilityStatus c st
        if demandTerminal then
          throwFrontier m!"derive_rounds: no terminal within \
            {maxRounds} rounds (partial mode requires `upto`)"
      | some stepsE => withCurrHeartbeats do
        -- The whole-run chain, the scheduler offer, the driver
        -- iteration (own budget scope, same rationale as per-round).
        let n := rounds.size
        let vE ← terminalValue stepsE n
        let accS ← `(fmapEmpty)
        let σ0S ← toStxU σ0E
        let stepsS ← toStxU stepsE
        -- chain statement:
        --   app (dnms lemDefaultFuel td fmapEmpty [tid]) σ0
        --     = (NDactive (fmapAddBy defaultCompare tid steps fmapEmpty),
        --        rN)
        let succS ← toStxU σ  -- final advancing state (rN)
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
          let hadvS ← toStxU
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
        let vS ← toStxU vE
        let chainS ← toStxU (mkAppN (mkConst chainName) fvars)
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
        let dataFVars ← match ← activeHypPack.get with
          | some hp => pure hp.valueFVars
          | none => pure fvars
        emitFlatDef finName dataFVars (← instantiateMVars finE)
          s!"The final driver state (post prepare_exit). \
             {provenanceNote "derive_rounds"}"
        let finS ← toStxU (mkAppN (mkConst finName) dataFVars)
        let ndctS ← toStxU (mkAppN (mkConst ndctName) fvars)
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
      activeHypPack.set none
      builderMode.set false
      baseFenceHeads.set {}
      for (c, st) in fenceSaved do
        setReducibilityStatus c st

end RoundEval
end RelSem
