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
  -- arc-6 S3: Std.TreeMap Int (OCaml: IntMap = Map.Make(Z), impl_mem.ml:93);
  -- never enumerated (order-unobserved), keys unique -> results identical to
  -- the previous assoc list at O(log n)
  allocations : Std.TreeMap Int Allocation := Std.TreeMap.empty
  iotaMap : List (Int × Int) := [] -- simplified from OCaml's polymorphic variant
  funptrmap : List (Int × (String × String)) := []
  varargs : List (Int × (Int × List (ctype × PointerValue))) := []
  nextVarargsId : Int := 0
  -- arc-6 S3: same treatment (the S0-profiled secondary hot seam)
  bytemap : Std.TreeMap Int AbsByte := Std.TreeMap.empty
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

/-! ## Layout computation — impl_mem.ml:98-273 (offsetsof / sizeof / alignof)

    OCaml's offsetsof/sizeof/alignof take `?(tagDefs= Tags.tagDefs ())` and
    every call site in impl_mem.ml uses the default, so the Lean versions
    read `CerbTags.tagDefs ()` at their struct/union arms (the same ambient
    tag-state pattern already used by memberShiftPtrval below).

    Integer/float leaf sizes come from CerberusImpl (the DefaultImpl port),
    exactly like OCaml routes them through `(Ocaml_implementation.get ())`
    — no local size constants are kept here. -/

private def targetPtrSize : Nat := 8  -- DefaultImpl.sizeof_pointer/alignof_pointer = Some 8

private abbrev TagDefs := List (sym × (CerbLocation.Loc × tag_definition))

/-! ARC-7 S4 TOTALIZATION (fuel; arc-3 pattern): the layout oracles and
    the (de)serializers below were `partial def`s — kernel-opaque, no
    equations, so NO slate app-equation could compute through a memory
    operation (S4 record, escalation event 1). Each is now a fuel'd
    worker `*_lemFuel` (fuel decremented once per recursion layer;
    exhaustion = the OPAQUE `fuelExhaustedWith` sentinel, LemLib —
    a fake value provable equal to something would be a lie, D4
    transparency doctrine) + the original name as the default-budget
    wrapper (`lemDefaultFuel`, rfl-defeq), so every call site and every
    runtime behavior is unchanged. `stringFromMemValue` (pp-only, never
    on a computed path) stays partial. -/

mutual

/-- Member alignment with the `align_opt` (_Alignas) override —
    impl_mem.ml:115-122 (the align_opt match inside offsetsof; the same
    three-way match is repeated verbatim at impl_mem.ml:179-186 for union
    sizeof and inside the struct/union alignof folds). -/
def memberAlign_lemFuel (lemFuel : Nat) (alignOpt : Option alignment)
    (ty : ctype) : Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.memberAlign: fuel exhausted" 1
  | lemFuel + 1 =>
    match alignOpt with
    | none => alignofCtype_lemFuel lemFuel ty
    | some (AlignInteger al_n) => al_n.toNat
    | some (AlignType al_ty) => alignofCtype_lemFuel lemFuel al_ty

/-- THE struct-layout oracle: fold over the raw member quadruples,
    padding each member up to its (possibly _Alignas-overridden)
    alignment. Mirrors the fold at impl_mem.ml:112-127. Returns
    ([(ident, ty, offset)], last_offset) where last_offset is the end of
    the last member BEFORE trailing padding — exactly OCaml's `maxoffset`.
    (Alignment 0 is impossible for valid C members; Lean's `% 0 = id` +
    truncated subtraction make it degrade to pad = 0 instead of OCaml's
    Division_by_zero.) -/
def offsetsofMembers_lemFuel (lemFuel : Nat)
    (members : List (identifier × (attributes × Option alignment × qualifiers × ctype)))
    : List (identifier × ctype × Nat) × Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.offsetsofMembers: fuel exhausted" ([], 0)
  | lemFuel + 1 =>
    let (xs, maxoffset) := members.foldl (init := (([] : List (identifier × ctype × Nat)), 0))
      fun (acc : List (identifier × ctype × Nat) × Nat) memb =>
        let (xs, lastOffset) := acc
        let (ident, (_, alignOpt, _, ty)) := memb
        let size := sizeofCtype_lemFuel lemFuel ty          -- impl_mem.ml:114
        let align := memberAlign_lemFuel lemFuel alignOpt ty -- impl_mem.ml:115-122
        let x := lastOffset % align                   -- impl_mem.ml:123
        let pad := if x == 0 then 0 else align - x    -- impl_mem.ml:124
        ((ident, ty, lastOffset + pad) :: xs, lastOffset + pad + size)  -- impl_mem.ml:125
    (xs.reverse, maxoffset)

/-- offsetsof — impl_mem.ml:98-129. Struct: offsetsofMembers over the
    member list, with the flexible array member appended as an ordinary
    member (its stored element ctype, verbatim per impl_mem.ml:104-108)
    unless `ignoreFlexible`. Union: every member at offset 0, last_offset
    0 (impl_mem.ml:128-129). Missing tag: OCaml's Pmap.find raises
    Not_found — panic here.
    Tag lookup uses symbolEquality (digest+nat, description-INSENSITIVE
    — OCaml's symbol_compare/Pmap key order, symbol.lem), NOT the derived
    BEq which also compares the description. Same for every tag lookup in
    this file. -/
def offsetsof_lemFuel (lemFuel : Nat) (tagDefs : TagDefs) (tagSym : sym)
    (ignoreFlexible : Bool := false) : List (identifier × ctype × Nat) × Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.offsetsof: fuel exhausted" ([], 0)
  | lemFuel + 1 =>
    match tagDefs.find? (fun (s, _) => symbolEquality s tagSym) with
    | none => panic! "CerbMem.offsetsof: unknown tag (OCaml: Pmap.find Not_found)"
    | some (_, (_, StructDef membrs_ flexibleOpt)) =>
      let membrs := match flexibleOpt with
        | none => membrs_
        | some (FlexibleArrayMember attrs ident qs ty) =>
          if ignoreFlexible then membrs_
          else membrs_ ++ [(ident, (attrs, none, qs, ty))]  -- impl_mem.ml:107-108 (raw stored ctype)
      offsetsofMembers_lemFuel lemFuel membrs
    | some (_, (_, UnionDef membrs)) =>
      (membrs.map (fun (ident, (_, _, _, ty)) => (ident, ty, 0)), 0)

/-- sizeof — impl_mem.ml:131-194.
    Struct (impl_mem.ml:162-171): offsetsof last_offset (ignore_flexible —
    the flexible member is uncounted except through alignof's trailing
    padding), padded up to alignof(struct).
    Union (impl_mem.ml:172-192): max member size padded up to max member
    alignment (align_opt honored).
    Divergence kept from the pre-existing code: Void/incomplete-Array/
    Function return 0 where OCaml `assert false` (impl_mem.ml:133-135). -/
def sizeofCtype_lemFuel (lemFuel : Nat) (cty : ctype) : Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.sizeofCtype: fuel exhausted" 0
  | lemFuel + 1 =>
    match cty with
    | Ctype _ ty_ =>
      match ty_ with
      | .Void0 => 0                                 -- OCaml: assert false
      | .Array0 _ none => 0                         -- OCaml: assert false
      | .Function _ _ _ | .FunctionNoParams _ => 0  -- OCaml: assert false
      | .Basic (.Integer ity) =>
        match CerberusImpl.sizeof_ity ity with      -- impl_mem.ml:136-141
        | some n => n
        | none => panic! "the concrete memory model requires a complete implementation sizeof INTEGER"
      | .Basic (.Floating fty) =>
        match CerberusImpl.sizeof_fty fty with      -- impl_mem.ml:143-148
        | some n => n
        | none => panic! "the concrete memory model requires a complete implementation sizeof FLOAT"
      | .Array0 elemCty (some n) => n.toNat * sizeofCtype_lemFuel lemFuel elemCty  -- impl_mem.ml:150-151
      | .Pointer _ _ => targetPtrSize               -- impl_mem.ml:153-158
      | .Atomic innerCty => sizeofCtype_lemFuel lemFuel innerCty    -- impl_mem.ml:160-161
      | .Struct tagSym =>                           -- impl_mem.ml:162-171
        let (_, maxOffset) := offsetsof_lemFuel lemFuel (fmapElements (CerbTags.tagDefs ())) tagSym (ignoreFlexible := true)
        let align := alignofCtype_lemFuel lemFuel cty
        let x := maxOffset % align
        if x == 0 then maxOffset else maxOffset + (align - x)
      | .Union0 tagSym =>                           -- impl_mem.ml:172-192
        match (fmapElements (CerbTags.tagDefs ())).find? (fun (s, _) => symbolEquality s tagSym) with
        | some (_, (_, UnionDef membrs)) =>
          let (maxSize, maxAlign) := membrs.foldl (init := ((0 : Nat), (0 : Nat)))
            fun (acc : Nat × Nat) memb =>
              let (accSize, accAlign) := acc
              let (_, (_, alignOpt, _, ty)) := memb
              (max accSize (sizeofCtype_lemFuel lemFuel ty),
               max accAlign (memberAlign_lemFuel lemFuel alignOpt ty))
          -- trailing padding up to the max alignment — impl_mem.ml:189-191
          let x := maxSize % maxAlign
          if x == 0 then maxSize else maxSize + (maxAlign - x)
        | _ => panic! "CerbMem.sizeofCtype: Union tag not a UnionDef (OCaml: assert false / Not_found)"
      | .Byte => 1                                  -- impl_mem.ml:193-194

/-- alignof — impl_mem.ml:196-273.
    Struct (impl_mem.ml:228-252): max member alignment (align_opt
    honored), the fold seeded with the flexible array member's
    array-of-element alignment when present (else 0).
    Union (impl_mem.ml:253-271): max member alignment, seed 0.
    Divergence kept from the pre-existing code: Void/Function return 1
    where OCaml `assert false`. -/
def alignofCtype_lemFuel (lemFuel : Nat) (cty : ctype) : Nat :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.alignofCtype: fuel exhausted" 1
  | lemFuel + 1 =>
    match cty with
    | Ctype _ ty_ =>
      match ty_ with
      | .Void0 => 1                                 -- OCaml: assert false
      | .Function _ _ _ | .FunctionNoParams _ => 1  -- OCaml: assert false
      | .Basic (.Integer ity) =>
        match CerberusImpl.alignof_ity ity with     -- impl_mem.ml:200-206
        | some n => n
        | none => panic! "the concrete memory model requires a complete implementation alignof INTEGER"
      | .Basic (.Floating fty) =>
        match CerberusImpl.alignof_fty fty with     -- impl_mem.ml:207-213
        | some n => n
        | none => panic! "the concrete memory model requires a complete implementation alignof FLOATING"
      | .Array0 elemCty _ => alignofCtype_lemFuel lemFuel elemCty   -- impl_mem.ml:214-215
      | .Pointer _ _ => targetPtrSize               -- impl_mem.ml:219-225
      | .Atomic innerCty => alignofCtype_lemFuel lemFuel innerCty   -- impl_mem.ml:226-227
      | .Struct tagSym =>                           -- impl_mem.ml:228-252
        match (fmapElements (CerbTags.tagDefs ())).find? (fun (s, _) => symbolEquality s tagSym) with
        | some (_, (_, StructDef membrs flexibleOpt)) =>
          let init := match flexibleOpt with        -- impl_mem.ml:234-239
            | none => 0
            | some (FlexibleArrayMember _ _ _ elemTy) =>
              alignofCtype_lemFuel lemFuel (mkCtype (.Array0 elemTy none))
          membrs.foldl (init := init) fun acc memb =>
            let (_, (_, alignOpt, _, ty)) := memb
            max (memberAlign_lemFuel lemFuel alignOpt ty) acc  -- impl_mem.ml:242-251
        | _ => panic! "CerbMem.alignofCtype: Struct tag not a StructDef (OCaml: assert false / Not_found)"
      | .Union0 tagSym =>                           -- impl_mem.ml:253-271
        match (fmapElements (CerbTags.tagDefs ())).find? (fun (s, _) => symbolEquality s tagSym) with
        | some (_, (_, UnionDef membrs)) =>
          membrs.foldl (init := (0 : Nat)) fun acc memb =>
            let (_, (_, alignOpt, _, ty)) := memb
            max (memberAlign_lemFuel lemFuel alignOpt ty) acc
        | _ => panic! "CerbMem.alignofCtype: Union tag not a UnionDef (OCaml: assert false / Not_found)"
      | .Byte => 1                                  -- impl_mem.ml:272-273

end

/-- Default-budget wrapper (rfl-defeq to the worker; arc-3 discipline). -/
def memberAlign (alignOpt : Option alignment) (ty : ctype) : Nat :=
  memberAlign_lemFuel lemDefaultFuel alignOpt ty

/-- Default-budget wrapper. -/
def offsetsofMembers
    (members : List (identifier × (attributes × Option alignment × qualifiers × ctype)))
    : List (identifier × ctype × Nat) × Nat :=
  offsetsofMembers_lemFuel lemDefaultFuel members

/-- Default-budget wrapper. -/
def offsetsof (tagDefs : TagDefs) (tagSym : sym)
    (ignoreFlexible : Bool := false) : List (identifier × ctype × Nat) × Nat :=
  offsetsof_lemFuel lemDefaultFuel tagDefs tagSym ignoreFlexible

/-- Default-budget wrapper. -/
def sizeofCtype (cty : ctype) : Nat :=
  sizeofCtype_lemFuel lemDefaultFuel cty

/-- Default-budget wrapper. -/
def alignofCtype (cty : ctype) : Nat :=
  alignofCtype_lemFuel lemDefaultFuel cty

/-! ## Byte-level serialization

    Integer signedness comes from CerberusImpl.is_signed_ity (the
    DefaultImpl port) — the local isSignedIty duplicate that disagreed on
    Wchar_t/Enum is deleted (survey finding 17). -/

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

/-- INTEGER-load provenance policy — AbsByte.pvi_split_bytes,
    impl_mem.ml:455-460: fold combine_prov over the bytes' provenances
    starting from Prov_none, in OCaml's exact argument order
    (`combine_prov b.prov prov_acc`) — the order matters: e.g.
    [some 1, some 2, some 2] folds to Prov_some 2, not Prov_none.
    Used by the Basic-Integer (impl_mem.ml:949-960) and Byte
    (impl_mem.ml:961-973) arms of abst. -/
def provFromIntegerBytes (bytes : List AbsByte) : Provenance :=
  bytes.foldl (fun acc b => combineProv b.prov acc) .Prov_none

/-- POINTER-load provenance policy — AbsByte.split_bytes,
    impl_mem.ml:432-453: the provenance is the bytes' SHARED provenance
    (`VALID p1, p2 when p1 = p2` fold) — any two differing provenances
    (including Prov_none vs Prov_some) collapse to Prov_none. Returns the
    ValidPtrProv status too (all copy_offsets consecutive from 0,
    impl_mem.ml:443-447): OCaml consults it ONLY under is_PNVI ()
    (impl_mem.ml:1021-1053), which this pipeline never enables (no SW_PNVI
    switch is ever set; the differential OCaml side runs with default
    switches), so the pointer arm of reconstructValue uses .1
    unconditionally, mirroring the non-PNVI use site (impl_mem.ml:1052-1054).
    Empty byte list: OCaml failwith (impl_mem.ml:433-434) — mirrored. -/
def splitBytesProv (bytes : List AbsByte) : Provenance × Bool :=
  match bytes with
  | [] => panic! "Concrete.AbsByte.split_bytes: called on an empty list"
  | b :: _ =>
    let prov := if bytes.all (fun b' => b'.prov == b.prov) then b.prov else .Prov_none
    let validPtr := (bytes.zipIdx.all fun (b', i) =>
      match b'.copyOffset with
      | some off => off == (i : Int)
      | none => false)
    (prov, validPtr)

/-- An unspecified padding byte — OCaml's `padding_byte` / `AbsByte.v
    Prov_none None` (impl_mem.ml:1200). -/
private def paddingByte : AbsByte :=
  { prov := .Prov_none, copyOffset := none, value := none }

/-- The funptrmap: function-pointer address (= the function symbol's
    nat) ↦ (file digest, name). Field of mem_state — impl_mem.ml:489. -/
abbrev Funptrmap := List (Int × (String × String))

/-- Serialize a MemValue to bytes — repr, impl_mem.ml:1139-1220.
    Threads the funptrmap exactly like OCaml's
    `repr funptrmap mval : (funptrmap' × bytes)` — storing a PVfunction
    registers the symbol in the map (impl_mem.ml:1168-1185, survey
    finding 20); all other arms pass it through. -/
def memValueToBytes_lemFuel (lemFuel : Nat) (funptrmap : Funptrmap)
    (val_ : MemValue) : Funptrmap × List AbsByte :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.memValueToBytes: fuel exhausted" (funptrmap, [])
  | lemFuel + 1 =>
  match val_ with
  | .MVunspecified ty =>
    -- impl_mem.ml:1142-1144
    let sz := sizeofCtype ty
    (funptrmap, List.replicate sz paddingByte)
  | .MVinteger ity (.IV prov n) =>
    -- impl_mem.ml:1145-1150 (size = sizeof (Basic (Integer ity)));
    -- `List.map (AbsByte.v prov)` — AbsByte.v's copy_offset DEFAULTS to
    -- None (impl_mem.ml:422-423): integer bytes carry NO copy_offset
    -- (audit-2 F8; previously `some i` here, which only pointer bytes
    -- get, impl_mem.ml:1186-1191)
    let sz := match CerberusImpl.sizeof_ity ity with
      | some n => n
      | none => panic! "the concrete memory model requires a complete implementation sizeof INTEGER"
    let rawBytes := intToBytes n sz
    (funptrmap, rawBytes.map fun v =>
      { prov := prov, copyOffset := none, value := v })
  | .MVfloating fty fv =>
    -- impl_mem.ml:1151-1156: Int64.bits_of_float over sizeof(fty) bytes
    -- (= 8 for all real floating types, DefaultImpl 8/8/8 hack — see
    -- CerberusImpl.sizeof_fty)
    let sz := match CerberusImpl.sizeof_fty fty with
      | some n => n
      | none => panic! "the concrete memory model requires a complete implementation sizeof FLOAT"
    let bits := fv.toBits.toNat
    let rawBytes := intToBytes bits sz
    (funptrmap, rawBytes.map fun v => { prov := .Prov_none, copyOffset := none, value := v })
  | .MVpointer _ (.PV prov base) =>
    -- impl_mem.ml:1157-1192
    match base with
    | .PVnull _ =>
      -- impl_mem.ml:1165-1167: all-zero bytes, Prov_none, NO copy_offset
      let rawBytes := intToBytes 0 targetPtrSize
      (funptrmap, rawBytes.map fun v =>
        { prov := .Prov_none, copyOffset := none, value := v })
    | .PVfunction (Symbol fileDig n optName) =>
      -- impl_mem.ml:1168-1185: bytes are the SYMBOL's nat (previously 0
      -- here — the finding-20 bug); an SD_Id symbol is registered in the
      -- funptrmap; bytes carry prov, NO copy_offset (List.map (AbsByte.v
      -- prov), impl_mem.ml:1181-1185)
      let funptrmap' := match optName with
        | SD_Id name =>
          ((n : Int), (fileDig, name)) ::
            funptrmap.filter (fun (a, _) => a != (n : Int))  -- IntMap.add = replace-or-insert
        | _ => funptrmap
      let rawBytes := intToBytes n targetPtrSize
      (funptrmap', rawBytes.map fun v =>
        { prov := prov, copyOffset := none, value := v })
    | .PVconcrete _ addr =>
      -- impl_mem.ml:1186-1191: bytes carry prov AND copy_offset
      let rawBytes := intToBytes addr targetPtrSize
      (funptrmap, (rawBytes.zip (List.range rawBytes.length)).map fun (v, i) =>
        { prov := prov, copyOffset := some i, value := v })
  | .MVarray elems =>
    -- impl_mem.ml:1193-1200: fold threading funptrmap, concat of reprs
    let (fpm, bss) := elems.foldl (init := (funptrmap, ([] : List (List AbsByte))))
      fun (acc : Funptrmap × List (List AbsByte)) mval =>
        let (fpm, bss) := acc
        let (fpm', bs) := memValueToBytes_lemFuel lemFuel fpm mval
        (fpm', bs :: bss)
    (fpm, bss.reverse.flatten)
  | .MVstruct tagSym members =>
    -- impl_mem.ml:1202-1214: pad from the previous member's end up to
    -- each member's offsetsof offset (unspecified bytes), then the
    -- member's bytes; then trailing padding out to sizeof(struct).
    let (offs, lastOff) := offsetsof (fmapElements (CerbTags.tagDefs ())) tagSym (ignoreFlexible := true)
    let finalPad := sizeofCtype (mkCtype (.Struct tagSym)) - lastOff  -- impl_mem.ml:1205
    -- fold2 over layout and members (impl_mem.ml:1207-1212); lengths
    -- coincide for well-typed values (OCaml fold_left2 would raise
    -- Invalid_argument otherwise — zip truncates instead)
    let (fpm, _, bs) := (offs.zip members).foldl
      (init := (funptrmap, (0 : Nat), ([] : List AbsByte)))
      fun (acc : Funptrmap × Nat × List AbsByte)
          (p : (identifier × ctype × Nat) × (identifier × ctype × MemValue)) =>
        let (fpm, lastOff, accBs) := acc
        let ((_, ty, off), (_, _, mval)) := p
        let pad := off - lastOff
        let (fpm', bs) := memValueToBytes_lemFuel lemFuel fpm mval
        (fpm', off + sizeofCtype ty, accBs ++ List.replicate pad paddingByte ++ bs)
    (fpm, bs ++ List.replicate finalPad paddingByte)  -- impl_mem.ml:1214
  | .MVunion tagSym _ mval =>
    -- impl_mem.ml:1216-1219: the active member's bytes, padded out with
    -- unspecified bytes to sizeof(union).
    let size := sizeofCtype (mkCtype (.Union0 tagSym))
    let (fpm, bs) := memValueToBytes_lemFuel lemFuel funptrmap mval
    (fpm, bs ++ List.replicate (size - bs.length) paddingByte)

/-- Default-budget wrapper (rfl-defeq to the worker). -/
def memValueToBytes (funptrmap : Funptrmap) (val_ : MemValue) :
    Funptrmap × List AbsByte :=
  memValueToBytes_lemFuel lemDefaultFuel funptrmap val_

/-- Reconstruct a MemValue from bytes — abst, impl_mem.ml:916-1095.
    INVARIANT (differs from OCaml's consume-and-return-rest shape):
    `bytes` is exactly the sizeof(ty) slice for this value; recursive
    calls re-slice. `unionmap` is mem_state.last_used_union_members and
    `addr` the value's address — consulted ONLY by the Union arm
    (impl_mem.ml:1080-1087); `funptrmap` is mem_state.funptrmap —
    consulted ONLY by the Pointer-to-Function arm (impl_mem.ml:1004-1016)
    — exactly as in OCaml's abst.
    Not ported: taint tracking (PNVI) and is_zap. -/
def reconstructValue_lemFuel (lemFuel : Nat)
    (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.reconstructValue: fuel exhausted" (.MVunspecified ty)
  | lemFuel + 1 =>
  match ty with
  | Ctype _ (.Basic (.Integer ity)) =>
    -- impl_mem.ml:949-960 (signedness via the implementation, as
    -- AilTypesAux.is_signed_ity does there); provenance via the INTEGER
    -- policy — pvi_split_bytes' combine_prov fold (impl_mem.ml:951,
    -- :455-460). mk_ival (impl_mem.ml:637-644) is the non-PNVI branch:
    -- IV (prov, n) as-is.
    let signed := CerberusImpl.is_signed_ity ity
    match bytesToInt bytes signed with
    | some n => .MVinteger ity (.IV (provFromIntegerBytes bytes) n)
    | none => .MVunspecified ty
  | Ctype _ (.Basic (.Floating fty)) =>
    -- impl_mem.ml:974-985
    match bytesToInt bytes false with
    | some n =>
      let bits : UInt64 := n.toNat.toUInt64
      .MVfloating fty (Float.ofBits bits)
    | none => .MVunspecified ty
  | Ctype _ (.Pointer _ pointeeCty) =>
    -- impl_mem.ml:995-1058. MVpointer stores the POINTEE type: every
    -- OCaml arm builds `MVpointer (ref_ty, ...)` (impl_mem.ml:1007,
    -- 1012, 1019, 1054) — matching `typeof` (impl_mem.ml:1123-1124:
    -- MVpointer (ref_ty, _) → Pointer (no_qualifiers, ref_ty)) and our
    -- own pointerMval/MVpointer.refTy. (Audit-2 C1: this previously
    -- stored the full pointer type `ty` — one indirection too many.)
    -- Provenance via the POINTER policy — AbsByte.split_bytes
    -- (impl_mem.ml:998, :432-453); the ValidPtrProv component is
    -- consulted only under is_PNVI (impl_mem.ml:1021-1053), never
    -- enabled here — see splitBytesProv.
    match bytesToInt bytes false with
    | some 0 =>
      -- both the Function and the object branch map 0 to PVnull
      -- (impl_mem.ml:1005-1007, 1017-1019)
      .MVpointer pointeeCty (.PV .Prov_none (.PVnull pointeeCty))
    | some ptrAddr =>
      let (prov, _validPtrProv) := splitBytesProv bytes
      match pointeeCty with
      | Ctype _ (.Function _ _ _) =>
        -- impl_mem.ml:1004-1015: a pointer-to-function is rebuilt from
        -- the funptrmap entry registered at store time (repr,
        -- impl_mem.ml:1168-1185); the address IS the function symbol's
        -- nat. Unknown address: OCaml failwith — panic. (OCaml's own
        -- FIXME about same-id symbols across files applies unchanged.)
        match funptrmap.find? (fun (a, _) => a == ptrAddr) with
        | some (_, (fileDig, name)) =>
          .MVpointer pointeeCty (.PV prov (.PVfunction (Symbol fileDig ptrAddr.toNat (SD_Id name))))
        | none => panic! s!"unknown function pointer: {ptrAddr}"
      | _ =>
        .MVpointer pointeeCty (.PV prov (.PVconcrete none ptrAddr.toNat))
    | none => .MVunspecified ty
  | Ctype _ (.Array0 elemCty (some n)) =>
    -- impl_mem.ml:986-994; NOTE OCaml's `self elem_ty cs` does NOT
    -- advance ~addr per element — every element sees the array's addr
    -- (mirrored: nested-union lookups use the array base address).
    let nNat := n.toNat
    let elemSize := sizeofCtype elemCty
    if elemSize == 0 then .MVarray []
    else
      let elems := List.range nNat |>.map fun i =>
        let start := i * elemSize
        let elemBytes := bytes.drop start |>.take elemSize
        reconstructValue_lemFuel lemFuel unionmap funptrmap addr elemCty elemBytes
      .MVarray elems
  | Ctype _ (.Atomic innerCty) =>
    -- impl_mem.ml:1058-1060 (same repr as the non-atomic version)
    reconstructValue_lemFuel lemFuel unionmap funptrmap addr innerCty bytes
  | Ctype _ .Byte =>
    -- impl_mem.ml:961-973 ("handled similarly to integers": provenance
    -- via pvi_split_bytes' combine_prov fold, impl_mem.ml:964)
    match bytesToInt (bytes.take 1) false with
    | some n => .MVinteger .Char0 (.IV (provFromIntegerBytes (bytes.take 1)) n)
    | none => .MVunspecified ty
  | Ctype _ (.Struct tagSym) =>
    -- impl_mem.ml:1061-1073: member-wise reconstruct at the offsetsof
    -- offsets (ignore_flexible=true), skipping inter-member padding.
    -- NOTE OCaml's `self ~offset:pad` advances the member addr by the
    -- PADDING before the member only, not by the member offset
    -- (impl_mem.ml:1063-1067) — mirrored quirk; addr is only consulted
    -- by nested union lookups.
    let (offs, _) := offsetsof (fmapElements (CerbTags.tagDefs ())) tagSym (ignoreFlexible := true)
    let (revXs, _) := offs.foldl
      (init := (([] : List (identifier × ctype × MemValue)), (0 : Nat)))
      fun (acc : List (identifier × ctype × MemValue) × Nat) (memb : identifier × ctype × Nat) =>
        let (revXs, prevEnd) := acc
        let (ident, membTy, off) := memb
        let pad := off - prevEnd
        let membBytes := bytes.drop off |>.take (sizeofCtype membTy)
        let mval := reconstructValue_lemFuel lemFuel unionmap funptrmap (addr + (pad : Int)) membTy membBytes
        ((ident, membTy, mval) :: revXs, off + sizeofCtype membTy)
    .MVstruct tagSym revXs.reverse
  | Ctype _ (.Union0 tagSym) =>
    -- impl_mem.ml:1074-1095: select the member recorded in
    -- last_used_union_members at this address; default to the FIRST
    -- declared member when absent (impl_mem.ml:1080-1083).
    match (fmapElements (CerbTags.tagDefs ())).find? (fun (s, _) => symbolEquality s tagSym) with
    | some (_, (_, UnionDef membrs)) =>
      match membrs with
      | [] => panic! "CerbMem.reconstructValue: empty UnionDef (OCaml: match failure)"
      | (firstIdent, (_, _, _, firstTy)) :: _ =>
        let (membIdent, membTy) :=
          match unionmap.find? (fun (a, _) => a == addr) with
          | none => (firstIdent, firstTy)
          | some (_, membr) =>
            -- ident comparison is by NAME (idEqual), as OCaml's
            -- Eq Symbol.identifier instance does (impl_mem.ml:1085-1090)
            match membrs.find? (fun (i, _) => idEqual i membr) with
            | some (i, (_, _, _, t)) => (i, t)
            | none => panic! "CerbMem.reconstructValue: recorded union member not in UnionDef (OCaml: assert false)"
        let mval := reconstructValue_lemFuel lemFuel unionmap funptrmap addr membTy
          (bytes.take (sizeofCtype membTy))  -- self membr_ty bs1 — impl_mem.ml:1091
        .MVunion tagSym membIdent mval
    | _ => panic! "CerbMem.reconstructValue: Union tag not a UnionDef (OCaml: assert false)"
  | _ => .MVunspecified ty

/-- Default-budget wrapper (rfl-defeq to the worker). -/
def reconstructValue (unionmap : List (Int × identifier))
    (funptrmap : Funptrmap) (addr : Int)
    (ty : ctype) (bytes : List AbsByte) : MemValue :=
  reconstructValue_lemFuel lemDefaultFuel unionmap funptrmap addr ty bytes

/-! ## Memory-value typing — the store guard's helpers (audit-2 C3) -/

/-- typeof — impl_mem.ml:1115-1136. The ctype a mem_value inhabits;
    MVpointer's first component is the POINTEE type (impl_mem.ml:1123-1124).
    MVarray []: OCaml `assert false` ("ill-formed value",
    impl_mem.ml:1125-1127) — panic. Array element type from the FIRST
    element only (OCaml's own TODO shrug, impl_mem.ml:1128-1131). -/
def typeofMval_lemFuel (lemFuel : Nat) : MemValue → ctype :=
  fun mval =>
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.typeofMval: fuel exhausted" (mkCtype .Void0)
  | lemFuel + 1 =>
  match mval with
  | .MVunspecified (Ctype _ ty) => mkCtype ty
  | .MVinteger ity _ => mkCtype (.Basic (.Integer ity))
  | .MVfloating fty _ => mkCtype (.Basic (.Floating fty))
  | .MVpointer refTy _ => mkCtype (.Pointer no_qualifiers refTy)
  | .MVarray [] => panic! "CerbMem.typeofMval: MVarray [] (OCaml: assert false, ill-formed value)"
  | .MVarray (mval :: rest) =>
    mkCtype (.Array0 (typeofMval_lemFuel lemFuel mval) (some ((rest.length + 1 : Nat) : Int)))
  | .MVstruct tagSym _ => mkCtype (.Struct tagSym)
  | .MVunion tagSym _ _ => mkCtype (.Union0 tagSym)

/-- Default-budget wrapper (rfl-defeq to the worker). -/
def typeofMval (mval : MemValue) : ctype :=
  typeofMval_lemFuel lemDefaultFuel mval

/-- ctype_mem_compatible — impl_mem.ml:23-49: structural ctype equality
    after recursively erasing qualifiers, annotations and Atomic wrappers;
    Byte compares as unsigned char (impl_mem.ml:30-32); function-parameter
    is_register flags are dropped to false (impl_mem.ml:33-38, the
    `(_, ty, _) -> (..., false)` map). Used ONLY by the store guard. -/
private def unqualifyAndUnatomic_lemFuel (lemFuel : Nat) : ctype → ctype_ :=
  fun cty =>
  match lemFuel with
  | 0 => fuelExhaustedWith "CerbMem.unqualifyAndUnatomic: fuel exhausted" .Void0
  | lemFuel + 1 =>
  match cty with
  | Ctype _ ty =>
    match ty with
    | .Void0 | .Basic _ | .Struct _ | .Union0 _ => ty
    | .Byte => .Basic (.Integer (.Unsigned .Ichar))
    | .Function (_, retTy) params variadic =>
      .Function (no_qualifiers, Ctype [] (unqualifyAndUnatomic_lemFuel lemFuel retTy))
        (params.map fun (p : qualifiers × ctype × Bool) =>
          (no_qualifiers, Ctype [] (unqualifyAndUnatomic_lemFuel lemFuel p.2.1), false))
        variadic
    | .FunctionNoParams (_, retTy) =>
      .FunctionNoParams (no_qualifiers, Ctype [] (unqualifyAndUnatomic_lemFuel lemFuel retTy))
    | .Array0 elemTy nOpt =>
      .Array0 (Ctype [] (unqualifyAndUnatomic_lemFuel lemFuel elemTy)) nOpt
    | .Pointer _ refTy =>
      .Pointer no_qualifiers (Ctype [] (unqualifyAndUnatomic_lemFuel lemFuel refTy))
    | .Atomic atomTy => unqualifyAndUnatomic_lemFuel lemFuel atomTy

/-- Default-budget wrapper (rfl-defeq to the worker). -/
private def unqualifyAndUnatomic (cty : ctype) : ctype_ :=
  unqualifyAndUnatomic_lemFuel lemDefaultFuel cty

def ctypeMemCompatible (ty1 ty2 : ctype) : Bool :=
  ctypeEqual (Ctype [] (unqualifyAndUnatomic ty1)) (Ctype [] (unqualifyAndUnatomic ty2))

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

/-- max_ival — impl_mem.ml:2367-2402. Enum is normalized through
    typeof_enum FIRST (impl_mem.ml:2369-2372; the CerberusImpl stub
    returns Signed Int_ — the real per-program enum registry is survey
    finding 18b, deliberately left a stub: nothing in tests/minimal
    declares an enum whose underlying type differs from int).
    Bool: OCaml uses unsigned_max = 255 (its own "TODO: not sure about
    this (maybe it should be 1 ...)" at impl_mem.ml:2385-2387 — mirrored
    as-is). Char: signed (DefaultImpl char_is_signed = true,
    ocaml_implementation.ml:257). Wchar_t: unsigned_max
    (impl_mem.ml:2388-2392); Wint_t: signed_max (impl_mem.ml:2393-2396).
    Missing sizeof: OCaml failwith → panic. -/
def maxIval (ity : integerType) : IntegerValue :=
  let ity := match ity with
    | .Enum0 nm => CerberusImpl.typeof_enum nm
    | _ => ity
  let size := match CerberusImpl.sizeof_ity ity with
    | some n => n
    | none => panic! "the concrete memory model requires a complete implementation MAX"
  let signedMax : Int := (2 ^ (size * 8 - 1)) - 1
  let unsignedMax : Int := (2 ^ (size * 8)) - 1
  integerIval (match ity with
    | .Char0 => if CerberusImpl.is_signed_ity .Char0 then signedMax else unsignedMax
    | .Bool0 => unsignedMax          -- 255, OCaml's own TODO behavior
    | .Size_t | .Wchar_t | .Unsigned _ => unsignedMax
    | .Ptrdiff_t | .Wint_t | .Signed _ => signedMax
    | .Ptraddr_t => unsignedMax
    | .Enum0 _ => panic! "maxIval: Enum after typeof_enum (OCaml: assert false)")

/-- min_ival — impl_mem.ml:2405-2434. Enum through typeof_enum
    (impl_mem.ml:2407-2410). Char: signed → -2^7 (OCaml hardcodes 8-1
    bits, impl_mem.ml:2412-2416). Bool/Size_t/Wchar_t/Wint_t/Unsigned:
    zero (impl_mem.ml:2417-2424 — note Wint_t is UNSIGNED here but
    SIGNED in max_ival; OCaml's asymmetry, mirrored). Ptrdiff_t/Signed:
    -2^(8n-1) (impl_mem.ml:2425-2432). -/
def minIval (ity : integerType) : IntegerValue :=
  let ity := match ity with
    | .Enum0 nm => CerberusImpl.typeof_enum nm
    | _ => ity
  integerIval (match ity with
    | .Char0 =>
      if CerberusImpl.is_signed_ity .Char0 then -(2 ^ (8 - 1)) else 0
    | .Bool0 | .Size_t | .Wchar_t | .Wint_t | .Unsigned _ => 0
    | .Ptrdiff_t | .Signed _ =>
      match CerberusImpl.sizeof_ity ity with
      | some n => -(2 ^ (n * 8 - 1))
      | none => panic! "the concrete memory model requires a complete implementation MIN"
    | .Ptraddr_t => 0
    | .Enum0 _ => panic! "minIval: Enum after typeof_enum (OCaml: assert false)")

def sizeofIval (ty : ctype) : IntegerValue := integerIval (sizeofCtype ty)
def alignofIval (ty : ctype) : IntegerValue := integerIval (alignofCtype ty)

def concurReadIval (_ : integerType) (_ : sym) : IntegerValue := integerIval 0

/-! ### Integer division/remainder helpers

    OCaml's `Z` in impl_mem.ml (impl_mem.ml:7-13) extends zarith with
      let integerRem_t = (mod)                  — zarith `Z.(mod)` = `Z.rem`
      let integerRem_f = Big_int_Z.mod_big_int  — zarith's legacy-Big_int mod
    Verified against zarith (z.mli:160-168, 820-821, and empirically):
      Z.div        : TRUNCATING quotient (round toward zero): -7/2 = -3
      Z.rem        : truncating remainder, sign of the DIVIDEND:
                     rem 7 (-2) = 1, rem (-7) 2 = -1
      mod_big_int  : EUCLIDEAN remainder, always non-negative (NOT
                     flooring): mod_big_int (-7) 2 = 1,
                     mod_big_int (-7) (-2) = 1 (floor would give -1)
    Lean's Int `/`/`%` are ediv/emod — NOT these; use the explicit forms.
    Zero divisor: zarith raises Division_by_zero where impl_mem.ml has no
    guard (IntRem_t/IntRem_f, impl_mem.ml:2481-2484); that is unreachable
    behind Core's division-by-zero UB guards (UB045), and Lean's total
    tdiv/tmod/emod return their `_ 0 = dividend`/`0` defaults instead —
    deliberate divergence on an unreachable input, recorded here. -/

/-- Z.div — truncating quotient (zarith z.mli:155-162). -/
def integerDiv_t (a b : Int) : Int := Int.tdiv a b
/-- Z.integerRem_t = Z.rem — truncating remainder, sign of dividend
    (impl_mem.ml:11, zarith z.mli:164-168). -/
def integerRem_t (a b : Int) : Int := Int.tmod a b
/-- Z.integerRem_f = Big_int_Z.mod_big_int — euclidean remainder,
    always non-negative (impl_mem.ml:12). Lean's Int.emod is exactly
    euclidean remainder. -/
def integerRem_f (a b : Int) : Int := Int.emod a b

/-- op_ival — impl_mem.ml:2464-2490 -/
def opIval (op : integer_operator) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    match op with
    | .IntAdd => .IV (combineProv prov1 prov2) (n1 + n2)
    | .IntSub =>
      -- provenance special case — impl_mem.ml:2469-2475: Sub forwards
      -- prov1 only when prov1 is Prov_some/device and prov2 is not
      -- Prov_some (ptr − int keeps the pointer's provenance; ptr − ptr
      -- and int − anything lose it)
      let prov' := match prov1, prov2 with
        | .Prov_some _, .Prov_some _ => Provenance.Prov_none
        | .Prov_none, _ => Provenance.Prov_none
        | _, _ => prov1
      .IV prov' (n1 - n2)
    | .IntMul => .IV (combineProv prov1 prov2) (n1 * n2)
    | .IntDiv =>
      -- impl_mem.ml:2479-2480: explicit zero guard, then TRUNCATING Z.div
      .IV (combineProv prov1 prov2) (if n2 == 0 then 0 else integerDiv_t n1 n2)
    | .IntRem_t => .IV (combineProv prov1 prov2) (integerRem_t n1 n2)  -- impl_mem.ml:2481-2482
    | .IntRem_f => .IV (combineProv prov1 prov2) (integerRem_f n1 n2)  -- impl_mem.ml:2483-2484
    | .IntExp =>
      -- impl_mem.ml:2485-2490: Prov_none (shift elaboration forwards the
      -- LEFT operand's provenance elsewhere); Z.pow with Z.to_int n2 —
      -- negative n2 raises in zarith (unreachable: shifts guard
      -- negative counts upstream); Lean's toNat clamps to 0 instead.
      .IV Provenance.Prov_none (n1 ^ n2.toNat)

/-- offsetof_ival — impl_mem.ml:2193-2201: offsetsof (WITHOUT
    ignore_flexible — OCaml uses the default there), member found by NAME
    (ident_equal = idEqual); union members are all at offset 0 via
    offsetsof's union arm. Missing member: OCaml failwith — panic here
    (the previous code silently returned 0 and compared identifiers
    location-sensitively with BEq). -/
def offsetofIval (tagDefsMap : CerbTags.TagDefsMap) (tag : sym) (memb : identifier) : IntegerValue :=
  -- target_rep for lem offsetof_ival (mem.lem:257): the lem-side argument is
  -- the tag map; scan its enumeration spine (arc-6 S3 — same list as before)
  let (xs, _) := offsetsof (fmapElements tagDefsMap) tag
  match xs.find? (fun (ident, _, _) => idEqual ident memb) with
  | some (_, _, off) => integerIval off
  | none => panic! "Concrete.offsetof_ival: invalid memb_ident"

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
    .IV prov (toSigned result bits (CerberusImpl.is_signed_ity ity))

def bitwiseAndIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let result := toUnsigned n1 bits &&& toUnsigned n2 bits
    .IV (combineProv prov1 prov2) (toSigned result bits (CerberusImpl.is_signed_ity ity))

def bitwiseOrIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let result := toUnsigned n1 bits ||| toUnsigned n2 bits
    .IV (combineProv prov1 prov2) (toSigned result bits (CerberusImpl.is_signed_ity ity))

def bitwiseXorIval (ity : integerType) (v1 v2 : IntegerValue) : IntegerValue :=
  match v1, v2 with
  | .IV prov1 n1, .IV prov2 n2 =>
    let size := match CerberusImpl.sizeof_ity ity with | some n => n | none => 4
    let bits := size * 8
    let result := toUnsigned n1 bits ^^^ toUnsigned n2 bits
    .IV (combineProv prov1 prov2) (toSigned result bits (CerberusImpl.is_signed_ity ity))

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
/-- ivfromfloat — impl_mem.ml:2553-2554: `IV (Prov_none, Z.of_float fval)`.
    Z.of_float truncates toward ZERO keeping the sign (verified against
    zarith: of_float (-2.9) = -2); CerbFloat.truncToInt mirrors that
    bit-exactly (the previous Float.toUInt64 path clamped all negatives
    to 0 — survey finding 6). NaN/inf: Z.of_float raises Z.Overflow,
    mirrored by truncToInt's panic. -/
def ivfromfloat (_ : integerType) (fv : FloatingValue) : IntegerValue :=
  integerIval (CerbFloat.truncToInt fv)

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

/-- array_shift_ptrval — shift pointer by array index.
    Matches impl_mem.ml:2203-2221: GNU extension lets void be byte-granular;
    null/function pointer arithmetic panics (per OCaml, UB in ISO C). -/
def arrayShiftPtrval (pv : PointerValue) (elemTy : ctype) (iv : IntegerValue) : PointerValue :=
  match pv, iv with
  | .PV _ (.PVnull _), _ =>
    panic! "array_shift_ptrval: shift on null pointer is UB"
  | .PV _ (.PVfunction _), _ =>
    panic! "array_shift_ptrval: PVfunction"
  | .PV prov (.PVconcrete um addr), .IV _ n =>
    -- GNU extension: void element type → byte-granular shift (sz = 1)
    let elemSize : Int := match elemTy with
      | Ctype _ .Void0 => 1
      | _ => Int.ofNat (sizeofCtype elemTy)
    let offset := n * elemSize
    .PV prov (.PVconcrete um (addr + offset))

/-- member_shift_ptrval — impl_mem.ml:2223-2242.
    Shift pointer to struct/union member. Uses CerbTags.tagDefs () to look up
    the struct layout. For unions, all members are at offset 0 but we record
    which member we're pointing to (in PVconcrete's unionMember field). -/
def memberShiftPtrval (pv : PointerValue) (tag : sym) (memb : identifier) : PointerValue :=
  let tagDefsAsList : List (sym × (CerbLocation.Loc × tag_definition)) :=
    fmapElements (CerbTags.tagDefs ())
  let (.IV _ offsetVal) := offsetofIval (CerbTags.tagDefs ()) tag memb
  let isUnion := match tagDefsAsList.find? (fun (s, _) => symbolEquality s tag) with
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

/-- The concrete model's kill reason for a memory error — mirrors
    Concrete.fail (impl_mem.ml:540-546): a mem_error that maps to an
    undefined behaviour via `undefinedFromMem_error` (mem_common.lem:248+)
    kills with `Undef0 (loc, [ub])` (→ batch verdict `Undefined {ub:...}`),
    everything else with `Other err`. Default loc mirrors OCaml's
    `?(loc=Cerb_location.other "Concrete")`. -/
private def failReason (err : mem_error)
    (loc : CerbLocation.Loc := CerbLocation.other "Concrete") :
    kill_reason mem_error :=
  match undefinedFromMem_error err with
  | some ub => Undef0 loc [ub]
  | none => kill_reason.Other err

/-- fail — impl_mem.ml:540-546 (see failReason). -/
private def memFail {a : Type} (err : mem_error)
    (loc : CerbLocation.Loc := CerbLocation.other "Concrete") : memM a :=
  kill (failReason err loc)

private def alignDown (addr align : Nat) : Nat := (addr / align) * align

/-! ### Bytemap operations -/

private def writeBytesTo (st : MemState) (addr : Int) (bytes : List AbsByte) : MemState :=
  -- insert-or-replace per byte (was: prepend + filter of the whole map)
  let bm := (bytes.foldl
    (fun (acc : Std.TreeMap Int AbsByte × Int) b => (acc.1.insert acc.2 b, acc.2 + 1))
    (st.bytemap, addr)).1
  { st with bytemap := bm }

private def readBytesFrom (st : MemState) (addr : Int) (size : Nat) : List AbsByte :=
  (List.range size).map fun (i : Nat) =>
    match st.bytemap.get? (addr + (i : Int)) with
    | some b => b
    | none => { prov := .Prov_none, copyOffset := none, value := none }

private def getAllocation (st : MemState) (pv : PointerValue) : Option (Int × Allocation) :=
  match pv with
  | .PV (.Prov_some allocId) _ =>
    if st.deadAllocations.contains allocId then none
    else (st.allocations.get? allocId).map (fun a => (allocId, a))
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
        allocations := st.allocations.insert allocId alloc }
      let st' := match initOpt with
        | some val_ =>
          -- repr threads the funptrmap into the state — impl_mem.ml:1336-1344
          let (fpm, bs) := memValueToBytes st'.funptrmap val_
          writeBytesTo { st' with funptrmap := fpm } alignedAddr bs
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
        allocations := st.allocations.insert allocId alloc
        dynamicAddrs := alignedAddr :: st.dynamicAddrs }
      let st' := writeBytesTo st' alignedAddr
          (List.replicate size { prov := .Prov_none, copyOffset := none, value := none })
      (NDactive (.PV (.Prov_some allocId) (.PVconcrete none alignedAddr)), st')

/-! ### Kill — impl_mem.ml:1464+ -/

def killM (loc : CerbLocation.Loc) (isDynamic : Bool) (pv : PointerValue) : memM Unit :=
  ND fun st =>
    -- errors route through the fail mapping (impl_mem.ml:540-546), so
    -- Free_non_matching/Free_dead_allocation surface as UB179a/UB179b
    let fail_ (err : mem_error) := (NDkilled (failReason err loc), st)
    match pv with
    | .PV _ (.PVnull _) =>
      if isDynamic then (NDactive (), st)
      else fail_ (MerrUndefinedFree Free_non_matching)
    | .PV _ (.PVfunction _) => fail_ (MerrUndefinedFree Free_non_matching)
    | .PV (.Prov_some allocId) (.PVconcrete _ addr) =>
      if st.deadAllocations.contains allocId then
        fail_ (MerrUndefinedFree Free_dead_allocation)
      else match st.allocations.get? allocId with
        | none => fail_ (MerrUndefinedFree Free_non_matching)
        | some alloc =>
          if addr != alloc.base then
            fail_ (MerrUndefinedFree Free_out_of_bound)
          else if isDynamic && !st.dynamicAddrs.contains alloc.base then
            fail_ (MerrUndefinedFree Free_non_matching)
          else
            let st' := { st with
              deadAllocations := allocId :: st.deadAllocations
              allocations := st.allocations.erase allocId }
            (NDactive (), st')
    | _ => fail_ (MerrUndefinedFree Free_non_matching)

/-! ### Load / Store — impl_mem.ml:1552-1789

    The provenance case split mirrors OCaml's load/store matches
    (impl_mem.ml:1604-1664 / 1711-1789). Notably (survey finding 12) the
    OCaml concrete model NEVER emits the NoProvPtr constructor — the
    three distinct outcomes are:
      Prov_none            → MerrAccess _ OutOfBoundPtr
                             (impl_mem.ml:1609-1610 / 1716-1717)
      Prov_some + dead     → load: MerrAccess LoadAccess DeadPtr
                             (explicit is_dead check, impl_mem.ml:1645-1650);
                             store: NO dead check — is_within_bound's
                             get_allocation on a discarded allocation
                             fails MerrOutsideLifetime
                             (impl_mem.ml:1763 → :669-675)
      Prov_some + missing  → MerrOutsideLifetime (get_allocation,
                             impl_mem.ml:669-675)
    Every failure goes through the fail mapping (failReason,
    impl_mem.ml:540-546), so UB-classed errors surface as Undef0.
    Not ported: Prov_device is_within_device (the device_ranges list is
    empty in this pipeline — no device allocations exist, so the OCaml
    check always returns false → OutOfBoundPtr, which is what we emit
    directly); Prov_symbolic iota resolution (PNVI-ae-udi; the concrete
    Lean model never mints Prov_symbolic). -/

/-- is_atomic_member_access — impl_mem.ml:689-706: accessing a PART of an
    atomic allocation (not the whole object with the same type) is an
    AtomicMemberof error. -/
private def isAtomicMemberAccess (alloc : Allocation) (lvalueTy : ctype) (addr : Int) : Bool :=
  match alloc.ty with
  | some allocTy =>
    match allocTy with
    | Ctype _ (.Atomic _) =>
      -- impl_mem.ml:692-703 (the type-equality conjunct deals with a
      -- padding-free first member)
      !(addr == alloc.base && (sizeofCtype lvalueTy : Int) == alloc.size
        && ctypeEqual lvalueTy allocTy)
    | _ => false
  | none => false

def loadM (loc : CerbLocation.Loc) (ty : ctype) (pv : PointerValue) : memM (Footprint × MemValue) :=
  ND fun st =>
    let fail_ (err : mem_error) := (NDkilled (failReason err loc), st)
    -- do_load — impl_mem.ml:1556-1603 (PNVI expose/last_used bookkeeping
    -- not ported; SW_strict_reads never set here)
    let doLoad (addr : Int) :=
      let size := sizeofCtype ty
      let bytes := readBytesFrom st addr size
      let fp : Footprint := .FP .R addr size
      -- abst at the load address with last_used_union_members and
      -- funptrmap — impl_mem.ml:1560
      let mv := reconstructValue st.lastUsedUnionMembers st.funptrmap addr ty bytes
      -- trap representation for _Bool — impl_mem.ml:1576-1591
      let isBool := match ty with | Ctype _ (.Basic (.Integer .Bool0)) => true | _ => false
      let isTrap := isBool && match mv with
        | .MVinteger _ (.IV _ n) => n != 0 && n != 1
        | .MVunspecified _ => true
        | _ => false
      if isTrap then fail_ (MerrTrapRepresentation LoadAccess)
      else (NDactive (fp, mv), st)
    match pv with
    | .PV _ (.PVnull _) => fail_ (MerrAccess LoadAccess NullPtr)          -- impl_mem.ml:1605-1606
    | .PV _ (.PVfunction _) => fail_ (MerrAccess LoadAccess FunctionPtr)  -- impl_mem.ml:1607-1608
    | .PV .Prov_none _ => fail_ (MerrAccess LoadAccess OutOfBoundPtr)     -- impl_mem.ml:1609-1610
    | .PV .Prov_device (.PVconcrete _ _) =>
      -- impl_mem.ml:1611-1617: is_within_device over the (empty) device
      -- ranges → always false here
      fail_ (MerrAccess LoadAccess OutOfBoundPtr)
    | .PV (.Prov_symbolic _) _ =>
      (NDkilled (kill_reason.Other
        (MerrOther "loadM: Prov_symbolic in concrete model")), st)
    | .PV (.Prov_some allocId) (.PVconcrete _ addr) =>
      -- impl_mem.ml:1644-1664
      if st.deadAllocations.contains allocId then
        fail_ (MerrAccess LoadAccess DeadPtr)                             -- impl_mem.ml:1645-1650
      else match st.allocations.get? allocId with
        | none =>
          -- get_allocation (via is_within_bound) — impl_mem.ml:669-675
          fail_ (MerrOutsideLifetime s!"Concrete.get_allocation, alloc_id={allocId}")
        | some alloc =>
          if !isInBounds alloc addr (sizeofCtype ty) then
            fail_ (MerrAccess LoadAccess OutOfBoundPtr)                   -- impl_mem.ml:1651-1656
          else if isAtomicMemberAccess alloc ty addr then
            fail_ (MerrAccess LoadAccess AtomicMemberof)                  -- impl_mem.ml:1658-1660
          else doLoad addr

def storeM (loc : CerbLocation.Loc) (ty : ctype) (isLocking : Bool) (pv : PointerValue) (mv : MemValue) : memM Footprint :=
  ND fun st =>
    let fail_ (err : mem_error) := (NDkilled (failReason err loc), st)
    -- select_ro_kind — impl_mem.ml:1704-1710
    let selectRoKind : prefix0 → readonly_kind := fun pref =>
      match pref with
      | PrefTemporaryLifetime _ _ => readonly_kind.ReadonlyTemporaryLifetime
      | PrefStringLiteral _ _ => readonly_kind.ReadonlyStringLiteral
      | _ => readonly_kind.ReadonlyConstQualified
    -- do_store — impl_mem.ml:1683-1703: bytemap write threads the
    -- funptrmap from repr; then the last_used_union_members update iff
    -- the pointer is PVconcrete (Some membr, _) (union member_shift,
    -- impl_mem.ml:1694-1701)
    let doStore (allocId : Int) (alloc : Allocation) (unionMem : Option identifier) (addr : Int) :=
      let (fpm, bytes) := memValueToBytes st.funptrmap mv
      let st' := writeBytesTo { st with funptrmap := fpm } addr bytes
      let st' := match unionMem with
        | some membr => { st' with lastUsedUnionMembers :=
            (addr, membr) :: st'.lastUsedUnionMembers.filter (fun (a, _) => a != addr) }
        | none => st'
      -- is_locking — impl_mem.ml:1776-1787: readonly kind from the
      -- allocation's prefix
      let st' := if isLocking then
        { st' with allocations := st'.allocations.map fun id a =>
            if id == allocId then
              { a with isReadonly := .IsReadOnly (selectRoKind alloc.prefix_) }
            else a }
        else st'
      let fp : Footprint := .FP .W addr (sizeofCtype ty)
      (NDactive fp, st')
    -- ill-typed-store guard — impl_mem.ml:1673-1681: checked BEFORE the
    -- provenance/pointer-kind match (so it wins over NullPtr etc.);
    -- OCaml's diagnostic printfs (:1674-1680) are not mirrored, the
    -- failure is (MerrOther, non-UB → Other kill, batch Error line).
    if !(ctypeMemCompatible ty (typeofMval mv)) then
      fail_ (MerrOther "store with an ill-typed memory value")
    else
    match pv with
    | .PV _ (.PVnull _) => fail_ (MerrAccess StoreAccess NullPtr)          -- impl_mem.ml:1712-1713 (order per :1711-1717)
    | .PV _ (.PVfunction _) => fail_ (MerrAccess StoreAccess FunctionPtr)  -- impl_mem.ml:1714-1715
    | .PV .Prov_none _ => fail_ (MerrAccess StoreAccess OutOfBoundPtr)     -- impl_mem.ml:1716-1717
    | .PV .Prov_device (.PVconcrete _ _) =>
      -- impl_mem.ml:1718-1724: empty device ranges → always out of bounds
      fail_ (MerrAccess StoreAccess OutOfBoundPtr)
    | .PV (.Prov_symbolic _) _ =>
      (NDkilled (kill_reason.Other
        (MerrOther "storeM: Prov_symbolic in concrete model")), st)
    | .PV (.Prov_some allocId) (.PVconcrete unionMem addr) =>
      -- impl_mem.ml:1762-1789: NO is_dead check on the store path — a
      -- dead allocation is caught by is_within_bound's get_allocation
      -- (MerrOutsideLifetime); bounds are checked BEFORE readonly
      match st.allocations.get? allocId with
      | none =>
        fail_ (MerrOutsideLifetime s!"Concrete.get_allocation, alloc_id={allocId}")
      | some alloc =>
        if !isInBounds alloc addr (sizeofCtype ty) then
          fail_ (MerrAccess StoreAccess OutOfBoundPtr)                     -- impl_mem.ml:1763-1765
        else match alloc.isReadonly with
          | .IsReadOnly kind => fail_ (MerrWriteOnReadOnly kind)           -- impl_mem.ml:1768-1770
          | .IsWritable =>
            if isAtomicMemberAccess alloc ty addr then
              -- NOTE: OCaml reports LoadAccess here (impl_mem.ml:1772-1774
              -- — looks like an upstream copy-paste; mirrored as-is)
              fail_ (MerrAccess LoadAccess AtomicMemberof)
            else doStore allocId alloc unionMem addr

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

/-- diff_ptrval — impl_mem.ml:1954-1984 (strict, non-PERMISSIVE path;
    the SW_pointer_arith PERMISSIVE branch at :1970-1975 is not ported —
    the Lean pipeline never sets that switch — and the Prov_symbolic
    iota arms at :1987-2058 are unreachable here: the concrete Lean
    model never mints Prov_symbolic).
    Valid only when BOTH pointers carry the SAME Prov_some allocation id
    and both addresses lie within [base, base+size] of that allocation
    (precond, impl_mem.ml:1955-1959); everything else fails MerrPtrdiff
    (→ UB048_disjoint_array_pointers_subtraction via the fail mapping).
    valid_postcond (impl_mem.ml:1961-1967): strip ONE Array layer off
    diff_ty, then TRUNCATING Z.div of the address difference by
    sizeof(elem). -/
def diffPtrval (loc : CerbLocation.Loc) (diffTy : ctype) (pv1 pv2 : PointerValue) : memM IntegerValue :=
  ND fun st =>
    let errorPostcond := (NDkilled (failReason MerrPtrdiff loc), st)
    match pv1, pv2 with
    | .PV (.Prov_some allocId1) (.PVconcrete _ addr1),
      .PV (.Prov_some allocId2) (.PVconcrete _ addr2) =>
      if allocId1 == allocId2 then
        match st.allocations.get? allocId1 with
        | none =>
          -- get_allocation ~loc alloc_id1 — impl_mem.ml:669-675
          (NDkilled (failReason (MerrOutsideLifetime
            s!"Concrete.get_allocation, alloc_id={allocId1}") loc), st)
        | some alloc =>
          let precond :=  -- impl_mem.ml:1955-1959
            alloc.base ≤ addr1 && addr1 ≤ alloc.base + alloc.size &&
            alloc.base ≤ addr2 && addr2 ≤ alloc.base + alloc.size
          if precond then
            let diffTy' := match diffTy with  -- impl_mem.ml:1962-1966
              | Ctype _ (.Array0 elemTy _) => elemTy
              | _ => diffTy
            (NDactive (integerIval
              (integerDiv_t (addr1 - addr2) (sizeofCtype diffTy' : Int))), st)
          else errorPostcond
      else errorPostcond
    | _, _ => errorPostcond

/-! ### Pointer validity -/

/-- Strip Atomic wrapper — mirrors OCaml unatomic_. -/
private def unatomic_ : ctype → ctype_
  | Ctype _ (.Atomic inner) => match inner with | Ctype _ t => t
  | Ctype _ t => t

/-- isWellAligned_ptrval — impl_mem.ml:2065-2083.
    Fails on void or function ref_ty. Fails on function pointers.
    True for null pointers. For concrete: checks addr % alignof == 0. -/
def isWellAlignedPtrval (ty : ctype) (pv : PointerValue) : memM Bool :=
  match unatomic_ ty with
  | .Void0 =>
    memFail (MerrOther "called isWellAligned_ptrval on void")
  | .Function _ _ _ | .FunctionNoParams _ =>
    memFail (MerrOther "called isWellAligned_ptrval on a function type")
  | _ =>
    match pv with
    | .PV _ (.PVnull _) => memReturn true
    | .PV _ (.PVfunction _) =>
      memFail (MerrOther "called isWellAligned_ptrval on function pointer")
    | .PV _ (.PVconcrete _ addr) =>
      memReturn (addr % (alignofCtype ty).max 1 == 0)

/-- validForDeref_ptrval — impl_mem.ml:2086-2123 (§6.5.3.3 footnote 102).
    Null/function pointer → false.
    Prov_none → false.
    Prov_device → checks alignment.
    Prov_some → checks !is_dead && well-aligned. -/
def validForDerefPtrval (ty : ctype) (pv : PointerValue) : memM Bool :=
  ND fun st =>
    match pv with
    | .PV _ (.PVnull _) | .PV _ (.PVfunction _) =>
      (NDactive false, st)
    | .PV .Prov_none _ =>
      (NDactive false, st)
    | .PV .Prov_device _ =>
      -- Device pointer: only check alignment (no liveness tracking)
      match isWellAlignedPtrval ty pv with
      | ND f => f st
    | .PV (.Prov_some allocId) _ =>
      if st.deadAllocations.contains allocId then
        (NDactive false, st)
      else
        match isWellAlignedPtrval ty pv with
        | ND f => f st
    | .PV (.Prov_symbolic _) _ =>
      -- PNVI-ae-udi: concrete model shouldn't see this; fail loudly
      (NDkilled (Other (MerrOther "validForDerefPtrval: Prov_symbolic in concrete model")), st)

/-! ### Pointer casts -/

/-- wrapI: wrap `n` into range [min, max] per C's unsigned conversion. -/
private def wrapI (n : Int) (lo hi : Int) : Int :=
  let dlt := hi - lo + 1
  let r := n % dlt
  let r := if r < 0 then r + dlt else r
  if r <= hi then r else r - dlt

/-- ptrfromint — impl_mem.ml:2126-2173.
    Wrap to pointer range, preserve provenance. n==0 → null pointer.
    (Skips the PNVI allocation-finding — concrete model uses PVI.) -/
def ptrfromint (_ : CerbLocation.Loc) (_ : integerType) (refTy : ctype)
    (iv : IntegerValue) : memM PointerValue :=
  match iv with
  | .IV prov nRaw =>
    -- Wrap to [0, 2^(8*ptrSize) - 1]
    let hi : Int := (2 : Int) ^ (targetPtrSize * 8) - 1
    let n := wrapI nRaw 0 hi
    if n == 0 then memReturn (.PV .Prov_none (.PVnull refTy))
    else memReturn (.PV prov (.PVconcrete none n))

/-- intfromptr — impl_mem.ml:2439-2461.
    For concrete pointer: validate address fits in target integer type,
    fail with MerrIntFromPtr on overflow. -/
def intfromptr (loc : CerbLocation.Loc) (_ : ctype) (ity : integerType)
    (pv : PointerValue) : memM IntegerValue :=
  match pv with
  | .PV prov (.PVnull _) => memReturn (.IV prov 0)
  | .PV prov (.PVfunction (Symbol _ n _)) => memReturn (.IV prov n)
  | .PV prov (.PVconcrete _ addr) =>
    let (.IV _ ityMin) := minIval ity
    let (.IV _ ityMax) := maxIval ity
    if addr < ityMin || ityMax < addr then
      memFail (MerrIntFromPtr)
    else
      memReturn (.IV prov addr)

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
      -- fail mapping (impl_mem.ml:540-546) — these surface as UB179a/b
      if !isDynamic then
        (NDkilled (failReason (MerrUndefinedFree Free_non_matching) loc), st)
      else if isDead then
        (NDkilled (failReason (MerrUndefinedFree Free_dead_allocation) loc), st)
      else match st.allocations.get? allocId with
        | none => (NDkilled (Other (MerrOther "realloc: allocation missing")), st)
        | some alloc =>
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
                  allocations := st2.allocations.erase allocId }
                (NDactive newPtr, st3)
              | _ => (NDactive newPtr, st1)
            | other => (other, st1)
  | _ => memFail (MerrOther "realloc: invalid pointer")

/-! ### Prefix operations -/

def updatePrefix (_ : prefix0 × MemValue) : memM Unit := memReturn ()
def prefixOfPointer (_ : PointerValue) : memM (Option String) := memReturn none

/-! ### Varargs

Mirrors impl_mem.ml:2698-2764 (va_start/va_copy/va_arg/va_end/va_list) on
the assoc-list `varargs` / `nextVarargsId` MemState fields (the faithful
mirror of OCaml's `varargs: (int * (ctype * pointer_value) list) IntMap.t`
+ `next_varargs_id`, impl_mem.ml:490-491).

PROTOTYPE PROVENANCE: the case structure follows the prototype's port
(cerberus-lean-prototype/lean/CerbLean/Semantics/Step.lean:1441-1513, which
carries the same impl_mem cites). Divergences from the prototype, resolved
OCaml-ward:
  * failures are `MerrWIP` mem_errors with OCaml's exact strings —
    including the "not initiliased" (sic) spelling — via the shared
    Concrete.fail path (impl_mem.ml:540-546 → failReason); the prototype
    threw its own `typeError` strings.
  * the map stays the MemState assoc list (keyed lookup only, iteration
    never observed); the prototype used Std.HashMap in its own state.
Like OCaml (impl_mem.ml:2730 `(* TODO: check type is compatible *)`) and
the prototype alike, va_arg does NOT check the requested ctype against the
stored one — adding a check would diverge from the oracle.

The `IntMap.add`-on-existing-key updates (va_arg's index bump) are
replace-in-place on the assoc list; fresh-id inserts (va_start/va_copy)
are conses. -/

/-- IntMap.add on the varargs assoc list: replace any existing binding for
    `id`, else cons. -/
private def varargsAdd (id : Int) (v : Int × List (ctype × PointerValue))
    (m : List (Int × (Int × List (ctype × PointerValue)))) :
    List (Int × (Int × List (ctype × PointerValue))) :=
  if m.any (fun e => e.1 == id) then
    m.map (fun e => if e.1 == id then (id, v) else e)
  else
    (id, v) :: m

/-- va_start — impl_mem.ml:2698-2704: fresh id bound to (index 0, args),
    next_varargs_id bumped, returns `IV (Prov_none, id)`. -/
def vaStart (args : List (ctype × PointerValue)) : memM IntegerValue :=
  ND fun st =>
    let id := st.nextVarargsId
    (NDactive (.IV .Prov_none id),
     { st with varargs := varargsAdd id (0, args) st.varargs
               nextVarargsId := st.nextVarargsId + 1 })

/-- va_copy — impl_mem.ml:2706-2721: duplicate the (index, args) entry
    under a fresh id (the copy's index advances independently). Only a
    `Prov_none` integer is a valid va_list value. -/
def vaCopy (va : IntegerValue) : memM IntegerValue :=
  match va with
  | .IV .Prov_none id =>
    ND fun st =>
      match st.varargs.find? (fun e => e.1 == id) with
      | some (_, entry) =>
        let id' := st.nextVarargsId
        (NDactive (.IV .Prov_none id'),
         { st with varargs := varargsAdd id' entry st.varargs
                   nextVarargsId := st.nextVarargsId + 1 })
      | none => (NDkilled (failReason (MerrWIP "va_copy: not initiliased")), st)
  | _ => memFail (MerrWIP "va_copy: invalid va_list")

/-- va_arg — impl_mem.ml:2723-2741: read the pointer at the current index
    and ADVANCE the index (IntMap.add on the existing id). No ctype
    compatibility check, mirroring OCaml's TODO at :2730. -/
def vaArg (va : IntegerValue) (_ : ctype) : memM PointerValue :=
  match va with
  | .IV .Prov_none id =>
    ND fun st =>
      match st.varargs.find? (fun e => e.1 == id) with
      | some (_, (i, args)) =>
        match args[i.toNat]? with
        | some (_, ptr) =>
          (NDactive ptr,
           { st with varargs := varargsAdd id (i + 1, args) st.varargs })
        | none =>
          (NDkilled (failReason (MerrWIP "va_arg: invalid number of arguments")), st)
      | none => (NDkilled (failReason (MerrWIP "va_arg: not initiliased")), st)
  | _ => memFail (MerrWIP "va_arg: invalid va_list")

/-- va_end — impl_mem.ml:2743-2754: IntMap.remove of an initialised id. -/
def vaEnd (va : IntegerValue) : memM Unit :=
  match va with
  | .IV .Prov_none id =>
    ND fun st =>
      if st.varargs.any (fun e => e.1 == id) then
        (NDactive (), { st with varargs := st.varargs.filter (fun e => e.1 != id) })
      else
        (NDkilled (failReason (MerrWIP "va_end: not initiliased")), st)
  | _ => memFail (MerrWIP "va_end: invalid va_list")

/-- va_list — impl_mem.ml:2756-2764: retrieve the argument list for an id
    (the variadic-call consumer, formatted.lem:799 vsnprintf). OCaml
    `assert (n = 0)` ("not sure what happens with n <> 0"): the assert is
    an oracle-side hard crash on a branch unreachable from generated code
    (va_list is only applied to a fresh va_start id) — mirrored as a
    MerrOther kill rather than a panic (same observable on the reachable
    surface: none). -/
def vaList (vaIdx : Int) : memM (List (ctype × PointerValue)) :=
  ND fun st =>
    match st.varargs.find? (fun e => e.1 == vaIdx) with
    | some (_, (n, args)) =>
      if n == 0 then (NDactive args, st)
      else (NDkilled (Other (MerrOther "va_list: index <> 0 (OCaml assert, impl_mem.ml:2760)")), st)
    | none => (NDkilled (failReason (MerrWIP "va_list")), st)

/-! ### Misc -/

def copyAllocId (_ : IntegerValue) (pv : PointerValue) : memM PointerValue := memReturn pv
def callIntrinsic (_ : CerbLocation.Loc) (_ : String) (_ : List MemValue) : memM (Option MemValue) := memReturn none

/-- Fuel-exhaustion sentinel for the fuel-threaded `Core_aux.zeros_aux`
    (arc-1): reached only past the default fuel's type-nesting depth, i.e.
    never for well-formed programs — same failure class as the existing
    failwith invariant branches. -/
/- Routed through the opaque fuelExhaustedWith (arc-3 audit F9): a plain
   `panic!` body is kernel-visible, making the fuel-exhausted branch
   provably equal to `default` — semantically false. Opaque core ⇒ no
   equations; still panics at runtime. -/
def zerosFuelExhausted (_ : Unit) : MemValue :=
  fuelExhaustedWith "Core_aux.zeros_aux: fuel exhausted" (MemValue.MVarray [])

end CerbMem
