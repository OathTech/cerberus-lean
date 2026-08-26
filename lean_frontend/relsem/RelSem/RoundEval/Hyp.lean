/-
  RelSem.RoundEval.Hyp — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: THE HYPOTHESIS-THREADING MODE — the hypothesis pack
  (HypRw/HypPack), directed substitute-first rewriting
  (substPattern/substPatternExact/hypSubst), the fenced hypothesis-
  aware normalizer (hypNorm), the directed equality provers
  (proveHypEqMat/Bld) and the `hyp_norm_side` tactic. Conditional
  rewriting made mechanical; every produced proof is an ordinary
  kernel-checked term. NO law names appear here — laws enter as
  registered rewrites in the pack.

  Split from RoundEval.lean; code carried VERBATIM (see the
  umbrella's module doc for lineage).

  House rules: no sorry, no axioms; meta code only.
-/
import RelSem.RoundEval.Core

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

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

/-- An `isSome` option equals `some` of its `getD` (the glue-round
    discovery bridge, arc-18 C3: the payload-blind route — `isSome`
    forward-normalizes through the pack where the payload spelling
    itself is verdict-substituted and not kernel-defeq to the folded
    face). -/
theorem option_eq_some_getD {α : Type} (o : Option α) (d : α)
    (h : o.isSome = true) : o = some (o.getD d) := by
  cases o with
  | none => simp at h
  | some v => rfl

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
  -- DATA-typed patterns (arc-18 C3): the position discipline below
  -- exists for DECIDABLE-typed verdicts (defeq-variant hazards in
  -- dependent slots). A pattern of rigid data type (IntegerValue,
  -- Option _, …) is replaceable at ANY value position reached by the
  -- recursion — the conv/catch law rewrites are data rewrites.
  let patTy ← try whnf (← inferType pat) catch _ => pure (mkConst ``Unit)
  let dataPat := !(patTy.isAppOf ``Decidable)
  let cache ← IO.mkRef ({} : Std.HashMap Expr Expr)
  let rec go (e : Expr) : MetaM Expr := do
    if dataPat && e == pat then
      found.set true
      return rhs
    unless e.isApp || e.isLambda || e.isForall || e.isLet
        || e.isMData || e.isProj do return e
    if let some r := (← cache.get).get? e then return r
    -- proofs are opaque (arc-18 C3, mirroring the materialized-mode
    -- transform's pre-skip): replacing inside a proof buys nothing
    -- and can desynchronize it from its statement spelling.
    if (← Meta.isProofQuick e) matches .true then return e
    let r ← (do
      match e with
      | .app .. => do
        let fn := e.getAppFn
        let args := e.getAppArgs
        -- which positions may take the verdict directly, and which
        -- may be RECURSED into? (arc-18 C3 hardening, replacing the
        -- interim whole-term type-check: for the Decidable machinery
        -- the Prop/motive/instance-type slots are NEVER entered —
        -- a nested replacement there changes an enclosing type and
        -- builds kernel-rejected terms [measured: the T5 body walk's
        -- round-14 guard]; a whole-term `check` per substitution was
        -- the measured 200k-heartbeat cost at round-35 tower sizes.)
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
        let recurseIdx : Array Nat ← (do
          match fn with
          | .const c _ =>
            if c == ``ite || c == ``dite then
              return #[3, 4]          -- branches only (α, c, inst frozen)
            else if c == ``decide then
              return #[]              -- whole-instance replacement only
            else if c == ``Decidable.rec then
              if args.size == 5 then return #[2, 3] else return #[]
            else if isMatcherAppCore env e then
              if let some ma ← Lean.Meta.matchMatcherApp? e then
                let base := ma.params.size + 1
                -- discrs + alts; params/motive frozen
                return (Array.range (ma.discrs.size + ma.alts.size)).map
                  (base + ·)
              return #[]
            else
              return Array.range args.size
          | _ => return Array.range args.size)
        let mut newArgs := args
        for i in [0:args.size] do
          if args[i]! == pat && safeIdx.contains i then
            newArgs := newArgs.set! i rhs
            found.set true
          else if recurseIdx.contains i then
            newArgs := newArgs.set! i (← go args[i]!)
        return mkAppN (← go fn) newArgs
      -- binder TYPES are quoted text (arc-18 C3, the frozen-slot
      -- discipline's binder face): a replacement inside a lambda's
      -- type annotation desynchronizes it from the enclosing
      -- application's Prop slots (measured: the T5 round-14 minor
      -- premise annotated at a verdict-substituted `decide` instance
      -- while the rec's Prop kept the original spelling)
      | .lam n t b i => return .lam n t (← go b) i
      | .forallE n t b i => return .forallE n t (← go b) i
      | .letE n t v b nd =>
        return .letE n t (← go v) (← go b) nd
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
    -- builder mode: STRUCTURAL position safety (arc-18 C3 hardened:
    -- substDecSafeCore no longer recurses into Prop/motive/instance
    -- type slots and skips proofs — the round-14 dependent-position
    -- kernel reject is unconstructible by position discipline; the
    -- interim whole-term check guard was the measured round-35
    -- 200k-heartbeat cost and is retired with the hardening)
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

/-- THE PROJECTION-NORMALIZATION HOP (arc-18 C3b — the C3 record's
    §3.4 routing item). Builder-state side-condition goals quote
    structure projections of FOLDED successor spellings
    (`(b55 …).layout_state.deadAllocations`) while the pack's facts
    are stated at the base binder (`mem.deadAllocations`) — and the
    attribute fence blocks kabstract's defeq walk from bridging the
    two (the fence is the very mechanism keeping the ladder
    law-shaped; measured: the T5 body walk's round-56 post-store-load
    `hdead`, discharged as a kernel-uncomputable deferred refl).

    The hop resolves such a projection to its base form: the
    projected structure argument is whnf-exposed (named-state defs
    unfold; the fence stops at the curated ladder heads), constructor
    records iota-reduce, and fenced ladder layers peel through the
    REGISTERED rfl-side projection laws (registry query, kind
    `memRW` — R4: no law names in engine code; only `side := rfl`
    entries are consumed, so every step is DEFINITIONAL and the whole
    hop is carried by one kernel-deferred refl bridge in the chain —
    the kernel is attribute-blind and never forces the bytemap fold).
    The resolved value is respelled as an accessor APPLICATION (the
    pack patterns' spelling, so the next scan matches). -/
private partial def resolveProjVal (sN : Name) (fieldIdx : Nat)
    (X0 : Expr) : MetaM (Option Expr) := do
  let env ← getEnv
  unless isStructure env sN do return none
  let fields := getStructureFields env sN
  let some field := fields[fieldIdx]? | return none
  let accName := sN ++ field
  let ctor := getStructureCtor env sN
  let ctorArity := ctor.numParams + ctor.numFields
  -- canonical accessor-app spelling of a resolved value (top node
  -- only — kabstract keys on head constants, `.proj` has none)
  let canon (v : Expr) : Expr :=
    match v with
    | .proj sN' j b =>
      if isStructure env sN' then
        match (getStructureFields env sN')[j]? with
        | some f => mkApp (mkConst (sN' ++ f)) b
        | none => v
      else v
    | _ => v
  let rec go (X : Expr) (fuel : Nat) (moved : Bool) :
      MetaM (Option Expr) := do
    match fuel with
    | 0 => return none
    | fuel + 1 =>
      -- expose (own scoped unit; a stuck whnf leaves X unchanged)
      let XW ← (try whnfU X catch _ => pure X)
      let moved := moved || XW != X
      -- constructor iota: the field value as stored
      if XW.isAppOfArity ctor.name ctorArity then
        let some v := XW.getAppArgs[ctor.numParams + fieldIdx]?
          | return none
        return some (canon v)
      -- registered rfl-side projection law at the accessor goal form
      -- (unify fallback ON: the hop runs only under the drive fence,
      -- where tree keys are perturbed — the round-59 measurement)
      let acc := mkApp (mkConst accName) XW
      let hits ← RelSem.LawRegistry.query `memRW acc
        (unifyFallback := true)
      for l in hits do
        if l.side == `rfl then
          let cinfo ← getConstInfo l.name
          let (_, _, concl) ← forallMetaTelescopeReducing cinfo.type
          if let some (_, lawLhs, lawRhs) := concl.eq? then
            if ← withReducible (isDefEq lawLhs acc) then
              let rhs' ← instantiateMVars lawRhs
              unless rhs'.hasExprMVar do
                -- the law's rhs is the projection at the peeled base
                -- — continue peeling there
                if rhs'.isApp && rhs'.getAppFn.constName? == some accName then
                  match ← go rhs'.appArg! fuel true with
                  | some v => return some v
                  | none => return some (canon rhs')
                else
                  return some (canon rhs')
      -- exposure alone is progress worth respelling only when a base
      -- binder was reached (the pack patterns' spelling)
      if moved && XW.isFVar then
        return some (mkApp (mkConst accName) XW)
      return none
  go X0 16 false

/-- The hop's term pass: respell every resolvable structure
    projection (raw `.proj` node or accessor application) in `e`.
    Proof subterms are opaque; nodes under binders are skipped (side
    conditions are closed goals). Returns none when nothing
    resolved. -/
def projNormHop (e : Expr) : MetaM (Option Expr) := do
  let env ← getEnv
  let changed ← IO.mkRef false
  let r ← Meta.transform e
    (pre := fun n => do
      if (← Meta.isProofQuick n) matches .true then
        return .done n
      return .continue)
    (post := fun node => do
      if node.hasLooseBVars then return .done node
      match node with
      | .proj sN i b =>
        match ← resolveProjVal sN i b with
        | some v => changed.set true; return .done v
        | none =>
          -- canonical accessor-app respelling even without a peel
          -- (defeq; `.proj` has no head constant for kabstract)
          if isStructure env sN then
            if let some f := (getStructureFields env sN)[i]? then
              changed.set true
              return .done (mkApp (mkConst (sN ++ f)) b)
          return .done node
      | .app .. =>
        let some c := node.getAppFn.constName? | return .done node
        let some pinfo := env.getProjectionFnInfo? c
          | return .done node
        let args := node.getAppArgs
        unless args.size == pinfo.numParams + 1 do return .done node
        let sN := pinfo.ctorName.getPrefix
        -- base already a binder: nothing to resolve
        if args.back!.isFVar then return .done node
        match ← resolveProjVal sN pinfo.i args.back! with
        | some v => changed.set true; return .done v
        | none => return .done node
      | _ => return .done node)
  if ← changed.get then return some r else return none

/-- Build a proof of `lhs = rhs` by the directed chain: normalize
    (defeq, free), substitute one registered rewrite via
    `kabstract`+`congrArg`, repeat; finish with `rfl` (elaborator
    defeq) or kernel `decide`. Every step is an ordinary term the
    kernel re-checks at addDecl (the S0 donor contract). -/
def proveHypEqBld (hp : HypPack) (lhs rhs : Expr) : TermElabM Expr := do
  let mut cur := lhs
  let mut pf : Option Expr := none
  -- the projection hop fires at most ONCE per chain (arc-18 C3b:
  -- groundNorm re-exposes `.proj` spellings the hop canonicalizes,
  -- so an unguarded hop ping-pongs against the normalizer)
  let hopUsed ← IO.mkRef false
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
      -- THE PROJECTION HOP (arc-18 C3b), last resort: nothing scans,
      -- nothing normalizes, nothing mints — respell stuck structure
      -- projections of folded successor spellings to their base form
      -- (see projNormHop). Placement is deliberately AFTER the
      -- ordinary lanes: previously-succeeding chains are untouched;
      -- the hop fires exactly where the chain used to give up and
      -- defer an uncomputable refl to the kernel (the round-56
      -- measured failure). The hop is definitional throughout, so
      -- ONE kernel-deferred bridge carries cur → hopped. Once per
      -- chain (the ping-pong guard — see hopUsed).
      if ← hopUsed.get then return (false, n, pf)
      hopUsed.set true
      match ← withCurrHeartbeats (projNormHop n) with
      | some n' =>
        if n' != n then
          trace[RelSem.roundEval] "proveHypEq: projection hop fired"
          let mut pf := pf
          let bridge ← mkExpectedTypeHint (← mkEqRefl n')
            (← mkEq cur n')
          pf := some (← match pf with
            | none => pure bridge
            | some p => mkEqTrans p bridge)
          return (true, n', pf)
        return (false, n, pf)
      | none => return (false, n, pf) :
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

end RoundEval
end RelSem
