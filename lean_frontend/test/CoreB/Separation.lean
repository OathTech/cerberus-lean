import Core_auxiliary
import Core_linking
import CerbCoreShape
import CoreB.Core_auxiliary
import CoreB.Core_linking
import CoreB.CerbCoreShape
import Lean.Elab.Command
import Lean.Util.FoldConsts

/- Both complete ASTs, a real consumer, handwritten support and generated
   auxiliary proof bindings coexist. No CoreB execution through erasure. -/

namespace CoreBSeparationTests

-- Nominally different ASTs and program containers, with shared symbol/ctype
-- services. These must fail even though the two definitions have equal shapes.
#check_failure (fun (x : core_base_type) => (show CoreB.core_base_type from x))
#check_failure (fun (x : expr Unit) => (show CoreB.expr Unit from x))
#check_failure (fun (x : generic_file Unit Unit) =>
  (show CoreB.generic_file Unit Unit from x))
#check_failure (fun (x : CoreB.expr Unit) => (show expr Unit from x))
#check_failure (fun (x : expr Unit) => CoreB.CerbCoreShape.IsPureExpr x)

-- Elaborated consumer types must use the B AST and the B error representation.
example : CoreB.generic_file Unit Unit → CoreB.generic_file Unit Unit →
    exceptM (CoreB.generic_file Unit Unit) (CerbLocation.Loc × CoreB.cause) :=
  CoreB.link_aux

example : generic_file Unit Unit → generic_file Unit Unit →
    exceptM (generic_file Unit Unit) (CerbLocation.Loc × cause) :=
  link_aux

#check_failure (fun (x : generic_file Unit Unit) => CoreB.link_aux x x)

-- Check actual declaration identities and the generated-to-handwritten proof
-- reference, rather than inferring either from module filenames.
run_cmd do
  let env ← Lean.getEnv
  for name in [`CoreB.generic_expr, `CoreB.generic_file, `CoreB.core_base_type] do
    unless (env.find? name).any (fun info => info matches .inductInfo _) do
      throwError "expected a distinct inductive/structure declaration: {name}"
  let some (.thmInfo info) := env.find? `CoreB.eq_core_base_type_measure_sufficient
    | throwError "missing B generated measure theorem"
  unless info.value.getUsedConstants.contains
      `CoreB.Core_lemMeasureProofs.eq_core_base_type_measure_sufficient do
    throwError "B auxiliary theorem does not invoke the B handwritten proof"

theorem coreB_link_no_main : CoreB.link_main none none = except_return none := rfl

theorem core_link_no_main : link_main none none = except_return none := rfl

theorem coreB_type_equality :
    CoreB.eq_core_base_type (.BTy_list .BTy_unit) (.BTy_list .BTy_unit) = true := rfl

theorem core_type_equality :
    eq_core_base_type (.BTy_list .BTy_unit) (.BTy_list .BTy_unit) = true := rfl

theorem coreB_shape : CoreB.CerbCoreShape.IsValuePexpr
    (.Pexpr [] () (.PEval .Vunit)) := ⟨[], .Vunit, rfl⟩

theorem core_shape : CerbCoreShape.IsValuePexpr
    (.Pexpr [] () (.PEval .Vunit)) := ⟨[], .Vunit, rfl⟩

-- This invokes the generated auxiliary theorem, which must bind to the owned
-- handwritten proof over B's equality worker, for every adequate fuel value.
theorem coreB_measure_binding (a b : CoreB.core_base_type) (fuel : Nat)
    (h : CoreB.core_base_type.lemSize a ≤ fuel) :
    CoreB.eq_core_base_type_lemFuel fuel a b = CoreB.eq_core_base_type a b :=
  CoreB.eq_core_base_type_measure_sufficient a b fuel h

#print axioms coreB_type_equality
#print axioms coreB_shape
#print axioms coreB_measure_binding
#print axioms coreB_link_no_main

end CoreBSeparationTests
