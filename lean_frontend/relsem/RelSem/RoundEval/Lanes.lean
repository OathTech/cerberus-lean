/-
  RelSem.RoundEval.Lanes — arc-18 C1 decomposition (2026-08-25).

  ABSTRACTION: THE MINTER LANES — fact emission (mintEmitSide/
  mintEmit: named ∀-closed kernel-checked facts, self-insertion
  guarded) and the per-shape lanes (Decidable/Bool/Bool-tower,
  env-lookup over Kit/Map's captured-comparator laws, the mem
  read-over-write lane over Kit/Mem's footprint laws), joined by the
  dispatcher mintCmpFact? (the mintHook implementation, loudly
  budget-guarded). Lanes apply REGISTERED laws; anything unminted is
  a fail-closed frontier at the consumer.

  Split from RoundEval.lean; code carried VERBATIM.

  House rules: no sorry, no axioms; meta code only.
-/
import RelSem.RoundEval.Arith
import RelSem.RoundEval.Classify
import RelSem.RoundEval.Mint
import RelSem.Kit.Round

set_option autoImplicit false

namespace RelSem
namespace RoundEval

open Lean Lean.Meta Lean.Elab Lean.Elab.Command
open RelSem.DeriveState (throwFrontier provenanceNote)

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
  -- THE ORIGINAL-SPELLING RULE (arc-18 C3, measured at the T5 body
  -- walk's round-14 guard): the verdict term must be typed at the
  -- ORIGINAL Prop spelling `p0` (what the term's dependent
  -- neighbors quote), not the normalized `p` omega consumed —
  -- substituting an `isTrue p …` into a `Decidable p0` position
  -- mixes defeq-variant spellings inside dependent structure and
  -- the kernel rejects the emitted round. The side fact stays
  -- STATED at `p` (omega's vocabulary); the use site carries a
  -- kernel-deferred cast p ≡ p0.
  if pol then
    let href ← mintEmitSide hp p pf "decidable/isTrue side"
    let href0 ← mkExpectedTypeHint href p0
    mintEmit hp d (mkApp2 (mkConst ``Decidable.isTrue) p0 href0)
      (mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isTrue) p0 href0 d)
      "decidable → isTrue"
  else
    let href ← mintEmitSide hp (mkApp (mkConst ``Not) p) pf
      "decidable/isFalse side"
    let href0 ← mkExpectedTypeHint href
      (mkApp (mkConst ``Not) p0)
    mintEmit hp d (mkApp2 (mkConst ``Decidable.isFalse) p0 href0)
      (mkApp3 (mkConst ``RelSem.RoundEval.dec_eq_isFalse) p0 href0 d)
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

/-- Soft registry query for the minter lanes (arc-18 C1): `none`
    (the lane DECLINES) instead of a frontier — the CONSUMER's
    frontier fires with the term printed if nothing ultimately mints
    (the minter's fail-closed contract, unchanged). Law selection by
    goal-form key; the hardcoded law-name tables are retired. -/
private def queryLaw? (kind : Name) (goal : Expr)
    (variant : Name := .anonymous) : MetaM (Option Name) := do
  try
    -- builder drives opt into the fence-robust fallback (arc-18
    -- C3b — the Core.queryLaw note; measured here: the fenced
    -- `List.contains` keys as a const where the tree stored the
    -- `List.elem`-reduced path, so the kill-skip lane's query missed)
    let l ← RelSem.LawRegistry.queryUnique kind goal variant
      (unifyFallback := ← (builderMode.get : BaseIO _))
    return some l.name
  catch _ => return none

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
    let some law ← queryLaw? `envMap
      (← mkAppMU ``RelSem.Kit.FmapBuilt
        #[mkConst ``RelSem.Kit.symCmpO, m]) (variant := `built)
      | return none
    return some (← mkAppOptMU law
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
  -- EMPTY-map base case (arc-18 C3): the core_extern wrapper at a
  -- freshly-drawn symbol — definitional, applied by registry query
  if m.isAppOf ``Fmap.empty || m.isAppOf ``fmapEmpty then
    let some emptyLaw ← queryLaw? `envMap d (variant := `empty)
      | return false
    let prf ← mkAppOptM emptyLaw #[some dArgs[0]!, some dArgs[1]!, some dArgs[2]!, some key]
    let some (_, _, rhs) := (← inferType prf).eq? | return false
    let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
    mintEmit hp d rhs prf' "env lookup empty"
    return true
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
    let some hitLaw ← queryLaw? `envMap d (variant := `hit)
      | return false
    let some pf ← mkLaw hitLaw hk rhs
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
    | _ => tryOmegaProofNumLit neStmt)
  let some pfNe := pfNe? | (do
    trace[RelSem.roundEval] "env lane: apartness unprovable: {neStmt}"
    return false)
  let hrefNe ← mintEmitSide hp neStmt pfNe "env-key apartness"
  let hk ← mkAppOptMU ``RelSem.RoundEval.symCmpO_ne_num
    #[some dg1, some dg2, some n1, some n2, some sd1, some sd2,
      some (← mkEqRefl dg1), some hrefNe]
  let rhs := mkAppN d.getAppFn (dArgs.set! 4 inner)
  let some skipLaw ← queryLaw? `envMap d (variant := `skip)
    | return false
  let some pf ← mkLaw skipLaw hk rhs
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
    -- REGISTRY DISPATCH (arc-18 C1): rebuild the accessor-application
    -- goal form (STRUCTURE METADATA, not a law table — the raw-proj
    -- spelling keys differently from the laws' accessor-app LHS) and
    -- query the memRW lane.
    let fields := getStructureFields (← getEnv) ``CerbMem.MemState
    let some field := fields[idx]? | return false
    let accApp ← mkAppMU (``CerbMem.MemState ++ field) #[b]
    let law? ← queryLaw? `memRW accApp
    if law?.isNone then
      trace[RelSem.roundEval] "mem lane: no registered projection law \
        for field {field} over writeBytesTo"
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
  -- projection lane: query the memRW registry at d's OWN goal form
  -- (registry dispatch, arc-18 C1 — the accessor-name table is
  -- retired; the four writeBytesTo projection laws key on their
  -- accessor heads, so d matches exactly its law or nothing)
  if args.size == 1 && args[0]!.isAppOfArity ``CerbMem.writeBytesTo 3 then
    if let some law ← queryLaw? `memRW d then
      let wa := args[0]!.getAppArgs
      let rhs := mkApp d.getAppFn wa[0]!
      let pf ← mkAppOptMU law
        #[some wa[0]!, some wa[1]!, some wa[2]!]
      mintEmit hp d rhs pf "mem write projection"
      return true
    -- fall through: no registered projection law (e.g. bytemap)
    trace[RelSem.roundEval] "mem lane: accessor-over-write {c}: no \
      registered projection law (query miss)"
  -- FENCED-ACCESSOR IOTA (arc-17 S3): a pack-hypothesis head fence
  -- freezes the accessor CONST, so `accessor {mk-record}` cannot
  -- delta-iota even though the reduction is fence-irrelevant. Mint
  -- the field value with a kernel-deferred refl bridge. (arc-18 C1:
  -- the field-index table is retired for PROJECTION METADATA —
  -- generic over every MemState field, same defeq bridge.)
  if let some pinfo := (← getEnv).getProjectionFnInfo? c then
    unless pinfo.ctorName == ``CerbMem.MemState.mk do return false
    unless args.size == 1 do return false
    let m' := args[0]!
    unless m'.isAppOfArity ``CerbMem.MemState.mk 14 do
      trace[RelSem.roundEval] "mem lane: accessor {c} arg neither \
        writeBytesTo nor mk-record (head {m'.getAppFn}) — declined"
      return false
    let some rhs := m'.getAppArgs[pinfo.numParams + pinfo.i]?
      | return false
    let pf ← mkExpectedTypeHint (← mkEqRefl rhs) (← mkEq d rhs)
    mintEmit hp d rhs pf "fenced-accessor iota"
    return true
  -- READ-OVER-UPDATE pass-throughs at the kill shapes (arc-18 C3b):
  -- get? through a fenced `erase` at ground distinct keys; contains
  -- through a cons at a ground-apart head — registered memRW laws
  -- (the exit walk's post-kill s-load, measured round 37).
  if c == ``Std.TreeMap.get? && args.size ≥ 2 then
    let m' := args[args.size - 2]!
    let k'E := args[args.size - 1]!
    let some k'v ← groundIntLit? k'E | return false
    if m'.isAppOf ``Std.TreeMap.erase then
      let ma := m'.getAppArgs
      if ma.size ≥ 2 then
        let tE := ma[ma.size - 2]!
        let kE := ma[ma.size - 1]!
        let some kv ← groundIntLit? kE | return false
        if kv ≠ k'v then
          let neStmt ← mkAppMU ``Ne #[kE, k'E]
          let some (true, pfNe) ← kernelVerdict neStmt | return false
          let some law ← queryLaw? `memRW d (variant := `eraseNe)
            | return false
          let prf ← mkAppM law #[tE, pfNe]
          let some (_, _, rhs) := (← inferType prf).eq? | return false
          let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
          mintEmit hp d rhs prf' "get? over erase (kill skip)"
          return true
      return false
    if m'.isAppOf ``Std.TreeMap.insert then
      let ma := m'.getAppArgs
      if ma.size ≥ 3 then
        let tE := ma[ma.size - 3]!
        let kE := ma[ma.size - 2]!
        let vE := ma[ma.size - 1]!
        let some kv ← groundIntLit? kE | return false
        if kv == k'v then
          -- HIT: the just-inserted record reads back
          let some law ← queryLaw? `memRW d (variant := `insertEq)
            | return false
          let prf ← mkAppM law #[tE, kE, vE]
          let some (_, _, rhs) := (← inferType prf).eq? | return false
          let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
          mintEmit hp d rhs prf' "get? over insert (hit)"
          return true
        else
          let neStmt ← mkAppMU ``Ne #[kE, k'E]
          let some (true, pfNe) ← kernelVerdict neStmt | return false
          let some law ← queryLaw? `memRW d (variant := `insertNe)
            | return false
          let prf ← mkAppM law #[tE, pfNe, vE]
          let some (_, _, rhs) := (← inferType prf).eq? | return false
          let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
          mintEmit hp d rhs prf' "get? over insert (skip)"
          return true
    return false
  if c == ``List.contains && args.size ≥ 2 then
    let lE := args[args.size - 2]!
    let xE := args[args.size - 1]!
    if lE.isAppOfArity ``List.cons 3 then
      let aE := lE.getAppArgs[1]!
      let tlE := lE.getAppArgs[2]!
      let some av ← groundIntLit? aE | return false
      let some xv ← groundIntLit? xE | return false
      if xv ≠ av then
        let beqStmt ← mkEq (← mkAppM ``BEq.beq #[xE, aE])
          (mkConst ``Bool.false)
        let some (true, pfNe) ← kernelVerdict beqStmt | return false
        let some law ← queryLaw? `memRW d (variant := `containsConsNe)
          | return false
        let prf ← mkAppM law #[tlE, pfNe]
        let some (_, _, rhs) := (← inferType prf).eq? | return false
        let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
        mintEmit hp d rhs prf' "contains over cons (kill skip)"
        return true
    return false
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
    let some law ← queryLaw? `memRW d (variant := `congr) | return false
    let pf ← mkAppOptMU law
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
    let some law ← queryLaw? `memRW d (variant := `hit) | return false
    let pf ← mkAppOptMU law
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
    let some law ← queryLaw? `memRW d (variant := `frame) | return false
    let pf ← mkAppOptMU law
      #[some m, some a, some a', some bs, some nE, some hdisj]
    mintEmit hp d rhs pf "mem read-over-write frame"
    return true
  trace[RelSem.roundEval] "mem lane: OVERLAPPING non-exact read \
    (write [{av}, {av + blen}), read [{av'}, {av' + nv})) — unsupported"
  return false


/-- THE CONV/CATCH ARITHMETIC LANE (arc-18 C3): a stuck
    `mk_conv_int` / `mk_call_catch_exceptional_condition` application
    at signed-int type and symbolic operands rewrites through the
    registered `evalArith` laws (Kit/Eval — the round-35 tower
    cascade of the T5 body walk, resolved as LAWS: the tower's
    semantic content at in-range operands is the identity / the
    guarded sum). Range premises discharge through the verdict
    engine (omega over the pack); law selection by registry query
    (R4). -/
private def mintConvArith (hp : HypPack) (d : Expr) : TermElabM Bool := do
  let .const c _ := d.getAppFn | return false
  let args := d.getAppArgs
  let sigInt := mkApp (mkConst ``integerType.Signed)
    (mkConst ``integerBaseType.Int_)
  let intLit (n : Int) : Expr := toExpr n
  let rangeProofs (v : Expr) : TermElabM (Option (Expr × Expr)) := do
    let p1 ← mkAppM ``LE.le #[intLit (-2147483648), v]
    let p2 ← mkAppM ``LE.le #[v, intLit 2147483647]
    -- omega reads the FOLDED vocabulary (arc-18 C3b, measured: a raw
    -- `Int.ofNat 1` operand from a whnf'd spelling atomizes — the
    -- round-59 i-increment catch); the side fact is stated folded and
    -- the use site carries a kernel-deferred cast to the term
    -- spelling (defeq — the foldArith contract; the mintDecidable
    -- original-spelling recipe)
    let p1F ← foldArith p1
    let p2F ← foldArith p2
    let some (true, pf1) ← propVerdict p1F
      | (do trace[RelSem.roundEval] "convArith: no lo-range verdict for {v}"
            return none)
    let some (true, pf2) ← propVerdict p2F
      | (do trace[RelSem.roundEval] "convArith: no hi-range verdict for {v}"
            return none)
    let h1 ← mintEmitSide hp p1F pf1 "conv-arith range lo"
    let h2 ← mintEmitSide hp p2F pf2 "conv-arith range hi"
    return some (← mkExpectedTypeHint h1 p1, ← mkExpectedTypeHint h2 p2)
  let emitVia (law : Name) (lawArgs : Array Expr) : TermElabM Bool := do
    let prf ← mkAppM law lawArgs
    let some (_, _, rhs) := (← inferType prf).eq? | return false
    if (rhs.find? (· == d)).isSome then return false
    let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
    mintEmit hp d rhs prf' "conv/catch arith law"
    return true
  if c == ``mk_conv_int && args.size == 2 then
    unless args[0]! == sigInt || (← isDefEq args[0]! sigInt) do
      return false
    let ivW ← whnfU args[1]!
    unless ivW.isAppOfArity ``CerbMem.IntegerValue.IV 2 do
      trace[RelSem.roundEval] "convArith: conv operand not IV-headed ({ivW.getAppFn})"
      return false
    unless ivW.appArg!.hasFVar do return false -- ground convs are whnf's job
    let some law ← queryLaw? `evalArith d (variant := `conv)
      | return false
    let some (h1, h2) ← rangeProofs ivW.appArg! | return false
    emitVia law #[ivW.getAppArgs[0]!, ivW.appArg!, h1, h2]
  else if c == ``mk_call_catch_exceptional_condition && args.size == 4 then
    unless args[0]! == sigInt || (← isDefEq args[0]! sigInt) do
      return false
    unless (← whnfU args[1]!).isConstOf ``iop.IOpAdd do return false
    -- pull an operand's value through ONE fenced conv layer (the
    -- Core spelling `catch(conv a, conv b)` — the conv is fenced to
    -- stay law-shaped, so resolve it here by the conv law with a
    -- congr-composed proof)
    let convValue? (arg : Expr) :
        TermElabM (Option (Expr × Expr × Option Expr)) := do
      let w ← whnfU arg
      if w.isAppOfArity ``CerbMem.IntegerValue.IV 2 then
        return some (w.getAppArgs[0]!, w.appArg!, none)
      if w.isAppOfArity ``mk_conv_int 2 then
        let wa := w.getAppArgs
        unless wa[0]! == sigInt || (← isDefEq wa[0]! sigInt) do
          return none
        let ivW ← whnfU wa[1]!
        unless ivW.isAppOfArity ``CerbMem.IntegerValue.IV 2 do
          return none
        let some cLaw ← queryLaw? `evalArith w (variant := `conv)
          | return none
        let some (h1, h2) ← rangeProofs ivW.appArg! | return none
        let prf ← mkAppM cLaw
          #[ivW.getAppArgs[0]!, ivW.appArg!, h1, h2]
        let some (_, _, rhs) := (← inferType prf).eq? | return none
        let prf' ← mkExpectedTypeHint prf (← mkEq arg rhs)
        return some (rhs.getAppArgs[0]!, rhs.appArg!, some prf')
      trace[RelSem.roundEval] "convArith: catch operand not resolvable ({w.getAppFn})"
      return none
    let some (pn1, a, hc1) ← convValue? args[2]! | return false
    let some (pn2, b, hc2) ← convValue? args[3]! | return false
    unless a.hasFVar || b.hasFVar do return false
    let some law ← queryLaw? `evalArith d (variant := `catchAdd)
      | (do trace[RelSem.roundEval] "convArith: catchAdd query miss"
            return false)
    let sum ← mkAppM ``HAdd.hAdd #[a, b]
    let some (h1, h2) ← rangeProofs sum | return false
    let catchAt (x y : Expr) : Expr :=
      mkApp4 (mkConst c) args[0]! args[1]! x y
    let mkIV (pn v : Expr) : Expr :=
      mkApp2 (mkConst ``CerbMem.IntegerValue.IV) pn v
    -- congr the operand conv proofs into the catch app
    let mut cur := d
    let mut prfAcc : Option Expr := none
    if let some h := hc1 then
      let motive := Lean.mkLambda `x .default
        (mkConst ``CerbMem.IntegerValue) (catchAt (.bvar 0) args[3]!)
      let piece ← mkCongrArg motive h
      let next := catchAt (mkIV pn1 a) args[3]!
      let piece ← mkExpectedTypeHint piece (← mkEq cur next)
      cur := next
      prfAcc := some piece
    if let some h := hc2 then
      let motive := Lean.mkLambda `y .default
        (mkConst ``CerbMem.IntegerValue)
        (mkApp4 (mkConst c) args[0]! args[1]!
          (if hc1.isSome then mkIV pn1 a else args[2]!) (.bvar 0))
      let piece ← mkCongrArg motive h
      let next := mkApp4 (mkConst c) args[0]! args[1]!
        (if hc1.isSome then mkIV pn1 a else args[2]!) (mkIV pn2 b)
      let piece ← mkExpectedTypeHint piece (← mkEq cur next)
      cur := next
      prfAcc := some (← match prfAcc with
        | none => pure piece
        | some p => mkEqTrans p piece)
    let lawPrf ← mkAppM law #[pn1, pn2, a, b, h1, h2]
    let some (_, _, rhs) := (← inferType lawPrf).eq? | return false
    if (rhs.find? (· == d)).isSome then return false
    let lawPrf ← mkExpectedTypeHint lawPrf (← mkEq cur rhs)
    let full ← match prfAcc with
      | none => pure lawPrf
      | some p => mkEqTrans p lawPrf
    let full ← mkExpectedTypeHint full (← mkEq d rhs)
    mintEmit hp d rhs full "conv/catch arith law"
    return true
  else
    return false


/-- THE PULL LANE (arc-18 C3): a stuck `pull_constrained` crossing at
    a constraint-free pexpr rewrites through THE PULL_CONSTRAINED
    IDENTITY LAW (Kit/Eval, kind `evalPull`) — the arc-17 S3 §3.4
    wall deleted by construction: the side condition is the
    `pullSpine` mirror's computation, kernel-deferred as an `Eq.refl`
    hint (structural, symbolic-leaf-safe). -/
private def mintPull (hp : HypPack) (d : Expr) : TermElabM Bool := do
  let .const c _ := d.getAppFn | return false
  let args := d.getAppArgs
  let mut face : Option (Name × Expr × Expr × Option Expr) := none
  if c == ``pull_constrained && args.size == 2 then
    face := some (`wrapper, args[0]!, args[1]!, none)
  else if c == ``pull_constrained_lemFuel && args.size == 3 then
    face := some (`fuel, args[1]!, args[2]!, some args[0]!)
  let some (variant, nE, peE, fuelE?) := face | return false
  let some law ← queryLaw? `evalPull d (variant := variant)
    | return false
  let fuelE := fuelE?.getD (mkConst ``lemDefaultFuel)
  let spineApp := mkApp2 (mkConst ``RelSem.Kit.pullSpine) fuelE peE
  let res ← withCurrHeartbeats (groundNorm "pullSpine" spineApp)
  unless res.isAppOfArity ``Option.some 2 do
    trace[RelSem.roundEval] "pull lane: spine did not close ({res.getAppFn})"
    return false
  let prfSide ← mkExpectedTypeHint (← mkEqRefl res)
    (← mkEq spineApp res)
  let peP := res.appArg!
  let prf ← (do
    match variant with
    | `wrapper => mkAppM law #[nE, prfSide]
    | _ => mkAppM law #[fuelE, peE, peP, nE, prfSide])
  let some (_, _, rhs) := (← inferType prf).eq? | return false
  if (rhs.find? (· == d)).isSome then return false
  let prf' ← mkExpectedTypeHint prf (← mkEq d rhs)
  mintEmit hp d rhs prf' "pull_constrained identity law"
  return true

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
    if ← withCurrHeartbeats (mintConvArith hp d) then
      trace[RelSem.roundEval] "arith minter: hit after {(← IO.monoMsNow) - t0} ms ({cands.size} candidates)"
      return true
    if ← withCurrHeartbeats (mintPull hp d) then
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

end RoundEval
end RelSem
