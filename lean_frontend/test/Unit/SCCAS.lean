import Unit.SCProtocolSupport

open SCProtocolControls Lem_Basic_classes

def atomicByte : ctype := Ctype [] (Atomic unsigned_char)
def objectPtr : CerbMem.PointerValue := pointer 20 200
def expectedPtr : CerbMem.PointerValue := pointer 30 300

def casExpr (weak : Bool) (success failure : memory_order := Seq_cst)
    (object : CerbMem.PointerValue := objectPtr) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC CAS control") empty_annotation
    (if weak then CompareExchangeWeak (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer object)))
      (pe (Vobject (OVpointer expectedPtr))) (pe (intval 9)) success failure
     else CompareExchangeStrong (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer object)))
      (pe (Vobject (OVpointer expectedPtr))) (pe (intval 9)) success failure))))

def setupCAS (object expected : Option UInt8) (s : driver_state) : driver_state :=
  { s with layout_state := { s.layout_state with
    allocations := (s.layout_state.allocations.insert 20 {base := 200, size := 1, ty := some atomicByte}).insert
      30 {base := 300, size := 1, ty := some unsigned_char}
    bytemap := (s.layout_state.bytemap.insert 200 {value := object}).insert 300 {value := expected} } }

def byteAt (s : driver_state) (address : Int) : Option UInt8 :=
  (s.layout_state.bytemap.get? address).bind (·.value)

def runCAS (fuel : Nat) (body : expr core_run_annotation) (expected : Option UInt8) :=
  letI := LemFuel.mk fuel
  runProgram (program body) (setupCAS (some 7) expected)

def check (label : String) (pass : Bool) : IO Bool := do
  IO.println s!"{label}: {pass}"
  return pass

def interference : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC interfering store") empty_annotation
    (Store0 false (pe (Vctype atomicByte)) (pe (Vobject (OVpointer objectPtr))) (pe (intval 5)) Seq_cst))))

def phaseNames (state : driver_state) : List String :=
  (memoryEffects state).map (fun recorded => match recorded.sc_effect_request.sc_request_kind0 with
    | SC_cas_expected _ _ _ => "E"
    | SC_cas_object _ => "O"
    | SC_cas_writeback _ => "W"
    | SC_access _ _ => "S"
    | _ => "unexpected")

def atomicObjectPair (state : driver_state) : Bool :=
  let effects := memoryEffects state
  let objectEffects := effects.filter (fun recorded => match recorded.sc_effect_request.sc_request_kind0 with
    | SC_cas_object _ => true | _ => false)
  match objectEffects with
  | [_] => true
  | [readEffect, writeEffect] =>
    readEffect.sc_effect_request.sc_request_id == writeEffect.sc_effect_request.sc_request_id &&
    (effects.zip effects.tail).any (fun (left, right) =>
      left.sc_effect_id == readEffect.sc_effect_id && right.sc_effect_id == writeEffect.sc_effect_id)
  | _ => false

def doubleType : ctype := Ctype [] (Basic (Floating (RealFloating Double)))
def doubleCASResults (fuel : Nat) (objectBits expectedBits : List UInt8) :=
  letI := LemFuel.mk fuel
  let atomicType := Ctype [] (Atomic doubleType)
  let expected := pointer 30 304
  let body := Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "SC double CAS") empty_annotation
    (CompareExchangeStrong (pe (Vctype doubleType)) (pe (Vobject (OVpointer objectPtr)))
      (pe (Vobject (OVpointer expected))) (pe (Vloaded (LVspecified (OVfloating 1.0)))) Seq_cst Seq_cst))))
  let setup := fun (s : driver_state) =>
    let writeBits := fun (base : Int) (bits : List UInt8) memory =>
      bits.zipIdx.foldl (fun bytes (value, offset) => bytes.insert (base + Int.ofNat offset)
        ({value := some value} : CerbMem.AbsByte)) memory
    { s with layout_state := { s.layout_state with
      allocations := (s.layout_state.allocations.insert 20 {base := 200, size := 8, ty := some atomicType}).insert
        30 {base := 304, size := 8, ty := some doubleType}
      bytemap := writeBits 304 expectedBits (writeBits 200 objectBits s.layout_state.bytemap) } }
  runProgram (program body) setup

def doubleCAS (fuel : Nat) (objectBits expectedBits : List UInt8) (succeeded : Bool) : Bool :=
  let results := doubleCASResults fuel objectBits expectedBits
  results.length == 1 && results.all (fun (outcome, _, state) => match outcome with
    | Active result =>
      let bytesAt := fun base => (List.range 8).map (fun offset => byteAt state (base + Int.ofNat offset))
      result.dres_core_value == intval (if succeeded then 1 else 0) &&
      bytesAt 200 == (if succeeded then [0,0,0,0,0,0,0xf0,0x3f] else objectBits).map some &&
      bytesAt 304 == (if succeeded then expectedBits else objectBits).map some && atomicObjectPair state
    | _ => false)

def completed (fuel : Nat) (weak : Bool) (expected : UInt8) (wanted : List Bool) : Bool :=
  let results := runCAS fuel (casExpr weak) (some expected)
  results.length == wanted.length && (results.zip wanted).all (fun ((outcome, _, state), succeeded) =>
    match outcome with
    | Active result =>
      !result.dres_blocked && result.dres_core_value == intval (if succeeded then 1 else 0) &&
      state.sc_pending.isEmpty && byteAt state 200 == some (if succeeded then 9 else 7) &&
      byteAt state 300 == some (if succeeded then expected else 7) &&
      (match memoryEffects state with
       | [expectedRead, objectRead, write] =>
         effectBefore expectedRead objectRead && effectBefore expectedRead write &&
         (if succeeded then
           objectRead.sc_effect_request.sc_request_id == write.sc_effect_request.sc_request_id
          else effectBefore objectRead write &&
           objectRead.sc_effect_request.sc_request_id != write.sc_effect_request.sc_request_id)
       | _ => false)
    | _ => false)

def main (args : List String) : IO UInt32 := do
  let [arg] := args | IO.eprintln "usage: sc-cas-test FUEL"; return 2
  let some fuel := arg.toNat? | IO.eprintln "invalid fuel"; return 2
  let mut good := true
  good := (← check "strong success keeps expected and writes object" (completed fuel false 7 [true])) && good
  good := (← check "strong failure writes expected and keeps object" (completed fuel false 6 [false])) && good
  -- Smt2's exhaustive NDnd runner prepends branch results: the source pick
  -- [true, false] is observed as failure then success, preserving both.
  good := (← check "weak equality retains success and spurious failure" (completed fuel true 7 [false, true])) && good
  good := (← check "weak inequality has only failure" (completed fuel true 6 [false])) && good
  good := (← check "CAS distinguishes positive and negative zero"
    (doubleCAS fuel [0,0,0,0,0,0,0,0] [0,0,0,0,0,0,0,0x80] false)) && good
  good := (← check "CAS succeeds on identical NaN bits"
    (doubleCAS fuel [1,0,0,0,0,0,0xf8,0x7f] [1,0,0,0,0,0,0xf8,0x7f] true)) && good
  good := (← check "CAS fails on different NaN payloads"
    (doubleCAS fuel [1,0,0,0,0,0,0xf8,0x7f] [2,0,0,0,0,0,0xf8,0x7f] false)) && good
  let gap := runCAS fuel (casExpr false) none
  good := (← check "unspecified representation retains both reads and refuses before writes"
    (!gap.isEmpty && gap.all (fun (outcome, _, state) =>
      (memoryEffects state).length == 2 && byteAt state 200 == some 7 && byteAt state 300 == none &&
      match outcome with
      | Killed _ (Other (DErr_concurrency msg)) => msg == "SC representation gap: compare-exchange has unspecified bytes"
      | _ => false))) && good
  let badObject := runCAS fuel (casExpr false Seq_cst Seq_cst (.PV .Prov_none (.PVnull atomicByte))) (some 7)
  good := (← check "object failure preserves completed expected read"
    (!badObject.isEmpty && badObject.all (fun (outcome, _, state) =>
      (memoryEffects state).length == 1 && match outcome with
      | Killed _ (Undef0 _ [UB019_lvalue_not_an_object]) => true
      | _ => false))) && good
  let excluded := runCAS fuel (casExpr false Relaxed Seq_cst) (some 7)
  good := (← check "weak order is refused before expected read"
    (!excluded.isEmpty && excluded.all (fun (outcome, _, state) =>
      (memoryEffects state).isEmpty && match outcome with
      | Killed _ (Other (DErr_concurrency msg)) => msg == "SC model excludes the requested memory order"
      | _ => false))) && good
  for (expected, witness, label) in
      [(7, ["E", "S", "O", "W"], "interleaving after expected read"),
       (6, ["E", "O", "S", "W"], "interleaving before failure write-back")] do
    let results := runCAS fuel (parExpr [casExpr false, interference]) (some expected)
    IO.println s!"{label}: {results.length} alternatives"
    good := (← check label (!results.isEmpty &&
      results.all (fun (outcome, _, state) => atomicObjectPair state && match outcome with
        | Active r => !r.dres_blocked && state.sc_pending.isEmpty
        | _ => false) &&
      results.any (fun (_, _, state) => phaseNames state == witness))) && good
  return if good then 0 else 1
