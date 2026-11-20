import ObservationNice

/-! Local recorder policy for offered single-thread, source-ordered decisions.
The generated evaluator, arena, candidate order and ND alternatives are untouched. -/
namespace CoreNiceDiff.OfferedOrder
open CoreNice Lean

private inductive Group where
  | relational | intArithmetic | assignment | intEquality | callArguments
  deriving BEq

private structure Slot where
  owner : Option Group
  index : Nat
  arity : Nat
  deriving BEq

private def tagged (annotations : List annot) (name : String) : Bool :=
  annotations.any fun a => match a with | .Astd label => label == name | _ => false

private def integerPair : CoreNice.pattern → Bool
  | .Pattern _ (.CaseCtor .Ctuple [.Pattern _ (.CaseBase (_, .BTy_loaded .OTy_integer)),
                                  .Pattern _ (.CaseBase (_, .BTy_loaded .OTy_integer))]) => true
  | _ => false

-- Integer equality emits an unmarked Ewseq. The owned marker survives on the
-- specified branch of its *immediate* pure case tail, including on !=.
private def intEqualityTail : CoreNice.expr CoreNice.core_run_annotation → Bool
  | .Expr _ (.Epure (.Pexpr _ _ (.PEcase _ [(_, .Pexpr a _ (.PEif (.Pexpr b _ _) _ _)), _]))) =>
    tagged a "§6.5.9#3" && tagged b "§6.5.9#4, sentence 3"
  | _ => false

private def group (outer inner : List annot) (pat : CoreNice.pattern)
    (tail : CoreNice.expr CoreNice.core_run_annotation) : Option Group :=
  if tagged outer "§6.5.16#3, sentence 4" && tagged inner "§6.5.16#3, sentence 5" then
    some .assignment
  else if integerPair pat && tagged outer "§6.5.8" then some .relational
  else if integerPair pat && tagged outer "§6.5.6" then some .intArithmetic
  else if integerPair pat && intEqualityTail tail then some .intEquality
  else none

private def slots : CoreNice.context → List Slot
  | .CTX => []
  | .Cwseq outer pat (.Cunseq inner before focus after) tail =>
    ⟨group outer inner pat tail, before.length, before.length + 1 + after.length⟩ :: slots focus
  | .Csseq outer _ (.Cunseq inner before focus after) _ =>
    let owner := if tagged outer "§6.5.2.2#10, sentence 1" &&
        tagged inner "§6.5.2.2#4, sentence 2" then some .callArguments else none
    ⟨owner, before.length, before.length + 1 + after.length⟩ :: slots focus
  | .Cunseq _ before focus after =>
    ⟨none, before.length, before.length + 1 + after.length⟩ :: slots focus
  | .Cwseq _ _ focus _ | .Csseq _ _ focus _ | .Cannot _ _ focus | .Cbound _ focus => slots focus

/-- Consume an outer group only while all candidates remain in the same slot;
at a fork, select the source-first slot before descending into it. -/
private def pick : Nat → List (Nat × List Slot) → Except String Nat
  | _, [(index, _)] => .ok index
  | 0, _ => .error "source-order policy: missing distinguishing operand context"
  | fuel + 1, candidates => do
    let rows ← candidates.mapM fun (i, path) => match path with
      | s :: tail => pure (i, s, tail)
      | [] => throw "source-order policy: missing distinguishing operand context"
    let first :: _ := rows | throw "source-order policy: empty scheduler frontier"
    let info := first.2.1
    if !(rows.all fun (_, s, _) => s.owner == info.owner && s.arity == info.arity) then
      throw "source-order policy: incompatible operand groups"
    if rows.all (fun (_, s, _) => s.index == info.index) then
      return ← pick fuel (rows.map fun (i, _, tail) => (i, tail))
    let some owner := info.owner | throw "source-order policy: unknown AIL operand group"
    if owner != .callArguments && info.arity != 2 then
      throw "source-order policy: expected a binary group"
    -- Call slot zero is the designator, then source arguments in order. A
    -- value operand contributes no focus. Select the earliest outstanding
    -- offered slot, not the zero slot after its value has been obtained.
    let desired := if owner == .callArguments then
        rows.foldl (fun n row => min n row.2.1.index) info.index
      else if owner == .assignment then 1 else 0
    let keep := rows.filterMap fun (i, s, tail) => if s.index == desired then some (i, tail) else none
    pick fuel keep

private def focusName (focus : CoreNice.expr CoreNice.core_run_annotation) : String :=
  match focus with
  | .Expr _ (.Eaction (.Paction _ (.Action _ _ (.Kill ..)))) => "deallocation"
  | .Expr _ (.Eexcluded _ (.Action _ _ (.Kill ..))) => "excluded deallocation"
  | .Expr _ (.Eaction (.Paction _ (.Action _ _ (.Store0 ..)))) => "store"
  | .Expr _ (.Eaction (.Paction _ (.Action _ _ (.Load0 ..)))) => "load"
  | .Expr _ (.Eaction (.Paction _ (.Action _ _ (.Create ..)))) => "creation"
  | .Expr _ (.Eccall ..) => "call"
  | .Expr _ (.Ememop ..) => "memop"
  | _ => "other"


def select (state : CoreNice.driver_state) (kind : Choice.Kind) (parent : Json)
    (alternatives : Array Json) : Except String Nat := do
  let label := ObservationNice.stepInfo (.SK_misc ["new_drive_core_threads"])
  if kind != .nd || parent != label || !(alternatives.all (· == label)) then
    throw "source-order policy: unsupported choice source"
  let [(_, _, thread)] := state.core_state0.thread_states
    | throw "source-order policy: expected exactly one live thread"
  -- step_ctx maps one step over each get_ctx focus in list order. After
  -- find_can_advance returns none, choose_core_steps passes those same steps
  -- to ND.pick, whose alternatives preserve list order. A single thread
  -- ensures another thread could not have advanced between these phases.
  let focuses := CoreNice.get_ctx thread.arena
  if alternatives.size != focuses.length then
    throw "source-order policy: offered alternatives differ in count from reached focuses"
  let rows := focuses.zipIdx.map fun ((ctx, _), i) => (i, slots ctx)
  match pick (rows.foldl (fun n row => max n row.2.length) 0) rows with
  | .error why =>
    throw (why ++ " (offered " ++ String.intercalate ", " (focuses.map fun (_, e) => focusName e) ++ ")")
  | .ok i => return i

end CoreNiceDiff.OfferedOrder
