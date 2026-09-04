/-
  FuelFormsTool — the (A)/(B)/(C) classifier of every fuel'd worker
  (fuel-parameter arc C2, 2026-09-04; the consumer's requirement made
  mechanical: refined-cerberus docs/2026-09-04_review-of-fuel-parameter-design.md §2).

  Runs at RUNTIME over the compiled environment (`importModules` of the
  modules named on its command line — the exec entries and every generated
  `*_auxiliary` module, so the measured wrappers' obligations are in scope)
  and prints one TSV row per fuel'd worker:

    FUEL_FORM <worker> <form> <reach>/<front> <detail>

  where
    worker  = a definition whose name ends in `_lemFuel` (the lem backend's
              fuel'd workers, generated and hand-written), or a CerbND runner
              worker `run*Fuel`;
    form    = MEASURED   — the constant `<f>_measure_sufficient` exists (the
                           generated obligation, proved in the hand-written
                           `<Module>_lemMeasureProofs`); its axiom cone and the
                           proof's cone are reported in <detail> (`axioms=ok` iff
                           ⊆ {propext, Classical.choice, Quot.sound});
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

  let env ← importModules imports {} 0
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
  for w in sorted do
    let f := baseName w
    let obl := Name.str f.getPrefix (f.getString! ++ "_measure_sufficient")
    let zero := Name.str w.getPrefix (w.getString! ++ "_zero")
    let isReach := reach.contains w
    let reachS := (if isReach then "yes" else "no") ++ (if reachFront.contains w then "/front" else "/-")
    let mut form := "AMBIENT"; let mut detail := ""
    if let some _ := env.find? obl then
      form := "MEASURED"
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
    else
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
    IO.println s!"FUEL_FORM\t{shown}\t{form}\t{reachS}\t{detail}"
  IO.println s!"FUEL_FORMS_SUMMARY\tworkers={sorted.size}\tmeasured={nMeasured}\tabsorbing={nAbsorbing}\tambient_reachable={nAmbientReach}\tambient_unreachable={nAmbientUnreach}\tclosure_size={reach.size}"
  return 0
