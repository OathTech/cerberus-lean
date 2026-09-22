import CerbSCOperational

/-! Typed inspection of actual SC failures. These laws do not turn a modeling
gap into ISO undefined behavior, or claim that all protocol guards are reachable. -/
namespace CerbSCFaults

theorem not_undefined reason loc ubs :
    (Other (DErr_concurrency reason) : kill_reason driver_error) ≠ Undef0 loc ubs := by
  intro impossible
  cases impossible

theorem identity {a b : sc_fault} :
    (Other (DErr_concurrency a) : kill_reason driver_error) = Other (DErr_concurrency b) ↔ a = b := by
  constructor
  · intro h
    cases h
    rfl
  · intro h
    cases h
    rfl

theorem order_identity {a b : sc_request_kind} :
    SC_fault_order a = SC_fault_order b ↔ a = b := by
  constructor
  · intro h
    cases h
    rfl
  · intro h
    cases h
    rfl

theorem unspecified_class :
    sc_fault_class SC_fault_unspecified_representation = SC_failure_representation := rfl

theorem uninitialized_step [LemFuel] tags (s : sc_machine_state) (h : s.sc_driver_state.sc_state0 = none) :
    CerbSCOperational.node (sc_step tags ()) s =
      (if LemFuel.fuel = 0 then
        (NDkilled (Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg), s)
       else (NDkilled (Other (DErr_concurrency SC_fault_uninitialized)), s)) := by
  cases budget : LemFuel.fuel with
  | zero =>
    simp only [CerbSCOperational.node, sc_step, nd_bind, budget, nd_bind_lemFuel]
    rfl
  | succ n => simp [CerbSCOperational.node, sc_step, nd_bind, budget, nd_bind_lemFuel, nd_get, h, kill]

theorem unowned_post_memory (s : driver_state) (sc : sc_state)
    (enabled : s.sc_state0 = some sc) (unowned : sc.sc_current_request = none) :
    sc_post_memory s = (some (Other (DErr_concurrency SC_fault_unowned_memory_node)), s) := by
  simp only [sc_post_memory, enabled, unowned]
  rfl

end CerbSCFaults
