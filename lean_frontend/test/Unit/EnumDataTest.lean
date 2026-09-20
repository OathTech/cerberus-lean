import CerberusImpl
import Implementation
import Lean.Elab.Command

/-! # EnumDataTest — the enum's compatible type is PROGRAM DATA the kernel can see

Program-data parameters E-A (2026-09-20; `docs/2026-09-20_program-data-parameters-EA-DA-record.md`,
design note §4's named checks — not new artefact surface). Before E-A the layout of an enum
type went through `CerberusImpl.typeof_enum`, an `IO.Ref` registry read behind
`implemented_by` (kernel-opaque: no theorem about an enum-typed object's size, alignment or
signedness was provable). Now the enum map is a value: the lem reader `enum_definitions`,
passed to every lifted def as `_lemReader_enum_definitions` (the first of the two readers in the
sorted order `enum_definitions`, `tagDefs`), and the lem val `normalise_integerType` is
the one consumer. These pins are the design note's checks, kernel-only (`rfl`/`decide`):

  * the lookup: `normalise_integerType e t (.Enum0 s) = .Unsigned .Int_` given the map entry;
  * the layout through the SHARED lem wrappers: `sizeof_ity e t (.Enum0 s) = some 4`,
    `alignof_ity … = some 4` — functions of program data, by `rfl`;
  * GCC's rule in lem: `enum_compatible_type [0, 1] = .Unsigned .Int_`, `[-1, 1] = .Signed .Int_`;
  * `register_enum s ns = true` — the Lean rep is the pure value (the OCaml keeps its registry);
  * the seed-value pin the S0.5 audit's N1 asks for: a DIFFERENT map gives a different answer
    (`Signed` vs `Unsigned`), so a positional mix-up of same-typed maps cannot type-check silently;
  * NEGATIVE controls (`#guard_msgs`): the retired names `CerberusImpl.typeof_enum`,
    `CerberusImpl.enumRegistryRef`, `CerberusImpl.register_enum_impl` no longer elaborate.

No proof method beyond `rfl`/`decide`/`#guard_msgs`; no option bumps. -/

namespace EnumDataTest

/-- A program's enum tag (any digest, any number). -/
def s : sym := Symbol "d" 7 SD_None
/-- The empty tag table (the run's `tagDefs` reader is not consulted by the enum path). -/
def t : Fmap sym (CerbLocation.Loc × tag_definition) := fmapEmpty
/-- `enum E { A, B }` — GCC's rule: no negative enumerator → `unsigned int`. -/
def eU : CerberusImpl.EnumDefs := Lem_Map.fromList [(s, .Unsigned .Int_)]
/-- `enum F { A = -1, B }` → `signed int`. -/
def eS : CerberusImpl.EnumDefs := Lem_Map.fromList [(s, .Signed .Int_)]

/-! ## The lookup and the layout are functions of program data -/

example : CerberusImpl.normalise_integerType eU t (.Enum0 s) = .Unsigned .Int_ := rfl
example : CerberusImpl.normalise_integerType eS t (.Enum0 s) = .Signed .Int_ := rfl
example : CerberusImpl.lookupEnum eU s = .Unsigned .Int_ := rfl
example : CerberusImpl.resolveEnum eU (.Enum0 s) = .Unsigned .Int_ := rfl
example : CerberusImpl.resolveEnum eU (.Signed .Long) = .Signed .Long := rfl

/-- The shared lem wrappers (generated `Implementation.*`, reader-lifted): `sizeof(enum E)`
    is `some 4` BY `rfl` given the map — the property the consumer names. -/
example : sizeof_ity eU t (.Enum0 s) = some 4 := rfl
example : alignof_ity eU t (.Enum0 s) = some 4 := rfl
example : is_signed_ity eU t (.Enum0 s) = false := rfl
example : is_signed_ity eS t (.Enum0 s) = true := rfl
example : precision_ity eU t (.Enum0 s) = some 32 := by decide
example : precision_ity eS t (.Enum0 s) = some 31 := by decide

/-! ## GCC's rule, in lem -/

example : enum_compatible_type [0, 1] = .Unsigned .Int_ := rfl
example : enum_compatible_type [-1, 1] = .Signed .Int_ := rfl
example : enum_compatible_type [] = .Unsigned .Int_ := rfl

/-! ## register_enum is the pure value on Lean -/

-- (the lem val is target_rep'd — generated code inlines the rep, so the rep IS the pin)
example : CerberusImpl.register_enum s [0, 1] = true := rfl
example : CerberusImpl.register_enum s [-1] = true := rfl

/-! ## The seed-value pin (S0.5 audit N1): the map's VALUE decides -/

example : is_signed_ity eU t (.Enum0 s) ≠ is_signed_ity eS t (.Enum0 s) := by decide

/-! ## Negative controls: the retired effect-erased names are gone -/

/-- error: Unknown identifier `CerberusImpl.typeof_enum` -/
#guard_msgs in
#check CerberusImpl.typeof_enum

/-- error: Unknown identifier `CerberusImpl.enumRegistryRef` -/
#guard_msgs in
#check CerberusImpl.enumRegistryRef

/-- error: Unknown identifier `CerberusImpl.register_enum_impl` -/
#guard_msgs in
#check CerberusImpl.register_enum_impl

/-! ## Axioms -/

theorem sizeof_enum_pin : sizeof_ity eU t (.Enum0 s) = some 4 := rfl
#print axioms sizeof_enum_pin

end EnumDataTest

def main : IO UInt32 := do
  IO.println "EnumDataTest: the enum's compatible type is program data — normalise/sizeof/alignof/is_signed/precision at a registered enum by rfl/decide given the map; GCC's rule in lem; register_enum = true; the retired registry names no longer elaborate — kernel-checked at compile time"
  return 0
