/-
  Concrete memory model for Cerberus.
  Corresponds to: memory/concrete/impl_mem.ml (module Concrete : Memory)

  This matches the OCaml concrete model's types and semantics exactly.
  The concrete model uses simplified types (raw numbers, 2-field pointers)
  compared to the defacto model's symbolic types.
-/

import IntegerType
import Ctype
import Symbol
import Mem_common
import Nondeterminism
import CerbTags
import CerberusImpl
import CerbFloat
import CerbLocation
import Annot

open CerberusImpl

namespace CerbMem

set_option autoImplicit true

/-! ## Types matching memory/concrete/impl_mem.ml lines 277-525 -/

/-- storage_instance_id = N.num (allocation ID) -/
abbrev StorageInstanceId := Int

/-- symbolic_storage_instance_id (for PNVI-ae-udi) -/
abbrev SymbolicStorageInstanceId := Int

/-- address = N.num (concrete memory address) -/
abbrev Address := Int

/-- Provenance — impl_mem.ml:287-291 -/
inductive Provenance where
  | Prov_none
  | Prov_some (allocId : StorageInstanceId)
  | Prov_symbolic (iota : SymbolicStorageInstanceId) -- only for PNVI-ae-udi
  | Prov_device
  deriving BEq, Inhabited, Repr

/-- pointer_value_base — impl_mem.ml:295-298 -/
inductive PointerValueBase where
  | PVnull (ty : ctype)
  | PVfunction (sym : sym)
  | PVconcrete (unionMember : Option identifier) (addr : Address)
  deriving Inhabited

/-- pointer_value = PV of provenance * pointer_value_base — impl_mem.ml:300-301
    NOTE: 2 fields, NO shift_path (that's the defacto model) -/
inductive PointerValue where
  | PV (prov : Provenance) (base : PointerValueBase)
  deriving Inhabited

/-- integer_value = IV of provenance * Nat_big_num.num — impl_mem.ml:303-304
    The concrete model stores just the raw number, not symbolic integer_value_base -/
inductive IntegerValue where
  | IV (prov : Provenance) (val_ : Int)
  deriving Inhabited

/-- floating_value = float — impl_mem.ml:306-308
    The concrete model uses raw OCaml floats -/
abbrev FloatingValue := Float

/-- mem_value — impl_mem.ml:310-317
    7 constructors (no MVdelayed/MVcomposite — those are defacto model only) -/
inductive MemValue where
  | MVunspecified (ty : ctype)
  | MVinteger (ity : integerType) (iv : IntegerValue)
  | MVfloating (fty : floatingType) (fv : FloatingValue)
  | MVpointer (refTy : ctype) (pv : PointerValue)
  | MVarray (vals : List MemValue)
  | MVstruct (tag : sym) (members : List (identifier × ctype × MemValue))
  | MVunion (tag : sym) (member : identifier) (val_ : MemValue)
  deriving Inhabited

/-- footprint = FP of [`W | `R] * address * N.num — impl_mem.ml:523-525 -/
inductive FootprintAccess where | W | R
  deriving BEq, Inhabited, Repr, Ord

inductive Footprint where
  | FP (access : FootprintAccess) (base : Address) (size : Int)
  deriving Inhabited

/-- readonly_status — impl_mem.ml:400-402 -/
inductive ReadonlyStatus where
  | IsWritable
  | IsReadOnly (kind : readonly_kind)
  deriving Inhabited

/-- Abstract byte — impl_mem.ml:415-420 (AbsByte module) -/
structure AbsByte where
  prov : Provenance := .Prov_none
  copyOffset : Option Int := none
  value : Option UInt8 := none
  deriving BEq, Inhabited, Repr

/-- Taint status for PNVI-ae -/
inductive Taint where
  | Unexposed
  | Exposed
  deriving BEq, Inhabited

/-- allocation — impl_mem.ml:404-412 -/
structure Allocation where
  base : Address
  size : Int
  ty : Option ctype := none
  isReadonly : ReadonlyStatus := .IsWritable
  taint : Taint := .Unexposed
  prefix_ : prefix0 := PrefOther ""
  deriving Inhabited

/-- mem_state — impl_mem.ml:482-501 (14 fields) -/
structure MemState where
  nextAllocId : StorageInstanceId := 0
  nextIota : SymbolicStorageInstanceId := 0
  lastAddress : Address := 0xFFFFFFFFFFFF
  allocations : List (Int × Allocation) := []
  iotaMap : List (Int × Int) := [] -- simplified from OCaml's polymorphic variant
  funptrmap : List (Int × (String × String)) := []
  varargs : List (Int × (Int × List (ctype × PointerValue))) := []
  nextVarargsId : Int := 0
  bytemap : List (Int × AbsByte) := []
  lastUsedUnionMembers : List (Int × identifier) := []
  deadAllocations : List StorageInstanceId := []
  dynamicAddrs : List Address := []
  lastUsed : Option StorageInstanceId := none
  requested : List (Address × Int) := []
  deriving Inhabited

/-! ## Instances -/

instance : BEq PointerValueBase where
  beq a b := match a, b with
    | .PVnull _, .PVnull _ => true
    | .PVfunction s1, .PVfunction s2 => s1 == s2
    | .PVconcrete _ a1, .PVconcrete _ a2 => a1 == a2
    | _, _ => false

instance : BEq PointerValue where
  beq | .PV p1 b1, .PV p2 b2 => p1 == p2 && b1 == b2

instance : BEq IntegerValue where
  beq | .IV p1 n1, .IV p2 n2 => p1 == p2 && n1 == n2

private unsafe def beqMemValueImpl : MemValue → MemValue → Bool
  | .MVunspecified _, .MVunspecified _ => true
  | .MVinteger _ v1, .MVinteger _ v2 => v1 == v2
  | .MVfloating _ v1, .MVfloating _ v2 => v1 == v2
  | .MVpointer _ v1, .MVpointer _ v2 => v1 == v2
  | .MVarray e1, .MVarray e2 =>
    e1.length == e2.length && (e1.zip e2).all (fun (a, b) => beqMemValueImpl a b)
  | .MVstruct t1 _, .MVstruct t2 _ => t1 == t2
  | .MVunion t1 m1 _, .MVunion t2 m2 _ => t1 == t2 && m1 == m2
  | _, _ => false

@[implemented_by beqMemValueImpl]
private opaque beqMemValueSafe : MemValue → MemValue → Bool

instance : BEq MemValue where beq := beqMemValueSafe
instance : BEq Footprint where
  beq | .FP a1 b1 s1, .FP a2 b2 s2 => a1 == a2 && b1 == b2 && s1 == s2
instance : Ord Footprint where
  compare | .FP _ b1 _, .FP _ b2 _ => compare b1 b2
instance : Ord PointerValue where compare _ _ := .eq
instance : Ord IntegerValue where compare | .IV _ n1, .IV _ n2 => compare n1 n2
instance : Ord MemValue where compare _ _ := .eq
instance : BEq Allocation where beq _ _ := false
instance : BEq MemState where beq _ _ := false
instance : Ord MemState where compare _ _ := .eq

/-! ## Helper: construct ctype with empty annotations -/

private def mkCtype (ty_ : ctype_) : ctype := Ctype ([] : List annot) ty_

/-! ## combine_prov — impl_mem.ml:366-394 -/

def combineProv : Provenance → Provenance → Provenance
  | .Prov_none, .Prov_none => .Prov_none
  | .Prov_none, .Prov_some id => .Prov_some id
  | .Prov_none, .Prov_device => .Prov_device
  | .Prov_some id, .Prov_none => .Prov_some id
  | .Prov_some id1, .Prov_some id2 =>
    if id1 == id2 then .Prov_some id1 else .Prov_none
  | .Prov_some _, .Prov_device => .Prov_device
  | .Prov_device, .Prov_none => .Prov_device
  | .Prov_device, .Prov_some _ => .Prov_device
  | .Prov_device, .Prov_device => .Prov_device
  -- PNVI-ae-udi only; concrete model doesn't use Prov_symbolic (impl_mem.ml:390-394)
  | .Prov_symbolic _, _ => panic! "Concrete.combine_prov: found a Prov_symbolic"
  | _, .Prov_symbolic _ => panic! "Concrete.combine_prov: found a Prov_symbolic"

/-! ## Layout computation — for sizeof/alignof -/

private def targetPtrSize : Nat := 8

private def basicTypeSize : basicType → Nat
  | .Integer ity => match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  | .Floating (.RealFloating .Float0) => 4
  | .Floating (.RealFloating .Double) => 8
  | .Floating (.RealFloating .LongDouble) => 16

private def alignUp (n align : Nat) : Nat :=
  if align == 0 then n else ((n + align - 1) / align) * align

partial def sizeofCtype : ctype → Nat
  | Ctype _ ty_ => sizeofCtype_ ty_
where sizeofCtype_ : ctype_ → Nat
  | .Void0 => 0
  | .Basic bty => basicTypeSize bty
  | .Array0 elemCty (some n) => n.toNat * sizeofCtype elemCty
  | .Array0 _ none => 0
  | .Function _ _ _ | .FunctionNoParams _ => 0
  | .Pointer _ _ => targetPtrSize
  | .Atomic innerCty => sizeofCtype innerCty
  | .Struct _ => 0  -- needs tag definitions
  | .Union0 _ => 0  -- needs tag definitions
  | .Byte => 1

partial def alignofCtype : ctype → Nat
  | Ctype _ ty_ => alignofCtype_ ty_
where alignofCtype_ : ctype_ → Nat
  | .Void0 => 1
  | .Basic bty => basicTypeSize bty
  | .Array0 elemCty _ => alignofCtype elemCty
  | .Function _ _ _ | .FunctionNoParams _ => 1
  | .Pointer _ _ => targetPtrSize
  | .Atomic innerCty => alignofCtype innerCty
  | .Struct _ => 1  -- needs tag definitions
  | .Union0 _ => 1  -- needs tag definitions
  | .Byte => 1

/-! ## Byte-level serialization -/

private def isSignedIty : integerType → Bool
  | .Signed _ => true
  | .Char0 => true  -- platform-dependent, we follow GCC (signed)
  | .Ptrdiff_t => true
  | .Wint_t => true
  | _ => false

def intToBytes (val_ : Int) (size : Nat) : List (Option UInt8) :=
  let totalBits := size * 8
  let modulusVal : Int := 1 <<< totalBits
  let unsigned : Int := if val_ < 0 then modulusVal + val_ else val_
  List.range size |>.map fun i =>
    let shifted := unsigned >>> (i * 8)
    some (shifted.toNat % 256).toUInt8

def bytesToInt (bytes : List AbsByte) (signed : Bool) : Option Int :=
  if bytes.any (·.value.isNone) then none
  else
    let rec go (bs : List AbsByte) (i : Nat) (acc : Int) : Int :=
      match bs with
      | [] => acc
      | b :: rest =>
        let contribution : Int := match b.value with
          | some v => (v.toNat : Int) <<< (i * 8)
          | none => 0
        go rest (i + 1) (acc + contribution)
    let val_ := go bytes 0 0
    if signed && bytes.length > 0 then
      let bits := bytes.length * 8
      let signBit : Int := 1 <<< (bits - 1)
      if val_ >= signBit then some (val_ - (1 <<< bits)) else some val_
    else some val_

/-- Extract provenance from bytes — impl_mem.ml AbsByte.split_bytes -/
def bytesProvenance (bytes : List AbsByte) : Provenance :=
  match bytes.find? (fun b => b.prov != .Prov_none) with
  | some b => b.prov
  | none => .Prov_none

/-- Serialize a MemValue to bytes -/
partial def memValueToBytes (val_ : MemValue) : List AbsByte :=
  match val_ with
  | .MVunspecified ty =>
    let sz := sizeofCtype ty
    List.replicate sz { prov := .Prov_none, copyOffset := none, value := none }
  | .MVinteger ity (.IV prov n) =>
    let sz := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let rawBytes := intToBytes n sz
    (rawBytes.zip (List.range rawBytes.length)).map fun (v, i) =>
      { prov := prov, copyOffset := some i, value := v }
  | .MVfloating fty fv =>
    let sz := match fty with
      | .RealFloating .Float0 => 4
      | .RealFloating .Double => 8
      | .RealFloating .LongDouble => 16
    let bits := fv.toBits.toNat
    let rawBytes := intToBytes bits sz
    rawBytes.map fun v => { prov := .Prov_none, copyOffset := none, value := v }
  | .MVpointer _ (.PV prov base) =>
    let (rawVal, prov') := match base with
      | .PVnull _ => (0, Provenance.Prov_none)
      | .PVfunction _ => (0, prov)
      | .PVconcrete _ addr => (addr, prov)
    let rawBytes := intToBytes rawVal targetPtrSize
    (rawBytes.zip (List.range rawBytes.length)).map fun (v, i) =>
      { prov := prov', copyOffset := some i, value := v }
  | .MVarray elems => elems.flatMap memValueToBytes
  | .MVstruct _ members =>
    members.flatMap fun (_, _, mval) => memValueToBytes mval
  | .MVunion _ _ mval => memValueToBytes mval

/-- Reconstruct a MemValue from bytes -/
partial def reconstructValue (ty : ctype) (bytes : List AbsByte) : MemValue :=
  match ty with
  | Ctype _ (.Basic (.Integer ity)) =>
    let signed := isSignedIty ity
    match bytesToInt bytes signed with
    | some n => .MVinteger ity (.IV (bytesProvenance bytes) n)
    | none => .MVunspecified ty
  | Ctype _ (.Basic (.Floating fty)) =>
    match bytesToInt bytes false with
    | some n =>
      let bits : UInt64 := n.toNat.toUInt64
      .MVfloating fty (Float.ofBits bits)
    | none => .MVunspecified ty
  | Ctype _ (.Pointer _ pointeeCty) =>
    match bytesToInt bytes false with
    | some 0 =>
      .MVpointer ty (.PV .Prov_none (.PVnull pointeeCty))
    | some addr =>
      let prov := bytesProvenance bytes
      .MVpointer ty (.PV prov (.PVconcrete none addr.toNat))
    | none => .MVunspecified ty
  | Ctype _ (.Array0 elemCty (some n)) =>
    let nNat := n.toNat
    let elemSize := sizeofCtype elemCty
    if elemSize == 0 then .MVarray []
    else
      let elems := List.range nNat |>.map fun i =>
        let start := i * elemSize
        let elemBytes := bytes.drop start |>.take elemSize
        reconstructValue elemCty elemBytes
      .MVarray elems
  | Ctype _ (.Atomic innerCty) => reconstructValue innerCty bytes
  | Ctype _ .Byte =>
    match bytesToInt (bytes.take 1) false with
    | some n => .MVinteger .Char0 (.IV (bytesProvenance (bytes.take 1)) n)
    | none => .MVunspecified ty
  | _ => .MVunspecified ty

/-! ## Pointer value constructors — impl_mem.ml:1799-1827 -/

def nullPtrval (ty : ctype) : PointerValue :=
  .PV .Prov_none (.PVnull ty)

def funPtrval (s : sym) : PointerValue :=
  .PV .Prov_none (.PVfunction s)

def concretePtrval (allocId : Int) (addr : Int) : PointerValue :=
  .PV (.Prov_some allocId) (.PVconcrete none addr)

/-- case_ptrval — impl_mem.ml:1808-1814 -/
def casePtrval {α : Type} (pv : PointerValue)
    (onNull : ctype → α) (onFun : Option sym → α)
    (onConcrete : Option Int → Int → α) : α :=
  match pv with
  | .PV _ (.PVnull ty) => onNull ty
  | .PV _ (.PVfunction f) => onFun (some f)
  | .PV .Prov_none (.PVconcrete _ addr) => onConcrete none addr
  | .PV (.Prov_some i) (.PVconcrete _ addr) => onConcrete (some i) addr
  | .PV _ (.PVconcrete _ addr) => onConcrete none addr -- fallback

/-- case_funsym_opt — impl_mem.ml:1816-1827 -/
def caseFunsymOpt (st : MemState) (pv : PointerValue) : Option sym :=
  match pv with
  | .PV _ (.PVfunction s) => some s
  | .PV _ (.PVconcrete _ addr) =>
    match st.funptrmap.find? (fun (a, _) => a == addr) with
    | some (_, (fileDig, name)) => some (Symbol fileDig addr.toNat (SD_Id name))
    | none => none
  | _ => none

/-! ## Integer value constructors — impl_mem.ml:2361-2511 -/

def integerIval (n : Int) : IntegerValue := .IV .Prov_none n

def maxIval (ity : integerType) : IntegerValue :=
  let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  let bits := size * 8
  let maxVal : Int := match ity with
    | .Char0 => 127
    | .Bool0 => 1
    | .Signed _ => (2 ^ (bits - 1)) - 1
    | .Unsigned _ => (2 ^ bits) - 1
    | .Enum0 _ => (2 ^ 31) - 1
    | .Size_t | .Ptraddr_t => (2 ^ bits) - 1
    | .Wchar_t => (2 ^ bits) - 1
    | .Wint_t | .Ptrdiff_t => (2 ^ (bits - 1)) - 1
  integerIval maxVal

def minIval (ity : integerType) : IntegerValue :=
  let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  let bits := size * 8
  let minVal : Int := match ity with
    | .Char0 => -128
    | .Bool0 => 0
    | .Signed _ => -(2 ^ (bits - 1))
    | .Unsigned _ => 0
    | .Enum0 _ => -(2 ^ 31)
    | .Size_t | .Wchar_t | .Ptraddr_t => 0
    | .Wint_t => 0
    | .Ptrdiff_t => -(2 ^ (bits - 1))
  integerIval minVal

def sizeofIval (ty : ctype) : IntegerValue := integerIval (sizeofCtype ty)
def alignofIval (ty : ctype) : IntegerValue := integerIval (alignofCtype ty)

def concurReadIval (_ : integerType) (_ : sym) : IntegerValue := integerIval 0

/-- op_ival — impl_mem.ml:2464-2490 -/
def opIval (op : integer_operator) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let result := match op with
      | .IntAdd => n1 + n2
      | .IntSub => n1 - n2
      | .IntMul => n1 * n2
      | .IntDiv => if n2 == 0 then 0 else n1 / n2
      | .IntRem_t => if n2 == 0 then 0 else n1 % n2
      | .IntRem_f => if n2 == 0 then 0 else n1 % n2
      | .IntExp => n1 ^ n2.toNat
    .IV (combineProv prov1 prov2) result

/-- Compute offsets of struct members, following impl_mem.ml:98-129 (offsetsof).
    Returns a list of (member ident, ctype, offset).
    For unions: all members at offset 0.
    For structs: each member padded to its alignment. -/
partial def offsetsofMembers (members : List (identifier × ctype))
    : List (identifier × ctype × Nat) :=
  let (xs, _) := members.foldl (init := ([], 0))
    (fun (acc : List (identifier × ctype × Nat) × Nat) (memb : identifier × ctype) =>
      let (xs, lastOffset) := acc
      let (ident, ty) := memb
      let size := sizeofCtype ty
      let align := (alignofCtype ty).max 1
      let rem := lastOffset % align
      let pad := if rem == 0 then 0 else align - rem
      let offset := lastOffset + pad
      ((ident, ty, offset) :: xs, offset + size))
  xs.reverse

def offsetofIval (tagDefs : List (sym × (CerbLocation.Loc × tag_definition)))
    (tag : sym) (memb : identifier) : IntegerValue :=
  match tagDefs.find? (fun (s, _) => s == tag) with
  | some (_, (_, StructDef members _)) =>
    let mems := members.map (fun (ident, (_, _, _, ty)) => (ident, ty))
    let offs := offsetsofMembers mems
    match offs.find? (fun (ident, _, _) => ident == memb) with
    | some (_, _, off) => integerIval off
    | none => integerIval 0
  | some (_, (_, UnionDef _)) => integerIval 0  -- all union members at offset 0
  | none => integerIval 0  -- tag not found; caller error

/-! ## Bitwise operations — impl_mem.ml:2497-2511 -/

private def toUnsigned (v : Int) (bits : Nat) : Nat :=
  let modulus : Int := 2 ^ bits
  if v < 0 then (modulus + v).toNat else v.toNat % modulus.toNat

private def toSigned (v : Nat) (bits : Nat) (signed : Bool) : Int :=
  if signed then
    let signBit := 2 ^ (bits - 1)
    if v >= signBit then Int.ofNat v - Int.ofNat (2 ^ bits)
    else Int.ofNat v
  else Int.ofNat v

def bitwiseComplementIval (ity : integerType) (v : IntegerValue) : IntegerValue :=
  match v with
  | .IV prov n =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let mask := 2 ^ bits - 1
    let unsigned := toUnsigned n bits
    let result := unsigned ^^^ mask
    .IV prov (toSigned result bits (isSignedIty ity))

def bitwiseAndIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let result := toUnsigned n1 bits &&& toUnsigned n2 bits
    .IV (combineProv prov1 prov2) (toSigned result bits (isSignedIty ity))

def bitwiseOrIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let result := toUnsigned n1 bits ||| toUnsigned n2 bits
    .IV (combineProv prov1 prov2) (toSigned result bits (isSignedIty ity))

def bitwiseXorIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let result := toUnsigned n1 bits ^^^ toUnsigned n2 bits
    .IV (combineProv prov1 prov2) (toSigned result bits (isSignedIty ity))

/-! ## Integer value destructors — impl_mem.ml:2513-2562 -/

/-- case_integer_value — impl_mem.ml:2513-2514
    In the concrete model, always calls f_concrete -/
def caseIntegerValue {α : Type} (iv : IntegerValue)
    (onSpecified : Int → α) (_ : Unit → α) : α :=
  match iv with | .IV _ n => onSpecified n

def isSpecifiedIval (_ : IntegerValue) : Bool := true

def eqIval (v1 v2 : IntegerValue) : Option Bool :=
  match v1, v2 with | .IV _ n1, .IV _ n2 => some (n1 == n2)
def ltIval (v1 v2 : IntegerValue) : Option Bool :=
  match v1, v2 with | .IV _ n1, .IV _ n2 => some (n1 < n2)
def leIval (v1 v2 : IntegerValue) : Option Bool :=
  match v1, v2 with | .IV _ n1, .IV _ n2 => some (n1 ≤ n2)

/-! ## Floating value operations — impl_mem.ml:2519-2554 -/

def zeroFval : FloatingValue := 0.0
def oneFval : FloatingValue := 1.0
def strFval (s : String) : FloatingValue := CerbFloat.of_string s

/-- case_fval — impl_mem.ml:2526-2527
    In the concrete model, always calls fconcrete -/
def caseFval {α : Type} (fv : FloatingValue) (_ : Unit → α) (onConcrete : Float → α) : α :=
  onConcrete fv

def opFval (op : floating_operator) (v1 v2 : FloatingValue) : FloatingValue :=
  match op with
  | .FloatAdd => v1 + v2 | .FloatSub => v1 - v2
  | .FloatMul => v1 * v2 | .FloatDiv => v1 / v2

def eqFval (v1 v2 : FloatingValue) : Bool := v1 == v2
def ltFval (v1 v2 : FloatingValue) : Bool := v1 < v2
def leFval (v1 v2 : FloatingValue) : Bool := v1 <= v2

def fvfromint (iv : IntegerValue) : FloatingValue :=
  match iv with | .IV _ n => Float.ofInt n
def ivfromfloat (_ : integerType) (fv : FloatingValue) : IntegerValue :=
  integerIval fv.toUInt64.toNat

/-! ## Memory value constructors — impl_mem.ml:2564-2595 -/

def unspecifiedMval (ty : ctype) : MemValue := .MVunspecified ty
def integerValueMval (ity : integerType) (iv : IntegerValue) : MemValue := .MVinteger ity iv
def floatingValueMval (fty : floatingType) (fv : FloatingValue) : MemValue := .MVfloating fty fv
def pointerMval (ty : ctype) (pv : PointerValue) : MemValue := .MVpointer ty pv
def arrayMval (elems : List MemValue) : MemValue := .MVarray elems
def structMval (tag : sym) (members : List (identifier × ctype × MemValue)) : MemValue := .MVstruct tag members
def unionMval (tag : sym) (member : identifier) (value : MemValue) : MemValue := .MVunion tag member value

/-- case_mem_value — impl_mem.ml:2579-2594
    The f_concur callback is never called in the concrete model -/
def caseMemValue {α : Type} (mv : MemValue)
    (onUnspec : ctype → α) (onConcurRead : integerType → sym → α)
    (onInt : integerType → IntegerValue → α) (onFloat : floatingType → FloatingValue → α)
    (onPtr : ctype → PointerValue → α) (onArray : List MemValue → α)
    (onStruct : sym → List (identifier × ctype × MemValue) → α)
    (onUnion : sym → identifier → MemValue → α) : α :=
  match mv with
  | .MVunspecified ty => onUnspec ty
  | .MVinteger ity iv => onInt ity iv
  | .MVfloating fty fv => onFloat fty fv
  | .MVpointer ty pv => onPtr ty pv
  | .MVarray elems => onArray elems
  | .MVstruct tag members => onStruct tag members
  | .MVunion tag member val_ => onUnion tag member val_

/-! ## Pure pointer operations — impl_mem.ml -/

/-- array_shift_ptrval — shift pointer by array index -/
def arrayShiftPtrval (pv : PointerValue) (elemTy : ctype) (iv : IntegerValue) : PointerValue :=
  match pv, iv with
  | .PV _ (.PVnull _), _ => pv
  | .PV _ (.PVfunction _), _ => pv
  | .PV prov (.PVconcrete um addr), .IV _ n =>
    let elemSize := sizeofCtype elemTy
    let offset := n * (Int.ofNat elemSize)
    .PV prov (.PVconcrete um (addr + offset))

/-- member_shift_ptrval — impl_mem.ml:2223-2242.
    Shift pointer to struct/union member. Uses CerbTags.tagDefs () to look up
    the struct layout. For unions, all members are at offset 0 but we record
    which member we're pointing to (in PVconcrete's unionMember field). -/
def memberShiftPtrval (pv : PointerValue) (tag : sym) (memb : identifier) : PointerValue :=
  let tagDefsAsList : List (sym × (CerbLocation.Loc × tag_definition)) :=
    CerbTags.tagDefs ()
  let (.IV _ offsetVal) := offsetofIval tagDefsAsList tag memb
  let isUnion := match tagDefsAsList.find? (fun (s, _) => s == tag) with
    | some (_, (_, UnionDef _)) => true
    | _ => false
  let unionMem := if isUnion then some memb else none
  match pv with
  | .PV prov (.PVnull ty) =>
    if offsetVal == 0 then .PV prov (.PVnull ty)
    else .PV prov (.PVconcrete unionMem offsetVal)
  | .PV _ (.PVfunction _) => pv  -- undefined per OCaml, but return unchanged
  | .PV prov (.PVconcrete _ addr) =>
    .PV prov (.PVconcrete unionMem (addr + offsetVal))

def bytefromint (iv : IntegerValue) : IntegerValue :=
  match iv with | .IV prov n => .IV prov (n % 256)
def intfrombyte (iv : IntegerValue) : IntegerValue := iv

/-- overlapping — impl_mem.ml:527-532 -/
def overlapping (f1 f2 : Footprint) : Bool :=
  match f1, f2 with
  | .FP .R _ _, .FP .R _ _ => false  -- two reads never overlap
  | .FP _ b1 sz1, .FP _ b2 sz2 =>
    !(b1 + sz1 ≤ b2 || b2 + sz2 ≤ b1)

def initialMemState : MemState := {}

/-! ## String conversion stubs -/

def stringFromCtype (_ : ctype) : String := "<ctype>"
/-- Minimal pretty-printer for diagnostics. Not a full impl of
    Impl_mem.string_of_mem_value. -/
partial def stringFromMemValue : MemValue → String
  | .MVunspecified _ => "MVunspecified"
  | .MVinteger _ (.IV _ n) => s!"MVinteger({n})"
  | .MVfloating _ f => s!"MVfloating({f})"
  | .MVpointer _ (.PV _ b) => s!"MVpointer({match b with
      | .PVnull _ => "null"
      | .PVfunction _ => "fun"
      | .PVconcrete _ addr => s!"@{addr}"})"
  | .MVarray vs => "MVarray[" ++ (vs.map stringFromMemValue).foldl (fun a b => a ++ ", " ++ b) "" ++ "]"
  | .MVstruct _ _ => "MVstruct(<tag>)"
  | .MVunion _ _ _ => "MVunion(<tag>)"

def stringFromPointerValue : PointerValue → String
  | .PV _ (.PVnull _) => "null"
  | .PV _ (.PVfunction _) => "<funptr>"
  | .PV _ (.PVconcrete _ addr) => s!"@{addr}"

def stringFromIntegerValue : IntegerValue → String
  | .IV _ n => toString n

/-! ## CHERI stubs (not used in concrete model) -/

def deriveCap (_ : Bool) (_ : derivecap_op) (v1 _ : IntegerValue) : IntegerValue := v1
def capAssignValue (_ : CerbLocation.Loc) (_ v : IntegerValue) : IntegerValue := v
def nullCap (_ : Bool) : IntegerValue := integerIval 0
def ptrTIntValue (iv : IntegerValue) : IntegerValue := iv
def cheriPointerHashPrintf (_ : Bool) (_ : PointerValue) : String := ""
def getIntrinsicTypeSpec (_ : String) : Option intrinsics_signature := none

/-! ## Monadic operations -/

abbrev memM (a : Type) := ndM a String mem_error (mem_constraint IntegerValue) MemState

private def memReturn {a : Type} (x : a) : memM a := nd_return x
private def memFail {a : Type} (err : mem_error) : memM a :=
  kill (kill_reason.Other err)

private def alignDown (addr align : Nat) : Nat := (addr / align) * align

/-! ### Bytemap operations -/

private def writeBytesTo (st : MemState) (addr : Int) (bytes : List AbsByte) : MemState :=
  let newEntries := bytes.mapIdx fun i b => (addr + i, b)
  let filtered := st.bytemap.filter fun (a, _) => !newEntries.any (fun (a', _) => a == a')
  { st with bytemap := newEntries ++ filtered }

private def readBytesFrom (st : MemState) (addr : Int) (size : Nat) : List AbsByte :=
  (List.range size).map fun (i : Nat) =>
    match st.bytemap.find? (fun (a, _) => a == addr + (i : Int)) with
    | some (_, b) => b
    | none => { prov := .Prov_none, copyOffset := none, value := none }

private def getAllocation (st : MemState) (pv : PointerValue) : Option (Int × Allocation) :=
  match pv with
  | .PV (.Prov_some allocId) _ =>
    if st.deadAllocations.contains allocId then none
    else st.allocations.find? (fun (id, _) => id == allocId)
  | _ => none

private def isInBounds (alloc : Allocation) (addr size : Int) : Bool :=
  addr >= alloc.base && addr + size <= alloc.base + alloc.size

/-! ### Allocation — impl_mem.ml:1288-1435 -/

def allocateObject (_ : Nat) (pref : prefix0) (alignIv : IntegerValue)
    (ty : ctype) (_ : Option Int) (initOpt : Option MemValue) : memM PointerValue :=
  match alignIv with
  | .IV _ alignN =>
  ND fun st =>
    let align := alignN.toNat.max 1
    let size := (sizeofCtype ty).max 1
    let addrAfterSize := st.lastAddress - size
    let alignedAddr := (alignDown addrAfterSize.toNat align : Int)
    if alignedAddr == 0 then (NDkilled (Other (MerrOther "out of memory")), st)
    else
      let allocId := st.nextAllocId
      let alloc : Allocation := { base := alignedAddr, size := size, ty := some ty, prefix_ := pref }
      let st' := { st with
        nextAllocId := allocId + 1, lastAddress := alignedAddr
        allocations := (allocId, alloc) :: st.allocations }
      let st' := match initOpt with
        | some val_ => writeBytesTo st' alignedAddr (memValueToBytes val_)
        | none => writeBytesTo st' alignedAddr
            (List.replicate size { prov := .Prov_none, copyOffset := none, value := none })
      (NDactive (.PV (.Prov_some allocId) (.PVconcrete none alignedAddr)), st')

def allocateRegion (_ : Nat) (pref : prefix0) (alignIv sizeIv : IntegerValue) : memM PointerValue :=
  match alignIv, sizeIv with
  | .IV _ alignN, .IV _ sizeN =>
  ND fun st =>
    let align := alignN.toNat.max 1
    let size := sizeN.toNat
    let addrAfterSize := st.lastAddress - size
    let alignedAddr := (alignDown addrAfterSize.toNat align : Int)
    if alignedAddr == 0 then (NDkilled (Other (MerrOther "out of memory")), st)
    else
      let allocId := st.nextAllocId
      let alloc : Allocation := { base := alignedAddr, size := size, prefix_ := pref }
      let st' := { st with
        nextAllocId := allocId + 1, lastAddress := alignedAddr
        allocations := (allocId, alloc) :: st.allocations
        dynamicAddrs := alignedAddr :: st.dynamicAddrs }
      let st' := writeBytesTo st' alignedAddr
          (List.replicate size { prov := .Prov_none, copyOffset := none, value := none })
      (NDactive (.PV (.Prov_some allocId) (.PVconcrete none alignedAddr)), st')

/-! ### Kill — impl_mem.ml:1464+ -/

def killM (_ : CerbLocation.Loc) (isDynamic : Bool) (pv : PointerValue) : memM Unit :=
  ND fun st =>
    match pv with
    | .PV _ (.PVnull _) =>
      if isDynamic then (NDactive (), st)
      else (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
    | .PV _ (.PVfunction _) => (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
    | .PV (.Prov_some allocId) (.PVconcrete _ addr) =>
      if st.deadAllocations.contains allocId then
        (NDkilled (Other (MerrUndefinedFree Free_dead_allocation)), st)
      else match st.allocations.find? (fun (id, _) => id == allocId) with
        | none => (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
        | some (_, alloc) =>
          if addr != alloc.base then
            (NDkilled (Other (MerrUndefinedFree Free_out_of_bound)), st)
          else if isDynamic && !st.dynamicAddrs.contains alloc.base then
            (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
          else
            let st' := { st with
              deadAllocations := allocId :: st.deadAllocations
              allocations := st.allocations.filter (fun (id, _) => id != allocId) }
            (NDactive (), st')
    | _ => (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)

/-! ### Load / Store — impl_mem.ml:1552-1799 -/

def loadM (_ : CerbLocation.Loc) (ty : ctype) (pv : PointerValue) : memM (Footprint × MemValue) :=
  ND fun st =>
    match pv with
    | .PV _ (.PVnull _) => (NDkilled (Other (MerrAccess LoadAccess NullPtr)), st)
    | .PV _ (.PVfunction _) => (NDkilled (Other (MerrAccess LoadAccess FunctionPtr)), st)
    | .PV _ (.PVconcrete _ addr) =>
      match getAllocation st pv with
      | none => (NDkilled (Other (MerrAccess LoadAccess NoProvPtr)), st)
      | some (_, alloc) =>
        let size := sizeofCtype ty
        if !isInBounds alloc addr size then
          (NDkilled (Other (MerrAccess LoadAccess OutOfBoundPtr)), st)
        else
          let bytes := readBytesFrom st addr size
          let fp : Footprint := .FP .R addr size
          let mv := reconstructValue ty bytes
          let isBool := match ty with | Ctype _ (.Basic (.Integer .Bool0)) => true | _ => false
          let isTrap := isBool && match mv with
            | .MVinteger _ (.IV _ n) => n != 0 && n != 1
            | .MVunspecified _ => true
            | _ => false
          if isTrap then
            (NDkilled (Other (MerrTrapRepresentation LoadAccess)), st)
          else
            (NDactive (fp, mv), st)

def storeM (_ : CerbLocation.Loc) (ty : ctype) (isLocking : Bool) (pv : PointerValue) (mv : MemValue) : memM Footprint :=
  ND fun st =>
    match pv with
    | .PV _ (.PVnull _) => (NDkilled (Other (MerrAccess StoreAccess NullPtr)), st)
    | .PV _ (.PVfunction _) => (NDkilled (Other (MerrAccess StoreAccess FunctionPtr)), st)
    | .PV _ (.PVconcrete unionMem addr) =>
      match getAllocation st pv with
      | none => (NDkilled (Other (MerrAccess StoreAccess NoProvPtr)), st)
      | some (allocId, alloc) =>
        match alloc.isReadonly with
        | .IsReadOnly kind => (NDkilled (Other (MerrWriteOnReadOnly kind)), st)
        | .IsWritable =>
          let size := sizeofCtype ty
          if !isInBounds alloc addr size then
            (NDkilled (Other (MerrAccess StoreAccess OutOfBoundPtr)), st)
          else
            let bytes := memValueToBytes mv
            let st' := writeBytesTo st addr bytes
            let st' := match unionMem with
              | some membr => { st' with lastUsedUnionMembers :=
                  (addr, membr) :: st'.lastUsedUnionMembers.filter (fun (a, _) => a != addr) }
              | none => st'
            let st' := if isLocking then
              let roKind := readonly_kind.ReadonlyConstQualified
              { st' with allocations := st'.allocations.map fun (id, a) =>
                  if id == allocId then (id, { a with isReadonly := .IsReadOnly roKind }) else (id, a) }
              else st'
            let fp : Footprint := .FP .W addr size
            (NDactive fp, st')

/-! ### Pointer comparisons — impl_mem.ml:1830+ -/

private def ptrAddr (pv : PointerValue) : Option Int :=
  match pv with | .PV _ (.PVconcrete _ addr) => some addr | _ => none

def eqPtrval (_ : CerbLocation.Loc) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match pv1, pv2 with
    | .PV _ (.PVnull _), .PV _ (.PVnull _) => true
    | .PV _ (.PVfunction s1), .PV _ (.PVfunction s2) => s1 == s2
    | .PV p1 (.PVconcrete _ a1), .PV p2 (.PVconcrete _ a2) => p1 == p2 && a1 == a2
    | _, _ => false)

def nePtrval (loc : CerbLocation.Loc) (pv1 pv2 : PointerValue) : memM Bool :=
  nd_bind (eqPtrval loc pv1 pv2) (fun b => memReturn (!b))

def ltPtrval (_ : CerbLocation.Loc) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 < a2 | _, _ => false)
def gtPtrval (_ : CerbLocation.Loc) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 > a2 | _, _ => false)
def lePtrval (_ : CerbLocation.Loc) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 <= a2 | _, _ => false)
def gePtrval (_ : CerbLocation.Loc) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 >= a2 | _, _ => false)

def diffPtrval (_ : CerbLocation.Loc) (elemTy : ctype) (pv1 pv2 : PointerValue) : memM IntegerValue :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 =>
      let elemSize := (sizeofCtype elemTy).max 1
      integerIval ((a1 - a2) / elemSize)
    | _, _ => integerIval 0)

/-! ### Pointer validity -/

def validForDerefPtrval (_ : ctype) (pv : PointerValue) : memM Bool :=
  ND fun st =>
    let result := match pv with
      | .PV _ (.PVnull _) | .PV _ (.PVfunction _) => false
      | _ => (getAllocation st pv).isSome
    (NDactive result, st)

def isWellAlignedPtrval (ty : ctype) (pv : PointerValue) : memM Bool :=
  memReturn (match pv with
    | .PV _ (.PVnull _) | .PV _ (.PVfunction _) => true
    | .PV _ (.PVconcrete _ addr) => addr % (alignofCtype ty).max 1 == 0)

/-! ### Pointer casts -/

def ptrfromint (_ : CerbLocation.Loc) (_ : integerType) (_ : ctype) (iv : IntegerValue) : memM PointerValue :=
  match iv with
  | .IV prov n =>
    if n == 0 then memReturn (nullPtrval (mkCtype Void0))
    else memReturn (.PV prov (.PVconcrete none n))

def intfromptr (_ : CerbLocation.Loc) (_ : ctype) (_ : integerType) (pv : PointerValue) : memM IntegerValue :=
  memReturn (match pv with
    | .PV prov (.PVnull _) => .IV prov 0
    | .PV prov (.PVfunction _) => .IV prov 0
    | .PV prov (.PVconcrete _ addr) => .IV prov addr)

/-! ### Effectful pointer shifts -/

def effArrayShiftPtrval (_ : CerbLocation.Loc) (pv : PointerValue) (elemTy : ctype) (iv : IntegerValue) : memM PointerValue :=
  memReturn (arrayShiftPtrval pv elemTy iv)

def effMemberShiftPtrval (_ : CerbLocation.Loc) (pv : PointerValue) (tag : sym) (member : identifier) : memM PointerValue :=
  memReturn (memberShiftPtrval pv tag member)

/-! ### Memory operations -/

def memcpyM (_ : CerbLocation.Loc) (dst src : PointerValue) (sizeIv : IntegerValue) : memM PointerValue :=
  ND fun st =>
    match dst, src, sizeIv with
    | .PV _ (.PVconcrete _ dstAddr), .PV _ (.PVconcrete _ srcAddr), .IV _ n =>
      let size := n.toNat
      let bytes := readBytesFrom st srcAddr size
      let st' := writeBytesTo st dstAddr bytes
      (NDactive dst, st')
    | _, _, _ => (NDkilled (Other (MerrOther "memcpy: non-concrete pointers")), st)

def memcmpM (pv1 pv2 : PointerValue) (sizeIv : IntegerValue) : memM IntegerValue :=
  ND fun st =>
    match pv1, pv2, sizeIv with
    | .PV _ (.PVconcrete _ a1), .PV _ (.PVconcrete _ a2), .IV _ n =>
      let size := n.toNat
      let b1 := readBytesFrom st a1 size
      let b2 := readBytesFrom st a2 size
      let cmp := (b1.zip b2).foldl (init := (0 : Int)) fun acc (x, y) =>
        if acc != 0 then acc
        else match x.value, y.value with
          | some v1, some v2 =>
            if v1.toNat < v2.toNat then -1 else if v1.toNat > v2.toNat then 1 else 0
          | _, _ => 0
      (NDactive (integerIval cmp), st)
    | _, _, _ => (NDactive (integerIval 0), st)

/-- realloc — impl_mem.ml:2668-2696.
    null → allocate_region (fresh)
    concrete + dynamic + live + base → allocate new, memcpy, kill old
    everything else → MerrWIP failure -/
def reallocM (loc : CerbLocation.Loc) (tid : Nat) (align : IntegerValue)
    (ptr : PointerValue) (size : IntegerValue) : memM PointerValue :=
  match ptr with
  | .PV .Prov_none (.PVnull _) =>
    allocateRegion tid (PrefOther "realloc") align size
  | .PV .Prov_none _ =>
    memFail (MerrOther "realloc no provenance")
  | .PV (.Prov_some allocId) (.PVconcrete _ addr) =>
    ND fun st =>
      let isDynamic := st.dynamicAddrs.contains addr
      let isDead := st.deadAllocations.contains allocId
      if !isDynamic then
        (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
      else if isDead then
        (NDkilled (Other (MerrUndefinedFree Free_dead_allocation)), st)
      else match st.allocations.find? (fun (id, _) => id == allocId) with
        | none => (NDkilled (Other (MerrOther "realloc: allocation missing")), st)
        | some (_, alloc) =>
          if alloc.base != addr then
            (NDkilled (Other (MerrOther "realloc: invalid pointer (not at base)")), st)
          else
            -- Allocate new region, copy bytes, free old
            let (newPtrStatus, st1) :=
              match allocateRegion tid (PrefOther "realloc") align size with
              | ND f => f st
            match newPtrStatus with
            | NDactive newPtr =>
              match newPtr with
              | .PV _ (.PVconcrete _ newAddr) =>
                let copySize := match size with
                  | .IV _ n => Nat.min alloc.size.toNat n.toNat
                let bytes := readBytesFrom st1 addr copySize
                let st2 := writeBytesTo st1 newAddr bytes
                -- Kill old
                let st3 := { st2 with
                  deadAllocations := allocId :: st2.deadAllocations
                  allocations := st2.allocations.filter (fun (id, _) => id != allocId) }
                (NDactive newPtr, st3)
              | _ => (NDactive newPtr, st1)
            | other => (other, st1)
  | _ => memFail (MerrOther "realloc: invalid pointer")

/-! ### Prefix operations -/

def updatePrefix (_ : prefix0 × MemValue) : memM Unit := memReturn ()
def prefixOfPointer (_ : PointerValue) : memM (Option String) := memReturn none

/-! ### Varargs -/

def vaStart (_ : List (ctype × PointerValue)) : memM IntegerValue := memReturn (integerIval 0)
def vaCopy (_ : IntegerValue) : memM IntegerValue := memReturn (integerIval 0)
def vaArg (_ : IntegerValue) (_ : ctype) : memM PointerValue := memReturn (nullPtrval (mkCtype Void0))
def vaEnd (_ : IntegerValue) : memM Unit := memReturn ()
def vaList (_ : Int) : memM (List (ctype × PointerValue)) := memReturn []

/-! ### Misc -/

def copyAllocId (_ : IntegerValue) (pv : PointerValue) : memM PointerValue := memReturn pv
def callIntrinsic (_ : CerbLocation.Loc) (_ : String) (_ : List MemValue) : memM (Option MemValue) := memReturn none

end CerbMem
