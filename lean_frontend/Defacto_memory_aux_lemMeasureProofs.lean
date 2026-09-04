/-
  Defacto_memory_aux_lemMeasureProofs — the hand-written proof of the
  `fuel_measure` obligation lem emits into Defacto_memory_aux_auxiliary.lean
  for `fake_mem_value_eq` (fuel-parameter arc C1 / D2 enablers, 2026-09-04;
  `declare {lean} fuel_measure val fake_mem_value_eq = `lemSize mval1`` in
  defacto_memory_aux.lem; the measure is the backend-derived structural
  size of `impl_mem_value`, a type of Defacto_memory_types — the
  cross-module case).

  THE OBLIGATION: `fake_mem_value_eq_lemFuel lemFuel mval1 mval2 =
  fake_mem_value_eq mval1 mval2` whenever `impl_mem_value.lemSize mval1 ≤
  lemFuel`. Shape: strong induction on the size; the one recursive arm is
  `MVarray`/`MVarray` — `List.all (lemListZip mvals1 mvals2) (uncurry (rec))`
  AS WRITTEN — bridged to `List.zip` by `LemLibTheorems.lemListZip_eq`, the
  child below its parent over the derived helper
  `impl_pointer_value.lemSize_aux3` (the list-of-`impl_mem_value` helper of
  the type's mutual block). The exhaustive `error` arm is a `failwithI`
  leaf (no fuel). Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: a proof about the Lean total worker; no OCaml text
  corresponds.
-/

import Defacto_memory_aux
import LemLibTheorems

set_option autoImplicit false

namespace Defacto_memory_aux_lemMeasureProofs

theorem impl_mem_value_child_lt (x : impl_mem_value) (xs : List impl_mem_value) (h : x ∈ xs) :
    impl_mem_value.lemSize x < impl_pointer_value.lemSize_aux3 xs := by
  induction xs with
  | nil => cases h
  | cons y ys ih =>
    cases h with
    | head => simp only [impl_pointer_value.lemSize_aux3]; omega
    | tail _ h' => have := ih h'; simp only [impl_pointer_value.lemSize_aux3]; omega

theorem all_congr {α : Type} (l : List α) (F G : α → Bool)
    (h : ∀ p ∈ l, F p = G p) : l.all F = l.all G := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.all_cons]
    rw [h x (List.mem_cons_self ..), ih (fun p hp => h p (List.mem_cons_of_mem _ hp))]

theorem impl_mem_value_lemSize_pos (m : impl_mem_value) : 1 ≤ impl_mem_value.lemSize m := by
  cases m <;> simp only [impl_mem_value.lemSize] <;> omega

theorem fake_mem_value_eq_stable_aux (k : Nat) : ∀ (m1 m2 : impl_mem_value) (f g : Nat),
    impl_mem_value.lemSize m1 ≤ k → impl_mem_value.lemSize m1 ≤ f → impl_mem_value.lemSize m1 ≤ g →
    fake_mem_value_eq_lemFuel f m1 m2 = fake_mem_value_eq_lemFuel g m1 m2 := by
  induction k with
  | zero => intro m1 _ _ _ hk; have := impl_mem_value_lemSize_pos m1; omega
  | succ k ih =>
    intro m1 m2 f g hk hf hg
    cases f with
    | zero => have := impl_mem_value_lemSize_pos m1; omega
    | succ f =>
      cases g with
      | zero => have := impl_mem_value_lemSize_pos m1; omega
      | succ g =>
        cases m1 <;> cases m2 <;> simp only [fake_mem_value_eq_lemFuel] <;> try rfl
        -- MVinteger / MVinteger: the worker's NESTED patterns
        -- (`MVinteger _ (IV _ (IVconcrete n))`) leave the matcher stuck on the
        -- inner values; expose their constructors and every arm is fuel-free
        · rename_i _ i1 _ i2
          rcases i1 with ⟨p1, iv1⟩
          rcases i2 with ⟨p2, iv2⟩
          cases iv1 <;> cases iv2 <;> rfl
        -- the one recursive arm: MVarray / MVarray
        simp only [impl_mem_value.lemSize] at hk hf hg
        rw [LemLibTheorems.lemListZip_eq]
        apply all_congr
        intro p hp
        obtain ⟨x, y⟩ := p
        have hmem := (List.of_mem_zip hp).1
        have := impl_mem_value_child_lt x _ hmem
        simp only [Lem_Function.uncurry]
        exact ih x y f g (by omega) (by omega) (by omega)

/-- THE OBLIGATION, exactly as Defacto_memory_aux_auxiliary.lean states and delegates it. -/
theorem fake_mem_value_eq_measure_sufficient (mval1 : impl_mem_value) (mval2 : impl_mem_value)
    (lemFuel : Nat) (lemMeasureLe : impl_mem_value.lemSize mval1 ≤ lemFuel) :
    fake_mem_value_eq_lemFuel lemFuel mval1 mval2 = fake_mem_value_eq mval1 mval2 :=
  fake_mem_value_eq_stable_aux (impl_mem_value.lemSize mval1) mval1 mval2 lemFuel
    (impl_mem_value.lemSize mval1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)


/-! ## C2: the bit-twiddling quartet (`nbits + 1`; nbits counts down under the
    Bool guard `nbits == 0`) — fuel-parameter arc C2, 2026-09-04. -/

theorem tmp_compl_aux_stable_aux (k : Nat) : ∀ (nbits : Nat) (n : Int) (f g : Nat),
    nbits + 1 ≤ k → nbits + 1 ≤ f → nbits + 1 ≤ g →
    tmp_compl_aux_lemFuel f nbits n = tmp_compl_aux_lemFuel g nbits n := by
  induction k with
  | zero => intro nbits n f g hk; omega
  | succ k ih =>
    intro nbits n f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [tmp_compl_aux_lemFuel]
        split
        · rfl
        · rename_i h
          have h' : nbits ≠ 0 := by intro hz; subst hz; exact absurd h (by decide)
          rw [ih (nbits - 1) _ f g (by omega) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as Defacto_memory_aux_auxiliary.lean states and delegates it. -/
theorem tmp_compl_aux_measure_sufficient (nbits : Nat) (n : Int) (lemFuel : Nat)
    (lemMeasureLe : nbits + 1 ≤ lemFuel) :
    tmp_compl_aux_lemFuel lemFuel nbits n = tmp_compl_aux nbits n :=
  tmp_compl_aux_stable_aux (nbits + 1) nbits n lemFuel (nbits + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-! ## C2: the bit-twiddling quartet (`nbits + 1`; nbits counts down under the
    Bool guard `nbits == 0`) — fuel-parameter arc C2, 2026-09-04. -/

theorem tmp_AND_aux_stable_aux (k : Nat) : ∀ (nbits : Nat) (n1 n2 : Int) (f g : Nat),
    nbits + 1 ≤ k → nbits + 1 ≤ f → nbits + 1 ≤ g →
    tmp_AND_aux_lemFuel f nbits n1 n2 = tmp_AND_aux_lemFuel g nbits n1 n2 := by
  induction k with
  | zero => intro nbits n1 n2 f g hk; omega
  | succ k ih =>
    intro nbits n1 n2 f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [tmp_AND_aux_lemFuel]
        split
        · rfl
        · rename_i h
          have h' : nbits ≠ 0 := by intro hz; subst hz; exact absurd h (by decide)
          rw [ih (nbits - 1) _ _ f g (by omega) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as Defacto_memory_aux_auxiliary.lean states and delegates it. -/
theorem tmp_AND_aux_measure_sufficient (nbits : Nat) (n1 n2 : Int) (lemFuel : Nat)
    (lemMeasureLe : nbits + 1 ≤ lemFuel) :
    tmp_AND_aux_lemFuel lemFuel nbits n1 n2 = tmp_AND_aux nbits n1 n2 :=
  tmp_AND_aux_stable_aux (nbits + 1) nbits n1 n2 lemFuel (nbits + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-! ## C2: the bit-twiddling quartet (`nbits + 1`; nbits counts down under the
    Bool guard `nbits == 0`) — fuel-parameter arc C2, 2026-09-04. -/

theorem tmp_OR_aux_stable_aux (k : Nat) : ∀ (nbits : Nat) (n1 n2 : Int) (f g : Nat),
    nbits + 1 ≤ k → nbits + 1 ≤ f → nbits + 1 ≤ g →
    tmp_OR_aux_lemFuel f nbits n1 n2 = tmp_OR_aux_lemFuel g nbits n1 n2 := by
  induction k with
  | zero => intro nbits n1 n2 f g hk; omega
  | succ k ih =>
    intro nbits n1 n2 f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [tmp_OR_aux_lemFuel]
        split
        · rfl
        · rename_i h
          have h' : nbits ≠ 0 := by intro hz; subst hz; exact absurd h (by decide)
          rw [ih (nbits - 1) _ _ f g (by omega) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as Defacto_memory_aux_auxiliary.lean states and delegates it. -/
theorem tmp_OR_aux_measure_sufficient (nbits : Nat) (n1 n2 : Int) (lemFuel : Nat)
    (lemMeasureLe : nbits + 1 ≤ lemFuel) :
    tmp_OR_aux_lemFuel lemFuel nbits n1 n2 = tmp_OR_aux nbits n1 n2 :=
  tmp_OR_aux_stable_aux (nbits + 1) nbits n1 n2 lemFuel (nbits + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

/-! ## C2: the bit-twiddling quartet (`nbits + 1`; nbits counts down under the
    Bool guard `nbits == 0`) — fuel-parameter arc C2, 2026-09-04. -/

theorem tmp_XOR_aux_stable_aux (k : Nat) : ∀ (nbits : Nat) (n1 n2 : Int) (f g : Nat),
    nbits + 1 ≤ k → nbits + 1 ≤ f → nbits + 1 ≤ g →
    tmp_XOR_aux_lemFuel f nbits n1 n2 = tmp_XOR_aux_lemFuel g nbits n1 n2 := by
  induction k with
  | zero => intro nbits n1 n2 f g hk; omega
  | succ k ih =>
    intro nbits n1 n2 f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [tmp_XOR_aux_lemFuel]
        split
        · rfl
        · rename_i h
          have h' : nbits ≠ 0 := by intro hz; subst hz; exact absurd h (by decide)
          rw [ih (nbits - 1) _ _ f g (by omega) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as Defacto_memory_aux_auxiliary.lean states and delegates it. -/
theorem tmp_XOR_aux_measure_sufficient (nbits : Nat) (n1 n2 : Int) (lemFuel : Nat)
    (lemMeasureLe : nbits + 1 ≤ lemFuel) :
    tmp_XOR_aux_lemFuel lemFuel nbits n1 n2 = tmp_XOR_aux nbits n1 n2 :=
  tmp_XOR_aux_stable_aux (nbits + 1) nbits n1 n2 lemFuel (nbits + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Defacto_memory_aux_lemMeasureProofs
