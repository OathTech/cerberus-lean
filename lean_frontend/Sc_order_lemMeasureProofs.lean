/- Fuel stability of the actual generated SC annotation workers.
   Derived from the existing Core_run_aux proof pattern; compiled in the isolated generation-18 Lean probe
   against the new protocol. No semantic restriction on input expressions. -/
import Sc_order
import CerbMeasureLemmas
set_option autoImplicit false
open CerbMeasureLemmas
namespace Sc_order_lemMeasureProofs

theorem sc_add_before_expr_stable_aux (k : Nat) : ∀ (p_aids : Pset (polarity × (thread_id × aid)))
    (e : generic_expr core_run_annotation Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    sc_add_before_expr_lemFuel f p_aids e = sc_add_before_expr_lemFuel g p_aids e := by
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
            sc_add_before_expr_lemFuel f q y = sc_add_before_expr_lemFuel g q y :=
          fun q y hy => ih q y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [sc_add_before_expr_lemFuel, key]
        -- Ecase
        · to_congr; intro p hp; obtain ⟨pat, e⟩ := p
          simp only []
          rw [key _ e (by have := expr_mem_lt_aux1 pat e _ hp; size_lt)]
        -- Eunseq
        · to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        -- End
        · to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        -- Epar
        · to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as Sc_order_auxiliary.lean states and delegates it. -/
theorem sc_add_before_expr_measure_sufficient (p_aids : Pset (polarity × (thread_id × aid)))
    (g : generic_expr core_run_annotation Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    sc_add_before_expr_lemFuel lemFuel p_aids g = sc_add_before_expr p_aids g :=
  sc_add_before_expr_stable_aux (generic_expr.lemSize g) p_aids g lemFuel (generic_expr.lemSize g)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

theorem sc_inherit_expr_stable_aux (k : Nat) : ∀ (p_aids : core_run_annotation)
    (e : generic_expr core_run_annotation Unit sym) (f g : Nat),
    generic_expr.lemSize e ≤ k → generic_expr.lemSize e ≤ f → generic_expr.lemSize e ≤ g →
    sc_inherit_expr_lemFuel f p_aids e = sc_inherit_expr_lemFuel g p_aids e := by
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
        have key : ∀ (q : core_run_annotation) (y : generic_expr core_run_annotation Unit sym),
            generic_expr.lemSize y < generic_expr.lemSize e →
            sc_inherit_expr_lemFuel f q y = sc_inherit_expr_lemFuel g q y :=
          fun q y hy => ih q y f g (by omega) (by omega) (by omega)
        obtain ⟨annot1, e_⟩ := e
        cases e_ <;> simp (disch := size_lt) only [sc_inherit_expr_lemFuel, key]
        -- Ecase
        · to_congr; intro p hp; obtain ⟨pat, e⟩ := p
          simp only []
          rw [key _ e (by have := expr_mem_lt_aux1 pat e _ hp; size_lt)]
        -- Eunseq
        · to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        -- End
        · to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)
        -- Epar
        · to_congr; intro e he
          exact key _ e (by have := expr_mem_lt_aux2 e _ he; size_lt)

/-- THE OBLIGATION, exactly as Sc_order_auxiliary.lean states and delegates it. -/
theorem sc_inherit_expr_measure_sufficient (p_aids : core_run_annotation)
    (g : generic_expr core_run_annotation Unit sym) (lemFuel : Nat)
    (lemMeasureLe : generic_expr.lemSize g ≤ lemFuel) :
    sc_inherit_expr_lemFuel lemFuel p_aids g = sc_inherit_expr p_aids g :=
  sc_inherit_expr_stable_aux (generic_expr.lemSize g) p_aids g lemFuel (generic_expr.lemSize g)
    (Nat.le_refl _) lemMeasureLe (Nat.le_refl _)

end Sc_order_lemMeasureProofs
