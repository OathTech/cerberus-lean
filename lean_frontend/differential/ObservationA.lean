import PipelineA
import ObservationShared
import ChoiceRunner

open Lean

deriving instance ToJson for core_object_type, core_base_type
deriving instance ToJson for core_run_cause, driver_error

namespace CoreNiceDiff.ObservationA

def stepInfo : step_kind → Json
  | .SK_action_request detail => node "action" [toJson detail]
  | .SK_memop_request => node "memop" []
  | .SK_tau detail => node "tau" [toJson detail]
  | .SK_eval detail => node "eval" [toJson detail]
  | .SK_done => node "done" []
  | .SK_misc details => node "misc" [toJson details]

mutual
partial def loadedValue : loaded_value → Except String Json
  | .LVspecified value => return node "LVspecified" [← objectValue value]
  | .LVunspecified ty => return node "LVunspecified" [toJson ty]

partial def objectValue : object_value → Except String Json
  | .OVinteger value => return node "OVinteger" [toJson value]
  | .OVfloating value => return node "OVfloating" [← floatPayload value]
  | .OVpointer value => return node "OVpointer" [toJson value]
  | .OVarray values => return node "OVarray" [Json.arr (← values.mapM loadedValue).toArray]
  | .OVstruct tag members =>
    return node "OVstruct" [toJson tag, Json.arr (← members.mapM fun (name, ty, value) =>
      return Json.arr #[toJson name, toJson ty, ← memoryValue value]).toArray]
  | .OVunion tag member value => return node "OVunion" [toJson tag, toJson member, ← memoryValue value]
end

partial def coreValue : value → Except String Json
  | .Vobject value => return node "Vobject" [← objectValue value]
  | .Vloaded value => return node "Vloaded" [← loadedValue value]
  | .Vunit => return node "Vunit" []
  | .Vtrue => return node "Vtrue" []
  | .Vfalse => return node "Vfalse" []
  | .Vctype ty => return node "Vctype" [toJson ty]
  | .Vlist ty values => return node "Vlist" [toJson ty, Json.arr (← values.mapM coreValue).toArray]
  | .Vtuple values => return node "Vtuple" [Json.arr (← values.mapM coreValue).toArray]

def streams (state : driver_state) : String × String :=
  (lemListFoldr String.append "" (toList state.core_state0.io.stdout),
   lemListFoldr String.append "" (toList state.core_state0.io.stderr))

def observer : Choice.Observer step_kind driver_error
    (mem_constraint CerbMem.IntegerValue) driver_state := {
  encodeInfo := stepInfo
  observeDelta := fun before after => boundaryDelta before.trace after.trace
    before.layout_state.observations after.layout_state.observations (streams before) (streams after)
  isExhaustion := exhausted
  isTrivialConstraint := trivialConstraint }

def result (value : driver_result) : Except String Json := do
  return Json.mkObj [("value", ← coreValue value.dres_core_value),
    ("stdout", toJson value.dres_stdout), ("stderr", toJson value.dres_stderr),
    ("blocked", toJson value.dres_blocked)]


end CoreNiceDiff.ObservationA
