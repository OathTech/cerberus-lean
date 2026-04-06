/-
  Concrete memory model for Cerberus.
  Corresponds to: memory/concrete/impl_mem.ml
  Following: lean-c-semantics/CerbLean/Memory/{Types,Interface,Concrete,Layout}.lean

  Defines concrete representations for mem.lem opaque types and implements
  all memory operations (allocate, load, store, kill, pointer ops, etc.)
-/

import IntegerType
import Ctype
import Symbol
import Mem_common
import Nondeterminism
import CerberusImpl
import CerbFloat
import CerbLocation
import Annot

open CerberusImpl

namespace CerbMem

/-- Helper to construct a ctype with empty annotations -/
private def mkCtype (ty_ : ctype_) : ctype := Ctype ([] : List annot) ty_

/-! ## Provenance -/

inductive Provenance where
  | none
  | some (allocId : Nat)
  | symbolic (iota : Nat)
  | device
  deriving BEq, Inhabited, Repr

/-! ## Value Types -/

structure IntegerValue where
  val : Int
  prov : Provenance := .none
  deriving Inhabited, Repr

inductive FloatingValue where
  | finite (val : Float)
  | unspecified
  deriving BEq, Inhabited, Repr

inductive PointerValueBase where
  | null (ty : ctype)
  | function (sym : sym)
  | concrete (unionMember : Option identifier) (addr : Nat)
  deriving Inhabited

structure PointerValue where
  prov : Provenance
  base : PointerValueBase
  deriving Inhabited

inductive MemValue where
  | unspecified (ty : ctype)
  | concurRead (ity : integerType) (sym : sym)
  | integer (ity : integerType) (v : IntegerValue)
  | floating (fty : floatingType) (v : FloatingValue)
  | pointer (ty : ctype) (v : PointerValue)
  | array (elems : List MemValue)
  | struct_ (tag : sym) (members : List (identifier × ctype × MemValue))
  | union_ (tag : sym) (member : identifier) (value : MemValue)
  deriving Inhabited

structure Footprint where
  isWrite : Bool
  base : Nat
  size : Nat
  deriving BEq, Inhabited, Repr, Ord

structure AbsByte where
  prov : Provenance := .none
  copyOffset : Option Nat := none
  value : Option UInt8 := none
  deriving BEq, Inhabited, Repr

inductive ReadonlyStatus where
  | writable
  | readonly (kind : readonly_kind)
  deriving Inhabited

structure Allocation where
  base : Nat
  size : Nat
  ty : Option ctype := none
  isReadonly : ReadonlyStatus := .writable
  taint : Bool := false
  name : String := ""
  deriving Inhabited

structure MemState where
  nextAllocId : Nat := 0
  allocations : List (Nat × Allocation) := []
  bytemap : List (Nat × AbsByte) := []
  deadAllocations : List Nat := []
  dynamicAddrs : List Nat := []
  funptrmap : List (Nat × sym) := []
  lastUsedUnionMembers : List (Nat × identifier) := []
  lastAddress : Nat := 0xFFFFFFFFFFFF
  varargs : List (Nat × List (ctype × PointerValue)) := []
  nextVarargsId : Nat := 0
  deriving Inhabited

/-! ## Instances -/

instance : BEq PointerValueBase where
  beq a b := match a, b with
    | .null _, .null _ => true
    | .function s1, .function s2 => s1 == s2
    | .concrete _ a1, .concrete _ a2 => a1 == a2
    | _, _ => false

instance : BEq PointerValue where
  beq a b := a.prov == b.prov && a.base == b.base

instance : BEq IntegerValue where
  beq a b := a.val == b.val && a.prov == b.prov

private unsafe def beqMemValueImpl : MemValue → MemValue → Bool
  | .unspecified _, .unspecified _ => true
  | .integer _ v1, .integer _ v2 => v1 == v2
  | .floating _ v1, .floating _ v2 => v1 == v2
  | .pointer _ v1, .pointer _ v2 => v1 == v2
  | .array e1, .array e2 => e1.length == e2.length && (e1.zip e2).all (fun (a, b) => beqMemValueImpl a b)
  | _, _ => false

@[implemented_by beqMemValueImpl]
private opaque beqMemValueSafe : MemValue → MemValue → Bool

instance : BEq MemValue where beq := beqMemValueSafe
instance : Ord PointerValue where compare _ _ := .eq
instance : Ord IntegerValue where compare a b := compare a.val b.val
instance : Ord FloatingValue where compare _ _ := .eq
instance : Ord MemValue where compare _ _ := .eq
instance : BEq Allocation where beq _ _ := false
instance : BEq MemState where beq _ _ := false
instance : Ord MemState where compare _ _ := .eq

/-! ## Layout computation
    Following lean-c-semantics Memory/Layout.lean -/

private def targetPtrSize : Nat := 8

/-- Size of a basic type in bytes -/
private def basicTypeSize : basicType → Nat
  | .Integer ity => match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  | .Floating (.RealFloating .Float0) => 4
  | .Floating (.RealFloating .Double) => 8
  | .Floating (.RealFloating .LongDouble) => 16

private def alignUp (n align : Nat) : Nat :=
  if align == 0 then n else ((n + align - 1) / align) * align

/-- Compute sizeof for a ctype. Returns 0 for types that need tag defs we don't have. -/
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

/-- Compute alignof for a ctype -/
partial def alignofCtype : ctype → Nat
  | Ctype _ ty_ => alignofCtype_ ty_
where alignofCtype_ : ctype_ → Nat
  | .Void0 => 1
  | .Basic bty => basicTypeSize bty  -- alignment = size for basic types on x86_64
  | .Array0 elemCty _ => alignofCtype elemCty
  | .Function _ _ _ | .FunctionNoParams _ => 1
  | .Pointer _ _ => targetPtrSize
  | .Atomic innerCty => alignofCtype innerCty
  | .Struct _ => 1  -- needs tag definitions
  | .Union0 _ => 1  -- needs tag definitions
  | .Byte => 1

/-! ## Byte-level serialization
    Following lean-c-semantics Memory/Concrete.lean -/

/-- Convert integer to little-endian bytes (two's complement).
    Handles negative values correctly. -/
def intToBytes (val : Int) (size : Nat) : List (Option UInt8) :=
  let totalBits := size * 8
  let modulusVal : Int := 1 <<< totalBits
  let unsigned : Int := if val < 0 then modulusVal + val else val
  List.range size |>.map fun i =>
    let shifted := unsigned >>> (i * 8)
    some (shifted.toNat % 256).toUInt8

/-- Convert little-endian bytes to integer.
    Returns none if any byte is uninitialized. -/
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
    let val := go bytes 0 0
    if signed && bytes.length > 0 then
      let bits := bytes.length * 8
      let signBit : Int := 1 <<< (bits - 1)
      if val >= signBit then some (val - (1 <<< bits)) else some val
    else some val

/-- Extract provenance from a list of bytes (first non-none provenance) -/
def bytesProvenance (bytes : List AbsByte) : Provenance :=
  match bytes.find? (fun b => b.prov != .none) with
  | some b => b.prov
  | none => .none

/-- Determine if an integer type is signed -/
private def isSignedIty : integerType → Bool
  | .Signed _ => true
  | .Char0 => true  -- platform-dependent, we follow GCC (signed)
  | .Ptrdiff_t => true
  | .Wint_t => true
  | _ => false

/-- Serialize a MemValue to bytes -/
partial def memValueToBytes (val : MemValue) : List AbsByte :=
  match val with
  | .unspecified ty =>
    let sz := sizeofCtype ty
    List.replicate sz { prov := .none, copyOffset := none, value := none }
  | .integer ity iv =>
    let sz := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let rawBytes := intToBytes iv.val sz
    (rawBytes.zip (List.range rawBytes.length)).map fun (v, i) => { prov := iv.prov, copyOffset := some i, value := v }
  | .floating fty fv =>
    let sz := match fty with
      | .RealFloating .Float0 => 4
      | .RealFloating .Double => 8
      | .RealFloating .LongDouble => 16
    match fv with
    | .finite f =>
      let bits := f.toBits.toNat
      let rawBytes := intToBytes bits sz
      rawBytes.map fun v => { prov := .none, copyOffset := none, value := v }
    | .unspecified =>
      List.replicate sz { prov := .none, copyOffset := none, value := none }
  | .pointer _ pv =>
    let (rawVal, prov) := match pv.base with
      | .null _ => (0, Provenance.none)
      | .function s => (0, pv.prov)  -- TODO: function address
      | .concrete _ addr => (Int.ofNat addr, pv.prov)
    let rawBytes := intToBytes rawVal targetPtrSize
    (rawBytes.zip (List.range rawBytes.length)).map fun (v, i) => { prov := prov, copyOffset := some i, value := v }
  | .array elems => elems.flatMap memValueToBytes
  | .struct_ _ members =>
    -- Simplified: concatenate member bytes without padding
    members.flatMap fun (_, _, mval) => memValueToBytes mval
  | .union_ _ _ mval => memValueToBytes mval
  | .concurRead ity _ =>
    let sz := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    List.replicate sz { prov := .none, copyOffset := none, value := none }

/-- Reconstruct a MemValue from bytes -/
partial def reconstructValue (ty : ctype) (bytes : List AbsByte) : MemValue :=
  match ty with
  | Ctype _ (.Basic (.Integer ity)) =>
    let signed := isSignedIty ity
    match bytesToInt bytes signed with
    | some n => .integer ity { val := n, prov := bytesProvenance bytes }
    | none => .unspecified ty
  | Ctype _ (.Basic (.Floating fty)) =>
    match bytesToInt bytes false with
    | some n =>
      let bits : UInt64 := n.toNat.toUInt64
      .floating fty (.finite (Float.ofBits bits))
    | none => .unspecified ty
  | Ctype _ (.Pointer _ pointeeCty) =>
    match bytesToInt bytes false with
    | some 0 =>
      let nulpv : PointerValue := { prov := .none, base := .null pointeeCty }
      .pointer ty nulpv
    | some addr =>
      let prov := bytesProvenance bytes
      .pointer ty { prov := prov, base := .concrete none addr.toNat }
    | none => .unspecified ty
  | Ctype _ (.Array0 elemCty (some n)) =>
    let nNat := n.toNat
    let elemSize := sizeofCtype elemCty
    if elemSize == 0 then .array []
    else
      let elems := List.range nNat |>.map fun i =>
        let start := i * elemSize
        let elemBytes := bytes.drop start |>.take elemSize
        reconstructValue elemCty elemBytes
      .array elems
  | Ctype _ (.Atomic innerCty) => reconstructValue innerCty bytes
  | Ctype _ .Byte =>
    match bytesToInt (bytes.take 1) false with
    | some n => .integer .Char0 { val := n, prov := bytesProvenance (bytes.take 1) }
    | none => .unspecified ty
  | _ => .unspecified ty

/-! ## Pointer Value Constructors -/

def nullPtrval (ty : ctype) : PointerValue :=
  { prov := .none, base := .null ty }

def funPtrval (s : sym) : PointerValue :=
  { prov := .none, base := .function s }

def concretePtrval (allocId : Int) (addr : Int) : PointerValue :=
  { prov := .some allocId.toNat, base := .concrete none addr.toNat }

def casePtrval {α : Type} (pv : PointerValue)
    (onNull : ctype → α) (onFun : Option sym → α)
    (onConcrete : Option Int → Int → α) : α :=
  match pv.base with
  | .null ty => onNull ty
  | .function s => onFun (some s)
  | .concrete _ addr => onConcrete
      (match pv.prov with | .some id => some (Int.ofNat id) | _ => none)
      (Int.ofNat addr)

def caseFunsymOpt (_ : MemState) (pv : PointerValue) : Option sym :=
  match pv.base with | .function s => some s | _ => none

/-! ## Integer Value Constructors -/

def integerIval (n : Int) : IntegerValue := { val := n, prov := .none }

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

def opIval (op : integer_operator) (v1 v2 : IntegerValue) : IntegerValue :=
  let result := match op with
    | .IntAdd => v1.val + v2.val
    | .IntSub => v1.val - v2.val
    | .IntMul => v1.val * v2.val
    | .IntDiv => if v2.val == 0 then 0 else v1.val / v2.val
    | .IntRem_t => if v2.val == 0 then 0 else v1.val % v2.val
    | .IntRem_f => if v2.val == 0 then 0 else v1.val % v2.val
    | .IntExp => v1.val  -- TODO: exponentiation
  { val := result, prov := v1.prov }

def offsetofIval (_ : List (sym × (t × tag_definition))) (_ : sym) (_ : identifier) : IntegerValue :=
  integerIval 0  -- TODO: requires struct layout from tag definitions

/-! ## Bitwise operations — proper two's complement handling -/

/-- Convert Int to unsigned representation for bitwise ops -/
private def toUnsigned (v : Int) (bits : Nat) : Nat :=
  let modulus : Int := 2 ^ bits
  if v < 0 then (modulus + v).toNat else v.toNat % modulus.toNat

/-- Convert unsigned back to signed if needed -/
private def toSigned (v : Nat) (bits : Nat) (signed : Bool) : Int :=
  if signed then
    let signBit := 2 ^ (bits - 1)
    if v >= signBit then Int.ofNat v - Int.ofNat (2 ^ bits)
    else Int.ofNat v
  else Int.ofNat v

def bitwiseComplementIval (ity : integerType) (v : IntegerValue) : IntegerValue :=
  let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  let bits := size * 8
  let mask := 2 ^ bits - 1
  let unsigned := toUnsigned v.val bits
  let result := unsigned ^^^ mask
  { val := toSigned result bits (isSignedIty ity), prov := v.prov }

def bitwiseAndIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  let bits := size * 8
  let result := toUnsigned v1.val bits &&& toUnsigned v2.val bits
  { val := toSigned result bits (isSignedIty ity), prov := v1.prov }

def bitwiseOrIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  let bits := size * 8
  let result := toUnsigned v1.val bits ||| toUnsigned v2.val bits
  { val := toSigned result bits (isSignedIty ity), prov := v1.prov }

def bitwiseXorIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
  let bits := size * 8
  let result := toUnsigned v1.val bits ^^^ toUnsigned v2.val bits
  { val := toSigned result bits (isSignedIty ity), prov := v1.prov }

def caseIntegerValue {α : Type} (iv : IntegerValue)
    (onSpecified : Int → α) (onUnspecified : Unit → α) : α :=
  onSpecified iv.val

def isSpecifiedIval (_ : IntegerValue) : Bool := true

def eqIval (v1 v2 : IntegerValue) : Option Bool := some (v1.val == v2.val)
def ltIval (v1 v2 : IntegerValue) : Option Bool := some (v1.val < v2.val)
def leIval (v1 v2 : IntegerValue) : Option Bool := some (v1.val ≤ v2.val)

/-! ## Floating Value operations -/

def zeroFval : FloatingValue := .finite 0.0
def oneFval : FloatingValue := .finite 1.0
def strFval (s : String) : FloatingValue := .finite (CerbFloat.of_string s)

def caseFval {α : Type} (fv : FloatingValue) (onUnspec : Unit → α) (onFinite : Float → α) : α :=
  match fv with | .finite f => onFinite f | .unspecified => onUnspec ()

def opFval (op : floating_operator) (v1 v2 : FloatingValue) : FloatingValue :=
  match v1, v2 with
  | .finite f1, .finite f2 => .finite (match op with
      | .FloatAdd => f1 + f2 | .FloatSub => f1 - f2
      | .FloatMul => f1 * f2 | .FloatDiv => f1 / f2)
  | _, _ => .unspecified

def eqFval (v1 v2 : FloatingValue) : Bool :=
  match v1, v2 with | .finite f1, .finite f2 => f1 == f2 | _, _ => false
def ltFval (v1 v2 : FloatingValue) : Bool :=
  match v1, v2 with | .finite f1, .finite f2 => f1 < f2 | _, _ => false
def leFval (v1 v2 : FloatingValue) : Bool :=
  match v1, v2 with | .finite f1, .finite f2 => f1 <= f2 | _, _ => false

def fvfromint (iv : IntegerValue) : FloatingValue := .finite (Float.ofInt iv.val)
def ivfromfloat (_ : integerType) (fv : FloatingValue) : IntegerValue :=
  match fv with | .finite f => integerIval f.toUInt64.toNat | .unspecified => integerIval 0

/-! ## Memory Value Constructors/Destructors -/

def unspecifiedMval (ty : ctype) : MemValue := .unspecified ty
def integerValueMval (ity : integerType) (iv : IntegerValue) : MemValue := .integer ity iv
def floatingValueMval (fty : floatingType) (fv : FloatingValue) : MemValue := .floating fty fv
def pointerMval (ty : ctype) (pv : PointerValue) : MemValue := .pointer ty pv
def arrayMval (elems : List MemValue) : MemValue := .array elems
def structMval (tag : sym) (members : List (identifier × ctype × MemValue)) : MemValue := .struct_ tag members
def unionMval (tag : sym) (member : identifier) (value : MemValue) : MemValue := .union_ tag member value

def caseMemValue {α : Type} (mv : MemValue)
    (onUnspec : ctype → α) (onConcurRead : integerType → sym → α)
    (onInt : integerType → IntegerValue → α) (onFloat : floatingType → FloatingValue → α)
    (onPtr : ctype → PointerValue → α) (onArray : List MemValue → α)
    (onStruct : sym → List (identifier × ctype × MemValue) → α)
    (onUnion : sym → identifier → MemValue → α) : α :=
  match mv with
  | .unspecified ty => onUnspec ty | .concurRead ity s => onConcurRead ity s
  | .integer ity iv => onInt ity iv | .floating fty fv => onFloat fty fv
  | .pointer ty pv => onPtr ty pv | .array elems => onArray elems
  | .struct_ tag members => onStruct tag members
  | .union_ tag member value => onUnion tag member value

/-! ## Pure Pointer Operations -/

def arrayShiftPtrval (pv : PointerValue) (elemTy : ctype) (iv : IntegerValue) : PointerValue :=
  match pv.base with
  | .null _ => pv
  | .function _ => pv
  | .concrete um addr =>
    let elemSize := sizeofCtype elemTy
    let offset := iv.val * (Int.ofNat elemSize)
    let newAddr := (Int.ofNat addr) + offset
    { prov := pv.prov, base := .concrete um newAddr.toNat }

def memberShiftPtrval (pv : PointerValue) (_ : sym) (_ : identifier) : PointerValue :=
  pv  -- TODO: compute member offset from tag definitions

def bytefromint (iv : IntegerValue) : IntegerValue := { val := iv.val % 256, prov := iv.prov }
def intfrombyte (iv : IntegerValue) : IntegerValue := iv

def overlapping (f1 f2 : Footprint) : Bool :=
  f1.base < f2.base + f2.size && f2.base < f1.base + f1.size

def initialMemState : MemState := default

def stringFromCtype (_ : ctype) : String := "<ctype>"
def stringFromMemValue (_ : MemValue) : String := "<mem_value>"
def stringFromPointerValue (_ : PointerValue) : String := "<pointer_value>"
def stringFromIntegerValue (_ : IntegerValue) : String := "<integer_value>"

def deriveCap (_ : Bool) (_ : derivecap_op) (v1 v2 : IntegerValue) : IntegerValue := v1
def capAssignValue (_ : t) (_ v : IntegerValue) : IntegerValue := v
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

private def writeBytesTo (st : MemState) (addr : Nat) (bytes : List AbsByte) : MemState :=
  let newEntries := bytes.mapIdx fun i b => (addr + i, b)
  let filtered := st.bytemap.filter fun (a, _) => !newEntries.any (fun (a', _) => a == a')
  { st with bytemap := newEntries ++ filtered }

private def readBytesFrom (st : MemState) (addr : Nat) (size : Nat) : List AbsByte :=
  List.range size |>.map fun i =>
    match st.bytemap.find? (fun (a, _) => a == addr + i) with
    | some (_, b) => b
    | none => { prov := .none, copyOffset := none, value := none }

private def getAllocation (st : MemState) (pv : PointerValue) : Option (Nat × Allocation) :=
  match pv.prov with
  | .some allocId =>
    if st.deadAllocations.contains allocId then none
    else match st.allocations.find? (fun (id, _) => id == allocId) with
      | some (id, alloc) => some (id, alloc)
      | none => none
  | _ => none

private def isInBounds (alloc : Allocation) (addr size : Nat) : Bool :=
  addr >= alloc.base && addr + size <= alloc.base + alloc.size

/-! ### Allocation -/

def allocateObject (_ : Nat) (_ : prefix0) (alignIv : IntegerValue)
    (ty : ctype) (_ : Option Int) (initOpt : Option MemValue) : memM PointerValue :=
  ND fun st =>
    let align := alignIv.val.toNat.max 1
    let size := (sizeofCtype ty).max 1
    let addrAfterSize := st.lastAddress - size
    let alignedAddr := alignDown addrAfterSize align
    if alignedAddr == 0 then (NDkilled (Other (MerrOther "out of memory")), st)
    else
      let allocId := st.nextAllocId
      let alloc : Allocation := { base := alignedAddr, size := size, ty := some ty, name := "" }
      let st' := { st with
        nextAllocId := allocId + 1, lastAddress := alignedAddr
        allocations := (allocId, alloc) :: st.allocations }
      let st' := match initOpt with
        | some val => writeBytesTo st' alignedAddr (memValueToBytes val)
        | none => writeBytesTo st' alignedAddr
            (List.replicate size { prov := .none, copyOffset := none, value := none })
      (NDactive { prov := .some allocId, base := .concrete none alignedAddr }, st')

def allocateRegion (_ : Nat) (_ : prefix0) (alignIv sizeIv : IntegerValue) : memM PointerValue :=
  ND fun st =>
    let align := alignIv.val.toNat.max 1
    let size := sizeIv.val.toNat
    let addrAfterSize := st.lastAddress - size
    let alignedAddr := alignDown addrAfterSize align
    if alignedAddr == 0 then (NDkilled (Other (MerrOther "out of memory")), st)
    else
      let allocId := st.nextAllocId
      let alloc : Allocation := { base := alignedAddr, size := size, name := "" }
      let st' := { st with
        nextAllocId := allocId + 1, lastAddress := alignedAddr
        allocations := (allocId, alloc) :: st.allocations
        dynamicAddrs := alignedAddr :: st.dynamicAddrs }
      let st' := writeBytesTo st' alignedAddr
          (List.replicate size { prov := .none, copyOffset := none, value := none })
      (NDactive { prov := .some allocId, base := .concrete none alignedAddr }, st')

/-! ### Kill -/

def killM (_ : t) (isDynamic : Bool) (pv : PointerValue) : memM Unit :=
  ND fun st =>
    match pv.base with
    | .null _ =>
      if isDynamic then (NDactive (), st)
      else (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
    | .function _ => (NDkilled (Other (MerrUndefinedFree Free_non_matching)), st)
    | .concrete _ addr =>
      match pv.prov with
      | .some allocId =>
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

/-! ### Load / Store -/

def loadM (_ : t) (ty : ctype) (pv : PointerValue) : memM (Footprint × MemValue) :=
  ND fun st =>
    match pv.base with
    | .null _ => (NDkilled (Other (MerrAccess LoadAccess NullPtr)), st)
    | .function _ => (NDkilled (Other (MerrAccess LoadAccess FunctionPtr)), st)
    | .concrete _ addr =>
      match getAllocation st pv with
      | none => (NDkilled (Other (MerrAccess LoadAccess NoProvPtr)), st)
      | some (_, alloc) =>
        let size := sizeofCtype ty
        if !isInBounds alloc addr size then
          (NDkilled (Other (MerrAccess LoadAccess OutOfBoundPtr)), st)
        else
          let bytes := readBytesFrom st addr size
          let fp : Footprint := { isWrite := false, base := addr, size := size }
          let mv := reconstructValue ty bytes
          -- Check for uninitialized bool (trap representation)
          let isBool := match ty with | Ctype _ (.Basic (.Integer .Bool0)) => true | _ => false
          let isTrap := isBool && match mv with
            | .integer _ iv => iv.val != 0 && iv.val != 1
            | .unspecified _ => true
            | _ => false
          if isTrap then
            (NDkilled (Other (MerrTrapRepresentation LoadAccess)), st)
          else
            (NDactive (fp, mv), st)

def storeM (_ : t) (ty : ctype) (isLocking : Bool) (pv : PointerValue) (mv : MemValue) : memM Footprint :=
  ND fun st =>
    match pv.base with
    | .null _ => (NDkilled (Other (MerrAccess StoreAccess NullPtr)), st)
    | .function _ => (NDkilled (Other (MerrAccess StoreAccess FunctionPtr)), st)
    | .concrete unionMem addr =>
      match getAllocation st pv with
      | none => (NDkilled (Other (MerrAccess StoreAccess NoProvPtr)), st)
      | some (allocId, alloc) =>
        match alloc.isReadonly with
        | .readonly kind => (NDkilled (Other (MerrWriteOnReadOnly kind)), st)
        | .writable =>
          let size := sizeofCtype ty
          if !isInBounds alloc addr size then
            (NDkilled (Other (MerrAccess StoreAccess OutOfBoundPtr)), st)
          else
            let bytes := memValueToBytes mv
            let st' := writeBytesTo st addr bytes
            -- Track union member access
            let st' := match unionMem with
              | some membr => { st' with lastUsedUnionMembers :=
                  (addr, membr) :: st'.lastUsedUnionMembers.filter (fun (a, _) => a != addr) }
              | none => st'
            -- Handle locking (readonly after first store)
            let st' := if isLocking then
              let roKind := match alloc.name with
                | "PrefStringLiteral" => readonly_kind.ReadonlyStringLiteral
                | "PrefTemporaryLifetime" => readonly_kind.ReadonlyTemporaryLifetime
                | _ => readonly_kind.ReadonlyConstQualified
              { st' with allocations := st'.allocations.map fun (id, a) =>
                  if id == allocId then (id, { a with isReadonly := .readonly roKind }) else (id, a) }
              else st'
            let fp : Footprint := { isWrite := true, base := addr, size := size }
            (NDactive fp, st')

/-! ### Pointer comparisons -/

private def ptrAddr (pv : PointerValue) : Option Nat :=
  match pv.base with | .concrete _ addr => some addr | _ => none

def eqPtrval (_ : t) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match pv1.base, pv2.base with
    | .null _, .null _ => true
    | .function s1, .function s2 => s1 == s2
    | .concrete _ a1, .concrete _ a2 => pv1.prov == pv2.prov && a1 == a2
    | _, _ => false)

def nePtrval (loc : t) (pv1 pv2 : PointerValue) : memM Bool :=
  nd_bind (eqPtrval loc pv1 pv2) (fun b => memReturn (!b))

def ltPtrval (_ : t) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 < a2 | _, _ => false)
def gtPtrval (_ : t) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 > a2 | _, _ => false)
def lePtrval (_ : t) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 <= a2 | _, _ => false)
def gePtrval (_ : t) (pv1 pv2 : PointerValue) : memM Bool :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 => a1 >= a2 | _, _ => false)

def diffPtrval (_ : t) (elemTy : ctype) (pv1 pv2 : PointerValue) : memM IntegerValue :=
  memReturn (match ptrAddr pv1, ptrAddr pv2 with
    | some a1, some a2 =>
      let elemSize := (sizeofCtype elemTy).max 1
      integerIval (((Int.ofNat a1) - (Int.ofNat a2)) / elemSize)
    | _, _ => integerIval 0)

/-! ### Pointer validity -/

def validForDerefPtrval (_ : ctype) (pv : PointerValue) : memM Bool :=
  ND fun st =>
    let result := match pv.base with
      | .null _ | .function _ => false
      | .concrete _ _ => (getAllocation st pv).isSome
    (NDactive result, st)

def isWellAlignedPtrval (ty : ctype) (pv : PointerValue) : memM Bool :=
  memReturn (match pv.base with
    | .null _ | .function _ => true
    | .concrete _ addr => addr % (alignofCtype ty).max 1 == 0)

/-! ### Pointer casts -/

def ptrfromint (_ : t) (_ : integerType) (_ : ctype) (iv : IntegerValue) : memM PointerValue :=
  if iv.val == 0 then memReturn (nullPtrval (mkCtype Void0))
  else memReturn { prov := iv.prov, base := .concrete none iv.val.toNat }

def intfromptr (_ : t) (_ : ctype) (_ : integerType) (pv : PointerValue) : memM IntegerValue :=
  memReturn (match pv.base with
    | .null _ => { val := 0, prov := pv.prov }
    | .function _ => { val := 0, prov := pv.prov }
    | .concrete _ addr => { val := Int.ofNat addr, prov := pv.prov })

/-! ### Effectful pointer shifts -/

def effArrayShiftPtrval (_ : t) (pv : PointerValue) (elemTy : ctype) (iv : IntegerValue) : memM PointerValue :=
  memReturn (arrayShiftPtrval pv elemTy iv)

def effMemberShiftPtrval (_ : t) (pv : PointerValue) (tag : sym) (member : identifier) : memM PointerValue :=
  memReturn (memberShiftPtrval pv tag member)

/-! ### Memory operations -/

def memcpyM (_ : t) (dst src : PointerValue) (sizeIv : IntegerValue) : memM PointerValue :=
  ND fun st =>
    match dst.base, src.base with
    | .concrete _ dstAddr, .concrete _ srcAddr =>
      let size := sizeIv.val.toNat
      let bytes := readBytesFrom st srcAddr size
      let st' := writeBytesTo st dstAddr bytes
      (NDactive dst, st')
    | _, _ => (NDkilled (Other (MerrOther "memcpy: non-concrete pointers")), st)

def memcmpM (pv1 pv2 : PointerValue) (sizeIv : IntegerValue) : memM IntegerValue :=
  ND fun st =>
    match pv1.base, pv2.base with
    | .concrete _ a1, .concrete _ a2 =>
      let size := sizeIv.val.toNat
      let b1 := readBytesFrom st a1 size
      let b2 := readBytesFrom st a2 size
      let cmp := (b1.zip b2).foldl (init := (0 : Int)) fun acc (x, y) =>
        if acc != 0 then acc
        else match x.value, y.value with
          | some v1, some v2 =>
            if v1.toNat < v2.toNat then -1 else if v1.toNat > v2.toNat then 1 else 0
          | _, _ => 0
      (NDactive (integerIval cmp), st)
    | _, _ => (NDactive (integerIval 0), st)

def reallocM (_ : t) (tid : Nat) (alignIv : IntegerValue) (pv : PointerValue) (sizeIv : IntegerValue) : memM PointerValue :=
  memReturn pv  -- TODO: allocate new, copy, free old

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
def callIntrinsic (_ : t) (_ : String) (_ : List MemValue) : memM (Option MemValue) := memReturn none

end CerbMem
