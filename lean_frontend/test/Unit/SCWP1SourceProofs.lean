import Unit.SCWP1ContextProofs

/-! Local Core-to-reference link for the actual production unseq reduction.
    The specification speaks about conflicting annotations in different
    operands. It is independent of fold order and has no scheduler-time edge.
    The exclusion predicates interpret Core's negative-hoisting protocol;
    relating all reachable annotations to C source sb remains S2's obligation.
    This theorem does not replace that global simulation. -/
namespace SCWP1SourceProofs

def footprint : dyn_annotation → CerbMem.Footprint
  | .DA_pos _ fp | .DA_neg _ _ fp => fp
def exclusions : dyn_annotation → List Nat
  | .DA_pos xs _ | .DA_neg _ xs _ => xs
def negative : dyn_annotation → Option Nat
  | .DA_pos .. => none | .DA_neg id .. => some id
def Excluded (a b : dyn_annotation) : Prop :=
  ∃ n, negative a = some n ∧ n ∈ exclusions b
def Conflict (a b : dyn_annotation) : Prop :=
  CerbMem.overlapping (footprint a) (footprint b) = true ∧
    ¬ Excluded a b ∧ ¬ Excluded b a
def Races (xs ys : List dyn_annotation) : Prop := ∃ a ∈ xs, ∃ b ∈ ys, Conflict a b

theorem member_nat (n : Nat) (xs : List Nat) : Lem_List.elem n xs = true ↔ n ∈ xs := by
  induction xs with
  | nil => simp [Lem_List.elem, listMemberBy]
  | cons x xs ih =>
    simp only [Lem_List.elem, listMemberBy, Bool.or_eq_true] at *
    rw [List.mem_cons]
    apply or_congr _ ih
    change Lem_Basic_classes.orderingIsEqual (defaultCompare n x) = true ↔ n = x
    have eq := @Nat.compare_eq_eq n x
    cases hc : compare n x <;> simp_all [defaultCompare, Lem_Basic_classes.orderingIsEqual]

theorem member_nat_false (n : Nat) (xs : List Nat) : Lem_List.elem n xs = false ↔ n ∉ xs := by
  rw [Bool.eq_false_iff]
  exact not_congr (member_nat n xs)


theorem race_iff (xs ys : List dyn_annotation) : do_race xs ys = true ↔ Races xs ys := by
  simp only [do_race, List.any_eq_true, Races]
  apply exists_congr; intro a
  apply and_congr_right; intro _
  cases a <;> simp only [List.any_eq_true]
  all_goals apply exists_congr; intro b; apply and_congr_right; intro _
  all_goals cases b <;> simp [Conflict, Excluded, footprint, exclusions, negative, member_nat, member_nat_false, and_comm]

theorem races_append (xs ys zs : List dyn_annotation) :
    Races xs (ys ++ zs) ↔ Races xs ys ∨ Races xs zs := by
  simp only [Races, List.mem_append]
  constructor
  · rintro ⟨a,ha,b,hb,hc⟩
    rcases hb with hb | hb
    · exact Or.inl ⟨a,ha,b,hb,hc⟩
    · exact Or.inr ⟨a,ha,b,hb,hc⟩
  · rintro (⟨a,ha,b,hb,hc⟩ | ⟨a,ha,b,hb,hc⟩)
    · exact ⟨a,ha,b,Or.inl hb,hc⟩
    · exact ⟨a,ha,b,Or.inr hb,hc⟩

def annotated (p : List dyn_annotation × value) : expr core_run_annotation :=
  Expr [] (Eannot p.1 (mk_value_e p.2))

/-- Pairwise conflicts across distinct completed operands, and conflicts
    against a preexisting accumulator. No within-operand conflict is added. -/
def Safe (acc : List dyn_annotation) : List (List dyn_annotation × value) → Prop
  | [] => True
  | (fps,_) :: rest => ¬ Races fps acc ∧ Safe (fps ++ acc) rest

/-- An order-independent pairwise contract over operand positions. The list
    order just chooses one orientation of each pair; it adds no causal edge. -/
theorem safe_pairwise (es : List (List dyn_annotation × value)) (acc : List dyn_annotation) :
    Safe acc es ↔ (∀ e ∈ es, ¬ Races e.1 acc) ∧
      es.Pairwise (fun earlier later => ¬ Races later.1 earlier.1) := by
  induction es generalizing acc with
  | nil => simp [Safe]
  | cons e es ih =>
    obtain ⟨fps,v⟩ := e
    simp [Safe, ih, races_append, List.pairwise_cons, not_or, forall_and,
      and_assoc, and_left_comm, and_comm]

/-- Arbitrarily many completed operands and arbitrary footprints, values and
    exclusion sets: the production measured fold succeeds iff the relational
    operand contract is safe. No execution predicate is assumed. -/
theorem unseq_success (es : List (List dyn_annotation × value))
    (acc : List dyn_annotation) (vs : List value) :
    (one_step_unseq_aux (acc,vs) (es.map annotated)).isSome = true ↔ Safe acc es := by
  unfold one_step_unseq_aux
  simp only [List.length_map]
  induction es generalizing acc vs with
  | nil => simp [one_step_unseq_aux_lemFuel, Safe]
  | cons e es ih =>
    obtain ⟨fps,v⟩ := e
    simp only [List.length_cons, List.map_cons, annotated, mk_value_e, mk_pure_e, mk_value_pe]
    rw [one_step_unseq_aux_lemFuel]
    simp only [Safe]
    cases h : do_race fps acc with
    | false =>
      have hn : ¬ Races fps acc := by rw [← race_iff, h]; simp
      simpa [h, hn, combine_dyn_annotations] using ih (fps ++ acc) (v :: vs)
    | true =>
      have hr : Races fps acc := (race_iff fps acc).mp h
      simp [h, hr]

theorem unseq_pairwise (es : List (List dyn_annotation × value)) :
    (one_step_unseq_aux ([],[]) (es.map annotated)).isSome = true ↔
      es.Pairwise (fun earlier later => ¬ Races later.1 earlier.1) := by
  rw [unseq_success, safe_pairwise]
  simp [Races]

def exclude (n : Nat) : dyn_annotation → dyn_annotation
  | .DA_pos xs fp => .DA_pos (n :: xs) fp
  | .DA_neg id xs fp => .DA_neg id (n :: xs) fp

def ancestors : context → List dyn_annotation
  | .CTX => []
  | .Cunseq _ _ c _ | .Cwseq _ _ c _ | .Csseq _ _ c _ | .Cbound _ c => ancestors c
  | .Cannot _ xs c => xs ++ ancestors c

/-- The actual negative-hoisting transformation tags exactly the annotations
    on the selected context path; it does not tag a sibling operand. -/
theorem hoisting_ancestors (n : Nat) (c : context) :
    ancestors (add_exclusion n c) = (ancestors c).map (exclude n) := by
  induction c <;> simp_all [ancestors, add_exclusion, exclude, List.map_append]
  intro a _; cases a <;> rfl

theorem hoisting_excludes_prior (n : Nat) (fp : CerbMem.Footprint) (c : context) :
    do_race [.DA_neg n [] fp] (ancestors (add_exclusion n c)) = false := by
  rw [Bool.eq_false_iff]
  intro hr
  obtain ⟨a,ha,b,hb,hc⟩ := (race_iff _ _).mp hr
  have : a = .DA_neg n [] fp := by simpa using ha
  subst a
  rw [hoisting_ancestors] at hb
  obtain ⟨b,hb,rfl⟩ := List.mem_map.mp hb
  have hx : Excluded (.DA_neg n [] fp) (exclude n b) := by
    cases b <;> simp [Excluded, exclude, exclusions, negative]
  exact hc.2.1 hx

#print axioms race_iff
#print axioms unseq_success
#print axioms unseq_pairwise
#print axioms hoisting_excludes_prior
end SCWP1SourceProofs
