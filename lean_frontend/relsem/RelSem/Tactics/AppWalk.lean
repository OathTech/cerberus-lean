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
          if dbg then
            -- dbg_trace, NOT logInfo: the caller's restoreState rolls
            -- the message log back, silently eating logInfo output
            -- from failed attempts (arc-11 S2 diagnosis finding)
            dbg_trace "app_walk?: attempt failed — {← ex.toMessageData.toString}"
          return none)
        (fun ex => do
          if dbg then
            dbg_trace "app_walk?: attempt ABORTED — {← ex.toMessageData.toString}"
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
  /-- PREVIEW mode (arc-11 S1 batch 2, design §12.2 as amended in the
      batch-1 record): discovery + trace WITHOUT closing power — the
      walk NEVER assigns any goal metavariable and never assembles a
      round/goal proof (state bridge + round seal + goal.assign are
      skipped). Fact-level aux certificates and value/state seal
      definitions still occur (faithful discovery needs them; they
      cannot close the user's theorem). NEVER CI-authoritative: the
      `app_walk_preview` tactic always fails, and the surface is
      gate-banned in committed proofs. -/
  preview : Bool := false
  /-- REPLAY restriction (arc-11 S1 batch 3, design §12.2): when set,
      `walkOnce` considers ONLY this law — replay removes CHOICE, not
      checking (every unification/discharge/kernel check re-runs). -/
  replayOnly : Option Name := none
  /-- SEAL-THROUGH-THE-CHASE checkpoint threshold (engineRev 5, the
      R13 wall kill). SEMANTICS: the maximum `approxDepth` an
      intermediate chase form may have before the chase NAMES it (a
      checkpoint seal — an ordinary aux definition) and continues
      against the seal constant, so every kernel certificate
      STATEMENT stays a shallow reference and every kernel defeq
      obligation's reduction anchors at a named constant. This is NOT
      a heartbeat-style ambient knob: raising it cannot make a stuck
      goal provable and lowering it cannot make a provable goal stuck
      — it only trades kernel-obligation COUNT against per-obligation
      statement depth (the stepper-note trade; count parallelizes,
      depth doesn't). Default measured against the R13 crossing (the
      `RSK_eval "Epure"` PEcase eval whose monolithic Kernel.whnf
      died with `deep recursion detected`): materialized parents at
      R13 sit at approxDepth 60-85, so 48 checkpoints every
      materialization there while leaving the shallow pre-R13 chase
      segments (≤ 48) un-sealed. -/
  chaseSealDepth : Nat := 48
  /-- The eq-fact chase's recursion fuel (was the hard-coded 48; a
      walker-internal LEDGERED sub-cap — bounds chase advances per
      discharge, never a kernel/elaborator budget). Deep R13-class
      evals consume one unit per position descent/advance/resume. -/
  chaseDepth : Nat := 48
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

/-- RAW kernel-only aux theorem (the shared mkAuxRfl/mkAuxThmRobust
    fallback, arc-15 T5 resumption): close `ty`/`val` over local
    fvars AND over unassigned LEVEL mvars — each level mvar becomes a
    FRESH LEVEL PARAM on the declaration side, and the returned
    reference instantiates that param with the ORIGINAL mvar, so the
    ambient proof is unchanged (measured defect: the round-seal raw
    fallback hit `(kernel) declaration has metavariables` on 6
    surviving universe mvars at the symbolic-j round 4 — the expr-mvar
    guard alone was not closure). The KERNEL remains the only checker
    (`addDecl`, heartbeat-free). -/
def addRawAuxThm (ty val : Expr) (base : Name) (kind : SealKind) :
    MetaM Expr := do
  let ty' ← instantiateMVars ty
  let val' ← instantiateMVars val
  let used := (collectFVars (collectFVars {} ty') val').fvarIds
  let used ← sortFVarIds used
  let fvarExprs := used.map mkFVar
  let tyAbs ← mkForallFVars fvarExprs ty'
  let valAbs ← mkLambdaFVars fvarExprs val'
  if tyAbs.hasExprMVar || valAbs.hasExprMVar then
    throwError "addRawAuxThm ({base}): residual expr mvars"
  -- LEVEL-MVAR closure
  let lmvs := (collectLevelMVars (collectLevelMVars {} tyAbs) valAbs).result
  let mut freshPs : Array (LMVarId × Name) := #[]
  for m in lmvs do
    freshPs := freshPs.push (m, (← mkFreshUserName `wu))
  let repl : Level → Option Level := fun l => match l with
    | .mvar id => (freshPs.find? (fun p => p.1 == id)).map
        (fun p => .param p.2)
    | _ => none
  let tyAbs := if freshPs.isEmpty then tyAbs else tyAbs.replaceLevel repl
  let valAbs := if freshPs.isEmpty then valAbs else valAbs.replaceLevel repl
  let lvls := (collectLevelParams (collectLevelParams {} tyAbs)
    valAbs).params.toList
  let nm ← mkFreshUserName base
  let nm := nm.appendAfter "_aux"
  addDecl <| .thmDecl {
    name := nm, levelParams := lvls, type := tyAbs, value := valAbs }
  registerSealedAux nm
  pushEngineEv (.seal { name := nm, kind := kind })
  let lvlArgs := lvls.map fun p =>
    match freshPs.find? (fun q => q.2 == p) with
    | some (m, _) => mkLevelMVar m
    | none => Level.param p
  return mkAppN (mkConst nm lvlArgs) fvarExprs

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
    -- RAW addDecl fallback (kernel-only checking; fvar + LEVEL-mvar
    -- closure shared with the round seal — addRawAuxThm).
    addRawAuxThm ty (← mkEqRefl lhs) `walkRfl .cert

/-- Seal an arbitrary PROOF as its own auxiliary theorem, robustly
    (arc-11 S2, the round-seal trip): primary path `mkAuxTheorem`
    (elaborator-side closure + check, budget-capped); on a trip, RAW
    `addDecl` — close type and value over their fvars and let the
    KERNEL be the only checker (heartbeat-free), exactly the
    `mkAuxRfl` fallback generalized to non-rfl values. -/
def mkAuxThmRobust (ty val : Expr) (base : Name := `walkRound) :
    MetaM Expr := do
  match ← tryCatchRuntimeEx
      (attempt (100000 * 1000) (do
        try mkAuxTheorem ty val (zetaDelta := false)
        catch ex =>
          dbg_trace "mkAuxThmRobust: primary mkAuxTheorem failed — {(← ex.toMessageData.toString).take 300}"
          throw ex))
      (fun ex => do
        dbg_trace "mkAuxThmRobust: primary ABORTED — {(← ex.toMessageData.toString).take 300}"
        pure none) with
  | some pf =>
    if let some n := pf.getAppFn.constName? then
      registerSealedAux n
      pushEngineEv (.seal { name := n, kind := .round })
    return pf
  | none =>
    -- RAW addDecl fallback (kernel-only checking; fvar + LEVEL-mvar
    -- closure — addRawAuxThm).
    addRawAuxThm ty val base .round

/-- KERNEL-BACKED whnf for discovery computation (arc-9 S3): the
    elaborator's substitution-based whnf was MEASURED to blow the
    memory cap on deep-context eval rounds (t5 entry round 10 —
    >40G on one crossing); the kernel's closure-based reducer handles
    the same reduction like the per-round rfl declarations of the
    arc-7 hand style. Falls back to meta whnf on mvars/kernel
    errors. Proofs are unaffected (the assigned values are re-checked
    by the kernel at declaration end as always).
    engineRev 5 (`kWhnfR`): returns the reduct PLUS the kernel-refusal
    signal (the deep-recursion pit — a kernel `.error`, distinct from
    an ok-but-stuck form); the chase's exposure branch keys on it.
    `fallback := false` (the CHASE configuration) suppresses the
    capped ELABORATOR retry after a kernel refusal: inside the chase
    that retry was measured pure waste (a ~50k-heartbeat grind per
    refused deep form, once per materialization/exposure level — the
    22-minute R13 first-attempt pathology); the exposure branch is
    the chase's refusal handler. -/
def kWhnfR (e : Expr) (avatars : Bool := false) (fallback : Bool := true) :
    MetaM (Expr × Bool) := do
  let e ← instantiateMVars e
  if e.hasExprMVar then
    if !avatars then
      return (← whnf e, false)
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
      pure ((← attempt (50000 * 1000) (whnf e)).getD e, false)
    else
      match Lean.Kernel.whnf (← getEnv) lctx e' with
      | .ok r =>
        let mut r := r
        for (fv, mv) in pairs do
          r := r.replace (fun x => if x == fv then some mv else none)
        return (r, false)
      | .error _ =>
        -- kernel refused (recursion pit); capped elaborator fallback —
        -- on a trip the caller gets the term unreduced (sealable).
        -- The refusal is REPORTED (engineRev 5): the chase's exposure
        -- branch keys on it (kernel-error ≠ kernel-stuck).
        if fallback then
          pure ((← attempt (50000 * 1000) (whnf e)).getD e, true)
        else
          pure (e, true)
  else do
    match Lean.Kernel.whnf (← getEnv) (← getLCtx) e with
    | .ok e' =>
      return (e', false)
    | .error _ =>
      if fallback then
        pure ((← attempt (50000 * 1000) (whnf e)).getD e, true)
      else
        pure (e, true)

/-- `kWhnf` — the classic entry (kernel-refusal signal dropped; every
    pre-rev-5 caller unchanged). -/
def kWhnf (e : Expr) (avatars : Bool := false) : MetaM Expr :=
  (·.1) <$> kWhnfR e avatars

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
        let e' := (← attempt (50000 * 1000) (whnf e)).getD e
        return (if e'.approxDepth ≤ e.approxDepth then e' else e)
      if scalarTypeHeads.contains tn then
        return (← withoutCanUnfoldPred (evalScalar scalarTypeHeads 12 e))
    -- (b) state-atom head opacity
    if let .const fn _ := e.getAppFn then
      if atoms.contains fn then return e
    -- CAPPED (arc-11 S2 stuck-round root cause): the elaborator whnf
    -- on a deep non-ctor subterm (measured: the census-R65 step's
    -- `apply_ctx` arena redex) trips the ambient window and ABORTS
    -- the whole fired candidate. A tripped whnf now falls back to
    -- ride-as-delivered (the give-up-keeps-compact-spelling
    -- discipline) — the next round's KERNEL discovery reduces
    -- through it heartbeat-free.
    let e' := (← attempt (50000 * 1000) (whnf e)).getD e
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
        -- CAPPED WHOLE (arc-11 S2 stuck-round root cause): the state
        -- normalizer's recursion carries uncapped elaborator
        -- inferType/whnf steps; on pathological states (the census
        -- R65 `apply_ctx`-arena post-state) it burns the candidate's
        -- window. A tripped normalization now RIDES THE RAW STATE
        -- (give-up-keeps-compact-spelling; the next round's KERNEL
        -- discovery computes through it heartbeat-free).
        let st'? ← tryCatchRuntimeEx
          (attempt (150000 * 1000) (normStateV2 cfg.atoms cfg.depth args[i]!))
          (fun _ => pure none)
        let some st' := st'? | return e
        if cfg.sealStates then
          -- Per-stage emitter (D3, landed): emit the normalized state
          -- as an auxiliary DEFINITION and continue with the constant
          -- — the T4 named-state structure (default in the sealing
          -- lane since arc-11 S1). CAPPED: a tripped seal rides the
          -- normalized state unsealed.
          let sealed? ← tryCatchRuntimeEx
            (attempt (100000 * 1000) (do
              let stTy ← inferType st'
              mkAuxDefinition
                ((← mkFreshUserName `walkSt).appendAfter "_aux") stTy st'
                (compile := false)))
            (fun _ => pure none)
          let some stConst := sealed?
            | return mkAppN e.getAppFn (args.set! i st')
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

/-- Unfold registered SEAL constants at the head (bounded delta +
    beta) until a non-seal head shows — computed values must expose
    their constructor to the ctor-pattern unification (arc-11 S2:
    a seal-headed value silently defeats `Result (Defined ?th', ?rs')`
    assignment). -/
def unsealHead (e : Expr) : MetaM Expr := do
  let mut e := e
  for _ in [0:8] do
    match e.getAppFn.constName? with
    | some n =>
      if (← isSealedAuxName n) then
        match ((← getEnv).find? n).bind (·.value?) with
        | some v => e := v.beta e.getAppArgs
        | none => return e
      else return e
    | none => return e
  return e

/-- Bounded kernel-side structural DIFF (TRACE LANES ONLY — the
    R-S2-3 register item: walk_diag-class dumps folded into the
    committed debug surface; arc-15 T5 resumption). Descends where
    `Kernel.isDefEq` says FALSE and both sides expose the same head
    after kernel whnf, printing the first differing LEAVES with their
    argument paths. Pure instrument: no proof surface, no behavioral
    effect on any walk (only reachable under `trace`). -/
partial def kDiffTrace (env : Environment) (lctx : LocalContext)
    (budget : IO.Ref Nat) (d : Nat) (path : String) (l r : Expr) :
    MetaM Unit := do
  if (← budget.get) == 0 then return
  match Lean.Kernel.isDefEq env lctx l r with
  | .ok true => return
  | .error _ =>
    budget.modify (· - 1)
    dbg_trace "kdiff {path}: KERNEL-ERR {l.getAppFn} vs {r.getAppFn}"
  | .ok false =>
    let l' := match Lean.Kernel.whnf env lctx l with | .ok x => x | _ => l
    let r' := match Lean.Kernel.whnf env lctx r with | .ok x => x | _ => r
    if d == 0 then
      budget.modify (· - 1)
      dbg_trace "kdiff {path}: DEPTH-CAP {l'.getAppFn} vs {r'.getAppFn}"
      return
    if Expr.equal l'.getAppFn r'.getAppFn
        && l'.getAppArgs.size == r'.getAppArgs.size
        && l'.getAppArgs.size > 0 then
      for i in [0:l'.getAppArgs.size] do
        kDiffTrace env lctx budget (d-1) s!"{path}.{i}"
          l'.getAppArgs[i]! r'.getAppArgs[i]!
    else if l'.isLambda && r'.isLambda then
      -- domains first: a non-defeq binder DOMAIN is its own leaf (the
      -- type-index divergence case — e.g. TreeMap's cmp index)
      let domOk := match Lean.Kernel.isDefEq env lctx
          l'.bindingDomain! r'.bindingDomain! with
        | .ok true => true | _ => false
      if !domOk then
        budget.modify (· - 1)
        dbg_trace "kdiff {path}: DOMAIN-LEAF\n  L: {((← withOptions (fun o => o.setBool `pp.explicit true) (ppExpr l'.bindingDomain!)).pretty 140).take 2000}\n  R: {((← withOptions (fun o => o.setBool `pp.explicit true) (ppExpr r'.bindingDomain!)).pretty 140).take 2000}"
        return
      -- descend under the binder with a shared fresh local (diff
      -- localization inside closures — the R-S2-1 surface)
      let fid ← mkFreshFVarId
      let lctx' := lctx.mkLocalDecl fid l'.bindingName! l'.bindingDomain!
      kDiffTrace env lctx' budget (d-1) s!"{path}.λ"
        (l'.bindingBody!.instantiate1 (mkFVar fid))
        (r'.bindingBody!.instantiate1 (mkFVar fid))
    else
      budget.modify (· - 1)
      dbg_trace "kdiff {path}: LEAF\n  L: {((← withOptions (fun o => o.setBool `pp.explicit true) (ppExpr l')).pretty 140).take 2000}\n  R: {((← withOptions (fun o => o.setBool `pp.explicit true) (ppExpr r')).pretty 140).take 2000}"

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
      -- spellings like `maxIval`). CAPPED (engineRev 5): a deep-state
      -- P sends the uncapped elaborator defeq into a maxRecDepth trip
      -- (measured at the R13 leaf, seal-r11) — `attempt` turns both
      -- budget and recursion-depth trips into misses.
      let probe (a b : Expr) : MetaM Bool := do
        let r ← attempt (20000 * 1000) (do
          let ok ← observing? (do unless (← isDefEq a b) do failure)
          pure ok.isSome)
        pure (r.getD false)
      if (← probe dty P) then
        return some (dec, decl.toExpr, true)
      if dty.isAppOfArity ``Not 1 then
        if (← probe dty.appArg! P) then
          return some (dec, decl.toExpr, false)
  return none

/-! ## Seal-through-the-chase (engineRev 5, arc/t5-seal — the R13
    wall kill; design: the arc-15 resumption record §5 + the stepper
    note's seals section). The kernel's recursion guard refuses a
    MONOLITHIC whnf of R13-class evals (deep major-premise chains)
    that the elaborator reduces fine; the chase therefore (a) EXPOSES
    a kernel-refused head (one delta+beta + whnfCore — no deep
    reduction) so the (b) descent can decompose the chain into
    per-position obligations, and (b) NAMES intermediate materialized
    forms past `chaseSealDepth` as CHECKPOINT SEALS (ordinary aux
    definitions) so every certificate statement stays a shallow
    reference. Zero new axioms; every link is an ordinary
    kernel-checked declaration; compositions cross seal constants by
    one-delta defeq at the `Eq.trans` points (no deep statements are
    ever minted). Obligation COUNT is the deliberate trade for
    obligation DEPTH (ledgered per chase). -/

/-- Unfold the head constant one delta+beta step (syntactic — no
    reduction machinery), then capped `whnfCore` (beta/proj/iota, no
    delta) to surface the stuck recursor/matcher. `none` when the head
    is not an unfoldable definition. -/
def exposeStuck (e : Expr) : MetaM (Option Expr) := do
  let f := e.getAppFn
  let some n := f.constName? | return none
  let some (.defnInfo dv) := (← getEnv).find? n | return none
  let body := dv.value.instantiateLevelParams dv.levelParams f.constLevels!
  let e1 := body.beta e.getAppArgs
  let e2 ← tryCatchRuntimeEx
    (attempt (50000 * 1000) (whnfCore e1) <&> (·.getD e1))
    (fun _ => pure e1)
  return some e2

/-- Mint a CHECKPOINT SEAL for an intermediate chase form: an ordinary
    aux definition (fvar-closed, kernel-checked at `addDecl` like
    every emitter aux). Returns the seal reference (constant applied
    to the closed-over locals) — downstream certificate statements
    reference it instead of inlining the deep form. Capped; `none`
    rides the raw form. -/
def chaseCheckpoint (e : Expr) (trace : Bool := false) :
    MetaM (Option Expr) := do
  if e.hasExprMVar then return none
  let r? ← tryCatchRuntimeEx
    (attempt (100000 * 1000) (do
      let nm := (← mkFreshUserName `chSeal).appendAfter "_aux"
      let r ← mkAuxDefinition nm (← inferType e) e (compile := false)
      pure (some r)))
    (fun _ => pure none)
  match r?.getD none with
  | some r =>
    if let some n := r.getAppFn.constName? then
      registerSealedAux n
      pushEngineEv (.seal { name := n, kind := .chase, depthBefore := e.approxDepth.toNat, depthAfter := r.approxDepth.toNat })
      if trace then
        dbg_trace "kwf: CHECKPOINT {n} (depth {e.approxDepth} → {r.approxDepth})"
    return some r
  | none =>
    if trace then
      dbg_trace "kwf: CHECKPOINT trip (depth {e.approxDepth}) — riding raw"
    return none

/-- Capped `whnfCore` (beta/proj/iota, NO delta): the deep-mode
    head-progress primitive — cheap by construction (no deep
    definitional chains can enter). -/
def whnfCoreCapped (e : Expr) : MetaM Expr := do
  tryCatchRuntimeEx
    (attempt (20000 * 1000) (whnfCore e) <&> (·.getD e))
    (fun _ => pure e)

/-- REAL structural depth (sharing-blind, iterative — trace lanes
    only; `approxDepth` saturates and hides the kernel-guard-relevant
    number). Capped at `cap` to bound the traversal. -/
def realDepth (e : Expr) (cap : Nat := 100000) : Nat := Id.run do
  let mut stack : Array (Expr × Nat) := #[(e, 0)]
  let mut best := 0
  let mut fuel := cap
  while h : stack.size > 0 do
    if fuel == 0 then return best
    fuel := fuel - 1
    let (x, dep) := stack[stack.size - 1]
    stack := stack.pop
    if dep > best then best := dep
    match x with
    | .app f a => stack := stack.push (f, dep+1) |>.push (a, dep+1)
    | .lam _ t b _ => stack := stack.push (t, dep+1) |>.push (b, dep+1)
    | .forallE _ t b _ => stack := stack.push (t, dep+1) |>.push (b, dep+1)
    | .letE _ t v b _ => stack := stack.push (t, dep+1) |>.push (v, dep+1) |>.push (b, dep+1)
    | .mdata _ b => stack := stack.push (b, dep+1)
    | .proj _ _ b => stack := stack.push (b, dep+1)
    | _ => pure ()
  return best

/-- Pure syntactic first-difference walker (trace lanes only): descend
    where both sides share an app head, report the first differing
    leaf paths. No reduction, no kernel. -/
partial def synDiff (budget : IO.Ref Nat) (d : Nat) (path : String)
    (l r : Expr) : MetaM Unit := do
  if (← budget.get) == 0 then return
  if Expr.equal l r then return
  if d == 0 then
    budget.modify (· - 1)
    dbg_trace "syndiff {path}: DEPTH-CAP {l.getAppFn} vs {r.getAppFn}"
    return
  if l.isApp && r.isApp && Expr.equal l.getAppFn r.getAppFn
      && l.getAppArgs.size == r.getAppArgs.size then
    for i in [0:l.getAppArgs.size] do
      synDiff budget (d-1) s!"{path}.{i}" l.getAppArgs[i]! r.getAppArgs[i]!
  else if l.isLambda && r.isLambda then
    synDiff budget (d-1) s!"{path}λt" l.bindingDomain! r.bindingDomain!
    synDiff budget (d-1) s!"{path}λ" l.bindingBody! r.bindingBody!
  else
    budget.modify (· - 1)
    dbg_trace "syndiff {path}: LEAF\n  L({l.ctorName}): {((← ppExpr l).pretty 120).take 300}\n  R({r.ctorName}): {((← ppExpr r).pretty 120).take 300}"

/-- STRICT single iota step (engineRev 5): fire `reduceRecMatcher?`
    ONLY when the recursor major / every matcher discriminant is
    SYNTACTICALLY constructor-headed — then the kernel re-derives the
    step by local iota+beta (shallow). The permissive form was
    measured to fire on meta-derived ctor majors whose kernel
    re-derivation is exactly the deep-recursion pit (seal-r14). -/
def iotaStepStrict (e : Expr) : MetaM (Option Expr) := do
  let f := e.getAppFn
  let some n := f.constName? | return none
  let env ← getEnv
  let args := e.getAppArgs
  let isCtorHeaded : Expr → Bool := fun x =>
    match x.getAppFn.constName? with
    | some cn => ((env.find? cn) matches some (.ctorInfo _))
    | none => false
  match env.find? n with
  | some (.recInfo ri) =>
    if h : ri.getMajorIdx < args.size then
      -- beta-redex majors occur in-situ (measured: the R13 rec-stall
      -- major was `(fun … => Result …) a b …`); pure beta is
      -- kernel-shallow, so expose the ctor first.
      let majorB := args[ri.getMajorIdx].headBeta
      if isCtorHeaded majorB then
        return (← Meta.reduceRecMatcher?
          (mkAppN f (args.set ri.getMajorIdx majorB (by simpa using h)))).map
          (·.headBeta)
      else return none
    else return none
  | _ =>
    if let some mi ← Lean.Meta.getMatcherInfo? n then
      let ds := (Array.range mi.numDiscrs).map (mi.numParams + 1 + ·)
      let mut args' := args
      for i in ds do
        if h : i < args'.size then
          args' := args'.set i args'[i].headBeta (by simpa using h)
      let allCtor := ds.all (fun i =>
        if h : i < args'.size then isCtorHeaded args'[i] else false)
      if allCtor then
        return (← Meta.reduceRecMatcher? (mkAppN f args')).map (·.headBeta)
      else return none
    else return none

/-! ## PROPOSITIONAL IOTA (engineRev 5, the R13 link-cert unlock).

    An INSTANTIATED iota certificate (`x = y` with y one rec/matcher
    step from x) is kernel-REFUSED on eval-scale terms: the kernel's
    lazy-delta prefers the higher-definitional-height head — the
    reduct side — and dives into continuing the whole eval (measured:
    deep-recursion trips on single-step links, seal-r18/r20/r21, with
    real term depth only ~150). The fix is to prove the iota step
    GENERICALLY, once per (head, ctor-vector): the generic equation's
    RHS head is a BOUND ALT/MINOR VARIABLE, so the kernel can only
    unfold the LHS — the check is local by construction. Instantiating
    the lemma at the deep terms is application typechecking — no
    reduction. Lemmas are cached process-globally (they recur across
    every round of the climb). -/

initialize iotaLemmaCache : IO.Ref (Std.HashMap String Name) ← IO.mkRef {}

/-- Build (or fetch) the generic one-step iota lemma for head `fn`
    (recursor / casesOn / matcher) at level instantiation `lvls`, with
    the discriminant/major positions `dPos` specialized to the ctor
    names `ctors`. Returns the lemma name; the lemma's statement is
    `∀ …, fn … (ctorᵢ fields…) … = <whnfCore reduct>` proved by rfl at
    the GENERIC level (small terms — an ordinary kernel-checked
    declaration). -/
def getIotaLemma (fn : Name) (lvls : List Level)
    (dPos : Array Nat) (ctors : Array Name) (trace : Bool) :
    MetaM (Option Name) := do
  let key := s!"{fn}|{lvls}|{dPos}|{ctors}"
  if let some n := (← iotaLemmaCache.get).get? key then
    return some n
  let finish (xs : Array Expr) (argMap : Array Expr)
      (fieldsAll : Array Expr) (fnE : Expr) : MetaM (Option Name) := do
    let lhs := mkAppN fnE argMap
    let rhs := (← whnfCore lhs).headBeta
    if Expr.equal rhs lhs then return none
    let mut binders : Array Expr := #[]
    for i in [0:xs.size] do
      unless dPos.contains i do
        binders := binders.push xs[i]!
    -- field binders depend only on params (earlier kept binders);
    -- mkForallFVars validates the dependency order.
    let allB := binders ++ fieldsAll
    let stmt ← mkForallFVars allB (← mkEq lhs rhs)
    let pf ← mkLambdaFVars allB (← mkEqRefl lhs)
    if stmt.hasExprMVar || stmt.hasFVar then return none
    let nm ← mkFreshUserName `chIota
    let nm := nm.appendAfter "_aux"
    addDecl <| .thmDecl {
      name := nm
      levelParams := (collectLevelParams (collectLevelParams {} stmt) pf).params.toList
      type := stmt, value := pf }
    registerSealedAux nm
    pushEngineEv (.seal { name := nm, kind := .chase })
    if trace then
      dbg_trace "kwf: IOTA-LEMMA minted {nm} for {fn} / {ctors}"
    return some nm
  let rec specialize (xs : Array Expr) (fnE : Expr)
      (pending : List (Nat × Name))
      (argMap : Array Expr) (fieldsAll : Array Expr) :
      MetaM (Option Name) := do
    match pending with
    | [] => finish xs argMap fieldsAll fnE
    | (p, ctorN) :: rest =>
      if hp : p < xs.size then
        let dty ← whnf (← inferType xs[p])
        let .const iName iLvls := dty.getAppFn | return none
        let some (.inductInfo iv) := (← getEnv).find? iName | return none
        let some (.ctorInfo cv) := (← getEnv).find? ctorN | return none
        let params := dty.getAppArgs[:iv.numParams].toArray
        let ctorTy0 ← instantiateForall
          (cv.type.instantiateLevelParams cv.levelParams iLvls) params
        forallTelescope ctorTy0 fun fs _ => do
          let ctorApp := mkAppN (mkAppN (mkConst ctorN iLvls) params) fs
          specialize xs fnE rest (argMap.set! p ctorApp)
            (fieldsAll ++ fs)
      else return none
  let build : MetaM (Option Name) := do
    let fnE := mkConst fn lvls
    let fnTy ← inferType fnE
    forallTelescopeReducing fnTy fun xs _ =>
      specialize xs fnE (dPos.toList.zip ctors.toList) xs #[]
  match ← tryCatchRuntimeEx
      (attempt (100000 * 1000) (try build catch ex => do
        if trace then
          dbg_trace "kwf: iota-lemma build FAILED for {fn}: {(← ex.toMessageData.toString).take 200}"
        pure none))
      (fun _ => pure none) with
  | some (some n) =>
    iotaLemmaCache.modify (·.insert key n)
    return some n
  | _ => return none

/-- Apply the generic iota lemma at a concrete application: unify the
    lemma's LHS pattern with `e` (structural — discr ctor spines match
    our syntactic ctors; everything else binds as plain mvars), return
    `(reduct, proof : e = reduct)`. Over-application is closed by
    `congrFun` (no defeq). -/
def applyIotaLemma (lemma : Name) (e : Expr) (trace : Bool := false) :
    MetaM (Option (Expr × Expr)) := do
  let lemE ← mkConstWithFreshMVarLevels lemma
  let (margs, _, lemTy) ← forallMetaTelescope (← inferType lemE)
  let some (_, lhs, rhs) := lemTy.eq? | return none
  -- split e's args to the lemma-lhs arity
  let lhsArity := lhs.getAppArgs.size
  let eArgs := e.getAppArgs
  if eArgs.size < lhsArity then
    if trace then
      dbg_trace "kwf: iota-apply MISS arity {eArgs.size} < {lhsArity} ({lemma})"
    return none
  let ePre := mkAppN e.getAppFn eArgs[:lhsArity]
  let extra := eArgs[lhsArity:].toArray
  let lhsArgs := lhs.getAppArgs
  let preArgs := ePre.getAppArgs
  unless lhsArgs.size == preArgs.size do return none
  unless (← withReducible <| isDefEq lhs.getAppFn ePre.getAppFn) do
    if trace then
      dbg_trace "kwf: iota-apply MISS head-unify ({lemma})"
    return none
  for i in [0:lhsArgs.size] do
    unless (← withReducible <| isDefEq lhsArgs[i]! preArgs[i]!) do
      if trace then
        dbg_trace "kwf: iota-apply MISS arg {i} ({lemma}):\n  L: {((← ppExpr (← instantiateMVars lhsArgs[i]!)).pretty 110).take 300}\n  R: {((← ppExpr preArgs[i]!).pretty 110).take 300}"
      return none
  let pf0 ← instantiateMVars (mkAppN lemE margs)
  if pf0.hasExprMVar then
    if trace then
      dbg_trace "kwf: iota-apply MISS residual mvars ({lemma})"
    return none
  let rhs' ← instantiateMVars rhs
  let mut pf := pf0
  let mut y := rhs'
  for a in extra do
    pf ← mkCongrFun pf a
    y := mkApp y a
  return some (y.headBeta, pf)

/-- Propositional iota at a concrete application (engineRev 5): find
    the discriminant/major positions, require SYNTACTIC ctor heads
    (after headBeta), fetch/mint the generic lemma, instantiate.
    Returns `(reduct, proof)`; the proof's type is stated at the
    beta-normalized discr spelling (consumers cross the pure-beta gap
    by defeq at their Eq.trans points — shallow, symmetric). -/
def iotaByLemma (e : Expr) (trace : Bool) : MetaM (Option (Expr × Expr)) := do
  let f := e.getAppFn
  let some n := f.constName? | return none
  let env ← getEnv
  let args := e.getAppArgs
  let dPos? ← do
    match env.find? n with
    | some (.recInfo ri) => pure (some #[ri.getMajorIdx])
    | _ =>
      if Lean.isCasesOnRecursor env n then
        match env.find? n.getPrefix with
        | some (.inductInfo iv) =>
          pure (some #[iv.numParams + 1 + iv.numIndices])
        | _ => pure none
      else if let some mi ← Lean.Meta.getMatcherInfo? n then
        pure (some ((Array.range mi.numDiscrs).map (mi.numParams + 1 + ·)))
      else pure none
  let some dPos := dPos? | return none
  let mut args' := args
  let mut ctors : Array Name := #[]
  for p in dPos do
    if h : p < args'.size then
      let b := args'[p].headBeta
      match b.getAppFn.constName? with
      | some cn =>
        if (env.find? cn) matches some (.ctorInfo _) then
          args' := args'.set p b (by simpa using h)
          ctors := ctors.push cn
        else return none
      | none => return none
    else return none
  let e' := mkAppN f args'
  let some lem ← getIotaLemma n f.constLevels! dPos ctors trace
    | return none
  applyIotaLemma lem e' (trace := trace)

/-- Chase memoization entry (engineRev 5): sub-chase results are
    deterministic within one discharge (fixed env/lctx/facts), and the
    descent re-visits identical subterms at every resume — measured
    O(advances²) re-refusals without it. `dTried` guards no-progress
    reuse (a failure at low fuel must not mask a success at high). -/
structure ChaseHit where
  dTried : Nat
  v : Expr
  pf : Expr
  prog : Bool

/-- Per-invocation chase state (engineRev 5): the sub-chase memo plus
    the REFUSED-HEAD set — once one application of a head constant
    kernel-refused (a ~28s guard-trip, measured), further applications
    of the same head skip the kernel attempt and go straight to
    exposure/descent (the eval/bind family heads recur constantly; a
    head that is shallow elsewhere just takes the descent route — no
    power lost, its leaf certificates are still kernel obligations). -/
structure ChaseSt where
  memo : Std.HashMap Expr ChaseHit := {}
  refusedHeads : NameSet := {}

/-- Per-invocation chase cache. NEVER shared across a `restoreState`
    boundary — stored proofs reference auxes created in this
    invocation's env (the kernel re-checks everything at declaration
    end as always). -/
abbrev ChaseCache := IO.Ref ChaseSt

mutual

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
partial def kWhnfWithFacts (d : Nat) (e : Expr)
    (trace : Bool := false) (sealDepth : Nat := 48)
    (deep : Bool := false) (cache : Option ChaseCache := none) :
    MetaM (Expr × Expr × Bool) := do
  -- memoization shell (engineRev 5): the descent re-visits identical
  -- subterms at every materialize/resume; results are deterministic
  -- within one discharge. No-progress reuse is fuel-guarded.
  let eKey ← instantiateMVars e
  if !eKey.hasExprMVar then
    if let some c := cache then
      if let some hit := (← c.get).memo.get? eKey then
        if hit.prog || hit.dTried ≥ d then
          if trace && !hit.prog then
            dbg_trace "kwf: cache-hit NOPROG d={d} (dTried={hit.dTried}) head {eKey.getAppFn}"
          return (hit.v, hit.pf, hit.prog)
  -- PER-LEVEL SETTLED WINDOW (engineRev 5): each chase level runs
  -- against a fresh heartbeat base and settles its consumption back —
  -- the walkLoop per-round accounting pushed into the chase. Every
  -- primitive inside a level is individually capped (whnfCore 20k,
  -- fact scans, exposure), so the total is bounded by
  -- chaseDepth × the per-level caps — a LEDGERED product, no ambient
  -- raise anywhere. (Without this, the R13 exposure cascade died
  -- mid-descent when the enclosing candidate window ran out —
  -- measured, seal-r6.)
  let hb0 ← IO.getNumHeartbeats
  let r ← tryCatchRuntimeEx
    (Core.withCurrHeartbeats
      (kWhnfWithFactsGo d e trace sealDepth deep cache))
    (fun ex => do
      if trace then
        dbg_trace "kwf: RUNTIME-EX[d={d}]: {(← ex.toMessageData.toString).take 200}"
      throw ex)
  IO.setNumHeartbeats hb0
  if !eKey.hasExprMVar then
    if let some c := cache then
      let hit : ChaseHit :=
        { dTried := d, v := r.1, pf := r.2.1, prog := r.2.2 }
      c.modify (fun s => { s with memo := s.memo.insert eKey hit })
  return r

partial def kWhnfWithFactsGo (d : Nat) (e : Expr)
    (trace : Bool) (sealDepth : Nat) (deep : Bool)
    (cache : Option ChaseCache) :
    MetaM (Expr × Expr × Bool) := do
  -- (arc-15 measured-and-reverted: a seal-transparent ENTRY — unseal
  -- then bridge by aux-rfl — dies with `(kernel) deep recursion
  -- detected`: the bridge DECLARATION's statement materializes the
  -- unsealed eval body, and kernel typechecking of that deep term is
  -- the pit. engineRev 5 lands the named fix — SEAL-THROUGH-THE-CHASE:
  -- exposure branch (c) + checkpoint seals at the (b) materialization,
  -- keeping every kernel statement shallow.)
  -- CHASE CONFIGURATION (engineRev 5): kernel-only — a refusal goes
  -- to the exposure branch, never to a wasted elaborator grind. DEEP
  -- MODE: once any enclosing form was kernel-refused, non-leaf forms
  -- are NEVER handed to the kernel whole (a refusal churns ~30s
  -- before the recursion guard trips — measured at R13); whnfCore
  -- gives cheap head progress, the descent/exposure give structure,
  -- and leaf-sized subterms (approxDepth ≤ sealDepth) keep full
  -- kernel treatment — one threshold, one meaning: forms above the
  -- bar are neither inlined in statements nor handed to the kernel
  -- whole.
  if trace then
    dbg_trace "kwf: enter[d={d}] deep={deep} depth={e.approxDepth} head {e.getAppFn}"
  -- deep-mode KERNEL-ATTEMPT bound (engineRev 5): distinct from the
  -- statement bar `sealDepth`. Concrete-but-large leaves (the
  -- conv-chain `valueFromPexpr` evals, depth ~150) REDUCE fine in the
  -- kernel — the pre-R13 rounds ran kernel whnf at this size
  -- routinely; only genuinely bottomless heads refuse, and the
  -- process-global head memo caps each such head at ONE ~20s refusal.
  let leafish := e.approxDepth.toNat ≤ max sealDepth 192
  let headRefused ← do
    match e.getAppFn.constName? with
    | some n => do
      let inLocal ← match cache with
        | some c => pure ((← c.get).refusedHeads.contains n)
        | none => pure false
      if inLocal then pure true
      else if (← refusedHeadsGlobal.get).contains n then pure true
      -- a CHASE-SEAL head in deep mode is definitionally the deep
      -- form we chose not to hand the kernel — never re-attempt it
      -- through the seal (measured: one ~20s refusal per checkpoint,
      -- distinct names defeating the head memo)
      else if deep then isSealedAuxName n
      else pure false
    | _ => pure false
  let tkw0 ← IO.monoMsNow
  let mut kernelTried := false
  -- PROPOSITIONAL-IOTA proof for the entry advance, when that lane
  -- produced it (engineRev 5): the certificate is a generic-lemma
  -- instantiation — no whole-term defeq link is minted.
  let mut lemPf : Option Expr := none
  -- lambda-headed app = beta-redex whose kernel whnf CONTINUES into
  -- the deep eval — always refuses here, and a lambda head cannot be
  -- head-memoized; never hand it to the kernel in deep mode.
  let headIsLam := e.getAppFn.isLambda
  let (e1, kRefused) ←
    if (deep && (!leafish || headIsLam)) || headRefused then do
      -- (1) propositional iota first (rec/casesOn/matcher with
      -- syntactic ctor discrs — the R13 link-cert unlock)
      match ← tryCatchRuntimeEx
          (attempt (50000 * 1000) (iotaByLemma e trace))
          (fun _ => pure none) with
      | some (some (y, pf)) =>
        if trace then
          dbg_trace "kwf: iota-lemma[d={d}] {e.getAppFn} → {y.getAppFn}"
        lemPf := some pf
        pure (y, true)
      | _ =>
        -- (2) whnfCore head progress (beta/proj; its defeq link is
        -- robust-guarded below); PURE headBeta as the unconditional
        -- last resort — whnfCoreCapped was measured silently no-oping
        -- on large beta-redexes (a caught runtime trip), and headBeta
        -- is syntactic (cannot fail; its link is a shallow beta defeq)
        let e' ← whnfCoreCapped e
        let e' := if Expr.equal e' e && e.getAppFn.isLambda && e.isApp
          then e.headBeta else e'
        pure (e', true)
    else do
      kernelTried := true
      let (r, ref) ← kWhnfR e (avatars := true) (fallback := false)
      if ref && Expr.equal r e then
        -- refused leafish form: the iota-lemma lane FIRST (a fresh
        -- refusal must not ride unreduced into the memo cache — the
        -- post-memo retry would hit the poisoned no-progress entry;
        -- measured, seal-r28), then the cheap whnfCore fallback.
        match ← tryCatchRuntimeEx
            (attempt (50000 * 1000) (iotaByLemma e trace))
            (fun _ => pure none) with
        | some (some (y, pf)) =>
          if trace then
            dbg_trace "kwf: iota-lemma[d={d}] (post-refusal) {e.getAppFn} → {y.getAppFn}"
          lemPf := some pf
          pure (y, true)
        | _ =>
          let e' ← whnfCoreCapped e
          let e' := if Expr.equal e' e && e.getAppFn.isLambda && e.isApp
            then e.headBeta else e'
          pure (e', true)
      else
        pure (r, ref)
  -- record a fresh kernel refusal's head (once per head,
  -- PROCESS-GLOBAL — the same family heads refuse in every round)
  if kernelTried && kRefused then
    if let some n := e.getAppFn.constName? then
      refusedHeadsGlobal.modify (·.insert n)
      if let some c := cache then
        c.modify (fun s =>
          { s with refusedHeads := s.refusedHeads.insert n })
  if trace then
    let dt := (← IO.monoMsNow) - tkw0
    if dt > 100 then
      dbg_trace "kwf: kWhnfR {dt}ms at d={d} (refused={kRefused}, deep={deep}, head {e.getAppFn})"
  let changed := !(Expr.equal e e1)
  if trace && changed then
    dbg_trace "kwf: entry-advance[d={d}] → head {e1.getAppFn} (depth {e1.approxDepth}); sealing p1"
  -- CERT-REFUSAL ROBUSTNESS (engineRev 5): a p1 certificate the
  -- kernel refuses (deep-recursion class) makes THIS advance
  -- unavailable — ride the unreduced form and let descent/exposure
  -- work instead; never let one refused link kill the whole chase
  -- (seal-r14: a thrown kernel exception unwound 50 productive
  -- levels). SEAL-LINKED STATEMENTS: sides past `sealDepth` are
  -- checkpointed first, so the link declaration's statement stays a
  -- shallow reference (the certificate's TYPE is stated at the seal
  -- references; consumers cross `x = xRef` by one delta at their
  -- Eq.trans points).
  let tryLink (x y : Expr) : MetaM (Option Expr) := do
    tryCatchRuntimeEx
      (try pure (some (← mkAuxRfl x y))
       catch ex => do
         if trace then
           dbg_trace "kwf: link-cert ORD-EX: {(← ex.toMessageData.toString).take 250}"
           dbg_trace "kwf: link-fail realDepth x={realDepth x} y={realDepth y} (approx {x.approxDepth}/{y.approxDepth})"
           -- meta one-step reduct of x, then SYNTACTIC diff vs y (the
           -- drift the kernel's shallow check would have to cross)
           let xw ← whnfCoreCapped x
           let xw := (← tryCatchRuntimeEx
             (attempt (20000*1000) (iotaStepStrict xw))
             (fun _ => pure none)).bind id |>.getD xw
           let b ← IO.mkRef 6
           synDiff b 60 "r" xw y
         pure none)
      (fun ex => do
        if trace then
          dbg_trace "kwf: link-cert RUNTIME-EX: {(← ex.toMessageData.toString).take 250}"
        pure none)
  let mkChaseLink (x y : Expr) : MetaM (Option Expr) := do
    -- RAW FIRST (engineRev 5, measured): a raw statement PRESERVES
    -- POINTER SHARING between the two snapshots, so the kernel's
    -- structural compare only walks the changed path; sealing first
    -- ABSTRACTS the fvars, which copies both bodies wholesale and
    -- sends the compare into full-real-depth recursion (the seal-r18
    -- link refusal). The sealed form remains the fallback for
    -- statements whose typecheck itself is the problem.
    match ← tryLink x y with
    | some p => pure (some p)
    | none =>
      let xR ← do
        if x.approxDepth.toNat > sealDepth && !x.hasExprMVar then
          pure ((← chaseCheckpoint x (trace := trace)).getD x)
        else pure x
      let yR ← do
        if y.approxDepth.toNat > sealDepth && !y.hasExprMVar then
          pure ((← chaseCheckpoint y (trace := trace)).getD y)
        else pure y
      if Expr.equal xR x && Expr.equal yR y then pure none
      else tryLink xR yR
  let (e1, changed, p1) ← do
    if changed then
      match lemPf with
      | some p => pure (e1, true, p)
      | none =>
        match ← mkChaseLink e e1 with
        | some p => pure (e1, true, p)
        | none =>
          if trace then
            dbg_trace "kwf: p1-cert REFUSED[d={d}] — riding unreduced"
          pure (e, false, ← mkEqRefl e)
    else
      pure (e1, false, ← mkEqRefl e)
  if d == 0 then return (e1, p1, changed)
  -- (a0) EQUATION-FACT rewrite at this level (arc-11 S2: the
  -- decide-facts chase GENERALIZED — the §11.2 hypothesis-mediated
  -- env-lookup route, mechanized): a context fact `h : L = v` whose
  -- LHS head matches the stuck form rewrites it to `v` and reduction
  -- resumes. Deterministic first match; the certificate is the fact
  -- itself under a defeq type hint (kernel-checked at declaration
  -- end as always).
  -- engineRev 5: the eq-fact stage is SKIPPED on a kernel-REFUSED
  -- (unreduced deep) form — facts are stated at reduced spellings, so
  -- a match attempt here is a per-fact kernel defeq that re-attempts
  -- the refused deep reduction (measured: the depth-48 R13 attack
  -- ground 38+ CPU-minutes in exactly these scans). The exposure
  -- descent reaches reduced sub-forms where matching is cheap.
  if !kRefused &&
     (!e1.getAppFn.isConst
      || !(match (← getEnv).find? e1.getAppFn.constName! with
           | some (.ctorInfo _) => true | _ => false)) then
    let h1 := e1.getAppFn
    -- a RECURSOR/matcher-stuck form has lost its def-level head
    -- (kernel-whnf unfolded it), so facts stated at def heads
    -- (fmapLookupBy, lookup_env, …) can only match by DEFEQ — relax
    -- the head filter for exactly the stuck classes (capped defeq
    -- decides; misses are cheap).
    let e1Stuck ← do
      match h1.constName? with
      | some n =>
        if (match (← getEnv).find? n with
            | some (.recInfo _) => true | _ => false) then pure true
        else pure (← Lean.Meta.getMatcherInfo? n).isSome
      | none => pure false
    for decl in (← getLCtx) do
      if decl.isImplementationDetail then continue
      let dty ← instantiateMVars decl.type
      if dty.isMVar then continue
      if let some (dα, dlhs, drhs) := dty.eq? then
        if dlhs.getAppFn == h1 || (e1Stuck && dlhs.getAppFn.isConst) then
          -- CLOSED facts decide by KERNEL defeq (heartbeat-free —
          -- the elaborator's capped defeq cannot afford e.g. the
          -- extern-lookup-through-seal reduction, measured); kernel
          -- errors are misses.
          let e1c ← instantiateMVars e1
          let dlhsc ← instantiateMVars dlhs
          let kernelLane := !e1c.hasExprMVar && !dlhsc.hasExprMVar
          let mut kFalse := false
          let hit ← do
            if kernelLane then
              match Lean.Kernel.isDefEq (← getEnv) (← getLCtx)
                  dlhsc e1c with
              | .ok b =>
                kFalse := !b
                pure b
              | .error _ =>
                if trace then
                  dbg_trace "kwf: eq-fact KERNEL-ERR {decl.userName} at d={d}"
                pure false
            else
              (·.isSome) <$> attempt (100000 * 1000) (do
                unless (← isDefEq dlhs e1) do failure)
          if trace && !hit then
            dbg_trace "kwf: eq-fact MISS {decl.userName} at d={d}"
            -- R-S2-3 diff instrument: on a KERNEL-FALSE miss whose
            -- fact reduces to the SAME stuck head as e1, print the
            -- first differing leaves (the R-S2-1 discrimination
            -- surface). Bounded; trace lanes only.
            if kFalse then
              let env ← getEnv
              let lctx ← getLCtx
              let dwh := match Lean.Kernel.whnf env lctx dlhsc with
                | .ok x => x | _ => dlhsc
              if Expr.equal dwh.getAppFn e1c.getAppFn then
                dbg_trace "kwf: KFALSE-DIFF {decl.userName} at d={d} (shared head {e1c.getAppFn}):"
                let budget ← IO.mkRef 12
                kDiffTrace env lctx budget 24 s!"{decl.userName}" dwh e1c
          if hit then
            if trace then dbg_trace "kwf: eq-fact HIT {decl.userName}"
            -- Certificate shape (arc-15 R-S2-1 batch): the spelling
            -- bridge `e1 = dlhs` is its OWN kernel-checked aux
            -- (Kernel.isDefEq just said true), composed with the fact
            -- by Eq.trans — the old defeq TYPE-HINT form rode the
            -- kernel defeq inside the parent proof, which defeated
            -- the elaborator re-check at round-seal time (measured:
            -- `Application type mismatch: hlk513` in the primary
            -- mkAuxTheorem, then level-mvar residue in the raw path).
            let _ := dα
            let pf ← do
              if Expr.equal dlhs e1 then
                pure decl.toExpr
              else do
                let bridge ← mkAuxRfl e1 dlhsc  -- e1 = dlhs (kernel)
                mkEqTrans bridge decl.toExpr    -- e1 = drhs
            let (v, p3, _) ← kWhnfWithFacts (d-1) drhs trace sealDepth (deep || kRefused) cache
            return (v, ← mkEqTrans p1 (← mkEqTrans pf p3), true)
  -- (a) a decide visible at this level with a context fact: rewrite,
  -- materialize its Boolean, resume.
  if trace then dbg_trace "kwf: phase-decide[d={d}]"
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
      let (v, p3, _) ← kWhnfWithFacts (d-1) e2 trace sealDepth (deep || kRefused) cache
      return (v, ← mkEqTrans p1 (← mkEqTrans p2 p3), true)
  -- (b) stuck on a recursor/matcher: chase into the blocking
  -- position(s), advance there, materialize, resume here.
  if trace then dbg_trace "kwf: phase-b[d={d}]"
  let hd := e1.getAppFn
  if hd.isConst && e1.isApp then
    let n := hd.constName!
    let args := e1.getAppArgs
    let positions : Array Nat ← do
      match (← getEnv).find? n with
      | some (.recInfo ri) =>
        -- the TRUE major position (engineRev 5 fix): an over-applied
        -- recursor (motive returning a function — the monadic shapes)
        -- carries trailing args AFTER the major; `args.size - 1`
        -- descended into those (measured: the exceptM.rec R13 stall —
        -- the major was ctor-ready but the chase chased the trailing
        -- state instead, and whnfCore's iota never fired).
        pure #[ri.getMajorIdx]
      | _ =>
        if let some mi ← Lean.Meta.getMatcherInfo? n then
          pure <| (Array.range mi.numDiscrs).map (mi.numParams + 1 + ·)
        else pure #[]
    for i in positions do
      if h : i < args.size then
        let (sv, spf, sChanged) ← kWhnfWithFacts (d-1) args[i] trace sealDepth (deep || kRefused) cache
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
          -- CHECKPOINT (engineRev 5): a materialized parent past the
          -- threshold is NAMED before the chase continues — the seal
          -- constant anchors every downstream certificate statement;
          -- the certificate chain crosses `e2 = seal args` by ONE
          -- delta at the Eq.trans points (kernel-checked there — no
          -- deep statement is minted for the crossing itself).
          let e2c ← do
            if e2.approxDepth.toNat > sealDepth then
              pure ((← chaseCheckpoint e2 (trace := trace)).getD e2)
            else pure e2
          let e2cSkipKernel ← do
            if (deep || kRefused) && e2c.approxDepth.toNat > sealDepth then
              pure true
            else match e2c.getAppFn.constName? with
              | some n => do
                if (← refusedHeadsGlobal.get).contains n then pure true
                else if deep || kRefused then isSealedAuxName n
                else pure false
              | none => pure false
          let (e3, _) ←
            if e2cSkipKernel then
              do pure (← whnfCoreCapped e2c, true)
            else
              kWhnfR e2c (avatars := true) (fallback := false)
          if Expr.equal e3 e2c then
            -- The sub-advance did not unlock the parent in one kernel
            -- whnf (R13 class: the kernel refused, or the next redex
            -- needs a further advance/fact). Re-enter the chase on
            -- the (possibly checkpointed) parent instead of
            -- DISCARDING the progress — the rev-4 `continue` here
            -- silently dropped p2 (a measured R13 progress leak).
            let (v, p4, prog2) ← kWhnfWithFacts (d-1) e2c trace sealDepth (deep || kRefused) cache
            if prog2 && !(Expr.equal v e2c) then
              return (v, ← mkEqTrans p1 (← mkEqTrans p2 p4), true)
            continue
          -- CERT-REFUSAL ROBUSTNESS: a refused p3 link falls back to
          -- the resume recursion on the unadvanced parent.
          let p3? ← mkChaseLink e2c e3
          match p3? with
          | some p3 =>
            let (v, p4, _) ← kWhnfWithFacts (d-1) e3 trace sealDepth (deep || kRefused) cache
            return (v, ← mkEqTrans p1 (← mkEqTrans p2 (← mkEqTrans p3 p4)), true)
          | none =>
            if trace then
              dbg_trace "kwf: p3-cert REFUSED[d={d}] — resume on parent"
            let (v, p4, prog2) ← kWhnfWithFacts (d-1) e2c trace sealDepth (deep || kRefused) cache
            if prog2 && !(Expr.equal v e2c) then
              return (v, ← mkEqTrans p1 (← mkEqTrans p2 p4), true)
            continue
  -- (c) EXPOSURE (engineRev 5, seal-through-the-chase): the KERNEL
  -- REFUSED this form (deep-recursion pit — reducible, not stuck) and
  -- no rec/matcher head is visible to descend into (the R13 shape: a
  -- sealed eval closure applied to the run state). Unfold the shallow
  -- anchor's head one delta+beta step + whnfCore (no delta, capped),
  -- and re-enter the chase on the EXPOSED form: its rec/matcher head
  -- lets the (b) descent decompose the deep major chain into
  -- per-position kernel obligations. The anchor `e1` stays the
  -- certificate chain's reference: `Eq.trans` is built RAW with
  -- b := e1, so the kernel crosses `e1 = exposed` by one delta + the
  -- whnfCore replay (shallow), and no deep statement is minted.
  -- rec-stall diagnostic (trace lane): a rec/matcher head that neither
  -- whnfCore nor the descent advanced — show the major's head.
  if trace && hd.isConst then
    if let some (.recInfo ri) := (← getEnv).find? hd.constName! then
      let args := e1.getAppArgs
      if h : ri.getMajorIdx < args.size then
        dbg_trace "kwf: rec-stall[d={d}] {hd.constName!} args={args.size} majorIdx={ri.getMajorIdx} majorHead={args[ri.getMajorIdx].getAppFn}"
      else
        dbg_trace "kwf: rec-stall[d={d}] {hd.constName!} UNDERAPPLIED args={args.size} majorIdx={ri.getMajorIdx}"
  if kRefused && d > 0 && !e1.hasExprMVar then
    let tex0 ← IO.monoMsNow
    if let some ex ← exposeStuck e1 then
      if !(Expr.equal ex e1) then
        if trace then
          dbg_trace "kwf: EXPOSE[d={d}] {e1.getAppFn} → head {ex.getAppFn} (depth {ex.approxDepth}, {(← IO.monoMsNow) - tex0}ms)"
        let (v, p3, prog) ← kWhnfWithFacts (d-1) ex trace sealDepth (deep || kRefused) cache
        if trace then
          dbg_trace "kwf: EXPOSE-RET[d={d}] prog={prog} vhead={v.getAppFn}"
        if prog && !(Expr.equal v ex) then
          let τ ← inferType e1
          let u ← getLevel τ
          let pf := mkApp6 (mkConst ``Eq.trans [u]) τ e e1 v p1 p3
          return (v, pf, true)
  if trace then
    -- chase exhaustion: show the stuck form so the missing FACT is
    -- readable off the trace (arc-11 S2)
    dbg_trace "kwf: STUCK[d={d}] at head {e1.getAppFn} (args={e1.getAppArgs.size}):\n{((← ppExpr e1).pretty 120).take 900}"
  return (e1, p1, changed)

end

/-- Selection-lane normalizer (arc-11 S2 engine prong, design
    §12.5-1 — the stuck-round root cause): `kWhnf` of a selection
    fact stops at `Option.some payload` in WHNF, leaving the PAYLOAD
    (the selected step) with a non-constructor head; a later advance
    law then finds it by DiscrTree keys (whnfCore exposes the ctor)
    but its full unification must re-reduce the payload with the
    ELABORATOR's whnf in deep context — measured: a 200k-heartbeat
    abort at the census-R65 round. Fix: kernel-whnf the payload too
    (heartbeat-free, kernel-canonical — the aux-rfl certificate
    re-derives it as its own reduct), so planted selections are
    ctor-headed one level down. -/
def kWhnfSelection (lhs : Expr) (avatars : Bool) : MetaM Expr := do
  let e ← kWhnf lhs (avatars := avatars)
  if e.isAppOfArity ``Option.some 2 then
    let p := e.appArg!
    let pIsCtor ← do
      match p.getAppFn.constName? with
      | some n => pure (((← getEnv).find? n).isSome
          && (match (← getEnv).find? n with
              | some (.ctorInfo _) => true | _ => false))
      | none => pure false
    if !pIsCtor then
      let p' ← kWhnf p (avatars := avatars)
      return mkApp e.appFn! p'
  return e

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
              -- SUB-CAPPED (arc-15 T5 resumption, measured at the
              -- symbolic-j R13 wall): an elaborator normCompute on a
              -- fact-needing crossing (stuck on symbolic env lookups)
              -- ground for ~30s producing a fact-blocked blob, and
              -- the candidate window then died in sealing — the
              -- facts route never ran. TIGHT sub-cap: a trip falls to
              -- the heartbeat-free kernel lane and the facts route
              -- under a FRESH window (contFresh) — the intended
              -- give-up-keeps-compact-spelling pipeline.
              tryCatchRuntimeEx
                (attempt (20000 * 1000)
                  (if isSelection then
                    kWhnfSelection lhs (avatars := cfg.sealStates)
                  else normCompute lhs))
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
          -- seal-headed values expose their ctor first (arc-11 S2)
          let v ← if v.getAppFn.isConst then do
              let v' ← unsealHead v
              if !(Expr.equal v' v) then pure (← kWhnf v' (avatars := cfg.sealStates)) else pure v
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
              let ob0 ← sealedAuxCount.get
              -- fresh per-invocation cache (NEVER shared across a
              -- restoreState boundary — cached proofs reference the
              -- auxes created in this invocation's env)
              let chaseC : ChaseCache ← IO.mkRef {}
              let (v0, pf0, prog) ←
                try kWhnfWithFacts cfg.chaseDepth lhs
                      (trace := cfg.trace) (sealDepth := cfg.chaseSealDepth)
                      (cache := some chaseC)
                catch ex =>
                  if cfg.trace then
                    dbg_trace "dh[{fuel}]: kWhnfWithFacts THREW: {(← ex.toMessageData.toString).take 300}"
                  throw ex
              if cfg.trace then
                -- the obligations-per-chase LEDGER (engineRev 5):
                -- count is the deliberate trade for depth
                dbg_trace "kwf: chase ledger — {(← sealedAuxCount.get) - ob0} kernel obligation(s) this chase (prog={prog})"
              if prog && !(Expr.equal v0 v) then
                let v0 ← unsealHead v0
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
        -- SECOND-CHANCE FACTS STAGE (arc-15 T5 resumption, measured
        -- at the symbolic-j R13 wall): the computed-value lane's
        -- window can die inside a long KERNEL whnf (kernel time is
        -- heartbeat-free and uncappable) before the chase-rewrite
        -- facts route ever runs. Re-run the route under its OWN
        -- fresh window; certificates identical to the in-lane route.
        if cfg.norm && cfg.sealFacts && !lhs.isAppOf `RelSem.app
            && !(rhs.isApp && rhs.getAppFn.isConstOf ``Option.some) then
          let st2 ← saveState
          let res2 ← tryCatchRuntimeEx
            (Core.withCurrHeartbeats (attempt cfg.candBudget (do
              let ob0 ← sealedAuxCount.get
              let chaseC : ChaseCache ← IO.mkRef {}
              let (v0, pf0, prog) ←
                try kWhnfWithFacts cfg.chaseDepth lhs
                      (trace := cfg.trace) (sealDepth := cfg.chaseSealDepth)
                      (cache := some chaseC)
                catch ex =>
                  if cfg.trace then
                    dbg_trace "dh[{fuel}]: second-chance kwf THREW: {(← ex.toMessageData.toString).take 300}"
                  throw ex
              if cfg.trace then
                dbg_trace "kwf: chase ledger — {(← sealedAuxCount.get) - ob0} kernel obligation(s) this chase (prog={prog}, second-chance)"
              if !prog then return false
              let v0' ← unsealHead v0
              let v1 ← tryCatchRuntimeEx
                (attempt (20000 * 1000) (normCompute v0')
                  <&> (·.getD v0'))
                (fun _ => pure v0')
              if (← isDefEq rhs v1) then
                let rhs' ← instantiateMVars rhs
                let pfB ← if Expr.equal v0 rhs' then mkEqRefl v0
                          else mkAuxRfl v0 rhs'
                h.assign (← mkEqTrans pf0 pfB)
                trHyp cfg.traceRef (.computed (4 - min 4 fuel)
                  .kWhnfAvatars pfB.getAppFn.constName?)
                if cfg.trace then
                  dbg_trace "dh[{fuel}]: second-chance facts HIT"
                return true
              else
                if cfg.trace then
                  dbg_trace "dh[{fuel}]: second-chance facts: v1 no-match; head {v1.getAppFn}"
                return false)))
            (fun _ => pure none)
          match res2 with
          | some true => return true
          | _ =>
            if cfg.trace then
              dbg_trace "dh[{fuel}]: second-chance none/false"
            restoreState st2
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
      -- SEAL-TRANSPARENT head (arc-11 S2): a crossing whose LHS head
      -- is an emitter-created sealed aux (e.g. a sealed step_m
      -- closure applied to the run state) must still match context
      -- facts stated at the REAL semantic head — unfold registered
      -- seals (registry-driven, bounded) + beta for the head
      -- comparison only; the full defeq crosses the seals by
      -- ordinary delta.
      let lhsEffHead ← do
        let mut e := lhs
        let mut out := lhsHead
        for _ in [0:8] do
          match e.getAppFn.constName? with
          | some n =>
            if (← isSealedAuxName n) then
              match ((← getEnv).find? n).bind (·.value?) with
              | some v => e := v.beta e.getAppArgs
              | none => break
            else
              out := e.getAppFn
              break
          | none =>
            out := e.getAppFn
            break
        pure out
      let lctx ← getLCtx
      for decl in lctx do
        if decl.isImplementationDetail then continue
        let dty ← instantiateMVars decl.type
        if let some (_, dlhs, _) := dty.eq? then
          if dlhs.getAppFn == lhsHead || dlhs.getAppFn == lhsEffHead then
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
  if cfg.trace then
    dbg_trace "dh[{fuel}]: past-assumption ({(← IO.monoMsNow) - ta0}ms)"
    -- arc-11 S2 diagnosis: show the seal-transparent head + a slice
    -- of the unfolded crossing so the missing FACT's statement shape
    -- is readable off the trace
    if let some (_, lhs, _) := ty.eq? then
      if let some n := lhs.getAppFn.constName? then
        if (← isSealedAuxName n) then
          let mut e := lhs
          for _ in [0:8] do
            match e.getAppFn.constName? with
            | some m =>
              if (← isSealedAuxName m) then
                match ((← getEnv).find? m).bind (·.value?) with
                | some v => e := v.beta e.getAppArgs
                | none => break
              else break
            | none => break
          dbg_trace "dh[{fuel}]: eff-head {e.getAppFn} unfolded:\n{((← ppExpr e).pretty 120).take 3500}"
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
      -- arc-11 S2 diagnosis: dump the crossing when an advance-class
      -- law is about to be tried (sealed leaves keep this moderate)
      if !cands.isEmpty && lhs.isAppOf `RelSem.app then
        dbg_trace "dh[{fuel}]: crossing:\n{((← ppExpr lhs).pretty 120).take 6000}"
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
      -- (dbg := cfg.trace): surface attempt-level ABORTS in the trace
      -- lane (arc-11 S2 diagnosis finding: a silent unification abort
      -- inside a candidate attempt is indistinguishable from a
      -- mismatch without it)
      let res ← attempt (dbg := cfg.trace) cfg.candBudget (do
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
        dbg_trace "dh[{fuel}]: STOP no law fired on app-shaped: {lhs.getAppFn}, {(← appEqMatches lhs).map (·.name)}"
        -- arc-11 S2 diagnosis: dump the crossing (sealed leaves keep
        -- this moderate) so aborted unifications are inspectable
        dbg_trace "dh[{fuel}]: STOP crossing:\n{(← ppExpr lhs).pretty 120 |>.take 4000}"
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

/-! ## The §12.3 context query (arc-11 S1 batch 4).
    Evidence: Lithium `FindInContext`/`FindHypEqual` + once-commit;
    Islaris `findR(r)`/`findM(a)` keyed lookup; Diaframe
    required-logical-state rule formats (design §12.3 evidence map). -/

inductive FactQueryResult where
  | hit (fact : Name) | noKey | commitFailed
  deriving BEq, Inhabited

/-- Resolve one declared required-fact for a candidate law whose LHS
    is unified. DETERMINISTIC: local hypotheses newest-first; the
    key argument compares syntactically first, then under a small
    capped defeq; the FIRST key-match COMMITS to one capped full-type
    defeq — success assigns the premise, failure is final for this
    query (no further scanning, no backtracking). -/
def queryRequiredFact (cfg : WalkCfg) (rf : RequiredFact)
    (pm : MVarId) : MetaM FactQueryResult := do
  let ty ← instantiateMVars (← pm.getType)
  let some (_, plhs, _) := ty.eq? | return .noKey
  unless plhs.getAppFn.isConstOf rf.head do return .noKey
  let pargs := plhs.getAppArgs
  unless rf.keyPos < pargs.size do return .noKey
  let key := pargs[rf.keyPos]!
  if key.hasExprMVar then return .noKey
  let decls := (← getLCtx).decls.toArray.filterMap id |>.reverse
  for decl in decls do
    if decl.isImplementationDetail then continue
    let dty ← instantiateMVars decl.type
    let some (_, dlhs, _) := dty.eq? | continue
    unless dlhs.getAppFn.isConstOf rf.head do continue
    let dargs := dlhs.getAppArgs
    unless rf.keyPos < dargs.size do continue
    let dkey := dargs[rf.keyPos]!
    let keyOk ←
      if Expr.equal dkey key then pure true
      else pure ((← attempt (20000 * 1000) (do
        unless (← isDefEq dkey key) do failure)).isSome)
    unless keyOk do continue
    -- first key-match COMMITS
    if (← attempt (100000 * 1000) (do
        unless (← isDefEq dty ty) do failure
        pm.assign decl.toExpr)).isSome then
      trHyp cfg.traceRef (.assumption 0 decl.userName)
      return .hit decl.userName
    else
      return .commitFailed
  return .noKey

/-- Typed residual classification (§12.3) for a failed premise. -/
def classifyResidual (pm : MVarId) : MetaM Residual := do
  let ty ← instantiateMVars (← pm.getType)
  match ty.eq? with
  | some (_, l, r) =>
    if l.isAppOfArity `RelSem.app 7 then
      let cands ← tryCatchRuntimeEx
        (attempt (20000 * 1000) (appEqMatches (← whnfCore l))
          <&> (·.getD #[]))
        (fun _ => pure #[])
      if cands.isEmpty then return .missingLaw
      return .semantic
        (l.getAppArgs[5]!.getAppFn.constName?.getD `RelSem.app)
    else
      return .defeqBridge (l.getAppFn.constName?.getD .anonymous)
        (r.getAppFn.constName?.getD .anonymous)
  | none =>
    let h := ty.getAppFn.constName?.getD .anonymous
    if h == ``LE.le || h == ``LT.lt || h == ``GE.ge || h == ``GT.gt
        || h == ``Ne || h == ``Not then
      return .arithmetic
    return .semantic h

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
  -- replay (batch 3): restrict to the recorded law — choice removed,
  -- checking identical.
  let cands : Array AppEqLaw := match cfg.replayOnly with
    | some n => cands.filter (fun l => l.name == n)
    | none => cands
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
      -- §12.3 CONTEXT QUERIES: declared required-fact premises run
      -- BEFORE mechanical discharge — gating facts (`fact!`) decide
      -- applicability; soft facts (`fact`) pre-discharge and fall
      -- through to the normal lanes on a miss.
      for rf in law.facts do
        if h : rf.idx < args.size then
          let a := args[rf.idx]
          if a.isMVar && !(← a.mvarId!.isAssigned) then
            match ← queryRequiredFact cfg rf a.mvarId! with
            | .hit _ => pure ()
            | .commitFailed =>
              if rf.gate then
                fateCell.set (some (.hypFailed rf.idx
                  (some (.defeqBridge rf.head rf.head))))
                return none
            | .noKey =>
              if rf.gate then
                fateCell.set (some (.hypFailed rf.idx
                  (some (.missingFact rf.head))))
                return none
      -- side hypotheses
      let mut ok := true
      let mut hidx := 0
      for a in args do
        if a.isMVar then
         if !(← a.mvarId!.isAssigned) then
          if (← isProp (← inferType a)) then
            unless (← Core.withCurrHeartbeats (dischargeHyp cfg 4 a.mvarId!)) do
              let rcls ← observing? (classifyResidual a.mvarId!)
              fateCell.set (some (.hypFailed hidx rcls))
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
      if cfg.trace then dbg_trace "walkOnce {law.name}: hyps ok"
      let proof ← Core.withCurrHeartbeats (instantiateMVars (mkAppN lemExpr args))
      if proof.hasExprMVar then
        fateCell.set (some .residualMvars)
        return none
      if cfg.trace then dbg_trace "walkOnce {law.name}: proof assembled"
      let lemRhs ← instantiateMVars lemRhs
      -- terminal: the law's RHS meets the goal's RHS directly.
      -- CAPPED (arc-11 S2 stuck-round root cause, measured at census
      -- R65): as the mid-iteration state approaches the target
      -- family, a NEGATIVE deep defeq here burns the whole window —
      -- a terminal that cannot be decided fast is NOT terminal (the
      -- op pre-match discipline); state restored on the miss.
      let st0 ← saveState
      let isTerminal := (← attempt (20000 * 1000)
        (withReducible <| isDefEq lemRhs rhs)).getD false
      unless isTerminal do restoreState st0
      if isTerminal then
        -- PREVIEW (§12.2): never assign the goal — the walk reports
        -- the terminal without closing anything.
        unless cfg.preview do
          goal.assign (← mkEqTrans proof (← mkEqRefl rhs))
        return some (law.name, none)
      -- chain: Eq.trans into a continuation goal. Under v2 the
      -- continuation's LHS state is replaced by its normalized
      -- (defeq) image; in the PER-STAGE lane (D3) the raw↔normalized
      -- bridge is proven field-wise (mkStateBridge — one aux per
      -- differing leaf) instead of being left to the trans
      -- unification as one monolithic kernel defeq.
      let lemRhsN ← normAppState cfg lemRhs
      if cfg.trace then dbg_trace "walkOnce {law.name}: state normalized"
      let proof ← do
        -- PREVIEW: skip the certificate assembly (bridge/round seal)
        -- — the continuation value lemRhsN is all progression needs.
        if !cfg.preview && cfg.sealStates && !(Expr.equal lemRhs lemRhsN) then
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
      if cfg.trace then dbg_trace "walkOnce {law.name}: bridge done"
      let proof ← if !cfg.preview && cfg.sealRounds then do
          -- ROBUST round seal (arc-11 S2): mkAuxTheorem capped with
          -- the raw-addDecl kernel-only fallback (the measured
          -- census-R65 trip after normalization/bridge were cleared).
          let pty ← instantiateMVars (← inferType proof)
          mkAuxThmRobust pty proof
        else pure proof
      if cfg.trace then dbg_trace "walkOnce {law.name}: round sealed"
      let restTy ← mkEq lemRhsN rhs
      let rest ← mkFreshExprMVar restTy (userName := `walk)
      -- PREVIEW: the continuation mvar drives the next round's
      -- discovery but is NEVER connected to the user's goal.
      unless cfg.preview do
        goal.assign (← mkEqTrans proof rest)
      return some (law.name, some rest.mvarId!))
    match res with
    | some (some r) =>
      -- §12.3 DYNAMIC AMBIGUITY: a SAME-priority sibling that also
      -- passes the applicability gate (LHS unification + gating
      -- facts) is an ERROR, never a silent first-wins. (Same-key
      -- same-prio pairs are already excluded at registration.)
      for law' in cands do
        if law'.name != law.name && law'.prio == law.prio then
          let st' ← saveState
          let amb ← attempt (20000 * 1000) (do
            let lemExpr' ← mkConstWithFreshMVarLevels law'.name
            let (args', _, lemTy') ← forallMetaTelescopeReducing
              (← inferType lemExpr')
            let some (_, lemLhs', _) := lemTy'.eq? | failure
            unless (← isDefEq lemLhs' lhs) do failure
            for rf in law'.facts do
              if rf.gate then
                if h : rf.idx < args'.size then
                  let a := args'[rf.idx]
                  if a.isMVar then
                    let qr ← queryRequiredFact cfg rf a.mvarId!
                    unless (match qr with | .hit _ => true | _ => false) do
                      failure)
          restoreState st'
          if amb.isSome then
            throwError "app_walk: AMBIGUOUS round — laws {law.name} \
              and {law'.name} both apply at priority {law.prio} \
              (§12.3 ambiguity-is-error; resolve with explicit \
              priorities)"
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
          -- PREVIEW: report closability, never close (round 0's `g`
          -- IS the user's goal).
          unless cfg.preview do
            g.assign (← mkEqRefl l))
      IO.setNumHeartbeats hb1
      trCloseRound cfg.traceRef idx none ledger
      if rflRes.isSome then
        trOutcome cfg.traceRef .closedRfl
        if verbose then logInfo m!"app_walk: closed by rfl"
        return none
      -- §12.3: classify the stuck goal (missing law vs semantic).
      let rcls ← g.withContext do
        let tgt := (← instantiateMVars (← g.getType)).consumeMData
        match tgt.eq? with
        | some (_, l, _) =>
          if l.isAppOfArity `RelSem.app 7 then
            let cands ← tryCatchRuntimeEx
              (attempt (20000 * 1000)
                (appEqMatches (← whnfCore l)) <&> (·.getD #[]))
              (fun _ => pure #[])
            if cands.isEmpty then pure (some Residual.missingLaw)
            else pure (some (Residual.semantic
              (l.getAppArgs[5]!.getAppFn.constName?.getD `RelSem.app)))
          else pure none
        | none => pure none
      trOutcome cfg.traceRef (.stuck rcls)
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
    formerly the `app_walk_norm!` surface, now retired).

    `app_walk_norm n nostates` — state SEALING off (facts/rounds
    still sealed): the measured entry-block configuration (batch-3
    archaeology: the sealStates lane stops early at the entry store-i
    round — S2 register item — while the nostates lane walks 21/21
    and leaves a boundary the kernel closes stably; on the iteration
    corpus the sealed lane reaches further, 44 vs 38 of 79, so the
    SEALED default stands per F12-4). -/
syntax (name := appWalkNorm) "app_walk_norm" (ppSpace num)?
  (ppSpace &"nostates")? : tactic

elab_rules : tactic
  | `(tactic| app_walk_norm $[$n:num]? $[nostates%$ns]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let cfg := normWalkCfg atoms
    let cfg := if ns.isSome then { cfg with sealStates := false } else cfg
    match ← walkLoop cfg goal budget false with
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

/-- `app_walk_preview` / `app_walk_preview n` — PREVIEW mode (design
    §12.2, survey rank 1): run discovery + record the structured
    trace, close NOTHING, then FAIL.

    NEVER CI-AUTHORITATIVE, by three independent layers:
    1. structural — `WalkCfg.preview` guards every `goal.assign`/
       `g.assign` site in the walk (audit scope: `goal.assign` is
       unreachable under `preview := true`), so no goal metavariable
       is ever assigned;
    2. the tactic ALWAYS FAILS (`throwError` below) — a proof
       containing it cannot elaborate (negative-tested: AppWalkTest
       E9 pins the failure on the very goal E1 closes);
    3. the surface is grep-banned in committed relsem proofs
       (scripts/check_proof_size.sh).

    The error message carries a deterministic summary (counts only,
    no timings — `#guard_msgs`-stable); the full trace (with ledger
    rows) is printed via `logInfo` only under `app_walk_norm?` or a
    programmatic `traceRef` consumer (the batch-3 bench). -/
syntax (name := appWalkPreview) "app_walk_preview" (ppSpace num)? : tactic

elab_rules : tactic
  | `(tactic| app_walk_preview $[$n:num]?) => do
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let tr ← IO.mkRef ({} : TraceSt)
    let cfg : WalkCfg :=
      { normWalkCfg atoms with preview := true, traceRef := some tr }
    let _ ← walkLoop cfg goal budget false
    let t := (← tr.get).toTrace
    let fired : Nat := t.rounds.foldl
      (fun (k : Nat) r => if r.fired.isSome then k + 1 else k) 0
    let outc := match t.outcome with
      | some o => o.tag
      | none => "(open)"
    throwError "app_walk_preview: preview only — goal intentionally \
      left unsolved ({t.rounds.size} round(s) previewed, {fired} \
      fired, outcome {outc})"

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

/-! ## Record → checked replay (arc-11 S1 batch 3, design §12.2).
    The trace is UNTRUSTED DATA: replay removes CHOICE (the law
    search), never CHECKING — every unification, discharge, and
    kernel obligation re-runs; the outputs are ordinary kernel-checked
    declarations indistinguishable from a discovery walk's. -/

/-- The kit component of the stability fingerprint: hash over the
    name-sorted `@[app_eq]` registry (name, key path, priority,
    statement hash). Freshness UX, never a trust surface. -/
def kitFingerprint : MetaM UInt64 := do
  let laws ← appEqAll
  let env ← getEnv
  let mut h : UInt64 := 7
  for l in laws do
    h := mixHash h l.name.hash
    h := mixHash h (UInt64.ofNat l.prio)
    for k in l.keys do
      h := mixHash h (hash k)
    if let some ci := env.find? l.name then
      h := mixHash h ci.type.hash
  return h

/-- Goal-statement key: hash of the pretty-printed goal (stable
    across elaborations — raw `Expr.hash` is fvar-id-sensitive). -/
def goalKey (g : MVarId) : MetaM UInt64 :=
  g.withContext do
    return (toString (← ppExpr (← instantiateMVars (← g.getType)))).hash

/-- `app_walk_rec name` / `app_walk_rec name n` — a NORMAL sealed
    walk (full closing power, ordinary certificates) that additionally
    RECORDS its trace under `name` in the persistent store, stamped
    with the stability fingerprint. Committed-legal: recording is the
    real walk plus data. -/
syntax (name := appWalkRec) "app_walk_rec" ident (ppSpace num)? : tactic

/-- Record/replay SEQUENCING CONTRACT (batch 3, recorded): under
    parallel proof elaboration (`Elab.async`, the default), a
    tactic-time env-extension write is not reliably visible to other
    declarations, and concurrent walks share the process-global
    heartbeat ledger (nondeterministic stop points). Recording and
    replaying declarations must therefore sit under
    `set_option Elab.async false` (file- or declaration-scoped); the
    elabs below warn when the option is on. This is a determinism/
    visibility contract, never a soundness surface (everything is
    kernel-checked either way). -/
def warnIfAsync (tac : String) : TacticM Unit := do
  if (← getOptions).get `Elab.async true then
    logWarning m!"{tac}: Elab.async is ON — cross-declaration trace \
      visibility and walk determinism are not guaranteed; wrap the \
      recording/replaying declarations in `set_option Elab.async \
      false`"

elab_rules : tactic
  | `(tactic| app_walk_rec $id:ident $[$n:num]?) => do
    warnIfAsync "app_walk_rec"
    let budget := match n with | some n => n.getNat | none => 64
    let goal ← getMainGoal
    let atoms ← stateAtoms
    let tr ← IO.mkRef ({} : TraceSt)
    let cfg : WalkCfg := { normWalkCfg atoms with traceRef := some tr }
    let gk ← goalKey goal
    let res ← walkLoop cfg goal budget false
    let fp : Fingerprint :=
      { kit := ← kitFingerprint, engine := engineRev, goal := gk }
    storeWalkTrace id.getId { (← tr.get).toTrace with fp := some fp }
    match res with
    | some g => replaceMainGoal [g]
    | none => replaceMainGoal []

/-- `app_walk_replay name` — CHECKED REPLAY (§12.2): fetch the stored
    trace; REFUSE loudly on fingerprint ABSENCE (audit A-F4) or
    staleness (engineRev / kit registry / goal statement); then walk
    exactly the recorded law
    sequence (choice removed, checking identical). Divergence = a
    loud error naming the step — NO fallback to search. Closure
    tactics (e.g. `app_defeq`) stay explicit in the proof text. -/
syntax (name := appWalkReplay) "app_walk_replay" ident : tactic

elab_rules : tactic
  | `(tactic| app_walk_replay $id:ident) => do
    warnIfAsync "app_walk_replay"
    let goal ← getMainGoal
    let some t ← (findWalkTrace id.getId : TacticM _)
      | throwError "app_walk_replay: no stored trace named '{id.getId}'"
    -- Arc-11 audit A-F4: a trace with NO fingerprint (predating the
    -- stamp, or hand-built) must REFUSE loudly — never silently skip
    -- the staleness checks.
    let some fp := t.fp
      | throwError "app_walk_replay: trace '{id.getId}' has NO \
          fingerprint — refusing to replay an unstamped trace; \
          re-record with app_walk_rec"
    unless fp.engine == engineRev do
      throwError "app_walk_replay: STALE trace '{id.getId}' — \
        engineRev {fp.engine} ≠ current {engineRev}; re-record"
    unless fp.kit == (← kitFingerprint) do
      throwError "app_walk_replay: STALE trace '{id.getId}' — the \
        @[app_eq] registry changed since recording; re-record"
    unless fp.goal == (← goalKey goal) do
      throwError "app_walk_replay: trace '{id.getId}' was recorded \
        for a DIFFERENT goal statement; re-record"
    let atoms ← stateAtoms
    let mut g := goal
    let mut i : Nat := 0
    for r in t.rounds do
      match r.fired with
      | none => break  -- the recorded stuck/boundary round
      | some f =>
        let cfg : WalkCfg :=
          { normWalkCfg atoms with replayOnly := some f.law }
        let hb0 ← IO.getNumHeartbeats
        let step? ← tryCatchRuntimeEx
          (Core.withCurrHeartbeats (walkOnce cfg g false))
          (fun _ => pure none)
        IO.setNumHeartbeats hb0
        match step? with
        | some (_, some g') => g := g'; i := i + 1
        | some (_, none) => replaceMainGoal []; return
        | none =>
          throwError "app_walk_replay: step {i}: recorded law \
            {f.law} no longer applies — the trace has diverged; \
            re-record"
    if t.outcome == some .closedRfl then
      let hb1 ← IO.getNumHeartbeats
      let rflRes ← attempt candidateBudget (do
          let some (_, l, r) :=
              (← instantiateMVars (← g.getType)).consumeMData.eq?
            | failure
          unless (← isDefEq l r) do failure
          g.assign (← mkEqRefl l))
      IO.setNumHeartbeats hb1
      if rflRes.isSome then replaceMainGoal []; return
    replaceMainGoal [g]

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
