import Core_auxiliary
import Core_linking
import CerbCoreShape
import CoreNice.Core_auxiliary
import CoreNice.Core_linking
import CoreNice.CerbCoreShape
import Lean.Elab.Command
import Lean.Util.FoldConsts

/- Both complete ASTs, a real consumer, handwritten support and generated
   auxiliary proof bindings coexist. No CoreNice execution through erasure. -/

namespace CoreNiceSeparationTests

-- Nominally different ASTs and program containers, with shared symbol/ctype
-- services. These must fail even though the two definitions have equal shapes.
#check_failure (fun (x : core_base_type) => (show CoreNice.core_base_type from x))
#check_failure (fun (x : expr Unit) => (show CoreNice.expr Unit from x))
#check_failure (fun (x : generic_file Unit Unit) =>
  (show CoreNice.generic_file Unit Unit from x))
#check_failure (fun (x : CoreNice.expr Unit) => (show expr Unit from x))
#check_failure (fun (x : expr Unit) => CoreNice.CerbCoreShape.IsPureExpr x)

-- Elaborated consumer types must use the B AST and the B error representation.
example : CoreNice.generic_file Unit Unit → CoreNice.generic_file Unit Unit →
    exceptM (CoreNice.generic_file Unit Unit) (CerbLocation.Loc × CoreNice.cause) :=
  CoreNice.link_aux

example : generic_file Unit Unit → generic_file Unit Unit →
    exceptM (generic_file Unit Unit) (CerbLocation.Loc × cause) :=
  link_aux

#check_failure (fun (x : generic_file Unit Unit) => CoreNice.link_aux x x)

-- Check actual declaration identities and the generated-to-handwritten proof
-- reference, rather than inferring either from module filenames.
run_cmd do
  let env ← Lean.getEnv
  for name in [`CoreNice.generic_expr, `CoreNice.generic_file, `CoreNice.core_base_type] do
    unless (env.find? name).any (fun info => info matches .inductInfo _) do
      throwError "expected a distinct inductive/structure declaration: {name}"
  let some (.thmInfo info) := env.find? `CoreNice.eq_core_base_type_measure_sufficient
    | throwError "missing B generated measure theorem"
  unless info.value.getUsedConstants.contains
      `CoreNice.Core_lemMeasureProofs.eq_core_base_type_measure_sufficient do
    throwError "B auxiliary theorem does not invoke the B handwritten proof"

theorem coreNice_link_no_main : CoreNice.link_main none none = except_return none := rfl

theorem core_link_no_main : link_main none none = except_return none := rfl

theorem coreNice_type_equality :
    CoreNice.eq_core_base_type (.BTy_list .BTy_unit) (.BTy_list .BTy_unit) = true := rfl

theorem core_type_equality :
    eq_core_base_type (.BTy_list .BTy_unit) (.BTy_list .BTy_unit) = true := rfl

theorem coreNice_shape : CoreNice.CerbCoreShape.IsValuePexpr
    (.Pexpr [] () (.PEval .Vunit)) := ⟨[], .Vunit, rfl⟩

theorem core_shape : CerbCoreShape.IsValuePexpr
    (.Pexpr [] () (.PEval .Vunit)) := ⟨[], .Vunit, rfl⟩

-- This invokes the generated auxiliary theorem, which must bind to the owned
-- handwritten proof over B's equality worker, for every adequate fuel value.
theorem coreNice_measure_binding (a b : CoreNice.core_base_type) (fuel : Nat)
    (h : CoreNice.core_base_type.lemSize a ≤ fuel) :
    CoreNice.eq_core_base_type_lemFuel fuel a b = CoreNice.eq_core_base_type a b :=
  CoreNice.eq_core_base_type_measure_sufficient a b fuel h

#print axioms coreNice_type_equality
#print axioms coreNice_shape
#print axioms coreNice_measure_binding
#print axioms coreNice_link_no_main

end CoreNiceSeparationTests
