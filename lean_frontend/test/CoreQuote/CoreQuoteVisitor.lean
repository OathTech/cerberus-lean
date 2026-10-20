import Lean
import Core_run_aux

/- Development generator for the independent test visitor. It reads elaborated
   datatype declarations, never CerbQuote or its output. Run from lean_frontend:
   ../scripts/capped lake env lean test/CoreQuote/CoreQuoteVisitor.lean > ../.tmp/visitor.txt
   Replace the marked block in test/Unit/CoreQuoteTest.lean with its output.
   Fmap's function field is deliberately left to the separate syntax check.
   All other constructor arguments are visited, including both Pos filenames. -/
open Lean Meta Elab Command
namespace CoreQuoteVisitor

private def leaves : List Name := [``Nat, ``Int, ``String, ``Float, ``Bool, ``Unit, ``PUnit]

private def ctorFields (ty : Expr) (ctor : Name) : MetaM (Array Expr) := do
  let .const n levels := ty.getAppFn | throwError "unnamed type {ty}"
  let .inductInfo info ← getConstInfo n | throwError "not inductive: {ty}"
  let ci ← getConstInfo ctor
  let mut ct := ci.type.instantiateLevelParams ci.levelParams levels
  for a in ty.getAppArgs[:info.numParams] do
    let .forallE _ _ body _ := ct | throwError "missing parameter: {ctor}"
    ct := body.instantiate1 a
  forallTelescopeReducing ct fun fields _ => fields.mapM (fun f => inferType f >>= whnf)

private partial def collect (ty : Expr) (seen : IO.Ref (Array Expr)) : MetaM Unit := do
  let ty ← whnf ty
  if (← seen.get).contains ty then return
  seen.modify (·.push ty)
  let .const n _ := ty.getAppFn | throwError "unnamed type {ty}"
  if leaves.contains n then return
  let .inductInfo info ← getConstInfo n | throwError "not inductive: {ty}"
  for ctor in info.ctors do
    for ft in (← ctorFields ty ctor) do
      if ft.isForall then
        unless n == ``Fmap do throwError "unexpected function in {ctor}"
      else collect ft seen

run_cmd liftTermElabM do
  let root := mkApp2 (mkConst ``generic_file) (mkConst ``Unit) (mkConst ``core_run_annotation)
  let seen ← IO.mkRef #[]
  collect root seen
  let types ← seen.get
  let mut heads : Array Name := #[]
  let mut ctors := 0
  IO.println "-- BEGIN DATATYPE VISITOR (test/CoreQuote/CoreQuoteVisitor.lean)\nmutual"
  for i in [:types.size] do
    let some ty := types[i]? | throwError "missing visitor type {i}"
    let .const n _ := ty.getAppFn | throwError "unnamed visitor type {ty}"
    IO.println s!"partial def view{i} (x : {← ppExpr ty}) : Shape :="
    if leaves.contains n then
      if n == ``Float then IO.println "  .scalar (if x.isNaN then \"NaN\" else \"Float.bits\") (toString x.toBits.toNat)"
      else if n == ``Unit || n == ``PUnit then IO.println "  let _ := x; .node \"Unit.unit\" #[]"
      else if n == ``String then IO.println "  .scalar \"String\" x"
      else IO.println s!"  .scalar \"{n}\" (toString x)"
    else
      let .inductInfo info ← getConstInfo n | throwError "not inductive: {ty}"
      if !heads.contains n then
        heads := heads.push n
        if ![``List, ``Option, ``Prod, ``Fmap, ``Pmap, ``Pset].contains n then
          ctors := ctors + info.ctors.length
      if n == ``List then
        let some elementType := ty.getAppArgs[0]? | throwError "List without an element type"
        let some k := types.toList.idxOf? (← whnf elementType) | throwError "unvisited List element"
        IO.println s!"  .node \"List\" (x.toArray.map view{k})"
      else
        IO.println "  match x with"
        for ctor in info.ctors do
          let fields ← ctorFields ty ctor
          let mut vars : Array String := #[]
          let mut args : Array String := #[]
          for j in [:fields.size] do
            let some ft := fields[j]? | throwError "missing constructor field {j}"
            if ft.isForall then vars := vars.push "_"
            else
              let v := s!"a{j}"
              vars := vars.push v
              if n == ``CerbLocation.Pos && (j == 0 || j == 3) then
                args := args.push s!"(.scalar \"Pos.path\" {v})"
              else
                let some k := types.toList.idxOf? ft | throwError "unvisited field: {ctor} {ft}"
                args := args.push s!"(view{k} {v})"
          let .str _ shortName := ctor | throwError "unexpected constructor name {ctor}"
          IO.println s!"  | .{shortName} {String.intercalate " " vars.toList} => .node \"{ctor}\" #[{String.intercalate ", " args.toList}]"
  IO.println "end\n-- END DATATYPE VISITOR"
  unless ctors == 638 && heads.size == 81 do
    throwError "inventory drift: {ctors} model constructors, {heads.size} container/model heads"
  IO.println s!"-- {ctors} model constructors; {types.size} instantiated types; 75 model + 6 container heads."

end CoreQuoteVisitor
