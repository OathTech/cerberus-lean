import Sc_reference_sequencing
import Sc_access_sequencing
import LemLibTheorems

set_option autoImplicit true
open Lem_Set Lem_Basic_classes Lem_Relation

namespace CerbSCReferenceSequencing
variable {α : Type}
private theorem not_false (b : Bool) : Bool.not b = false ↔ b = true := by
  cases b <;> simp [Bool.not]
private theorem elementsAux_eq (s : Pset α) (acc : List α) :
    Pset.elementsAux acc s = Pset.elements s ++ acc := by
  induction s generalizing acc with
  | Empty => rfl
  | Node l v r h ihl ihr =>
    change Pset.elementsAux (v :: Pset.elementsAux acc r) l =
      Pset.elementsAux (v :: Pset.elementsAux [] r) l ++ acc
    rw [ihl, ihl, ihr]
    simp only [Pset.elements, List.cons_append, List.append_assoc]

private theorem elements_node (l : Pset α) (v : α) (r : Pset α) (h : Nat) :
    Pset.elements (.Node l v r h) = Pset.elements l ++ v :: Pset.elements r := by
  change Pset.elementsAux (v :: Pset.elementsAux [] r) l = _
  rw [elementsAux_eq]
  rfl

theorem forAll_elements (s : Pset α) (p : α → Bool) :
    Pset.forAll p s = true ↔ ∀ x ∈ Pset.elements s, p x = true := by
  induction s with
  | Empty => simp [Pset.forAll, Pset.elements, Pset.elementsAux]
  | Node l v r h ihl ihr =>
    rw [Pset.forAll, Bool.and_eq_true, Bool.and_eq_true, ihl, ihr, elements_node]
    simp only [List.mem_append, List.mem_cons]
    constructor
    · rintro ⟨⟨hv,hl⟩,hr⟩ x (hx | hx | hx)
      · exact hl x hx
      · exact hx ▸ hv
      · exact hr x hx
    · intro hall
      exact ⟨⟨hall v (Or.inr (Or.inl rfl)), fun x hx => hall x (Or.inl hx)⟩,
        fun x hx => hall x (Or.inr (Or.inr hx))⟩

theorem witnesses_membership (execution : sc_ref_pre_execution) (a b : sc_ref_action) :
    (a,b) ∈ sc_reference_sequencing_witnesses execution ↔
    a ∈ setToList execution.sc_ref_actions ∧ b ∈ setToList execution.sc_ref_actions ∧
      sc_reference_sequencing_violation execution a b = true := by
  unfold sc_reference_sequencing_witnesses
  constructor
  · intro h
    obtain ⟨part,partIn,pairIn⟩ := List.mem_flatten.mp h
    obtain ⟨a',aIn,rfl⟩ := List.mem_map.mp partIn
    obtain ⟨b',bIn,pairEq⟩ := List.mem_map.mp pairIn
    have ae : a' = a := congrArg Prod.fst pairEq
    have be : b' = b := congrArg Prod.snd pairEq
    subst a'; subst b'
    exact ⟨aIn, (List.mem_filter.mp bIn).1, (List.mem_filter.mp bIn).2⟩
  · rintro ⟨ha,hb,hv⟩
    exact List.mem_flatten.mpr ⟨_, List.mem_map.mpr ⟨a,ha,rfl⟩,
      List.mem_map.mpr ⟨b,List.mem_filter.mpr ⟨hb,hv⟩,rfl⟩⟩

-- This is the actual pinned predicate, with no assumptions about the shape,
-- locations, values, completeness or consistency of the supplied candidate.
theorem witnesses_empty_iff_reference (execution : sc_ref_pre_execution) :
    sc_reference_sequencing_witnesses execution = [] ↔
      sc_ref_indeterminate_sequencing execution = true := by
  rw [List.eq_nil_iff_forall_not_mem]
  simp only [Prod.forall, witnesses_membership]
  unfold sc_ref_indeterminate_sequencing setForAll
  rw [forAll_elements]
  simp only [forAll_elements, setToList]
  constructor
  · intro h a ha b hb
    have hv := h a b
    have no : sc_reference_sequencing_violation execution a b = false := by
      cases v : sc_reference_sequencing_violation execution a b
      · rfl
      · exact False.elim (hv ⟨ha,hb,v⟩)
    simpa only [sc_reference_sequencing_violation, not_false] using no
  · intro h a b ⟨ha,hb,hv⟩
    have good := h a ha b hb
    have notV : sc_reference_sequencing_violation execution a b = false := by
      simpa only [sc_reference_sequencing_violation, not_false] using good
    rw [notV] at hv
    cases hv
end CerbSCReferenceSequencing
namespace CerbSCAccessSequencing
set_option autoImplicit true
open CerbSCReferenceSequencing
private theorem union_empty (s : Pset (Nat × Nat)) :
    setUnionBy (pairCompare defaultCompare defaultCompare) s .Empty = s := by
  cases s <;> rfl

theorem graph_closure (nodes : List sc_graph_node) :
    (sc_build_source_graph nodes).sc_graph_sbasw =
      set_tcByCmp (pairCompare defaultCompare defaultCompare)
        (setUnionBy (pairCompare defaultCompare defaultCompare)
          (sc_build_source_graph nodes).sc_graph_sb
          (sc_build_source_graph nodes).sc_graph_asw) := by
  unfold sc_build_source_graph
  split
  split
  rfl

theorem query_eq (nodes : List sc_graph_node) (history : List sc_effect) :
    sc_access_sequence_witnesses_reusing_graph (sc_build_source_graph nodes) history =
      sc_access_sequence_witnesses (sc_build_source_graph nodes) history := by
  have hc := graph_closure nodes
  generalize sc_build_source_graph nodes = graph at hc ⊢
  unfold sc_access_sequence_witnesses_reusing_graph sc_access_sequence_witnesses
  cases ha : graph.sc_graph_asw with
  | Empty =>
    simp only [ha, setIsEmpty, Pset.isEmpty, if_true]
    rw [hc, ha, union_empty]
  | Node l v r h => simp only [ha, setIsEmpty, Pset.isEmpty, Bool.false_eq_true, if_false]

private theorem not_true (b : Bool) (h : Bool.not b = true) : b = false := by
  cases b
  · rfl
  · cases h

private theorem fold_spec (sb : Pset (Nat × Nat)) (left : sc_effect)
    (history : List sc_effect) (w : sc_access_sequence_witness)
    (h : w ∈ List.foldr (fun right rest =>
      if sc_access_sequence_pair sb left right then
        ⟨left,right⟩ :: rest else rest) [] history) :
    w.sc_sequence_left = left ∧ w.sc_sequence_right ∈ history ∧
      sc_access_sequence_pair sb w.sc_sequence_left w.sc_sequence_right = true := by
  induction history with
  | nil => cases h
  | cons right rest ih =>
    simp only [List.foldr] at h
    cases hp : sc_access_sequence_pair sb left right with
    | false =>
      simp only [hp, Bool.false_eq_true, if_false] at h
      have ⟨hl,hr,pair⟩ := ih h
      exact ⟨hl,List.mem_cons_of_mem _ hr,pair⟩
    | true =>
      simp only [hp, if_true, List.mem_cons] at h
      rcases h with heq | h
      · cases heq
        exact ⟨rfl,List.mem_cons_self,hp⟩
      · have ⟨hl,hr,pair⟩ := ih h
        exact ⟨hl,List.mem_cons_of_mem _ hr,pair⟩

theorem emitted_pair (graph : sc_source_graph) (history : List sc_effect)
    (w : sc_access_sequence_witness)
    (h : w ∈ sc_access_sequence_witnesses graph history) :
    w.sc_sequence_left ∈ history ∧ w.sc_sequence_right ∈ history ∧
      sc_access_sequence_pair
        (set_tcByCmp (pairCompare defaultCompare defaultCompare) graph.sc_graph_sb)
        w.sc_sequence_left w.sc_sequence_right = true := by
  unfold sc_access_sequence_witnesses sc_access_sequence_witnesses_closed at h
  obtain ⟨part,partIn,wIn⟩ := List.mem_flatten.mp h
  obtain ⟨left,leftIn,rfl⟩ := List.mem_map.mp partIn
  rw [LemLibTheorems.lemListFoldr_eq] at wIn
  have ⟨hl,hr,pair⟩ := fold_spec _ left history w wIn
  exact ⟨hl ▸ leftIn,hr,pair⟩

theorem sc_not_non_atomic (lk : sc_ref_location → sc_ref_location_kind)
    (a : sc_ref_action) (hsc : sc_ref_is_seq_cst a = true)
    (hlk : sc_ref_action_respects_location_kinds () lk a = true) :
    sc_ref_is_at_non_atomic_location lk a = false := by
  cases a with
  | SCRef_Load id tid mo loc value =>
    cases mo <;> cases hk : lk loc <;>
      simp only [sc_ref_is_at_non_atomic_location, sc_ref_loc_of, hk] <;>
      simp only [sc_ref_action_respects_location_kinds, hk] at hlk <;>
      first | exact Bool.noConfusion hsc | exact Bool.noConfusion hlk | rfl
  | SCRef_Store id tid mo loc value =>
    cases mo <;> cases hk : lk loc <;>
      simp only [sc_ref_is_at_non_atomic_location, sc_ref_loc_of, hk] <;>
      simp only [sc_ref_action_respects_location_kinds, hk] at hlk <;>
      first | exact Bool.noConfusion hsc | exact Bool.noConfusion hlk | rfl
  | SCRef_RMW id tid mo loc before after =>
    cases hk : lk loc <;>
      simp only [sc_ref_is_at_non_atomic_location, sc_ref_loc_of, hk] <;>
      simp only [sc_ref_action_respects_location_kinds, hk] at hlk <;>
      first | exact Bool.noConfusion hlk | rfl
  | SCRef_Fence id tid mo => rfl
  | SCRef_Lock id tid loc outcome => cases hsc
  | SCRef_Unlock id tid loc => cases hsc
  | SCRef_Blocked_rmw id tid loc => cases hsc
  | SCRef_Alloc id tid loc => cases hsc
  | SCRef_Dealloc id tid loc => cases hsc

theorem global_kind_at (execution : sc_ref_pre_execution) (a : sc_ref_action)
    (ha : a ∈ setToList execution.sc_ref_actions)
    (h : sc_ref_actions_respect_location_kinds execution.sc_ref_actions
      execution.sc_ref_lk = true) :
    sc_ref_action_respects_location_kinds () execution.sc_ref_lk a = true := by
  unfold sc_ref_actions_respect_location_kinds setForAll at h
  exact (forAll_elements _ _).mp h a ha

-- This is a conditional connection. The current runtime has not established
-- these mapping obligations for all observed C objects and values.
theorem pair_violates_reference
    (sb : Pset (Nat × Nat)) (left right : sc_effect)
    (execution : sc_ref_pre_execution) (a b : sc_ref_action)
    (pair : sc_access_sequence_pair sb left right = true)
    (ha : a ∈ setToList execution.sc_ref_actions)
    (hb : b ∈ setToList execution.sc_ref_actions)
    (kinds : sc_ref_actions_respect_location_kinds execution.sc_ref_actions
      execution.sc_ref_lk = true)
    (thread : (sc_ref_tid_of a == sc_ref_tid_of b) =
      (left.sc_effect_request.sc_request_thread == right.sc_effect_request.sc_request_thread))
    (distinct : sc_ref_action_equality a b = (left.sc_effect_request.sc_request_id == right.sc_effect_request.sc_request_id))
    (scLeft : sc_observed_access_order left = some Seq_cst → sc_ref_is_seq_cst a = true)
    (scRight : sc_observed_access_order right = some Seq_cst → sc_ref_is_seq_cst b = true)
    (forward : setMemberBy
      (pairCompare (fun x y => defaultCompare (sc_ref_aid_of x) (sc_ref_aid_of y))
        (fun x y => defaultCompare (sc_ref_aid_of x) (sc_ref_aid_of y)))
      (a,b) execution.sc_ref_sb =
      setMemberBy (pairCompare defaultCompare defaultCompare)
        (left.sc_effect_id,right.sc_effect_id) sb)
    (backward : setMemberBy
      (pairCompare (fun x y => defaultCompare (sc_ref_aid_of x) (sc_ref_aid_of y))
        (fun x y => defaultCompare (sc_ref_aid_of x) (sc_ref_aid_of y)))
      (b,a) execution.sc_ref_sb =
      setMemberBy (pairCompare defaultCompare defaultCompare)
        (right.sc_effect_id,left.sc_effect_id) sb) :
    sc_ref_indeterminate_sequencing execution = false := by
  simp only [sc_access_sequence_pair, Bool.and_eq_true] at pair
  obtain ⟨_,ht,hd,hf,hback,hrole⟩ := pair
  have role : sc_observed_access_order left = some Seq_cst ∨
      sc_observed_access_order right = some Seq_cst := by
    split at hrole <;> try contradiction
    rename_i l r hl hr
    cases l <;> cases r <;>
      first | exact Or.inl hl | exact Or.inr hr | exact Bool.noConfusion hrole
  have nonAtomic : (sc_ref_is_at_non_atomic_location execution.sc_ref_lk a &&
      sc_ref_is_at_non_atomic_location execution.sc_ref_lk b) = false := by
    rcases role with hl | hr
    · rw [sc_not_non_atomic _ _ (scLeft hl) (global_kind_at execution a ha kinds)]
      rfl
    · rw [sc_not_non_atomic _ _ (scRight hr) (global_kind_at execution b hb kinds)]
      simp only [Bool.and_false]
  have hf0 := not_true _ hf
  have hb0 := not_true _ hback
  have violation : sc_reference_sequencing_violation execution a b = true := by
    simp only [sc_reference_sequencing_violation, thread, distinct, forward,
      backward, ht, hd, hf0, hb0, nonAtomic]
    rfl
  have present := witnesses_membership execution a b |>.mpr ⟨ha,hb,violation⟩
  cases h : sc_ref_indeterminate_sequencing execution with
  | false => rfl
  | true =>
    have empty := (witnesses_empty_iff_reference execution).mpr h
    rw [empty] at present
    cases present

end CerbSCAccessSequencing

namespace CerbCmmEquality
open Lem_Basic_classes

theorem reference_action_identity (a b : sc_ref_action) :
    isEqual a b = isEqual (sc_ref_aid_of a) (sc_ref_aid_of b) := rfl

theorem live_action_identity (a b : action) :
    isEqual a b = isEqual (aid_of a) (aid_of b) := rfl

theorem reference_pre_execution_instance (a b : sc_ref_pre_execution) :
    isEqual a b = sc_ref_pre_execution_equal a b := rfl

theorem live_pre_execution_instance (a b : pre_execution) :
    isEqual a b = pre_execution_equal a b := rfl

theorem reference_witness_instance (a b : sc_ref_execution_witness) :
    isEqual a b = sc_ref_execution_witness_equal a b := rfl

theorem live_witness_instance (a b : execution_witness) :
    isEqual a b = execution_witness_equal a b := rfl

end CerbCmmEquality
