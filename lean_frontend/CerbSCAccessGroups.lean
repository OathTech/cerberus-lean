import Sc_access_group

set_option autoImplicit true
open Lem_Basic_classes

namespace CerbSCAccessGroups

theorem pair_has_accesses (first second : sc_effect)
    (h : sc_can_pair_accesses first second = true) :
    sc_is_access first = true ∧ sc_is_access second = true := by
  simp only [sc_can_pair_accesses, Bool.and_eq_true] at h
  have shape := h.2.2.2.2
  split at shape <;> simp_all [sc_is_access]

private theorem nat_key_eq (a b : Nat) (h : (a == b) = true) : a = b := by
  change (match defaultCompare a b with | .EQ => true | _ => false) = true at h
  unfold defaultCompare at h
  cases hc : Ord.compare a b with
  | lt => simp [hc] at h
  | eq => exact Nat.compare_eq_eq.mp hc
  | gt => simp [hc] at h

theorem pair_same_owner (first second : sc_effect)
    (h : sc_can_pair_accesses first second = true) :
    first.sc_effect_request.sc_request_id = second.sc_effect_request.sc_request_id ∧
    first.sc_effect_request.sc_request_thread = second.sc_effect_request.sc_request_thread := by
  simp only [sc_can_pair_accesses, Bool.and_eq_true] at h
  exact ⟨nat_key_eq _ _ h.2.1, nat_key_eq _ _ h.2.2.1⟩

theorem ungroup_exact (history : List sc_effect) :
    sc_ungroup_accesses (sc_group_accesses history) = sc_access_effects history := by
  induction history using sc_group_accesses.induct with
  | case1 => rfl
  | case2 first h =>
    simp [sc_group_accesses, h, sc_ungroup_accesses, sc_access_effects, sc_group_occurrences]
  | case3 first h =>
    simp [sc_group_accesses, h, sc_ungroup_accesses, sc_access_effects]
  | case4 first second rest h ih =>
    have ⟨hf,hs⟩ := pair_has_accesses first second h
    simp only [sc_ungroup_accesses, sc_access_effects] at ih ⊢
    rw [sc_group_accesses, if_pos h]
    simpa [sc_group_occurrences, hf, hs] using congrArg (fun xs => first :: second :: xs) ih
  | case5 first second rest h hf ih =>
    simp only [sc_ungroup_accesses, sc_access_effects] at ih ⊢
    rw [sc_group_accesses, if_neg h]
    simpa [sc_group_occurrences, hf] using congrArg (fun xs => first :: xs) ih
  | case6 first second rest h hf ih =>
    simp only [sc_ungroup_accesses, sc_access_effects] at ih ⊢
    rw [sc_group_accesses, if_neg h]
    simpa [hf] using ih

theorem emitted_pair (history : List sc_effect) (first second : sc_effect)
    (present : SC_access_atomic_pair first second ∈ sc_group_accesses history) :
    sc_can_pair_accesses first second = true := by
  induction history using sc_group_accesses.induct with
  | case1 => simp [sc_group_accesses] at present
  | case2 f h => simp [sc_group_accesses, h] at present
  | case3 f h => simp [sc_group_accesses, h] at present
  | case4 f s rest h ih =>
    rw [sc_group_accesses, if_pos h, List.mem_cons] at present
    rcases present with hp | ht
    · cases hp; exact h
    · exact ih ht
  | case5 f s rest h hf ih =>
    rw [sc_group_accesses, if_neg h] at present
    simp only [hf, if_true, List.mem_cons, reduceCtorEq, false_or] at present
    exact ih present
  | case6 f s rest h hf ih =>
    rw [sc_group_accesses, if_neg h] at present
    simp only [hf, if_false] at present
    exact ih present

end CerbSCAccessGroups
