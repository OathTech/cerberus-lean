import CerbSCOperational
import Atomic_order

/-! Laws over the actual evaluator and driver. No Cmm completeness claim. -/
namespace CerbSCAtomicSurface

theorem gap_not_undefined location gap ubLocation ubs :
    (Other (DErr_core_run (Model_gap location gap)) : kill_reason driver_error) ≠
      Undef0 ubLocation ubs := by
  intro impossible
  cases impossible

theorem gap_identity {location₁ location₂ : CerbLocation.Loc}
    {gap₁ gap₂ : core_model_gap} :
    Model_gap location₁ gap₁ = Model_gap location₂ gap₂ ↔
      location₁ = location₂ ∧ gap₁ = gap₂ := by
  constructor
  · intro h
    cases h
    exact ⟨rfl, rfl⟩
  · rintro ⟨rfl, rfl⟩
    rfl

theorem gap_evaluation [LemFuel] (fuel : Nat) tags n location callLocation externs
    environment memory file constrained annotations gapLocation gap :
    step_eval_pexpr_lemFuel (fuel + 1) tags n location callLocation externs
      environment memory file constrained (Pexpr annotations () (PEmodel_gap gapLocation gap)) =
      Exception (Model_gap
        (if CerbLocation.isLibraryLocation gapLocation then location else gapLocation) gap) := rfl

theorem gap_lifting_retains_state {α : Type} [LemFuel] location gap (s : driver_state) :
    CerbSCOperational.node (liftCore_run
      (stExceptUndef_fail (Model_gap location gap) : core_runM α)) s =
      (if LemFuel.fuel = 0 then
         (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), s)
       else (NDkilled (Other (DErr_core_run (Model_gap location gap))), s)) := by
  cases budget : LemFuel.fuel with
  | zero =>
    simp only [CerbSCOperational.node, liftCore_run, nd_bind, budget, nd_bind_lemFuel]
    rfl
  | succ n =>
    simp [CerbSCOperational.node, liftCore_run, nd_bind, budget, nd_bind_lemFuel,
      nd_get, stExceptUndef_run, stExceptUndef_fail, runE, runEU, fail0, throw0, except_bind, kill]

theorem substitution_preserves_gap target value annotations location gap :
    subst_sym_pexpr target value (Pexpr annotations () (PEmodel_gap location gap)) =
      Pexpr annotations () (PEmodel_gap location gap) := rfl

theorem signal_order_retained (order : memory_order) :
    sc_request_in_model (SC_signal_fence order) = (order != NA) := rfl

theorem release_is_not_acquire_failure :
    atomic_compare_orders_error Release Acquire =
      some UB207_atomic_compare_exchange_memorder := rfl

end CerbSCAtomicSurface
