import Prepared
import CoreNice.CoreParser
import CoreNice.Translation
import CoreNice.Core_run_aux
import CoreNice.Driver
import IncomingReachability
import Saturation

namespace CoreNiceDiff

structure ExecutionNice where
  translated : CoreNice.file Unit
  file : CoreNice.file CoreNice.core_run_annotation
  state : CoreNice.driver_state
  translatedSupply : Nat
  initialSupply : Nat
  incomingStats : CoreNice.Incoming.Stats

def loadImplementationNice (parsed : CoreNice.CoreParser.CoreFile) : Except String CoreNice.impl := do
  parsed.impls.foldlM (fun acc (name, value) => do
    let key ← CoreNice.CoreParser.pImplConstant name
    pure (fmapAddBy implementation_constant_compare key value acc)) fmapEmpty

private def lowerNiceWith [LemFuel] (saturate : Bool) (prepared : Prepared) : IO ExecutionNice := do
  let _ ← (CerberusFresh.setDigestIO "" : BaseIO Unit)
  let std ← match CoreNice.CoreParser.parseLibraryFile prepared.runtime.text.stdPath
      prepared.runtime.text.stdText with
    | .ok result => pure result
    | .error reason => fail s!"CoreNice runtime parse failed: {reason}"
  let implFile ← match CoreNice.CoreParser.parseLibraryFile prepared.runtime.text.implPath
      prepared.runtime.text.implText with
    | .ok result => pure result
    | .error reason => fail s!"CoreNice implementation parse failed: {reason}"
  let implementation ← match loadImplementationNice implFile with
    | .ok result => pure result
    | .error reason => fail s!"CoreNice implementation key failed: {reason}"
  let ailnames : Fmap String sym := Lem_Map.fromList std.ailnames
  let functions : CoreNice.fun_map Unit := Lem_Map.fromList (std.funs ++ std.procs ++ std.builtins)
  -- The admitted recipe has only the normal calling convention. All other
  -- configuration fields are carried from the shared frontend's config.
  let config : CoreNice.elab_config := {
    calling_convention1 := .Normal_callconv
    is_PNVI := defaultElabConfig.is_PNVI
    is_CHERI := defaultElabConfig.is_CHERI
    is_CN := defaultElabConfig.is_CN
    strict_pointer_arith := defaultElabConfig.strict_pointer_arith
    branching_on_unspec := .Elab_UB }
  let _ ← (CerberusFresh.setDigestIO prepared.sourceDigest : BaseIO Unit)
  let (translated, supply) ← (CerberusFresh.forceIO (fun () =>
    CoreNice.translate prepared.enumDefs fmapEmpty prepared.supply
      (ailnames, functions) config implementation prepared.typed) : BaseIO _)
  let linked ← match CoreNice.link [translated] with
    | .Result result => pure result
    | .Exception (loc, _) => fail s!"CoreNice linking failed at {CerbLocation.stringFromLocation loc}"
  let conservative ← match CoreNice.Incoming.finalize linked with
    | .ok result => pure result
    | .error reason => fail s!"CoreNice incoming annotation failed: {reason}"
  let incoming ← match CoreNice.Incoming.tighten conservative with
    | .ok result => pure result.result
    | .error reason => fail s!"CoreNice incoming tightening failed: {reason}"
  let target ← if saturate then
      match CoreNice.Saturation.insert incoming.file with
      | .ok result => pure result.file
      | .error reason => fail s!"CoreNice saturation failed: {reason}"
    else pure incoming.file
  let file := CoreNice.convert_file target
  if saturate then
    match CoreNice.Saturation.check file with
    | .ok () => pure ()
    | .error reason => fail s!"CoreNice converted saturation failed: {reason}"
  let (state, initialSupply) := CoreNice.initial_driver_state supply prepared.addressSpaceTop
    prepared.runDigest file CerbFS.fs_initial_state
  return { translated, file, state, initialSupply, translatedSupply := supply, incomingStats := incoming.stats }

def lowerNice [LemFuel] (prepared : Prepared) : IO ExecutionNice :=
  lowerNiceWith false prepared

def lowerSaturatedNice [LemFuel] (prepared : Prepared) : IO ExecutionNice :=
  lowerNiceWith true prepared

/-- Existing passive memory diagnostics; disabled for the calibration oracle. -/
def ExecutionNice.capture (execution : ExecutionNice) (enabled : Bool) : Except String ExecutionNice := do
  let memory ← if enabled then
      match CerbMem.beginObserving execution.state.layout_state with
      | some memory => pure memory
      | none => throw "memory implementation refuses access receipt capture"
    else pure (CerbMem.stopObserving execution.state.layout_state)
  return { execution with state := { execution.state with layout_state := memory } }

def ExecutionNice.action [LemFuel] (execution : ExecutionNice) (argv : List String) :
    CoreNice.driverM CoreNice.driver_result :=
  letI : CerbGlobal.Switches := ⟨[]⟩
  CoreNice.drive execution.file.enumDefs execution.file.tagDefs false execution.file argv

end CoreNiceDiff
