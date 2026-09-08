import CerbFailProofs

/- Executable witnesses, not kernel evaluation. The fuel is supplied by
   test_unit.sh. Kernel propagation contracts live in CerbFailProofs. -/
namespace MonadicFailstop
open CerbMem CerbFail
set_option autoImplicit true

def stops (m : CerbMem.memM a) (s : MemState) (msg : String) : Bool :=
  match step m s with
  | (NDkilled (Error0 loc text), _) => loc == modelFailStopLoc && text == msg
  | _ => false

def active (m : CerbMem.memM a) (s : MemState) : Bool :=
  match step m s with | (NDactive _, _) => true | _ => false

def checks (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let tags : CerbTags.TagDefsMap := default
  let loc := CerbLocation.unknown
  let iv := IntegerValue.IV .Prov_none
  let ptr := PointerValue.PV (.Prov_some 7) (.PVconcrete none 100)
  let alloc : Allocation := { base := 100, size := 1 }
  let st : MemState := { initialMemState with
    allocations := initialMemState.allocations.insert 7 alloc
    lastUsed := some 99 }
  let dead := { st with deadAllocations := [7], dynamicAddrs := [100] }
  let va := { st with varargs := [(4, (1, []))] }
  let memcmpStop := memcmpM tags ptr ptr (iv 1)
  let cmpMsg := "Concrete.memcmp: non-integer byte (impl_mem.ml:2658-2659 assert false)"
  let liveByte := writeBytesTo st 100 [{ prov := .Prov_none, copyOffset := none, value := some 42 }]
  return [
    ("allocator zero alignment remains a refusal", stops (allocator 0 0) st
      "CerbMem.allocator: alignment 0 has no meaning in the model (impl_mem.ml:1252 quomod raises Division_by_zero — an OCaml-execution artifact, not the referent); operator decision pending, zero-discrepancy Z2 record §10"),
    ("allocator ordinary alignment", active (allocator 1 1) st),
    ("requested address", stops (allocateObject tags 0 (PrefOther "test") (iv 1) unsigned_char (some 100) none) st
      "TODO: cerb::with_address() is yet implemented"),
    ("ordinary allocation", active (allocateObject tags 0 (PrefOther "test") (iv 1) unsigned_char none none) st),
    ("dead static allocation", stops (killM loc false ptr) dead "Concrete: FREE was called on a dead allocation"),
    ("live static allocation", active (killM loc false ptr) st),
    ("dead dynamic allocation remains UB", match step (killM loc true ptr) dead with
      | (NDkilled (Undef0 _ _), _) => true | _ => false),
    ("function pointer shift", stops (effArrayShiftPtrval tags loc (.PV .Prov_none (.PVfunction default)) unsigned_char (iv 1)) st
      "Concrete.eff_array_shift_ptrval, PVfunction"),
    ("ordinary pointer shift", active (effArrayShiftPtrval tags loc ptr unsigned_char (iv 1)) st),
    ("unspecified memcmp byte", stops memcmpStop st cmpMsg),
    ("memcmp retains load's updated state", (step memcmpStop st).2.lastUsed == some 7),
    ("specified memcmp byte", match step (memcmpM tags ptr ptr (iv 1)) liveByte with
      | (NDactive (.IV _ value), _) => value == 0 | _ => false),
    ("noninitial va_list", stops (vaList 4) va "va_list: assert (n = 0) failed (impl_mem.ml:2760)"),
    ("initial va_list", active (vaList 4) { va with varargs := [(4, (0, []))] }),
    ("CHERI intrinsic", stops (callIntrinsic loc "test" []) st
      "assert false (* CHERI only *): Concrete.call_intrinsic (impl_mem.ml:2190-2191)"),
    ("ordinary model errors remain Other", match step (memFail (MerrOther cmpMsg) : CerbMem.memM Unit) st with
      | (NDkilled (Other _), _) => true | _ => false),
    ("continuation cannot revive failure or overwrite its state",
      stops (nd_bind memcmpStop (fun _ => memReturn ())) st cmpMsg &&
        (step (nd_bind memcmpStop (fun _ => ND fun _ => (NDactive (), initialMemState))) st).2.lastUsed == some 7),
    ("UTF-8 and control bytes are escaped", batchRecord "a\n\"\\—" ==
      "ModelFailure {msg: \"a\\n\\\"\\\\\\226\\128\\148\"}")]

end MonadicFailstop

def main (args : List String) : IO UInt32 := do
  if args.isEmpty then
    IO.eprintln "monadic-failstop-test requires caller-selected fuel (at least 2)"
    return 2
  let mut failed := false
  for arg in args do
    let some fuel := arg.toNat? | return 2
    if fuel < 2 then return 2
    for (name, ok) in MonadicFailstop.checks fuel do
      IO.println s!"{if ok then "PASS" else "FAIL"} [{fuel}] {name}"
      failed := failed || !ok
  return if failed then 1 else 0
