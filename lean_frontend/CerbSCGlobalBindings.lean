import Driver
import Sc_global_bindings
import CerbSCOperational

set_option autoImplicit true
namespace CerbSCGlobalBindings
open CerbSCOperational

theorem disabled thread step symbol value previous :
    sc_note_global_binding none thread step symbol value previous = previous := rfl

theorem enabled sc thread step symbol value previous :
    sc_note_global_binding (some sc) thread step symbol value previous =
      { sc_binding_symbol := symbol, sc_binding_value := value,
        sc_binding_thread := thread, sc_binding_step := step,
        sc_binding_effect_frontier := sc.sc_effects.length } :: previous := rfl

theorem prior_receipts sc thread step symbol value previous :
    (sc_note_global_binding (some sc) thread step symbol value previous).tail = previous := rfl

theorem initializer_disabled thread : sc_initialization_thread none thread = thread := rfl

theorem initializer_enabled annotation thread :
    sc_initialization_thread (some annotation) thread =
      { thread with arena := sc_inherit_expr annotation thread.arena } := rfl

theorem environment_retained annotation thread :
    (sc_initialization_thread annotation thread).env = thread.env := by
  cases annotation <;> rfl

theorem stack_retained annotation thread :
    (sc_initialization_thread annotation thread).stack0 = thread.stack0 := by
  cases annotation <;> rfl

/-- Exact factorization of the actual Driver update: no extra ND transition. -/
theorem actual_initialization_update tid thread :
    (initialize_thread_state tid thread : driverM Unit) =
      nd_update (fun state : driver_state => { state with core_state0 := (update_thread_state tid
          (sc_initialization_thread (state.sc_state0.map (fun _ => sc_initial_annotation tid state)) thread)
          state.core_state0) }) := by
  unfold initialize_thread_state initialize_thread_state_with_binding
  congr 1
  funext state
  cases state.sc_state0 <;> rfl

/-- The actual update records a completed binding without another ND node. -/
theorem producer_receipt (tid : Nat) thread symbol value (state : driver_state) :
    (node (initialize_thread_state_with_binding (some (symbol,value)) tid thread : driverM Unit) state).2.sc_global_bindings =
      sc_note_global_binding state.sc_state0 tid state.dr_step_counter symbol value state.sc_global_bindings := rfl

/-- Beginning a new recording clears receipts from the prior recording epoch. -/
theorem enable_resets_receipts (state : driver_state) memory
    (available : CerbMem.beginObserving state.layout_state = some memory) :
    (node (sc_enable : driverM Unit) state).2.sc_global_bindings = [] := by
  simp only [node, sc_enable, available]

/-- The producer changes no concrete memory state or memory-effect history. -/
theorem producer_memory (tid : Nat) thread binding (state : driver_state) :
    let after := (node (initialize_thread_state_with_binding binding tid thread : driverM Unit) state).2
    after.layout_state = state.layout_state ∧ after.sc_state0 = state.sc_state0 := by
  exact ⟨rfl,rfl⟩

/-- Erasing only the new receipt field recovers the complete prior update. -/
theorem producer_erasure (tid : Nat) thread binding (state : driver_state) :
    let added := node (initialize_thread_state_with_binding binding tid thread : driverM Unit) state
    let plain := node (initialize_thread_state tid thread : driverM Unit) state
    added.1 = plain.1 ∧
      { added.2 with sc_global_bindings := plain.2.sc_global_bindings } = plain.2 := by
  exact ⟨rfl,rfl⟩

end CerbSCGlobalBindings
