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
    equation feeds: `rest | read1 | argobj | scratch1 | write1`. -/
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
    included) or `rfl`. -/
private def solveHole (mid : MVarId) : MetaM Bool := do
  let ty ← instantiateMVars (← mid.getType)
  let byLocal ← (← getLCtx).findDeclM? fun d => do
    if d.isImplementationDetail then return none
    fromLocal d.toExpr d.type ty
  if let some e := byLocal then
    mid.assign e
    return true
  if let some (_, l, r) := ty.eq? then
    if ← isDefEq l r then
      mid.assign (← mkEqRefl r)
      return true
  return false

/-- Instantiate a registered entry against an expected proposition:
    meta-telescope the entry, unify its conclusion, then close
    leftover hypothesis holes (`solveHole`). Returns the proof term,
    or `none` (state restored). -/
private def instantiateEntry (declName : Name) (expected : Expr) :
    MetaM (Option Expr) := do
  let s ← saveState
  try
    let cinfo ← getConstInfo declName
    let (margs, _, concl) ← forallMetaTelescopeReducing cinfo.type
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
    restoreState s; return none

/-- Scan all registered entries of `kind` for one whose conclusion
    proves `expected`. -/
private def proveByRegistry (kind : Name) (expected : Expr) :
    MetaM (Option Expr) := do
  for l in ← LawRegistry.byKind kind do
    if let some pf ← instantiateEntry l.name expected then
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
  let cheap : List (TSyntax `tactic) :=
    [← `(tactic| assumption), ← `(tactic| wp_ground),
     ← `(tactic| rfl)]
  for t in cheap do
    if ← tryTac t then
      return
  let g ← getMainGoal
  g.withContext do
  let expected ← instantiateMVars (← g.getType)
  if let some pf ← proveByRegistry `segFact expected then
    g.assign pf
    replaceMainGoal []
  else
    throwError "seg_side: no route to side condition (assumption/\
      wp_ground/rfl/segFact all missed):{indentExpr expected}"

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
          -- built-ness: the captured-comparator refl at the unified
          -- inner chain
          let hmSlot ← instantiateMVars margs[margs.size - 2]!
          if hmSlot.isMVar then
            let hmTy ← instantiateMVars (← hmSlot.mvarId!.getType)
            let hmPf ← mkExpectedTypeHint
              (← mkEqRefl (mkConst ``RelSem.Kit.symCmpO)) hmTy
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

/-! ## §3 The auto-fed walk macros (the CerbHeapWalk macros with the
    ground-fact slots routed through `seg_side` instead of an explicit
    term — same rules, same case structure; the explicit-feed macros
    stay for hand-fed walks). -/

/-- Object-creation step, auto side facts (mirror of `wp_argobj`,
    CerbHeapWalk.lean). -/
macro "seg_argobj" e:term:max h:ident hal:ident hpt:ident : tactic =>
  `(tactic| (wp_expose
             iapply RelSem.Cerb.wpk_seq_alloc_store_ecast $e ?wpe ?wprho ?wpsz ?wpaddr ?wpnz ?wplen ?wpnid ?wpal
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wprho => rfl
             case wpnid => rfl
             case wpal => rfl
             case wpsz => rfl
             case wpaddr => seg_side
             case wpnz => seg_side
             case wplen => rfl
             iintro ⟨$h:ident, $hal:ident, $hpt:ident⟩))

/-- Scratch-object step, auto side facts (mirror of `wp_scratch1`). -/
macro "seg_scratch1" e:term:max hr:ident haV:ident hpV:ident
    hptS:ident : tactic =>
  `(tactic| (wp_expose
             iapply RelSem.Cerb.wpk_seq_scratch1_ecast $e ?wpe ?wprho ?wplayk ?wpsz ?wpaddr ?wpnz ?wplen ?wpnid ?wpal
             rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left; rotate_left
             rotate_left; rotate_left; rotate_left
             iframe $hr:ident $haV:ident $hpV:ident
             case wpe => rfl
             case wprho => rfl
             case wpnid => rfl
             case wpal => rfl
             case wplayk => rfl
             case wpsz => rfl
             case wpaddr => seg_side
             case wpnz => seg_side
             case wplen => rfl
             iintro ⟨$hr:ident, $haV:ident, $hpV:ident, $hptS:ident⟩))

/-- The harness terminal, auto readout (mirror of `wp_fin`). -/
macro "seg_fin" h:ident : tactic =>
  `(tactic| (wp_expose
             iapply RelSem.Cerb.wpk_get_done_pure_ecast ?wpp ?wpe
             rotate_left
             rotate_left
             iframe $h:ident
             case wpe => rfl
             case wpp => seg_post_side))

/-! ## §4 `verify_fn` -/

/-- `verify_fn <spec>`: statement → WP obligation through the FnSpec
    (role 1) + threaded heap-route adequacy. Handles the closed
    (`A = Unit`) and one-parameter guarded statement shapes, and both
    the adequacy and UB-freedom faces. The fixture's spec must be
    REDUCIBLE (`abbrev`) — its projections are unified against the
    byte-stable statement text. Leaves the WP obligation introduced,
    with the initial rest half named `Hst`. -/
elab "verify_fn" spec:term : tactic => do
  let alts : List (TSyntax `tactic) := [
    -- closed, unconditional (T6)
    ← `(tactic| refine fun seed => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.Cerb.CerbHeapS) ?_ seed () trivial trivial),
    -- closed, guarded (the T4/T5/T7 house shape: EnvHyp → ∀ seed, Apart seed → …)
    ← `(tactic| refine fun henv seed hap => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.Cerb.CerbHeapS) ?_ seed () ⟨henv, hap⟩ trivial),
    -- one-parameter guarded statement (∀ seed x, pre x → …)
    ← `(tactic| refine fun seed a ha => RelSem.Seg.FnSpec.dischargeThr (S := $spec) (GF := RelSem.Cerb.CerbHeapS) ?_ seed a trivial ha),
    -- the UB-freedom twins
    ← `(tactic| refine fun seed => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.Cerb.CerbHeapS) ?_ seed () trivial trivial),
    ← `(tactic| refine fun henv seed hap => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.Cerb.CerbHeapS) ?_ seed () ⟨henv, hap⟩ trivial),
    ← `(tactic| refine fun seed a ha => RelSem.Seg.FnSpec.dischargeUBThr (S := $spec) (GF := RelSem.Cerb.CerbHeapS) ?_ seed a trivial ha)]
  let mut bridged := false
  for t in alts do
    if !bridged then
      bridged ← tryTac t
  unless bridged do
    throwError "verify_fn: the goal is not a recognized threaded \
      statement shape for this spec (closed or one-parameter guarded, \
      adequacy or UB-freedom face)"
  evalTactic (← `(tactic| intro seed a hg ha _inst))
  evalTactic (← `(tactic| iintro Hst))

/-! ## §5 `seg_auto` — the registry-driven segment walker -/

open Iris.ProofMode in
/-- All hypotheses of the current Iris proof-mode goal
    (name × asserted prop). -/
private def collectHyps (tgt : Expr) :
    MetaM (Option (Array (Name × Expr))) := do
  let some ig := parseIrisGoal? tgt | return none
  let acc ← IO.mkRef (#[] : Array (Name × Expr))
  let _ ← ig.hyps.findM? (m := MetaM) (fun name _ _ ty => do
    acc.modify (·.push (name, ty)); pure false)
  return some (← acc.get)

/-- The WP application inside the goal (the `wp_expose` search). -/
private def findWp? (tgt : Expr) : Option Expr :=
  tgt.find? (fun t =>
    t.isAppOf ``Iris.Wp.wp && t.getAppNumArgs ≥ 9)

/-- Fresh proof-mode hypothesis name avoiding the current context. -/
private def freshHypName (hyps : Array (Name × Expr)) (base : String) :
    Name := Id.run do
  let mut i := 0
  while hyps.any (fun (n, _) => n == Name.mkSimple s!"{base}{i}") do
    i := i + 1
  return Name.mkSimple s!"{base}{i}"

/-- Arity of a registered equation's prefix — the binders BEFORE its
    trailing open-memory section (`∀ (bm : TreeMap Int AbsByte)
    (am : TreeMap Int Allocation), …`). -/
private partial def prefixArity (ty : Expr) (n : Nat := 0) :
    MetaM Nat := do
  match ty with
  | .forallE _ d b _ =>
    let isBm := d.isAppOf ``Std.TreeMap
      && d.getAppArgs[1]? == some (mkConst ``CerbMem.AbsByte)
    let nextIsAm := match b with
      | .forallE _ d2 _ _ =>
        d2.isAppOf ``Std.TreeMap
          && d2.getAppArgs[1]? == some (mkConst ``CerbMem.Allocation)
      | _ => false
    if isBm && nextIsAm then return n
    else prefixArity b (n + 1)
  | _ => return n

/-- The footprint a registered equation's hypotheses read: allocation
    lookups (`am.get? aid = some al`) and pointwise byte ranges
    (`∀ i, i < bs.length → bm.get? (addr + ↑i) = some bs[i]`) —
    the indices that locate `allocIs`/`pointsToBytes` hypotheses. -/
private structure EqFootprint where
  aids : Array Expr := #[]
  addrs : Array Expr := #[]

private def eqFootprint (hTy : Expr) : MetaM EqFootprint := do
  forallTelescope hTy fun xs _ => do
    let mut fp : EqFootprint := {}
    for x in xs do
      let ty ← instantiateMVars (← inferType x)
      if let some (_, lhs, rhs) := ty.eq? then
        if lhs.isAppOf ``Std.TreeMap.get?
            && rhs.isAppOf ``Option.some then
          if (← inferType rhs.appArg!).isAppOf ``CerbMem.Allocation then
            fp := { fp with aids := fp.aids.push (← instantiateMVars lhs.appArg!) }
      else if ty.isForall then
        let inner ← forallTelescope ty fun _ body => pure body
        if let some (_, lhs, _) := inner.eq? then
          if lhs.isAppOf ``Std.TreeMap.get? then
            let idx := lhs.appArg!
            let addr := if idx.isAppOf ``HAdd.hAdd then
                idx.getAppArgs[idx.getAppNumArgs - 2]!
              else idx
            fp := { fp with addrs := fp.addrs.push (← instantiateMVars addr) }
    return fp

/-- Locate a proof-mode hypothesis by head constant and one index
    argument (position counted from the back; checked defeq). -/
private def findResHyp (hyps : Array (Name × Expr)) (head : Name)
    (idxFromBack : Nat) (idxVal : Expr) : MetaM (Option Name) := do
  for (n, ty) in hyps do
    if ty.isAppOf head then
      let args := ty.getAppArgs
      if args.size > idxFromBack then
        if ← isDefEq args[args.size - 1 - idxFromBack]! idxVal then
          return some n
  return none

/-- The restIs hypothesis (name, rest state) of the proof-mode
    context. -/
private def findRest (hyps : Array (Name × Expr)) :
    Option (Name × Expr) :=
  hyps.findSome? fun (n, ty) =>
    if ty.isAppOf ``RelSem.Cerb.restIs then
      some (n, ty.getAppArgs.back!)
    else none

initialize registerTraceClass `RelSem.segAuto

/-- A matched segment equation: the registry entry, the instantiated
    application (the walk rule's `h` feed), and its type. -/
private structure EqHit where
  law : LawRegistry.StepLaw
  h : Expr
  hTy : Expr

/-- Match the head atom `m` at rest `ρ` against the registered segEq
    supply: unify each entry's equation LHS (`app m' (setMaps ρ' bm
    am)`) with the goal-derived pattern, close leftover prefix holes
    (`solveHole`). -/
private def matchSegEq (m ρ : Expr) : TacticM (Option EqHit) := do
  for l in ← LawRegistry.byKind `segEq do
    let s ← saveState
    let hit? ← try
      let cinfo ← getConstInfo l.name
      let nPrefix ← prefixArity cinfo.type
      let (margs, _, hTy) ←
        forallMetaTelescopeReducing cinfo.type (some nPrefix)
      let okU ← forallTelescope hTy fun xs body => do
        if let some (_, lhs, _) := body.eq? then
          let pat ← mkAppM ``RelSem.app
            #[m, ← mkAppM ``RelSem.Cerb.setMaps #[ρ, xs[0]!, xs[1]!]]
          let r ← withReducible (isDefEq lhs pat)
          unless r do
            trace[RelSem.segAuto] "matchSegEq {l.name}: lhs/pat defeq \
              MISS\nlhs {indentExpr lhs}\npat {indentExpr pat}"
          pure r
        else
          trace[RelSem.segAuto] "matchSegEq {l.name}: hTy body not an \
            Eq: {indentExpr body}"
          pure false
      if !okU then
        pure none
      else
        let mut ok := true
        for mv in margs do
          let mv ← instantiateMVars mv
          unless mv.isMVar do continue
          unless ← solveHole mv.mvarId! do ok := false
        if !ok then
          pure none
        else
          let h ← instantiateMVars (mkAppN
            (mkConst l.name (cinfo.levelParams.map Level.param)) margs)
          pure (some { law := l, h, hTy := ← instantiateMVars hTy })
    catch ex =>
      trace[RelSem.segAuto] "matchSegEq {l.name}: exception \
        {ex.toMessageData}"
      pure none
    match hit? with
    | some hit => return some hit
    | none => restoreState s
  return none

/-- One seg_auto step. `false` when the goal carries no WP joint. -/
private def segStep : TacticM Bool := do
  if (← getGoals).isEmpty then return false
  match ← tryTac (← `(tactic| wp_expose)) with
  | false => return false
  | true => pure ()
  let g ← getMainGoal
  g.withContext do
  let tgt ← instantiateMVars (← g.getType)
  let some hyps ← collectHyps tgt | return false
  let some (hstName, ρ) := findRest hyps
    | throwError "seg_auto: no restIs hypothesis in the proof-mode \
        context"
  let some wpApp := findWp? tgt | return false
  let e ← whnf wpApp.getAppArgs[wpApp.getAppNumArgs - 2]!
  unless e.isAppOf ``RelSem.KExpr.seq do
    return false
  let eArgs := e.getAppArgs
  let m := eArgs[eArgs.size - 2]!
  let hstId := mkIdent hstName
  -- ── nd_get joints: harness terminal, else mid-walk state read ──
  if m.isAppOf ``nd_get then
    if ← tryTac (← `(tactic| seg_fin $hstId)) then
      return true
    -- mid-walk read: canonical representative from the segCanon supply
    let cM ← mkFreshExprMVar (mkConst ``driver_state)
    let pat ← mkAppM ``RelSem.Seg.CanonAt #[ρ, cM]
    let some _ ← proveByRegistry `segCanon pat
      | throwError "seg_auto: nd_get joint — neither the harness \
          terminal nor a registered segCanon representative applies \
          at rest{indentExpr ρ}"
    let c ← instantiateMVars cM
    let cStx ← Term.exprToSyntax c
    evalTactic (← `(tactic| wp_get $cStx $hstId))
    return true
  -- ── equation joints: registry dispatch by goal form (R4) ──
  let some hit ← matchSegEq m ρ
    | throwError "seg_auto: no registered segment equation (kind \
        segEq) matches the head atom at rest{indentExpr ρ}\natom:\
        {indentExpr m}\nregistered segEq entries: \
        {(← LawRegistry.byKind `segEq).map (·.name)}\n\
        (fail-closed: register the stage equation \
        with @[seg_eq <variant>], or extend the engine's minting \
        lane — the registered arc-19 frontier)"
  let hStx ← Term.exprToSyntax hit.h
  match hit.law.variant with
  | `rest =>
    evalTactic (← `(tactic| wp_rest $hStx $hstId))
    return true
  | `read1 =>
    let fp ← eqFootprint hit.hTy
    let some aid := fp.aids[0]? | throwError "seg_auto: read1 entry \
      {hit.law.name} carries no allocation-lookup hypothesis"
    let some addr := fp.addrs[0]? | throwError "seg_auto: read1 entry \
      {hit.law.name} carries no byte-range hypothesis"
    let some ha ← findResHyp hyps ``RelSem.Cerb.allocIs 2 aid
      | throwError "seg_auto: no allocIs hypothesis for aid\
          {indentExpr aid}"
    let some hp ← findResHyp hyps ``RelSem.Cerb.pointsToBytes 2 addr
      | throwError "seg_auto: no pointsToBytes hypothesis at\
          {indentExpr addr}"
    evalTactic (← `(tactic|
      wp_read1 $hStx $hstId $(mkIdent ha) $(mkIdent hp)))
    return true
  | `argobj =>
    let hal := mkIdent (freshHypName hyps "Hal")
    let hpt := mkIdent (freshHypName hyps "Hpt")
    evalTactic (← `(tactic| seg_argobj $hStx $hstId $hal $hpt))
    return true
  | `scratch1 =>
    let fp ← eqFootprint hit.hTy
    let some aid := fp.aids[0]? | throwError "seg_auto: scratch1 entry \
      {hit.law.name} carries no allocation-lookup hypothesis"
    let some addr := fp.addrs[0]? | throwError "seg_auto: scratch1 \
      entry {hit.law.name} carries no byte-range hypothesis"
    let some haV ← findResHyp hyps ``RelSem.Cerb.allocIs 2 aid
      | throwError "seg_auto: no allocIs hypothesis for aid\
          {indentExpr aid}"
    let some hpV ← findResHyp hyps ``RelSem.Cerb.pointsToBytes 2 addr
      | throwError "seg_auto: no pointsToBytes hypothesis at\
          {indentExpr addr}"
    let hptS := mkIdent (freshHypName hyps "HptDead")
    evalTactic (← `(tactic| seg_scratch1 $hStx $hstId
      $(mkIdent haV) $(mkIdent hpV) $hptS))
    return true
  | `write1 =>
    let fp ← eqFootprint hit.hTy
    let some aid := fp.aids[0]? | throwError "seg_auto: write1 entry \
      {hit.law.name} carries no allocation-lookup hypothesis"
    let some addr := fp.addrs[0]? | throwError "seg_auto: write1 \
      entry {hit.law.name} carries no byte-range hypothesis"
    let some ha ← findResHyp hyps ``RelSem.Cerb.allocIs 2 aid
      | throwError "seg_auto: no allocIs hypothesis for aid\
          {indentExpr aid}"
    let some hp ← findResHyp hyps ``RelSem.Cerb.pointsToBytes 2 addr
      | throwError "seg_auto: no pointsToBytes hypothesis at\
          {indentExpr addr}"
    evalTactic (← `(tactic|
      wp_write1 $hStx $hstId $(mkIdent ha) $(mkIdent hp)))
    return true
  | v =>
    throwError "seg_auto: registered variant '{v}' of {hit.law.name} \
      has no dispatch arm yet (fail-closed)"

/-- `seg_auto`: walk the harness's straight-line segments to the
    terminal, one registry-dispatched step at a time (§5 header;
    fail-closed at any undispatchable joint). -/
elab "seg_auto" : tactic => do
  let mut steps := 0
  let mut progressed := true
  while progressed do
    if (← getGoals).isEmpty then return
    progressed ← segStep
    steps := steps + 1
    if steps > 128 then
      throwError "seg_auto: step limit (128) exceeded — runaway walk"

end RelSem.Seg
