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

private def annotationSuspension : IO Unit := do
  let annotations : List dyn_annotation := [
    .DA_pos [4, 8] (.FP .R 512 4), .DA_neg 9 [2, 3] (.FP .W 768 8)]
  let arena := marked (.Expr [] (.Eannot annotations unitExpr))
  let expected := .Expr [] (.Eannot annotations suffix)
  expectBoundary arena expected
  let start := { state with core_state0 := { state.core_state0 with
    thread_states := [(0, (none, thread false arena))] } }
  let config : nice_resume_config := ⟨false, file, []⟩
  let .ND action := nice_drive_loop fmapEmpty fmapEmpty config 10
    (.NiceNonmemory .NiceAfterMain fmapEmpty [0])
  match (action start).1 with
  | .NDactive (.NiceSuspended saved) =>
    match saved.suspension_state.core_state0.thread_states with
    | [(0, (_, next))] =>
      check "nonempty positive/negative annotations reach the suspension exactly"
        (saved.suspension_site == site && next.arena == expected)
    | _ => throw (IO.userError "annotated suspension lost its thread")
  | _ => throw (IO.userError "annotated completion did not suspend")

private def reconstructionTransitions : IO Unit := do
  let ptr := CerbMem.concretePtrval 3 512
  let typePE := mk_value_pe (.Vctype signed_int)
  let pointerPE := mk_value_pe (.Vobject (.OVpointer ptr))
  let load : action0 core_run_annotation :=
    .Action (.other "negative-load") default (.Load0 typePE pointerPE .NA)
  let negative : expr core_run_annotation := .Expr [] (.Eaction (.Paction .Neg0 load))
  let bounded := fun left => .Expr [] (.Ebound (marked left))
  -- Execute the real empty-inner-context negative-action rewrite.
  match production (bounded negative) with
  | [.Step_tau2 "Neg Action, CTX" .TSK_Misc next] =>
    match next.arena with
    | .Expr _ (.Ebound (.Expr _ (.Esseq pat
        (.Expr _ (.Eaction (.Paction .Pos (.Action loc _ (.Load0 ty addr .NA)))))
        (.Breakpoint seen, body)))) =>
      check "actual negative action becomes positive and retains the marked tail"
        (pat == binding && loc == .other "negative-load" && ty == typePE &&
          addr == pointerPE && seen == site && body == suffix)
    | _ => throw (IO.userError "negative-action transition lost or moved the breakpoint")
  | _ => throw (IO.userError "expected the actual negative-action CTX transition")
  -- The nonempty inner context takes a different stateful reconstruction arm.
  let inner := mk_wseq_e (mk_empty_pat .BTy_unit) negative unitExpr
  match production (bounded inner) with
  | [.Step_with_runstate2 (.RSK_tau _ .TSK_Misc) action] =>
    match action state.core_run_state0 with
    | .Result (.Defined next, runState) =>
      match next.arena with
      | .Expr _ (.Ebound (.Expr _ (.Esseq _ (.Expr _ (.Eunseq [
          .Expr _ (.Eexcluded exclusion (.Action _ _ (.Load0 ty addr .NA))), residual]))
          (.Breakpoint seen, body)))) =>
        check "stateful negative-action reconstruction retains exclusion and marked tail"
          (exclusion == state.core_run_state0.excluded_supply &&
            runState.excluded_supply == state.core_run_state0.excluded_supply + 1 &&
            ty == typePE && addr == pointerPE && seen == site && body == suffix &&
            residual == mk_wseq_e (mk_empty_pat .BTy_unit) unitExpr unitExpr)
      | _ => throw (IO.userError "stateful negative-action reconstruction lost the marked tail")
    | _ => throw (IO.userError "stateful negative-action transition failed")
  | _ => throw (IO.userError "expected the nonempty-context negative-action transition")
  -- Obtain the real RMW service request and invoke its completion callback.
  -- The supplied memory reply tests reconstruction, not allocation validity.
  let oldValue := CerbMem.MemValue.MVinteger (.Signed .Int_) (.IV .Prov_none 41)
  let newValue := CerbMem.MemValue.MVinteger (.Signed .Int_) (.IV .Prov_none 42)
  let footprint := CerbMem.Footprint.FP .W 512 4
  let rmw : expr core_run_annotation := .Expr [] (.Eaction (.Paction .Pos
    (.Action (.other "rmw") default (.SeqRMW false typePE pointerPE parameter
      (mk_value_pe (valueFromMemValue newValue).2)))))
  let rmwBinding := mk_sym_pat parameter (.BTy_loaded .OTy_integer)
  let rmwArena := .Expr [] (.Ebound (mk_breakpoint_sseq_e site rmwBinding rmw suffix))
  match production rmwArena with
  | [.Step_action_request2 "SeqRMW" _ 0 false request] =>
    match request state.core_run_state0 with
    | .Result (.Defined (.SeqRMWRequest2 ty address update complete), runState) =>
      check "actual RMW request operands" (ty == signed_int && address == ptr)
      match update oldValue runState with
      | .Result (.Defined observed, _) => check "actual RMW update expression" (observed == newValue)
      | _ => throw (IO.userError "actual RMW update failed")
      let next := complete default footprint oldValue newValue
      match next.arena with
      | .Expr _ (.Ebound (.Expr _ (.Esseq pat
          (.Expr _ (.Eannot annotations value)) (.Breakpoint seen, body)))) =>
        check "RMW callback retains fresh annotation, old value and marked tail"
          (pat == rmwBinding && seen == site && body == suffix &&
            annotations == [.DA_neg state.core_run_state0.excluded_supply [] footprint] &&
            value == mk_value_e (valueFromMemValue oldValue).2)
      | _ => throw (IO.userError "actual RMW callback lost the marked tail")
      match production next.arena with
      | [.Step_tau2 _ (.TSK_Breakpoint seen) resumed] =>
        check "reconstructed RMW reaches the original annotated cut"
          (seen == site && resumed.arena == .Expr [] (.Ebound (.Expr [] (.Eannot
            [.DA_neg state.core_run_state0.excluded_supply [] footprint] suffix))))
      | _ => throw (IO.userError "reconstructed RMW did not reach its breakpoint")
    | _ => throw (IO.userError "actual RMW request failed")
  | _ => throw (IO.userError "expected the actual RMW request transition")

def run : IO Unit := do
  expectBoundary marked suffix
  expectBoundary (marked (.Expr [] (.Eannot [] unitExpr))) (.Expr [] (.Eannot [] suffix))
  annotationSuspension
  reconstructionTransitions
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
