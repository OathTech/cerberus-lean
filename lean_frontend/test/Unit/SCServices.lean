import Unit.SCProtocolSupport
import CerbSCServices

open SCProtocolControls CerbSCOperational Lem_Basic_classes

private def loc := CerbLocation.other "SC service control"
private def thread (n : Nat) : thread_state := {
  arena := pureExpr (intval (Int.ofNat n))
  stack0 := Stack_empty
  errno := pointer 20 200
  env := []
  current_proc_opt := none
  exec_loc := ELoc_globals
  current_loc := loc }
private def setup (s : driver_state) : driver_state := { s with
  core_state0 := { s.core_state0 with
    thread_states := [(0,(none,thread 0)), (1,(some 0,thread 1)),
      (2,(some 0,thread 2)), (3,(some 0,thread 3))] }
  layout_state := { s.layout_state with
    allocations := (s.layout_state.allocations.insert 20 {base := 200, size := 4}).insert
      30 {base := 300, size := 4}
    bytemap := ([(200,7),(201,9),(202,0),(203,0),(300,0),(301,0),(302,0),(303,0)] : List (Int × UInt8)).foldl
      (fun bytes (address,value) => bytes.insert address {value := some value}) s.layout_state.bytemap } }
private def byteAt (m : sc_machine_state) (address : Int) :=
  (m.sc_driver_state.layout_state.bytemap.get? address).bind (·.value)
private def history (m : sc_machine_state) := memoryEffects m.sc_driver_state
private def savedThreads (m : sc_machine_state) := m.sc_service_state.sc_suspended_services.map sc_saved_thread
private def choiceThread : sc_service_choice → Nat
  | SC_start_service tid _ => tid
  | SC_resume_service saved => sc_saved_thread saved
private def offered [LemFuel] (m : sc_machine_state) : List sc_service_choice :=
  match m.sc_driver_state.sc_state0 with
  | none => []
  | some sc => sc_machine_choices m.sc_driver_state.core_file.tagDefs sc m
private def advance [LemFuel] (tid : Nat) (m : sc_machine_state) := do
  let choice ← (offered m).find? fun choice => choiceThread choice == tid
  pure (node (sc_start_machine_choice m.sc_driver_state.core_file.tagDefs choice) m)
private def continueState (r : nd_action sc_step_progress step_kind driver_error
    (mem_constraint CerbMem.IntegerValue) sc_machine_state × sc_machine_state) :=
  match r.1 with | NDactive SC_continue => some r.2 | _ => none
private def turn [LemFuel] (tid : Nat) (m : sc_machine_state) :=
  (advance tid m).bind continueState
private def pending (tid : Nat) (step : core_step2) (m : sc_machine_state) := { m with
  sc_driver_state := { m.sc_driver_state with
    sc_pending := (tid,step) :: m.sc_driver_state.sc_pending.filter (fun p => p.1 != tid) } }
private def copyStep (count : Int) := Step_memop_request2 empty_annotation loc Memcpy
  [Vobject (OVpointer (pointer 30 300)), Vobject (OVpointer (pointer 20 200)),
   Vobject (OVinteger (CerbMem.integerIval count))] 0 false
  (fun receipt value => { thread 0 with arena := sc_add_before_expr (receipt.2.getD default) (pureExpr value) })
private def storeStep (address n : Int) := Step_action_request2 empty_annotation Pos "store" loc 1 false
  (stExceptUndef_return (StoreRequest2 NA unsigned_char false (pointer 20 address)
    (.MVinteger (Unsigned Ichar) (CerbMem.integerIval n)) (fun _ _ => thread 11)))
private def fsStep (tid : Nat) (operation : fs_oper) := Step_fs2 empty_annotation tid (thread tid)
  (fun _ result => { thread tid with arena := Expr [] (Epure result) })
  (stExceptUndef_return (FS_oper operation))
private def initial [LemFuel] : sc_machine_state :=
  let base := setup (initial_driver_state 2 0x10000 (program (pureExpr Vunit)) CerbFS.fs_initial_state).1
  sc_machine_initial (node (sc_enable : driverM Unit) base).2

private def copyControls [LemFuel] : List (String × Bool) := Id.run do
  let base := pending 1 (storeStep 200 21) (pending 0 (copyStep 2) initial)
  let .some first := turn 0 base | return [("copy begins through offered Core request",false)]
  let .some changed := turn 1 first | return [("other thread writes while copy is paused",false)]
  let .some changed := turn 1 (pending 1 (storeStep 201 22) changed)
    | return [("other thread performs its next write",false)]
  let .some second := turn 0 changed | return [("copy resumes captured first read",false)]
  let .some third := turn 0 second | return [("copy reads current second byte",false)]
  let .some finished := turn 0 third | return [("copy writes second byte and completes",false)]
  let own := (history finished).filter fun e => e.sc_effect_request.sc_request_thread == 0
  let other := (history finished).filter fun e => e.sc_effect_request.sc_request_thread == 1
  let request := first.sc_service_state.sc_suspended_services.head?
  let owned := sc_request_state 1 (SC_runtime "interposed lifetime end") empty_annotation third.sc_driver_state
  let ended := node (driver_liftMem (CerbMem.killM loc false (pointer 30 300))) owned
  let dead := { third with sc_driver_state := ended.2 }
  let direct := node (driver_liftMem (CerbMem.storeM dead.sc_driver_state.core_file.tagDefs
    loc unsigned_char false (pointer 30 301) (.MVinteger (Unsigned Ichar) (CerbMem.integerIval 22)))) dead.sc_driver_state
  let failed := advance 0 dead
  return [
    ("first primitive yields before a write or Core completion", savedThreads first == [0] &&
      (history first).length == 1 && byteAt first 300 == some 0 &&
      first.sc_driver_state.dr_step_counter == base.sc_driver_state.dr_step_counter),
    ("saved service replaces only its owner's Core choices", (offered first).length == 4 &&
      ((offered first).filter fun c => choiceThread c == 0).all (fun c => match c with
        | SC_resume_service _ => true | _ => false)),
    ("resumed write retains captured read across other thread stores", byteAt second 200 == some 21 &&
      byteAt second 300 == some 7 && byteAt second 301 == some 0),
    ("later helper read uses current memory and completion occurs once", byteAt finished 301 == some 22 &&
      savedThreads finished == [] && finished.sc_driver_state.dr_step_counter == base.sc_driver_state.dr_step_counter &&
      (Lem_List.lookupBy (fun x y : Nat => x == y) 1 finished.sc_driver_state.core_state0.thread_states).map (·.2) == some (thread 11)),
    ("request restoration retains global history and fresh effect identities", (history finished).length == 6 &&
      ((history finished).map (fun e => e.sc_effect_id)).eraseDups.length == 6 &&
      finished.sc_driver_state.core_run_state0.aid_supply == changed.sc_driver_state.core_run_state0.aid_supply + 3 &&
      match request with | some saved => own.length == 4 && own.all (fun e =>
        e.sc_effect_request.sc_request_id == saved.sc_saved_request.sc_request_id) | none => false),
    ("internal copy order excludes intervening thread effects", own.all (fun a => own.all fun b =>
      if a.sc_effect_id < b.sc_effect_id then effectBefore a b else true) &&
      own.all (fun a => other.all fun b => !effectBefore a b && !effectBefore b a)),
    ("resumed failure rechecks lifetime and keeps completed effects", match failed, direct.1 with
      | some (NDkilled reason, after), NDkilled expected => reason == expected &&
          after.sc_driver_state.sc_state0.map (fun s => s.sc_effects.length) ==
            dead.sc_driver_state.sc_state0.map (fun s => s.sc_effects.length) &&
          after.sc_driver_state.dr_step_counter == dead.sc_driver_state.dr_step_counter &&
          after.sc_driver_state.core_state0.thread_states == dead.sc_driver_state.core_state0.thread_states
      | _, _ => false)]

private def filesystemControls [LemFuel] : List (String × Bool) := Id.run do
  let machine := initial
  let owned := sc_request_state 0 (SC_memop Va_start) empty_annotation machine.sc_driver_state
  let started := node (driver_liftMem (CerbMem.vaStart [])) owned
  let NDactive (.IV _ va) := started.1 | return [("filesystem varargs setup",false)]
  let machine := { machine with sc_driver_state := started.2 }
  let otherFS := fsStep 2 (FS_WRITE 1 ['Q'] 1)
  let tau := Step_tau2 "interposed tau" TSK_Misc (thread 33)
  let ready := pending 3 tau (pending 2 otherFS (pending 1 (storeStep 200 21) machine))
  let perform := fun address fmt => pending 0 (fsStep 0
    (FS_VSNPRINTF (pointer 30 address) (CerbMem.integerIval 4) fmt va)) ready
  let .some first := turn 0 (perform 300 ['X']) | return [("filesystem pauses after varargs read",false)]
  let .some interposed := turn 3 first | return [("non-filesystem thread remains eligible",false)]
  let .some second := turn 0 interposed | return [("filesystem resumes first character store",false)]
  let .some finished := turn 0 second | return [("filesystem terminator and completion",false)]
  let .some badFirst := turn 0 (perform 303 ['X','Y']) | return [("failing filesystem service begins",false)]
  let .some badSecond := turn 0 badFirst | return [("failing filesystem service keeps first write",false)]
  let failed := advance 0 badSecond
  return [
    ("paused filesystem service owns only filesystem scheduling", first.sc_service_state.sc_filesystem_owner == some 0 &&
      (offered first).map choiceThread == [0,1,3]),
    ("filesystem completion retains interposed Core updates and counter", savedThreads finished == [] &&
      finished.sc_service_state.sc_filesystem_owner == none && byteAt finished 300 == some 88 &&
      byteAt finished 301 == some 0 &&
      finished.sc_driver_state.dr_step_counter == ready.sc_driver_state.dr_step_counter + 2 &&
      (Lem_List.lookupBy (fun x y : Nat => x == y) 3 finished.sc_driver_state.core_state0.thread_states).map (·.2) == some (thread 33) &&
      (offered finished).any (fun c => choiceThread c == 2)),
    ("filesystem failure retains written prefix, ownership, and uncommitted completion", match failed with
      | some (NDkilled _, after) => byteAt after 303 == some 88 &&
          after.sc_service_state.sc_filesystem_owner == some 0 &&
          after.sc_driver_state.fs_state0 == ready.sc_driver_state.fs_state0 &&
          after.sc_driver_state.dr_step_counter == ready.sc_driver_state.dr_step_counter &&
          after.sc_driver_state.core_state0.thread_states == ready.sc_driver_state.core_state0.thread_states
      | _ => false)]

private def projectionControls (fuel : Nat) : List (String × Bool) :=
  letI := LemFuel.mk fuel
  Id.run do
    let base := initial
    let services := { sc_empty_services with sc_filesystem_owner := some 3 }
    let read : ndM Nat String String Unit sc_machine_state := ND fun m =>
      (NDactive (m.sc_service_state.sc_filesystem_owner.getD 99), m)
    let choose : ndM Nat String String Unit sc_machine_state := ND fun m =>
      (NDnd "duplicates" [("same",read),("same",read)], { m with sc_service_state := services })
    let projected := CerbND.runNDFuel fuel (sc_project sc_empty_services choose) base.sc_driver_state
    let fail : driverM sc_step_progress := ND fun d =>
      (NDkilled (Other (DErr_other "original failure")), { d with dr_step_counter := 91 })
    let killed := node (sc_capture_service 0 fail) { base with sc_service_state := services }
    return [
      ("projection carries returned services into every duplicate branch", projected.length == 2 &&
        projected.all fun (status,_,_) => match status with | Active n => n == 3 | _ => false),
      ("captured failure retains full current machine and original reason", match killed.1 with
        | NDkilled (Other (DErr_other message)) => message == "original failure" &&
            killed.2.sc_service_state.sc_filesystem_owner == some 3 &&
            killed.2.sc_driver_state.dr_step_counter == 91
        | _ => false)]

private def batchControl [LemFuel] : List (String × Bool) :=
  let copy := Expr [] (Ememop empty_annotation Memcpy
    [pe (Vobject (OVpointer (pointer 30 300))), pe (Vobject (OVpointer (pointer 20 200))),
     pe (Vobject (OVinteger (CerbMem.integerIval 1)))])
  let store := Expr [] (Eaction (Paction Pos (Action loc empty_annotation
    (Store0 false (pe (Vctype unsigned_char)) (pe (Vobject (OVpointer (pointer 20 200))))
      (pe (intval 21)) NA))))
  let results := runProgram (program (parExpr [copy,store]))
    (fun s => {setup s with core_state0 := s.core_state0})
  let destinations := results.map fun (_,_,s) =>
    (s.layout_state.bytemap.get? 300).bind (·.value)
  [("batch scheduler exposes an interposed store inside an actual Core copy", !results.isEmpty &&
    results.all (fun (status,_,s) => match status with
      | Active result => !result.dres_blocked && (memoryEffects s).length == 3
      | _ => false) && destinations.contains (some 7) && destinations.contains (some 21) &&
    results.any (fun (_,_,s) => match memoryEffects s with
      | [first,interposed,last] =>
          first.sc_effect_request.sc_request_id == last.sc_effect_request.sc_request_id &&
          first.sc_effect_request.sc_request_thread != interposed.sc_effect_request.sc_request_thread &&
          (match first.sc_effect_observation, interposed.sc_effect_observation, last.sc_effect_observation with
          | Observe_access _ LoadAccess _ _ _ _ _ _ _, Observe_access _ StoreAccess _ _ _ _ _ _ _,
            Observe_access _ StoreAccess _ _ _ _ _ _ _ => true
          | _, _, _ => false)
      | _ => false))]

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let controls := @copyControls ⟨fuel⟩ ++ @filesystemControls ⟨fuel⟩ ++ projectionControls fuel ++ @batchControl ⟨fuel⟩
  let mut good := true
  for (label, pass) in controls do
    IO.println s!"{label}: {pass}"
    good := good && pass
  return if good then 0 else 1
