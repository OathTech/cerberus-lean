/-
  Ctype_lemMeasureProofs — the hand-written proof of the `fuel_measure`
  obligation lem emits into Ctype_auxiliary.lean for `ctypeEqual`
  (fuel-parameter arc C1 / D2 enablers, 2026-09-04; `declare {lean}
  fuel_measure val ctypeEqual = `lemSize c`` in ctype.lem — the SAME-MODULE
  case: the measure is the backend-derived structural size `ctype.lemSize`
  emitted beside the type, lem-lean TODO row 15).

  THE OBLIGATION (Ctype_auxiliary.lean, generated): the worker is fuel-STABLE
  at the measure — `ctypeEqual_lemFuel lemFuel c c0 = ctypeEqual c c0`
  whenever `ctype.lemSize c ≤ lemFuel`. Shape = lem-lean
  tests/comprehensive/lean-test/Test_lem_size_lemMeasureProofs.lean (`tm_eq`):
  strong induction on the size; the recursive arms are `Array0`, `Atomic`,
  `FunctionNoParams` (direct on the child) and `Function` (the child AND the
  parameter list, `List.all (lemListZip params1 params2) (uncurry
  paramsEqual)` AS WRITTEN — bridged to `List.zip` by
  `LemLibTheorems.lemListZip_eq`, each parameter's type below the parent
  over the derived list helper `ctype_.lemSize_aux1`). The tuple patterns
  `Function (qs, ty) …` are destructured before the matcher is reduced.
  Kernel-only tactics; no option bumps; axiom cone probed by
  scripts/check_theorem_axioms.sh.

  MIRROR-OCAML NOTE: a proof about the Lean total worker; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Ctype
import LemLibTheorems

set_option autoImplicit false

namespace Ctype_lemMeasureProofs

/-- A parameter's type is below the parameter list's helper size. -/
theorem ctype_param_lt (t : ctype) (q : qualifiers) (b : Bool)
    (ps : List (qualifiers × ctype × Bool)) (h : (q, t, b) ∈ ps) :
    ctype.lemSize t < ctype_.lemSize_aux1 ps := by
  induction ps with
  | nil => cases h
  | cons x xs ih =>
    obtain ⟨q', t', b'⟩ := x
    cases h with
    | head => simp only [ctype_.lemSize_aux1]; omega
    | tail _ h' => have := ih h'; simp only [ctype_.lemSize_aux1]; omega

theorem all_congr {α : Type} (l : List α) (F G : α → Bool)
    (h : ∀ p ∈ l, F p = G p) : l.all F = l.all G := by
  induction l with
  | nil => rfl
  | cons x xs ih =>
    simp only [List.all_cons]
    rw [h x (List.mem_cons_self ..), ih (fun p hp => h p (List.mem_cons_of_mem _ hp))]

theorem ctype_lemSize_pos (c : ctype) : 1 ≤ ctype.lemSize c := by
  cases c with
  | Ctype _ ty => cases ty <;> simp only [ctype.lemSize, ctype_.lemSize] <;> omega

theorem ctypeEqual_stable_aux (k : Nat) : ∀ (c c0 : ctype) (f g : Nat),
    ctype.lemSize c ≤ k → ctype.lemSize c ≤ f → ctype.lemSize c ≤ g →
    ctypeEqual_lemFuel f c c0 = ctypeEqual_lemFuel g c c0 := by
  induction k with
  | zero => intro c _ _ _ hk; have := ctype_lemSize_pos c; omega
  | succ k ih =>
    intro c c0 f g hk hf hg
    cases f with
    | zero => have := ctype_lemSize_pos c; omega
    | succ f =>
      cases g with
      | zero => have := ctype_lemSize_pos c; omega
      | succ g =>
        obtain ⟨an1, ty1⟩ := c
        obtain ⟨an2, ty2⟩ := c0
        -- every constructor of both sides, tuple patterns destructured
        (rcases ty1 with _ | b1 | ⟨t1, n1⟩ | ⟨⟨q1, t1⟩, ps1, bb1⟩ | ⟨⟨q1, t1⟩⟩ | ⟨q1, t1⟩ | t1 | s1 | s1 | _ <;>
          rcases ty2 with _ | b2 | ⟨t2, n2⟩ | ⟨⟨q2, t2⟩, ps2, bb2⟩ | ⟨⟨q2, t2⟩⟩ | ⟨q2, t2⟩ | t2 | s2 | s2 | _ <;>
          simp only [ctypeEqual_lemFuel] <;> try rfl)
        all_goals simp only [ctype.lemSize, ctype_.lemSize] at hk hf hg
        -- Array0 / Array0
        · rw [ih t1 t2 f g (by omega) (by omega) (by omega)]
        -- Function / Function: the child and the parameter list
        · rw [ih t1 t2 f g (by omega) (by omega) (by omega), LemLibTheorems.lemListZip_eq]
          congr 3
          apply all_congr
          intro p hp
          obtain ⟨⟨q1', t1', b1'⟩, ⟨q2', t2', b2'⟩⟩ := p
          have hmem := (List.of_mem_zip hp).1
          have := ctype_param_lt t1' q1' b1' ps1 hmem
          simp only [Lem_Function.uncurry]
          rw [ih t1' t2' f g (by omega) (by omega) (by omega)]
        -- FunctionNoParams / FunctionNoParams
        · rw [ih t1 t2 f g (by omega) (by omega) (by omega)]
        -- Atomic / Atomic
        · rw [ih t1 t2 f g (by omega) (by omega) (by omega)]

/-- THE OBLIGATION, exactly as Ctype_auxiliary.lean states and delegates it. -/
theorem ctypeEqual_measure_sufficient (c : ctype) (c0 : ctype) (lemFuel : Nat)
    (lemMeasureLe : ctype.lemSize c ≤ lemFuel) :
    ctypeEqual_lemFuel lemFuel c c0 = ctypeEqual c c0 :=
  ctypeEqual_stable_aux (ctype.lemSize c) c c0 lemFuel (ctype.lemSize c)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Ctype_lemMeasureProofs
