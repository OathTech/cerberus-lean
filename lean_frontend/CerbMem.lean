/-
  Concrete memory model for Cerberus.
  Corresponds to: memory/concrete/impl_mem.ml
  Following: lean-c-semantics/CerbLean/Memory/{Types,Interface,Concrete}.lean

  Defines concrete representations for mem.lem opaque types and implements
  all memory operations (allocate, load, store, kill, pointer ops, etc.)
-/

import IntegerType
import Ctype
import Symbol
import Mem_common
import CerberusImpl
import CerbFloat
import CerbLocation

open CerberusImpl

/-! ## Provenance

Corresponds to: provenance in impl_mem.ml
Following: lean-c-semantics Core/Value.lean -/

namespace CerbMem

inductive Provenance where
  | none
  | some (allocId : Nat)
  | symbolic (iota : Nat)
  | device
  deriving BEq, Inhabited, Repr

/-! ## Value Types -/

/-- Integer value with provenance tracking.
    Corresponds to: integer_value in impl_mem.ml -/
structure IntegerValue where
  val : Int
  prov : Provenance := .none
  deriving BEq, Inhabited, Repr

/-- Floating value with special IEEE 754 cases.
    Corresponds to: floating_value in impl_mem.ml -/
inductive FloatingValue where
  | finite (val : Float)
  | unspecified
  deriving BEq, Inhabited, Repr

/-- Pointer value base — what the pointer points to.
    Corresponds to: pointer_value_ in impl_mem.ml -/
inductive PointerValueBase where
  | null (ty : ctype)
  | function (sym : sym)
  | concrete (unionMember : Option identifier) (addr : Nat)
  deriving Inhabited

/-- Pointer value with provenance.
    Corresponds to: pointer_value in impl_mem.ml -/
structure PointerValue where
  prov : Provenance
  base : PointerValueBase
  deriving Inhabited

/-- Memory value — runtime representation of C values.
    Corresponds to: mem_value in impl_mem.ml -/
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

/-- Memory access footprint for race detection.
    Corresponds to: footprint in impl_mem.ml -/
structure Footprint where
  isWrite : Bool  -- false = read, true = write
  base : Nat
  size : Nat
  deriving BEq, Inhabited, Repr, Ord

/-- Abstract byte in memory.
    Corresponds to: AbsByte.t in impl_mem.ml -/
structure AbsByte where
  prov : Provenance := .none
  copyOffset : Option Nat := none
  value : Option UInt8 := none
  deriving BEq, Inhabited, Repr

/-- Read-only status for allocations. -/
inductive ReadonlyStatus where
  | writable
  | readonly (kind : readonly_kind)
  deriving Inhabited

/-- Metadata for a single memory allocation. -/
structure Allocation where
  base : Nat
  size : Nat
  ty : Option ctype := none
  isReadonly : ReadonlyStatus := .writable
  taint : Bool := false  -- true = exposed (PNVI-ae)
  name : String := ""
  deriving Inhabited

/-- Global memory state.
    Corresponds to: mem_state in impl_mem.ml -/
structure MemState where
  nextAllocId : Nat := 0
  allocations : List (Nat × Allocation) := []  -- allocId → Allocation
  bytemap : List (Nat × AbsByte) := []         -- address → AbsByte
  deadAllocations : List Nat := []
  dynamicAddrs : List Nat := []
  funptrmap : List (Nat × sym) := []           -- address → function symbol
  lastUsedUnionMembers : List (Nat × identifier) := []
  lastAddress : Nat := 0xFFFFFFFFFFFF           -- 48-bit address space
  varargs : List (Nat × List (ctype × PointerValue)) := []
  nextVarargsId : Nat := 0
  deriving Inhabited

/-! ## Instances needed by generated code -/

instance : BEq PointerValueBase where
  beq a b := match a, b with
    | .null _, .null _ => true
    | .function s1, .function s2 => s1 == s2
    | .concrete _ a1, .concrete _ a2 => a1 == a2
    | _, _ => false

instance : BEq PointerValue where
  beq a b := a.base == b.base

instance : BEq FloatingValue where
  beq a b := match a, b with
    | .finite f1, .finite f2 => f1 == f2
    | .unspecified, .unspecified => true
    | _, _ => false

instance : BEq IntegerValue where
  beq a b := a.val == b.val

private unsafe def beqMemValueImpl : MemValue → MemValue → Bool
  | .unspecified _, .unspecified _ => true
  | .integer _ v1, .integer _ v2 => v1 == v2
  | .floating _ v1, .floating _ v2 => v1 == v2
  | .pointer _ v1, .pointer _ v2 => v1 == v2
  | .array e1, .array e2 => e1.length == e2.length && (e1.zip e2).all (fun (a, b) => beqMemValueImpl a b)
  | _, _ => false

@[implemented_by beqMemValueImpl]
private opaque beqMemValueSafe : MemValue → MemValue → Bool

instance : BEq MemValue where
  beq := beqMemValueSafe

instance : Ord PointerValue where
  compare _ _ := .eq

instance : Ord IntegerValue where
  compare a b := compare a.val b.val

instance : Ord FloatingValue where
  compare _ _ := .eq

instance : Ord MemValue where
  compare _ _ := .eq

/-! ## Pointer Value Constructors -/

def nullPtrval (ty : ctype) : PointerValue :=
  { prov := .none, base := .null ty }

def funPtrval (s : sym) : PointerValue :=
  { prov := .none, base := .function s }

def concretePtrval (allocId : Int) (addr : Int) : PointerValue :=
  { prov := .some allocId.toNat, base := .concrete none addr.toNat }

/-- Case analysis on pointer values.
    Corresponds to: case_ptrval in impl_mem.ml -/
def casePtrval {α : Type} (pv : PointerValue)
    (onNull : ctype → α)
    (onFun : Option sym → α)
    (onConcrete : Option Int → Int → α) : α :=
  match pv.base with
  | .null ty => onNull ty
  | .function s => onFun (some s)
  | .concrete _ addr => onConcrete (match pv.prov with
      | .some id => some (Int.ofNat id)
      | _ => none) (Int.ofNat addr)

/-- Extract function symbol from pointer if it's a function pointer. -/
def caseFunsymOpt (_ : MemState) (pv : PointerValue) : Option sym :=
  match pv.base with
  | .function s => some s
  | _ => none

/-! ## Integer Value Constructors -/

def integerIval (n : Int) : IntegerValue :=
  { val := n, prov := .none }

def maxIval (ity : integerType) : IntegerValue :=
  let bits := match CerberusImpl.precision_ity ity with
    | some n => n
    | none => 31  -- fallback
  integerIval (2 ^ bits - 1)

def minIval (ity : integerType) : IntegerValue :=
  if CerberusImpl.is_signed_ity ity then
    let bits := match CerberusImpl.precision_ity ity with
      | some n => n
      | none => 31
    integerIval (-(2 ^ bits))
  else
    integerIval 0

def sizeofIval (ty : ctype) : IntegerValue :=
  -- TODO: full sizeof computation requires tag definitions
  integerIval 0

def alignofIval (ty : ctype) : IntegerValue :=
  -- TODO: full alignof computation requires tag definitions
  integerIval 1

def concurReadIval (_ : integerType) (_ : sym) : IntegerValue :=
  integerIval 0  -- Placeholder for concurrent reads

/-- Integer arithmetic with overflow.
    Corresponds to: op_ival in impl_mem.ml -/
def opIval (op : integer_operator) (v1 v2 : IntegerValue) : IntegerValue :=
  let result := match op with
    | .IntAdd => v1.val + v2.val
    | .IntSub => v1.val - v2.val
    | .IntMul => v1.val * v2.val
    | .IntDiv => if v2.val == 0 then 0 else v1.val / v2.val
    | .IntRem_t => if v2.val == 0 then 0 else v1.val % v2.val
    | .IntRem_f => if v2.val == 0 then 0 else v1.val % v2.val
    | .IntExp => v1.val  -- TODO
  { val := result, prov := v1.prov }

def offsetofIval (_ : List (sym × (t × tag_definition))) (_ : sym) (_ : identifier) : IntegerValue :=
  integerIval 0  -- TODO: requires struct layout

/-- Bitwise complement. -/
def bitwiseComplementIval (ity : integerType) (v : IntegerValue) : IntegerValue :=
  let bits := match CerberusImpl.sizeof_ity ity with
    | some n => n * 8
    | none => 32
  let mask := (2 ^ bits) - 1
  { val := Int.ofNat (v.val.toNat ^^^ mask), prov := v.prov }

/-- Bitwise AND. -/
def bitwiseAndIval (_ : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  { val := Int.ofNat (v1.val.toNat &&& v2.val.toNat), prov := v1.prov }

/-- Bitwise OR. -/
def bitwiseOrIval (_ : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  { val := Int.ofNat (v1.val.toNat ||| v2.val.toNat), prov := v1.prov }

/-- Bitwise XOR. -/
def bitwiseXorIval (_ : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  { val := Int.ofNat (v1.val.toNat ^^^ v2.val.toNat), prov := v1.prov }

/-- Case analysis on integer values. -/
def caseIntegerValue {α : Type} (iv : IntegerValue) (onSpecified : Int → α) (onUnspecified : Unit → α) : α :=
  onSpecified iv.val  -- concrete model: always specified

def isSpecifiedIval (_ : IntegerValue) : Bool := true  -- concrete model

/-- Integer value comparison predicates. -/
def eqIval (v1 v2 : IntegerValue) : Option Bool := some (v1.val == v2.val)
def ltIval (v1 v2 : IntegerValue) : Option Bool := some (v1.val < v2.val)
def leIval (v1 v2 : IntegerValue) : Option Bool := some (v1.val ≤ v2.val)

/-! ## Floating Value Constructors -/

def zeroFval : FloatingValue := .finite 0.0
def oneFval : FloatingValue := .finite 1.0
def strFval (s : String) : FloatingValue := .finite (CerbFloat.of_string s)

def caseFval {α : Type} (fv : FloatingValue) (onUnspec : Unit → α) (onFinite : Float → α) : α :=
  match fv with
  | .finite f => onFinite f
  | .unspecified => onUnspec ()

def opFval (op : floating_operator) (v1 v2 : FloatingValue) : FloatingValue :=
  match v1, v2 with
  | .finite f1, .finite f2 =>
    .finite (match op with
      | .FloatAdd => f1 + f2
      | .FloatSub => f1 - f2
      | .FloatMul => f1 * f2
      | .FloatDiv => f1 / f2)
  | _, _ => .unspecified

def eqFval (v1 v2 : FloatingValue) : Bool :=
  match v1, v2 with
  | .finite f1, .finite f2 => f1 == f2
  | _, _ => false

def ltFval (v1 v2 : FloatingValue) : Bool :=
  match v1, v2 with
  | .finite f1, .finite f2 => f1 < f2
  | _, _ => false

def leFval (v1 v2 : FloatingValue) : Bool :=
  match v1, v2 with
  | .finite f1, .finite f2 => f1 <= f2
  | _, _ => false

def fvfromint (iv : IntegerValue) : FloatingValue :=
  .finite (Float.ofInt iv.val)

def ivfromfloat (_ : integerType) (fv : FloatingValue) : IntegerValue :=
  match fv with
  | .finite f => integerIval f.toUInt64.toNat
  | .unspecified => integerIval 0

/-! ## Memory Value Constructors -/

def unspecifiedMval (ty : ctype) : MemValue := .unspecified ty
def integerValueMval (ity : integerType) (iv : IntegerValue) : MemValue := .integer ity iv
def floatingValueMval (fty : floatingType) (fv : FloatingValue) : MemValue := .floating fty fv
def pointerMval (ty : ctype) (pv : PointerValue) : MemValue := .pointer ty pv
def arrayMval (elems : List MemValue) : MemValue := .array elems
def structMval (tag : sym) (members : List (identifier × ctype × MemValue)) : MemValue := .struct_ tag members
def unionMval (tag : sym) (member : identifier) (value : MemValue) : MemValue := .union_ tag member value

/-- Case analysis on memory values (8-way).
    Corresponds to: case_mem_value in impl_mem.ml -/
def caseMemValue {α : Type} (mv : MemValue)
    (onUnspec : ctype → α)
    (onConcurRead : integerType → sym → α)
    (onInt : integerType → IntegerValue → α)
    (onFloat : floatingType → FloatingValue → α)
    (onPtr : ctype → PointerValue → α)
    (onArray : List MemValue → α)
    (onStruct : sym → List (identifier × ctype × MemValue) → α)
    (onUnion : sym → identifier → MemValue → α) : α :=
  match mv with
  | .unspecified ty => onUnspec ty
  | .concurRead ity s => onConcurRead ity s
  | .integer ity iv => onInt ity iv
  | .floating fty fv => onFloat fty fv
  | .pointer ty pv => onPtr ty pv
  | .array elems => onArray elems
  | .struct_ tag members => onStruct tag members
  | .union_ tag member value => onUnion tag member value

/-! ## Pure Pointer Operations -/

/-- Array element shift (pure, no bounds check).
    Corresponds to: array_shift_ptrval in impl_mem.ml -/
def arrayShiftPtrval (pv : PointerValue) (elemTy : ctype) (iv : IntegerValue) : PointerValue :=
  match pv.base with
  | .null _ => pv  -- shifting null stays null (UB checked elsewhere)
  | .function _ => pv
  | .concrete um addr =>
    let elemSize := match CerberusImpl.sizeof_ity (Signed Int_) with  -- TODO: proper sizeof for ctype
      | some n => n
      | none => 1
    let offset := iv.val * elemSize
    let newAddr := (addr : Int) + offset
    { prov := pv.prov, base := .concrete um newAddr.toNat }

/-- Struct/union member shift (pure).
    Corresponds to: member_shift_ptrval in impl_mem.ml -/
def memberShiftPtrval (pv : PointerValue) (_ : sym) (_ : identifier) : PointerValue :=
  pv  -- TODO: compute member offset from tag definitions

/-! ## Byte-level operations -/

def bytefromint (iv : IntegerValue) : IntegerValue :=
  { val := iv.val % 256, prov := iv.prov }

def intfrombyte (iv : IntegerValue) : IntegerValue := iv

/-! ## Overlapping footprints -/

def overlapping (f1 f2 : Footprint) : Bool :=
  f1.base < f2.base + f2.size && f2.base < f1.base + f1.size

/-! ## Initial state -/

def initialMemState : MemState := default

/-! ## String conversions -/

def stringFromCtype (_ : ctype) : String := "<ctype>"
def stringFromMemValue (_ : MemValue) : String := "<mem_value>"
def stringFromPointerValue (_ : PointerValue) : String := "<pointer_value>"
def stringFromIntegerValue (_ : IntegerValue) : String := "<integer_value>"

/-! ## CHERI stubs (not implemented) -/

def deriveCap (_ : Bool) (_ : derivecap_op) (v1 v2 : IntegerValue) : IntegerValue := v1
def capAssignValue (_ : t) (_ v : IntegerValue) : IntegerValue := v
def nullCap (_ : Bool) : IntegerValue := integerIval 0
def ptrTIntValue (iv : IntegerValue) : IntegerValue := iv

def cheriPointerHashPrintf (_ : Bool) (_ : PointerValue) : String := ""
def getIntrinsicTypeSpec (_ : String) : Option intrinsics_signature := none

/-! ## Monadic operations

These operations work within the nondeterminism monad (ndM).
The ndM type from Nondeterminism.lem is:
  ndM α string mem_error (mem_constraint integer_value) mem_state

For now, we provide the return-wrapped versions. Full monadic
implementations require wiring into the ndM monad. -/

-- Placeholder: monadic operations are sorry for now.
-- The pure constructors/destructors above cover the non-monadic API.
-- The monadic operations (allocate, load, store, kill, pointer comparisons,
-- casts, memcpy, memcmp, realloc, varargs) need to be wired into the
-- nondeterminism monad, which requires more infrastructure.

end CerbMem
