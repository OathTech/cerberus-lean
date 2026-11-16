import Core_eval
import CoreNice.Core_eval
import PipelineA
import PipelineNice
import Lean.Util.FoldConsts
import Lean.Elab.Command

/- A small equation over the actual B evaluator. This demonstrates the proof
   interface; it is not a correspondence theorem between the two machines. -/
namespace CoreNiceInterpreterTests

#check_failure (fun (e : pexpr) => (show CoreNice.pexpr from e))
#check_failure (fun (s : driver_state) => (show CoreNice.driver_state from s))

-- Check resolved constants through the B-owned execution closure. Shared
-- frontend/services are intentional; original target execution is not.
run_cmd do
  let env ← Lean.getEnv
  let roots := #[`CoreNiceDiff.lowerNice, `CoreNiceDiff.ExecutionNice.action]
  let expected := #[`CoreNice.CoreParser.parseLibraryFile, `CoreNice.translate,
    `CoreNice.link, `CoreNice.convert_file, `CoreNice.initial_driver_state,
    `CoreNice.drive, `CoreNice.driver2, `CoreNice.step_ctx, `CoreNice.call_proc,
    `CoreNice.step_eval_pexpr]
  let forbidden := expected.map fun name =>
    (name.toString.drop "CoreNice.".length).toString
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
        if (`CoreNice).isPrefixOf used then pending := used :: pending
  for name in expected do
    unless seen.contains name do throwError "B execution does not reach {name}"

theorem value_step [LemFuel]
    (enums : Fmap sym integerType)
    (tags : Fmap sym (CerbLocation.Loc × tag_definition))
    (n : Nat) (loc : CerbLocation.Loc) (parent : Option CerbLocation.Loc)
    (externs : Fmap sym sym) (env : List (Fmap sym CoreNice.value))
    (mem : Option CerbMem.MemState)
    (file : CoreNice.generic_file Unit CoreNice.core_run_annotation)
    (constrained : Bool) (value : CoreNice.value) (fuel : Nat) :
    CoreNice.step_eval_pexpr_lemFuel (fuel + 1) enums tags n loc parent externs env
      mem file constrained (.Pexpr [] () (.PEval value)) =
      exception_undef_return (.Pexpr [] () (.PEval value)) := rfl

#print axioms value_step

end CoreNiceInterpreterTests
