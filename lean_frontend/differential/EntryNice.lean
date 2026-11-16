import EntryCommon
import ObservationNice

open Lean CoreNiceDiff

def main (args : List String) : IO UInt32 :=
  withOptions args fun options => do
    let fuel : LemFuel := ⟨options.fuel⟩
    let mode ← options.choiceMode
    let prepared ← @prepare fuel options.runtime options.input options.addressSpaceTop options.args
    let execution ← @lowerNice fuel prepared
    let execution ← match execution.capture true with
      | .ok execution => pure execution
      | .error reason => fail reason
    let expected := header "CoreNice" options prepared execution.translatedSupply execution.initialSupply
    let result ← (CerberusFresh.forceIO (fun () =>
      Choice.run options.fuel ObservationNice.observer mode expected
        (@ExecutionNice.action fuel execution prepared.argv) execution.state) : BaseIO _)
    finish options expected ObservationNice.result toJson ObservationNice.streams result
