import Driver
import CerbSCSequencing
import Sc_prefix_obligations

set_option autoImplicit true
namespace CerbSCPrefixObligations
private theorem if_preserves (condition : Bool) (previous later : List sc_prefix_obligation)
    (h : ∃ added, later = added ++ previous) :
    ∃ added, (if condition then previous else later) = added ++ previous := by
  cases condition
  · exact h
  · exact ⟨[],rfl⟩

-- The actual accumulator only prepends evidence; this holds for arbitrary
-- supplied states, even if a later malformed state changes the source graph.
theorem accumulate_preserves (state : sc_state) (previous : List sc_prefix_obligation) :
    ∃ added, sc_accumulate_sequence_obligations state previous = added ++ previous := by
  unfold sc_accumulate_sequence_obligations
  apply if_preserves
  apply if_preserves
  exact ⟨[_],rfl⟩

theorem obligation_retained (state : sc_state) (previous : List sc_prefix_obligation)
    (obligation : sc_prefix_obligation) (h : obligation ∈ previous) :
    obligation ∈ sc_accumulate_sequence_obligations state previous := by
  obtain ⟨added,eq⟩ := accumulate_preserves state previous
  rw [eq,List.mem_append]
  exact Or.inr h

theorem new_obligation (state : sc_state) (previous : List sc_prefix_obligation)
    (obligation : sc_prefix_obligation)
    (h : obligation ∈ sc_accumulate_sequence_obligations state previous)
    (old : obligation ∉ previous) :
    ∃ pairs, obligation = SC_obligation_access_sequencing (sc_prefix_graph state) pairs ∧
      ∀ pair ∈ pairs, pair ∈ sc_access_sequence_witnesses
        (sc_prefix_graph state) state.sc_effects.reverse := by
  unfold sc_accumulate_sequence_obligations at h
  dsimp only at h
  simp only [sc_prefix_graph, CerbSCAccessSequencing.query_eq] at h ⊢
  split at h
  · exact False.elim (old h)
  · split at h
    all_goals
      split at h
      · exact False.elim (old h)
      · simp only [List.mem_cons] at h
        rcases h with eq | h
        · subst obligation
          refine ⟨_,rfl,?_⟩
          intro pair hp
          first | exact (List.mem_filter.mp hp).1 | exact hp
        · exact False.elim (old h)

-- Restoring the old diagnostic field recovers the entire original state.
theorem note_state (state : driver_state) :
    { sc_note_prefix state with sc_prefix_obligations := state.sc_prefix_obligations } = state := by
  simp only [sc_note_prefix]
  split <;> rfl

theorem note_disabled (state : driver_state) (h : state.sc_state0 = none) :
    sc_note_prefix state = state := by simp only [sc_note_prefix,h]

theorem note_enabled (state : driver_state) (sc : sc_state) (h : state.sc_state0 = some sc) :
    (sc_note_prefix state).sc_prefix_obligations =
      sc_accumulate_sequence_obligations sc state.sc_prefix_obligations := by
  simp only [sc_note_prefix,h]

theorem saved_resume_retains (saved : sc_saved_service) (state : driver_state) :
    (sc_restore_service saved state).2.sc_prefix_obligations = state.sc_prefix_obligations := by
  simp only [sc_restore_service]
  split <;> rfl

end CerbSCPrefixObligations
