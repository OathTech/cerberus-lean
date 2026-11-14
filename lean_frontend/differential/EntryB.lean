import EntryCommon
import ObservationB

open Lean CoreBDiff

def main (args : List String) : IO UInt32 :=
  withOptions args fun options => do
    letI : LemFuel := ⟨options.fuel⟩
    let mode ← options.choiceMode
    let prepared ← prepare options.runtime options.input options.addressSpaceTop options.args
    let execution ← lowerB prepared
    let expected := header "CoreB" options prepared execution.translatedSupply execution.initialSupply
    let result ← (CerberusFresh.forceIO (fun () =>
      Choice.run options.fuel ObservationB.observer mode expected
        (execution.action prepared.argv) execution.state) : BaseIO _)
    finish options expected ObservationB.result toJson ObservationB.streams result
