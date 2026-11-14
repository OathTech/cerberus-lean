import Lean.Data.Json
import Trace_event
import CerbFuel
import CerbFail

/- Structural codecs for observable payloads only. No driver state, heap,
   environment, expression or continuation is serialized here. Derived JSON
   keeps constructor identity and every field, including locations and symbol
   digests. Floating payloads use bits; NaNs are refused because Float.toBits
   canonicalizes their payload on this toolchain. -/

open Lean

deriving instance ToJson for CerbLocation.Pos, CerbLocation.Cursor, CerbLocation.Loc
deriving instance ToJson for identifier, attribute0, attributes
deriving instance ToJson for symbol_description, sym, prefix0
deriving instance ToJson for integerBaseType, integerType
deriving instance ToJson for bmc_annot, cerb_attribute, label_annot, value_annot, annot
deriving instance ToJson for realFloatingType, floatingType, basicType, qualifiers
deriving instance ToJson for ctype_, ctype
deriving instance ToJson for CerbMem.Provenance, CerbMem.IntegerValue
deriving instance ToJson for CerbMem.PointerValueBase, CerbMem.PointerValue
deriving instance ToJson for unspecified_ub_context, undefined_by_omission, undefined_behaviour
deriving instance ToJson for access_kind, access_error, free_error, memcpy_error
deriving instance ToJson for observed_provenance, representation_byte_view
deriving instance ToJson for vip_kind, vip_error, mem_cheri_error, readonly_kind, mem_error

namespace CoreBDiff

def node (tag : String) (fields : List Json) : Json :=
  Json.mkObj [("tag", toJson tag), ("fields", Json.arr fields.toArray)]

def floatPayload (value : Float) : Except String Json :=
  if value.isNaN then .error "observation refuses NaN payload: Float.toBits canonicalizes it"
  else .ok (node "FloatBits" [toJson value.toBits.toNat])

partial def memoryValue : CerbMem.MemValue → Except String Json
  | .MVunspecified ty => return node "MVunspecified" [toJson ty]
  | .MVinteger ty value => return node "MVinteger" [toJson ty, toJson value]
  | .MVfloating ty value => return node "MVfloating" [toJson ty, ← floatPayload value]
  | .MVpointer ty value => return node "MVpointer" [toJson ty, toJson value]
  | .MVarray values => return node "MVarray" [Json.arr (← values.mapM memoryValue).toArray]
  | .MVstruct tag members =>
    return node "MVstruct" [toJson tag, Json.arr (← members.mapM fun (name, ty, value) =>
      return Json.arr #[toJson name, toJson ty, ← memoryValue value]).toArray]
  | .MVunion tag name value => return node "MVunion" [toJson tag, toJson name, ← memoryValue value]

def optionalMemoryValue : Option CerbMem.MemValue → Except String Json
  | none => return Json.null
  | some value => memoryValue value

def accessReceipt : CerbMem.AccessReceipt → Except String Json
  | .Access_receipt loc kind ty pointer allocation address bytes value locking =>
    return node "access_receipt" [toJson loc, toJson kind, toJson ty, toJson pointer,
      toJson allocation, toJson address, toJson bytes, ← memoryValue value, toJson locking]

def receiptDelta (before after : Option (List CerbMem.AccessReceipt)) :
    Except String (Array Json) := do
  match before, after with
  | none, none => return #[]
  | some before, some after =>
    if after.length < before.length || after.drop (after.length - before.length) != before then
      throw "access receipts did not retain the previous suffix"
    return (← (after.take (after.length - before.length)).reverse.mapM accessReceipt).toArray
  | _, _ => throw "access receipt capture changed during execution"

def outputDelta (before after : String) : Except String String :=
  if after.startsWith before then .ok (after.drop before.length).toString
  else .error "output stream did not retain its previous prefix"

def traceEvent : trace_event → Except String Json
  | .ME_function_call sym values =>
    return node "function_call" [toJson sym, Json.arr (← values.mapM memoryValue).toArray]
  | .ME_function_return sym value =>
    return node "function_return" [toJson sym, ← optionalMemoryValue value]
  | .ME_allocate_object tid origin align ty initial pointer =>
    return node "allocate_object" [toJson tid, toJson origin, toJson align, toJson ty,
      ← optionalMemoryValue initial, toJson pointer]
  | .ME_allocate_region tid origin align size pointer =>
    return node "allocate_region" [toJson tid, toJson origin, toJson align, toJson size, toJson pointer]
  | .ME_kill loc dynamic pointer =>
    return node "kill" [toJson loc, toJson dynamic, toJson pointer]
  | .ME_load loc origin ty pointer value =>
    return node "load" [toJson loc, toJson origin, toJson ty, toJson pointer, ← memoryValue value]
  | .ME_store loc origin ty locking pointer value =>
    return node "store" [toJson loc, toJson origin, toJson ty, toJson locking,
      toJson pointer, ← memoryValue value]
  | .ME_seq_rmw loc origin ty pointer loaded stored =>
    return node "seq_rmw" [toJson loc, toJson origin, toJson ty, toJson pointer,
      ← memoryValue loaded, ← memoryValue stored]
  | .ME_eff_array_shift_ptrval pointer ty offset result =>
    return node "array_shift" [toJson pointer, toJson ty, toJson offset, toJson result]
  | .ME_eff_member_shift_ptrval tag member pointer result =>
    return node "member_shift" [toJson tag, toJson member, toJson pointer, toJson result]

/-- Driver.trace is newest first; retain its old suffix and emit new events
    once in execution order. A changed/lost suffix is an instrument failure. -/
def traceDelta (before after : List trace_event) : Except String (Array Json) := do
  if after.length < before.length then .error "driver trace shrank"
  else
    let count := after.length - before.length
    if after.drop count != before then .error "driver trace did not retain the previous suffix"
    else return (← (after.take count).reverse.mapM traceEvent).toArray

/-- Channels retain their own order within an ND boundary. The array of channel
    batches does not assert interleaving between different underlying buffers. -/
def boundaryDelta (beforeTrace afterTrace : List trace_event)
    (beforeReceipts afterReceipts : Option (List CerbMem.AccessReceipt))
    (beforeIO afterIO : String × String) : Except String (Array Json) := do
  let driver ← traceDelta beforeTrace afterTrace
  let receipts ← receiptDelta beforeReceipts afterReceipts
  let stdout ← outputDelta beforeIO.1 afterIO.1
  let stderr ← outputDelta beforeIO.2 afterIO.2
  let mut events := #[]
  for (channel, batch) in [("driver", driver), ("memory", receipts)] do
    if !batch.isEmpty then
      events := events.push (Json.mkObj [("channel", toJson channel), ("events", toJson batch)])
  for (channel, delta) in [("stdout", stdout), ("stderr", stderr)] do
    if !delta.isEmpty then
      events := events.push (Json.mkObj [("channel", toJson channel), ("text", toJson delta)])
  return events

def trivialConstraint : mem_constraint CerbMem.IntegerValue → Bool
  | .MC_empty => true
  | _ => false

def exhausted {err : Type} : kill_reason err → Bool
  | .Error0 loc message => loc == CerbFuel.fuelExhaustedLoc && message == CerbFuel.fuelExhaustedMsg
  | _ => false

end CoreBDiff
