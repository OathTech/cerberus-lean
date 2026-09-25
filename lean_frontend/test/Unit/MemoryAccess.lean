import CerbFailProofs
import Unit.MemoryAccessProofs

namespace MemoryAccess
open CerbMem CerbFail
set_option autoImplicit true

def loc := CerbLocation.Loc.other "wp0"
def top : Int := 65536
def base : Int := 65472
def iv := IntegerValue.IV .Prov_none
def uc := unsigned_char
def si := Ctype [] (.Basic (.Integer (.Signed .Int_)))
def bt := Ctype [] (.Basic (.Integer .Bool0))
def dt := Ctype [] (.Basic (.Floating (.RealFloating .Double)))
def pt := Ctype [] (.Pointer no_qualifiers si)
def arrTy := Ctype [] (.Array0 uc (some 4))
def intv t n := MemValue.MVinteger t (iv n)
def bv := intv (.Unsigned .Ichar)
def ptr (offset : Int) := PointerValue.PV (.Prov_some 0) (.PVconcrete none (base + offset))
def opt (f : α → String) : Option α → String | none => "-" | some x => f x

def prov : observed_provenance → String
  | .Observed_no_provenance => "none"
  | .Observed_allocation_provenance n => s!"alloc:{n}"
  | .Observed_symbolic_provenance n => s!"symbolic:{n}"
  | .Observed_device_provenance => "device"
def byte : representation_byte_view → String
  | .Byte_view p off v => s!"{prov p}/{opt toString off}/{opt toString v}"
def pv : PointerValue → String
  | .PV _ (.PVnull _) => "null"
  | .PV _ (.PVfunction _) => "function"
  | .PV p (.PVconcrete _ a) => s!"{match p with | .Prov_some n => toString n | _ => "-"}:{a}"
def ty (t : ctype) : String :=
  if t == uc then "uc" else if t == si then "int" else if t == bt then "bool"
  else if t == dt then "double" else if t == pt then "ptr" else if t == arrTy then "array" else "UNKNOWN"
def value : MemValue → String
  | .MVunspecified t => "unspec:" ++ ty t
  | .MVinteger t (.IV _ n) => (if t == .Bool0 then "b:" else "i:") ++ toString n
  | .MVfloating _ f => s!"f:{f.toBits}"
  | .MVpointer _ p => "p:" ++ pv p
  | .MVarray vs => "a:" ++ String.intercalate "," (vs.map value)
  | .MVstruct _ _ => "UNEXPECTED_STRUCT"
  | .MVunion _ _ _ => "UNEXPECTED_UNION"
termination_by v => sizeOf v

def status : nd_action α String mem_error cs MemState → String
  | .NDactive _ => "active"
  | .NDkilled (.Undef0 _ [.UB012_lvalue_read_trap_representation]) => "trap"
  | .NDkilled (.Other (.MerrOther "after")) => "after"
  | .NDkilled (.Undef0 l [.UB064_modifying_const]) => if l == loc then "readonly" else "BADLOC"
  | .NDkilled (.Undef0 l [.UB019_lvalue_not_an_object]) => if l == loc then "null" else "BADLOC"
  | .NDkilled _ => "UNEXPECTED_KILL"
  | _ => "UNEXPECTED_NODE"

def receipt (name : String) : AccessReceipt → String
  | .Access_receipt l k t p a addr bs v locking =>
    s!"access {name} {if l == loc then "loc" else "BADLOC"} {if k == .LoadAccess then "R" else "W"} {opt (fun b => if b then "1" else "0") locking} {ty t} {pv p} {opt toString a} {addr} {String.intercalate "," (bs.map byte)} {value v}"

-- The production BEq MemState/Allocation instances are intentionally degenerate;
-- compare EVERY sequential field explicitly, rather than relying on those instances.
def roEq : ReadonlyStatus → ReadonlyStatus → Bool
  | .IsWritable, .IsWritable => true
  | .IsReadOnly a, .IsReadOnly b => a == b
  | _, _ => false
def allocEq (a b : Allocation) : Bool :=
  a.base == b.base && a.size == b.size && a.ty == b.ty && roEq a.isReadonly b.isReadonly &&
    a.taint == b.taint && a.prefix_ == b.prefix_
def stateEq (a b : MemState) : Bool :=
  a.nextAllocId == b.nextAllocId && a.nextIota == b.nextIota && a.lastAddress == b.lastAddress &&
  (a.allocations.toList.length == b.allocations.toList.length &&
    (a.allocations.toList.zip b.allocations.toList).all (fun ((ka, va), (kb, vb)) => ka == kb && allocEq va vb)) &&
  a.iotaMap == b.iotaMap && a.funptrmap == b.funptrmap && a.varargs == b.varargs &&
  a.nextVarargsId == b.nextVarargsId && a.bytemap.toList == b.bytemap.toList &&
  a.lastUsedUnionMembers == b.lastUsedUnionMembers && a.deadAllocations == b.deadAllocations &&
  a.dynamicAddrs == b.dynamicAddrs && a.lastUsed == b.lastUsed && a.requested == b.requested

def actionEq [BEq α] : nd_action α String mem_error cs MemState → nd_action α String mem_error cs MemState → Bool
  | .NDactive a, .NDactive b => a == b
  | .NDkilled a, .NDkilled b => a == b
  | _, _ => false

def require (ok : Bool) (msg : String) : IO Unit :=
  unless ok do throw (IO.userError msg)
def enable (st : MemState) : IO MemState := do
  let some st := beginObserving st | throw (IO.userError "observation unsupported")
  return st
def drain (st : MemState) : IO (List AccessReceipt × MemState) := do
  let some p := takeObservations st | throw (IO.userError "observation disabled")
  return p

def run [BEq α] (name : String) (m : CerbMem.memM α) (st : MemState) : IO MemState := do
  let (plain, plainSt) := step m (stopObserving st)
  let (action, observedSt) := step m (← enable st)
  require (actionEq plain action && stateEq plainSt (stopObserving observedSt)) (name ++ ": erasure")
  if name == "same-write" then require (stateEq st plainSt) "same-value control changed state"
  let (rs, st) ← drain observedSt
  let (again, st) ← drain st
  require again.isEmpty (name ++ ": drain")
  IO.println s!"node {name} {status action} {opt toString st.lastUsed} {rs.length}"
  for r in rs do IO.println (receipt name r)
  return st

def setup [LemFuel] : IO MemState := do
  let alloc := allocateRegion 0 (PrefOther "wp0") (iv 1) (iv 64)
  let (a, st) := step alloc (initialMemState top)
  let .NDactive p := a | throw (IO.userError "setup allocation 0")
  let (a, st) := step alloc st
  let .NDactive q := a | throw (IO.userError "setup allocation 1")
  require (pv p == "0:65472" && pv q == "1:65408") "allocation layout"
  return st

def store [LemFuel] t offset v := storeM fmapEmpty (default : CerbTags.TagDefsMap) loc t false (ptr offset) v
def load [LemFuel] t offset := loadM fmapEmpty (default : CerbTags.TagDefsMap) loc t (ptr offset)

def scenarios [LemFuel] (st : MemState) : IO MemState := do
  let st ← run "byte-write" (store uc 0 (bv 42)) st
  let st ← run "same-write" (store uc 0 (bv 42)) st
  let st ← run "byte-read" (load uc 0) st
  let st ← run "int-write" (store si 4 (intv (.Signed .Int_) 16909060)) st
  let st ← run "int-read" (load si 4) st
  let st ← run "byte-update" (store uc 5 (bv 170)) st
  let st ← run "updated-int" (load si 4) st
  let st ← run "ptr-write" (store pt 8 (.MVpointer si (ptr 4))) st
  let st ← run "ptr-read" (load pt 8) st
  let st ← run "float-write" (store dt 16 (.MVfloating (.RealFloating .Double) (Float.ofBits 9223372036854775808))) st
  let st ← run "float-read" (load dt 16) st
  let st ← run "array-write" (store arrTy 24 (.MVarray ([1,2,3,4].map bv))) st
  let st ← run "array-read" (load arrTy 24) st
  let st ← run "unspec-write" (store si 4 (.MVunspecified si)) st
  let st ← run "unspec-read" (load si 4) st
  let st ← run "trap-byte" (store uc 0 (bv 2)) st
  let st ← run "trap-read" (load bt 0) st
  let st ← run "unspec-bool-write" (store bt 0 (.MVunspecified bt)) st
  let st ← run "unspec-bool-read" (load bt 0) st
  let st ← run "null-read" (loadM fmapEmpty default loc uc (.PV .Prov_none (.PVnull uc))) st
  let st ← run "null-write" (storeM fmapEmpty default loc uc false (.PV .Prov_none (.PVnull uc)) (bv 1)) st
  let q := PointerValue.PV (.Prov_some 1) (.PVconcrete none 65408)
  let st ← run "locking-write" (storeM fmapEmpty default loc uc true q (bv 7)) st
  let st ← run "readonly-write" (storeM fmapEmpty default loc uc false q (bv 8)) st
  let st ← run "readonly-read" (loadM fmapEmpty default loc uc q) st
  let st ← run "before-failure" (nd_bind (load uc 24) (fun _ =>
    (kill (.Other (.MerrOther "after")) : CerbMem.memM Unit))) st
  let st ← run "two-before-failure" (nd_bind (store uc 0 (bv 9)) (fun _ =>
    nd_bind (load uc 24) (fun _ => (kill (.Other (.MerrOther "after")) : CerbMem.memM Unit)))) st
  require (takeObservations (stopObserving st)).isNone "disabled drain"
  let (_, pending) := step (store uc 0 (bv 42)) (← enable st)
  let (rs, _) ← drain (← enable pending)
  require (rs.length == 1) "enabling dropped prefix"
  return st

-- Structural observation retains even an unsatisfiable guard. This diagnostic
-- does not solve constraints or claim these are admitted C executions.
def transport [LemFuel] (st : MemState) : IO Unit := do
  let cs := MC_eq (iv 1) (iv 2)
  let child (n : Int) := nd_bind (store uc 0 (bv n)) (fun _ => memReturn n)
  let children := [("left", child 11), ("right", child 12)]
  let cases : List (nd_action Int String mem_error (mem_constraint IntegerValue) MemState) :=
    [NDactive 7, NDkilled (.Other (.MerrOther "after")), NDnd "choice" children,
     NDguard "guard" cs (child 11), NDbranch "branch" cs (child 11) (child 12), NDstep "step" children]
  for node in cases do
    let m := nd_bind (store uc 0 (bv 33)) (fun _ => ND fun s => (node, s))
    let lifted := liftND Prod.fst (fun s out => (out, s.2)) id id m
    let (action, (out, marker)) := step lifted (← enable st, (99 : Nat))
    require (marker == 99) "lift changed enclosing state"
    let (rs, out) ← drain out
    require (rs.length == 1) "lift lost completed prefix"
    let actualByte (n : Int) (s : MemState) := match step (load uc 0) (stopObserving s) with
      | (NDactive (_, v), _) => v == bv n
      | _ => false
    require (actualByte 33 out && out.lastUsed == some 0) "lift lost returned memory state"
    let childCheck (n : Int) (m : ndM Int String mem_error (mem_constraint IntegerValue) (MemState × Nat)) : IO Unit := do
      match step m (out, marker) with
      | (NDactive v, (s, marker)) =>
        let (rs, _) ← drain s
        require (v == n && marker == 99 && rs.length == 1 && actualByte n s) "lift changed child"
      | _ => throw (IO.userError "lift child killed/dropped")
    match node, action with
    | NDactive 7, NDactive 7 => pure ()
    | NDkilled r, NDkilled r' => require (r == r') "lift changed kill"
    | NDnd _ _, NDnd "choice" [("left", l), ("right", r)]
    | NDstep _ _, NDstep "step" [("left", l), ("right", r)] => childCheck 11 l; childCheck 12 r
    | NDguard _ _ _, NDguard "guard" c m => require (c == cs) "lift changed guard"; childCheck 11 m
    | NDbranch _ _ _ _, NDbranch "branch" c l r =>
      require (c == cs) "lift changed branch"; childCheck 11 l; childCheck 12 r
    | _, _ => throw (IO.userError "lift changed node/alternatives/order")
  IO.println "transport active killed nd guard branch step"

end MemoryAccess

def runAll (fuel count : Nat) (enabled : Bool) : IO UInt32 :=
  letI := LemFuel.mk fuel
  do
    let initial ← MemoryAccess.scenarios (← MemoryAccess.setup)
    let mut st := initial
    MemoryAccess.transport st
    if !enabled then st := CerbMem.stopObserving st
    for _ in [:count] do
      let (action, next) := CerbFail.step (MemoryAccess.store MemoryAccess.uc 0 (MemoryAccess.bv 42)) st
      MemoryAccess.require (match action with | .NDactive _ => true | _ => false) "stream primitive failed"
      if enabled then
        let (rs, next) ← MemoryAccess.drain next
        MemoryAccess.require (rs.length == 1) "stream must drain one receipt per primitive"
        st := next
      else
        MemoryAccess.require (CerbMem.takeObservations next).isNone "disabled stream captured"
        st := next
    let retained := match CerbMem.takeObservations st with | none => 0 | some (rs, _) => rs.length
    IO.println s!"stream {if enabled then "on" else "off"} {count} {retained}"
    return 0

def main (args : List String) : IO UInt32 := do
  let [fuelArg, countArg, mode] := args | throw (IO.userError "usage: memory-access-test FUEL ITERATIONS on|off")
  let some fuel := fuelArg.toNat? | return 2
  let some count := countArg.toNat? | return 2
  if mode != "on" && mode != "off" then return 2
  runAll fuel count (mode == "on")
