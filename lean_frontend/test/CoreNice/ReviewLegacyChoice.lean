import Driver
import CoreNice.Driver

/-! Review witness: marking otherwise pure strong sequences adds alternatives
to the legacy evaluator's unsequenced-expression rule. No model source changes.
Run with scripts/lean_probe.sh from a provisioned lean_frontend package. -/

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

namespace Original
private def procedure : sym := .Symbol "review-legacy-choice" 1 .SD_None
private def unitExpr : expr core_run_annotation := mk_value_e .Vunit
private def sequence : expr core_run_annotation :=
  .Expr [] (.Esseq (mk_empty_pat .BTy_unit) unitExpr unitExpr)
private def body : expr core_run_annotation := .Expr [] (.Eunseq [sequence, sequence])
private def program : file core_run_annotation := {
  (default : file core_run_annotation) with
  funs := Lem_Map.fromList [(procedure, .Proc .unknown none (.BTy_tuple [.BTy_unit, .BTy_unit]) [] body)] }
private def state : driver_state :=
  (initial_driver_state_given 100 65535 "review-legacy-choice" program CerbFS.fs_initial_state).1
private def thread : thread_state := {
  arena := body,
  stack0 := .Stack_cons (some procedure) [] .Stack_empty,
  errno := CerbMem.nullPtrval signed_int, env := [fmapEmpty],
  current_proc_opt := some procedure, exec_loc := .ELoc_normal [], current_loc := .unknown }
def transitions : List core_step :=
  core_thread_step2 fmapEmpty fmapEmpty state.layout_state program fmapEmpty fmapEmpty
    0 (none, thread)
end Original

namespace Marked
open CoreNice
private def procedure : sym := .Symbol "review-legacy-choice" 1 .SD_None
private def site (id : Nat) : nice_breakpoint_site := {
  breakpoint_procedure := procedure, breakpoint_id := id,
  breakpoint_role := .BP_internal, breakpoint_ail_path := none,
  breakpoint_location := .unknown }
private def unitExpr : CoreNice.expr CoreNice.core_run_annotation := CoreNice.mk_value_e .Vunit
private def sequence (mark : Bool) (id : Nat) : CoreNice.expr CoreNice.core_run_annotation :=
  .Expr [] (.Esseq (CoreNice.mk_empty_pat .BTy_unit) unitExpr
    ((if mark then .Breakpoint (site id) else .Continue), unitExpr))
private def body (mark : Bool) : CoreNice.expr CoreNice.core_run_annotation :=
  .Expr [] (.Eunseq [sequence mark 1, sequence mark 2])
private def program (mark : Bool) : CoreNice.file CoreNice.core_run_annotation := {
  (default : CoreNice.file CoreNice.core_run_annotation) with
  funs := Lem_Map.fromList [(procedure, .Proc .unknown none (.BTy_tuple [.BTy_unit, .BTy_unit]) [] (body mark))] }
private def state (mark : Bool) : CoreNice.driver_state :=
  (CoreNice.initial_driver_state_given 100 65535 "review-legacy-choice" (program mark) CerbFS.fs_initial_state).1
private def thread (mark : Bool) : CoreNice.thread_state := {
  arena := body mark,
  stack0 := .Stack_cons (some procedure) [] .Stack_empty,
  errno := CerbMem.nullPtrval signed_int, env := [fmapEmpty],
  current_proc_opt := some procedure, exec_loc := .ELoc_normal [], current_loc := .unknown }
def transitions (mark : Bool) : List CoreNice.core_step :=
  CoreNice.core_thread_step2 fmapEmpty fmapEmpty (state mark).layout_state (program mark) fmapEmpty fmapEmpty
    0 (none, thread mark)
end Marked

#eval do
  let original := Original.transitions.length
  let unmarked := (Marked.transitions false).length
  let marked := (Marked.transitions true).length
  unless original == 1 && unmarked == 1 && marked == 2 do
    throw (IO.userError s!"witness changed: Core={original}, Nice/Continue={unmarked}, Nice/Breakpoint={marked}")
  IO.println s!"COUNTEREXAMPLE: Core={original}, Nice/Continue={unmarked}, Nice/Breakpoint={marked} enabled legacy transitions"
  match Original.transitions, Marked.transitions false, Marked.transitions true with
  | [.Step_tau "Eunseq pure" .TSK_Misc _],
    [.Step_tau "Eunseq pure" .TSK_Misc _],
    [.Step_tau "Eunseq" .TSK_Misc _, .Step_tau "Eunseq" .TSK_Misc _] =>
      IO.println "Core collapses pure operands; marked Nice offers either operand first."
  | _, _, _ => throw (IO.userError "unexpected transition descriptors")
