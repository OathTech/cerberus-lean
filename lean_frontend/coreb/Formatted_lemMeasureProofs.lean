/-
  Formatted_lemMeasureProofs — the sufficiency proof of the one `fuel_measure`
  obligation of formatted.lem (fuel-parameter arc C4, 2026-09-05), the first
  HYPOTHESIS-CARRYING obligation of the generated tree (lem-lean `assuming`,
  doc/lean-backend/2026-09-05_measure-hypothesis-record.md):

    showNonNegativeWithBasis_aux   measure `n + 1`   assuming `2 ≤ b`

  The recursion is on `n / b`; at `b = 1` it never descends (the oracle loops
  forever there, the unconditional obligation is FALSE — the lem record §3 has
  the kernel-checked counterexample for its twin `ndigits`), at `b = 0` the
  division is the opaque `lemDivByZero`. Under `2 ≤ b`: `lemNatDiv n b = n / b`
  and `n / b < n` for `0 < n`, so the measure `n + 1` is sufficient. The
  hypothesis is used exactly there — it is not decoration. Template: the lem
  suite's `ndigits` proof (stability above the measure by strong induction on
  the measured quantity generalizing the two fuels, the hypothesis threaded).
  Kernel-only tactics; no option bumps; no `sorry`.

  MIRROR-OCAML NOTE: proofs about the Lean total worker; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Formatted

set_option autoImplicit false

namespace Formatted_lemMeasureProofs

theorem lemNatDiv_of_pos (n b : Nat) (hb : 0 < b) : lemNatDiv n b = n / b := by
  unfold lemNatDiv
  split
  · rename_i h
    have : b = 0 := by simpa using h
    omega
  · rfl

theorem showNonNegativeWithBasis_aux_stable_aux (k : Nat) :
    ∀ (acc : List Char) (useUpper : Bool) (b n f g : Nat), 2 ≤ b → n ≤ k → n + 1 ≤ f → n + 1 ≤ g →
    showNonNegativeWithBasis_aux_lemFuel f acc useUpper b n = showNonNegativeWithBasis_aux_lemFuel g acc useUpper b n := by
  induction k with
  | zero =>
    intro acc useUpper b n f g hb hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        have hn : n = 0 := by omega
        subst hn
        simp only [showNonNegativeWithBasis_aux_lemFuel]
        rw [lemNatDiv_of_pos 0 b (by omega)]
        simp
  | succ k ih =>
    intro acc useUpper b n f g hb hk hf hg
    cases f with
    | zero => omega
    | succ f =>
      cases g with
      | zero => omega
      | succ g =>
        simp only [showNonNegativeWithBasis_aux_lemFuel]
        rw [lemNatDiv_of_pos n b (by omega)]
        by_cases hq : n / b = 0
        · simp [hq]
        · have hqf : (n / b == 0) = false := by
            cases h : n / b with
            | zero => exact absurd h hq
            | succ m => rfl
          simp only [hqf, Bool.false_eq_true, ↓reduceIte]
          have hn : 0 < n := by
            rcases Nat.eq_zero_or_pos n with h0 | h0
            · subst h0; simp at hq
            · exact h0
          have hlt : n / b < n := Nat.div_lt_self hn (by omega)
          rw [ih _ useUpper b (n / b) f g hb (by omega) (by omega) (by omega)]

/-- THE OBLIGATION's proof (the generated `Formatted_auxiliary` shell delegates
    here with the `lemHyp` binder in the `assuming` position). -/
theorem showNonNegativeWithBasis_aux_measure_sufficient (acc : List Char) (useUpper : Bool) (b : Nat) (n : Nat)
    (lemHyp : 2 ≤ b) (lemFuel : Nat) (lemMeasureLe : n + 1 ≤ lemFuel) :
    showNonNegativeWithBasis_aux_lemFuel lemFuel acc useUpper b n = showNonNegativeWithBasis_aux acc useUpper b n :=
  showNonNegativeWithBasis_aux_stable_aux n acc useUpper b n lemFuel (n + 1) lemHyp (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Formatted_lemMeasureProofs
