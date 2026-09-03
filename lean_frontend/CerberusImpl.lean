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

/-! ## Type normalisation — the alias table and `normalise_integerType_`

    DefaultImpl's `type_alias_map` (ocaml_implementation.ml:154-171): the
    three N-families alias through ONE function `n_t_aliases` (8 → Ichar,
    16 → Short, 32 → Int_, 64 → Long, `_ → None`); `Intmax_t`/`Intptr_t` →
    Long; `wchar_t`/`wint_t` → Signed Int_; `size_t` → Unsigned Long;
    `ptrdiff_t` → Signed Long. `Common.normalise_integerType_` (:37-66)
    applies `Option.get` to the N-family lookups (:39-44), so a width
    outside {8, 16, 32, 64} — `__cerbty_int128_t`, builtins.lem:19/53 —
    is an uncaught `Invalid_argument "option is None"` on the oracle,
    mirrored as a fail-stop (zero-discrepancy Z2-I-03, ruling Q4).
    Zero-discrepancy Z2-I-01: the previous `normalise_integerType` had NO
    `Signed/Unsigned (IntN_t | Int_leastN_t | Int_fastN_t | Intmax_t |
    Intptr_t)` aliasing, so ailTypesAux.lem:302-303's `(Signed (IntN_t _),
    _) -> fail ()` arms — "inaccessible because of the normalisation" on
    the oracle — were reachable on Lean through the DIRECT `__cerbty_intN_t`
    spellings (the shared <stdint.h> typedefs int32_t as plain `signed
    int`, so ordinary C never produced IntN_t): pin
    tests/immaculate/nolibc/zd-z2i01-cerbty-int32-uac.c. Z2-I-02: the
    previous `.Ptraddr_t => .Unsigned .Long` arm computed where the
    OCaml's `| ity -> ity` (:65-66) keeps Ptraddr_t (and the shared model
    then errors "WIP … Ptraddr_t") — mirrored. -/

/-- `n_t_aliases` — ocaml_implementation.ml:155-160. -/
def n_t_aliases : Nat → Option integerBaseType
  | 8 => some .Ichar
  | 16 => some .Short
  | 32 => some .Int_
  | 64 => some .Long
  | _ => none

/-- `aux_ibty` of `Common.normalise_integerType_` — ocaml_implementation.ml:38-50,
    with `Option.get` (:40/:42/:44) mirrored as a fail-stop. -/
def aux_ibty : integerBaseType → integerBaseType
  | .IntN_t n | .Int_leastN_t n | .Int_fastN_t n =>
    match n_t_aliases n with
    | some ibty => ibty
    | none => panic! s!"Option.get: type_alias_map has no alias for an N-family width of {n} (ocaml_implementation.ml:39-44, :155-160 — Invalid_argument on the oracle)"
  | .Intmax_t => .Long     -- :45-46, :162
  | .Intptr_t => .Long     -- :47-48, :163
  | ibty => ibty           -- :49-50

/-- Normalise an integer type by resolving aliases.
    Corresponds to: Common.normalise_integerType_ in ocaml_implementation.ml:37-66
    instantiated with DefaultImpl's type_alias_map (:154-171) and typeof_enum. -/
def normalise_integerType : integerType → integerType
  | .Signed ibty => .Signed (aux_ibty ibty)      -- :52-53
  | .Unsigned ibty => .Unsigned (aux_ibty ibty)  -- :54-55
  | .Enum0 tag_sym => typeof_enum tag_sym        -- :56-57
  | .Wchar_t => .Signed .Int_                    -- :58-59, :164 (TODO: check — upstream's own note)
  | .Wint_t => .Signed .Int_                     -- :60-61, :165
  | .Size_t => .Unsigned .Long                   -- :62-63, :166
  | .Ptrdiff_t => .Signed .Long                  -- :64-65, :167
  | ity => ity                                   -- :65-66 (Char, Bool, Ptraddr_t)

/-- Size of an integer type in bytes.
    Corresponds to: DefaultImpl.sizeof_ity in ocaml_implementation.ml:172-201,
    arm for arm: the type is normalised FIRST (:173), so the N-families,
    Intmax_t/Intptr_t, Enum, wchar_t/wint_t/size_t/ptrdiff_t never reach
    the match — their arms are `assert false` (:188-193, :195-200) and are
    mirrored as fail-stops (unreachable after a total normalisation).
    Zero-discrepancy Z2-I-01/03: the previous per-width arithmetic
    (`(n+7)/8`, nested `if`s) computed a size for EVERY width where the
    oracle aliases four widths and crashes on the rest. -/
def sizeof_ity (ity : integerType) : Option Nat :=
  match normalise_integerType ity with
  | .Char0 | .Bool0 => some 1                                            -- :174-176
  | .Signed ibty | .Unsigned ibty =>                                     -- :177-193
    some (match ibty with
      | .Ichar => 1
      | .Short => 2
      | .Int_ => 4
      | .Long | .LongLong => 8
      | .IntN_t _ | .Int_leastN_t _ | .Int_fastN_t _ | .Intmax_t | .Intptr_t =>
        panic! "assert false: DefaultImpl.sizeof_ity reached an un-normalised base type (ocaml_implementation.ml:188-193)")
  | .Enum0 _ | .Wchar_t | .Wint_t | .Size_t | .Ptrdiff_t =>
    panic! "assert false: DefaultImpl.sizeof_ity reached an un-normalised type (ocaml_implementation.ml:195-200)"
  | .Ptraddr_t => some 8                                                 -- :201

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
    Corresponds to: DefaultImpl.alignof_ity in ocaml_implementation.ml:214-243
    — textually the same table as sizeof_ity (:172-201), normalisation
    first, `assert false` on the un-normalised arms; hence `= sizeof_ity`. -/
def alignof_ity : integerType → Option Nat
  := sizeof_ity

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

/-! ## alignof_ty fail paths — DECLARED (zero-discrepancy Z2-I-04)

    `alignof_ty` above answers `none` for `void`, function types and an
    unknown struct/union tag where `Ocaml_implementation.alignof_proxy`
    (ocaml_implementation.ml:446-447, :464-466 `assert false`; :491/:509
    `Pmap.find` → `Not_found`) crashes. Reachability: Ail typing rejects
    `sizeof`/`alignof`/`_Alignas` of void, function and incomplete types
    before elaboration (the shared front end), and every complete struct/
    union tag is in the tag map it was elaborated with; the `none` is
    consumed by the layout family's own panics (CerbMem.alignofCtype
    "requires a complete implementation alignof …"). Declared, not
    mirrored: a crash-for-crash change on an unreachable input. -/

end CerberusImpl
