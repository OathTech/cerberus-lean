import Incoming
import CoreNice.Core_aux

/-! Executable control-cut insertion for linked AIL output and its runtime.
    Entries use a binder-free unit sequence; calls retain their original choice
    point and carry a cut on return. This is a structural coverage check, not a
    termination theorem for pure evaluation or primitive implementations. -/
namespace CoreNice.Saturation

open Incoming

structure Stats where
  procedures : Nat := 0
  labels : Nat := 0
  callReturns : Nat := 0
  pureFunctions : Nat := 0
  primitiveCalls : Nat := 0
  deriving Repr, BEq

private structure Supply where
  next : Nat
  stats : Stats := {}
  cache : List (sym × fun_map_decl Unit × fun_map_decl Unit) := []

def isEntryRole : nice_breakpoint_role → Bool
  | .BP_procedure_entry | .BP_label_entry => true
  | _ => false

private def fresh (owner : sym) (role : nice_breakpoint_role) (location : CerbLocation.Loc) :
    StateT Supply (Except String) nice_breakpoint_site := do
  let state ← get
  set { state with next := state.next + 1 }
  return {
    breakpoint_procedure := owner, breakpoint_id := state.next,
    breakpoint_role := role, breakpoint_origin := .NiceInternal,
    breakpoint_location := location }

def entry {a : Type} (site : nice_breakpoint_site) (body : expr a) : expr a :=
  mk_breakpoint_sseq_e site (mk_empty_pat .BTy_unit) (mk_value_e .Vunit) body

/-- Recognize only the exact administrative entry shape. -/
def entrySite {a : Type} : expr a → Option nice_breakpoint_site
  | .Expr [] (.Esseq (.Pattern [] (.CaseBase (none, .BTy_unit)))
      (.Expr [] (.Epure (.Pexpr [] () (.PEval .Vunit)))) (.Breakpoint site, _)) =>
    if isEntryRole site.breakpoint_role then some site else none
  | _ => none

private def maxId {a : Type} (body : expr a) : Nat :=
  ((mapExprM (fun _ _ node => do
    match node with
    | .Esseq _ _ (.Breakpoint site, _) => modify (max site.breakpoint_id)
    | .Eccall (_, .Breakpoint site) .. | .Eproc (_, .Breakpoint site) .. =>
      modify (max site.breakpoint_id)
    | _ => pure ()
    pure node) {} body : StateM Nat (expr a)).run 0).2

private def initialId (program : file Unit) : Nat :=
  let bodies := (fmapElements program.stdlib ++ fmapElements program.funs).filterMap
    (fun (_, decl) => match decl with | .Proc _ _ _ _ body => some body | _ => none)
  let globals := program.globs.filterMap
    (fun (_, decl) => match decl with | .GlobalDef _ body => some body | _ => none)
  (bodies ++ globals).foldl (fun n body => max n (maxId body)) 0 + 1

private def insertBody (owner : sym) (body : expr Unit) :
    StateT Supply (Except String) (expr Unit) :=
  mapExprM (fun context annotations node => do
    let loc := get_loc_ annotations
    match node with
    | .Esave label params body info =>
      unless context.labelsCollected && !context.parallelChild do
        throw "saturation: saved label is outside the supported continuation collector"
      let site ← fresh owner .BP_label_entry loc
      modify fun s => { s with stats.labels := s.stats.labels + 1 }
      return .Esave label params (entry site body) info
    | .Eccall (annotation, .Continue) ty function args =>
      let site ← fresh owner .BP_call_return loc
      modify fun s => { s with stats.callReturns := s.stats.callReturns + 1 }
      return .Eccall (annotation, .Breakpoint site) ty function args
    | .Eproc (annotation, .Continue) (.Sym function) args =>
      let site ← fresh owner .BP_call_return loc
      modify fun s => { s with stats.callReturns := s.stats.callReturns + 1 }
      return .Eproc (annotation, .Breakpoint site) (.Sym function) args
    | .Eproc (_, .Continue) (.Impl _) _ =>
      modify fun s => { s with stats.primitiveCalls := s.stats.primitiveCalls + 1 }
      return node
    | .Eccall (_, .Breakpoint _) .. | .Eproc (_, .Breakpoint _) .. =>
      throw "saturation: input already carries call-return cuts"
    | .Esseq _ _ (.Breakpoint site, _) =>
      if isEntryRole site.breakpoint_role then
        throw "saturation: input already carries administrative entry cuts"
      return node
    | .Epar _ | .Ewait _ =>
      throw "saturation: parallel execution is outside this AIL recipe"
    | _ => return node) {} body

private def insertProcedure (owner : sym) (decl : fun_map_decl Unit) :
    StateT Supply (Except String) (fun_map_decl Unit) := do
  match decl with
  | .Proc .. => pure ()
  | .Fun .. =>
    modify fun s => { s with stats.pureFunctions := s.stats.pureFunctions + 1 }
    return decl
  | _ => return decl
  match (← get).cache.find? (fun (key, _, _) => sameSymbol key owner) with
  | some (_, original, result) =>
    unless original == decl do throw "saturation: conflicting duplicate procedure definitions"
    return result
  | none => pure ()
  let result ← match decl with
    | .Proc location markers result params body => do
      let body ← insertBody owner body
      let site ← fresh owner .BP_procedure_entry location
      modify fun s => { s with stats.procedures := s.stats.procedures + 1 }
      pure (.Proc location markers result params (entry site body))
    | .Fun .. => do
      modify fun s => { s with stats.pureFunctions := s.stats.pureFunctions + 1 }
      pure decl
    | _ => pure decl
  modify fun s => { s with cache := (owner, decl, result) :: s.cache }
  return result

/-- Check actual AST coverage without trusting comesfrom's allowed-origin sets.
    Entry shapes cover all syntactic saved targets, including return labels.
    Pure functions and Impl calls are separately summarized primitive work. -/
def check {a : Type} (program : file a) : Except String Unit := do
  let checkBody (owner : sym) (body : expr a) : Except String Unit := do
    let _ ← mapExprM (fun context _ node => do
      match node with
      | .Esave _ _ target _ =>
        unless context.labelsCollected && !context.parallelChild do
          throw "saturation: unsupported saved-label context"
        let some site := entrySite target | throw "saturation: saved label lacks an entry cut"
        unless site.breakpoint_role == .BP_label_entry && sameSymbol site.breakpoint_procedure owner do
          throw "saturation: wrong saved-label entry cut"
      | .Eccall (_, tail) .. | .Eproc (_, tail) (.Sym _) _ =>
        let .Breakpoint site := tail | throw "saturation: call lacks a return cut"
        unless site.breakpoint_role == .BP_call_return && sameSymbol site.breakpoint_procedure owner do
          throw "saturation: wrong call-return cut"
      | .Eproc (_, .Breakpoint _) (.Impl _) _ =>
        throw "saturation: primitive call cannot advertise a stack-return cut"
      | .Epar _ | .Ewait _ => throw "saturation: unsupported parallel execution"
      | _ => pure ()
      return node) {} body
    pure ()
  for (owner, decl) in fmapElements program.stdlib ++ fmapElements program.funs do
    match decl with
    | .Proc _ _ _ _ body =>
      let some site := entrySite body | throw "saturation: procedure lacks an entry cut"
      unless site.breakpoint_role == .BP_procedure_entry && sameSymbol site.breakpoint_procedure owner do
        throw "saturation: wrong procedure entry cut"
      checkBody owner body
    | _ => pure ()
  for (owner, decl) in program.globs do
    match decl with
    | .GlobalDef _ body => checkBody owner body
    | _ => pure ()

structure Result where
  file : CoreNice.file Unit
  stats : Stats

def insert (program : file Unit) : Except String Result := do
  let (file, state) ← (do
    let stdlib ← mapValuesM insertProcedure program.stdlib
    let funs ← mapValuesM insertProcedure program.funs
    let globs ← program.globs.mapM fun (owner, decl) => do
      match decl with
      | GlobalDef ty body => pure (owner, GlobalDef ty (← insertBody owner body))
      | _ => pure (owner, decl)
    pure { program with stdlib, funs, globs }).run { next := initialId program }
  check file
  return { file, stats := state.stats }

end CoreNice.Saturation
