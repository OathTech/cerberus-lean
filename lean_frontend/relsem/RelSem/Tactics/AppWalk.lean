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
  * `app_walk_norm` — the normalizing walk (v2 type-aware state
    normalization, §11.3) with the D3 per-stage certificate emitter
    ON by default (arc-11 S1, F12-4; the old opt-in `app_walk_norm!`
    surface is retired). `app_walk_norm?` is its debug lane.

  Arc-11 S1: the walk records a STRUCTURED TRACE (RelSem.Tactics.
  WalkTrace, design §12.1 — rounds, candidate fates, discharge lanes,
  seal events, ledger rows) when `WalkCfg.traceRef` is set. The trace
  is UNTRUSTED DATA: inspection/replay guidance only, never grounds
  for acceptance. Aux-constant filters consult the sealed-aux
  REGISTRY (A-F6 fix), not name conventions.

  Meta-code residency (design §1.3): `partial` is allowed here (inside
  the tactic monad only); every proof produced is kernel-checked and
  swept by the in-build audit; the D14 ban applies to outputs via the
  axiom gates.

  House rules: no sorry, no axioms.
-/

import Lean
import RelSem.Tactics.AppEqAttr
import RelSem.Tactics.WalkTrace

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
  -- LEDGERED (D3): an attempt's consumption is settled locally — the
  -- window is its own cap, and the global counter is RESTORED on exit
  -- so enclosing meters bill only their own glue (the walkLoop
  -- per-round accounting model, pushed down to every attempt).
  let hb0 ← IO.getNumHeartbeats
  let res ← Core.withCurrHeartbeats do
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
  IO.setNumHeartbeats hb0
  return res

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
  /-- Per-stage emitter (D3, LANDED arc-9 S3 §8): seal computed-value
      facts as auxiliary theorems (per-fact kernel checks). Default ON
      for `app_walk_norm` since arc-11 S1 (F12-4 sealing-as-default). -/
  sealFacts : Bool := false
  /-- Per-stage emitter (D3, LANDED): seal each round's equation as an
      auxiliary theorem (per-round kernel checks — the arc-7
      accounting). Default ON for `app_walk_norm` since arc-11 S1. -/
  sealRounds : Bool := false
  /-- Per-stage emitter (D3, LANDED): emit each normalized
      continuation state as an auxiliary definition (the T4
      named-state structure). Default ON for `app_walk_norm` since
      arc-11 S1. -/
  sealStates : Bool := false
  /-- Structured trace sink (arc-11 S1, design §12.1): when set, the
      walk records rounds/candidates/discharge events into the
      builder. The trace is UNTRUSTED DATA — inspection and (batch-3)
      replay guidance only; it never justifies acceptance. -/
  traceRef : Option TraceRef := none
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

/-- Seal a kernel-established defeq as its OWN auxiliary theorem
    (`mkAuxTheorem` closes over local fvars): the main proof then
    references an opaque constant, so the kernel's per-declaration
    recursion is bounded per COMPUTED VALUE instead of accumulating
    across a whole round application (the S3 create-round
    deep-recursion finding; the arc-7 per-round-declaration
    accounting made literal). -/
def mkAuxRfl (lhs rhs : Expr) : MetaM Expr := do
  let ty ← mkEq lhs rhs
  -- primary path: mkAuxTheorem (elaborator-side closure + check).
  -- On a BUDGET trip there, fall back to a RAW addDecl: close the
  -- type/value over fvars ourselves and let the KERNEL be the only
  -- checker (heartbeat-free) — the elaborator re-verification of a
  -- heavy defeq is exactly what the kernel engine exists to avoid.
  match ← tryCatchRuntimeEx
      (attempt (100000 * 1000)
        (mkAuxTheorem ty (← mkEqRefl lhs) (zetaDelta := false)))
      (fun _ => pure none) with
  | some pf =>
    if let some n := pf.getAppFn.constName? then
      registerSealedAux n
      pushEngineEv (.seal { name := n, kind := .cert })
    return pf
  | none =>
    let value ← mkEqRefl lhs
    let ty' ← instantiateMVars ty
    let value' ← instantiateMVars value
    -- fvar closure (shared for type and value)
    let fvars := (collectFVars {} ty').fvarIds
    let fvarExprs := fvars.map mkFVar
    let tyAbs ← mkForallFVars fvarExprs ty'
    let valAbs ← mkLambdaFVars fvarExprs value'
    if tyAbs.hasExprMVar || valAbs.hasExprMVar then
      throwError "mkAuxRfl raw fallback: residual mvars"
    let lvls := (collectLevelParams {} tyAbs).params.toList
    let nm ← mkFreshUserName `walkRfl
    let nm := nm.appendAfter "_aux"
    addDecl <| .thmDecl {
      name := nm, levelParams := lvls, type := tyAbs, value := valAbs }
    registerSealedAux nm
    pushEngineEv (.seal { name := nm, kind := .cert })
    return mkAppN (mkConst nm (lvls.map .param)) fvarExprs

/-- KERNEL-BACKED whnf for discovery computation (arc-9 S3): the
    elaborator's substitution-based whnf was MEASURED to blow the
    memory cap on deep-context eval rounds (t5 entry round 10 —
    >40G on one crossing); the kernel's closure-based reducer handles
    the same reduction like the per-round rfl declarations of the
    arc-7 hand style. Falls back to meta whnf on mvars/kernel
    errors. Proofs are unaffected (the assigned values are re-checked
    by the kernel at declaration end as always). -/
def kWhnf (e : Expr) (avatars : Bool := false) : MetaM Expr := do
  let e ← instantiateMVars e
  if e.hasExprMVar then
    if !avatars then
      return (← whnf e)
    -- AVATAR ABSTRACTION (D3, opt-in — v3 lanes only; the kernel
    -- ignores the atom discipline, so v1/v2 callers keep the
    -- elaborator path): an unassigned mvar (e.g. the abstraction
    -- avatar of a symbolic variable) is just an atom — present it as
    -- a fresh local constant, kernel-whnf, then restore. Falls back
    -- to the elaborator only if an mvar's own type carries mvars.
    let mvs := (e.collectMVars {}).result
    let mut lctx ← getLCtx
    let mut e' := e
    let mut pairs : Array (Expr × Expr) := #[]
    let mut ok := true
    for m in mvs do
      let mty ← instantiateMVars (← m.getType)
      if mty.hasExprMVar || mty.hasFVar then
        ok := false
        break
      let fid ← mkFreshFVarId
      lctx := lctx.mkLocalDecl fid ((`kAtom).appendAfter (toString pairs.size)) mty
      let fv := mkFVar fid
      e' := e'.replace (fun x => if x == mkMVar m then some fv else none)
      pairs := pairs.push (fv, mkMVar m)
    if !ok then
      pure ((← attempt (50000 * 1000) (whnf e)).getD e)
    else
      match Lean.Kernel.whnf (← getEnv) lctx e' with
      | .ok r =>
        let mut r := r
        for (fv, mv) in pairs do
          r := r.replace (fun x => if x == fv then some mv else none)
        return r
      | .error _ =>
        -- kernel refused (recursion pit); capped elaborator fallback —
        -- on a trip the caller gets the term unreduced (sealable)
        pure ((← attempt (50000 * 1000) (whnf e)).getD e)
  else do
    match Lean.Kernel.whnf (← getEnv) (← getLCtx) e with
    | .ok e' =>
      return e'
    | .error _ =>
      pure ((← attempt (50000 * 1000) (whnf e)).getD e)

/-- PROOF-CARRYING scalar evaluation (D3 emitter): returns
    `(v, proof : e = v)` with the kernel obligations DECOMPOSED —
    one small aux per non-arithmetic leaf (a projection chain to a
    literal) and one per operator fold over already-evaluated
    arguments. Rationale (measured, S3-D3 minimal repro): the
    kernel's accelerated Nat arithmetic does not fire through
    unreduced argument redexes; `Nat.div`-class operators then take
    the unary definitional path on 2^48-scale operands and trip the
    recursion guard. Decomposition keeps every obligation in the
    fast literal classes. -/
partial def evalScalarPf (scalarHeads : List Name) :
    Nat → Expr → MetaM (Expr × Expr)
  | 0, e => return (e, ← mkEqRefl e)
  | d + 1, e => do
    -- already a literal?
    let isLit (x : Expr) : Bool :=
      x.rawNatLit?.isSome
      || (x.isAppOfArity ``OfNat.ofNat 3)
      || (x.isAppOfArity ``Int.ofNat 1 && x.appArg!.rawNatLit?.isSome)
    if isLit e then return (e, ← mkEqRefl e)
    let f := e.getAppFn
    unless f.isConst do
      let v ← kWhnf e
      if Expr.equal v e then return (e, ← mkEqRefl e)
      else return (v, ← mkAuxRfl e v)
    -- recurse into scalar-typed args (arith spines); leaf otherwise
    let args := e.getAppArgs
    let mut anyScalarArg := false
    let mut newArgs := args
    let mut proofs : Array (Option Expr) := Array.replicate args.size none
    for i in [0:args.size] do
      let a := args[i]!
      let ty ← whnf (← instantiateMVars (← inferType a))
      if let .const tn _ := ty.getAppFn then
        if scalarHeads.contains tn && !isLit a then
          anyScalarArg := true
          let (v, pf) ← evalScalarPf scalarHeads d a
          newArgs := newArgs.set! i v
          proofs := proofs.set! i (some pf)
    if anyScalarArg then
      -- e = f newArgs by congr over the evaluated args, then fold
      let e' := mkAppN f newArgs
      let congPf ← observing? do
        let mut pf ← mkEqRefl f
        for i in [0:args.size] do
          match proofs[i]! with
          | some p => pf ← mkCongr pf p
          | none => pf ← mkCongr pf (← mkEqRefl args[i]!)
        pure pf
      match congPf with
      | none =>
        -- dependency prevented congr: single leaf aux
        let v ← kWhnf e
        if Expr.equal v e then return (e, ← mkEqRefl e)
        else return (v, ← mkAuxRfl e v)
      | some congPf =>
        let v ← kWhnf e'
        if Expr.equal v e' then
          return (e', congPf)
        else
          let foldPf ← mkAuxRfl e' v
          return (v, ← mkEqTrans congPf foldPf)
    else
      -- non-arith leaf: one small aux to its kernel value
      let v ← kWhnf e
      if Expr.equal v e then return (e, ← mkEqRefl e)
      else return (v, ← mkAuxRfl e v)

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

def normCompute (e : Expr) : MetaM Expr := do
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

/-- THE PER-STAGE STATE BRIDGE (walker v3, D3): prove
    `raw = normalized` for two spellings of the same structure value
    by decomposing FIELD-WISE (kernel-whnf/def-unfold one
    constructor level, `congr` assembly) and emitting one auxiliary
    rfl-theorem per DIFFERING leaf — so the kernel checks each
    normalization step (a memory write, an arena reconstruction, a
    counter fold) as its own small obligation, exactly the T4
    hand-proof granularity. Syntactically equal fields cost an
    `Eq.refl`. Depth-bounded; at the bound a leaf aux carries the
    residual (still one component's worth). -/
partial def mkStateBridge (d : Nat) (l r : Expr) : MetaM Expr := do
  if Expr.equal l r then
    mkAppM ``Eq.refl #[l]
  else if d == 0 then
    mkAuxRfl l r
  else
    let env ← getEnv
    let lctx ← getLCtx
    -- expose constructors: kernel whnf on the raw side; def-unfold +
    -- beta on a sealed-const side; fall back to the term itself
    let expose (e : Expr) : MetaM Expr := do
      if e.getAppFn.isConst then
        let n := e.getAppFn.constName!
        if let some (.defnInfo dv) := env.find? n then
          -- registry-first (A-F6 fix): the emitter registers every aux
          -- it creates; the suffix fallback covers imported auxes only
          if (← isSealedAuxName n) then
            return (dv.value.beta e.getAppArgs)
      match Lean.Kernel.whnf env lctx e with
      | .ok e' => return e'
      | .error _ => return e
    let lC ← expose l
    let rC ← expose r
    if lC.getAppFn.isConst && rC.getAppFn.isConst
        && lC.getAppFn.constName! == rC.getAppFn.constName!
        && lC.getAppArgs.size == rC.getAppArgs.size then
      match env.find? lC.getAppFn.constName! with
      | some (.ctorInfo _) =>
        let lAs := lC.getAppArgs
        let rAs := rC.getAppArgs
        -- fold the leading syntactically-equal prefix (params etc.)
        -- into the head; congr only the tail (structure fields are
        -- non-dependent). Any congr failure (dependency) falls back
        -- to a single leaf aux for this node.
        let assembled ← observing? do
          let mut k := 0
          while h : k < lAs.size do
            if Expr.equal lAs[k] rAs[k]! then k := k + 1 else break
          let mut pf ← mkEqRefl (mkAppN lC.getAppFn lAs[:k])
          for i in [k:lAs.size] do
            if Expr.equal lAs[i]! rAs[i]! then
              pf ← mkCongr pf (← mkEqRefl lAs[i]!)
            else
              pf ← mkCongr pf (← mkStateBridge (d-1) lAs[i]! rAs[i]!)
          pure pf
        match assembled with
        | none => mkAuxRfl l r
        | some pf =>
          -- bridge the outer spellings to the exposed ctor forms
          let lB ← if Expr.equal l lC then mkEqRefl l
                   else mkAuxRfl l lC
          let rB ← if Expr.equal rC r then mkEqRefl r
                   else mkAuxRfl rC r
          mkEqTrans lB (← mkEqTrans pf rB)
      | _ => mkAuxRfl l r
    else
      mkAuxRfl l r

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
          -- Per-stage emitter (D3, landed): emit the normalized state
          -- as an auxiliary DEFINITION and continue with the constant
          -- — the T4 named-state structure (default in the sealing
          -- lane since arc-11 S1).
          let stTy ← inferType st'
          let stConst ← mkAuxDefinition
            ((← mkFreshUserName `walkSt).appendAfter "_aux") stTy st'
            (compile := false)
          if let some n := stConst.getAppFn.constName? then
            registerSealedAux n
            pushEngineEv (.seal { name := n, kind := .state, depthBefore := e.appArg!.approxDepth.toNat, depthAfter := st'.approxDepth.toNat })
          if cfg.trace then
            let n := stConst.getAppFn.constName!
            let body := ((← getEnv).find? n).map (fun ci => ci.value?.getD (mkConst `x)) |>.getD (mkConst `x)
            dbg_trace "sealState {n} bodyDepth={body.approxDepth} args={stConst.getAppArgs.size} headOfBody={toString body.getAppFn |>.take 40}"
          return mkAppN e.getAppFn (args.set! i stConst)
        return mkAppN e.getAppFn (args.set! i st')
  return e

/-- Kernel-engine spine normalizer: kernel-whnf at each level,
    recursing into constructor fields (heartbeat-free fallback for
    when the elaborator normalizer trips the ambient budget). -/
partial def kNormCompute (d : Nat) (e : Expr) : MetaM Expr := do
  if d == 0 then return e
  let e1 ← kWhnf e
  let hd := e1.getAppFn
  if hd.isConst then
    if let some (.ctorInfo ci) := (← getEnv).find? hd.constName! then
      let args := e1.getAppArgs
      let mut out := args
      for i in [ci.numParams : args.size] do
        out := out.set! i (← kNormCompute (d-1) args[i]!)
      return mkAppN hd out
  return e1

/-- Seal the LEAVES of a constructor spine as auxiliary definitions:
    constructor structure stays visible (pattern hypotheses must still
    match), while each large non-constructor leaf becomes a constant —
    downstream traversals (occurs checks, whnfCore, congruence) see
    small terms and the kernel unfolds on demand. -/
partial def sealCtorLeaves (d : Nat) (e : Expr) : MetaM Expr := do
  let sealIfBig (x : Expr) : MetaM Expr := do
    let already ← match x.getAppFn.constName? with
      | some n => (isSealedAuxName n : MetaM Bool)
      | none => pure false
    if already || x.approxDepth.toNat ≤ 24 then return x
    -- capped: type inference can be arbitrarily deep on continuation
    -- lambdas — an unsealable leaf stays raw rather than burning
    pure ((← attempt (100000 * 1000) (do
      let nm := (← mkFreshUserName `walkVal).appendAfter "_aux"
      let r ← mkAuxDefinition nm (← inferType x) x (compile := false)
      if let some n := r.getAppFn.constName? then
        registerSealedAux n
        pushEngineEv (.seal { name := n, kind := .value, depthBefore := x.approxDepth.toNat, depthAfter := r.approxDepth.toNat })
      pure r)).getD x)
  if d == 0 then return (← sealIfBig e)
  -- normalize to constructor form first (kernel engine): an
  -- unreduced element would otherwise be sealed whole, hiding its
  -- constructor from law dispatch (DiscrTree keys).
  let e0 := e
  let e ← if e.approxDepth.toNat > 24 then kWhnf e (avatars := true) else pure e
  let hd := e.getAppFn
  if hd.isConst then
    if let some (.ctorInfo ci) := (← getEnv).find? hd.constName! then
      let args := e.getAppArgs
      let mut out := args
      for i in [ci.numParams : args.size] do
        out := out.set! i (← sealCtorLeaves (d-1) args[i]!)
      return mkAppN hd out
  let r ← sealIfBig e
  -- a leaf that could not be sealed keeps its ORIGINAL (pre-whnf)
  -- spelling — never trade a compact unreduced form for a large
  -- materialized one without a seal to pay for it
  if !r.getAppFn.isConst || r.approxDepth.toNat ≤ e0.approxDepth.toNat then
    return r
  if (← match r.getAppFn.constName? with
      | some n => (isSealedAuxName n : MetaM Bool)
      | none => pure false) then
    return r
  return e0

/-- Collect closed `decide P` applications in an expression
    (bounded traversal; duplicates deduped). -/
partial def collectDecides (e : Expr) : Array Expr := Id.run do
  let mut out : Array Expr := #[]
  let mut stack : Array Expr := #[e]
  let mut fuel := 100000
  while h : stack.size > 0 do
    if fuel == 0 then break
    fuel := fuel - 1
    let x := stack[stack.size - 1]
    stack := stack.pop
    if x.isAppOfArity ``decide 2 && !x.hasLooseBVars then
      if !out.any (Expr.equal · x) then out := out.push x
    match x with
    | .app f a => stack := stack.push f |>.push a
    | .lam _ _ b _ => stack := stack.push b
    | .letE _ _ v b _ => stack := stack.push v |>.push b
    | .mdata _ b => stack := stack.push b
    | .proj _ _ b => stack := stack.push b
    | _ => pure ()
  return out

/-- Find a closed `decide P` subterm of `e` with a matching context
    hypothesis `h : P` (or `h : ¬P`). -/
def findDecideFact (e : Expr) : MetaM (Option (Expr × Expr × Bool)) := do
  for dec in collectDecides e do
    let P := dec.getAppArgs[0]!
    for decl in (← getLCtx) do
      if decl.isImplementationDetail then continue
      let dty ← instantiateMVars decl.type
      if dty.isMVar then continue
      -- small props: full-transparency defeq (literal spellings vary:
      -- `Int.ofNat 0` vs `OfNat.ofNat 0`; bounds sit under matcher
      -- spellings like `maxIval`)
      if (← observing? (do unless (← isDefEq dty P) do failure)).isSome then
        return some (dec, decl.toExpr, true)
      if dty.isAppOfArity ``Not 1 then
        if (← observing? (do
            unless (← isDefEq dty.appArg! P) do failure)).isSome then
          return some (dec, decl.toExpr, false)
  return none

/-- DECIDE-REWRITING evaluation (D3, the T1-s4 ladder mechanized).

    Kernel-whnf until stuck. A symbolic `decide P` blocking the
    reduction generally sits INSIDE an unreduced recursor major /
    matcher discriminant (it materializes only transiently during
    whnf), so on a stuck form we CHASE: descend into the stuck
    position, recursively rewrite there, and MATERIALIZE the advanced
    subterm back into the parent via an `Eq.ndrec` motive step (the
    matcher result types are syntactically discr-dependent, so
    `congrArg` does not apply); then resume whnf at the parent. Every
    kernel obligation stays small: aux-rfl segments (pure definitional
    advances) and one-position congruences (the rewrites). Returns
    `(value, proof : e = value, progressed)`. -/
partial def kWhnfWithFacts (d : Nat) (e : Expr) :
    MetaM (Expr × Expr × Bool) := do
  let e1 ← kWhnf e (avatars := true)
  let changed := !(Expr.equal e e1)
  let p1 ← if changed then mkAuxRfl e e1 else mkEqRefl e
  if d == 0 then return (e1, p1, changed)
  -- (a) a decide visible at this level with a context fact: rewrite,
  -- materialize its Boolean, resume.
  if let some (dec, hpf, pos) ← findDecideFact e1 then
    let fname ← if hpf.isFVar then
        do pure (← hpf.fvarId!.getDecl).userName
      else pure Name.anonymous
    pushEngineEv (.decideFact fname pos)
    let bval := if pos then mkConst ``Bool.true else mkConst ``Bool.false
    let hdec ← if pos then mkAppM ``decide_eq_true #[hpf]
               else mkAppM ``decide_eq_false #[hpf]
    let motiveBody ← kabstract e1 dec
    if motiveBody.hasLooseBVars then
      let τ ← inferType e1
      let u ← getLevel τ
      let eqMotive := Lean.mkLambda `x .default (mkConst ``Bool)
        (mkApp3 (mkConst ``Eq [u]) τ e1 motiveBody)
      let base ← mkExpectedTypeHint (← mkEqRefl e1)
        (mkApp3 (mkConst ``Eq [u]) τ e1 (motiveBody.instantiate1 dec))
      let p2 ← mkEqNDRec eqMotive base hdec
      let e2 := motiveBody.instantiate1 bval
      let (v, p3, _) ← kWhnfWithFacts (d-1) e2
      return (v, ← mkEqTrans p1 (← mkEqTrans p2 p3), true)
  -- (b) stuck on a recursor/matcher: chase into the blocking
  -- position(s), advance there, materialize, resume here.
  let hd := e1.getAppFn
  if hd.isConst && e1.isApp then
    let n := hd.constName!
    let args := e1.getAppArgs
    let positions : Array Nat ← do
      if ((← getEnv).find? n).any (fun ci => ci matches .recInfo _) then
        pure #[args.size - 1]
      else if let some mi ← Lean.Meta.getMatcherInfo? n then
        pure <| (Array.range mi.numDiscrs).map (mi.numParams + 1 + ·)
      else pure #[]
    for i in positions do
      if h : i < args.size then
        let (sv, spf, sChanged) ← kWhnfWithFacts (d-1) args[i]
        if sChanged then
          let aty ← inferType args[i]
          let τ ← inferType e1
          let cAt := fun (x : Expr) => mkAppN hd (args.set i x (by simpa using h))
          let u ← getLevel τ
          let eqMotive := Lean.mkLambda `x .default aty
            (mkApp3 (mkConst ``Eq [u]) τ e1 (cAt (mkBVar 0)))
          let base ← mkExpectedTypeHint (← mkEqRefl e1)
            (mkApp3 (mkConst ``Eq [u]) τ e1 (cAt args[i]))
          let p2 ← mkEqNDRec eqMotive base spf
          let e2 := cAt sv
          let e3 ← kWhnf e2 (avatars := true)
          if Expr.equal e3 e2 then
            continue
          let p3 ← mkAuxRfl e2 e3
          let (v, p4, _) ← kWhnfWithFacts (d-1) e3
          return (v, ← mkEqTrans p1 (← mkEqTrans p2 (← mkEqTrans p3 p4)), true)
  return (e1, p1, changed)

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
  if let some (eqTy, lhs, rhs) := ty.eq? then
    let _ := eqTy
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
     -- ENUMERATION SHORT-CIRCUIT (D3, v3 lane): a bare-mvar step
     -- enumeration (`step_ctx … = ?steps`) is consumed only by the
     -- selection hypothesis, which kernel-whnfs its LHS anyway —
     -- plant the enumeration VERBATIM with a rfl certificate; the
     -- selection's own certificate carries the real computation.
     if cfg.sealStates && rhs.isMVar && lhs.isAppOf `step_ctx then
       if (← isDefEq rhs lhs) then
         h.assign (← mkEqRefl lhs)
         trHyp cfg.traceRef
           (.seal { name := .anonymous, kind := .enumVerbatim })
         if cfg.trace then dbg_trace "dh[{fuel}]: enum verbatim-plant"
         return true
     -- (A-F4 cleanup, arc-11 S1: the vestigial `if true then` guard is
     -- gone; the nested `do` keeps the block's indentation and the
     -- enclosing early-return semantics unchanged.)
     do
      let st ← saveState
      let depth := 4 - min 4 fuel
      match ← attempt cfg.candBudget (do
          let t0 ← IO.monoMsNow
          -- SCALAR-typed facts go through the PROOF-CARRYING
          -- evaluator (decomposed kernel obligations — the D3
          -- unary-arithmetic finding); the aux-rfl of a raw
          -- arithmetic spelling is never used.
          if cfg.norm && cfg.sealFacts then
            let lty ← whnf (← instantiateMVars (← inferType lhs))
            if let .const tn _ := lty.getAppFn then
              if scalarTypeHeads.contains tn then
                let (v, pf) ← evalScalarPf scalarTypeHeads 16 lhs
                if (← isDefEq rhs v) then
                  h.assign pf
                  trHyp cfg.traceRef
                    (.scalarPf depth pf.getAppFn.constName?)
                  return true
                else
                  return false
          -- selection-shaped facts (`some ?x` patterns) take the
          -- kernel-whnf output VERBATIM: the value is a subterm of an
          -- already-normal spine, and re-normalization creates a
          -- structurally different form whose kernel bridge
          -- deep-recurses (S3 hfind finding).
          let isSelection := rhs.isApp && rhs.getAppFn.isConstOf ``Option.some
          let v? ← do
            if cfg.norm then
              tryCatchRuntimeEx
                ((if isSelection then kWhnf lhs
                  else normCompute lhs) <&> some)
                (fun _ => pure none)
            else
              -- v1: original behavior, no fallback lane
              (normSpine 4 lhs) <&> some
          -- A budget trip inside the normalizer exhausted THIS
          -- attempt's heartbeat window; the kernel-engine fallback
          -- and everything after it run under a FRESH window (the
          -- fallback work itself is kernel-side, heartbeat-free).
          let contFresh := v?.isNone
          let v ← match v? with
            | some v => pure v
            | none => do
              if cfg.trace then
                dbg_trace "dh[{fuel}]: normCompute TRIPPED ({(← IO.monoMsNow) - t0}ms); kWhnf fallback"
              Core.withCurrHeartbeats (kWhnf lhs (avatars := cfg.sealStates))
          if cfg.trace then
            dbg_trace "dh[{fuel}]: lane v ready ({(← IO.monoMsNow) - t0}ms)"
          (if contFresh then Core.withCurrHeartbeats else id) do
          -- VALUE SEALING (v3 lane): huge computed values (step
          -- enumerations embedding whole continuations) get their
          -- constructor-spine LEAVES sealed before planting.
          let v ← do
            if cfg.sealStates && v.approxDepth.toNat > 24 then
              let v' ← sealCtorLeaves 12 v
              if cfg.trace then
                dbg_trace "dh[{fuel}]: sealed leaves (depth {v.approxDepth.toNat} → {v'.approxDepth.toNat})"
              pure v'
            else pure v
          let defeqOk ← isDefEq rhs v
          if cfg.trace then
            dbg_trace "dh[{fuel}]: lane isDefEq={defeqOk} ({(← IO.monoMsNow) - t0}ms)"
          if defeqOk then
            if cfg.sealFacts then
              -- fresh window: the value computation/unification above
              -- may have consumed this attempt's budget; the
              -- certificate build is mostly kernel-side work
              let pf ← Core.withCurrHeartbeats do
                try mkAuxRfl lhs (← instantiateMVars rhs)
                catch ex =>
                  if cfg.trace then
                    -- emit a standalone repro (the fact type + every
                    -- referenced walk const body) on the TRACE stream.
                    -- No file IO here (audit A-F1): an IO failure in
                    -- diagnostics must never mask the original `ex`.
                    dbg_trace "dh[{fuel}]: mkAuxRfl THREW: {← ex.toMessageData.toString}"
                    let ty ← mkEq lhs (← instantiateMVars rhs)
                    dbg_trace "dh[{fuel}]: repro FACT TYPE:\n{← ppExpr ty}"
                    let cs := ty.getUsedConstants
                    for c in cs do
                      let isW := match c with
                        | .str _ t => t.startsWith "walkSt" || t.endsWith "_aux"
                        | _ => false
                      if isW then
                        if let some ci := (← getEnv).find? c then
                          dbg_trace "dh[{fuel}]: repro CONST {c} : {← ppExpr ci.type}"
                          if let some v := ci.value? then
                            dbg_trace "dh[{fuel}]: repro BODY:\n{← ppExpr v}"
                  throw ex
              h.assign pf
              trHyp cfg.traceRef (.computed depth
                (if !cfg.norm then .spineV1
                 else if contFresh then .kWhnfAvatars
                 else if isSelection then .selectionKWhnf
                 else .normCompute) pf.getAppFn.constName?)
            else
              h.assign (← mkEqRefl lhs)
              trHyp cfg.traceRef (.computed depth
                (if !cfg.norm then .spineV1
                 else if contFresh then .kWhnfAvatars
                 else if isSelection then .selectionKWhnf
                 else .normCompute) none)
            return true
          else
            -- DECIDE-FACTS route (D3): a run-state crossing stuck on
            -- a symbolic `decide P` with a context fact `h : P` —
            -- chase-rewrite-and-resume (kWhnfWithFacts), then
            -- normalize the resumed value; the certificate is the
            -- facts chain composed with an aux-rfl bridge.
            if cfg.norm && cfg.sealFacts && !isSelection
                && !lhs.isAppOf `RelSem.app then
              let (v0, pf0, prog) ←
                try kWhnfWithFacts 24 lhs
                catch ex =>
                  if cfg.trace then
                    dbg_trace "dh[{fuel}]: kWhnfWithFacts THREW: {(← ex.toMessageData.toString).take 300}"
                  throw ex
              if prog && !(Expr.equal v0 v) then
                let v1 ← tryCatchRuntimeEx
                  (normCompute v0) (fun _ => pure v0)
                if (← isDefEq rhs v1) then
                  let rhs' ← instantiateMVars rhs
                  let pfB ← if Expr.equal v0 rhs' then mkEqRefl v0
                            else mkAuxRfl v0 rhs'
                  h.assign (← mkEqTrans pf0 pfB)
                  trHyp cfg.traceRef (.computed depth .kWhnfAvatars
                    pfB.getAppFn.constName?)
                  if cfg.trace then dbg_trace "dh[{fuel}]: decide-facts HIT"
                  return true
            if cfg.trace then
              dbg_trace "dh[{fuel}]: lane isDefEq FAILED; v-head: {v.getAppFn}"
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
            -- OP PRE-MATCH (D3): for `app comp mem`-shaped facts,
            -- require the COMPUTATION arguments to unify FIRST
            -- (small terms, no states) — a wrong-op fact must miss
            -- fast; full-type unification on a mismatched op was
            -- measured to fall into whole-computation reduction.
            -- Both defeq steps are BUDGET-CAPPED (ledgered): a fact
            -- that cannot be decided quickly is a MISS, never a
            -- window burn.
            let opOk ← do
              if lhs.isAppOfArity `RelSem.app 7
                  && dlhs.isAppOfArity `RelSem.app 7 then
                pure <| (← attempt (20000 * 1000) (do
                  unless (← isDefEq dlhs.getAppArgs[5]!
                      lhs.getAppArgs[5]!) do failure)).isSome
              else pure true
            if opOk then
              if (← attempt (100000 * 1000) (do
                  unless (← isDefEq dty ty) do failure
                  h.assign decl.toExpr)).isSome then
                trHyp cfg.traceRef
                  (.assumption (4 - min 4 fuel) decl.userName)
                if cfg.trace then dbg_trace "assum HIT {decl.userName}"
                return true
      return false
  if tried then return true
  if cfg.trace then dbg_trace "dh[{fuel}]: past-assumption ({(← IO.monoMsNow) - ta0}ms)"
  match fuel, ty.eq? with
  | fuel + 1, some (_, lhs, _) =>
    -- (ii) one-shot registered law on an app-shaped hypothesis
    let t0 ← IO.monoMsNow
    -- capped: a pathological whnfCore / DiscrTree key computation
    -- (matcher scrutinee chains over large embedded terms) must not
    -- burn the enclosing window
    let lhs ← Core.withCurrHeartbeats <| tryCatchRuntimeEx
      (attempt (20000 * 1000) (whnfCore lhs) <&> (·.getD lhs))
      (fun _ => pure lhs)
    let t1 ← IO.monoMsNow
    let cands ← Core.withCurrHeartbeats <| tryCatchRuntimeEx
      (attempt (20000 * 1000) (appEqMatches lhs) <&> (·.getD #[]))
      (fun _ => pure #[])
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
                -- per-hyp ledger window: each discharge is internally
                -- capped; its consumption must not bill the round
                let okh ← Core.withCurrHeartbeats (dischargeHyp cfg fuel a.mvarId!)
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
        -- fresh window: hyp discharges may have consumed this
        -- attempt's entire budget; assembling and planting the proof
        -- must not inherit their bill
        Core.withCurrHeartbeats do
          -- any remaining non-Prop arg mvars must be determined
          let proof ← instantiateMVars (mkAppN lemExpr args)
          if proof.hasExprMVar then
            if cfg.trace then dbg_trace "dh law {law.name}: RESIDUAL MVARS"
            return false
          h.assign proof
          return true)
      match res with
      | some true =>
        trHyp cfg.traceRef (.lawFired (4 - min 4 (fuel+1)) law.name)
        return true
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
          let pf ← mkAuxRfl lhs' (← instantiateMVars rhs')
          h.assign pf
          trHyp cfg.traceRef
            (.rflClosed (4 - min 4 (fuel+1)) pf.getAppFn.constName?)
        else
          h.assign (← mkEqRefl lhs')
          trHyp cfg.traceRef (.rflClosed (4 - min 4 (fuel+1)) none)
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
  -- (A-F4 cleanup, arc-11 S1: the dead `verbose && false` raw-attempt
  -- block is deleted — its diagnostic role is covered by the
  -- structured trace + the dischargeHyp trace lane.)
  for law in cands do
    trResetHyps cfg.traceRef
    -- per-candidate fate cell: the attempt's do-block records WHY the
    -- candidate failed; an attempt-level abort (budget/runtime trip)
    -- leaves it empty and is recorded as `.aborted` (the survey
    -- rank-3 requirement: every candidate considered gets a fate).
    let fateCell ← IO.mkRef (none : Option CandFate)
    let st ← saveState
    let res ← attempt (dbg := verbose) cfg.candBudget (do
      let lemExpr ← mkConstWithFreshMVarLevels law.name
      let (args, _, lemTy) ← forallMetaTelescopeReducing
        (← inferType lemExpr)
      let some (_, lemLhs, lemRhs) := lemTy.eq? | return none
      unless (← isDefEq lemLhs lhs) do
        fateCell.set (some .lhsMismatch)
        if verbose then logInfo m!"app_walk?: {law.name} LHS mismatch"
        return none
      -- side hypotheses
      let mut ok := true
      let mut hidx := 0
      for a in args do
        if a.isMVar then
         if !(← a.mvarId!.isAssigned) then
          if (← isProp (← inferType a)) then
            unless (← Core.withCurrHeartbeats (dischargeHyp cfg 4 a.mvarId!)) do
              fateCell.set (some (.hypFailed hidx))
              if verbose then
                let ty' ← instantiateMVars (← a.mvarId!.getType)
                let lhsHead := match ty'.eq? with
                  | some (_, l, _) => toString l.getAppFn ++ " " ++ String.intercalate " " (l.getAppArgs.map (fun (x : Expr) => toString x.getAppFn)).toList
                  | none => toString ty'.getAppFn
                dbg_trace "app_walk?: {law.name} rejected — not mechanical: {lhsHead.take 300}"
              ok := false
              break
            hidx := hidx + 1
      unless ok do return none
      let proof ← Core.withCurrHeartbeats (instantiateMVars (mkAppN lemExpr args))
      if proof.hasExprMVar then
        fateCell.set (some .residualMvars)
        return none
      let lemRhs ← instantiateMVars lemRhs
      -- terminal: the law's RHS meets the goal's RHS directly
      if (← withReducible <| isDefEq lemRhs rhs) then
        goal.assign (← mkEqTrans proof (← mkEqRefl rhs))
        return some (law.name, none)
      -- chain: Eq.trans into a continuation goal. Under v2 the
      -- continuation's LHS state is replaced by its normalized
      -- (defeq) image; in the PER-STAGE lane (D3) the raw↔normalized
      -- bridge is proven field-wise (mkStateBridge — one aux per
      -- differing leaf) instead of being left to the trans
      -- unification as one monolithic kernel defeq.
      let lemRhsN ← normAppState cfg lemRhs
      let proof ← do
        if cfg.sealStates && !(Expr.equal lemRhs lemRhsN) then
          let bridge ←
            if lemRhs.isApp && lemRhsN.isApp
                && Expr.equal lemRhs.appFn! lemRhsN.appFn! then do
              let sb ← mkStateBridge 6 lemRhs.appArg! lemRhsN.appArg!
              mkAppM ``congrArg #[lemRhs.appFn!, sb]
            else mkAuxRfl lemRhs lemRhsN
          mkEqTrans proof bridge
        else pure proof
      -- PER-ROUND SEALING (after the bridge: the sealed type is a
      -- named-state-to-named-state equation — small for the kernel).
      let proof ← if cfg.sealRounds then do
          let pty ← instantiateMVars (← inferType proof)
          let pf ← mkAuxTheorem pty proof (zetaDelta := false)
          if let some n := pf.getAppFn.constName? then
            registerSealedAux n
            pushEngineEv (.seal { name := n, kind := .round })
          pure pf
        else pure proof
      let restTy ← mkEq lemRhsN rhs
      let rest ← mkFreshExprMVar restTy (userName := `walk)
      goal.assign (← mkEqTrans proof rest)
      return some (law.name, some rest.mvarId!))
    match res with
    | some (some r) =>
      trFate cfg.traceRef law.name law.prio .fired
      return some r
    | _ =>
      trFate cfg.traceRef law.name law.prio
        ((← fateCell.get).getD .aborted)
      restoreState st
  -- no law fired: leave the goal untouched
  let _ := α
  return none

/-- The walk loop: up to `budget` rounds, then (if the goal survives)
    try `rfl`. Reports the trace when `verbose`. -/
private partial def walkLoopCore (cfg : WalkCfg) (goal : MVarId)
    (budget : Nat) (verbose : Bool) :
    TacticM (Option MVarId) := do
  let mut g := goal
  let mut idx := 0
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
    let hbUsed := (← IO.getNumHeartbeats) - hb0
    IO.setNumHeartbeats hb0
    let ledger : Ledger :=
      { ms := (← IO.monoMsNow) - t0, hb := hbUsed / 1000 }
    match step? with
    | some (n, some g') =>
      trCloseRound cfg.traceRef idx (some n) ledger
      idx := idx + 1
      if verbose then
        dbg_trace "app_walk: {n} ({(← IO.monoMsNow) - t0}ms)"
      g := g'
    | some (n, none) =>
      trCloseRound cfg.traceRef idx (some n) ledger
      trOutcome cfg.traceRef .closedTerminal
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
      trCloseRound cfg.traceRef idx none ledger
      if rflRes.isSome then
        trOutcome cfg.traceRef .closedRfl
        if verbose then logInfo m!"app_walk: closed by rfl"
        return none
      trOutcome cfg.traceRef (.stuck none)
      if verbose then dbg_trace "app_walk?: returning stuck goal"
      return some g
  trOutcome cfg.traceRef .budget
  return some g

/-- The walk loop, tracing-aware wrapper: enables the low-level
    engine event buffer for a traced walk and restores it on every
    exit path (structured tracing, arc-11 S1 — design §12.1). -/
partial def walkLoop (cfg : WalkCfg) (goal : MVarId) (budget : Nat)
    (verbose : Bool) :
    TacticM (Option MVarId) := do
  if cfg.traceRef.isSome then engineEvEnabled.set true
  try
    walkLoopCore cfg goal budget verbose
  finally
    engineEvEnabled.set false
    engineEvBuf.set #[]

/-- `app_walk` / `app_walk n` — see the header contract. -/
syntax (name := appWalk) "app_walk" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    match ← walkLoop {} goal budget false with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- The `app_walk_norm` configuration (arc-11 S1, F12-4
    sealing-as-default): type-aware selective state normalization
    (design §11.3) WITH the D3 per-stage certificate emitter
    (sealFacts/sealRounds/sealStates) — name-every-big-term as the
    standing invariant (design §12.6 batch 1; Lithium review §6
    item 1). `app_walk` (v1) is untouched. -/
def normWalkCfg (atoms : NameSet) : WalkCfg :=
  { norm := true, atoms := atoms, candBudget := 200000 * 1000,
    sealFacts := true, sealRounds := true, sealStates := true }

/-- `app_walk_norm` / `app_walk_norm n` — the normalizing walk with
    the per-stage certificate emitter ON by default (arc-11 S1;
    formerly the `app_walk_norm!` surface, now retired). -/
syntax (name := appWalkNorm) "app_walk_norm" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk_norm $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    let atoms ← stateAtoms
    match ← walkLoop (normWalkCfg atoms) goal budget false with
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

-- (`app_walk_norm!` RETIRED, arc-11 S1 F12-4: sealing is
-- `app_walk_norm`'s default; the ban-list row is dropped in the same
-- commit — scripts/check_proof_size.sh.)

/-- `app_walk_norm?` — the norm-walk debug lane (banned in committed
    proofs, same as `app_walk?`): mirrors `app_walk_norm`'s
    configuration (seals ON), verbose + discharge tracing, and prints
    the STRUCTURED trace dump at walk end (design §12.1). -/
syntax (name := appWalkNormDebug) "app_walk_norm?" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk_norm? $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 1
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let tr ← IO.mkRef ({} : TraceSt)
    let cfg : WalkCfg :=
      { normWalkCfg atoms with trace := true, traceRef := some tr }
    let res ← walkLoop cfg goal budget true
    logInfo m!"{((← tr.get).toTrace.dump (hyps := true))}"
    match res with
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
  let wakeOk := match wakeName with
    | .str _ tail => tail == "NOWAKEUP"
    | _ => false
  unless wakeOk do return none
  let σraw := adv.getAppArgs[3]!
  -- normalize + seal the post-state
  let σnorm ← normStateV2 cfg.atoms cfg.depth σraw
  let σconst ← mkAuxDefinition
    ((← mkFreshUserName `kwSt).appendAfter "_aux")
    (← inferType σnorm) σnorm (compile := false)
  if let some n := σconst.getAppFn.constName? then
    registerSealedAux n
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
