/-
  FuelFormsTool — the (A)/(B)/(C) classifier of every fuel'd worker
  (fuel-parameter arc C2, 2026-09-04; the consumer's requirement made
  mechanical: refined-cerberus docs/2026-09-04_review-of-fuel-parameter-design.md §2).

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
                           the contract's SHAPE (audit M1; `obligationShape`:
                           `∀ …, [lemHyp : H →] μ ≤ lemFuel → worker lemFuel … = wrapper …`,
                           the worker/wrapper constants compared by name as the
                           heads of the two sides, the fuel binder pinned by its
                           NAME `lemFuel` (lem audit N1, C4), the optional
                           hypothesis binder pinned by its reserved NAME `lemHyp`
                           immediately before `lemFuel` (lem-lean's `assuming`
                           form, 2026-09-05)); its axiom cone and the proof's cone
                           are reported in <detail> (`axioms=ok` iff ⊆ {propext,
                           Classical.choice, Quot.sound}); the <hyp> column is the
                           `lemHyp` binder's TYPE pretty-printed (whitespace-
                           normalized), empty for the unconditional form — the
                           policy requires a reviewed register row per hypothesis
                           (scripts/fuel_hypotheses.txt). A same-named constant
                           of ANOTHER type is `MALFORMED …` in <detail> (never
                           MEASURED; the policy is RED on it);
              ABSORBING  — the `<worker>_zero` lemma's right-hand side is the
                           declared absorbing element of its monad: it mentions
                           the fuel atom (`CerbFuel.fuelExhaustedLoc` or
                           `CerbND.fuelExhaustedKill`) under an absorbing head
                           (`NDkilled` for the ND monad, `Killed` for the runner
                           result, `t0.Error` for the undefined monad) and NO
                           value-returning sentinel (`fuelExhausted`,
                           `fuelExhaustedWith`, `failwithI`, `panic`);
              AMBIENT    — neither (the opaque value sentinel: a fail-open
                           exhaustion IF reachable);
    reach   = yes/no — whether the worker lies in the kernel constant closure of
              the drive cone (`drive`, `initial_driver_state`, the CerbND runners,
              `CerbCall.driveCall`), closed under mutual blocks: the consumer's
              "(C) not reachable from drive"; `/front` marks membership in the
              front-end pipeline's closure (`desugar` … `convert_file`),
              informational.

  The POLICY (what is RED) lives in scripts/check_fuel_forms.sh, which also
  plant-tests itself on doctored tables; this tool is the measurement. Exit 0
  unless the environment cannot be loaded or an entry constant is missing
  (fail-closed: a vacuous table is an error, not an empty pass).
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

def stripForalls : Expr → Expr
  | .forallE _ _ b _ => stripForalls b
  | e => e

/-- The ∀-telescope of a type: the binders (name, type) in order (each type
    with loose bvars referring to earlier binders) and the body. -/
partial def telescope (e : Expr) (acc : Array (Name × Expr) := #[]) : Array (Name × Expr) × Expr :=
  match e with
  | .forallE n ty b _ => telescope b (acc.push (n, ty))
  | e => (acc, e)

/-- The CONTRACT SHAPE of a sufficiency obligation (audit M1: a same-named
    theorem of any other type must not count; lem audit N1 / C4: the fuel
    binder is pinned by NAME, and the hypothesis-carrying form is recognized
    by its reserved binder): after the ∀-telescope the conclusion is
    `worker … = wrapper …` with the two constants COMPARED BY NAME as the heads
    of the two sides; a binder NAMED `lemFuel` of type `Nat` occurs as an
    argument of the worker's side; a later binder is `_ ≤ lemFuel` on that very
    binder (`LE.le _ _ _ lemFuel`); IF a binder named `lemHyp` exists it is
    immediately before `lemFuel` (lem-lean reserves the name, so no user
    variable can produce the mark); and EVERY other binder is an argument of
    the wrapper side (C4 audit F-A4: an extra unnamed Prop binder would be an
    unregistered second hypothesis). This is exactly how the generated
    `<Module>_auxiliary` shells state it (`theorem f_measure_sufficient (xs…)
    [(lemHyp : H)] (lemFuel : Nat) (lemMeasureLe : μ ≤ lemFuel) : f_lemFuel
    lemFuel xs… = f xs…`). Returns the index of the `lemHyp` binder (none for
    the unconditional form), or the mismatch. -/
def obligationShape (ty : Expr) (worker wrapper : Name) : Except String (Option Nat) := do
  let (binders, body) := telescope ty
  let n := binders.size
  let some (_, lhs, rhs) := body.eq? | throw "conclusion is not an equation"
  match lhs.getAppFn with
  | .const c _ => if c != worker then throw s!"left-hand head `{c}` is not the worker `{worker}`"
  | _ => throw "left-hand side is not an application of the worker"
  match rhs.getAppFn with
  | .const c _ => if c != wrapper then throw s!"right-hand head `{c}` is not the wrapper `{wrapper}`"
  | _ => throw "right-hand side is not an application of the wrapper"
  -- the fuel binder, by NAME
  let some jFuel := binders.findIdx? (fun (nm, _) => nm == `lemFuel) | throw "no binder named `lemFuel`"
  let isNat := match binders[jFuel]!.2 with | .const c _ => c == ``Nat | _ => false
  if !isNat then throw "the `lemFuel` binder is not a `Nat`"
  -- binder j is bvar (n - 1 - j) in the conclusion
  if !(lhs.getAppArgs.any fun a => a == .bvar (n - 1 - jFuel)) then
    throw "the `lemFuel` binder is not an argument of the worker side"
  -- a `≤ lemFuel` hypothesis on that binder: at binder k > jFuel, lemFuel is bvar (k - 1 - jFuel)
  let mut kLe? : Option Nat := none
  for k in [jFuel + 1:n] do
    let bt := binders[k]!.2
    let isLe := match bt.getAppFn with | .const c _ => c == ``LE.le | _ => false
    if isLe && kLe?.isNone then
      let args := bt.getAppArgs
      if args.size == 4 && args[3]! == .bvar (k - 1 - jFuel) then kLe? := some k
  let some kLe := kLe? | throw "no hypothesis `_ ≤ lemFuel` on the `lemFuel` binder"
  -- the optional hypothesis binder, by its reserved NAME, immediately before lemFuel
  let jHyp? := binders.findIdx? (fun (nm, _) => nm == `lemHyp)
  if let some jHyp := jHyp? then
    if jHyp + 1 != jFuel then throw "a binder named `lemHyp` that is not immediately before `lemFuel`"
  -- C4 audit F-A4: EVERY other binder is an argument of the wrapper side (the
  -- statement quantifies exactly the wrapper's parameters — an extra Prop
  -- binder would be an unregistered second hypothesis)
  let rhsArgs := rhs.getAppArgs
  for j in [:n] do
    if j != jFuel && j != kLe && jHyp? != some j then
      if !(rhsArgs.any fun a => a == .bvar (n - 1 - j)) then
        throw s!"binder `{binders[j]!.1}` (#{j}) is neither reserved (`lemHyp`/`lemFuel`/the `≤ lemFuel` hypothesis) nor an argument of the wrapper side"
  return jHyp?

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

/-- The `lemHyp` binder's type, pretty-printed under the obligation's own
    binder names (MetaM `forallTelescope`), whitespace-normalized. -/
def ppHyp (env : Environment) (ty : Expr) (jHyp : Nat) : IO String := do
  let act : Lean.Meta.MetaM String := Lean.Meta.forallTelescope ty fun fvars _ => do
    let t ← Lean.Meta.inferType fvars[jHyp]!
    let fmt ← Lean.PrettyPrinter.ppExpr t
    return normWs (fmt.pretty 100000)
  let (s, _) ← Lean.Core.CoreM.toIO (Lean.Meta.MetaM.run' act) { fileName := "<fuel-forms>", fileMap := default } { env }
  return s

def absorbingHeads : List Name := [`nd_action.NDkilled, `nd_status.Killed, `t0.Error]
def fuelAtoms : List Name := [`CerbFuel.fuelExhaustedLoc, `CerbND.fuelExhaustedKill]
def valueSentinels : List Name := [`fuelExhausted, `fuelExhaustedWith, `failwithI, `panic, `panicCore]

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
     match obligationShape oci.type w f with
     | .error why =>
      -- the NAME matches but the TYPE is not the contract's statement (audit M1):
      -- never MEASURED; flagged for the policy (RED)
      detail := s!"MALFORMED obligation={obl}: {why}"
     | .ok jHyp? =>
      form := "MEASURED"
      if let some jHyp := jHyp? then
        hyp ← ppHyp env oci.type jHyp
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
      detail := s!"obligation={obl} axioms={axiomsVerdict axs}{pv}"
      nMeasured := nMeasured + 1
    if form == "AMBIENT" && !detail.startsWith "MALFORMED" then
      match env.find? zero with
      | some zci =>
        let concl := stripForalls zci.type
        match concl.eq? with
        | some (_, _, rhs) =>
          let cs := rhs.getUsedConstants
          let hasAtom := cs.any (fun c => fuelAtoms.contains c)
          let hasHead := cs.any (fun c => absorbingHeads.contains c)
          let hasSentinel := cs.any (fun c => valueSentinels.contains c)
          if hasAtom && hasHead && !hasSentinel then
            form := "ABSORBING"; nAbsorbing := nAbsorbing + 1
            detail := s!"zero={zero} heads={cs.toList.filter (fun c => absorbingHeads.contains c || fuelAtoms.contains c)}"
          else
            detail := s!"zero={zero} rhs-consts={cs.toList}"
        | none => detail := s!"zero={zero} (not an equation)"
      | none => detail := "no _zero lemma"
      if form == "AMBIENT" then
        if isReach then nAmbientReach := nAmbientReach + 1 else nAmbientUnreach := nAmbientUnreach + 1
    let shown := (privateToUserName? w).getD w
    IO.println s!"FUEL_FORM\t{shown}\t{form}\t{reachS}\t{detail}\t{hyp}"
  IO.println s!"FUEL_FORMS_SUMMARY\tworkers={sorted.size}\tmeasured={nMeasured}\tmeasured_under_hyp={nHyp}\tabsorbing={nAbsorbing}\tambient_reachable={nAmbientReach}\tambient_unreachable={nAmbientUnreach}\tclosure_size={reach.size}"
  return 0
