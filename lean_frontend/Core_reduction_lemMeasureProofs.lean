/-
  Core_reduction_lemMeasureProofs — the hand-written proof of the `fuel_measure`
  obligation lem emits into Core_reduction_auxiliary.lean (fuel-parameter arc
  C2, 2026-09-04; `declare {lean} fuel_measure val has_ccall = `lemSize g`` in
  frontend/model/core_reduction.lem, Lean-only). Shape: the C2 template
  (Core_run_aux_lemMeasureProofs.lean) — strong induction on the derived
  expression size, `key` rewrites the direct children, `List.any` congruence
  for `Ecase`/`Eunseq`/`End`. Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds (fuel is a Lean-target artifact).
-/

import Core_reduction
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Core_reduction_lemMeasureProofs

theorem has_ccall_stable_aux {a : Type} {b : Type} {c : Type} (k : Nat) : ∀ (e : generic_expr c b a) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    has_ccall_lemFuel f e = has_ccall_lemFuel g e := by
  induction k with
  | zero => intro e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (y : generic_expr c b a), generic_expr.lemSize y < generic_expr.lemSize e →
            has_ccall_lemFuel f y = has_ccall_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [has_ccall_lemFuel, key]
        case Ecase pe xs =>
          apply lany_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          apply lany_congr; intro e he
          exact key e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          apply lany_congr; intro e he
          exact key e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem has_ccall_measure_sufficient {a : Type} {b : Type} {c : Type} (g : generic_expr c b a) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    has_ccall_lemFuel lemFuel g = has_ccall g :=
  has_ccall_stable_aux (generic_expr.lemSize g) g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Core_reduction_lemMeasureProofs
