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

/-! ## The enum registry (sem:S9, arc-14 re-mark basket)

Mirrors DefaultImpl's mutable `registered_enums` (ocaml_implementation.ml:
124-150): `register_enum` decides the enum's compatible type — GCC's
rule, `Signed Int_` iff any enumerator is negative, else `Unsigned Int_`
(:130-135) — and records it; `typeof_enum` looks it up and FAILS on an
unregistered tag (:144-150). Registration flows through the SHARED lem
model (cabs_to_ail_effect.lem:1759 calls Implementation.register_enum
during desugar), so the Lean pipeline registers exactly where the oracle
does. (Previously typeof_enum was a stub returning `Signed Int_` for
every enum — silently wrong signedness for all-nonnegative enums; lane
probe tests/immaculate/nolibc/s9-enum-signedness.c.)

EFFECT-ERASURE SEAM (the invariant page,
docs/2026-08-22_arc14-effect-erasure-invariant.md): both entry points
are pure-typed at the lem interface (the OCaml side mutates a ref inside
pure-typed functions the same way). The cell uses Lean's `initialize`
idiom (the page's sanctioned pattern for a WRITTEN cell without a native
global) + the standard armour; per the invariant, no proof may relate
these applications across registrations and no theorem statement may
mention them — registration and every lookup happen within one desugar
run's ambient state. Keys compare by digest+num (Symbol.symbol_compare
parity, ocaml_implementation.ml:137,145). -/

initialize enumRegistryRef : IO.Ref (List (sym × integerType)) ← IO.mkRef []

private def symKeyEq : sym → sym → Bool
  | Symbol d1 n1 _, Symbol d2 n2 _ =>
    CerberusFresh.digest_compare d1 d2 == 0 && n1 == n2

@[never_extract, noinline]
private unsafe def typeof_enum_impl (tag_sym : sym) : integerType :=
  unsafeBaseIO do
    let regs ← enumRegistryRef.get
    match regs.find? (fun (z, _) => symKeyEq z tag_sym) with
    | some (_, ity) => pure ity
    | none =>
      -- ocaml_implementation.ml:146-149 failwith, mirrored loud
      pure (panic! "Ocaml_implementation.typeof_enum: tag was not registered (ocaml_implementation.ml:146-149)")

/-- typeof_enum — ocaml_implementation.ml:144-150 (registry lookup;
    unregistered tag panics, mirroring upstream's failwith). -/
@[implemented_by typeof_enum_impl]
opaque typeof_enum : sym → integerType
attribute [never_extract] typeof_enum

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
    Corresponds to: DefaultImpl.sizeof_ity in ocaml_implementation.ml.
    The Enum arm ROUTES through typeof_enum (sem:S9 routing fix — was a
    literal `some 4` that would silently stop tracking the registry;
    the registry only ever returns Signed/Unsigned Int_, so the VALUE is
    unchanged, but the route now follows upstream's). Non-recursive by
    construction: typeof_enum never returns Enum0, so one re-dispatch on
    the base arms suffices. -/
def sizeof_ity : integerType → Option Nat
  | .Char0 => some 1
  | .Bool0 => some 1
  | .Signed ibty => some (sizeof_integerBaseType ibty)
  | .Unsigned ibty => some (sizeof_integerBaseType ibty)
  | .Enum0 tag_sym =>
    (match typeof_enum tag_sym with
     | .Signed ibty | .Unsigned ibty => some (sizeof_integerBaseType ibty)
     | _ => panic! "CerberusImpl.sizeof_ity: typeof_enum returned a non-Int type (unreachable)")
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
    -- arc-6 S3: Fmap is no longer a raw assoc list; scan the enumerated
    -- spine with the SAME BEq predicate as before (bit-identical result).
    (fmapElements tagDefs).find? (fun (k, _) => k == tag) |>.map Prod.snd
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

The REAL registry (sem:S9; S4b F-3 header de-stale — the "all enums
treated as signed int" simplification this header once described is
GONE): register_enum below writes the ref-cell registry declared with
typeof_enum above, mirroring DefaultImpl exactly. -/

@[never_extract, noinline]
private unsafe def register_enum_impl (tag_sym : sym) (ns : List Int) : Bool :=
  unsafeBaseIO do
    -- GCC's rule — ocaml_implementation.ml:130-135
    let ity : integerType := if ns.any (· < 0) then .Signed .Int_ else .Unsigned .Int_
    let regs ← enumRegistryRef.get
    if regs.any (fun (z, _) => symKeyEq z tag_sym) then
      pure false                                        -- :136-138 (duplicate)
    else do
      enumRegistryRef.set ((tag_sym, ity) :: regs)      -- :139-141
      pure true

/-- register_enum — ocaml_implementation.ml:129-142 (the real registry;
    was a `true`-returning stub). Returns false on a duplicate tag,
    exactly as upstream (cabs_to_ail uses the bool for redefinition
    detection). -/
@[implemented_by register_enum_impl]
opaque register_enum : sym → List Int → Bool
attribute [never_extract] register_enum

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
