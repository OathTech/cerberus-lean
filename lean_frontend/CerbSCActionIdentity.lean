import Sc_action_identity
import CerbSCAccessGroups

set_option autoImplicit true

namespace CerbSCActionIdentity

-- Same actual Lem natural-key comparison proof as CerbSCScopes.
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


 theorem group_occurrences_preserved (group : sc_access_group) :
    (sc_group_aliases group).map sc_action_alias.sc_alias_occurrence =
      (sc_group_occurrences group).map sc_effect.sc_effect_id := by
  simp [sc_group_aliases, List.map_map]

 theorem all_group_occurrences_preserved (groups : List sc_access_group) :
    (sc_access_aliases groups).map sc_action_alias.sc_alias_occurrence =
      (sc_ungroup_accesses groups).map sc_effect.sc_effect_id := by
  induction groups with
  | nil => rfl
  | cons group rest ih =>
    change (sc_group_aliases group ++ sc_access_aliases rest).map _ =
      (sc_group_occurrences group ++ sc_ungroup_accesses rest).map _
    simp only [List.map_append, group_occurrences_preserved, ih]

 theorem actual_access_occurrences_preserved (history : List sc_effect) :
    (sc_access_aliases (sc_group_accesses history)).map sc_action_alias.sc_alias_occurrence =
      (sc_access_effects history).map sc_effect.sc_effect_id := by
  rw [all_group_occurrences_preserved, CerbSCAccessGroups.ungroup_exact]

 theorem group_anchor_preserved (group : sc_access_group) (entry : sc_action_alias)
    (h : entry ∈ sc_group_aliases group) : entry.sc_alias_action = sc_group_anchor group := by
  simp only [sc_group_aliases, List.mem_map] at h
  obtain ⟨observed, _, rfl⟩ := h
  rfl

 theorem lookup_action_origin (occurrence action : Nat) (aliases : List sc_action_alias) :
    action ∈ sc_lookup_actions occurrence aliases ↔
      ∃ entry ∈ aliases, entry.sc_alias_occurrence = occurrence ∧ entry.sc_alias_action = action := by
  simp only [sc_lookup_actions, List.mem_map, List.mem_filter, nat_key_eq_iff]
  constructor
  · rintro ⟨entry, ⟨present, same⟩, value⟩
    exact ⟨entry, present, same.symm, value⟩
  · rintro ⟨entry, present, same, value⟩
    exact ⟨entry, ⟨present, same.symm⟩, value⟩

 theorem lookup_occurrence_origin (occurrence action : Nat) (aliases : List sc_action_alias) :
    occurrence ∈ sc_lookup_occurrences action aliases ↔
      ∃ entry ∈ aliases, entry.sc_alias_action = action ∧ entry.sc_alias_occurrence = occurrence := by
  simp only [sc_lookup_occurrences, List.mem_map, List.mem_filter, nat_key_eq_iff]
  constructor
  · rintro ⟨entry, ⟨present, same⟩, value⟩
    exact ⟨entry, present, same.symm, value⟩
  · rintro ⟨entry, present, same, value⟩
    exact ⟨entry, ⟨present, same.symm⟩, value⟩

 theorem raw_edges_preserved (aliases : List sc_action_alias) (edges : List (Nat × Nat)) :
    (sc_project_action_edges aliases edges).map Prod.fst = edges := by
  induction edges with
  | nil => rfl
  | cons edge rest ih => exact congrArg (List.cons edge) ih

 theorem expansion_origin (aliases : List sc_action_alias) (source target left right : Nat) :
    (left,right) ∈ sc_expand_action_edge aliases (source,target) ↔
      left ∈ sc_lookup_occurrences source aliases ∧ right ∈ sc_lookup_occurrences target aliases := by
  simp only [sc_expand_action_edge, List.mem_flatten]
  constructor
  · rintro ⟨part, hp, he⟩
    obtain ⟨a, ha, rfl⟩ := List.mem_map.mp hp
    obtain ⟨b, hb, hpair⟩ := List.mem_map.mp he
    cases hpair
    exact ⟨ha,hb⟩
  · rintro ⟨hl,hr⟩
    refine ⟨_, List.mem_map.mpr ⟨left,hl,rfl⟩, ?_⟩
    exact List.mem_map.mpr ⟨right,hr,rfl⟩

 theorem internal_edge_explicit aliases source target action
    (h₁ : sc_lookup_actions source aliases = [action])
    (h₂ : sc_lookup_actions target aliases = [action]) :
    sc_project_action_edge aliases (source,target) = .SC_edge_within_action action := by
  simp [sc_project_action_edge, h₁, h₂, nat_key_eq_iff]

 theorem duplicate_mapping_explicit aliases source target action other
    (h₁ : sc_lookup_actions source aliases = [action,action])
    (h₂ : sc_lookup_actions target aliases = [other]) :
    sc_project_action_edge aliases (source,target) = .SC_edge_ambiguous_actions [action,action] [other] := by
  simp [sc_project_action_edge, h₁, h₂]

 theorem absent_edges_explicit aliases source target
    (h₁ : sc_lookup_actions source aliases = [])
    (h₂ : sc_lookup_actions target aliases = []) :
    sc_project_action_edge aliases (source,target) = .SC_edge_outside_actions none none := by
  simp [sc_project_action_edge, h₁, h₂]

end CerbSCActionIdentity


/- Proof vocabulary for the actual draft endpoint expansion. These are conditional
   adapter laws, not a replacement operational semantics or an HB checker. -/
namespace CerbSCActionIdentity

def AliasFunctional (aliases : List sc_action_alias) : Prop :=
  ∀ occurrence a b, occurrence ∈ sc_lookup_occurrences a aliases →
    occurrence ∈ sc_lookup_occurrences b aliases → a = b

def Expanded (aliases : List sc_action_alias) (relation : Nat → Nat → Prop)
    (left right : Nat) : Prop :=
  ∃ source target, relation source target ∧
    (left,right) ∈ sc_expand_action_edge aliases (source,target)

def Composed (first second : Nat → Nat → Prop) (left right : Nat) : Prop :=
  ∃ middle, first left middle ∧ second middle right

 theorem expanded_origin aliases relation left right :
    Expanded aliases relation left right ↔
    ∃ source target, relation source target ∧
      left ∈ sc_lookup_occurrences source aliases ∧
      right ∈ sc_lookup_occurrences target aliases := by
  simp only [Expanded, expansion_origin]

 theorem expanded_false aliases left right :
    ¬ Expanded aliases (fun _ _ => False) left right := by
  rintro ⟨_, _, h, _⟩
  exact h

 theorem expanded_union aliases first second left right :
    Expanded aliases (fun a b => first a b ∨ second a b) left right ↔
      Expanded aliases first left right ∨ Expanded aliases second left right := by
  constructor
  · rintro ⟨a, b, h | h, endpoints⟩
    · exact Or.inl ⟨a,b,h,endpoints⟩
    · exact Or.inr ⟨a,b,h,endpoints⟩
  · rintro (⟨a,b,h,endpoints⟩ | ⟨a,b,h,endpoints⟩)
    · exact ⟨a,b,Or.inl h,endpoints⟩
    · exact ⟨a,b,Or.inr h,endpoints⟩

-- Forward composition cannot accidentally join different reference actions at
-- one raw occurrence. The exact functionality hypothesis excludes that defect.
 theorem expanded_composition_forward aliases first second left right
    (functional : AliasFunctional aliases) :
    Composed (Expanded aliases first) (Expanded aliases second) left right →
      Expanded aliases (Composed first second) left right := by
  rintro ⟨middle, h₁, h₂⟩
  obtain ⟨a,b,hab,hl,hm₁⟩ := (expanded_origin _ _ _ _).mp h₁
  obtain ⟨c,d,hcd,hm₂,hr⟩ := (expanded_origin _ _ _ _).mp h₂
  have same : b = c := functional middle b c hm₁ hm₂
  cases same
  exact (expanded_origin _ _ _ _).mpr ⟨a,d,⟨b,hab,hcd⟩,hl,hr⟩

-- Reverse composition needs a representative only for intermediate actions
-- that actually join these two relations, not for every natural identifier.
 theorem expanded_composition_backward aliases first second left right
    (covered : ∀ a b c, first a b → second b c →
      ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases) :
    Expanded aliases (Composed first second) left right →
      Composed (Expanded aliases first) (Expanded aliases second) left right := by
  intro h
  obtain ⟨a,c,⟨b,hab,hbc⟩,hl,hr⟩ := (expanded_origin _ _ _ _).mp h
  obtain ⟨middle,hm⟩ := covered a b c hab hbc
  exact ⟨middle,(expanded_origin _ _ _ _).mpr ⟨a,b,hab,hl,hm⟩,
    (expanded_origin _ _ _ _).mpr ⟨b,c,hbc,hm,hr⟩⟩

 theorem expanded_composition_iff aliases first second left right
    (functional : AliasFunctional aliases)
    (covered : ∀ a b c, first a b → second b c →
      ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases) :
    Composed (Expanded aliases first) (Expanded aliases second) left right ↔
      Expanded aliases (Composed first second) left right :=
  ⟨expanded_composition_forward _ _ _ _ _ functional,
    expanded_composition_backward _ _ _ _ _ covered⟩

 theorem lookup_duality aliases occurrence action :
    action ∈ sc_lookup_actions occurrence aliases ↔
      occurrence ∈ sc_lookup_occurrences action aliases := by
  rw [lookup_action_origin, lookup_occurrence_origin]
  constructor
  · rintro ⟨entry,present,ho,ha⟩
    exact ⟨entry,present,ha,ho⟩
  · rintro ⟨entry,present,ha,ho⟩
    exact ⟨entry,present,ho,ha⟩

 theorem single_mapping_functional aliases
    (single : ∀ occurrence, (sc_lookup_actions occurrence aliases).length ≤ 1) :
    AliasFunctional aliases := by
  intro occurrence a b ha hb
  have ma := (lookup_duality aliases occurrence a).mpr ha
  have mb := (lookup_duality aliases occurrence b).mpr hb
  have bound := single occurrence
  cases h : sc_lookup_actions occurrence aliases with
  | nil => simp only [h,List.not_mem_nil] at ma
  | cons first rest =>
    cases rest with
    | nil =>
      have ea : a = first := by simpa only [h,List.mem_singleton] using ma
      have eb : b = first := by simpa only [h,List.mem_singleton] using mb
      exact ea.trans eb.symm
    | cons second tail => simp only [h,List.length_cons] at bound; omega

 theorem group_anchor_covered group :
    sc_group_anchor group ∈ sc_lookup_occurrences (sc_group_anchor group)
      (sc_group_aliases group) := by
  apply (lookup_occurrence_origin _ _ _).mpr
  cases group with
  | SC_access_single e =>
    exact ⟨⟨e.sc_effect_id,e.sc_effect_id⟩,by simp [sc_group_aliases,sc_group_occurrences,sc_group_anchor],rfl,rfl⟩
  | SC_access_atomic_pair r w =>
    exact ⟨⟨r.sc_effect_id,r.sc_effect_id⟩,by simp [sc_group_aliases,sc_group_occurrences,sc_group_anchor],rfl,rfl⟩

 theorem access_group_anchor_covered groups group (present : group ∈ groups) :
    sc_group_anchor group ∈ sc_lookup_occurrences (sc_group_anchor group)
      (sc_access_aliases groups) := by
  obtain ⟨entry,hin,ha,ho⟩ := (lookup_occurrence_origin _ _ _).mp (group_anchor_covered group)
  apply (lookup_occurrence_origin _ _ _).mpr
  refine ⟨entry,?_,ha,ho⟩
  exact List.mem_flatten.mpr ⟨sc_group_aliases group,List.mem_map.mpr ⟨group,present,rfl⟩,hin⟩

end CerbSCActionIdentity


/- Closure laws of the actual alias expansion. Relation.TransGen is only the
   mathematical path predicate here; no Lem Pset.tc correctness is assumed. -/
namespace CerbSCActionIdentity

 theorem expanded_closure_forward aliases relation left right
    (functional : AliasFunctional aliases) :
    Relation.TransGen (Expanded aliases relation) left right →
      Expanded aliases (Relation.TransGen relation) left right := by
  intro path
  induction path with
  | single edge =>
    obtain ⟨a,b,hab,hl,hr⟩ := (expanded_origin _ _ _ _).mp edge
    exact (expanded_origin _ _ _ _).mpr ⟨a,b,Relation.TransGen.single hab,hl,hr⟩
  | tail _ edge ih =>
    obtain ⟨a,b,hab,hl,hm₁⟩ := (expanded_origin _ _ _ _).mp ih
    obtain ⟨c,d,hcd,hm₂,hr⟩ := (expanded_origin _ _ _ _).mp edge
    have same := functional _ b c hm₁ hm₂
    cases same
    exact (expanded_origin _ _ _ _).mpr ⟨a,d,Relation.TransGen.tail hab hcd,hl,hr⟩

 theorem expanded_closure_backward aliases relation left right
    (covered : ∀ a b c, Relation.TransGen relation a b → relation b c →
      ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases) :
    Expanded aliases (Relation.TransGen relation) left right →
      Relation.TransGen (Expanded aliases relation) left right := by
  intro h
  obtain ⟨a,c,path,hl,hr⟩ := (expanded_origin _ _ _ _).mp h
  clear h
  induction path generalizing left right with
  | single edge =>
    exact Relation.TransGen.single ((expanded_origin _ _ _ _).mpr ⟨_,_,edge,hl,hr⟩)
  | tail path edge ih =>
    obtain ⟨middle,hm⟩ := covered _ _ _ path edge
    exact Relation.TransGen.tail (ih left middle hl hm)
      ((expanded_origin _ _ _ _).mpr ⟨_,_,edge,hm,hr⟩)

 theorem expanded_closure_iff aliases relation left right
    (functional : AliasFunctional aliases)
    (covered : ∀ a b c, Relation.TransGen relation a b → relation b c →
      ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases) :
    Relation.TransGen (Expanded aliases relation) left right ↔
      Expanded aliases (Relation.TransGen relation) left right :=
  ⟨expanded_closure_forward _ _ _ _ functional,
    expanded_closure_backward _ _ _ _ covered⟩

 theorem expanded_cycle_origin aliases relation occurrence
    (functional : AliasFunctional aliases)
    (cycle : Relation.TransGen (Expanded aliases relation) occurrence occurrence) :
    ∃ action, occurrence ∈ sc_lookup_occurrences action aliases ∧
      Relation.TransGen relation action action := by
  obtain ⟨a,b,path,hl,hr⟩ := (expanded_origin _ _ _ _).mp
    (expanded_closure_forward _ _ _ _ functional cycle)
  have same := functional occurrence a b hl hr
  cases same
  exact ⟨a,hl,path⟩

 theorem expanded_cycle_retained aliases relation action occurrence
    (covered : ∀ a b c, Relation.TransGen relation a b → relation b c →
      ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases)
    (representative : occurrence ∈ sc_lookup_occurrences action aliases)
    (cycle : Relation.TransGen relation action action) :
    Relation.TransGen (Expanded aliases relation) occurrence occurrence :=
  expanded_closure_backward _ _ _ _ covered
    ((expanded_origin _ _ _ _).mpr ⟨action,action,cycle,representative,representative⟩)

end CerbSCActionIdentity

/- Mathematical all-vertex composition through the actual occurrence aliases.
   The source relation is already transitively closed before endpoint projection.
   Neither these hypotheses nor Relation.TransGen are a Pset.tc theorem. -/
namespace CerbSCActionIdentity

private def ReferencePrefix (aliases : List sc_action_alias)
    (source reference : Nat → Nat → Prop) (action start finish : Nat) : Prop :=
  source start finish ∨ ∃ b endpoint,
    Relation.TransGen reference action b ∧
    endpoint ∈ sc_lookup_occurrences b aliases ∧
    (endpoint = finish ∨ source endpoint finish)

private theorem all_vertex_prefix
    (aliases : List sc_action_alias) (source sourceRef sync : Nat → Nat → Prop)
    (functional : AliasFunctional aliases)
    (source_trans : ∀ {a b c}, source a b → source b c → source a c)
    (project : ∀ a b left right,
      left ∈ sc_lookup_occurrences a aliases →
      right ∈ sc_lookup_occurrences b aliases → source left right → sourceRef a b)
    (action left right : Nat) (initial : left ∈ sc_lookup_occurrences action aliases)
    (path : Relation.TransGen (fun a b => source a b ∨ Expanded aliases sync a b) left right) :
    ReferencePrefix aliases source (fun a b => sourceRef a b ∨ sync a b) action left right := by
  induction path with
  | single edge =>
    rcases edge with plain | synchronization
    · exact Or.inl plain
    · obtain ⟨a,b,hab,hl,hr⟩ := (expanded_origin _ _ _ _).mp synchronization
      have same := functional _ action a initial hl
      cases same
      exact Or.inr ⟨b,_,Relation.TransGen.single (Or.inr hab),hr,Or.inl rfl⟩
  | tail _ edge ih =>
    rcases edge with plain | synchronization
    · rcases ih with prior | ⟨b,endpoint,refpath,hendpoint,rest⟩
      · exact Or.inl (source_trans prior plain)
      · refine Or.inr ⟨b,endpoint,refpath,hendpoint,Or.inr ?_⟩
        rcases rest with same | prior
        · cases same; exact plain
        · exact source_trans prior plain
    · obtain ⟨a,b,hab,hl,hr⟩ := (expanded_origin _ _ _ _).mp synchronization
      have refPrefixProof : Relation.TransGen (fun a b => sourceRef a b ∨ sync a b) action a := by
        rcases ih with prior | ⟨c,endpoint,refpath,hendpoint,rest⟩
        · exact Relation.TransGen.single (Or.inl (project _ _ _ _ initial hl prior))
        · rcases rest with same | prior
          · cases same
            have sameAction := functional _ c a hendpoint hl
            cases sameAction
            exact refpath
          · exact Relation.TransGen.tail refpath (Or.inl (project _ _ _ _ hendpoint hl prior))
      exact Or.inr ⟨b,_,Relation.TransGen.tail refPrefixProof (Or.inr hab),hr,Or.inl rfl⟩

/-- Source-only paths through omitted metadata vertices still reach the
reference endpoints; no intermediate vertex needs an action alias. -/
theorem all_vertex_closure_forward
    (aliases : List sc_action_alias) (source sourceRef sync : Nat → Nat → Prop)
    (functional : AliasFunctional aliases)
    (source_trans : ∀ {a b c}, source a b → source b c → source a c)
    (project : ∀ a b left right,
      left ∈ sc_lookup_occurrences a aliases →
      right ∈ sc_lookup_occurrences b aliases → source left right → sourceRef a b)
    (a b left right : Nat)
    (hl : left ∈ sc_lookup_occurrences a aliases)
    (hr : right ∈ sc_lookup_occurrences b aliases)
    (path : Relation.TransGen (fun x y => source x y ∨ Expanded aliases sync x y) left right) :
    Relation.TransGen (fun x y => sourceRef x y ∨ sync x y) a b := by
  have refPrefixProof := all_vertex_prefix aliases source sourceRef sync functional source_trans
    project a left right hl path
  rcases refPrefixProof with plain | ⟨c,endpoint,refpath,hendpoint,rest⟩
  · exact Relation.TransGen.single (Or.inl (project _ _ _ _ hl hr plain))
  · rcases rest with same | plain
    · cases same
      have sameAction := functional _ c b hendpoint hr
      cases sameAction
      exact refpath
    · exact Relation.TransGen.tail refpath (Or.inl (project _ _ _ _ hendpoint hr plain))

/-- The converse needs source order for every representative of each reference
edge, and a representative for every intermediate action on this path. -/
theorem all_vertex_closure_backward
    (aliases : List sc_action_alias) (source sourceRef sync : Nat → Nat → Prop)
    (lift : ∀ a b left right, sourceRef a b →
      left ∈ sc_lookup_occurrences a aliases →
      right ∈ sc_lookup_occurrences b aliases → source left right)
    (covered : ∀ a b c, Relation.TransGen (fun x y => sourceRef x y ∨ sync x y) a b →
      (sourceRef b c ∨ sync b c) → ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases)
    (a b left right : Nat)
    (hl : left ∈ sc_lookup_occurrences a aliases)
    (hr : right ∈ sc_lookup_occurrences b aliases)
    (path : Relation.TransGen (fun x y => sourceRef x y ∨ sync x y) a b) :
    Relation.TransGen (fun x y => source x y ∨ Expanded aliases sync x y) left right := by
  have expanded : Expanded aliases (Relation.TransGen (fun x y => sourceRef x y ∨ sync x y)) left right :=
    (expanded_origin _ _ _ _).mpr ⟨a,b,path,hl,hr⟩
  have physical := expanded_closure_backward aliases _ left right covered expanded
  have step : ∀ x y, Expanded aliases (fun a b => sourceRef a b ∨ sync a b) x y →
      source x y ∨ Expanded aliases sync x y := by
    intro x y h
    obtain ⟨a,b,edge,hx,hy⟩ := (expanded_origin _ _ _ _).mp h
    rcases edge with plain | synchronization
    · exact Or.inl (lift _ _ _ _ plain hx hy)
    · exact Or.inr ((expanded_origin _ _ _ _).mpr ⟨a,b,synchronization,hx,hy⟩)
  clear expanded path hl hr
  induction physical with
  | single edge => exact Relation.TransGen.single (step _ _ edge)
  | tail _ edge ih => exact Relation.TransGen.tail ih (step _ _ edge)

 theorem all_vertex_closure_iff
    (aliases : List sc_action_alias) (source sourceRef sync : Nat → Nat → Prop)
    (functional : AliasFunctional aliases)
    (source_trans : ∀ {a b c}, source a b → source b c → source a c)
    (project : ∀ a b left right,
      left ∈ sc_lookup_occurrences a aliases →
      right ∈ sc_lookup_occurrences b aliases → source left right → sourceRef a b)
    (lift : ∀ a b left right, sourceRef a b →
      left ∈ sc_lookup_occurrences a aliases →
      right ∈ sc_lookup_occurrences b aliases → source left right)
    (covered : ∀ a b c, Relation.TransGen (fun x y => sourceRef x y ∨ sync x y) a b →
      (sourceRef b c ∨ sync b c) → ∃ occurrence, occurrence ∈ sc_lookup_occurrences b aliases)
    (a b left right : Nat)
    (hl : left ∈ sc_lookup_occurrences a aliases)
    (hr : right ∈ sc_lookup_occurrences b aliases) :
    Relation.TransGen (fun x y => source x y ∨ Expanded aliases sync x y) left right ↔
      Relation.TransGen (fun x y => sourceRef x y ∨ sync x y) a b :=
  ⟨all_vertex_closure_forward aliases source sourceRef sync functional source_trans project a b left right hl hr,
    all_vertex_closure_backward aliases source sourceRef sync lift covered a b left right hl hr⟩

end CerbSCActionIdentity

namespace CerbSCActionIdentity
/-- Closing source/spawn/join edges first leaves HB unchanged when the selected
reference synchronization already includes every spawn/join edge. -/
theorem source_closure_absorbed
    (source spawn sync : Nat → Nat → Prop)
    (included : ∀ a b, spawn a b → sync a b) (left right : Nat) :
    Relation.TransGen (fun a b => Relation.TransGen (fun x y => source x y ∨ spawn x y) a b ∨ sync a b) left right ↔
      Relation.TransGen (fun a b => source a b ∨ sync a b) left right := by
  have sourcePath : ∀ a b, Relation.TransGen (fun x y => source x y ∨ spawn x y) a b →
      Relation.TransGen (fun x y => source x y ∨ sync x y) a b := by
    intro a b path
    induction path with
    | single edge =>
      exact Relation.TransGen.single (edge.elim Or.inl (fun h => Or.inr (included _ _ h)))
    | tail _ edge ih =>
      exact Relation.TransGen.tail ih (edge.elim Or.inl (fun h => Or.inr (included _ _ h)))
  constructor
  · intro path
    induction path with
    | single edge => exact edge.elim (sourcePath _ _) (fun h => Relation.TransGen.single (Or.inr h))
    | tail _ edge ih =>
      exact edge.elim (fun h => Relation.TransGen.trans ih (sourcePath _ _ h))
        (fun h => Relation.TransGen.tail ih (Or.inr h))
  · intro path
    induction path with
    | single edge =>
      exact Relation.TransGen.single (edge.elim (fun h => Or.inl (Relation.TransGen.single (Or.inl h))) Or.inr)
    | tail _ edge ih =>
      exact Relation.TransGen.tail ih (edge.elim (fun h => Or.inl (Relation.TransGen.single (Or.inl h))) Or.inr)
end CerbSCActionIdentity
