import Prepared
import Translation
import Core_run_aux
import Driver

namespace CoreBDiff

structure ExecutionA where
  file : file core_run_annotation
  state : driver_state
  translatedSupply : Nat
  initialSupply : Nat

def lowerA [LemFuel] (prepared : Prepared) : IO ExecutionA := do
  let _ ← (CerberusFresh.setDigestIO prepared.sourceDigest : BaseIO Unit)
  let (translated, supply) ← (CerberusFresh.forceIO (fun () =>
    translate prepared.enumDefs fmapEmpty prepared.supply
      (prepared.runtime.ailnames, prepared.runtime.functions) defaultElabConfig
      prepared.runtime.implementation prepared.typed) : BaseIO _)
  let linked ← match link [translated] with
    | .Result result => pure result
    | .Exception (loc, _) => fail s!"Core linking failed at {CerbLocation.stringFromLocation loc}"
  let file := convert_file linked
  let (state, initialSupply) := initial_driver_state supply prepared.addressSpaceTop
    prepared.runDigest file CerbFS.fs_initial_state
  return { file, state, translatedSupply := supply, initialSupply }

def ExecutionA.action [LemFuel] (execution : ExecutionA) (argv : List String) :
    driverM driver_result :=
  letI : CerbGlobal.Switches := ⟨[]⟩
  drive execution.file.enumDefs execution.file.tagDefs false execution.file argv

end CoreBDiff
