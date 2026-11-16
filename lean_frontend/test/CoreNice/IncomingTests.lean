import CoreNice.Core_run
import CoreNice.Core_reduction
import CoreNice.Driver

/- Executable tests of the actual substitution and environment jump rules.
   These are differential-testing instruments, not correspondence theorems. -/
namespace CoreNice.IncomingTests

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

private def check (label : String) (condition : Bool) : IO Unit :=
  unless condition do throw (IO.Error.userError s!"incoming check failed: {label}")

private def procedure : sym := .Symbol "incoming-test" 1 (.SD_Id "procedure")
private def aliasProcedure : sym := .Symbol "incoming-test" 2 (.SD_Id "alias")
private def destination : sym := .Symbol "incoming-test" 3 (.SD_Id "destination")
private def parameter : sym := .Symbol "incoming-test" 4 (.SD_Id "parameter")
private def absentLabel : sym := .Symbol "incoming-test" 5 (.SD_Id "absent")
private def jumpLocation : CerbLocation.Loc := .other "incoming-test:jump"
private def labelLocation : CerbLocation.Loc := .other "incoming-test:label"
private def jump (origin : Nat := 17) : nice_jump_info := ⟨origin, jumpLocation⟩
private def incoming (origins : List Nat) : nice_label_info := ⟨origins, labelLocation⟩
private def unitPE : pexpr := .Pexpr [] () (.PEval .Vunit)
private def unitExpr : expr core_run_annotation := .Expr [] (.Epure unitPE)
private def runExpr (origin : Nat := 17) (args : List pexpr := [])
    (label : sym := destination) : expr core_run_annotation :=
  .Expr [] (.Erun default label args (jump origin))

private def saved (origins : List Nat) (withParam : Bool := false) : expr core_run_annotation :=
  .Expr [] (.Esave (destination, .BTy_unit)
    (if withParam then [(parameter, ((.BTy_unit, none), unitPE))] else [])
    unitExpr (incoming origins))

private def fileFor (body : expr core_run_annotation) : file core_run_annotation :=
  { (default : file core_run_annotation) with
    funs := Lem_Map.fromList [(procedure, .Proc .unknown none .BTy_unit [] body)] }

private def stateFor (body : expr core_run_annotation) : driver_state :=
  (initial_driver_state_given 100 65535 "incoming-test" (fileFor body) CerbFS.fs_initial_state).1

private def threadFor (legacy : Bool) (arena : expr core_run_annotation)
    (proc : sym := procedure) : thread_state := {
  arena
  stack0 := if legacy then .Stack_cons (some proc) [] .Stack_empty else .Stack_empty
  errno := CerbMem.nullPtrval signed_int
  env := [fmapEmpty]
  current_proc_opt := some proc
  exec_loc := .ELoc_normal []
  current_loc := .unknown }

private abbrev StepResult := exceptM (t0 thread_state × core_run_state) core_run_cause

/-- Execute the closure returned by the real jump rule; require one existing
    semantic step rather than accepting a helper's isolated membership result. -/
private def execute (legacy : Bool) (state : driver_state) (thread : thread_state)
    (externs : Fmap sym sym := fmapEmpty) : IO StepResult := do
  if legacy then
    match core_thread_step2 fmapEmpty fmapEmpty state.layout_state state.core_file externs
        fmapEmpty 0 (none, thread) with
    | [.Step_tau "Erun" .TSK_Misc action] => pure (action state.core_run_state0)
    | [.Step_tau "Eif (then)" .TSK_Misc action] => pure (action state.core_run_state0)
    | [.Step_eval _ action] => pure (action state.core_run_state0)
    | _ => throw (IO.Error.userError "legacy rule did not produce one expected semantic step")
  else
    match step_ctx fmapEmpty fmapEmpty state.layout_state state.core_file externs 0 (none, thread) with
    | [.Step_with_runstate2 _ action] => pure (action state.core_run_state0)
    | [.Step_tau2 _ _ next] => pure (.Result (.Defined next, state.core_run_state0))
    | _ => throw (IO.Error.userError "optimized rule did not produce one expected semantic step")

private def expectSuccess (label : String) (result : StepResult)
    (expected : expr core_run_annotation := unitExpr) : IO Unit := do
  match result with
  | .Result (.Defined next, _) => check label (next.arena == expected)
  | _ => throw (IO.Error.userError s!"{label}: expected successful transition")

private def expectFault (label : String) (result : StepResult)
    (origin : Nat) (permitted : List Nat) : IO Unit := do
  match result with
  | .Exception (.NiceFault (.IncomingOriginDenied fault)) =>
    check s!"{label}: resolved procedure" (fault.fault_procedure == procedure)
    check s!"{label}: actual jump metadata" (fault.fault_jump == jump origin)
    check s!"{label}: resolved destination" (fault.fault_label == destination)
    check s!"{label}: exact label metadata" (fault.fault_incoming == incoming permitted)
  | _ => throw (IO.Error.userError s!"{label}: expected typed IncomingOriginDenied")

private def ruleTests (legacy : Bool) : IO Unit := do
  let rule := if legacy then "core_run" else "core_reduction"
  let good := stateFor (saved [11, 17, 29])
  let denied := stateFor (saved [11, 29])
  expectSuccess s!"{rule}: permitted jump" (← execute legacy good (threadFor legacy (runExpr)))
  expectFault s!"{rule}: removed taken origin"
    (← execute legacy denied (threadFor legacy (runExpr))) 17 [11, 29]
  expectFault s!"{rule}: fresh wrong origin"
    (← execute legacy good (threadFor legacy (runExpr 101))) 101 [11, 17, 29]
  let aliases := Lem_Map.fromList [(aliasProcedure, procedure)]
  expectFault s!"{rule}: alias resolution payload"
    (← execute legacy denied (threadFor legacy (runExpr) aliasProcedure) aliases) 17 [11, 29]
  let noOrigins := stateFor (saved [])
  expectSuccess s!"{rule}: normal Esave entry needs no incoming origin"
    (← execute legacy noOrigins (threadFor legacy (saved [])))
  let untaken := .Expr [] (.Eif (.Pexpr [] () (.PEval .Vtrue)) unitExpr (runExpr))
  expectSuccess s!"{rule}: forbidden untaken edge does not fault"
    (← execute legacy noOrigins (threadFor legacy untaken))
  let arity := ← execute legacy noOrigins (threadFor legacy (runExpr 17 [unitPE]))
  match arity with
  | .Exception (.Illformed_program message) =>
    check s!"{rule}: arity precedence"
      (message == "Erun: the argument list does not fit the continuation's parameters")
  | _ => throw (IO.Error.userError s!"{rule}: wrong arity must precede the incoming check")
  let badArg : pexpr := .Pexpr [] () (.PEundef (.other "argument-must-not-evaluate") .UB001)
  let parameterized := stateFor (saved [11, 29] true)
  expectFault s!"{rule}: denied check precedes argument handling"
    (← execute legacy parameterized (threadFor legacy (runExpr 17 [badArg]))) 17 [11, 29]
  if !legacy then
    let allowedArg := stateFor (saved [17] true)
    match ← execute legacy allowedArg (threadFor legacy (runExpr 17 [badArg])) with
    | .Result (.Undef location reasons, _) =>
      check "argument UB positive control"
        (location == .other "argument-must-not-evaluate" && reasons == [.UB001])
    | _ => throw (IO.Error.userError "permitted optimized jump must evaluate the UB argument")
  for _ in [0:4] do
    expectSuccess s!"{rule}: static origin reusable"
      (← execute legacy good (threadFor legacy (runExpr)))
  IO.println s!"PASS: {rule}: 12 actual transitions; typed payloads, entry and precedence"
  if !legacy then IO.println "PASS: optimized argument UB positive control (1 additional transition)"

/-- Unknown-label behavior is an existing native panic. Run this control in its
    own process with LEAN_ABORT_ON_PANIC=1; it must never become a NiceFault. -/
def unknownLabelControl (legacy : Bool) : IO Unit := do
  let state := stateFor (saved [])
  let result ← execute legacy state (threadFor legacy (runExpr 17 [] absentLabel))
  match result with
  | .Exception (.NiceFault _) => throw (IO.Error.userError "unknown label became NiceFault")
  | _ => throw (IO.Error.userError "unknown label unexpectedly returned")

def tests : IO Unit := do
  ruleTests true
  ruleTests false

end CoreNice.IncomingTests

def main (args : List String) : IO Unit :=
  match args with
  | [] => CoreNice.IncomingTests.tests
  | ["--unknown-label-legacy"] => CoreNice.IncomingTests.unknownLabelControl true
  | ["--unknown-label-optimized"] => CoreNice.IncomingTests.unknownLabelControl false
  | _ => throw (IO.Error.userError "unknown incoming-test arguments")
