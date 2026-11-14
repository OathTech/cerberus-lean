import PipelineB
import ObservationShared
import ChoiceRunner

open Lean

deriving instance ToJson for CoreB.core_object_type, CoreB.core_base_type
deriving instance ToJson for CoreB.core_run_cause, CoreB.driver_error

namespace CoreBDiff.ObservationB

def stepInfo : CoreB.step_kind → Json
  | .SK_action_request detail => node "action" [toJson detail]
  | .SK_memop_request => node "memop" []
  | .SK_tau detail => node "tau" [toJson detail]
  | .SK_eval detail => node "eval" [toJson detail]
  | .SK_done => node "done" []
  | .SK_misc details => node "misc" [toJson details]

mutual
partial def loadedValue : CoreB.loaded_value → Except String Json
  | .LVspecified value => return node "LVspecified" [← objectValue value]
  | .LVunspecified ty => return node "LVunspecified" [toJson ty]

partial def objectValue : CoreB.object_value → Except String Json
  | .OVinteger value => return node "OVinteger" [toJson value]
  | .OVfloating value => return node "OVfloating" [← floatPayload value]
  | .OVpointer value => return node "OVpointer" [toJson value]
  | .OVarray values => return node "OVarray" [Json.arr (← values.mapM loadedValue).toArray]
  | .OVstruct tag members =>
    return node "OVstruct" [toJson tag, Json.arr (← members.mapM fun (name, ty, value) =>
      return Json.arr #[toJson name, toJson ty, ← memoryValue value]).toArray]
  | .OVunion tag member value => return node "OVunion" [toJson tag, toJson member, ← memoryValue value]
end

partial def coreValue : CoreB.value → Except String Json
  | .Vobject value => return node "Vobject" [← objectValue value]
  | .Vloaded value => return node "Vloaded" [← loadedValue value]
  | .Vunit => return node "Vunit" []
  | .Vtrue => return node "Vtrue" []
  | .Vfalse => return node "Vfalse" []
  | .Vctype ty => return node "Vctype" [toJson ty]
  | .Vlist ty values => return node "Vlist" [toJson ty, Json.arr (← values.mapM coreValue).toArray]
  | .Vtuple values => return node "Vtuple" [Json.arr (← values.mapM coreValue).toArray]

def observer : Choice.Observer CoreB.step_kind CoreB.driver_error
    (mem_constraint CerbMem.IntegerValue) CoreB.driver_state := {
  encodeInfo := stepInfo
  observeDelta := fun before after => traceDelta before.trace after.trace
  isExhaustion := exhausted
  isTrivialConstraint := trivialConstraint }

def result (value : CoreB.driver_result) : Except String Json := do
  return Json.mkObj [("value", ← coreValue value.dres_core_value),
    ("stdout", toJson value.dres_stdout), ("stderr", toJson value.dres_stderr),
    ("blocked", toJson value.dres_blocked)]

def streams (state : CoreB.driver_state) : String × String :=
  (lemListFoldr String.append "" (toList state.core_state0.io.stdout),
   lemListFoldr String.append "" (toList state.core_state0.io.stderr))

end CoreBDiff.ObservationB
