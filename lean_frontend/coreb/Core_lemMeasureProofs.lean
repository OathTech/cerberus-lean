/-
  Core_lemMeasureProofs — the hand-written proof of the `fuel_measure`
  obligation lem emits into Core_auxiliary.lean for `eq_core_base_type`
  (fuel-parameter arc C1 / D2 enablers, 2026-09-04; `declare {lean}
  fuel_measure val eq_core_base_type = `lemSize bTy1`` in core.lem).

  THE OBLIGATION (Core_auxiliary.lean, generated): the worker is fuel-STABLE
  at the measure — `eq_core_base_type_lemFuel lemFuel bTy1 bTy2 =
  eq_core_base_type bTy1 bTy2` whenever `core_base_type.lemSize bTy1 ≤
  lemFuel` (the wrapper starts the counter at exactly the measure). Proof
  shape = lem-lean tests/comprehensive/lean-test/Test_lem_size_lemMeasureProofs.lean
  (`tm_eq`): strong induction on the backend-derived structural size, a
  child's size strictly below its parent's over the derived list helper
  (`core_base_type.lemSize_aux1`), and the list traversal congruent in the
  per-element function (`listEqualBy`, LemLib). Kernel-only tactics; no
  option bumps; axiom cone probed by scripts/check_theorem_axioms.sh.

  MIRROR-OCAML NOTE: a proof about the Lean total worker; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Core
import LemLibTheorems

set_option autoImplicit false

namespace Core_lemMeasureProofs

/-- A tuple component's size is below the tuple's list-helper size. -/
theorem core_base_type_child_lt (x : core_base_type) (xs : List core_base_type) (h : x ∈ xs) :
    core_base_type.lemSize x < core_base_type.lemSize_aux1 xs := by
  induction xs with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [core_base_type.lemSize_aux1]; omega
    | tail _ h' => have := ih h'; simp only [core_base_type.lemSize_aux1]; omega

/-- `listEqualBy` (LemLib) is congruent in the element equality on the
    first list's members. -/
theorem listEqualBy_congr {α : Type} (F G : α → α → Bool) (l1 : List α)
    (h : ∀ x ∈ l1, ∀ y, F x y = G x y) : ∀ l2, listEqualBy F l1 l2 = listEqualBy G l1 l2 := by
  induction l1 with
  | nil => intro l2; cases l2 <;> rfl
  | cons x xs ih =>
    intro l2
    cases l2 with
    | nil => rfl
    | cons y ys =>
      simp only [listEqualBy]
      rw [h x (List.mem_cons_self ..), ih (fun z hz w => h z (List.mem_cons_of_mem _ hz) w) ys]

/-- Every constructor counts at least 1. -/
theorem core_base_type_lemSize_pos (b : core_base_type) : 1 ≤ core_base_type.lemSize b := by
  cases b <;> simp only [core_base_type.lemSize] <;> omega

theorem eq_core_base_type_stable_aux (k : Nat) : ∀ (b1 b2 : core_base_type) (f g : Nat),
    core_base_type.lemSize b1 ≤ k → core_base_type.lemSize b1 ≤ f → core_base_type.lemSize b1 ≤ g →
    eq_core_base_type_lemFuel f b1 b2 = eq_core_base_type_lemFuel g b1 b2 := by
  induction k with
  | zero => intro b1 _ _ _ hk; have := core_base_type_lemSize_pos b1; omega
  | succ k ih =>
    intro b1 b2 f g hk hf hg
    cases f with
    | zero => have := core_base_type_lemSize_pos b1; omega
    | succ f =>
      cases g with
      | zero => have := core_base_type_lemSize_pos b1; omega
      | succ g =>
        cases b1 <;> cases b2 <;> simp only [eq_core_base_type_lemFuel] <;> try rfl
        -- the two recursive arms: BTy_list (direct) and BTy_tuple (listEqualBy)
        all_goals simp only [core_base_type.lemSize] at hk hf hg
        · exact ih _ _ f g (by omega) (by omega) (by omega)
        · apply listEqualBy_congr
          intro x hx y
          have := core_base_type_child_lt x _ hx
          exact ih x y f g (by omega) (by omega) (by omega)

/-- THE OBLIGATION, exactly as Core_auxiliary.lean states and delegates it. -/
theorem eq_core_base_type_measure_sufficient (bTy1 : core_base_type) (bTy2 : core_base_type)
    (lemFuel : Nat) (lemMeasureLe : core_base_type.lemSize bTy1 ≤ lemFuel) :
    eq_core_base_type_lemFuel lemFuel bTy1 bTy2 = eq_core_base_type bTy1 bTy2 :=
  eq_core_base_type_stable_aux (core_base_type.lemSize bTy1) bTy1 bTy2 lemFuel
    (core_base_type.lemSize bTy1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Core_lemMeasureProofs
