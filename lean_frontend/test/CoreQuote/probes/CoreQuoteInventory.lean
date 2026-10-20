import Lean
import Main

open Lean Meta Elab Command

/- Development inventory for the Core quotation seam. Run from lean_frontend:
   CERB_MEM_MAX=48G ../scripts/capped lake env lean test/CoreQuote/probes/CoreQuoteInventory.lean
   This reports type declarations and elaborated instances; it adds no theorem,
   no correctness gate, and no production instance. -/

namespace CoreQuoteInventory

set_option pp.explicit true
set_option pp.fullNames true

#synth Lem_Basic_classes.Eq0 sym
#synth Lem_Basic_classes.Ord0 sym
#synth Lem_Basic_classes.SetType sym
#synth Lem_Map.MapKeyType sym
#synth Lem_Map.MapKeyType implementation_constant
#synth Ord Nat
#synth Ord String
#check @Lem_Basic_classes.ordCompare sym
#print Lem_Basic_classes.ordCompare

def symbolFromListComparator : sym → sym → LemOrdering := Lem_Map.mapKeyCompare
def symbolInsertComparator : sym → sym → LemOrdering := Lem_Basic_classes.ordCompare
def typedImplComparator : implementation_constant → implementation_constant → LemOrdering :=
  Lem_Map.mapKeyCompare
def natInsertComparator : Nat → Nat → LemOrdering := defaultCompare
def identifierInsertComparator : identifier → identifier → LemOrdering :=
  fun (.Identifier _ a) (.Identifier _ b) => defaultCompare a b

#print symbolFromListComparator
#print symbolInsertComparator
#print typedImplComparator
#print natInsertComparator
#print identifierInsertComparator

private partial def inventory (ty : Expr) (seen : IO.Ref (Array Name))
    (visited : IO.Ref (Array Expr)) : MetaM Unit := do
  let ty ← whnf ty
  if (← visited.get).contains ty then return
  visited.modify (·.push ty)
  let .const n levels := ty.getAppFn
    | throwError "inventory expected a named type, got {ty}"
  if [``List, ``Option, ``Prod, ``Fmap, ``Pmap, ``Pset].contains n then
    if !(← seen.get).contains n then
      seen.modify (·.push n)
      let .inductInfo info ← getConstInfo n
        | throwError "unhandled container {ty}"
      IO.println s!"CONTAINER {n}: {String.intercalate ", " (info.ctors.map Name.toString)}"
    for arg in ty.getAppArgs do
      inventory arg seen visited
    if n == ``Fmap then
      inventory (mkAppN (mkConst ``Pmap) ty.getAppArgs) seen visited
    return
  let newHead := !(← seen.get).contains n
  if newHead then seen.modify (·.push n)
  if [``Nat, ``Int, ``String, ``Float, ``Bool, ``Unit, ``PUnit].contains n then
    if newHead then IO.println s!"LEAF {n}"
    return
  let .inductInfo info ← getConstInfo n
    | throwError "unhandled inventory type {ty}"
  let args := ty.getAppArgs
  if newHead then
    IO.println s!"TYPE {n}: {String.intercalate ", " (info.ctors.map Name.toString)}"
  for ctor in info.ctors do
    let ci ← getConstInfo ctor
    let mut ct := ci.type.instantiateLevelParams ci.levelParams levels
    for a in args[:info.numParams] do
      let .forallE _ _ body _ := ct
        | throwError "missing parameter in {ctor}"
      ct := body.instantiate1 a
    forallTelescopeReducing ct fun fields _ => do
      for field in fields do
        let ft ← inferType field
        if ft.isForall then
          throwError "function field outside Fmap: {ctor}: {ft}"
        else
          inventory ft seen visited

run_cmd do
  liftTermElabM do
    let seen ← IO.mkRef #[]
    let visited ← IO.mkRef #[]
    inventory (mkApp2 (mkConst ``generic_file) (mkConst ``Unit) (mkConst ``core_run_annotation)) seen visited
    IO.println s!"TOTAL type heads: {(← seen.get).size}"


#print translate_tag_definitions
#print loadCoreStdlib
#print record_loop_attribute
#print record_object_types_marker

run_cmd do
  for n in [``translate_program, ``typecheck_program, ``link_aux, ``link_extern,
      ``collect_saves_aux_lemFuel, ``collect_saves, ``union_saves] do
    let .defnInfo d ← getConstInfo n | throwError "not a definition: {n}"
    let selected := d.value.getUsedConstants.filter fun c =>
      c.toString.startsWith "inst" || c.toString.contains "Compare" ||
      c.toString.contains "MapKeyType"
    logInfo m!"CONSTRUCTION {n}: {selected}"

end CoreQuoteInventory
