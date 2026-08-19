/-
  Hand-written Lean implementations for Cerberus implementation-defined behaviour.
  Corresponds to: ocaml_frontend/ocaml_implementation.ml (DefaultImpl module)

  These functions are referenced by `declare lean target_rep` in implementation.lem
  and work with the Lem-generated types from IntegerType.lean and Ctype.lean.

  ABI: LP64 (x86_64-apple-darwin), matching Cerberus DefaultImpl.
-/

import IntegerType
import Ctype

namespace CerberusImpl

/-! ## Target Configuration -/

/-- Maximum alignment in bytes (LP64).
    Corresponds to: DefaultImpl.max_alignment in ocaml_implementation.ml -/
def max_alignment : Nat := 8

/-! ## Integer Type Properties -/

/-- Get the integer type for an enum.
    Corresponds to: DefaultImpl.typeof_enum in ocaml_implementation.ml:144-150.
    OCaml looks the tag up in the mutable `registered_enums` registry
    (populated by register_enum: Signed Int_ if any negative enumerator,
    else Unsigned Int_) and fails if unregistered. The Lean registry is
    NOT ported yet (survey finding 18, S3c): this stub returns the
    all-negative-enumerators answer `Signed Int_` for every tag.
    Polymorphic in sym to avoid circular imports. -/
def typeof_enum {α : Type} (_ : α) : integerType := .Signed .Int_

/-- Whether an integer type is signed.
    Corresponds to: Common.is_signed_ity in ocaml_implementation.ml:79-107,
    instantiated with ~typeof_enum ~char_is_signed:true as DefaultImpl does
    (ocaml_implementation.ml:257). OCaml first resolves Enum through
    typeof_enum, then matches; we mirror that shape exactly (the Enum arm
    of the second match is `assert false` there — unreachable because
    typeof_enum never returns an Enum). -/
def is_signed_ity (ity : integerType) : Bool :=
  let ity' := match ity with
    | .Enum0 tag_sym => typeof_enum tag_sym
    | _ => ity
  match ity' with
  | .Char0 => true      -- char_is_signed = true for DefaultImpl
  | .Bool0 => false
  | .Signed _ => true
  | .Unsigned _ => false
  | .Enum0 _ => false   -- unreachable (OCaml: assert false); typeof_enum is total
  | .Size_t => false    -- STD §7.19#2
  | .Wchar_t => true
  | .Wint_t => true
  | .Ptrdiff_t => true  -- STD §7.19#2
  | .Ptraddr_t => false

/-- Size of an integer base type in bytes (LP64).
    Corresponds to: DefaultImpl.sizeof_ity in ocaml_implementation.ml -/
def sizeof_integerBaseType : integerBaseType → Nat
  | .Ichar => 1
  | .Short => 2
  | .Int_ => 4
  | .Long => 8       -- LP64: long is 8 bytes
  | .LongLong => 8
  | .IntN_t n => (n + 7) / 8
  | .Int_leastN_t n =>
    if n ≤ 8 then 1
    else if n ≤ 16 then 2
    else if n ≤ 32 then 4
    else 8
  | .Int_fastN_t n =>
    if n ≤ 8 then 1
    else if n ≤ 16 then 2
    else if n ≤ 32 then 4
    else 8
  | .Intmax_t => 8
  | .Intptr_t => 8   -- pointer-sized

/-- Size of an integer type in bytes.
    Corresponds to: DefaultImpl.sizeof_ity in ocaml_implementation.ml -/
def sizeof_ity : integerType → Option Nat
  | .Char0 => some 1
  | .Bool0 => some 1
  | .Signed ibty => some (sizeof_integerBaseType ibty)
  | .Unsigned ibty => some (sizeof_integerBaseType ibty)
  | .Enum0 _ => some 4  -- enums are int-sized
  | .Wchar_t => some 4  -- wchar_t is int-sized
  | .Wint_t => some 4   -- wint_t is int-sized
  | .Size_t => some 8   -- LP64: size_t is 8 bytes
  | .Ptrdiff_t => some 8
  | .Ptraddr_t => some 8

/-- Precision (number of value bits) of an integer type.
    Corresponds to: Common.precision_ity in ocaml_implementation.ml -/
def precision_ity (ity : integerType) : Option Nat :=
  match sizeof_ity ity with
  | some n =>
    if is_signed_ity ity then some (8 * n - 1) else some (8 * n)
  | none => none

/-- Size of a floating type in bytes.
    Corresponds to: DefaultImpl.sizeof_fty in ocaml_implementation.ml:206-212,
    which returns 8 for ALL three real floating types — including its
    literal `(* TODO:hack ==> 4 *)` on Float and `(* TODO:hack ==> 16 *)`
    on LongDouble (OCaml's float IS 64-bit, so every floating_value is
    represented in 8 bytes; the natural 4/16 sizes are explicitly hacked
    to 8 there). We mirror the BEHAVIOR, hack included, for byte-level
    parity with the OCaml concrete memory model. -/
def sizeof_fty : floatingType → Option Nat
  | .RealFloating .Float0 => some 8      -- OCaml: Some 8 (* TODO:hack ==> 4 *)
  | .RealFloating .Double => some 8
  | .RealFloating .LongDouble => some 8  -- OCaml: Some 8 (* TODO:hack ==> 16 *)

/-- Alignment of an integer type in bytes.
    Corresponds to: DefaultImpl.alignof_ity in ocaml_implementation.ml
    Note: alignment equals size for all standard types on x86_64. -/
def alignof_ity : integerType → Option Nat
  := sizeof_ity  -- alignment == size on x86_64

/-- Alignment of a floating type in bytes.
    Corresponds to: DefaultImpl.alignof_fty in ocaml_implementation.ml:247-253
    — 8 for all three real floating types, same TODO:hack comments as
    sizeof_fty (see above); behavior mirrored, hack included. -/
def alignof_fty : floatingType → Option Nat
  | .RealFloating .Float0 => some 8      -- OCaml: Some 8 (* TODO:hack ==> 4 *)
  | .RealFloating .Double => some 8
  | .RealFloating .LongDouble => some 8  -- OCaml: Some 8 (* TODO:hack ==> 16 *)

/-- Alignment of a full ctype, including struct/union via tag definitions.
    Corresponds to: Ocaml_implementation.alignof_proxy in ocaml_implementation.ml
    The tagDefs maps ail_identifier (= sym) to member lists. -/
partial def alignof_ty
    (tagDefs : Fmap sym (List (Option alignment × ctype)))
    (ty : ctype) : Option Nat :=
  let lookupTag (tag : sym) : Option (List (Option alignment × ctype)) :=
    tagDefs.find? (fun (k, _) => k == tag) |>.map Prod.snd
  let foldMembers (members : List (Option alignment × ctype)) : Option Nat :=
    members.foldl (fun acc_opt (align_opt, mty) =>
      let al_opt := match align_opt with
        | none => alignof_ty tagDefs mty
        | some (AlignInteger n) => some n.toNat
        | some (AlignType al_ty) => alignof_ty tagDefs al_ty
      match acc_opt, al_opt with
      | some acc, some al => some (max al acc)
      | _, _ => none
    ) (some 1)
  match ty with
  | Ctype _ Void0 => none
  | Ctype _ (Basic (Integer ity)) => alignof_ity ity
  | Ctype _ (Basic (Floating fty)) => alignof_fty fty
  | Ctype _ (Array0 elem_ty _) => alignof_ty tagDefs elem_ty
  | Ctype _ (Function _ _ _) => none
  | Ctype _ (FunctionNoParams _) => none
  | Ctype _ (Pointer _ _) => some 8  -- pointer alignment on LP64
  | Ctype _ (Atomic atom_ty) => alignof_ty tagDefs atom_ty
  | Ctype _ (Struct tag_sym) =>
    match lookupTag tag_sym with
    | some members => foldMembers members
    | none => none
  | Ctype _ (Union0 tag_sym) =>
    match lookupTag tag_sym with
    | some members => foldMembers members
    | none => none
  | Ctype _ Byte => some 1

/-! ## Enum Registration

In OCaml Cerberus, enum registration uses a mutable ref cell. For the Lean
port we use a simpler approach: all enums are treated as signed int.
This matches the common case and can be refined later.
-/

/-- Register an enum type. Returns true if all values fit in int.
    Corresponds to: DefaultImpl.register_enum in ocaml_implementation.ml
    Polymorphic in sym to avoid circular imports.
    (typeof_enum lives above is_signed_ity, which routes Enum through it.) -/
def register_enum {α : Type} (_ : α) (_ : List Int) : Bool := true

/-! ## Type Normalisation -/

/-- Normalise an integer type by resolving aliases.
    Corresponds to: Common.normalise_integerType_ in ocaml_implementation.ml
    Resolves Size_t, Ptrdiff_t, Wchar_t, etc. to their underlying types. -/
def normalise_integerType : integerType → integerType
  | .Enum0 tag_sym => typeof_enum tag_sym
  | .Wchar_t => .Signed .Int_          -- wchar_t → signed int
  | .Wint_t => .Signed .Int_           -- wint_t → signed int
  | .Size_t => .Unsigned .Long          -- size_t → unsigned long (LP64)
  | .Ptrdiff_t => .Signed .Long         -- ptrdiff_t → signed long (LP64)
  | .Ptraddr_t => .Unsigned .Long       -- ptraddr_t → unsigned long
  | ity => ity

end CerberusImpl
