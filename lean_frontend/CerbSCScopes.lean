import Driver

set_option autoImplicit true
open Lem_Basic_classes

namespace CerbSCScopes

private theorem nat_key_eq_iff (a b : Nat) : (a == b) = true ↔ a = b := by
  constructor
  · intro h
    change (match defaultCompare a b with | .EQ => true | _ => false) = true at h
    unfold defaultCompare at h
    cases hc : Ord.compare a b with
    | lt => simp only [hc, Bool.false_eq_true] at h
    | eq => exact Nat.compare_eq_eq.mp hc
    | gt => simp only [hc, Bool.false_eq_true] at h
  · intro h
    cases h
    change (match defaultCompare a a with | .EQ => true | _ => false) = true
    have h : Ord.compare a a = Ordering.eq := Nat.compare_eq_eq.mpr rfl
    simp only [defaultCompare, h]


theorem push_depth {a : Type} flag name (ctx : context) (stack : stack a) (n : Nat)
    (known : sc_stack_depth stack = some n) :
    sc_stack_depth (Stack_cons2 flag name ctx stack) = some (n + 1) := by
  simp only [sc_stack_depth, known]

theorem enter (before after : thread_state) (n : Nat) flag name ctx
    (known : sc_stack_depth before.stack0 = some n)
    (pushed : after.stack0 = Stack_cons2 flag name ctx before.stack0) :
    sc_call_boundary0 before after = SC_call_enter (n + 1) := by
  simp only [sc_call_boundary0, pushed, sc_stack_depth, known, nat_key_eq_iff]
  rw [if_neg (by omega), if_pos True.intro]

theorem returned (before after : thread_state) (n : Nat) flag name ctx
    (known : sc_stack_depth after.stack0 = some n)
    (popped : before.stack0 = Stack_cons2 flag name ctx after.stack0) :
    sc_call_boundary0 before after = SC_call_return (n + 1) := by
  simp only [sc_call_boundary0, popped, sc_stack_depth, known, nat_key_eq_iff]
  rw [if_neg (by omega), if_neg (by omega), if_pos True.intro]

theorem same_stack (before after : thread_state) (n : Nat)
    (known : sc_stack_depth before.stack0 = some n)
    (same : after.stack0 = before.stack0) :
    sc_call_boundary0 before after = SC_call_unchanged n := by
  simp only [sc_call_boundary0, same, known, nat_key_eq_iff, if_pos True.intro]

theorem legacy_before (before after : thread_state)
    (unknown : sc_stack_depth before.stack0 = none) :
    sc_call_boundary0 before after = SC_call_legacy_depth := by
  simp [sc_call_boundary0, unknown]

theorem legacy_after (before after : thread_state)
    (unknown : sc_stack_depth after.stack0 = none) :
    sc_call_boundary0 before after = SC_call_legacy_depth := by
  simp only [sc_call_boundary0, unknown]
  cases sc_stack_depth before.stack0 <;> rfl


theorem unchanged_state {a b : Type} (file : generic_file a b) extern tid frontier before after state n
    (known : sc_stack_depth before.stack0 = some (sc_scope_thread0 tid state).length)
    (boundary : sc_call_boundary0 before after = SC_call_unchanged n) :
    sc_scope_observe file extern tid frontier before after state = state := by
  simp only [sc_scope_observe, known, Lem_Maybe.maybeEqualBy, nat_key_eq_iff, if_pos True.intro, boundary]

theorem enter_next {a b : Type} (file : generic_file a b) extern tid frontier before after state n
    (boundary : sc_call_boundary0 before after = SC_call_enter n) :
    (sc_scope_observe file extern tid frontier before after state).sc_scope_next = state.sc_scope_next + 1 := by
  simp only [sc_scope_observe, boundary, sc_scope_set_thread]
  split <;> rfl

theorem enter_history {a b : Type} (file : generic_file a b) extern tid frontier before after state n
    (boundary : sc_call_boundary0 before after = SC_call_enter n) :
    (sc_scope_observe file extern tid frontier before after state).sc_scope_events.tail = state.sc_scope_events := by
  simp only [sc_scope_observe, boundary, sc_scope_set_thread]
  split <;> rfl

theorem return_history {a b : Type} (file : generic_file a b) extern tid frontier before after state n id rest
    (boundary : sc_call_boundary0 before after = SC_call_return n)
    (live : sc_scope_thread0 tid state = id :: rest) :
    (sc_scope_observe file extern tid frontier before after state).sc_scope_events =
      SC_scope_returned id frontier :: state.sc_scope_events := by
  simp only [sc_scope_observe, boundary, live, sc_scope_set_thread]
  split <;> rfl

theorem discard_history tid frontier state id rest
    (live : sc_scope_thread0 tid state = id :: rest) :
    (sc_scope_discard tid frontier state).sc_scope_events =
      SC_scope_discarded tid (id :: rest) frontier :: state.sc_scope_events := by
  simp only [sc_scope_discard, live, sc_scope_set_thread]

theorem discard_empty tid frontier state
    (live : sc_scope_thread0 tid state = []) :
    sc_scope_discard tid frontier state = state := by
  simp only [sc_scope_discard, live]

/-- The actual request captures the currently live scopes, before any helper
can suspend and another thread can enter or leave a call. -/
theorem request_owns_scopes tid kind annotation (state : driver_state) sc
    (enabled : state.sc_state0 = some sc) :
    ((sc_request_state tid kind annotation state).sc_state0.bind
      (·.sc_current_request)).map (·.sc_request_scopes) =
        some (sc_scope_thread0 tid sc.sc_scopes) := by
  simp only [sc_request_state, enabled, sc_begin_request]
  rfl

/-- A call observation consumes no effect identity and changes no object
memory, Core thread, filesystem, or continuation. Only the passive SC field
is replaced. The service subsequently installs the supplied Core thread. -/
theorem observe_state tid after (state : driver_state) :
    let observed := sc_observe_thread tid after state
    { observed with sc_state0 := state.sc_state0 } = state := by
  simp only [sc_observe_thread]
  split <;> rfl

theorem observe_disabled tid after (state : driver_state)
    (disabled : state.sc_state0 = none) :
    sc_observe_thread tid after state = state := by
  simp only [sc_observe_thread, disabled]

/-- A suspended request keeps its original call identities; resumption uses
the current branch's scope state, including other threads' intervening calls. -/
theorem restore_scopes (saved : sc_saved_service) (state : driver_state) sc
    (enabled : state.sc_state0 = some sc) :
    (sc_restore_service saved state).2.sc_state0.map (·.sc_scopes) = some sc.sc_scopes ∧
    ((sc_restore_service saved state).2.sc_state0.bind
      (·.sc_current_request)).map (·.sc_request_scopes) =
        some saved.sc_saved_request.sc_request_scopes := by
  simp only [sc_restore_service, enabled]
  exact ⟨rfl, rfl⟩

end CerbSCScopes
