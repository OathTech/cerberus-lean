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

/-- Whether an integer type is signed.
    Corresponds to: Common.is_signed_ity in ocaml_implementation.ml
    Note: char is signed on this target (char_is_signed = true). -/
def is_signed_ity : integerType → Bool
  | .Char0 => true  -- char_is_signed = true for DefaultImpl
  | .Bool0 => false
  | .Signed _ => true
  | .Unsigned _ => false
  | .Enum0 _ => true  -- enums are signed int by default
  | .Wchar_t => true  -- wchar_t aliases to int (signed)
  | .Wint_t => true   -- wint_t aliases to int (signed)
  | .Size_t => false   -- size_t is unsigned (§7.19#2)
  | .Ptrdiff_t => true -- ptrdiff_t is signed (§7.19#2)
  | .Ptraddr_t => false -- ptraddr_t is unsigned

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
    Corresponds to: DefaultImpl.sizeof_fty in ocaml_implementation.ml -/
def sizeof_fty : floatingType → Option Nat
  | .RealFloating .Float0 => some 4
  | .RealFloating .Double => some 8
  | .RealFloating .LongDouble => some 16

/-- Alignment of an integer type in bytes.
    Corresponds to: DefaultImpl.alignof_ity in ocaml_implementation.ml
    Note: alignment equals size for all standard types on x86_64. -/
def alignof_ity : integerType → Option Nat
  := sizeof_ity  -- alignment == size on x86_64

/-- Alignment of a floating type in bytes.
    Corresponds to: DefaultImpl.alignof_fty in ocaml_implementation.ml -/
def alignof_fty : floatingType → Option Nat
  | .RealFloating .Float0 => some 4
  | .RealFloating .Double => some 8
  | .RealFloating .LongDouble => some 16

/-! ## Enum Registration

In OCaml Cerberus, enum registration uses a mutable ref cell. For the Lean
port we use a simpler approach: all enums are treated as signed int.
This matches the common case and can be refined later.
-/

/-- Register an enum type. Returns true if all values fit in int.
    Corresponds to: DefaultImpl.register_enum in ocaml_implementation.ml
    Polymorphic in sym to avoid circular imports. -/
def register_enum {α : Type} (_ : α) (_ : List Int) : Bool := true

/-- Get the integer type for an enum.
    Corresponds to: DefaultImpl.typeof_enum in ocaml_implementation.ml
    Polymorphic in sym to avoid circular imports. -/
def typeof_enum {α : Type} (_ : α) : integerType := .Signed .Int_

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
