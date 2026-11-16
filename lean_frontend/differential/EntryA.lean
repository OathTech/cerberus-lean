import EntryCommon
import ObservationA

open Lean CoreNiceDiff

def main (args : List String) : IO UInt32 :=
  withOptions args fun options => do
    let fuel : LemFuel := ⟨options.fuel⟩
    let mode ← options.choiceMode
    let prepared ← @prepare fuel options.runtime options.input options.addressSpaceTop options.args
    let execution ← @lowerA fuel prepared
    let execution ← match execution.capture true with
      | .ok execution => pure execution
      | .error reason => fail reason
    let expected := header "Core" options prepared execution.translatedSupply execution.initialSupply
    let result ← (CerberusFresh.forceIO (fun () =>
      Choice.run options.fuel ObservationA.observer mode expected
        (@ExecutionA.action fuel execution prepared.argv) execution.state) : BaseIO _)
    finish options expected ObservationA.result toJson ObservationA.streams result
