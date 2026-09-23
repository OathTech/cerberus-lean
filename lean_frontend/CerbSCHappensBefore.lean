import Sc_happens_before
import CerbSCActionIdentity

set_option autoImplicit true

/- Laws over the generated query, including its actual diagnostic propagation.
   This does not assert a Cmm SW/RF producer or a general Pset.tc theorem. -/
namespace CerbSCHappensBefore
 theorem source_retained graph aliases synchronization :
    (sc_build_happens_before graph aliases synchronization).sc_hb_source = graph := rfl
 theorem aliases_retained graph aliases synchronization :
    (sc_build_happens_before graph aliases synchronization).sc_hb_aliases = aliases := rfl
 theorem synchronization_retained graph aliases synchronization :
    ((sc_build_happens_before graph aliases synchronization).sc_hb_sync_receipts).map Prod.fst = synchronization := by
  change (synchronization.map (fun edge => (edge, sc_expand_action_edge aliases edge))).map Prod.fst = _
  simp only [List.map_map, Function.comp_def, List.map_id']
 theorem actual_closure graph aliases synchronization :
    (sc_build_happens_before graph aliases synchronization).sc_hb_relation =
      set_tcByCmp (Lem_Basic_classes.pairCompare defaultCompare defaultCompare)
        (setUnionBy (Lem_Basic_classes.pairCompare defaultCompare defaultCompare) graph.sc_graph_sbasw
          (sc_build_happens_before graph aliases synchronization).sc_hb_lifted_sync) := rfl
 theorem alias_issue_retained graph aliases synchronization issue
    (present : issue ∈ sc_hb_alias_issues graph aliases) :
    issue ∈ (sc_build_happens_before graph aliases synchronization).sc_hb_issues :=
  List.mem_append_left _ present
 theorem sync_issue_retained graph aliases synchronization edge issue
    (edge_present : edge ∈ synchronization)
    (issue_present : issue ∈ sc_hb_sync_issues aliases edge) :
    issue ∈ (sc_build_happens_before graph aliases synchronization).sc_hb_issues := by
  apply List.mem_append_right
  exact List.mem_flatten.mpr ⟨sc_hb_sync_issues aliases edge,
    List.mem_map.mpr ⟨edge,edge_present,rfl⟩,issue_present⟩
 theorem missing_source_reported aliases source target
    (absent : sc_lookup_occurrences source aliases = []) :
    SC_hb_missing_reference_source source target ∈ sc_hb_sync_issues aliases (source,target) := by
  unfold sc_hb_sync_issues
  apply List.mem_append_left
  simp only [absent, List.isEmpty_nil, ↓reduceIte, List.mem_singleton]
 theorem missing_target_reported aliases source target
    (absent : sc_lookup_occurrences target aliases = []) :
    SC_hb_missing_reference_target source target ∈ sc_hb_sync_issues aliases (source,target) := by
  unfold sc_hb_sync_issues
  apply List.mem_append_right
  simp only [absent, List.isEmpty_nil, ↓reduceIte, List.mem_singleton]
end CerbSCHappensBefore

/- Conditional path stability, with the obligations on actual graph extensions
   explicit. This is not a theorem that the Driver establishes those premises,
   nor a replacement definition for LemLib's executable transitive closure. -/
namespace CerbSCHappensBefore.Prefix

theorem earlier_path (prior : α → Prop) (earlier later : α → α → Prop)
    (incoming : ∀ a b, later a b → prior b → prior a)
    (old_edge : ∀ a b, prior a → prior b → later a b → earlier a b)
    (left right : α) (path : Relation.TransGen later left right) :
    prior right → Relation.TransGen earlier left right := by
  induction path with
  | single edge =>
    intro oldRight
    exact Relation.TransGen.single
      (old_edge _ _ (incoming _ _ edge oldRight) oldRight edge)
  | tail _ edge ih =>
    intro oldRight
    have oldMiddle := incoming _ _ edge oldRight
    exact Relation.TransGen.tail (ih oldMiddle)
      (old_edge _ _ oldMiddle oldRight edge)

theorem retained_path (earlier later : α → α → Prop)
    (retained : ∀ a b, earlier a b → later a b)
    (left right : α) (path : Relation.TransGen earlier left right) :
    Relation.TransGen later left right := by
  induction path with
  | single edge => exact Relation.TransGen.single (retained _ _ edge)
  | tail _ edge ih => exact Relation.TransGen.tail ih (retained _ _ edge)

theorem closure_unchanged (prior : α → Prop) (earlier later : α → α → Prop)
    (incoming : ∀ a b, later a b → prior b → prior a)
    (old_edge : ∀ a b, prior a → prior b → later a b → earlier a b)
    (retained : ∀ a b, earlier a b → later a b)
    (left right : α) (oldRight : prior right) :
    Relation.TransGen later left right ↔ Relation.TransGen earlier left right :=
  ⟨fun path => earlier_path prior earlier later incoming old_edge left right path oldRight,
   retained_path earlier later retained left right⟩

theorem unordered_unchanged (prior : α → Prop) (earlier later : α → α → Prop)
    (incoming : ∀ a b, later a b → prior b → prior a)
    (old_edge : ∀ a b, prior a → prior b → later a b → earlier a b)
    (retained : ∀ a b, earlier a b → later a b)
    (left right : α) (oldLeft : prior left) (oldRight : prior right) :
    (¬ Relation.TransGen later left right ∧ ¬ Relation.TransGen later right left) ↔
      (¬ Relation.TransGen earlier left right ∧ ¬ Relation.TransGen earlier right left) := by
  rw [closure_unchanged prior earlier later incoming old_edge retained left right oldRight,
      closure_unchanged prior earlier later incoming old_edge retained right left oldLeft]

end CerbSCHappensBefore.Prefix
