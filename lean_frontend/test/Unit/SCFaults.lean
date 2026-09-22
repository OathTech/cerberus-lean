import Unit.SCProtocolSupport
import CerbSCFaults

open SCProtocolControls

private def diagnosticCases : List (sc_fault × String × sc_fault_category) := [
  (SC_fault_unowned_memory_node, "SC port gap: unowned memory node", SC_failure_protocol),
  (SC_fault_observer_unavailable, "SC port gap: memory observer unavailable", SC_failure_observation),
  (SC_fault_observer_lost, "SC port gap: observer state lost", SC_failure_protocol),
  (SC_fault_unowned_memory_effect, "SC port gap: unowned memory effect", SC_failure_protocol),
  (SC_fault_cas_no_owner, "SC compare-exchange phase has no owner", SC_failure_protocol),
  (SC_fault_cas_outside_mode, "SC compare-exchange requested outside SC mode", SC_failure_protocol),
  (SC_fault_rmw_no_owner, "SC ordinary RMW phase has no owner", SC_failure_protocol),
  (SC_fault_rmw_outside_mode, "SC ordinary RMW phase requested outside SC mode", SC_failure_protocol),
  (SC_fault_cas_read_shape, "SC compare-exchange has no unique completed read", SC_failure_protocol),
  (SC_fault_unspecified_representation, "SC representation gap: compare-exchange has unspecified bytes", SC_failure_representation),
  (SC_fault_representation_size, "SC representation gap: compare-exchange read sizes differ", SC_failure_representation),
  (SC_fault_fence_outside_mode, "SC fence requested outside SC mode", SC_failure_protocol),
  (SC_fault_fence_owner, "SC fence has no matching owned request", SC_failure_protocol),
  ((SC_fault_order (SC_access NA Pos)), "SC model excludes the requested memory order", SC_failure_order),
  (SC_fault_uninitialized, "SC state is not initialized", SC_failure_protocol),
  (SC_fault_checker_pending, "SC port gap: atomic/race/fence checker integration pending", SC_failure_unimplemented),
  (SC_fault_suspension_unavailable, "SC port gap: memory suspension unavailable", SC_failure_observation),
  (SC_fault_resume_outside_mode, "SC service resumed without SC state", SC_failure_protocol),
  (SC_fault_suspend_outside_mode, "SC service suspended without SC state", SC_failure_protocol),
  (SC_fault_suspend_no_owner, "SC service suspension has no owner", SC_failure_protocol),
  (SC_fault_suspend_wrong_thread, "SC service suspension changed its thread owner", SC_failure_protocol)
]

private def controls (fuel : Nat) : List (String × Bool) := Id.run do
  letI := LemFuel.mk fuel
  let f := program (pureExpr Vunit)
  let base := memorySetup (initial_driver_state 2 0x10000 f CerbFS.fs_initial_state).1
  let enabled := (CerbSCOperational.node
    (sc_enable : ndM Unit step_kind driver_error (mem_constraint CerbMem.IntegerValue) driver_state) base).2
  let uninitialized := CerbSCOperational.node (sc_step f.tagDefs ()) (sc_machine_initial base)
  let unowned := CerbSCOperational.node (driver_liftMem
    (CerbMem.loadM f.tagDefs (CerbLocation.other "typed SC fault") unsigned_char (pointer 20 200))) enabled
  let unavailable := sc_post_memory
    { (sc_request_state 0 (SC_access NA Pos) empty_annotation enabled) with
      layout_state := { enabled.layout_state with observations := none } }
  let badReadShape := CerbSCOperational.node
    (sc_cas_read_representation : ndM (List CerbMem.AbsByte) step_kind driver_error
      (mem_constraint CerbMem.IntegerValue) driver_state) enabled
  let publicEntry := CerbND.runND (drive f.tagDefs true f ["typed fault control"]) base
  return [
    ("all existing SC diagnostics retain their text and category", diagnosticCases.length == 21 &&
      diagnosticCases.all fun (fault,message,category) => sc_fault_message fault == message && sc_fault_class fault == category),
    ("uninitialized step keeps state and exposes the protocol identity", match uninitialized.1 with
      | NDkilled (Other (DErr_concurrency SC_fault_uninitialized)) =>
          uninitialized.2.sc_driver_state.sc_state0 == none && uninitialized.2.sc_driver_state.layout_state.bytemap == base.layout_state.bytemap &&
          uninitialized.2.sc_driver_state.dr_step_counter == base.dr_step_counter
      | _ => false),
    ("unowned memory failure exposes identity and preserves the actual read", match unowned.1 with
      | NDkilled (Other (DErr_concurrency reason)) => reason == SC_fault_unowned_memory_node &&
          sc_fault_class reason == SC_failure_protocol &&
          sc_fault_message reason == "SC port gap: unowned memory node" &&
          (match CerbMem.takeObservations unowned.2.layout_state with
           | some ([Observe_access _ LoadAccess _ _ _ _ _ _ _], _) => true | _ => false)
      | _ => false),
    ("missing observer has a separate observation identity", match unavailable.1 with
      | some (Other (DErr_concurrency reason)) => reason == SC_fault_observer_unavailable &&
          sc_fault_class reason == SC_failure_observation
      | _ => false),
    ("invalid direct CAS phase reports protocol failure without inventing a read", match badReadShape.1 with
      | NDkilled (Other (DErr_concurrency SC_fault_cas_read_shape)) => (memoryEffects badReadShape.2).isEmpty
      | _ => false),
    ("public entry remains explicit about pending checker after execution",
      !publicEntry.isEmpty && publicEntry.all fun (outcome, _, s) => match outcome, s.sc_state0 with
        | Killed _ (Other (DErr_concurrency reason)), some sc =>
            reason == SC_fault_checker_pending && sc_fault_class reason == SC_failure_unimplemented &&
            !sc.sc_effects.isEmpty
        | _, _ => false)]

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  for (label, pass) in controls fuel do
    IO.println s!"{label}: {pass}"
    good := good && pass
  return if good then 0 else 1
