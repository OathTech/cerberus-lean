/-
  Defacto_memory_lemMeasureProofs — the hand-written proofs of the
  `fuel_measure` obligations lem emits into Defacto_memory_auxiliary.lean
  (fuel-parameter arc C2, 2026-09-04; frontend/model/defacto_memory.lem,
  Lean-only):

    has_concurRead             measure `lemSize ival_`                  (integer_value_base.lemSize)
    find_array_index           measure `size - i + 1`                   (i climbs to size; ND-typed, data-bounded)
    easy_update_mem_value_aux  measure `List.length sh + 1`             (the shift path is consumed per step)
    memcmp_load_aux            measure `Int.toNat (max_offset - offset) + 1` (offset climbs to max_offset)

  The two ND-typed rows whose workers pass the ambient on keep `[LemFuel]` on
  the statement (`easy_update_mem_value_aux` reaches the ambient
  `mkUnspec`/`simplify_integer_value_base`; `memcmp_load_aux` the ambient
  `impl_load`); their own counters are the measures. Shape = the C2 template;
  the recursive calls under `nd_bind` continuations are rewritten by `key`
  under the binder (the measure does not depend on the bound variable).
  Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Defacto_memory
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Defacto_memory_lemMeasureProofs

theorem has_concurRead_stable_aux (k : Nat) : ∀ (e : integer_value_base) (f g : Nat),
    integer_value_base.lemSize e ≤ k → integer_value_base.lemSize e ≤ f → integer_value_base.lemSize e ≤ g →
    has_concurRead_lemFuel f e = has_concurRead_lemFuel g e := by
  induction k with
  | zero => intro e f g hk _ _; have := ival_lemSize_pos e; omega
  | succ k ih =>
    intro e f g hk hf hg
    cases f with
    | zero => have := ival_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := ival_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (y : integer_value_base), integer_value_base.lemSize y < integer_value_base.lemSize e →
            has_concurRead_lemFuel f y = has_concurRead_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        cases e <;> simp only [has_concurRead_lemFuel]
        case IVop iop l =>
          apply lany_congr; intro iv hiv
          exact key iv (by have := ival_mem_lt_aux2 iv _ hiv; size_lt)
        case IVcomposite l =>
          apply lany_congr; intro iv hiv
          exact key iv (by have := ival_mem_lt_aux2 iv _ hiv; size_lt)
        case IVbitwise ity bw =>
          cases bw <;> simp (disch := size_lt) only [has_concurRead_lemFuel, key]

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem has_concurRead_measure_sufficient (ival_ : integer_value_base) (lemFuel : Nat)
    (lemMeasureLe : integer_value_base.lemSize ival_ ≤ lemFuel) :
    has_concurRead_lemFuel lemFuel ival_ = has_concurRead ival_ :=
  has_concurRead_stable_aux (integer_value_base.lemSize ival_) ival_ lemFuel (integer_value_base.lemSize ival_) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem find_array_index_stable_aux (k : Nat) : ∀ (size i : Nat) (ival_ : integer_value_base) (f g : Nat),
    size - i + 1 ≤ k → size - i + 1 ≤ f → size - i + 1 ≤ g →
    find_array_index_lemFuel f size i ival_ = find_array_index_lemFuel g size i ival_ := by
  induction k with
  | zero => intro size i ival_ f g hk; omega
  | succ k ih =>
    intro size i ival_ f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [find_array_index_lemFuel, natGteb]
        split
        · rfl
        · rename_i h
          have h' : ¬ (i ≥ size) := fun hle => h (decide_eq_true hle)
          rw [ih size (i + 1) ival_ f g (by omega) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as Defacto_memory_auxiliary.lean states and delegates it. -/
theorem find_array_index_measure_sufficient (size : Nat) (i : Nat) (ival_ : integer_value_base) (lemFuel : Nat)
    (lemMeasureLe : size - i + 1 ≤ lemFuel) :
    find_array_index_lemFuel lemFuel size i ival_ = find_array_index size i ival_ :=
  find_array_index_stable_aux (size - i + 1) size i ival_ lemFuel (size - i + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem easy_update_mem_value_aux_stable_aux [LemFuel] (k : Nat) :
    ∀ (td : Fmap sym (CerbLocation.Loc × tag_definition)) (loc1 : CerbLocation.Loc) (is_strong : Bool)
      (write_ty : ctype) (sh : List shift_path_element) (write_mval current_mval : impl_mem_value) (f g : Nat),
    List.length sh + 1 ≤ k → List.length sh + 1 ≤ f → List.length sh + 1 ≤ g →
    easy_update_mem_value_aux_lemFuel f td loc1 is_strong write_ty sh write_mval current_mval =
      easy_update_mem_value_aux_lemFuel g td loc1 is_strong write_ty sh write_mval current_mval := by
  induction k with
  | zero => intro td loc1 is_strong write_ty sh write_mval current_mval f g hk; omega
  | succ k ih =>
    intro td loc1 is_strong write_ty sh write_mval current_mval f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have key : ∀ (wty : ctype) (tl : List shift_path_element) (wmv cmv : impl_mem_value),
            List.length tl < List.length sh →
            easy_update_mem_value_aux_lemFuel f td loc1 is_strong wty tl wmv cmv =
              easy_update_mem_value_aux_lemFuel g td loc1 is_strong wty tl wmv cmv :=
          fun wty tl wmv cmv hy => ih td loc1 is_strong wty tl wmv cmv f g (by omega) (by omega) (by omega)
        rcases sh with _ | ⟨spe, sh'⟩
        · simp only [easy_update_mem_value_aux_lemFuel]
        · cases spe <;> cases current_mval <;> simp (disch := size_lt) only [easy_update_mem_value_aux_lemFuel, key]

/-- THE OBLIGATION, exactly as Defacto_memory_auxiliary.lean states and delegates it. -/
theorem easy_update_mem_value_aux_measure_sufficient [LemFuel] (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc1 : CerbLocation.Loc) (is_strong : Bool) (write_ty : ctype) (sh : List shift_path_element)
    (write_mval : impl_mem_value) (current_mval : impl_mem_value) (lemFuel : Nat)
    (lemMeasureLe : List.length sh + 1 ≤ lemFuel) :
    easy_update_mem_value_aux_lemFuel lemFuel _lemReader_tagDefs loc1 is_strong write_ty sh write_mval current_mval =
      easy_update_mem_value_aux _lemReader_tagDefs loc1 is_strong write_ty sh write_mval current_mval :=
  easy_update_mem_value_aux_stable_aux (List.length sh + 1) _lemReader_tagDefs loc1 is_strong write_ty sh write_mval current_mval
    lemFuel (List.length sh + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem memcmp_load_aux_stable_aux [LemFuel] (k : Nat) :
    ∀ (td : Fmap sym (CerbLocation.Loc × tag_definition)) (ptrval : impl_pointer_value) (offset max_offset : Int)
      (acc : List impl_mem_value) (f g : Nat),
    Int.toNat (max_offset - offset) + 1 ≤ k → Int.toNat (max_offset - offset) + 1 ≤ f →
    Int.toNat (max_offset - offset) + 1 ≤ g →
    memcmp_load_aux_lemFuel f td ptrval offset max_offset acc = memcmp_load_aux_lemFuel g td ptrval offset max_offset acc := by
  induction k with
  | zero => intro td ptrval offset max_offset acc f g hk; omega
  | succ k ih =>
    intro td ptrval offset max_offset acc f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [memcmp_load_aux_lemFuel, intGteb]
        split
        · rfl
        · rename_i h
          have h' : ¬ (offset ≥ max_offset) := fun hle => h (decide_eq_true hle)
          have key : ∀ (pv : impl_pointer_value) (acc' : List impl_mem_value),
              memcmp_load_aux_lemFuel f td pv (offset + 1) max_offset acc' =
                memcmp_load_aux_lemFuel g td pv (offset + 1) max_offset acc' :=
            fun pv acc' => ih td pv (offset + 1) max_offset acc' f g (by omega) (by omega) (by omega)
          simp only [key]

/-- THE OBLIGATION, exactly as Defacto_memory_auxiliary.lean states and delegates it. -/
theorem memcmp_load_aux_measure_sufficient [LemFuel] (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (ptrval : impl_pointer_value) (offset : Int) (max_offset : Int) (acc : List impl_mem_value) (lemFuel : Nat)
    (lemMeasureLe : Int.toNat (max_offset - offset) + 1 ≤ lemFuel) :
    memcmp_load_aux_lemFuel lemFuel _lemReader_tagDefs ptrval offset max_offset acc =
      memcmp_load_aux _lemReader_tagDefs ptrval offset max_offset acc :=
  memcmp_load_aux_stable_aux (Int.toNat (max_offset - offset) + 1) _lemReader_tagDefs ptrval offset max_offset acc
    lemFuel (Int.toNat (max_offset - offset) + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Defacto_memory_lemMeasureProofs
