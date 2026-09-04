/-
  Core_run_aux_lemMeasureProofs — the hand-written proofs of the `fuel_measure`
  obligations lem emits into Core_run_aux_auxiliary.lean (fuel-parameter arc
  C2, 2026-09-04; `declare {lean} fuel_measure val …` in
  frontend/model/core_run_aux.lem, Lean-only):

    add_to_sb / add_to_asw   measure `lemSize g`  (generic_expr.lemSize)
    convert_pexpr            measure `lemSize g`  (generic_pexpr.lemSize)
    convert_expr             measure `lemSize g`  (generic_expr.lemSize)

  THE OBLIGATION (per function, generated): the worker is fuel-STABLE at the
  measure. Shape = the C1 template: strong induction on the size bound; at
  `Nat.succ f`/`Nat.succ g` the body is unfolded and every recursive call on a
  direct sub-expression is rewritten by the induction hypothesis (`key`, a
  `simp` rewrite whose side condition `size child < size parent` the
  `size_lt` discharger proves); the list traversals (`List.map` over
  `Ecase`/`Eunseq`/`End`/`Epar`, the pexpr constructors' lists) are rewritten
  by membership-relative congruence with the derived list helpers' member
  bounds (CerbMeasureLemmas). Kernel-only tactics; no option bumps.

  MIRROR-OCAML NOTE: proofs about the Lean total workers; no OCaml text
  corresponds.
-/

import Core_run_aux
import CerbMeasureLemmas

set_option autoImplicit false

open CerbMeasureLemmas

namespace Core_run_aux_lemMeasureProofs

theorem add_to_sb_stable_aux (k : Nat) : ∀ (p_aids : Pset (polarity × (thread_id × aid)))
    (e : generic_expr core_run_annotation Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    add_to_sb_lemFuel f p_aids e = add_to_sb_lemFuel g p_aids e := by
  induction k with
  | zero => intro _ e _ _ hk; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro p_aids e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (q : Pset (polarity × (thread_id × aid))) (y : generic_expr core_run_annotation Unit sym),
            generic_expr.lemSize y < generic_expr.lemSize e →
            add_to_sb_lemFuel f q y = add_to_sb_lemFuel g q y :=
          fun q y hy => ih q y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [add_to_sb_lemFuel, key]
        -- Ecase
        · split <;> try rfl
          to_congr; intro p hp; obtain ⟨pat, e⟩ := p
          simp only []
          rw [key _ e (by have := expr_mem_lt_aux1 pat e _ hp; size_lt)]
        -- Eunseq
        · split <;> try rfl
          to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        -- End
        · split <;> try rfl
          to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        -- Epar
        · split <;> try rfl
          to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as Core_run_aux_auxiliary.lean states and delegates it. -/
theorem add_to_sb_measure_sufficient (p_aids : Pset (polarity × (thread_id × aid)))
    (g : generic_expr core_run_annotation Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    add_to_sb_lemFuel lemFuel p_aids g = add_to_sb p_aids g :=
  add_to_sb_stable_aux (generic_expr.lemSize g) p_aids g lemFuel (generic_expr.lemSize g)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem add_to_asw_stable_aux (k : Nat) : ∀ (aids : Pset Nat) (e : generic_expr core_run_annotation Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    add_to_asw_lemFuel f aids e = add_to_asw_lemFuel g aids e := by
  induction k with
  | zero => intro aids e f g hk _ _; have := expr_lemSize_pos e; omega
  | succ k ih =>
    intro aids e f g hk hf hg
    cases f with
    | zero => have := expr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := expr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (aids' : Pset Nat) (y : generic_expr core_run_annotation Unit sym), generic_expr.lemSize y < generic_expr.lemSize e →
            add_to_asw_lemFuel f aids' y = add_to_asw_lemFuel g aids' y :=
          fun aids' y hy => ih aids' y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [add_to_asw_lemFuel, key]
        case Ecase pe pat_es =>
          split <;> try rfl
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key _ e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          split <;> try rfl
          to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          split <;> try rfl
          to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          split <;> try rfl
          to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem add_to_asw_measure_sufficient (aids : Pset Nat) (g : generic_expr core_run_annotation Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    add_to_asw_lemFuel lemFuel aids g = add_to_asw aids g :=
  add_to_asw_stable_aux (generic_expr.lemSize g) aids g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem convert_pexpr_stable_aux {bty : Type} (k : Nat) : ∀ (e : generic_pexpr bty sym) (f g : Nat),
    generic_pexpr.lemSize e ≤ k → generic_pexpr.lemSize e ≤ f → generic_pexpr.lemSize e ≤ g →
    convert_pexpr_lemFuel f e = convert_pexpr_lemFuel g e := by
  induction k with
  | zero => intro e f g hk _ _; have := pexpr_lemSize_pos e; omega
  | succ k ih =>
    intro e f g hk hf hg
    cases f with
    | zero => have := pexpr_lemSize_pos e; omega
    | succ f =>
      cases g with
      | zero => have := pexpr_lemSize_pos e; omega
      | succ g =>
        have key : ∀ (y : generic_pexpr bty sym), generic_pexpr.lemSize y < generic_pexpr.lemSize e →
            convert_pexpr_lemFuel f y = convert_pexpr_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, bty, pexpr_⟩ := e
        cases pexpr_ <;> simp (disch := size_lt) only [convert_pexpr_lemFuel, key]
        case PEconstrained xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key  e (by have := pexpr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case PEctor ctor1 pes =>
          to_congr; intro e he
          exact key  e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)
        case PEcase pe pat_pes =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key  e (by have := pexpr_mem_lt_aux3 x1 e _ hp; size_lt)]
        case PEmemop mop pes =>
          to_congr; intro e he
          exact key  e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)
        case PEstruct tag xs =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key  e (by have := pexpr_mem_lt_aux4 x1 e _ hp; size_lt)]
        case PEcall nm pes =>
          to_congr; intro e he
          exact key  e (by have := pexpr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem convert_pexpr_measure_sufficient {bty : Type} (g : generic_pexpr bty sym) (lemFuel : Nat)
    (lemMeasureLe : generic_pexpr.lemSize g ≤ lemFuel) :
    convert_pexpr_lemFuel lemFuel g = convert_pexpr g :=
  convert_pexpr_stable_aux (generic_pexpr.lemSize g) g lemFuel (generic_pexpr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem convert_expr_stable_aux {a : Type} {bty : Type} (k : Nat) : ∀ (e : generic_expr a bty sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    convert_expr_lemFuel f e = convert_expr_lemFuel g e := by
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
        have key : ∀ (y : generic_expr a bty sym), generic_expr.lemSize y < generic_expr.lemSize e →
            convert_expr_lemFuel f y = convert_expr_lemFuel g y :=
          fun y hy => ih y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [convert_expr_lemFuel, key]
        case Ecase pe pat_es =>
          to_congr; intro p hp; obtain ⟨x1, e⟩ := p
          dsimp only
          rw [key  e (by have := expr_mem_lt_aux1 x1 e _ hp; size_lt)]
        case Eunseq es =>
          to_congr; intro e he
          exact key  e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case End es =>
          to_congr; intro e he
          exact key  e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        case Epar es =>
          to_congr; intro e he
          exact key  e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as the generated auxiliary module states and delegates it. -/
theorem convert_expr_measure_sufficient {a : Type} {bty : Type} (g : generic_expr a bty sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    convert_expr_lemFuel lemFuel g = convert_expr g :=
  convert_expr_stable_aux (generic_expr.lemSize g) g lemFuel (generic_expr.lemSize g) (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Core_run_aux_lemMeasureProofs
