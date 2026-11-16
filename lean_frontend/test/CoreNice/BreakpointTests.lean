import CoreNice.Core_run
import CoreNice.Core_reduction
import CoreNice.Driver
import CoreNice.Core_rewrite

namespace CoreNice.BreakpointTests

private instance : LemFuel := ⟨10000⟩
private instance : CerbGlobal.Switches := ⟨[]⟩

private def check (label : String) (condition : Bool) : IO Unit :=
  unless condition do throw (IO.userError s!"breakpoint check failed: {label}")

private def procedure : sym := .Symbol "breakpoints" 1 (.SD_Id "procedure")
private def parameter : sym := .Symbol "breakpoints" 2 (.SD_Id "bound")
private def label : sym := .Symbol "breakpoints" 3 (.SD_Id "label")
private def site : nice_breakpoint_site := {
  breakpoint_procedure := procedure, breakpoint_id := 17,
  breakpoint_role := .BP_internal, breakpoint_ail_path := none,
  breakpoint_location := .other "boundary" }
private def unitExpr : expr core_run_annotation := mk_value_e .Vunit
private def suffix : expr core_run_annotation := mk_value_e .Vtrue
private def binding : pattern := mk_sym_pat parameter .BTy_unit
private def marked (left : expr core_run_annotation := unitExpr)
    (pat : pattern := binding) : expr core_run_annotation :=
  mk_breakpoint_sseq_e site pat left suffix
private def file : file core_run_annotation := default
private def state : driver_state :=
  (initial_driver_state_given 100 65535 "breakpoints" file CerbFS.fs_initial_state).1
private def thread (legacy : Bool) (arena : expr core_run_annotation) : thread_state := {
  arena, stack0 := if legacy then .Stack_cons (some procedure) [] .Stack_empty else .Stack_empty,
  errno := CerbMem.nullPtrval signed_int, env := [fmapEmpty],
  current_proc_opt := some procedure, exec_loc := .ELoc_normal [], current_loc := .unknown }

private def production (arena : expr core_run_annotation) : List core_step2 :=
  step_ctx fmapEmpty fmapEmpty state.layout_state file fmapEmpty 0 (none, thread false arena)

private def expectBoundary (arena expected : expr core_run_annotation) : IO Unit := do
  match production arena with
  | [.Step_tau2 _ (.TSK_Breakpoint observed) next] =>
    check "exact site" (observed == site)
    check "suffix pending" (next.arena == expected)
    check "binding already complete" (next.env == update_env binding .Vunit [fmapEmpty])
  | _ => throw (IO.userError "expected one actual breakpoint transition")

def run : IO Unit := do
  expectBoundary marked suffix
  expectBoundary (marked (.Expr [] (.Eannot [] unitExpr))) (.Expr [] (.Eannot [] suffix))
  let bad : pattern := .Pattern [] (.CaseCtor .Ctuple [binding])
  match production (marked unitExpr bad) with
  | [.Step_with_runstate2 _ action] =>
    match action state.core_run_state0 with
    | .Exception (.Illformed_program _) => pure ()
    | _ => throw (IO.userError "failed pattern did not report failure")
  | _ => throw (IO.userError "failed pattern falsely reached breakpoint")
  match core_thread_step2 fmapEmpty fmapEmpty state.layout_state file fmapEmpty fmapEmpty
      0 (none, thread true marked) with
  | [.Step_tau _ (.TSK_Breakpoint observed) action] =>
    match action state.core_run_state0 with
    | .Result (.Defined next, _) =>
      check "legacy site/binding/suffix"
        (observed == site && next.arena == suffix && next.env == update_env binding .Vunit [fmapEmpty])
    | _ => throw (IO.userError "legacy completion failed")
  | _ => throw (IO.userError "legacy completion missed breakpoint")
  let saved := .Expr [] (.Esave (label, .BTy_unit) [] unitExpr empty_nice_label_info)
  let left := mk_breakpoint_sseq_e site binding saved suffix
  let right := mk_breakpoint_sseq_e site binding unitExpr saved
  match fmapLookupBy symbol_compare label (collect_saves_aux empty_saves left).tmp_acc with
  | some (_, .Expr _ (.Esseq _ _ (.Breakpoint seen, _)), _) =>
    check "left-label suffix retains site" (seen == site)
  | _ => throw (IO.userError "left-label suffix lost breakpoint")
  match fmapLookupBy symbol_compare label (collect_saves_aux empty_saves right).tmp_acc with
  | some (_, body, _) => check "right-label entry bypasses breakpoint" (body == unitExpr)
  | none => throw (IO.userError "right label was not collected")
  let context := context.Cbound [] (.Csseq [] binding .CTX (.Breakpoint site, suffix))
  match break_at_bound_and_sseq context with
  | .BOUND_WITH_SSEQ _ _ _ _ (.Breakpoint seen, body) =>
    check "negative-action split retains whole tail" (seen == site && body == suffix)
  | _ => throw (IO.userError "boundary splitting lost breakpoint")
  check "to_pure must not erase a marked cut" ((to_pure marked).isNone)
  let candidate : expr Unit := mk_breakpoint_sseq_e site (mk_empty_pat .BTy_unit)
    (mk_value_e .Vunit) (mk_value_e .Vunit)
  for optimized in [remove_skips candidate, flatten_seqs candidate, pure_propagation2 candidate] do
    match optimized with
    | .Expr _ (.Esseq _ _ (.Breakpoint seen, _)) => check "optimizer retains site" (seen == site)
    | _ => throw (IO.userError "optimizer erased reachable breakpoint")
  IO.println "PASS: actual breakpoint rules, binding, annotations, saved labels and reconstruction"

end CoreNice.BreakpointTests

def main : IO Unit := CoreNice.BreakpointTests.run
