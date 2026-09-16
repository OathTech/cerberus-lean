import S0_3_Traversal
set_option autoImplicit false

namespace PlanReview
open S0_3

def legacyThenStop (sp : interp_stop) (x st : Nat) : exceptM (t0 Nat × Nat) String :=
  if x = 0 then Result (Undef CerbLocation.Loc.unknown [], st)
  else if x = 1 then Result (Stopped sp, st + 1)
  else Exception "later"

def errorThenStop (sp : interp_stop) (x st : Nat) : exceptM (t0 Nat × Nat) String :=
  if x = 0 then Result (Error CerbLocation.Loc.unknown "ordinary", st)
  else Result (Stopped sp, st + 1)

def legacyThenDefined (x st : Nat) : exceptM (t0 Nat × Nat) String :=
  if x = 0 then Result (Undef CerbLocation.Loc.unknown [], st)
  else if x = 1 then Result (Defined x, st + 1)
  else Exception "later"

theorem candidate_hides_any_stop (sp : interp_stop) :
    mapM' (legacyThenStop sp) [0, 1, 2] 0 =
      Result (Undef CerbLocation.Loc.unknown [], 1) := by
  simp [mapM', collectS, stExpect_bind, stExpect_return, except_bind, except_return,
    legacyThenStop, mapM1, sequence0, lemListFoldr, bind2, return1]

theorem candidate_error_hides_any_stop (sp : interp_stop) :
    mapM' (errorThenStop sp) [0, 1] 0 =
      Result (Error CerbLocation.Loc.unknown "ordinary", 1) := by
  simp [mapM', collectS, stExpect_bind, stExpect_return, except_bind, except_return,
    errorThenStop, mapM1, sequence0, lemListFoldr, bind2, return1]

theorem current_layering_reaches_later_exception (sp : interp_stop) :
    stExceptUndef_mapM (legacyThenStop sp) [0, 1, 2] 0 = Exception "later" := by
  simp [stExceptUndef_mapM, stExpect_mapM, stExpect_bind,
    except_bind, legacyThenStop, lemListFoldr]

theorem replacing_stop_with_defined_changes_observation :
    mapM' legacyThenDefined [0, 1, 2] 0 = Exception "later" := by
  simp [mapM', collectS, stExpect_bind, except_bind, legacyThenDefined]

end PlanReview

#print axioms PlanReview.candidate_hides_any_stop
#print axioms PlanReview.candidate_error_hides_any_stop
#print axioms PlanReview.current_layering_reaches_later_exception
#print axioms PlanReview.replacing_stop_with_defined_changes_observation
