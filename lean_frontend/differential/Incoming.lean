import CoreNice.Core

/-! Static comesfrom metadata for the linked CoreNice program.

The conservative producer includes every syntactic jump to each saved label.
It never evaluates Core, chooses a trace, or uses the Cerberus freshness supply.
Only metadata changes: even the finite maps' key trees and comparators survive.
The traversal is total and also supports mutations *after* finalization, so a
negative control reaches the semantic check rather than this producer.
-/

namespace CoreNice.Incoming

/-- The actual saved-label collector does not descend into bound/nd/annot.
    Parallel children also lack the enclosing procedure's ordinary call frame. -/
structure Context where
  labelsCollected : Bool := true
  parallelChild : Bool := false

mutual
/-- Total postorder traversal. The callback sees original annotation locations
    and reconstructed children; it must preserve ordinary fields when used as a
    metadata-only transformation. -/
def mapExprM {m : Type → Type} [Monad m] {a : Type}
    (visit : Context → List annot → generic_expr_ a Unit sym →
      m (generic_expr_ a Unit sym)) (context : Context) (expression : expr a) : m (expr a) := do
  match expression with
  | .Expr annotations node =>
    let node ← mapNodeM visit context node
    return .Expr annotations (← visit context annotations node)
termination_by structural expression

def mapNodeM {m : Type → Type} [Monad m] {a : Type}
    (visit : Context → List annot → generic_expr_ a Unit sym →
      m (generic_expr_ a Unit sym)) (context : Context)
    (node : generic_expr_ a Unit sym) : m (generic_expr_ a Unit sym) := do
  match node with
  | .Epure value => return .Epure value
  | .Ememop op args => return .Ememop op args
  | .Eaction action => return .Eaction action
  | .Ecase value branches => return .Ecase value (← mapBranchesM visit context branches)
  | .Elet pattern value body => return .Elet pattern value (← mapExprM visit context body)
  | .Eif condition yes no =>
    return .Eif condition (← mapExprM visit context yes) (← mapExprM visit context no)
  | .Eccall annotation functionType function args =>
    return .Eccall annotation functionType function args
  | .Eproc annotation function args => return .Eproc annotation function args
  | .Eunseq expressions => return .Eunseq (← mapExprsM visit context expressions)
  | .Ewseq pattern first second =>
    return .Ewseq pattern (← mapExprM visit context first) (← mapExprM visit context second)
  | .Esseq pattern first (tail, second) =>
    return .Esseq pattern (← mapExprM visit context first) (tail, ← mapExprM visit context second)
  | .Ebound body =>
    return .Ebound (← mapExprM visit { context with labelsCollected := false } body)
  | .End expressions =>
    return .End (← mapExprsM visit { context with labelsCollected := false } expressions)
  | .Esave label params body info =>
    return .Esave label params (← mapExprM visit context body) info
  | .Erun annotation label args info => return .Erun annotation label args info
  | .Epar expressions =>
    return .Epar (← mapExprsM visit { context with parallelChild := true } expressions)
  | .Ewait thread => return .Ewait thread
  | .Eannot annotations body =>
    return .Eannot annotations
      (← mapExprM visit { context with labelsCollected := false } body)
  | .Eexcluded count action => return .Eexcluded count action
termination_by structural node

def mapExprsM {m : Type → Type} [Monad m] {a : Type}
    (visit : Context → List annot → generic_expr_ a Unit sym →
      m (generic_expr_ a Unit sym)) (context : Context) (expressions : List (expr a)) :
    m (List (expr a)) := do
  match expressions with
  | [] => return []
  | first :: rest => return (← mapExprM visit context first) :: (← mapExprsM visit context rest)
termination_by structural expressions

def mapBranchesM {m : Type → Type} [Monad m] {a : Type}
    (visit : Context → List annot → generic_expr_ a Unit sym →
      m (generic_expr_ a Unit sym)) (context : Context)
    (branches : List (generic_pattern sym × expr a)) :
    m (List (generic_pattern sym × expr a)) := do
  match branches with
  | [] => return []
  | (pattern, first) :: rest =>
    return (pattern, ← mapExprM visit context first) :: (← mapBranchesM visit context rest)
termination_by structural branches
end

/-- Change only the appended control metadata, including inside all containers.
    There is deliberately no validity check here: corruption tests use this after
    `finalize` and must exercise the machine's actual fault rule. -/
def mapMetadataExpr {a : Type} (onJump : sym → nice_jump_info → nice_jump_info)
    (onLabel : sym → nice_label_info → nice_label_info) (expression : expr a) : expr a :=
  Id.run <| mapExprM (fun _ _ node => pure <| match node with
    | .Erun annotation label args info => .Erun annotation label args (onJump label info)
    | .Esave label params body info => .Esave label params body (onLabel label.1 info)
    | other => other) {} expression

private def mapProcedureMetadata {a : Type}
    (onJump : sym → sym → nice_jump_info → nice_jump_info)
    (onLabel : sym → sym → nice_label_info → nice_label_info)
    (procedure : sym) (decl : generic_fun_map_decl Unit a) : generic_fun_map_decl Unit a :=
  match decl with
  | .Proc location markers result params body =>
    .Proc location markers result params (mapMetadataExpr (onJump procedure) (onLabel procedure) body)
  | other => other

/-- Map the metadata of all procedure definitions in both maps. Global
    initializers cannot contain finalized jumps or saved labels. -/
def mapMetadataFile {a : Type} (onJump : sym → sym → nice_jump_info → nice_jump_info)
    (onLabel : sym → sym → nice_label_info → nice_label_info) (program : file a) : file a :=
  { program with
    stdlib := fmapMapi (mapProcedureMetadata onJump onLabel) program.stdlib
    funs := fmapMapi (mapProcedureMetadata onJump onLabel) program.funs }

structure JumpSite where
  target : sym
  info : nice_jump_info

structure LabelSite where
  symbol : sym
  info : nice_label_info

structure Procedure where
  symbol : sym
  sourceMap : String
  jumps : List JumpSite
  labels : List LabelSite

private def inspectProcedure {a : Type} (sourceMap : String) (procedure : sym)
    (body : expr a) : Procedure := Id.run do
  let visit (_ : Context) (_ : List annot) (node : generic_expr_ a Unit sym) :
      StateM (List JumpSite × List LabelSite) (generic_expr_ a Unit sym) := do
    match node with
    | .Erun _ target _ info => modify fun (jumps, labels) => ({ target, info } :: jumps, labels)
    | .Esave label _ _ info => modify fun (jumps, labels) => (jumps, { symbol := label.1, info } :: labels)
    | _ => pure ()
    return node
  let (_, (jumps, labels)) := (mapExprM visit {} body).run ([], [])
  return { symbol := procedure, sourceMap, jumps := jumps.reverse, labels := labels.reverse }

/-- Inspect the actual metadata, including deliberately corrupted runtime files.
    This is an inventory, not a producer validation or a machine precondition. -/
def inspectFile {a : Type} (program : file a) : List Procedure :=
  let inspect (sourceMap : String) (entry : sym × generic_fun_map_decl Unit a) :=
    match entry with
    | (procedure, .Proc _ _ _ _ body) => some (inspectProcedure sourceMap procedure body)
    | _ => none
  (fmapElements program.stdlib).filterMap (inspect "stdlib") ++
    (fmapElements program.funs).filterMap (inspect "funs")

structure Stats where
  procedures : Nat := 0
  jumps : Nat := 0
  labels : Nat := 0
  allowedOrigins : Nat := 0
  zeroIncomingLabels : Nat := 0
  maxIncoming : Nat := 0
  deriving Repr, BEq

structure Result where
  file : CoreNice.file Unit
  stats : Stats
  procedures : List Procedure

/-- Match the actual symbol-key comparator, which ignores pretty descriptions. -/
def sameSymbol (left right : sym) : Bool :=
  match symbol_compare left right with
  | .EQ => true
  | .LT | .GT => false

private def siteDescription (procedure : sym) (annotations : List annot) : String :=
  s!"procedure {show_symbol procedure} at {CerbLocation.stringFromLocation (get_loc_ annotations)}"

private structure Scan where
  nextOrigin : Nat := 1
  jumps : List JumpSite := []
  labels : List LabelSite := []

private def assign (procedure : sym) (context : Context) (annotations : List annot)
    (node : generic_expr_ Unit Unit sym) : StateT Scan (Except String) (generic_expr_ Unit Unit sym) := do
  match node with
  | .Esave label params body _ =>
    unless context.labelsCollected do
      throw s!"comesfrom: saved label under bound/nd/annot is not collected ({siteDescription procedure annotations})"
    if context.parallelChild then
      throw s!"comesfrom: saved label in a parallel child has unsupported procedure binding ({siteDescription procedure annotations})"
    let state ← get
    if state.labels.any (fun prior => sameSymbol prior.symbol label.1) then
      throw s!"comesfrom: duplicate saved label {show_symbol label.1} ({siteDescription procedure annotations})"
    let info : nice_label_info := {
      nice_label_origins := [], nice_label_location := get_loc_ annotations }
    set { state with labels := { symbol := label.1, info } :: state.labels }
    return .Esave label params body info
  | .Erun annotation label args _ =>
    if context.parallelChild then
      throw s!"comesfrom: jump in a parallel child has unsupported procedure binding ({siteDescription procedure annotations})"
    let state ← get
    let info : nice_jump_info := {
      nice_jump_origin := state.nextOrigin, nice_jump_location := get_loc_ annotations }
    set { state with
      nextOrigin := state.nextOrigin + 1
      jumps := { target := label, info } :: state.jumps }
    return .Erun annotation label args info
  | .Ewait _ =>
    throw s!"comesfrom: runtime-only wait node in producer input ({siteDescription procedure annotations})"
  | other => return other

/-- Producer-only checks. Runtime mutation tests must not re-run this after
    corrupting annotations: the dynamic check is the object of those tests. -/
private def validateAssigned (procedure : sym) (state : Scan) : Except String Unit := do
  let mut seen : List Nat := []
  for jump in state.jumps do
    let origin := jump.info.nice_jump_origin
    if origin == 0 || seen.contains origin then
      throw s!"comesfrom: producer assigned a zero or duplicate jump identity in {show_symbol procedure}"
    seen := origin :: seen
    unless state.labels.any (fun label => sameSymbol jump.target label.symbol) do
      throw s!"comesfrom: unresolved jump to {show_symbol jump.target} in {show_symbol procedure} at {CerbLocation.stringFromLocation jump.info.nice_jump_location}"

private def incoming (jumps : List JumpSite) (label : sym) : List Nat :=
  jumps.filterMap fun jump =>
    if sameSymbol jump.target label then some jump.info.nice_jump_origin else none

private def finalizeProcedure (sourceMap : String) (procedure : sym) (body : expr Unit) :
    Except String (expr Unit × Procedure) := do
  let (assigned, state) ← (mapExprM (assign procedure) {} body).run {}
  validateAssigned procedure state
  let jumps := state.jumps.reverse
  let labels := state.labels.reverse.map fun label =>
    { label with info := { label.info with nice_label_origins := incoming jumps label.symbol } }
  let body := Id.run <| mapExprM (fun _ _ node => pure <| match node with
    | .Esave label params body info =>
      .Esave label params body { info with nice_label_origins := incoming jumps label.1 }
    | other => other) {} assigned
  return (body, { symbol := procedure, sourceMap, jumps, labels })

private def isProcedure {a : Type} : generic_fun_map_decl Unit a → Bool
  | .Proc .. => true
  | .Fun .. | .ProcDecl .. | .BuiltinDecl .. => false

/-- The runtime call lookup prefers stdlib, whereas its collected label map
    prefers funs. Agreeing duplicate declarations are harmless; conflicting
    procedure definitions must not receive an invented resolution policy here. -/
private def validateBindings (program : file Unit) : Except String Unit := do
  let stdlib := fmapElements program.stdlib
  let funs := fmapElements program.funs
  for (key, decl) in stdlib do
    for (otherKey, otherDecl) in funs do
      if sameSymbol key otherKey && (isProcedure decl || isProcedure otherDecl) then
        unless decl == otherDecl do
          throw s!"comesfrom: conflicting stdlib/funs procedure binding for {show_symbol key}"
  let mut aliases : List (sym × sym) := []
  for (_, (declarations, kind)) in fmapElements program.extern do
    let target := match kind with
      | .LK_none => none
      | .LK_tentative definition | .LK_normal definition => some definition
    if let some target := target then
      for declaration in declarations do
        for (prior, priorTarget) in aliases do
          if sameSymbol prior declaration && !sameSymbol priorTarget target then
            throw s!"comesfrom: conflicting external aliases for {show_symbol declaration}"
        aliases := (declaration, target) :: aliases
  for (key, decl) in stdlib ++ funs do
    if isProcedure decl then
      for (declaration, target) in aliases do
        if sameSymbol key declaration && !sameSymbol key target then
          throw s!"comesfrom: procedure definition {show_symbol key} is remapped by an external alias"

private def rejectGlobalControl (global : sym) (body : expr Unit) : Except String Unit := do
  let _ ← mapExprM (fun _ annotations node => do
    match node with
    | .Esave .. | .Erun .. =>
      throw s!"comesfrom: control label/jump outside a procedure in global {show_symbol global} at {CerbLocation.stringFromLocation (get_loc_ annotations)}"
    | _ => pure node) {} body

private def mapTreeM {m : Type → Type} [Monad m] {α β γ : Type}
    (transform : α → β → m γ) : Pmap α β → m (Pmap α γ)
  | .Empty => pure .Empty
  | .Node left key value right height => do
    let left ← mapTreeM transform left
    let value ← transform key value
    let right ← mapTreeM transform right
    return .Node left key value right height

/-- Effectful value mapping that preserves the comparator and entire key tree. -/
def mapValuesM {m : Type → Type} [Monad m] {α β γ : Type}
    (transform : α → β → m γ) : Fmap α β → m (Fmap α γ)
  | .empty => pure .empty
  | .mk comparator tree => return .mk comparator (← mapTreeM transform tree)

/-- Compact static counts from a procedure inventory, including mutated files. -/
def summarize (procedures : List Procedure) : Stats :=
  procedures.foldl (fun stats procedure =>
    procedure.labels.foldl (fun stats label =>
      let count := label.info.nice_label_origins.length
      { stats with
        allowedOrigins := stats.allowedOrigins + count
        zeroIncomingLabels := stats.zeroIncomingLabels + (if count == 0 then 1 else 0)
        maxIncoming := max stats.maxIncoming count })
      { stats with
        procedures := stats.procedures + 1
        jumps := stats.jumps + procedure.jumps.length
        labels := stats.labels + procedure.labels.length }) {}

/-- Annotate both linked procedure maps, retaining all ordinary AST fields.
    Identities are assigned deterministically in structural postorder, separately
    for each procedure. Labels admit every syntactic jump to their symbol.
    Unsupported bindings are explicit errors, never runtime faults or omissions. -/
def finalize (program : file Unit) : Except String Result := do
  validateBindings program
  for (global, declaration) in program.globs do
    match declaration with
    | .GlobalDef _ body => rejectGlobalControl global body
    | .GlobalDecl _ => pure ()
  let transform (sourceMap : String) (procedure : sym) (decl : generic_fun_map_decl Unit Unit) :
      StateT (List Procedure) (Except String) (generic_fun_map_decl Unit Unit) := do
    match decl with
    | .Proc location markers result params body =>
      let (body, inventory) ← finalizeProcedure sourceMap procedure body
      modify (inventory :: ·)
      return .Proc location markers result params body
    | other => return other
  let ((stdlib, funs), inventory) ← (do
    let stdlib ← mapValuesM (transform "stdlib") program.stdlib
    let funs ← mapValuesM (transform "funs") program.funs
    pure (stdlib, funs)).run []
  let procedures := inventory.reverse
  return { file := { program with stdlib, funs }, stats := summarize procedures, procedures }

end CoreNice.Incoming
