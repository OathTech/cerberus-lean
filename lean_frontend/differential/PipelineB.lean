import Prepared
import CoreB.CoreParser
import CoreB.Translation
import CoreB.Core_run_aux
import CoreB.Driver

namespace CoreBDiff

structure ExecutionB where
  file : CoreB.file CoreB.core_run_annotation
  state : CoreB.driver_state
  translatedSupply : Nat
  initialSupply : Nat

def loadImplementationB (parsed : CoreB.CoreParser.CoreFile) : Except String CoreB.impl := do
  parsed.impls.foldlM (fun acc (name, value) => do
    let key ← CoreB.CoreParser.pImplConstant name
    pure (fmapAddBy implementation_constant_compare key value acc)) fmapEmpty

def lowerB [LemFuel] (prepared : Prepared) : IO ExecutionB := do
  let _ ← (CerberusFresh.setDigestIO "" : BaseIO Unit)
  let std ← match CoreB.CoreParser.parseLibraryFile prepared.runtime.text.stdPath
      prepared.runtime.text.stdText with
    | .ok result => pure result
    | .error reason => fail s!"CoreB runtime parse failed: {reason}"
  let implFile ← match CoreB.CoreParser.parseLibraryFile prepared.runtime.text.implPath
      prepared.runtime.text.implText with
    | .ok result => pure result
    | .error reason => fail s!"CoreB implementation parse failed: {reason}"
  let implementation ← match loadImplementationB implFile with
    | .ok result => pure result
    | .error reason => fail s!"CoreB implementation key failed: {reason}"
  let ailnames : Fmap String sym := Lem_Map.fromList std.ailnames
  let functions : CoreB.fun_map Unit := Lem_Map.fromList (std.funs ++ std.procs ++ std.builtins)
  -- The admitted recipe has only the normal calling convention. All other
  -- configuration fields are carried from the shared frontend's config.
  let config : CoreB.elab_config := {
    calling_convention1 := .Normal_callconv
    is_PNVI := defaultElabConfig.is_PNVI
    is_CHERI := defaultElabConfig.is_CHERI
    is_CN := defaultElabConfig.is_CN
    strict_pointer_arith := defaultElabConfig.strict_pointer_arith
    branching_on_unspec := .Elab_UB }
  let _ ← (CerberusFresh.setDigestIO prepared.sourceDigest : BaseIO Unit)
  let (translated, supply) ← (CerberusFresh.forceIO (fun () =>
    CoreB.translate prepared.enumDefs fmapEmpty prepared.supply
      (ailnames, functions) config implementation prepared.typed) : BaseIO _)
  let linked ← match CoreB.link [translated] with
    | .Result result => pure result
    | .Exception (loc, _) => fail s!"CoreB linking failed at {CerbLocation.stringFromLocation loc}"
  let file := CoreB.convert_file linked
  let (state, initialSupply) := CoreB.initial_driver_state supply prepared.addressSpaceTop
    prepared.runDigest file CerbFS.fs_initial_state
  return { file, state, translatedSupply := supply, initialSupply }

def ExecutionB.action [LemFuel] (execution : ExecutionB) (argv : List String) :
    CoreB.driverM CoreB.driver_result :=
  letI : CerbGlobal.Switches := ⟨[]⟩
  CoreB.drive execution.file.enumDefs execution.file.tagDefs false execution.file argv

end CoreBDiff
