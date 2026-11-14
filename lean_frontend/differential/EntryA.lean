import EntryCommon
import ObservationA

open Lean CoreBDiff

def main (args : List String) : IO UInt32 :=
  withOptions args fun options => do
    letI : LemFuel := ⟨options.fuel⟩
    let mode ← options.choiceMode
    let prepared ← prepare options.runtime options.input options.addressSpaceTop options.args
    let execution ← lowerA prepared
    let expected := header "Core" options prepared execution.translatedSupply execution.initialSupply
    let result ← (CerberusFresh.forceIO (fun () =>
      Choice.run options.fuel ObservationA.observer mode expected
        (execution.action prepared.argv) execution.state) : BaseIO _)
    finish options expected ObservationA.result toJson ObservationA.streams result
