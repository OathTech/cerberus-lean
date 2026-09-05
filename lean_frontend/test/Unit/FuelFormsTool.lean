/-
  FuelFormsTool — the (A)/(B)/(C) classifier of every fuel'd worker
  (fuel-parameter arc C2, 2026-09-04; the consumer's requirement made
  mechanical: refined-cerberus docs/2026-09-04_review-of-fuel-parameter-design.md §2;
  P0 instrument repair 2026-09-05 — whole-project audit F2, record
  lean_frontend/docs/2026-09-05_p0-instruments-record.md §F2).

  Runs at RUNTIME over the compiled environment (`importModules` of the
  modules named on its command line — the exec entries and every generated
  `*_auxiliary` module, so the measured wrappers' obligations are in scope)
  and prints one TSV row per fuel'd worker:

    FUEL_FORM <worker> <form> <reach>/<front> <detail> <hyp>

  where
    worker  = a definition whose name ends in `_lemFuel` (the lem backend's
              fuel'd workers, generated and hand-written), or a CerbND runner
              worker `run*Fuel`;
    form    = MEASURED   — the constant `<f>_measure_sufficient` exists AND has
                           the contract's SHAPE (`obligationShape`, checked in
                           MetaM under the statement's own telescope):
                             ∀ xs… [lemHyp : H] (lemFuel : Nat), μ ≤ lemFuel →
                               worker … lemFuel … = wrapper xs…
                           with (audit M1) the two heads compared by constant
                           name; (lem audit N1 / C4) the fuel binder pinned by
                           its NAME `lemFuel`, the optional hypothesis by its
                           reserved NAME `lemHyp` immediately before it; (C4
                           audit F-A4) every other binder a wrapper argument;
                           and (P0 audit F2) the ARGUMENT CORRESPONDENCE:
                             * the wrapper side is the wrapper applied to
                               exactly the statement's non-reserved binders,
                               in order (positional);
                             * `lemFuel` occurs exactly once on the worker
                               side, at the position of the worker's own
                               parameter named `lemFuel`; every other worker
                               argument is one of the wrapper's input binders
                               (no literal, no other term);
                             * the WRAPPER'S OWN BODY, delta-unfolded and
                               beta-reduced on the statement's binders, is a
                               call of the worker whose arguments equal the
                               worker side's arguments position by position,
                               with the μ of the `≤ lemFuel` hypothesis at the
                               fuel position (syntactically, or definitionally
                               at reducible transparency — reported) — i.e.
                               the lower bound IS the wrapper's actual
                               measure, and the equation relates the worker
                               to the wrapper on the wrapper's own inputs.
                             The generated shells pass `lemFuel` then the
                             wrapper's binders in order; the hand-written
                             CerbMem seams (`alignofCtype_lemFuel lemFuel
                             ambient ambient cty = alignofCtype ambient cty`)
                             pass a binder twice — both are accepted because
                             the check is against the wrapper's body, and the
                             detail reports which (`args=positional` /
                             `args=wrapper-body`).
                           Its axiom cone and the proof's cone are reported in
                           <detail> (`axioms=ok` iff ⊆ {propext,
                           Classical.choice, Quot.sound}); the <hyp> column is
                           the `lemHyp` binder's TYPE pretty-printed
                           (whitespace-normalized), empty for the unconditional
                           form — the policy requires a reviewed register row
                           per hypothesis (scripts/fuel_hypotheses.txt). A
                           same-named constant of ANOTHER shape is
                           `MALFORMED obligation=… : <why>` in <detail> (never
                           MEASURED; the policy is RED on it);
              ABSORBING  — "kill at zero" (P0 relabel; propagation of exhaustion
                           through the successor cases is NOT proved — lem-lean
                           doc/lean-backend/TODO.md row 13, fuel monotonicity):
                           the `<worker>_zero` lemma's statement has the shape
                             ∀ xs…, worker … 0 … = <absorbing element>
                           where (P0 audit F2) the left-hand head IS the worker
                           constant, exactly one worker argument is the literal
                           `0` (`OfNat.ofNat Nat 0` / `Nat.zero`) and it sits at
                           a `Nat` parameter of the worker, and the remaining
                           worker arguments are exactly the lemma's binders,
                           each once (as a set — auto-bound implicits may be
                           permuted); and the right-hand side mentions the fuel
                           atom (`CerbFuel.fuelExhaustedLoc` or
                           `CerbND.fuelExhaustedKill`) under an absorbing head
                           (`NDkilled` for the ND monad, `Killed` for the runner
                           result, `t0.Error` for the undefined monad) and NO
                           value-returning sentinel (`fuelExhausted`,
                           `fuelExhaustedWith`, `failwithI`, `panic`). The
                           lemma's axiom cone is reported (`axioms=ok`, same
                           standard as MEASURED; the policy is RED otherwise).
                           A same-named lemma of another shape is
                           `MALFORMED-ZERO zero=… : <why>` (never ABSORBING;
                           the policy is RED on it);
              AMBIENT    — neither (the opaque value sentinel: a fail-open
                           exhaustion IF reachable);
    reach   = yes/no — whether the worker lies in the kernel constant closure of
              the drive cone (`drive`, `initial_driver_state`, the CerbND runners,
              `CerbCall.driveCall`), closed under mutual blocks: the consumer's
              "(C) not reachable from drive"; `/front` marks membership in the
              front-end pipeline's closure (`desugar` … `convert_file`),
              informational.

  The POLICY (what is RED) lives in scripts/check_fuel_forms.sh, which also
  plant-tests itself on doctored tables and compiled decoy modules; this tool
  is the measurement. Exit 0 unless the environment cannot be loaded or an
  entry constant is missing (fail-closed: a vacuous table is an error, not an
  empty pass).
-/
import Lean
open Lean

/-- The consumer's cone: `drive` and its cold start, the CerbND runners, the
    `--call` entry. -/
def entries : List Name := [`drive, `initial_driver_state, `CerbND.runND, `CerbND.runND1, `CerbND.runND1Trace, `CerbCall.driveCall]
/-- The front-end pipeline entries (check_theorem_axioms.sh's exec-entry set
    minus the drive cone): reported as a second column, informational. -/
def frontEntries : List Name := [`desugar, `annotate_program, `translate, `link, `convert_file]

def isWorker (n : Name) : Bool :=
  match n with
  | .str p s => (s.endsWith "_lemFuel") || (p == `CerbND && s.startsWith "run" && s.endsWith "Fuel")
  | _ => false

def baseName (n : Name) : Name :=
  match n with
  | .str p s => .str p (s.dropRight "_lemFuel".length)
  | _ => n

/-- The mutual block a structurally/well-founded-recursive definition belongs
    to (Lean's equation-info extensions): a mutual block compiles to ONE
    recursor term in which the siblings' NAMES do not occur, so the kernel
    closure must add them explicitly. -/
def mutualSiblings (env : Environment) (n : Name) : List Name :=
  match Lean.Elab.Structural.eqnInfoExt.find? env n with
  | some info => info.declNames.toList
  | none =>
    match Lean.Elab.WF.eqnInfoExt.find? env n with
    | some info => info.declNames.toList
    | none => []

/-- Kernel constant closure of the roots (values and types; matchers, instances
    and auxiliary definitions are constants too), closed under mutual blocks. -/
partial def closure (env : Environment) (roots : List Name) : NameSet := Id.run do
  let mut seen : NameSet := {}
  let mut stack := roots
  while true do
    match stack with
    | [] => break
    | n :: rest =>
      stack := rest
      if seen.contains n then continue
      seen := seen.insert n
      match env.find? n with
      | some ci =>
        for c in ci.getUsedConstantsAsSet do
          if !seen.contains c then stack := c :: stack
        for s in mutualSiblings env n do
          if !seen.contains s then stack := s :: stack
      | none => pure ()
  return seen

/-- The ∀-telescope of a type: the binders (name, type) in order (each type
    with loose bvars referring to earlier binders) and the body. -/
partial def telescope (e : Expr) (acc : Array (Name × Expr) := #[]) : Array (Name × Expr) × Expr :=
  match e with
  | .forallE n ty b _ => telescope b (acc.push (n, ty))
  | e => (acc, e)

/-- Whitespace-normalize a pretty-printed type (the register compares text). -/
def normWs (s : String) : String := Id.run do
  let mut out := ""
  let mut pendingSpace := false
  let mut started := false
  for c in s.toList do
    if c == ' ' || c == '\n' || c == '\t' then
      pendingSpace := true
    else
      if pendingSpace && started then out := out.push ' '
      pendingSpace := false
      started := true
      out := out.push c
  return out

/-- Run a MetaM action over the loaded environment. -/
def runMeta {α : Type} (env : Environment) (act : Lean.Meta.MetaM α) : IO α := do
  let (r, _) ← Lean.Core.CoreM.toIO (Lean.Meta.MetaM.run' act) { fileName := "<fuel-forms>", fileMap := default } { env }
  return r

/-- Pretty-print for messages (single line, whitespace-normalized). -/
def ppE (e : Expr) : Lean.Meta.MetaM String := do
  let fmt ← Lean.Meta.ppExpr e
  return normWs (fmt.pretty 100000)

/-- The literal natural `0`: `OfNat.ofNat Nat 0 _`, `Nat.zero`, or the raw literal. -/
def isLitZero (e : Expr) : Bool :=
  match e.nat? with
  | some 0 => true
  | _ => e.isConstOf ``Nat.zero || (match e with | .lit (.natVal 0) => true | _ => false)

/-- The index of the first worker parameter named `lemFuel` (generated and
    hand-written workers name it so), else none. -/
def workerFuelIndex (workerTy : Expr) : Option Nat :=
  (telescope workerTy).1.findIdx? (fun (nm, _) => nm == `lemFuel)

/-- The CONTRACT SHAPE of a sufficiency obligation — see the header. Checked in
    MetaM under the statement's own telescope (fvars), so the wrapper's body can
    be instantiated on the same binders. Returns (index of the `lemHyp` binder
    if any, argument-correspondence kind, measure-agreement kind) or the FIRST
    mismatch, in this order: heads → `lemFuel` binder → `≤ lemFuel` hypothesis
    → `lemHyp` placement → every non-reserved binder a wrapper argument →
    wrapper side positional → `lemFuel` once on the worker side → every other
    worker argument a wrapper input → `lemFuel` at the worker's own `lemFuel`
    parameter → the wrapper's body is the worker on those very arguments at
    the μ. -/
def obligationShape (ty : Expr) (worker wrapper : Name) : Lean.Meta.MetaM (Except String (Option Nat × String × String)) :=
  Lean.Meta.forallTelescope ty fun fvars body => do
    let n := fvars.size
    let mut names : Array Name := #[]
    for fv in fvars do names := names.push (← fv.fvarId!.getUserName)
    let some (_, lhs, rhs) := body.eq? | return .error "conclusion is not an equation"
    match lhs.getAppFn with
    | .const c _ => if c != worker then return .error s!"left-hand head `{c}` is not the worker `{worker}`"
    | _ => return .error "left-hand side is not an application of the worker"
    let wrapperLevels ← match rhs.getAppFn with
    | .const c us => if c != wrapper then return .error s!"right-hand head `{c}` is not the wrapper `{wrapper}`" else pure us
    | _ => return .error "right-hand side is not an application of the wrapper"
    -- the fuel binder, by NAME
    let some jFuel := names.findIdx? (· == `lemFuel) | return .error "no binder named `lemFuel`"
    let fuel := fvars[jFuel]!
    unless (← Lean.Meta.inferType fuel).isConstOf ``Nat do return .error "the `lemFuel` binder is not a `Nat`"
    -- the `μ ≤ lemFuel` hypothesis on that very binder (first such binder after it)
    let mut kLe? : Option Nat := none
    let mut mu? : Option Expr := none
    for k in [jFuel + 1:n] do
      if kLe?.isNone then
        let bt ← Lean.Meta.inferType fvars[k]!
        if bt.isAppOfArity ``LE.le 4 then
          let args := bt.getAppArgs
          if args[3]! == fuel then
            kLe? := some k
            mu? := some args[2]!
    let some kLe := kLe? | return .error "no hypothesis `_ ≤ lemFuel` on the `lemFuel` binder"
    let some mu := mu? | return .error "no hypothesis `_ ≤ lemFuel` on the `lemFuel` binder"
    -- the optional hypothesis binder, by its reserved NAME, immediately before lemFuel
    let jHyp? := names.findIdx? (· == `lemHyp)
    if let some jHyp := jHyp? then
      if jHyp + 1 != jFuel then return .error "a binder named `lemHyp` that is not immediately before `lemFuel`"
    -- the wrapper's inputs: every non-reserved binder, in order
    let inputIdx := ((List.range n).filter fun j => j != jFuel && j != kLe && jHyp? != some j).toArray
    let inputs := inputIdx.map (fvars[·]!)
    let rhsArgs := rhs.getAppArgs
    -- (C4 audit F-A4) every non-reserved binder is a wrapper argument
    for j in inputIdx do
      unless rhsArgs.contains fvars[j]! do
        return .error s!"binder `{names[j]!}` (#{j}) is neither reserved (`lemHyp`/`lemFuel`/the `≤ lemFuel` hypothesis) nor an argument of the wrapper side"
    -- (P0 F2) the wrapper side is the wrapper on exactly those binders, in order
    if rhsArgs.size != inputs.size then
      return .error s!"the wrapper side has {rhsArgs.size} arguments but the statement has {inputs.size} non-reserved binders — the wrapper side must be the wrapper applied to the statement's own binders, in order, and nothing else"
    for i in [:inputs.size] do
      if rhsArgs[i]! != inputs[i]! then
        return .error s!"wrapper argument #{i} is `{← ppE rhsArgs[i]!}`, not the binder `{names[inputIdx[i]!]!}` — the wrapper side must be the wrapper applied to the statement's own binders, in order"
    -- (P0 F2) the worker side: `lemFuel` exactly once, at the worker's `lemFuel` parameter
    let lhsArgs := lhs.getAppArgs
    let fuelPositions := (List.range lhsArgs.size).filter fun i => lhsArgs[i]! == fuel
    let p ← match fuelPositions with
      | [p] => pure p
      | [] => return .error "the `lemFuel` binder is not an argument of the worker side"
      | _ => return .error "the `lemFuel` binder occurs more than once on the worker side"
    for i in [:lhsArgs.size] do
      if i != p then
        unless inputs.contains lhsArgs[i]! do
          return .error s!"worker argument #{i} is `{← ppE lhsArgs[i]!}`, not one of the wrapper's input binders — the obligation must relate the worker to the wrapper on the SAME inputs"
    let some wci := (← getEnv).find? worker | return .error s!"worker `{worker}` not found"
    let wparams := (telescope wci.type).1
    match workerFuelIndex wci.type with
    | none => return .error s!"the worker `{worker}` has no parameter named `lemFuel`"
    | some wf =>
      if p != wf then
        let pname := if h : p < wparams.size then s!"`{wparams[p].1}`" else "(out of range)"
        return .error s!"wrong fuel position: `lemFuel` is passed as worker argument #{p} ({pname}), but the worker's `lemFuel` parameter is #{wf}"
    -- (P0 F2) the wrapper's own body on these binders is the worker on these very arguments at μ
    let some wrci := (← getEnv).find? wrapper | return .error s!"wrapper `{wrapper}` not found"
    unless wrci.hasValue do return .error s!"the wrapper `{wrapper}` has no definitional body"
    let call := ((wrci.instantiateValueLevelParams! wrapperLevels).beta rhsArgs).headBeta.consumeMData
    match call.getAppFn with
    | .const c _ =>
      if c != worker then return .error s!"the wrapper `{wrapper}` does not call the worker `{worker}`: on these inputs its body is a call of `{c}`"
    | h => return .error s!"the wrapper `{wrapper}` does not call the worker `{worker}`: on these inputs its body has head `{← ppE h}`"
    let callArgs := call.getAppArgs
    if callArgs.size != lhsArgs.size then
      return .error s!"the wrapper `{wrapper}` calls the worker with {callArgs.size} arguments, the obligation's worker side has {lhsArgs.size}"
    let mut measureKind := "syntactic"
    for i in [:lhsArgs.size] do
      if i == p then
        if callArgs[p]! != mu then
          let ok ← Lean.Meta.withTransparency .reducible <| Lean.Meta.isDefEq callArgs[p]! mu
          unless ok do
            return .error s!"the lower bound `{← ppE mu}` of the `≤ lemFuel` hypothesis is not the wrapper's measure: `{wrapper}` calls the worker at fuel `{← ppE callArgs[p]!}`"
          measureKind := "defeq"
      else if callArgs[i]! != lhsArgs[i]! then
        return .error s!"worker argument #{i}: the obligation passes `{← ppE lhsArgs[i]!}`, but the wrapper `{wrapper}` passes `{← ppE callArgs[i]!}` — the equation does not relate the worker to the wrapper on the same inputs"
    let positional := lhsArgs.toList.eraseIdx p == rhsArgs.toList
    return .ok (jHyp?, if positional then "positional" else "wrapper-body", measureKind)

/-- The `lemHyp` binder's type, pretty-printed under the obligation's own
    binder names (MetaM `forallTelescope`), whitespace-normalized. -/
def ppHyp (ty : Expr) (jHyp : Nat) : Lean.Meta.MetaM String :=
  Lean.Meta.forallTelescope ty fun fvars _ => do
    ppE (← Lean.Meta.inferType fvars[jHyp]!)

def absorbingHeads : List Name := [`nd_action.NDkilled, `nd_status.Killed, `t0.Error]
def fuelAtoms : List Name := [`CerbFuel.fuelExhaustedLoc, `CerbND.fuelExhaustedKill]
def valueSentinels : List Name := [`fuelExhausted, `fuelExhaustedWith, `failwithI, `panic, `panicCore]

/-- The `_zero` lemma's LEFT-HAND shape (P0 audit F2: the audit's decoy
    `review_bad_lemFuel_zero` stated a fact about `CerbND.runNDFuel`, not about
    `review_bad_lemFuel`, and was counted ABSORBING). Returns the right-hand
    side for the head checks, or the first mismatch. -/
def zeroShape (ty : Expr) (worker : Name) : Lean.Meta.MetaM (Except String Expr) :=
  Lean.Meta.forallTelescope ty fun fvars body => do
    let some (_, lhs, rhs) := body.eq? | return .error "conclusion is not an equation"
    match lhs.getAppFn with
    | .const c _ => if c != worker then return .error s!"left-hand head `{c}` is not the worker `{worker}`"
    | _ => return .error "left-hand side is not an application of the worker"
    let args := lhs.getAppArgs
    let zeros := (List.range args.size).filter fun i => isLitZero args[i]!
    let p ← match zeros with
      | [p] => pure p
      | [] => return .error "no literal `0` among the worker's arguments (the lemma must state the worker at fuel 0)"
      | _ => return .error "more than one literal `0` among the worker's arguments"
    let some wci := (← getEnv).find? worker | return .error s!"worker `{worker}` not found"
    let wparams := (telescope wci.type).1
    if h : p < wparams.size then
      unless wparams[p].2.isConstOf ``Nat do
        return .error s!"the literal `0` is passed as worker argument #{p} (`{wparams[p].1}`), which is not a `Nat` parameter"
    else
      return .error s!"the literal `0` is passed as worker argument #{p}, beyond the worker's {wparams.size} parameters"
    -- the remaining arguments are exactly the lemma's binders, each once (as a
    -- SET: auto-bound implicits may be ordered differently in the worker and the
    -- lemma — CerbND.runND1TraceFuel_zero — and a permutation of distinct
    -- universally quantified binders is still fully general)
    let others := args.toList.eraseIdx p
    if others.length != fvars.size then
      return .error s!"the worker's non-fuel arguments ({others.length}) are not the lemma's {fvars.size} binders"
    for a in others do
      unless fvars.contains a do
        return .error s!"worker argument `{← ppE a}` is not one of the lemma's binders (the lemma must state the worker at fuel 0 on universally quantified inputs)"
    if others.eraseDups.length != others.length then
      return .error "a binder is passed to the worker more than once"
    return .ok rhs

def okAxioms : List Name := [`propext, `Classical.choice, `Quot.sound]

def axiomsOf (env : Environment) (c : Name) : IO (Array Name) := do
  let (axs, _) ← Lean.Core.CoreM.toIO (Lean.collectAxioms c) { fileName := "<fuel-forms>", fileMap := default } { env }
  return axs

def axiomsVerdict (axs : Array Name) : String :=
  if axs.all (fun a => okAxioms.contains a) then "ok" else s!"BAD[{axs.toList}]"

unsafe def main (args : List String) : IO UInt32 := do
  if args.isEmpty then
    IO.eprintln "fuel-forms-tool: usage: fuel-forms-tool <Module> ... (the modules to import; run under `lake env`)"
    return 2
  initSearchPath (← findSysroot)
  let mods := args.filter (fun m => !m.isEmpty)
  for m in mods do
    if (String.toName m).isAnonymous then
      IO.eprintln s!"fuel-forms-tool: FAIL — module argument `{m}` is not a valid module name"
      return 2
  let imports : Array Import := mods.toArray.map fun m => { module := String.toName m }
  IO.eprintln s!"fuel-forms-tool: importing {imports.size} modules"

  -- `loadExts`: the environment extensions that need the interpreter (the
  -- `app_unexpander` table among them) are loaded, so the `hyp` column is
  -- printed with notation (`2 ≤ b`, not `instLENat.le 2 b`) — C4. This is
  -- why `main` is `unsafe` (`enableInitializersExecution` is): an
  -- INSTRUMENT-side unsafe, pinned in scripts/unsafebaseio_allowlist.txt;
  -- nothing in the semantics depends on this executable.
  Lean.enableInitializersExecution
  let env ← importModules imports {} 0 (loadExts := true)
  -- entries must exist (fail-closed)
  for e in entries ++ frontEntries do
    if env.find? e |>.isNone then
      IO.eprintln s!"fuel-forms-tool: FAIL — exec entry `{e}` not found in the loaded environment"
      return 1
  let reach := closure env entries
  let reachFront := closure env frontEntries
  -- every fuel'd worker
  let mut workers : Array Name := #[]
  for (n, ci) in env.constants.toList do
    if isWorker n then
      match ci with
      | .defnInfo _ => workers := workers.push n
      | _ => pure ()
  let sorted := workers.qsort (fun a b => a.toString < b.toString)
  if sorted.size < 30 then
    IO.eprintln s!"fuel-forms-tool: FAIL — only {sorted.size} fuel'd workers found (vacuity guard; is the tree regenerated / are the right modules imported?)"
    return 1
  IO.println "FUEL_FORMS_LEGEND\tMEASURED = obligation `<f>_measure_sufficient` of the contract's shape (heads, lemFuel/lemHyp binders, argument correspondence against the wrapper's own body, μ = the wrapper's measure), cones reported\tABSORBING = kill at zero (the `_zero` lemma: the worker at literal fuel 0 on its own binders IS the monad's absorbing element; propagation of exhaustion through the successor cases is NOT proved — lem TODO 13)\tAMBIENT = neither"
  let mut nMeasured := 0; let mut nAbsorbing := 0; let mut nAmbientReach := 0; let mut nAmbientUnreach := 0
  let mut nHyp := 0
  for w in sorted do
    let f := baseName w
    let obl := Name.str f.getPrefix (f.getString! ++ "_measure_sufficient")
    let zero := Name.str w.getPrefix (w.getString! ++ "_zero")
    let isReach := reach.contains w
    let reachS := (if isReach then "yes" else "no") ++ (if reachFront.contains w then "/front" else "/-")
    let mut form := "AMBIENT"; let mut detail := ""; let mut hyp := ""
    if let some oci := env.find? obl then
     match ← runMeta env (obligationShape oci.type w f) with
     | Except.error why =>
      -- the NAME matches but the TYPE is not the contract's statement (audit M1):
      -- never MEASURED; flagged for the policy (RED)
      detail := s!"MALFORMED obligation={obl}: {why}"
     | Except.ok (jHyp?, argsKind, muKind) =>
      form := "MEASURED"
      if let some jHyp := jHyp? then
        hyp ← runMeta env (ppHyp oci.type jHyp)
        nHyp := nHyp + 1
      let axs ← axiomsOf env obl
      -- the hand-written proof constant the obligation delegates to
      let target := f.getString! ++ "_measure_sufficient"
      let proofs := env.constants.toList.filter fun (n, _) =>
        (match n with | .str _ s => s == target | _ => false) && n != obl
      let mut pv := ""
      for (pn, _) in proofs do
        let pax ← axiomsOf env pn
        pv := pv ++ s!" proof={pn}:{axiomsVerdict pax}"
      detail := s!"obligation={obl} axioms={axiomsVerdict axs}{pv} args={argsKind} measure={muKind}"
      nMeasured := nMeasured + 1
    if form == "AMBIENT" && !detail.startsWith "MALFORMED" then
      match env.find? zero with
      | some zci =>
        match ← runMeta env (zeroShape zci.type w) with
        | Except.error why => detail := s!"MALFORMED-ZERO zero={zero}: {why}"
        | Except.ok rhs =>
          let cs := rhs.getUsedConstants
          let hasAtom := cs.any (fun c => fuelAtoms.contains c)
          let hasHead := cs.any (fun c => absorbingHeads.contains c)
          let hasSentinel := cs.any (fun c => valueSentinels.contains c)
          if hasAtom && hasHead && !hasSentinel then
            form := "ABSORBING"; nAbsorbing := nAbsorbing + 1
            let zax ← axiomsOf env zero
            detail := s!"zero={zero} heads={cs.toList.filter (fun c => absorbingHeads.contains c || fuelAtoms.contains c)} axioms={axiomsVerdict zax}"
          else
            detail := s!"zero={zero} rhs-consts={cs.toList}"
      | none => detail := "no _zero lemma"
    -- every AMBIENT row (a MALFORMED obligation or _zero lemma included) is
    -- counted once, by reachability
    if form == "AMBIENT" then
      if isReach then nAmbientReach := nAmbientReach + 1 else nAmbientUnreach := nAmbientUnreach + 1
    let shown := (privateToUserName? w).getD w
    IO.println s!"FUEL_FORM\t{shown}\t{form}\t{reachS}\t{detail}\t{hyp}"
  IO.println s!"FUEL_FORMS_SUMMARY\tworkers={sorted.size}\tmeasured={nMeasured}\tmeasured_under_hyp={nHyp}\tabsorbing={nAbsorbing}\tambient_reachable={nAmbientReach}\tambient_unreachable={nAmbientUnreach}\tclosure_size={reach.size}"
  return 0
