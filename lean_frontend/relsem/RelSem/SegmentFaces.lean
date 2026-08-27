/-
  RelSem.SegmentFaces — arc-18 R2 (2026-08-26): THE SEGMENT FACES.

  The thin user surfaces over the segment layer (RelSem/Segment.lean):

  * `verify_fn <spec>` — statement → WP obligation through the FnSpec
    ([F9]) + the threaded heap-route adequacy (one `refine`, no
    logic).
  * `seg_auto` — the registry-driven segment walker: per straight-line
    segment it consults THE ONE REGISTRY (RelSem/LawRegistry.lean —
    the R4 contract: dispatch by goal form, never hardcoded names) for
    the fixture's registered OPEN-MEMORY equation, selects the walk
    rule the entry's `variant` names, discovers the footprint
    resources in the proof-mode context by shape, and applies the
    EXISTING walk rules (RelSem/CerbHeapWalk.lean) through their
    macros — brick-wp discipline: lemmas + thin faces, all semantic
    content in registered, kernel-checked laws; the meta layer shapes
    claims, never certifies them. Anything undispatchable is a LOUD
    fail-closed error naming the atom (the frontier discipline).
  * Registration attributes `@[seg_eq <variant>]`, `@[seg_fact]`,
    `@[seg_canon]`, `@[seg_post]` — fixture equation supply enters
    the registry under kinds `segEq`/`segFact`/`segCanon`/`segPost`
    (visible per-kind in the census; SUPPLY entries, not laws — the
    kind field marks them, and the engine-side mover that MINTS them
    is the registered arc-19 frontier).

  Donor naming (justified against the donors): `verify_fn` — the
  spec-based analogue of RefinedC's `typed_function`
  (deps/refinedc/theories/typing/programs.v; ours is a Hoare-style
  FnSpec, not a refinement type — design pass §2.2); `seg_auto` —
  brick-wp's `wp_auto` packaging idea one level up (segments, not
  source steps); the invariant face is a DECLARATION (`SegInv` + the
  derived obligations, Segment.lean §3), as in both donors (RefinedC
  annotations attach to blocks; BRiCk's `wp_while_inv` takes `I` as a
  term), never a tactic step.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Segment
import RelSem.PerStepTactics
import RelSem.LawRegistry
import RelSem.Kit.Map

set_option autoImplicit false

open Lean Elab Meta Tactic

namespace RelSem.Seg

/-! ## §1 Registration attributes (the registry is the interface, R4) -/

open LawRegistry in
private def registerSegEntry (declName : Name) (kind : Name)
    (variant : Name) (attrKind : AttributeKind) : AttrM Unit := do
  let keys ← MetaM.run' (goalFormKeys declName)
  ScopedEnvExtension.add stepLawExt
    { name := declName, keys, kind, variant, side := `fed,
      frontier := s!"seg/{kind}",
      trace := s!"\{law := {declName}, joint := seg/{kind}/{variant}}",
      lineage := "fixture equation supply (segment layer, arc-18 R2; \
        engine-side minting is the registered arc-19 frontier)",
      prio := keys.size } attrKind

/-- `@[seg_eq <variant>]`: register a fixture OPEN-MEMORY stage/atom
    equation (`∀ bm am, app m (setMaps ρ bm am) = …`) as segment
    equation supply. `<variant>` names the walk-rule class the
    equation feeds: `rest | read1 | read2 | argobj | argobj2 | scratch1 | scratch1p | scratch2 | write1`. -/
syntax (name := seg_eq) "seg_eq" ident : attr

initialize registerBuiltinAttribute {
  name := `seg_eq
  descr := "segment-layer equation supply (kind segEq in THE ONE \
    registry); the ident names the walk-rule class"
  add := fun declName stx kind => do
    registerSegEntry declName `segEq stx[1].getId kind
}

/-- `@[seg_fact]`: register a ground side fact (address arithmetic
    etc.) consumed by `seg_side` during rule application. -/
syntax (name := seg_fact) "seg_fact" : attr

initialize registerBuiltinAttribute {
  name := `seg_fact
  descr := "segment-layer ground side fact (kind segFact)"
  add := fun declName _ kind => do
    registerSegEntry declName `segFact .anonymous kind
}

/-- `@[seg_canon]`: register the canonical mid-walk representative
    (`CanonAt ρ c`) for an `nd_get` joint. -/
syntax (name := seg_canon) "seg_canon" : attr

initialize registerBuiltinAttribute {
  name := `seg_canon
  descr := "segment-layer canonical state representative (kind segCanon)"
  add := fun declName _ kind => do
    registerSegEntry declName `segCanon .anonymous kind
}

/-- `@[seg_post]`: register a terminal readout fact
    (`∀ bm am, φ (g (setMaps ρ bm am))`) for the harness terminal. -/
syntax (name := seg_post) "seg_post" : attr

initialize registerBuiltinAttribute {
  name := `seg_post
  descr := "segment-layer terminal readout fact (kind segPost)"
  add := fun declName _ kind => do
    registerSegEntry declName `segPost .anonymous kind
}

initialize registerTraceClass `RelSem.segAuto

/-! ## §2 Registry-backed side-condition discharge -/

/-- A proof of `ty` from a local proof `e : ety`, descending through
    conjunctions (guarded statements pack digest pins + seed
    apartness as one `∧` — the components feed separate equation
    hypotheses). -/
private partial def fromLocal (e ety ty : Expr) (depth : Nat := 3) :
    MetaM (Option Expr) := do
  if ← isDefEq ety ty then return some e
  if depth == 0 then return none
  let ety ← whnf ety
  if ety.isAppOfArity ``And 2 then
    let l := ety.getAppArgs[0]!
    let r := ety.getAppArgs[1]!
    if let some p ← fromLocal (← mkAppM ``And.left #[e]) l ty
        (depth - 1) then
      return some p
    fromLocal (← mkAppM ``And.right #[e]) r ty (depth - 1)
  else
    return none

/-- Close a hypothesis hole by local assumption (conjunct descent
    included) or `rfl`. INNERMOST-FIRST (arc-18 R4): the statement
    faces leave the outer statement binders in the hole's context
    beside the freshly-introduced obligation binders; the obligation's
    own (innermost) locals are the intended witnesses. -/
private def solveHole (mid : MVarId) : MetaM Bool := do
  let ty ← instantiateMVars (← mid.getType)
  let decls := (← getLCtx).foldl (init := #[]) fun acc d =>
    if d.isImplementationDetail then acc else acc.push d
  let mut byLocal : Option Expr := none
  for i in [0:decls.size] do
    if byLocal.isNone then
      let d := decls[decls.size - 1 - i]!
      byLocal ← fromLocal d.toExpr d.type ty
  if let some e := byLocal then
    mid.assign e
    return true
  if let some (_, l, r) := ty.eq? then
    if ← isDefEq l r then
      mid.assign (← mkEqRefl r)
      return true
  return false

/-- The ∀-arity of a type (plain syntactic count — the partial
    telescope below matches a ∀-shaped expectation without consuming
    its binders). -/
private def forallArity : Expr → Nat
  | .forallE _ _ b _ => forallArity b + 1
  | _ => 0

/-- Instantiate a registered entry against an expected proposition:
    meta-telescope the entry DOWN TO the expectation's own ∀-arity
    (arc-18 R4: ∀-shaped holes — e.g. the scratch2 rule's
    `∀ bm am, …` final-state facts — match registered facts whose
    trailing binders line up), unify its conclusion, then close
    leftover hypothesis holes (`solveHole`). Returns the proof term,
    or `none` (state restored). -/
private def instantiateEntry (declName : Name) (expected : Expr) :
    MetaM (Option Expr) := do
  let s ← saveState
  -- runtime exceptions (deep-recursion storms during speculative
  -- unification against arbitrary registered entries) must restore
  -- and miss, exactly like ordinary failures (arc-18 R4)
  tryCatchRuntimeEx (do
    try
      let cinfo ← getConstInfo declName
      let nT := forallArity cinfo.type
      let nE := forallArity expected
      let (margs, _, concl) ←
        forallMetaTelescopeReducing cinfo.type (some (nT - nE))
      unless ← isDefEq concl expected do
        restoreState s; return none
      let mut ok := true
      for m in margs do
        let m ← instantiateMVars m
        unless m.isMVar do continue
        unless ← solveHole m.mvarId! do ok := false
      unless ok do
        restoreState s; return none
      return some (← instantiateMVars (mkAppN
        (mkConst declName (cinfo.levelParams.map Level.param)) margs))
    catch _ =>
      restoreState s; return none)
    (fun _ => do restoreState s; return none)

/-- Run a speculative probe under its OWN small heartbeat budget
    (arc-18 R4): a probe that storms (whnf into a symbolic-index
    family, say) burns only its own allowance — the enclosing
    declaration's budget is measured from a fresh start, so one bad
    probe cannot poison every later match into instant timeout. -/
private def withProbeBudget {m : Type → Type} {α : Type} [Monad m]
    [MonadControlT Core.CoreM m] [Lean.MonadWithOptions m]
    (x : m α) : m α :=
  Core.withCurrHeartbeats
    (withOptions (fun o => o.set `maxHeartbeats (5000 : Nat)) x)

/-- Scan registered entries of `kind` for one whose conclusion proves
    `expected` — KEYED pre-selection first (the expectation's
    goal-form key, symmetric to `goalFormKeys`: telescope, eq-LHS;
    arc-18 R4 — the linear all-entries scan burned the enclosing
    declaration's heartbeat budget on speculative unification), the
    fence/shape-robust full kind scan as fallback. Every attempt is
    probe-budgeted. -/
private def proveByRegistry (kind : Name) (expected : Expr) :
    MetaM (Option Expr) := do
  let tryEntry (nm : Name) : MetaM (Option Expr) := do
    match ← withProbeBudget (instantiateEntry nm expected) with
    | some pf =>
      trace[RelSem.segAuto] "proveByRegistry: {nm} HIT for        {indentExpr expected}"
      return some pf
    | none =>
      trace[RelSem.segAuto] "proveByRegistry: {nm} miss"
      return none
  let cands ← try
    withoutModifyingState do
      let (_, _, body) ← forallMetaTelescopeReducing expected
      let target := match body.eq? with
        | some (_, l, _) => l
        | none => body
      LawRegistry.query kind target
    catch _ => pure #[]
  let mut tried : Array Name := #[]
  for l in cands do
    tried := tried.push l.name
    if let some pf ← tryEntry l.name then
      return some pf
  for l in ← LawRegistry.byKind kind do
    unless tried.contains l.name do
      if let some pf ← tryEntry l.name then
        return some pf
  return none

/-- Try a tactic; restore state (including the message log — tactic
    ERROR RECOVERY logs-and-admits instead of throwing, which would
    otherwise turn a failed branch into a silently sorried "success")
    and report `false` on failure. -/
private def tryTac (stx : TSyntax `tactic) : TacticM Bool := do
  let s ← saveState
  let msgs := (← getThe Core.State).messages
  let fail : TacticM Bool := do
    restoreState s
    modifyThe Core.State fun st => { st with messages := msgs }
    pure false
  try
    evalTactic stx
    -- flush postponed elaboration NOW (arc-18 R4): a `refine`
    -- alternative can otherwise "succeed" with deferred unification
    -- errors that detonate at the end of the surrounding tactic
    -- block — long after the wrong alternative was accepted
    Term.synthesizeSyntheticMVarsNoPostponing
    if (← getThe Core.State).messages.hasErrors && !msgs.hasErrors then
      fail
    else
      pure true
  catch _ => fail

/-- `seg_side`: side-condition discharge for auto-applied walk rules —
    `assumption`/`wp_ground`/`rfl`, then the registered `segFact`
    supply (address arithmetic at open states). Fail-closed: names the
    goal on miss. -/
elab "seg_side" : tactic => do
  -- cheap closed-form attempts first (probe-budgeted: a storming
  -- probe must not poison the registry scan's budget), the
  -- registered segFact supply next, `wp_ground` (kernel decide —
  -- the most storm-prone probe) LAST
  let cheap : List (TSyntax `tactic) :=
    [← `(tactic| assumption), ← `(tactic| rfl)]
  for t in cheap do
    if ← withProbeBudget (tryTac t) then
      return
  let g ← getMainGoal
  let done ← g.withContext do
    let expected ← instantiateMVars (← g.getType)
    if let some pf ← proveByRegistry `segFact expected then
      g.assign pf
      pure true
    else
      pure false
  if done then
    replaceMainGoal []
    return
  if ← withProbeBudget (tryTac (← `(tactic| wp_ground))) then
    return
  let g ← getMainGoal
  g.withContext do
    let expected ← instantiateMVars (← g.getType)
    throwError "seg_side: no route to side condition (assumption/\
      rfl/segFact/wp_ground all missed):{indentExpr expected}"

/-- `seg_post_side`: the harness terminal's readout — the uniform
    inline witness first, then the registered `segPost` supply. -/
elab "seg_post_side" : tactic => do
  if ← tryTac (← `(tactic| exact fun _ _ => ⟨_, rfl, rfl⟩)) then
    return
  let g ← getMainGoal
  g.withContext do
  let expected ← instantiateMVars (← g.getType)
  if let some pf ← proveByRegistry `segPost expected then
    g.assign pf
    replaceMainGoal []
  else
    throwError "seg_post_side: terminal readout — the inline witness \
      failed and no registered segPost fact applies:\
      {indentExpr expected}"

/-! ## §2b The env-peel discharger (the R4-priced env-lookup
    automation's concrete-instance base case — built as a TACTIC
    instead of ground per instance, per the proof-grind rule's third
    species: the missing automation step IS the deliverable). -/

/-- Reduce a map expression to its law-shaped head (`fmapAddBy` chain
    or a materialized `Fmap.mk`/empty) WITHOUT unfolding the adds —
    stepwise delta/iota so the Kit lookup laws' spelling survives. -/
private def exposeMap (e : Expr) : MetaM Expr := do
  let e ← instantiateMVars e
  if e.isAppOf ``fmapAddBy || e.isAppOf ``Fmap.mk
      || e.isAppOf ``Fmap.empty || e.isAppOf ``fmapEmpty then
    return e
  -- whnf UNTIL the chain head surfaces (never past it — the law
  -- spelling survives); a non-chain result falls back untouched
  if let some r ← whnfUntil e ``fmapAddBy then
    return r
  return e

/-- Built-ness proof for a (possibly open-based) `fmapAddBy` chain at
    the pinned comparator `c` (arc-18 R4, the ∀-k closure's engine
    leg): peel chain layers through the once-proved
    `Kit.fmapAddBy_built` (instances taken FROM THE TERM — the R-S2-1
    lesson), close the base by (a) the captured-comparator refl when
    the base is MATERIALIZED (`FmapBuilt c (Fmap.mk c …)` whnfs to an
    `Eq`, CHECKED — the pre-R4 unchecked cast is gone), or (b) a
    local hypothesis `FmapBuilt c base` (the symbolic-base case: the
    family lemmas carry built-ness as an ordinary hypothesis).
    Fail-closed: `none` when neither applies. -/
private partial def mkBuiltProof (c : Expr) (mTerm : Expr) :
    MetaM (Option Expr) := do
  let mTerm ← instantiateMVars mTerm
  let mExp ← exposeMap mTerm
  -- CLOSED-chain materialized refl FIRST (arc-18 R5): a concrete
  -- chain over the empty map — T4's harness env at the composition
  -- site — whnfs to `Fmap.mk` and closes by the captured-comparator
  -- refl in one step; the layer descent would otherwise bottom out
  -- at `FmapBuilt c fmapEmpty = False` (built-ness starts at the
  -- FIRST insert, which the descent has no base case for). The fvar
  -- guard keeps symbolic-key chains off the whnf (the S3
  -- materialization wall).
  if !mExp.hasFVar && !mExp.hasExprMVar then
    let ty ← mkAppM ``RelSem.Kit.FmapBuilt #[c, mExp]
    let tyW ← whnf ty
    if let some (_, l, r) := tyW.eq? then
      if (← isDefEq l r) then
        return some (← mkExpectedTypeHint (← mkEqRefl r) ty)
  if mExp.isAppOf ``fmapAddBy && mExp.getAppNumArgs == 7 then
    let args := mExp.getAppArgs
    let some inner ← mkBuiltProof c args[6]! | return none
    return some (← mkAppOptM ``RelSem.Kit.fmapAddBy_built
      #[args[0]!, args[1]!, args[2]!, c, args[3]!, args[4]!, args[5]!,
        args[6]!, inner])
  -- materialized base: checked captured-comparator refl
  let ty ← mkAppM ``RelSem.Kit.FmapBuilt #[c, mExp]
  let tyW ← whnf ty
  if let some (_, l, r) := tyW.eq? then
    if (← isDefEq l r) then
      return some (← mkExpectedTypeHint (← mkEqRefl r) ty)
  -- symbolic base: a local FmapBuilt hypothesis
  let byLocal ← (← getLCtx).findDeclM? fun d => do
    if d.isImplementationDetail then return none
    if ← isDefEq d.type ty then return some d.toExpr else return none
  return byLocal

/-- `seg_env_lookup`: discharge a `fmapLookupBy _ k <env>` goal at a
    minted state's env — peel non-matching `fmapAddBy` layers by the
    registered Kit skip law (`refine`-driven: the chain is exposed by
    DEFEQ UNIFICATION with the law's LHS, so folded projections like
    `envOf (walk-endpoint …)` need no manual exposure; built-ness by
    `rfl` post-unification; key apartness via `symCmpO_eq_iff` +
    `omega`, consuming any seed bound/supply pins in context), take
    the hit layer when the keys agree, and close ground residues by
    `rfl`. Fail-closed with the residual goal. -/
elab "seg_env_lookup" : tactic => do
  for _ in [0:64] do
    let g ← getMainGoal
    let action ← g.withContext do
      let tgt := (← instantiateMVars (← g.getType)).consumeMData
      let some (_, lhs, _) := tgt.eq?
        | throwError "seg_env_lookup: goal is not an equation:\
            {indentExpr tgt}"
      unless lhs.isAppOf ``fmapLookupBy do
        return Sum.inl ()
      let mp := lhs.getAppArgs.back!
      let mp' ← exposeMap mp
      unless mp' == mp do
        let lhs' := mkAppN lhs.getAppFn
          (lhs.getAppArgs.set! (lhs.getAppNumArgs - 1) mp')
        let tgt' := tgt.replace
          (fun t => if t == lhs then some lhs' else none)
        let g' ← g.change tgt'
        replaceMainGoal [g']
      pure (Sum.inr (mp'.isAppOf ``fmapAddBy))
    match action with
    | .inl () =>
      evalTactic (← `(tactic| rfl))
      return
    | .inr false =>
      evalTactic (← `(tactic| rfl))
      return
    | .inr true => pure ()
    let g ← getMainGoal
    let stepped ← g.withContext do
      let tgt := (← instantiateMVars (← g.getType)).consumeMData
      let some (_, goalLhs, goalRhs) := tgt.eq? | pure false
      -- arithmetic facts for the apartness discharge (seed bounds +
      -- supply pins from the caller's context)
      let arithFacts ← (← getLCtx).foldlM (init := #[]) fun acc d => do
        if d.isImplementationDetail then return acc
        let t := d.type.consumeMData
        if t.isAppOf ``Eq || t.isAppOf ``Ne || t.isAppOf ``LT.lt
            || t.isAppOf ``LE.le || t.isAppOf ``GT.gt
            || t.isAppOf ``GE.ge || t.isAppOf ``Not then
          return acc.push d.toExpr
        return acc
      -- ¬ n1 = n2: kernel decide at closed layers, omega (with the
      -- gathered facts) at seed layers
      let mkNe (n1 n2 : Expr) : TacticM Expr := do
        let neTy := mkApp (mkConst ``Not)
          (← mkEq n1 n2)
        -- kernel decide only at CLOSED disequalities (mkDecideProof
        -- does not itself reject open props — the kernel would)
        try
          if neTy.hasFVar || neTy.hasMVar then
            throwError "open (omega route)"
          -- guard (arc-18 R4): a FALSE closed disequality must fail
          -- HERE — mkDecideProof does not evaluate, so on equal keys
          -- (rebind layers) it would fabricate a kernel-rejected
          -- proof and mask the hit route
          if ← isDefEq n1 n2 then
            throwError "keys equal (not a skip — hit route)"
          mkDecideProof neTy
        catch _ =>
          let gNe ← mkFreshExprMVar neTy
          try
            -- the MetaM omega entry expects a byContra'd goal (the
            -- omegaTactic frontend's own first move)
            if let some g' ← gNe.mvarId!.falseOrByContra then
              g'.withContext do
                Lean.Elab.Tactic.Omega.omega
                  (arithFacts.toList ++ (← getLocalHyps).toList) g'
          catch ex =>
            trace[RelSem.segAuto] "seg_env_lookup: apartness omega \
              failed on{indentExpr neTy}\nwith facts \
              {arithFacts.size}: {ex.toMessageData}"
            throw ex
          instantiateMVars gNe
      let applyLaw (law : Name) (isSkip : Bool) : TacticM Bool := do
        let s0 ← saveState
        try
          let cinfo ← getConstInfo law
          let (margs, _, concl) ← forallMetaTelescope cinfo.type
          let some (_, lawLhs, _) := concl.eq? | throwError "law shape"
          unless ← isDefEq lawLhs goalLhs do
            throwError "law LHS does not unify"
          -- the invariant comparator `c` appears only in the
          -- HYPOTHESES (never the conclusion) — pin it explicitly
          for m in margs do
            let m ← instantiateMVars m
            if m.isMVar then
              let t ← instantiateMVars (← m.mvarId!.getType)
              if t == (← mkArrow (mkConst ``sym)
                  (← mkArrow (mkConst ``sym) (mkConst ``Ordering))) then
                let _ ← isDefEq m (mkConst ``RelSem.Kit.symCmpO)
          -- instance holes (e.g. [Std.TransCmp c]) appear only in the
          -- hypotheses — synthesize them at the now-pinned comparator
          for m in margs do
            let m ← instantiateMVars m
            if m.isMVar then
              let t ← instantiateMVars (← m.mvarId!.getType)
              if (← isClass? t).isSome then
                if let .some inst ← trySynthInstance t then
                  let _ ← isDefEq m inst
          -- built-ness: checked refl at materialized chains, the
          -- fmapAddBy_built chain at open bases (arc-18 R4 — the old
          -- UNCHECKED refl cast produced kernel-rejected terms at
          -- symbolic base envs)
          let hmSlot ← instantiateMVars margs[margs.size - 2]!
          if hmSlot.isMVar then
            let hmTy ← instantiateMVars (← hmSlot.mvarId!.getType)
            unless hmTy.isAppOfArity ``RelSem.Kit.FmapBuilt 4 do
              throwError "hm slot shape"
            let hmArgs := hmTy.getAppArgs
            let some hmPf ← mkBuiltProof hmArgs[2]! hmArgs[3]!
              | throwError "hm: no built-ness route (materialized \
                  refl and local-hypothesis base both missed)"
            unless ← isDefEq hmSlot hmPf do
              throwError "hm assignment failed"
          -- key verdict: PURE construction over the ctor components
          -- (no nested tactic runs — the assignments stay ambient)
          let hkSlot ← instantiateMVars margs[margs.size - 1]!
          if hkSlot.isMVar then
            let hkTy ← instantiateMVars (← hkSlot.mvarId!.getType)
            let eqTy := if isSkip then hkTy.appArg! else hkTy
            let some (_, cmpApp, _) := eqTy.eq?
              | throwError "hk shape"
            let lk ← whnf cmpApp.getAppArgs[cmpApp.getAppNumArgs - 2]!
            let tk ← whnf cmpApp.getAppArgs.back!
            unless lk.isAppOfArity ``Symbol 3
                && tk.isAppOfArity ``Symbol 3 do
              throwError "keys not in constructor form"
            let la := lk.getAppArgs
            let ta := tk.getAppArgs
            let iffE := mkAppN (mkConst ``RelSem.Kit.symCmpO_eq_iff)
              #[la[0]!, ta[0]!, la[1]!, ta[1]!, la[2]!, ta[2]!]
            let hkPf ← (do
              if isSkip then
                let nePf ← mkNe la[1]! ta[1]!
                withLocalDeclD `hEq eqTy fun hEq => do
                  let h2 ← mkAppM ``Iff.mp #[iffE, hEq]
                  let h22 ← mkAppM ``And.right #[h2]
                  let bot ← mkAppOptM ``absurd
                    #[none, some (mkConst ``False), some h22, some nePf]
                  mkLambdaFVars #[hEq] bot
              else
                -- a HIT must be a CHECKED key agreement (an unchecked
                -- refl hint would defer the mismatch to the kernel)
                unless (← isDefEq la[0]! ta[0]!)
                    && (← isDefEq la[1]! ta[1]!) do
                  throwError "keys do not agree (not a hit)"
                let dEq ← mkExpectedTypeHint (← mkEqRefl la[0]!)
                  (← mkEq la[0]! ta[0]!)
                let nEq ← mkExpectedTypeHint (← mkEqRefl la[1]!)
                  (← mkEq la[1]! ta[1]!)
                mkAppM ``Iff.mpr
                  #[iffE, ← mkAppM ``And.intro #[dEq, nEq]])
            let hkPf ← mkExpectedTypeHint hkPf hkTy
            unless ← isDefEq hkSlot hkPf do
              throwError "hk assignment failed"
          let lawE ← instantiateMVars (mkAppN
            (mkConst law (cinfo.levelParams.map Level.param)) margs)
          let some (_, _, lawRhs) := (← inferType lawE).eq?
            | throwError "law lost its equation"
          let gNew ← mkFreshExprMVar
            (← mkEq (← instantiateMVars lawRhs) goalRhs)
          g.assign (← mkEqTrans lawE gNew)
          replaceMainGoal [gNew.mvarId!]
          pure true
        catch ex =>
          restoreState s0
          trace[RelSem.segAuto] "seg_env_lookup: {law} failed: \
            {ex.toMessageData}"
          pure false
      if ← applyLaw ``RelSem.Kit.fmapLookupBy_addBy_ne true then
        pure true
      else if ← applyLaw ``RelSem.Kit.fmapLookupBy_addBy_eq false then
        pure true
      else
        pure false
    unless stepped do
      throwError "seg_env_lookup: neither skip nor hit applies at \
        the current layer (fail-closed):{indentExpr (← getMainTarget)}"
  throwError "seg_env_lookup: layer budget (64) exceeded"

/-! ## (§3 — the auto-fed walk macros — DELETED at V1 2026-08-28
    with the whole-state walk rules they applied (CerbHeapWalk); the
    V2 per-construct stepper owns the successor tactic layer over the
    decomposed interpretation.) -/

/-! ## §4 `verify_fn` -/

/-! `verify_fn <spec>`: statement → WP obligation through the FnSpec
    (role 1) + threaded heap-route adequacy. Handles the closed and
    one/two-parameter, unguarded and guarded statement shapes, and
    both the adequacy and UB-freedom faces. The fixture's spec must
    be REDUCIBLE (`abbrev`) — its projections are unified against the
    byte-stable statement text. Leaves the WP obligation introduced,
    with the initial rest half named `Hst`. -/
/-- The statement-shape index (arc-18 R4): pick the ONE bridge
    alternative from the goal's leading binder domains instead of
    trying every alternative — mis-matched `refine` attempts unify
    against the whole adequacy statement and burn real budget. -/
private inductive StmtShape
  | closed | closedGuarded | oneParam | oneParamGuarded | twoParam

private def classifyStmt : TacticM StmtShape := do
  let tgt ← getMainTarget
  let tgt ← whnf tgt
  forallBoundedTelescope tgt (some 6) fun xs _ => do
    let doms ← xs.mapM fun x => inferType x
    let isInt (e : Expr) : Bool := e.isConstOf ``Int
    let isNat (e : Expr) : Bool := e.isConstOf ``Nat
    let isP (e : Expr) : MetaM Bool := do pure (← inferType e).isProp
    if h0 : 0 < doms.size then
      if ← isP doms[0] then
        -- guarded family: EnvHyp → ∀ seed, Apart → …
        if h3 : 3 < doms.size then
          if isInt doms[3] then return .oneParamGuarded
          else return .closedGuarded
        else return .closedGuarded
      else if isNat doms[0] then
        if h1 : 1 < doms.size then
          if isInt doms[1] then
            if h2 : 2 < doms.size then
              if isInt doms[2] then return .twoParam
              else return .oneParam
            else return .oneParam
          else return .closed
        else return .closed
      else
        throwError "verify_fn: unrecognized leading binder"
    else
      throwError "verify_fn: no leading binders"

elab "verify_fn" spec:term : tactic => do
  let shape ← classifyStmt
  let altA : TSyntax `tactic ← match shape with
    | .closed => `(tactic| refine fun seed => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed () trivial trivial)
    | .closedGuarded => `(tactic| refine fun henv seed hap => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed () ⟨henv, hap⟩ trivial)
    | .oneParam => `(tactic| refine fun seed a ha => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed a trivial ha)
    | .oneParamGuarded => `(tactic| refine fun henv seed hap a ha => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed a ⟨henv, hap⟩ ha)
    | .twoParam => `(tactic| refine fun seed x y h1 h2 h3 => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed (x, y) trivial ⟨h1, h2, h3⟩)
  let altB : TSyntax `tactic ← match shape with
    | .closed => `(tactic| refine fun seed => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed () trivial trivial)
    | .closedGuarded => `(tactic| refine fun henv seed hap => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed () ⟨henv, hap⟩ trivial)
    | .oneParam => `(tactic| refine fun seed a ha => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed a trivial ha)
    | .oneParamGuarded => `(tactic| refine fun henv seed hap a ha => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed a ⟨henv, hap⟩ ha)
    | .twoParam => `(tactic| refine fun seed x y h1 h2 h3 => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.CerbSt.CerbStS) ?_ seed (x, y) trivial ⟨h1, h2, h3⟩)
  let mut bridged := false
  for t in [altA, altB] do
    if !bridged then
      bridged ← tryTac t
  unless bridged do
    throwError "verify_fn: the goal is not a recognized threaded \
      statement shape for this spec (closed/guarded, one/two-parameter, \
      adequacy or UB-freedom face)"
  evalTactic (← `(tactic| intro seed a hg ha _inst))
  evalTactic (← `(tactic| iintro Hst))

/-! ## (§5 — `seg_auto`, the registry-driven segment walker —
    DELETED at V1 2026-08-28: its applier set was exactly the
    whole-state walk rules retired with the `restIs` route. The
    face name returns at the V2 re-target over the per-construct
    rules, per the infrastructure plan's component H.) -/

end RelSem.Seg
