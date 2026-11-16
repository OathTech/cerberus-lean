import EntryCommon
import BreakpointExecution

open Lean CoreNiceDiff

private def extractPolicy : List String → Option String → List String →
    Except String (Breakpoints.Policy × List String)
  | [], policy, rest => do return (← Breakpoints.Policy.parse (policy.getD "all"), rest.reverse)
  | "--pause-policy" :: value :: args, none, rest => extractPolicy args (some value) rest
  | "--pause-policy" :: _, some _, _ => .error "duplicate --pause-policy"
  | flag :: value :: args, policy, rest => extractPolicy args policy (value :: flag :: rest)
  | [_], _, _ => .error "every option requires a value"

private def finishPauses [LemFuel] [CerbGlobal.Switches]
    (progress : Choice.Progress Breakpoints.Result CoreNice.driver_result Breakpoints.Point
      CoreNice.step_kind CoreNice.driver_error mem_iv_constraint CoreNice.driver_state) :
    IO (Choice.Run CoreNice.driver_result CoreNice.driver_error CoreNice.driver_state) := do
  let mut progress := progress
  repeat
    match progress with
    | .complete result => return result
    | .suspended suspension =>
      progress ← (CerberusFresh.forceIO (fun () => Choice.resume suspension) : BaseIO _)

def main (args : List String) : IO UInt32 := do
  match extractPolicy args none [] with
  | .error reason =>
    emit (Json.mkObj [("record", toJson "failure"), ("kind", toJson "input-error"), ("reason", toJson reason)])
    return 2
  | .ok (policy, remaining) => withOptions remaining fun options => do
    let fuel : LemFuel := ⟨options.fuel⟩
    let switches : CerbGlobal.Switches := ⟨[]⟩
    let mode ← options.choiceMode
    let prepared ← @prepare fuel options.runtime options.input options.addressSpaceTop options.args
    let execution ← @lowerNice fuel prepared
    let execution ← match execution.capture true with
      | .ok execution => pure execution
      | .error reason => fail reason
    let expected := header "CoreNice" options prepared execution.translatedSupply execution.initialSupply
    let action := @CoreNice.drive_until_breakpoint fuel switches execution.file.enumDefs
      execution.file.tagDefs false execution.file prepared.argv options.fuel
    let result ← (CerberusFresh.forceIO (fun () =>
      Choice.startResumable options.fuel ObservationNice.observer mode expected
        (@Breakpoints.adapter fuel switches policy)
        (@Breakpoints.advance fuel switches policy options.fuel 0 action) execution.state) : BaseIO _)
    let result ← @finishPauses fuel switches result
    finish options expected ObservationNice.result toJson ObservationNice.streams result
