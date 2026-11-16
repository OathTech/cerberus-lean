import Incoming
import CoreNice.Core_aux

/-! Optional structural tightening, applied to the conservative producer result.

Every procedure's ordinary entry is a root. Reachable jumps make the *actual
saved continuation* another root, including suffixes reconstructed by the
machine's collector. This matters for labels under a syntactically dead branch.
Only literal Core booleans and non-returning jumps cut syntax; arbitrary pure
expressions, calls, patterns, memory operations, and dynamic conditions remain
conservative. No observed tape or run participates in this analysis.

This executable producer is a differential-testing hypothesis, not a soundness
theorem. The required later theorem relates its overapproximation to both jump
entry and ordinary entry in the CoreNice machine.
-/

namespace CoreNice.Incoming

namespace Reachability

structure Summary where
  mayReturn : Bool
  jumps : List JumpSite

private def join (left right : Summary) : Summary :=
  { mayReturn := left.mayReturn || right.mayReturn, jumps := left.jumps ++ right.jumps }

private def sequence (first second : Summary) : Summary :=
  if first.mayReturn then
    { mayReturn := second.mayReturn, jumps := first.jumps ++ second.jumps }
  else first

mutual
/-- Return means falling through this expression's current continuation.
    An Erun replaces that continuation, so its target is explored separately. -/
def summarizeExpr {a : Type} (expression : expr a) : Summary :=
  match expression with
  | .Expr _ node => summarizeNode node
termination_by structural expression

def summarizeNode {a : Type} (node : generic_expr_ a Unit sym) : Summary :=
  match node with
  | .Epure _ | .Ememop .. | .Eaction _ | .Eccall .. | .Eproc .. | .Eexcluded .. =>
    { mayReturn := true, jumps := [] }
  | .Ecase _ branches => summarizeBranches branches
  | .Elet _ _ body => summarizeExpr body
  | .Eif (.Pexpr _ _ (.PEval .Vtrue)) yes _ => summarizeExpr yes
  | .Eif (.Pexpr _ _ (.PEval .Vfalse)) _ no => summarizeExpr no
  | .Eif _ yes no => join (summarizeExpr yes) (summarizeExpr no)
  | .Eunseq expressions | .Epar expressions => summarizeAll expressions
  | .Ewseq _ first second | .Esseq _ first (_, second) =>
    sequence (summarizeExpr first) (summarizeExpr second)
  | .Ebound body | .Eannot _ body | .Esave _ _ body _ => summarizeExpr body
  | .End expressions => summarizeAlternatives expressions
  | .Erun _ target _ info => { mayReturn := false, jumps := [{ target, info }] }
  | .Ewait _ => { mayReturn := true, jumps := [] }
termination_by structural node

/-- Any unsequenced child can run first; retain every child's jumps even when
    another child never returns. Completion requires all children to return. -/
def summarizeAll {a : Type} (expressions : List (expr a)) : Summary :=
  match expressions with
  | [] => { mayReturn := true, jumps := [] }
  | first :: rest =>
    let first := summarizeExpr first
    let rest := summarizeAll rest
    { mayReturn := first.mayReturn && rest.mayReturn, jumps := first.jumps ++ rest.jumps }
termination_by structural expressions

def summarizeAlternatives {a : Type} (expressions : List (expr a)) : Summary :=
  match expressions with
  | [] => { mayReturn := false, jumps := [] }
  | first :: rest => join (summarizeExpr first) (summarizeAlternatives rest)
termination_by structural expressions

def summarizeBranches {a : Type} (branches : List (generic_pattern sym × expr a)) : Summary :=
  match branches with
  | [] => { mayReturn := false, jumps := [] }
  | (_, first) :: rest => join (summarizeExpr first) (summarizeBranches rest)
termination_by structural branches
end

private def containsSymbol (symbols : List sym) (symbol : sym) : Bool :=
  symbols.any (sameSymbol · symbol)

private def uniqueTargets (jumps : List JumpSite) : List sym :=
  jumps.foldl (fun targets jump =>
    if containsSymbol targets jump.target then targets else targets ++ [jump.target]) []

private def insertJumps (accumulator fresh : List JumpSite) : Except String (List JumpSite) :=
  fresh.foldlM (fun accumulator jump => do
    match accumulator.find? (fun prior => prior.info.nice_jump_origin == jump.info.nice_jump_origin) with
    | none => return accumulator ++ [jump]
    | some prior =>
      unless sameSymbol prior.target jump.target do
        throw "comesfrom reachability: one static jump identity has conflicting targets"
      return accumulator) accumulator

structure Closure where
  jumps : List JumpSite
  labels : List sym

/-- Each iteration processes one previously unseen saved label. The fuel bound is
    the number of collected labels plus one; exhaustion is an implementation
    error, not a successful analysis or a silently incomplete allowed set. -/
private def close {a : Type}
    (saved : Fmap sym (List (sym × core_base_type) × expr a × nice_label_info)) :
    Nat → List sym → Closure → Except String Closure
  | 0, [], state => pure state
  | 0, _ :: _, _ => throw "comesfrom reachability: label worklist exceeded its finite bound"
  | _ + 1, [], state => pure state
  | fuel + 1, target :: pending, state => do
    if containsSymbol state.labels target then
      throw "comesfrom reachability: duplicate label on the pending worklist"
    let continuation ← match fmapLookupBy symbol_compare target saved with
      | some (_, body, _) => pure body
      | none => throw s!"comesfrom reachability: missing saved continuation {show_symbol target}"
    let jumps ← insertJumps state.jumps (summarizeExpr continuation).jumps
    let labels := state.labels ++ [target]
    let fresh := (uniqueTargets jumps).filter fun label =>
      !containsSymbol labels label && !containsSymbol pending label
    close saved fuel (pending ++ fresh) { jumps, labels }

def reachable {a : Type} (body : expr a) : Except String Closure := do
  let saved := collect_saves body
  let jumps ← insertJumps [] (summarizeExpr body).jumps
  close saved ((fmapElements saved).length + 1) (uniqueTargets jumps) { jumps, labels := [] }

end Reachability

structure TighteningStats where
  conservativeOrigins : Nat := 0
  retainedOrigins : Nat := 0
  removedOrigins : Nat := 0
  unreachableJumpSites : Nat := 0
  visitedLabels : Nat := 0
  deriving Repr, BEq

structure Tightened where
  result : Result
  tightening : TighteningStats

/-- Apply only after conservative finalization. Kept separate from `finalize` so
    differential testing can establish the baseline before enabling this policy.
    Static identities, source locations and ordinary AST fields stay unchanged. -/
def tighten (baseline : Result) : Except String Tightened := do
  let transform (procedure : sym) (decl : fun_map_decl Unit) :
      StateT TighteningStats (Except String) (fun_map_decl Unit) := do
    match decl with
    | .Proc location markers result params body =>
      let reached ← (Reachability.reachable body).mapError fun reason =>
        s!"{reason} in procedure {show_symbol procedure}"
      let liveIds := reached.jumps.map (·.info.nice_jump_origin)
      let visit (_ : Context) (_ : List annot) (node : generic_expr_ Unit Unit sym) :
          StateM Nat (generic_expr_ Unit Unit sym) := do
        match node with
        | .Esave label params body info =>
          let kept := info.nice_label_origins.filter liveIds.contains
          modify (· + (info.nice_label_origins.length - kept.length))
          return .Esave label params body { info with nice_label_origins := kept }
        | other => return other
      let (body, removedCount) := (mapExprM visit {} body).run 0
      modify fun stats => { stats with
        removedOrigins := stats.removedOrigins + removedCount
        visitedLabels := stats.visitedLabels + reached.labels.length }
      return .Proc location markers result params body
    | other => return other
  let ((stdlib, funs), tightening) ← (do
    let stdlib ← mapValuesM transform baseline.file.stdlib
    let funs ← mapValuesM transform baseline.file.funs
    pure (stdlib, funs)).run {}
  let file := { baseline.file with stdlib, funs }
  let procedures := inspectFile file
  let stats := summarize procedures
  let retained := stats.allowedOrigins
  let before := baseline.stats.allowedOrigins
  unless before == retained + tightening.removedOrigins do
    throw "comesfrom reachability: incoming-set reduction counts disagree"
  return {
    result := { file, procedures, stats }
    tightening := { tightening with
      conservativeOrigins := before
      retainedOrigins := retained
      unreachableJumpSites := tightening.removedOrigins } }

end CoreNice.Incoming
