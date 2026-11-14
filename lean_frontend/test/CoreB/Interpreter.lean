import Core_eval
import CoreB.Core_eval
import PipelineA
import PipelineB

/- A small equation over the actual B evaluator. This demonstrates the proof
   interface; it is not a correspondence theorem between the two machines. -/
namespace CoreBInterpreterTests

#check_failure (fun (e : pexpr) => (show CoreB.pexpr from e))
#check_failure (fun (s : driver_state) => (show CoreB.driver_state from s))

theorem value_step [LemFuel]
    (enums : Fmap sym integerType)
    (tags : Fmap sym (CerbLocation.Loc × tag_definition))
    (n : Nat) (loc : CerbLocation.Loc) (parent : Option CerbLocation.Loc)
    (externs : Fmap sym sym) (env : List (Fmap sym CoreB.value))
    (mem : Option CerbMem.MemState)
    (file : CoreB.generic_file Unit CoreB.core_run_annotation)
    (constrained : Bool) (value : CoreB.value) (fuel : Nat) :
    CoreB.step_eval_pexpr_lemFuel (fuel + 1) enums tags n loc parent externs env
      mem file constrained (.Pexpr [] () (.PEval value)) =
      exception_undef_return (.Pexpr [] () (.PEval value)) := rfl

#print axioms value_step

end CoreBInterpreterTests
