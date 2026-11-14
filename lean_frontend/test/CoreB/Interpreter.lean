import Core_eval
import CoreB.Core_eval
import PipelineA
import PipelineB
import Lean.Util.FoldConsts
import Lean.Elab.Command

/- A small equation over the actual B evaluator. This demonstrates the proof
   interface; it is not a correspondence theorem between the two machines. -/
namespace CoreBInterpreterTests

#check_failure (fun (e : pexpr) => (show CoreB.pexpr from e))
#check_failure (fun (s : driver_state) => (show CoreB.driver_state from s))

-- Check resolved constants through the B-owned execution closure. Shared
-- frontend/services are intentional; original target execution is not.
run_cmd do
  let env ← Lean.getEnv
  let roots := #[`CoreBDiff.lowerB, `CoreBDiff.ExecutionB.action]
  let expected := #[`CoreB.CoreParser.parseLibraryFile, `CoreB.translate,
    `CoreB.link, `CoreB.convert_file, `CoreB.initial_driver_state,
    `CoreB.drive, `CoreB.driver2, `CoreB.step_ctx, `CoreB.call_proc,
    `CoreB.step_eval_pexpr]
  let forbidden := expected.map fun name =>
    (name.toString.drop 6).toString
  let mut pending := roots.toList
  let mut seen : Lean.NameSet := {}
  while let name :: rest := pending do
    pending := rest
    if seen.contains name then continue
    seen := seen.insert name
    let some info := env.find? name | throwError "missing execution declaration {name}"
    if let some value := info.value? then
      for used in value.getUsedConstants do
        if forbidden.contains used.toString then
          throwError "B execution {name} references original target {used}"
        if (`CoreB).isPrefixOf used then pending := used :: pending
  for name in expected do
    unless seen.contains name do throwError "B execution does not reach {name}"

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
