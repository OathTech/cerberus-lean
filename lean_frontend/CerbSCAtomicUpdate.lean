import Core_aux

/-! Equations over the actual atomic-update syntax and structural conversion.
These laws do not claim Cmm correspondence or a completed SC checker. -/
namespace CerbSCAtomicUpdate

theorem constructor_equation (loc : CerbLocation.Loc) (forward : Bool)
    (ty ptr : pexpr) (binder : sym) (update : pexpr) (order : memory_order) :
    (atomic_update loc forward ty ptr binder update order : expr Unit) =
      Expr [] (Eaction (Paction Pos (Action loc default
        (AtomicUpdate forward ty ptr binder update order)))) := rfl

/-- An update binder scopes its update expression, not its address or type. -/
theorem substitution_at_binder (target binder : sym) (value : value)
    forward ty ptr update order (h : symbolEquality target binder = true) :
    subst_sym_action_ target value (AtomicUpdate forward ty ptr binder update order) =
      AtomicUpdate forward (subst_sym_pexpr target value ty)
        (subst_sym_pexpr target value ptr) binder update order := by
  unfold symbolEquality at h
  simp only [subst_sym_action_, h, if_true]

theorem structural_pure (annots : List annot) (pe : pexpr) :
    to_pure_structural (Expr annots (Epure pe) : expr Unit) = some pe := rfl

/-- Converting an effectful action to pure arithmetic must fail explicitly. -/
theorem structural_action_refused (annots : List annot) (action : paction Unit) :
    to_pure_structural (Expr annots (Eaction action)) = none := rfl

end CerbSCAtomicUpdate
