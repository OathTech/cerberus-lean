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
import Core_run

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

/-- With an explicitly passed singleton tagDefs map (arc-6 S3: built with
    `fmapAddBy`, keyed by `symbol_compare` like every generated sym map),
    the lookup returns the stored definition. No extern, no axiom: the
    reader parameter IS the state. (Concrete instance — evaluation; the
    symbolic lookup lemmas live in lem-lean's LemLibTest.) -/
example :
    get_membersDefs
      (fmapAddBy symbol_compare (Symbol "" 0 SD_None)
        (CerbLocation.unknown, UnionDef []) fmapEmpty)
      (Symbol "" 0 SD_None)
    = UnionDef [] := rfl

/-! ### Fuel threading: `zeros_aux` is total with explicit fuel -/

/-- The wrapper at ANY instance fuel is definitionally the worker started
    there (fuel-parameter arc: `∀ n, @f ⟨n⟩ = f_lemFuel n`; no default
    constant exists). -/
example (n : Nat) : @zeros_aux a ⟨n⟩ = @zeros_aux_lemFuel a n := rfl

/-- At any nonzero fuel, the integer case computes — SYMBOLIC in the fuel,
    the tagDefs map, the annotations, and the integer type. Impossible over
    the former `partial def` (no equations). -/
example (f : Nat) (td : Fmap sym (a × tag_definition)) (an : List annot)
    (ity : integerType) :
    zeros_aux_lemFuel (Nat.succ f) td (Ctype an (Basic (Integer ity)))
      = CerbMem.integerValueMval ity (CerbMem.integerIval 0) := rfl

/-! ### Threaded symbol supply (arc-2 S1/S2): fresh_symbol' is a pure
    function of the run state — the theorems the ambient counter could
    never support. Kernel-only proofs, symbolic in the whole state. -/

private def symId : sym → Nat | .Symbol _ n _ => n

/-- The drawn symbol's id IS the supply. -/
example (s : core_run_state) : symId (fresh_symbol' s).1 = s.sym_supply := rfl

/-- Drawing advances the supply by exactly one. -/
example (s : core_run_state) :
    ((fresh_symbol' s).2).sym_supply = s.sym_supply + 1 := rfl

/-- Two successive draws are distinct — the uniqueness fact the opsem
    needs, now PROVABLE because the supply is threaded state. -/
example (s : core_run_state) :
    (fresh_symbol' s).1 ≠ (fresh_symbol' (fresh_symbol' s).2).1 := fun h =>
  Nat.succ_ne_self s.sym_supply (congrArg symId h).symm

def main : IO UInt32 := do
  IO.println "effects-proof-test: all theorems checked at compile time"
  IO.println "  total core_object_type_of_ctype: 3 symbolic rfl theorems"
  IO.println "  reader-lifted get_membersDefs: 1 concrete lookup theorem"
  IO.println "  fuel-threaded zeros_aux: wrapper fuel-parametric (∀ n) + symbolic integer case"
  IO.println "  threaded sym_supply: id/advance/distinctness, symbolic in the state"
  return 0
