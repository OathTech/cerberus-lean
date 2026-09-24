import CerbMem
import CerbNDObserveProofs

namespace SCUnit.SCPrototype

/- Component tests for the actual memory operations. These do not yet assert
   completeness of the production driver's concurrency observation path. -/
namespace SCPrototype
open CerbMem

def step {α : Type} (m : memM α) (st : MemState) :=
  match m with | ND run => run st

def accessKinds (st : MemState) : List access_kind :=
  match takeObservations st with
  | none => []
  | some (observations, _) => observations.filterMap fun observation =>
    match observation with
    | Observe_access _ kind _ _ _ _ _ _ _ => some kind
    | _ => none

def killed {α : Type} (result : nd_action α String mem_error (mem_constraint IntegerValue) MemState) : Bool :=
  match result with | NDkilled _ => true | _ => false

def checks (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let tags : CerbTags.TagDefsMap := default
  let loc := CerbLocation.other "SC memory observation test"
  let iv := IntegerValue.IV .Prov_none
  let ptr := fun id addr => PointerValue.PV (.Prov_some id) (.PVconcrete none addr)
  let base := initialMemState 0x10000
  let unobserved : MemState := { base with
    allocations := (base.allocations.insert 1 { base := 100, size := 1 }).insert 2 { base := 200, size := 2 }
    bytemap := (base.bytemap.insert 100 { value := some 7 }).insert 200 { value := some 7 }
    lastUsed := some 99 }
  let observed := { unobserved with observations := some [] }
  let byteValue := MemValue.MVinteger (.Unsigned .Ichar) (iv 7)
  let store := storeM tags loc unsigned_char false (ptr 2 200) byteValue
  let oneStore := step store observed
  let twoStores := step store oneStore.2
  let copy := step (memcpyM tags loc (ptr 2 200) (ptr 1 100) (iv 2)) observed
  let trapState := { observed with bytemap := observed.bytemap.insert 100 { value := some 2 } }
  let boolTy := Ctype [] (.Basic (.Integer .Bool0))
  let trap := step (loadM tags loc boolTy (ptr 1 100)) trapState
  let lifetime := step (killM loc false (ptr 1 100)) observed
  let region := step (allocateRegion 0 (PrefOther "SC test") (iv 1) (iv 4)) { base with observations := some [] }
  let initialized := step
    (allocateObject tags 0 (PrefOther "SC test") (iv 1) unsigned_char none (some byteValue))
    { base with observations := some [] }
  let exhaustedVa := step (vaArg (iv 4) unsigned_char)
    { observed with varargs := [(4, (0, []))] }
  let advancedVa := step (vaArg (iv 4) unsigned_char)
    { observed with varargs := [(4, (0, [(unsigned_char, ptr 1 100)]))] }
  return [
    ("failed varargs access keeps metadata read", killed exhaustedVa.1 &&
      match takeObservations exhaustedVa.2 with
      | some ([Observe_varargs Varargs_read id], _) => id == 4
      | _ => false),
    ("varargs cursor advance is distinct from byte accesses", match takeObservations advancedVa.2 with
      | some ([Observe_varargs Varargs_read id, Observe_varargs Varargs_advance id'], _) =>
        id == 4 && id' == 4
      | _ => false),
    ("disabled extraction is explicit", (takeObservations unobserved).isNone),
    ("begin enables empty observation", match beginObserving unobserved with
      | some st => match takeObservations st with | some ([], _) => true | _ => false
      | none => false),
    ("equal-value stores are both observed", accessKinds twoStores.2 == [StoreAccess, StoreAccess]),
    ("equal-value stores retain bytes", readBytesFrom twoStores.2 200 1 == readBytesFrom unobserved 200 1),
    ("copy faults on second source byte", killed copy.1),
    ("copy keeps its completed read/write prefix", accessKinds copy.2 == [LoadAccess, StoreAccess]),
    ("copy keeps first destination byte", (readBytesFrom copy.2 200 1).head?.bind (·.value) == some 7),
    ("trap is a failed read", killed trap.1),
    ("trap read remains observed", accessKinds trap.2 == [LoadAccess]),
    ("trap preserves last-used state", trap.2.lastUsed == some 1),
    ("disabled load keeps observations disabled", (step (loadM tags loc unsigned_char (ptr 1 100)) unobserved).2.observations.isNone),
    ("lifetime end retains original range", match takeObservations lifetime.2 with
      | some ([Observe_deallocation _ false _ id (some (addr, size))], _) => id == 1 && addr == 100 && size == 1
      | _ => false),
    ("region creation is not a value store", match takeObservations region.2 with
      | some ([Observe_allocation _ _ _ size none none []], _) => size == 4
      | _ => false),
    ("dynamic deallocation is identified", match region with
      | (NDactive pointer, st) => match takeObservations st with
        | some (_, st) => match takeObservations (step (killM loc true pointer) st).2 with
          | some ([Observe_deallocation _ true _ _ (some (_, size))], _) => size == 4
          | _ => false
        | none => false
      | _ => false),
    ("supplied initialization retains representation", match takeObservations initialized.2 with
      | some ([Observe_allocation _ _ _ _ (some _) (some _) bytes], _) =>
        bytes.length == 1 && bytes.head?.bind (·.value) == some 7
      | _ => false),
    ("drain preserves enabled recording", match takeObservations twoStores.2 with
      | some (_, st) => match takeObservations st with | some ([], _) => true | _ => false
      | none => false),
    ("stop disables recording", (takeObservations (stopObserving twoStores.2)).isNone)]

end SCPrototype

def runTests (args : List String) : IO UInt32 := do
  if args.isEmpty then
    IO.eprintln "sc-prototype-test requires caller-selected fuel"
    return 2
  let mut failed := false
  for argument in args do
    let some fuel := argument.toNat? | return 2
    for (name, ok) in SCPrototype.checks fuel do
      IO.println s!"{if ok then "PASS" else "FAIL"} [{fuel}] {name}"
      failed := failed || !ok
  return if failed then 1 else 0

end SCUnit.SCPrototype
