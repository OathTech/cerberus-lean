import Driver
import CoreNice.Driver
import Core_rewrite
import CoreNice.Core_rewrite

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

namespace OriginalExtra
private def procedure : sym := .Symbol "repair-review" 1 .SD_None
private def unitExpr : expr core_run_annotation := mk_value_e .Vunit
private def failure : expr core_run_annotation := mk_pure_e (mk_undef_pe .unknown .UB035_unsequenced_race)
private def sequence : expr core_run_annotation :=
  .Expr [] (.Esseq (mk_empty_pat .BTy_unit) failure unitExpr)
private def body : expr core_run_annotation := .Expr [] (.Eunseq [sequence, unitExpr])
private def program : file core_run_annotation := {
  (default : file core_run_annotation) with
  funs := Lem_Map.fromList [(procedure, .Proc .unknown none (.BTy_tuple [.BTy_unit, .BTy_unit]) [] body)] }
private def state : driver_state :=
  (initial_driver_state_given 100 65535 "repair-review" program CerbFS.fs_initial_state).1
private def thread : thread_state := {
  arena := body, stack0 := .Stack_cons (some procedure) [] .Stack_empty,
  errno := CerbMem.nullPtrval signed_int, env := [fmapEmpty],
  current_proc_opt := some procedure, exec_loc := .ELoc_normal [], current_loc := .unknown }
private def run : Nat → thread_state → IO String
  | 0, _ => throw (IO.userError "budget exhausted")
  | n+1, th => do
    match core_thread_step2 fmapEmpty fmapEmpty state.layout_state program fmapEmpty fmapEmpty 0 (none, th) with
    | [.Step_tau _ _ action] | [.Step_eval _ action] =>
      match action state.core_run_state0 with
      | .Result (.Defined next, _) => run n next
      | .Result (.Undef _ _, _) => pure "UB"
      | .Result (.Error _ _, _) => pure "modeled error"
      | .Exception _ => pure "error"
    | [.Step_done _] => pure "done"
    | _ => throw (IO.userError "unexpected original step")
def outcome : IO String := run 20 thread
def collapseSkipsUndef : Bool := to_pure sequence == some (mk_value_pe .Vunit)
def rewriteSkipsUndef : Bool := rewrite_expr body ==
  mk_pure_e (mk_tuple_pe [mk_value_pe .Vunit, mk_value_pe .Vunit])
private def runOptimized : Nat → thread_state → IO String
  | 0, _ => throw (IO.userError "optimized budget exhausted")
  | n+1, th => do
    match step_ctx fmapEmpty fmapEmpty state.layout_state program fmapEmpty 0 (none, th) with
    | [.Step_tau2 _ _ next] => runOptimized n next
    | [.Step_with_runstate2 _ action] =>
      match action state.core_run_state0 with
      | .Result (.Defined next, _) => runOptimized n next
      | .Result (.Undef _ _, _) => pure "UB"
      | .Result (.Error _ _, _) => pure "modeled error"
      | .Exception _ => pure "error"
    | _ => throw (IO.userError "unexpected original optimized step")
def optimizedOutcome : IO String := runOptimized 20 { thread with stack0 := .Stack_empty }
end OriginalExtra

namespace MarkedExtra
open CoreNice
private def procedure : sym := .Symbol "repair-review" 1 .SD_None
private def site : nice_breakpoint_site := {
  breakpoint_procedure := procedure, breakpoint_id := 1,
  breakpoint_role := .BP_internal, breakpoint_origin := .NiceInternal,
  breakpoint_location := .unknown }
private def unitExpr : CoreNice.expr CoreNice.core_run_annotation := CoreNice.mk_value_e .Vunit
private def failure : CoreNice.expr CoreNice.core_run_annotation :=
  CoreNice.mk_pure_e (CoreNice.mk_undef_pe .unknown .UB035_unsequenced_race)
private def sequence : CoreNice.expr CoreNice.core_run_annotation :=
  .Expr [] (.Esseq (CoreNice.mk_empty_pat .BTy_unit) failure (.Breakpoint site, unitExpr))
private def body : CoreNice.expr CoreNice.core_run_annotation := .Expr [] (.Eunseq [sequence, unitExpr])
private def program : CoreNice.file CoreNice.core_run_annotation := {
  (default : CoreNice.file CoreNice.core_run_annotation) with
  funs := Lem_Map.fromList [(procedure, .Proc .unknown none (.BTy_tuple [.BTy_unit, .BTy_unit]) [] body)] }
private def state : CoreNice.driver_state :=
  (CoreNice.initial_driver_state_given 100 65535 "repair-review" program CerbFS.fs_initial_state).1
private def thread : CoreNice.thread_state := {
  arena := body, stack0 := .Stack_cons (some procedure) [] .Stack_empty,
  errno := CerbMem.nullPtrval signed_int, env := [fmapEmpty],
  current_proc_opt := some procedure, exec_loc := .ELoc_normal [], current_loc := .unknown }
private def run : Nat → CoreNice.thread_state → IO String
  | 0, _ => throw (IO.userError "budget exhausted")
  | n+1, th => do
    match CoreNice.core_thread_step2 fmapEmpty fmapEmpty state.layout_state program fmapEmpty fmapEmpty 0 (none, th) with
    | [.Step_tau _ _ action] | [.Step_eval _ action] =>
      match action state.core_run_state0 with
      | .Result (.Defined next, _) => run n next
      | .Result (.Undef _ _, _) => pure "UB"
      | .Result (.Error _ _, _) => pure "modeled error"
      | .Exception _ => pure "error"
    | [.Step_done _] => pure "done"
    | _ => throw (IO.userError "unexpected marked step")
def outcome : IO String := run 20 thread
private def runOptimized : Nat → Nat → CoreNice.thread_state → IO (String × Nat)
  | 0, _, _ => throw (IO.userError "optimized budget exhausted")
  | n+1, visits, th => do
    match CoreNice.step_ctx fmapEmpty fmapEmpty state.layout_state program fmapEmpty 0 (none, th) with
    | [.Step_tau2 _ kind next] =>
      let visits := match kind with | .TSK_Breakpoint _ => visits + 1 | _ => visits
      runOptimized n visits next
    | [.Step_with_runstate2 _ action] =>
      match action state.core_run_state0 with
      | .Result (.Defined next, _) => runOptimized n visits next
      | .Result (.Undef _ _, _) => pure ("UB", visits)
      | .Result (.Error _ _, _) => pure ("modeled error", visits)
      | .Exception _ => pure ("error", visits)
    | _ => throw (IO.userError "unexpected marked optimized step")
def optimizedOutcome : IO (String × Nat) := runOptimized 20 0 { thread with stack0 := .Stack_empty }
end MarkedExtra

#eval do
  let original ← OriginalExtra.outcome
  let marked ← MarkedExtra.outcome
  IO.println s!"Core={original}; marked Nice={marked}; collapse erases UB={OriginalExtra.collapseSkipsUndef}"
  unless original == "done" && marked == "UB" && OriginalExtra.collapseSkipsUndef do
    throw (IO.userError "witness changed")
  IO.println s!"Original Core rewrite erases UB={OriginalExtra.rewriteSkipsUndef}"
  unless OriginalExtra.rewriteSkipsUndef do
    throw (IO.userError "rewrite witness changed")
  let optimizedOriginal ← OriginalExtra.optimizedOutcome
  let optimizedMarked ← MarkedExtra.optimizedOutcome
  IO.println s!"Optimized Core={optimizedOriginal}; optimized marked Nice={optimizedMarked.1}; visits={optimizedMarked.2}"
  unless optimizedOriginal == "UB" && optimizedMarked == ("UB", 0) do
    throw (IO.userError "optimized control changed")
