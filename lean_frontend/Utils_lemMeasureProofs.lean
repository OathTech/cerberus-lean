/-
  Utils_lemMeasureProofs — the hand-written proofs of the `fuel_measure`
  obligations lem emits into Utils_auxiliary.lean (fuel-parameter arc C2,
  2026-09-04; `declare {lean} fuel_measure val …` in frontend/model/utils.lem,
  Lean-only):

    mkListN_aux      measure `Int.toNat (n - i) + 1`     (i climbs to n)
    mkListFromTo_aux measure `Int.toNat (max2 + 1 - i) + 1`  (i climbs to max2 inclusive: the exact depth)
    replicate_list_  measure `n + 1`                     (n counts down to 0)

  THE OBLIGATION (per function, generated): the worker is fuel-STABLE at the
  measure — `f_lemFuel lemFuel … = f …` whenever `<measure> ≤ lemFuel`.
  Shape = the C1 template: a stability lemma by strong induction on the
  measure bound (`∀ f g ≥ μ x, W f x = W g x`), the one recursive arm under
  the counter guard (`intLtb`/`intLteb`/`natGtb`, LemLib: `decide` of the
  order), the guard's negation closing the base arm by `rfl`; the obligation
  is the instance `g := μ x`. Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Utils

set_option autoImplicit false

namespace Utils_lemMeasureProofs

theorem mkListN_aux_stable_aux (k : Nat) : ∀ (n i : Int) (acc : List Int) (f g : Nat),
    Int.toNat (n - i) + 1 ≤ k → Int.toNat (n - i) + 1 ≤ f → Int.toNat (n - i) + 1 ≤ g →
    mkListN_aux_lemFuel f n i acc = mkListN_aux_lemFuel g n i acc := by
  induction k with
  | zero => intro n i acc f g hk; omega
  | succ k ih =>
    intro n i acc f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [mkListN_aux_lemFuel, intLtb]
        split
        · rename_i h
          have h' := of_decide_eq_true h
          exact ih n (i + 1) (i :: acc) f g (by omega) (by omega) (by omega)
        · rfl

/-- THE OBLIGATION, exactly as Utils_auxiliary.lean states and delegates it. -/
theorem mkListN_aux_measure_sufficient (n : Int) (i : Int) (acc : List Int) (lemFuel : Nat)
    (lemMeasureLe : Int.toNat (n - i) + 1 ≤ lemFuel) :
    mkListN_aux_lemFuel lemFuel n i acc = mkListN_aux n i acc :=
  mkListN_aux_stable_aux (Int.toNat (n - i) + 1) n i acc lemFuel (Int.toNat (n - i) + 1)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem mkListFromTo_aux_stable_aux (k : Nat) : ∀ (i max2 : Int) (acc : List Int) (f g : Nat),
    Int.toNat (max2 + 1 - i) + 1 ≤ k → Int.toNat (max2 + 1 - i) + 1 ≤ f → Int.toNat (max2 + 1 - i) + 1 ≤ g →
    mkListFromTo_aux_lemFuel f i max2 acc = mkListFromTo_aux_lemFuel g i max2 acc := by
  induction k with
  | zero => intro i max2 acc f g hk; omega
  | succ k ih =>
    intro i max2 acc f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [mkListFromTo_aux_lemFuel, intLteb]
        split
        · rename_i h
          have h' := of_decide_eq_true h
          exact ih (i + 1) max2 (i :: acc) f g (by omega) (by omega) (by omega)
        · rfl

/-- THE OBLIGATION, exactly as Utils_auxiliary.lean states and delegates it. -/
theorem mkListFromTo_aux_measure_sufficient (i : Int) (max2 : Int) (acc : List Int) (lemFuel : Nat)
    (lemMeasureLe : Int.toNat (max2 + 1 - i) + 1 ≤ lemFuel) :
    mkListFromTo_aux_lemFuel lemFuel i max2 acc = mkListFromTo_aux i max2 acc :=
  mkListFromTo_aux_stable_aux (Int.toNat (max2 + 1 - i) + 1) i max2 acc lemFuel
    (Int.toNat (max2 + 1 - i) + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem replicate_list__stable_aux {a : Type} (k : Nat) : ∀ (x : a) (n : Nat) (acc : List a) (f g : Nat),
    n + 1 ≤ k → n + 1 ≤ f → n + 1 ≤ g →
    replicate_list__lemFuel f x n acc = replicate_list__lemFuel g x n acc := by
  induction k with
  | zero => intro x n acc f g hk; omega
  | succ k ih =>
    intro x n acc f g hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [replicate_list__lemFuel, natGtb]
        split
        · rename_i h
          have h' := of_decide_eq_true h
          exact ih x (n - 1) (x :: acc) f g (by omega) (by omega) (by omega)
        · rfl

/-- THE OBLIGATION, exactly as Utils_auxiliary.lean states and delegates it. -/
theorem replicate_list__measure_sufficient {a : Type} (x : a) (n : Nat) (acc : List a) (lemFuel : Nat)
    (lemMeasureLe : n + 1 ≤ lemFuel) :
    replicate_list__lemFuel lemFuel x n acc = replicate_list_ x n acc :=
  replicate_list__stable_aux (n + 1) x n acc lemFuel (n + 1) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Utils_lemMeasureProofs
