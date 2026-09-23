import Sc_varargs
import LemLibTheorems

/-! Laws about the actual metadata query. They assume a supplied order;
    no theorem here identifies an arbitrary relation with happens-before. -/
namespace CerbSCVarargs

theorem separate_identities (left right : sc_varargs_event)
    (different : left.sc_va_identity ≠ right.sc_va_identity) :
    sc_varargs_conflict left right = false := by
  simp only [sc_varargs_conflict, Bool.and_eq_false_iff]
  left
  change (match defaultCompare left.sc_va_identity right.sc_va_identity with
    | LemOrdering.EQ => true | _ => false) = false
  unfold defaultCompare
  cases compared : compare left.sc_va_identity right.sc_va_identity with
  | lt => rfl
  | eq => exact False.elim (different (Int.compare_eq_eq.mp compared))
  | gt => rfl

theorem two_reads (left right : sc_varargs_event)
    (lread : left.sc_va_operation = Varargs_read)
    (rread : right.sc_va_operation = Varargs_read) :
    sc_varargs_conflict left right = false := by
  simp [sc_varargs_conflict, sc_varargs_modifies, lread, rread]

theorem forward_order_suppresses (hb) (left right : sc_varargs_event)
    (ordered : sc_varargs_ordered hb left right = true) :
    sc_varargs_unordered_pair hb left right = none := by
  simp [sc_varargs_unordered_pair, ordered]

theorem reverse_order_suppresses (hb) (left right : sc_varargs_event)
    (ordered : sc_varargs_ordered hb right left = true) :
    sc_varargs_unordered_pair hb left right = none := by
  simp [sc_varargs_unordered_pair, ordered]

theorem no_conflict_no_witness (hb) (left right : sc_varargs_event)
    (noConflict : sc_varargs_conflict left right = false) :
    sc_varargs_unordered_pair hb left right = none := by
  simp [sc_varargs_unordered_pair, noConflict]

/-- The query preserves the journal's occurrence order and multiplicity. -/
theorem events_eq_filterMap (history : List sc_effect) :
    sc_varargs_events history = history.filterMap sc_varargs_event_of := by
  unfold sc_varargs_events
  rw [LemLibTheorems.lemListFoldr_eq]
  induction history with
  | nil => rfl
  | cons observed rest ih =>
    cases value : sc_varargs_event_of observed <;> simp [List.foldr, value, ih]

theorem event_from_history (history : List sc_effect) (event : sc_varargs_event)
    (present : event ∈ sc_varargs_events history) :
    ∃ observed ∈ history, sc_varargs_event_of observed = some event := by
  simpa only [events_eq_filterMap, List.mem_filterMap] using present

private theorem pair_fields (hb) (left right : sc_varargs_event)
    (witness : sc_varargs_conflict_witness)
    (found : sc_varargs_unordered_pair hb left right = some witness) :
    witness.sc_va_conflict_left = left ∧ witness.sc_va_conflict_right = right := by
  unfold sc_varargs_unordered_pair at found
  split at found
  · cases Option.some.inj found
    exact ⟨rfl,rfl⟩
  · cases found

/-- Each side of a reported witness is an actual journal event. No memory
    write or metadata occurrence is synthesized by pair collection. -/
theorem witness_from_history (hb) (history : List sc_effect)
    (witness : sc_varargs_conflict_witness)
    (present : witness ∈ sc_varargs_unordered_pairs hb history) :
    witness.sc_va_conflict_left ∈ sc_varargs_events history ∧
    witness.sc_va_conflict_right ∈ sc_varargs_events history := by
  have collected : sc_varargs_unordered_pairs hb history =
      ((sc_varargs_events history).map fun left =>
        (sc_varargs_events history).filterMap (sc_varargs_unordered_pair hb left)).flatten := by
    unfold sc_varargs_unordered_pairs
    dsimp only
    apply congrArg List.flatten
    apply List.map_congr_left
    intro left _
    rw [LemLibTheorems.lemListFoldr_eq]
    induction sc_varargs_events history with
    | nil => rfl
    | cons right rest ih =>
      cases value : sc_varargs_unordered_pair hb left right <;> simp [List.foldr, value, ih]
  rw [collected] at present
  obtain ⟨part, partIn, witnessIn⟩ := List.mem_flatten.mp present
  obtain ⟨left, leftIn, rfl⟩ := List.mem_map.mp partIn
  obtain ⟨right, rightIn, found⟩ := List.mem_filterMap.mp witnessIn
  obtain ⟨leftEq,rightEq⟩ := pair_fields hb left right witness found
  exact ⟨leftEq.symm ▸ leftIn, rightEq.symm ▸ rightIn⟩

end CerbSCVarargs
