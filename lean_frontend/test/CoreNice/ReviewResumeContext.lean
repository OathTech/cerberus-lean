import BreakpointExecution

/-! Configuration probe discussed in landing review R1. Changing a semantic
reader can change the result; this does not refute decomposition of an
execution with unchanged inputs. The controls check saved state restoration
and the production choice adapter's retained configuration.
Run from lean_frontend using ../scripts/lean_probe.sh on this file. -/

open CoreNiceDiff

namespace CoreNice.ReviewResumeContext

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

private def mainSym : sym := .Symbol "review" 1 (.SD_Id "main")
private def enumSym : sym := .Symbol "review" 2 (.SD_Id "E")
private def unsigned : CerberusImpl.EnumDefs := Lem_Map.fromList [(enumSym, .Unsigned .Int_)]
private def signed : CerberusImpl.EnumDefs := Lem_Map.fromList [(enumSym, .Signed .Int_)]
private def site : nice_breakpoint_site := {
  breakpoint_procedure := mainSym, breakpoint_id := 1,
  breakpoint_role := .BP_internal, breakpoint_origin := .NiceInternal,
  breakpoint_location := .other "review" }
private def program : file core_run_annotation := {
  (default : file core_run_annotation) with
  main := some mainSym, enumDefs := unsigned,
  funs := Lem_Map.fromList [(mainSym, .Proc .unknown none .BTy_unit []
    (mk_breakpoint_sseq_e site (mk_empty_pat .BTy_unit) (mk_value_e .Vunit)
      (.Expr [] (.Epure (.Pexpr [] () (.PEconv_int (.Enum0 enumSym)
        (mk_integer_pe 4294967295)))))))] }
private def start : driver_state :=
  (initial_driver_state_given 100 65535 "review" program CerbFS.fs_initial_state).1

private def run {α : Type} : Nat → driverM α → driver_state → IO (α × driver_state)
  | 0, _, _ => throw (IO.userError "probe traversal exhausted")
  | fuel + 1, .ND action, state => do
    let (next, state') := action state
    match next with
    | .NDactive value => pure (value, state')
    | .NDnd _ [(_, continuation)] | .NDstep _ [(_, continuation)] => run fuel continuation state'
    | _ => throw (IO.userError "probe encountered a failure or genuine choice")

private def require (label : String) (ok : Bool) : IO Unit :=
  unless ok do throw (IO.userError label)

def main : IO Unit := do
  let action := drive_until_breakpoint unsigned fmapEmpty false program [] 100
  let (result, state) ← run 100 action start
  let .NiceSuspended saved := result | throw (IO.userError "expected cut")
  let (normal, normalState) ← run 100 (resume_breakpoint unsigned fmapEmpty saved) state
  let .NiceCompleted normal := normal | throw (IO.userError "expected completion")
  require "original enum reader" (normal.dres_core_value == .Vobject (.OVinteger (.IV .Prov_none 4294967295)))
  let (changed, _) ← run 100 (resume_breakpoint signed fmapEmpty saved) state
  let .NiceCompleted changed := changed | throw (IO.userError "expected completion")
  require "replacement enum reader did not change result" (changed.dres_core_value == .Vobject (.OVinteger (.IV .Prov_none (-1))))
  IO.println "PASS: changing the enum reader changes 4294967295 to -1; the semantic inputs differ"
  let poisoned := { start with dr_step_counter := 99999, exit_routed := true }
  let (restored, restoredState) ← run 100 (resume_breakpoint unsigned fmapEmpty saved) poisoned
  let .NiceCompleted restored := restored | throw (IO.userError "expected restored completion")
  require "raw resume failed to restore saved state" (restored.dres_core_value == normal.dres_core_value &&
    restoredState.dr_step_counter == normalState.dr_step_counter &&
    restoredState.exit_routed == normalState.exit_routed)
  IO.println "PASS: raw resume restores its saved state despite unrelated supplied driver state"
  let header : Choice.Header := {
    input := "review", prepared := "synthetic", config := .null,
    coreBuild := "review", coreNiceBuild := "review", origin := "review" }
  let session := Choice.startResumable 100 ObservationNice.observer (.record .first) header
    (Breakpoints.adapter .all) (Breakpoints.advance .all 100 0 action) start
  let .suspended session := session | throw (IO.userError "expected host cut")
  let .complete completed := Choice.resume session | throw (IO.userError "expected host completion")
  let .returned host := completed.outcome | throw (IO.userError "host failed")
  require "captured host reader" (host.dres_core_value == normal.dres_core_value)
  IO.println "PASS: host adapter resumes using the retained original enum reader"

#eval main

end CoreNice.ReviewResumeContext
