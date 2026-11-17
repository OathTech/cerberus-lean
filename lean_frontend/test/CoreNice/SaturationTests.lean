import Saturation
import BreakpointExecution

namespace CoreNice.SaturationTests
open CoreNiceDiff

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩
private def symbol (n : Nat) : sym := .Symbol "saturation-tests" n (.SD_Id s!"p{n}")
private def mainSym := symbol 1
private def helper := symbol 2
private def label := symbol 3
private def unitExpr : expr Unit := mk_value_e .Vunit
private def call : expr Unit := .Expr [] (.Eproc ((), .Continue) (.Sym helper) [])
private def proc (body : expr Unit) : fun_map_decl Unit := .Proc .unknown none .BTy_unit [] body
private def program : file Unit := { (default : file Unit) with
  main := some mainSym,
  stdlib := Lem_Map.fromList [(helper, proc unitExpr)],
  funs := Lem_Map.fromList [(mainSym, proc call)] }

private def require (ok : Bool) (message : String) : IO Unit :=
  unless ok do throw (IO.userError message)
private def unwrap {a : Type} : Except String a → IO a
  | .ok value => pure value
  | .error reason => throw (IO.userError reason)
private def refuses (candidate : file Unit) : IO Unit :=
  match Saturation.check candidate with
  | .error _ => pure ()
  | .ok _ => throw (IO.userError "coverage checker accepted a missing cut")

private def onlyThread (state : driver_state) : IO thread_state :=
  match state.core_state0.thread_states with
  | [(_, (_, thread))] => pure thread
  | _ => throw (IO.userError "expected exactly one thread")

private def runSuspensions : Nat →
    Choice.Progress Breakpoints.Result driver_result Breakpoints.Point step_kind
      driver_error mem_iv_constraint driver_state →
    List nice_suspension → IO (List nice_suspension)
  | 0, _, _ => throw (IO.userError "finite test exceeded its suspension bound")
  | n + 1, .suspended saved, points =>
    runSuspensions n (Choice.resume saved) (saved.point.machine :: points)
  | _, .complete result, points =>
    match result.outcome with
    | .returned _ => pure points.reverse
    | _ => throw (IO.userError "expected ordinary completion in return test")

def run : IO Unit := do
  let saturated ← unwrap (Saturation.insert program)
  require (saturated.stats.procedures == 2 && saturated.stats.callReturns == 1)
    "producer omitted the runtime procedure or call return"
  refuses program
  let removeReturn (_ : sym) (decl : fun_map_decl Unit) := match decl with
    | .Proc loc marker ty params body =>
      .Proc loc marker ty params (Id.run <| Incoming.mapExprM (fun _ _ node => pure <|
        match node with
        | .Eproc (a, _) target args => .Eproc (a, .Continue) target args
        | other => other) {} body)
    | other => other
  refuses { saturated.file with funs := fmapMapi removeReturn saturated.file.funs }
  let duplicateFuns := fmapAddBy symbol_compare helper (proc unitExpr) program.funs
  let duplicated ← unwrap (Saturation.insert { program with funs := duplicateFuns })
  require (fmapLookupBy symbol_compare helper duplicated.file.stdlib ==
    fmapLookupBy symbol_compare helper duplicated.file.funs)
    "duplicate definitions received different entry identities"
  let jump : expr Unit := .Expr [] (.Erun () label [] empty_nice_jump_info)
  let save : expr Unit := .Expr [] (.Esave (label, .BTy_unit) [] jump empty_nice_label_info)
  let rawLabel := { program with funs := Lem_Map.fromList [(mainSym, proc save)] }
  let assigned ← unwrap (Incoming.finalize rawLabel)
  let markedLabel ← unwrap (Saturation.insert assigned.file)
  let some (.Proc _ _ _ _ body) := fmapLookupBy symbol_compare mainSym markedLabel.file.funs
    | throw (IO.userError "missing main body")
  let some (_, target, _) := fmapLookupBy symbol_compare label (collect_saves body)
    | throw (IO.userError "saved label collector lost the label")
  let some site := Saturation.entrySite target
    | throw (IO.userError "jump target bypasses the label-entry cut")
  require (site.breakpoint_role == .BP_label_entry) "wrong label-target role"
  -- The converted machine must retain the call-return AST field in the stack.
  let file := convert_file saturated.file
  let state := (initial_driver_state_given 100 65535 "saturation-tests" file CerbFS.fs_initial_state).1
  let action := drive_until_breakpoint file.enumDefs file.tagDefs false file [] 1000
  let header : Choice.Header := {
    input := "synthetic", prepared := "synthetic", config := .null,
    coreBuild := "test", coreNiceBuild := "test", origin := "test" }
  let points ← runSuspensions 20
    (Choice.startResumable 1000 ObservationNice.observer (.record .first) header
      (Breakpoints.adapter .all) (Breakpoints.advance .all 1000 0 action) state) []
  require (points.map (·.suspension_site.breakpoint_role) ==
    [.BP_procedure_entry, .BP_procedure_entry, .BP_call_return])
    "expected entry, callee entry, then caller resumption"
  let caller ← onlyThread points[0]!.suspension_state
  let resumed ← onlyThread points[2]!.suspension_state
  require (resumed.current_proc_opt == some mainSym && resumed.env == caller.env)
    "return cut did not restore the caller/environment"
  require (resumed.arena == mk_value_e .Vunit) "return cut changed the returned value or residual"
  let returnSite := points[2]!.suspension_site
  let invalidPrimitive : expr core_run_annotation := .Expr []
    (.Eproc (empty_annotation, .Breakpoint returnSite)
      (.Impl (.BuiltinFunction "exit")) [mk_integer_pe 0])
  match step_ctx file.enumDefs file.tagDefs state.layout_state file fmapEmpty 0
      (none, { resumed with arena := invalidPrimitive }) with
  | [.Step_with_runstate2 _ action] =>
    match action state.core_run_state0 with
    | .Exception (.Illformed_program _) => pure ()
    | _ => throw (IO.userError "marked primitive did not fail explicitly")
  | _ => throw (IO.userError "marked primitive reached ordinary dispatch")
  IO.println "PASS: saturation shape controls, saved-target cut, exact caller resumption and primitive-cut refusal"

end CoreNice.SaturationTests

def main : IO Unit := CoreNice.SaturationTests.run
