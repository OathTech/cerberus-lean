import Core_reduction_auxiliary
import CerbMem_lemMeasureProofs

set_option autoImplicit false

open Core_reduction_lemMeasureProofs
open CerbCoreMeasure

-- Landing improvement (orchestrator review, 2026-09-08): the measure is the
-- NAMED structural definition `CerbCoreMeasure.getCtxBound` (seam
-- CerbCoreMeasure.lean), not a macro-expanded `CerbTagsWf.callBoundEntry`
-- term; the pins below are now the same constant on both sides.
-- Pin the raw generated measures to the named proof measures by definitional equality.
example (e : generic_expr core_run_annotation Unit sym) :
    get_ctx e = get_ctx_lemFuel (getCtxBound (.inl e)) e := by rfl

example (annot1 : List annot)
    (acc : List (context × generic_expr core_run_annotation Unit sym))
    (es1 l : List (generic_expr core_run_annotation Unit sym)) :
    get_ctx_unseq_aux annot1 acc es1 l =
      get_ctx_unseq_aux_lemFuel (getCtxBound (.inr l)) annot1 acc es1 l := by rfl

#print axioms CerbCoreMeasure.getCtxBound
#print axioms CerbCoreMeasure.getCtxBound_pos
#print axioms CerbCoreMeasure.getCtxBound_child_lt
#print axioms Core_reduction_lemMeasureProofs.get_ctx_search_stable_aux
#print axioms Core_reduction_lemMeasureProofs.get_ctx_measure_sufficient
#print axioms Core_reduction_lemMeasureProofs.get_ctx_unseq_aux_measure_sufficient
#print axioms Core_reduction_lemMeasureProofs.get_ctx_previous_measure_eq
#print axioms Core_reduction_lemMeasureProofs.get_ctx_unseq_aux_previous_measure_eq
#print axioms CerbMem.alignofCtype_measure_sufficient
#print axioms CerbMem.sizeofCtype_measure_sufficient
#print axioms CerbMem.memberAlign_measure_sufficient
#print axioms CerbMem.offsetsofMembers_measure_sufficient
#print axioms CerbMem.offsetsof_measure_sufficient
#print axioms CerbMem.reconstructValue_measure_sufficient

-- Preserve the consumer's definitional reduction at value contexts (a
-- structural definition reduces by `rfl`; no unrolled entry frame needed).
example (v : value) : get_ctx (mk_value_e v) = [(CTX, mk_value_e v)] := by rfl
example (v : value) : CerbCoreMeasure.getCtxBound (.inl (mk_value_e v)) = 1 := by rfl
