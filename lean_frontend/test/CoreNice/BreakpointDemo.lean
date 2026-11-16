import BreakpointExecution
import ArtifactCompare
import RunOutput

/- Executable midpoint and mutation experiment for composition.c. The heap
   projection reads four bytes of its unique live source allocation x. No
   state serialization or inferred ownership/scope theorem is involved. -/
namespace CoreNiceDiff.BreakpointDemo
open Lean Breakpoints

private instance : LemFuel := ⟨1000000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

private def require (message : String) (condition : Bool) : IO Unit :=
  unless condition do fail s!"breakpoint demo: {message}"

private def named (expected : String) : sym → Bool
  | .Symbol _ _ (.SD_Id actual) => expected == actual
  | _ => false

private def checkTypedShape (prepared : Prepared) : IO Unit := do
  let [(_, (_, _, _, [], body))] :=
    prepared.typed.2.function_definitions.filter (fun (f, _) => named "main" f)
    | fail "expected one parameterless typed AIL main"
  let .AilSblock bindings statements := body.node
    | fail "typed AIL main is not a block"
  let [(x, _)] := bindings
    | fail "typed AIL main must own exactly one binding"
  require "typed AIL binding is not source object x" (match x with
    | .Symbol _ _ (.SD_ObjectAddress "x") => true
    | _ => false)
  let [decl, call, assignment, loop, ret] := statements
    | fail "unexpected typed AIL main statement count"
  match decl.node, call.node, assignment.node, loop.node, ret.node with
  | .AilSdeclaration [(declared, some _)], .AilSexpr _, .AilSexpr _,
      .AilSwhile _ loopBody _, .AilSreturn _ =>
    require "declaration does not initialize main's x binding" (declared == x)
    let .AilSblock [] [bodyStatement] := loopBody.node
      | fail "original typed AIL loop body is not a singleton empty-binding block"
    let .AilSexpr _ := bodyStatement.node
      | fail "original typed AIL loop body is not an expression statement"
    IO.println "PASS: typed AIL main owns x; declaration,expr,expr,while,return; loop body block[]=[expr]"
  | _, _, _, _, _ => fail "unexpected typed AIL main constructor sequence"

private def readX (state : CoreNice.driver_state) : Option Int := do
  let memory := state.layout_state
  let [(_, allocation)] := memory.allocations.toList.filter (fun (id, allocation) =>
    !memory.deadAllocations.contains id && match allocation.prefix_ with
      | .PrefSource _ symbols => symbols.any (fun symbol => match symbol with
          | .Symbol _ _ (.SD_ObjectAddress name) => name == "x"
          | _ => false)
      | _ => false) | none
  if allocation.size != 4 then none
  else CerbMem.bytesToInt (CerbMem.readBytesFrom memory allocation.base 4) true

private abbrev Node := CoreNice.nice_breakpoint_site ×
  CoreNice.expr CoreNice.core_run_annotation × CoreNice.expr CoreNice.core_run_annotation

private def sites (body : CoreNice.expr CoreNice.core_run_annotation) : List Node :=
  ((CoreNice.Incoming.mapExprM (m := StateM (List Node)) (fun _ _ node => do
    match node with
    | .Esseq _ left (.Breakpoint site, right) => modify ((site, left, right) :: ·)
    | _ => pure ()
    return node) {} body).run []).2

private def containsResidual (body expected : CoreNice.expr CoreNice.core_run_annotation) : Bool :=
  ((CoreNice.Incoming.mapExprM (m := StateM Bool) (fun _ annotations node => do
    if (.Expr annotations node : CoreNice.expr CoreNice.core_run_annotation) == expected then set true
    return node) {} body).run false).2

private def mutateState (left : CoreNice.expr CoreNice.core_run_annotation) (skip : Bool)
    (point : Point) : Point :=
  let machine := point.machine
  let state := machine.suspension_state
  let threads := state.core_state0.thread_states.map fun (id, parent, thread) =>
    if id == machine.suspension_thread then
      let arena := if skip then CoreNice.mk_value_e .Vunit else
        CoreNice.mk_sseq_e (CoreNice.mk_empty_pat .BTy_unit) left thread.arena
      (id, parent, { thread with arena })
    else (id, parent, thread)
  { point with machine := { machine with suspension_state := { state with
    core_state0 := { state.core_state0 with thread_states := threads } } } }

private def testAdapter (nodes : List Node) (mutation : String) :
    Choice.Adapter Result CoreNice.driver_result Point CoreNice.step_kind
      CoreNice.driver_error mem_iv_constraint CoreNice.driver_state :=
  let normal := adapter .all
  { normal with continueFrom := fun point =>
    let target := named "main" point.machine.suspension_site.breakpoint_procedure &&
      point.machine.suspension_site.breakpoint_role == .BP_statement_join &&
      readX point.machine.suspension_state == some 1
    if !target then normal.continueFrom point else
      match mutation with
      | "repeat-left" | "skip-suffix" =>
        match nodes.find? (fun node => node.1 == point.machine.suspension_site) with
        | none => nd_return (.incomplete "mutation target missing from artifact")
        | some (_, left, _) => normal.continueFrom (mutateState left (mutation == "skip-suffix") point)
      | "extra-choice" =>
        .ND fun state =>
          let info := CoreNice.SK_misc ["injected breakpoint choice"]
          (.NDnd info [(info, normal.continueFrom point), (info, normal.continueFrom point)], state)
      | "normal" => normal.continueFrom point
      | _ => nd_return (.incomplete "unknown mutation") }

private structure Sample where
  site : CoreNice.nice_breakpoint_site
  x : Int

private def execute (prepared : Prepared) (execution : ExecutionNice) (nodes : List Node)
    (mutation : String) : IO (Choice.Run CoreNice.driver_result CoreNice.driver_error
      CoreNice.driver_state × List Sample) := do
  let header : Choice.Header := {
    input := "composition", prepared := "shared-typed-ail"
    config := toJson "midpoint-experiment", coreBuild := "local"
    coreNiceBuild := "local", origin := "CoreNice" }
  let action := CoreNice.drive_until_breakpoint execution.file.enumDefs execution.file.tagDefs
    false execution.file prepared.argv 1000000
  let mut progress ← (CerberusFresh.forceIO (fun () =>
    Choice.startResumable 1000000 ObservationNice.observer (.record .first) header
      (testAdapter nodes mutation) (advance .all 1000000 0 action) execution.state) : BaseIO _)
  let mut samples : List Sample := []
  repeat
    match progress with
    | .complete result => return (result, samples.reverse)
    | .suspended suspension =>
      let point := suspension.point
      let site := point.machine.suspension_site
      if named "main" site.breakpoint_procedure then
        let some x := readX suspension.state | do
          let allocations := suspension.state.layout_state.allocations.toList.map fun (id, a) =>
            Json.mkObj [("id", toJson id), ("size", toJson a.size), ("prefix", toJson a.prefix_),
              ("dead", toJson (suspension.state.layout_state.deadAllocations.contains id))]
          fail s!"main midpoint {site.breakpoint_id} lacks unique initialized x: {(toJson allocations).compress}"
        let some (_, _, right) := nodes.find? (fun node => node.1 == site)
          | fail "dynamic site absent from source artifact"
        if mutation == "normal" && site.breakpoint_role == .BP_statement_join && x == 1 then
          let some (_, _, thread) := suspension.state.core_state0.thread_states.find?
            (fun (id, _, _) => id == point.machine.suspension_thread)
            | fail "suspended thread missing"
          require "source suffix absent from actual suspended arena"
            (containsResidual thread.arena right)
        samples := { site, x } :: samples
      progress ← (CerberusFresh.forceIO (fun () => Choice.resume suspension) : BaseIO _)

private def dropSite (execution : ExecutionNice) (prepared : Prepared)
    (target : CoreNice.nice_breakpoint_site) : IO ExecutionNice := do
  let transform (_ : sym) (decl : CoreNice.fun_map_decl CoreNice.core_run_annotation) :=
    match decl with
    | .Proc location markers result params body =>
      let body := Id.run <| CoreNice.Incoming.mapExprM (fun _ _ node => pure <| match node with
        | .Esseq pat left (.Breakpoint site, right) =>
          .Esseq pat left (if site == target then (.Continue, right) else (.Breakpoint site, right))
        | other => other) {} body
      .Proc location markers result params body
    | other => other
  let file := { execution.file with funs := fmapMapi transform execution.file.funs }
  let (state, initialSupply) := CoreNice.initial_driver_state_given execution.translatedSupply
    prepared.addressSpaceTop prepared.runDigest file CerbFS.fs_initial_state
  require "mutation changed initial supply" (initialSupply == execution.initialSupply)
  match ({ execution with file, state }).capture true with
  | .ok result => return result
  | .error reason => fail reason

def run (runtime input : String) : IO Unit := do
  let prepared ← prepare runtime input 18446744073709551615 []
  checkTypedShape prepared
  let original ← lowerA prepared
  let execution ← lowerNice prepared
  match ArtifactCompare.compare original execution with
  | .ok () => pure ()
  | .error reason => fail reason
  let execution ← match execution.capture true with
    | .ok result => pure result
    | .error reason => fail reason
  let some main := execution.file.main | fail "missing main"
  let some (.Proc _ _ _ _ body) := fmapLookupBy symbol_compare main execution.file.funs
    | fail "main is not a procedure"
  let nodes := sites body
  let (baseline, samples) ← execute prepared execution nodes "normal"
  let observations (run : Choice.Run CoreNice.driver_result CoreNice.driver_error CoreNice.driver_state) := do
    let outcome ← encodeOutcome ObservationNice.result toJson ObservationNice.streams run
    let effects ← ObservationNice.observer.observeDelta execution.state run.finalState
    pure (outcome, effects)
  let .ok baselineObservations := observations baseline | fail "baseline observation encoding failed"
  let .returned value := baseline.outcome | fail "normal demo did not complete"
  require "unexpected final value" (match value.dres_core_value with
    | .Vloaded (.LVspecified (.OVinteger (.IV _ 6))) => true
    | _ => false)
  let joins := samples.filter (fun s => s.site.breakpoint_role == .BP_statement_join)
  let some target := joins.find? (fun s => s.x == 1) | fail "missing x=1 sequence handoff"
  require "suffix effect absent at cut and later present" (joins.any (fun s => s.x == 3))
  let conditionValues := (samples.filter (fun s => s.site.breakpoint_role == .BP_condition_ready)).map (·.x)
  let bodyValues := (samples.filter (fun s => s.site.breakpoint_role == .BP_loop_body_done)).map (·.x)
  require "condition phases" (conditionValues == [3, 4, 5, 6])
  require "body-to-backedge phases" (bodyValues == [4, 5, 6])
  for sample in samples do
    IO.println (Json.mkObj [("site", toJson sample.site.breakpoint_id),
      ("role", toJson (roleName sample.site.breakpoint_role)),
      ("ailOrigin", toJson sample.site.breakpoint_ail_path), ("x", toJson sample.x)]).compress
  for mutation in ["repeat-left", "skip-suffix", "extra-choice"] do
    let (mutant, _) ← execute prepared execution nodes mutation
    let .ok mutantObservations := observations mutant | fail "mutation observation encoding failed"
    require s!"{mutation} escaped observation"
      (mutantObservations != baselineObservations || mutant.tape.entries != baseline.tape.entries)
    IO.println s!"PASS: rejected injected {mutation}"
  let dropped ← dropSite execution prepared target.site
  let (mutant, missing) ← execute prepared dropped nodes "normal"
  let .ok mutantObservations := observations mutant | fail "lost-site observation encoding failed"
  require "lost-site control changed C effects/outcome/tape"
    (mutantObservations == baselineObservations && mutant.tape.entries == baseline.tape.entries)
  require "lost-site escaped source-to-encounter expectation" (!(missing.any (fun s => s.site == target.site)))
  IO.println "PASS: lost-site control detected by required encounter despite identical C effects"
  IO.println "PASS: actual heap midpoints, pending suffix, source sites and complete artifact erasure"

end CoreNiceDiff.BreakpointDemo

def main (args : List String) : IO Unit := do
  unless (← IO.getEnv "LEAN_ABORT_ON_PANIC") == some "1" do
    throw (IO.userError "LEAN_ABORT_ON_PANIC=1 is required")
  match args with
  | [runtime, input] => CoreNiceDiff.BreakpointDemo.run runtime input
  | _ => throw (IO.userError "usage: corenice-breakpoint-demo RUNTIME CABS-JSON (composition.c)")
