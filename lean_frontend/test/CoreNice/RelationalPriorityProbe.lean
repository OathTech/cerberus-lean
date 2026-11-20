import CoreNice.Core_reduction

namespace CoreNice.RelationalPriority

/-- The priority experiment preserves each candidate with its original focus,
context and multiplicity. This does not imply an identical eager transition. -/
theorem candidates_perm {α β γ δ : Type} (as : List annot) (group : generic_expr δ γ β)
    (xs : List (context × α)) : (nice_relational_priority as group xs).Perm xs := by
  unfold nice_relational_priority
  split
  · dsimp only
    split
    · exact List.filter_append_perm _ _
    · exact List.Perm.refl _
  · exact List.Perm.refl _

/-- Relational lowering owns the source-order tuple slots. Both actions keep
their full sibling context as the first candidate changes to the left action. -/
theorem marked_two_actions (atGroup atLeft atRight : List annot)
    (left right : generic_paction core_run_annotation Unit sym)
    (resultPattern : generic_pattern sym) (tail : expr core_run_annotation) :
    let l : expr core_run_annotation := .Expr atLeft (.Eaction left)
    let r : expr core_run_annotation := .Expr atRight (.Eaction right)
    let spec := [annot.Astd "§6.5.8"]
    get_ctx (.Expr spec (.Ewseq resultPattern (.Expr atGroup (.Eunseq [l, r])) tail)) =
      [(.Cwseq spec resultPattern (.Cunseq atGroup [] .CTX [r]) tail, l),
       (.Cwseq spec resultPattern (.Cunseq atGroup [l] .CTX []) tail, r)] := by
  rfl

#print axioms candidates_perm
#print axioms marked_two_actions

end CoreNice.RelationalPriority
