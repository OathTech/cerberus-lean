import CerbSCOperational

/-! Complete-machine laws. Saved services are part of the operational state;
the batch interface projects them into its continuations. These laws concern
the actual definitions and make no Cmm or ISO completeness claim. -/
namespace CerbSCServices
open CerbSCOperational

/-- All offered machine choices, including service precedence and filesystem
ownership. This statement retains the actual list multiplicities operationally;
its membership view neither equates nor compares saved computations. -/
theorem choices_iff [LemFuel] tags (sc : sc_state) (machine : sc_machine_state)
    (choice : sc_service_choice) :
    choice ∈ sc_machine_choices tags sc machine ↔
      ∃ tid thInfo, (tid, thInfo) ∈ machine.sc_driver_state.core_state0.thread_states ∧
        (match Lem_List.find (fun saved => sc_saved_thread saved == tid)
            machine.sc_service_state.sc_suspended_services with
        | some saved => choice = SC_resume_service saved
        | none => ∃ step, (tid, step) ∈ sc_thread_choices tags tid thInfo sc machine.sc_driver_state ∧
            (!sc_is_filesystem_step step || sc_filesystem_available tid machine.sc_service_state) = true ∧
            choice = SC_start_service tid step) := by
  simp only [sc_machine_choices]
  constructor
  · intro h
    rcases List.mem_flatten.mp h with ⟨xs, hxs, hx⟩
    rcases List.mem_map.mp hxs with ⟨⟨tid, thInfo⟩, hthread, rfl⟩
    refine ⟨tid, thInfo, hthread, ?_⟩
    cases found : Lem_List.find (fun saved => sc_saved_thread saved == tid)
        machine.sc_service_state.sc_suspended_services with
    | some saved => simpa only [found, List.mem_singleton] using hx
    | none =>
      simp only [found] at hx ⊢
      rcases List.mem_map.mp hx with ⟨⟨other, step⟩, hoffered, heq⟩
      rcases List.mem_filter.mp hoffered with ⟨hstep, havailable⟩
      have same : other = tid := by
        simp only [sc_thread_choices] at hstep
        cases pending : Lem_List.lookupBy (fun x y : Nat => x == y) tid
            machine.sc_driver_state.sc_pending with
        | some p =>
          simp only [pending, List.mem_singleton, Prod.mk.injEq] at hstep
          exact hstep.1
        | none =>
          simp only [pending] at hstep
          rcases List.mem_map.mp hstep with ⟨_, _, h⟩
          exact (Prod.mk.inj h).1.symm
      cases same
      exact ⟨step, hstep, havailable, heq.symm⟩
  · rintro ⟨tid, thInfo, hthread, hchoice⟩
    apply List.mem_flatten.mpr
    refine ⟨_, List.mem_map.mpr ⟨(tid, thInfo), hthread, rfl⟩, ?_⟩
    cases found : Lem_List.find (fun saved => sc_saved_thread saved == tid)
        machine.sc_service_state.sc_suspended_services with
    | some saved => simpa only [found, List.mem_singleton] using hchoice
    | none =>
      simp only [found] at hchoice ⊢
      rcases hchoice with ⟨step, hstep, havailable, rfl⟩
      exact List.mem_map.mpr ⟨(tid, step), List.mem_filter.mpr ⟨hstep, havailable⟩, rfl⟩

/-- Resumption restores only the saved ownership and receipt. Memory, journal,
fresh supplies, filesystem, and the current thread map come from the new state. -/
theorem restore_current (saved : sc_saved_service) (state : driver_state)
    (current : sc_state) (h : state.sc_state0 = some current) :
    sc_restore_service saved state = (none, { state with
      sc_state0 := some { current with
        sc_current_request := some saved.sc_saved_request
        sc_current_effects := saved.sc_saved_effects } }) := by
  simp only [sc_restore_service, h]

theorem killed_keeps_machine (fuel tid : Nat) (reason : kill_reason driver_error)
    (state : sc_machine_state) (after : driver_state) :
    node (sc_capture_service_lemFuel (fuel + 1) tid
      (ND (fun _ => (NDkilled reason, after)))) state =
      (NDkilled reason, {state with sc_driver_state := after}) := rfl

/-- The saved continuation is the one produced by the selected service, with
its actual receipt. The surrounding machine retains every other saved service. -/
theorem suspension_saved (fuel tid : Nat) (continuation : driverM sc_step_progress)
    (state : sc_machine_state) (after : driver_state) (current : sc_state)
    (request : sc_request) (hsc : after.sc_state0 = some current)
    (hrequest : current.sc_current_request = some request)
    (hthread : request.sc_request_thread = tid) :
    node (sc_capture_service_lemFuel (fuel + 1) tid
      (ND (fun _ => (NDsuspend continuation, after)))) state =
      let services := sc_drop_saved tid state.sc_service_state
      sc_machine_return { services with sc_suspended_services :=
        { sc_saved_request := request, sc_saved_effects := current.sc_current_effects,
          sc_saved_computation := continuation } :: services.sc_suspended_services }
        SC_continue {state with sc_driver_state := after} := by
  simp [node, sc_capture_service_lemFuel, hsc, hrequest, hthread,
    Lem_Basic_classes.isEqual, BEq.beq, Lem_Basic_classes.setElemCompare, defaultCompare]

theorem capture_duplicates (fuel tid : Nat) label
    (choices : List (step_kind × driverM sc_step_progress))
    (state : sc_machine_state) (after : driver_state) :
    node (sc_capture_service_lemFuel (fuel + 1) tid
      (ND (fun _ => (NDnd label choices, after)))) state =
      (NDnd label (choices.map fun (label, next) =>
        (label, sc_capture_service_lemFuel fuel tid next)), {state with sc_driver_state := after}) := rfl

variable {α info err cs : Type}

/-- The exact action projection: every continuation carries the service state
returned by this node. Duplicate branches and all failure constructors remain. -/
def projectAction (fuel : Nat) (services : sc_services) :
    nd_action α info err cs sc_machine_state → nd_action α info err cs driver_state
  | NDactive value => NDactive value
  | NDkilled reason => NDkilled reason
  | NDsuspend next => NDsuspend (sc_project_lemFuel fuel services next)
  | NDguard label condition next => NDguard label condition (sc_project_lemFuel fuel services next)
  | NDbranch label condition first second => NDbranch label condition
      (sc_project_lemFuel fuel services first) (sc_project_lemFuel fuel services second)
  | NDnd label choices => NDnd label (choices.map fun (label, next) =>
      (label, sc_project_lemFuel fuel services next))
  | NDstep label choices => NDstep label (choices.map fun (label, next) =>
      (label, sc_project_lemFuel fuel services next))

theorem projection_node (fuel : Nat) (services : sc_services)
    (operation : ndM α info err cs sc_machine_state) (state : driver_state) :
    node (sc_project_lemFuel (fuel + 1) services operation) state =
      let result := node operation {sc_driver_state := state, sc_service_state := services}
      (projectAction fuel result.2.sc_service_state result.1, result.2.sc_driver_state) := by
  cases operation with
  | ND run =>
    simp only [node, sc_project_lemFuel]
    generalize run {sc_driver_state := state, sc_service_state := services} = result
    rcases result with ⟨action, machine⟩
    cases action <;> rfl

end CerbSCServices
