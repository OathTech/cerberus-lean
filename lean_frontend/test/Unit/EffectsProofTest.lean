/-
  Arc-1 reasoning smoke test (the thing the unsafe-extern scaffold cannot do):
  theorems over generated code, possible only because
  - `core_object_type_of_ctype` is a TOTAL def (termination_argument declare,
    slice 2c) — a `partial def` has no equations and cannot be unfolded;
  - `get_membersDefs` is reader-lifted (slice 2b) — tagDefs is an honest
    parameter, so its behavior is a pure function of its inputs, with no
    hidden extern read to axiomatize away.

  These are compile-time proofs; main just reports success at runtime.
-/

import Core_aux
import Ctype_aux
import Ctype
import Symbol

set_option autoImplicit true

/-! ### Totality: symbolic theorems over `core_object_type_of_ctype` -/

/-- Pointers map to `OTy_pointer` — SYMBOLIC in the annotations, qualifiers,
    and referenced type. Provable by `rfl` only because the def is total. -/
example (a : List annot) (q : qualifiers) (t : ctype) :
    core_object_type_of_ctype (Ctype a (Pointer q t)) = some OTy_pointer := rfl

/-- Arrays lift the element's object type (symbolic in element pieces/size). -/
example (a a' : List annot) (q : qualifiers) (t : ctype) (n : Option Int) :
    core_object_type_of_ctype (Ctype a (Array0 (Ctype a' (Pointer q t)) n))
      = some (OTy_array OTy_pointer) := rfl

/-- Atomic is transparent for object typing. -/
example (a a' : List annot) (i : integerType) :
    core_object_type_of_ctype (Ctype a (Atomic (Ctype a' (Basic (Integer i)))))
      = some OTy_integer := rfl

/-! ### Reader lifting: `get_membersDefs` is a function of its tagDefs input -/

/-- With an explicitly passed singleton tagDefs map (Fmap is an association
    list), the lookup returns the stored definition. No extern, no axiom:
    the reader parameter IS the state. (Concrete instance — evaluation; the
    symbolic lookup lemmas belong to the Fmap library, a later arc.) -/
example :
    get_membersDefs
      [(Symbol "" 0 SD_None, (CerbLocation.unknown, UnionDef []))]
      (Symbol "" 0 SD_None)
    = UnionDef [] := rfl

/-! ### Fuel threading: `zeros_aux` is total with explicit fuel -/

/-- The wrapper is definitionally the worker at the default fuel. -/
example : @zeros_aux a = @zeros_aux_lemFuel a lemDefaultFuel := rfl

/-- At any nonzero fuel, the integer case computes — SYMBOLIC in the fuel,
    the tagDefs map, the annotations, and the integer type. Impossible over
    the former `partial def` (no equations). -/
example (f : Nat) (td : Fmap sym (a × tag_definition)) (an : List annot)
    (ity : integerType) :
    zeros_aux_lemFuel (Nat.succ f) td (Ctype an (Basic (Integer ity)))
      = CerbMem.integerValueMval ity (CerbMem.integerIval 0) := rfl

def main : IO UInt32 := do
  IO.println "effects-proof-test: all theorems checked at compile time"
  IO.println "  total core_object_type_of_ctype: 3 symbolic rfl theorems"
  IO.println "  reader-lifted get_membersDefs: 1 concrete lookup theorem"
  IO.println "  fuel-threaded zeros_aux: wrapper defeq + symbolic integer case"
  return 0
