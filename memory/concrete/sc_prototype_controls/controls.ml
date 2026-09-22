(* Actual scheduler and compatible memory/ND closure, freshly generated/built. *)
open Cerb_frontend
open Core
module D = Driver
module R = Sc_runtime
module M = Impl_mem
module N = Nondeterminism
module C = Core_reduction
module T = Core_run_aux
let loc = Cerb_location.other "SC service control"
let iv n = M.integer_ival (Z.of_int n)
let byte = Ctype.Ctype ([], Ctype.Basic (Ctype.Integer (Ctype.Unsigned Ctype.Ichar)))
let value n = M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv n)
let core_value n = Vloaded (LVspecified (OVinteger (iv n)))
let pure v = Expr ([], Epure (Pexpr ([], (), PEval v)))
let node (N.ND run) state = run state
let active operation state = match node operation state with
  | N.NDactive value, after -> value, after
  | _ -> failwith "control operation did not complete"
let check label good = Printf.printf "%s: %b\n%!" label good; if not good then exit 1
let empty () = Pmap.empty Stdlib.compare
let main_sym = Symbol.Symbol ("SC service control", 1, Symbol.SD_None)
let program = {
  main=Some main_sym; calling_convention=Normal_callconv;
  tagDefs=empty (); stdlib=empty (); impl=empty (); globs=[];
  funs=Pmap.add main_sym (Proc (loc,None,BTy_unit,[],pure Vunit)) (empty ());
  extern=empty (); funinfo=empty (); loop_attributes0=empty ();
  visible_objects_env=empty () }
let thread errno n = { T.arena=pure (core_value n); stack=T.Stack_empty; errno;
  env=[];current_proc_opt=None;exec_loc=T.ELoc_globals;current_loc=loc }
let shift pointer n = M.array_shift_ptrval pointer byte (iv n)
let byte_at machine pointer =
  let (_,read),_ = active (M.load loc byte pointer) (M.stop_observing machine.D.sc_driver_state.D.layout_state) in
  List.find_opt (fun n -> read=value n) (List.init 256 Fun.id)
let history m = List.filter (fun e -> match e.R.sc_effect_observation with
  | Mem_common.Observe_access _ -> true | _ -> false)
  (List.rev (Option.get m.D.sc_driver_state.D.sc_state).R.sc_effects)
let saved_threads m = List.map D.sc_saved_thread m.D.sc_service_state.D.sc_suspended_services
let choice_thread = function D.SC_start_service (tid,_) -> tid | D.SC_resume_service saved -> D.sc_saved_thread saved
let offered m = D.sc_machine_choices (Option.get m.D.sc_driver_state.D.sc_state) m
let advance tid m =
  let choice=List.find (fun c -> choice_thread c=tid) (offered m) in
  node (D.sc_start_machine_choice choice) m
let turn tid m = match advance tid m with
  | N.NDactive D.SC_continue, after -> after
  | N.NDkilled (N.Error0 (_,message)), _ -> failwith ("turn killed: " ^ message)
  | _ -> failwith "turn did not continue"
let pending tid step m = {m with D.sc_driver_state={m.D.sc_driver_state with D.sc_pending=
  (tid,step)::List.filter (fun (other,_) -> other<>tid) m.D.sc_driver_state.D.sc_pending}}
let copy_step src dst errno count = C.Step_memop_request2 (Core_run.empty_annotation,loc,Mem_common.Memcpy,
  [Vobject (OVpointer dst);Vobject (OVpointer src);Vobject (OVinteger (iv count))],0,false,
  (fun receipt value -> { (thread errno 0) with T.arena=Sc_order.sc_add_before_expr
    (Option.value (snd receipt) ~default:(Pset.empty Stdlib.compare)) (pure value) }))
let store_step errno pointer n = C.Step_action_request2 (Core_run.empty_annotation,Pos,"store",loc,1,false,
  State_exception_undefined.stExceptUndef_return (C.StoreRequest2 (Cmm_csem.NA,byte,false,pointer,value n,
    (fun _ _ -> thread errno 11))))
let fs_step errno tid operation = C.Step_fs2 (Core_run.empty_annotation,tid,thread errno tid,
  (fun _ result -> {(thread errno tid) with T.arena=Expr ([],Epure result)}),
  State_exception_undefined.stExceptUndef_return (C.FS_oper operation))
let before a b = Pset.mem (a.R.sc_effect_request.R.sc_request_thread,a.R.sc_effect_id)
  b.R.sc_effect_request.R.sc_request_annotation.T.sb_before
let initial () =
  let d = D.initial_driver_state (Z.of_int 0x10000) program Sibylfs.fs_initial_state in
  let src,m = active (M.allocate_region 0 (Symbol.PrefOther "source") (iv 1) (iv 4)) d.D.layout_state in
  let dst,m = active (M.allocate_region 0 (Symbol.PrefOther "destination") (iv 1) (iv 4)) m in
  let m=List.fold_left (fun s (p,n) -> snd (active (M.store loc byte false p (value n)) s)) m
    [src,7;shift src 1,9;shift src 2,0;shift src 3,0;dst,0;shift dst 1,0;shift dst 2,0;shift dst 3,0] in
  let d={d with D.layout_state=m; D.core_state={d.D.core_state with T.thread_states=
    [0,(None,thread src 0);1,(Some 0,thread src 1);2,(Some 0,thread src 2);3,(Some 0,thread src 3)]}} in
  let _,d=active D.sc_enable d in
  src,dst,D.sc_machine_initial d
let copies () =
  let src,dst,m=initial () in
  let base=pending 1 (store_step src src 21) (pending 0 (copy_step src dst src 2) m) in
  let first=turn 0 base in
  check "first primitive yields before a write or Core completion"
    (saved_threads first=[0] && List.length (history first)=1 && byte_at first dst=Some 0 &&
     first.D.sc_driver_state.D.dr_step_counter=base.D.sc_driver_state.D.dr_step_counter);
  check "saved service replaces only its owner's Core choices"
    (List.length (offered first)=4 && List.for_all (function D.SC_resume_service _ -> true | _ -> false)
      (List.filter (fun c -> choice_thread c=0) (offered first)));
  let changed=turn 1 first in
  let changed=turn 1 (pending 1 (store_step src (shift src 1) 22) changed) in
  let second=turn 0 changed in
  let third=turn 0 second in
  let finished=turn 0 third in
  let own=List.filter (fun e -> e.R.sc_effect_request.R.sc_request_thread=0) (history finished) in
  let other=List.filter (fun e -> e.R.sc_effect_request.R.sc_request_thread=1) (history finished) in
  let saved=List.hd first.D.sc_service_state.D.sc_suspended_services in
  check "resumed write retains captured read across other thread stores"
    (byte_at second src=Some 21 && byte_at second dst=Some 7 && byte_at second (shift dst 1)=Some 0);
  check "later helper read uses current memory and completion occurs once"
    (byte_at finished (shift dst 1)=Some 22 && saved_threads finished=[] &&
     finished.D.sc_driver_state.D.dr_step_counter=base.D.sc_driver_state.D.dr_step_counter &&
     snd (List.assoc 1 finished.D.sc_driver_state.D.core_state.T.thread_states)=thread src 11);
  let ids=List.map (fun e -> e.R.sc_effect_id) (history finished) in
  check "request restoration retains global history and fresh effect identities"
    (List.length ids=6 && List.length (List.sort_uniq Stdlib.compare ids)=6 &&
     finished.D.sc_driver_state.D.core_run_state.T.aid_supply=changed.D.sc_driver_state.D.core_run_state.T.aid_supply+3 &&
     List.length own=4 && List.for_all (fun e -> e.R.sc_effect_request.R.sc_request_id=saved.D.sc_saved_request.R.sc_request_id) own);
  check "internal copy order excludes intervening thread effects"
    (List.for_all (fun a -> List.for_all (fun b -> a.R.sc_effect_id>=b.R.sc_effect_id || before a b) own) own &&
     List.for_all (fun a -> List.for_all (fun b -> not (before a b) && not (before b a)) other) own);
  let owned=D.sc_request_state 1 (R.SC_runtime "interposed lifetime end") Core_run.empty_annotation third.D.sc_driver_state in
  let _,ended=active (D.driver_liftMem (M.kill loc true dst)) owned in
  let dead={third with D.sc_driver_state=ended} in
  let direct=node (D.driver_liftMem (M.store loc byte false (shift dst 1) (value 22))) dead.D.sc_driver_state in
  check "resumed failure rechecks lifetime and keeps completed effects"
    (match advance 0 dead,fst direct with
     | (N.NDkilled reason,after),N.NDkilled expected -> reason=expected &&
       (Option.get after.D.sc_driver_state.D.sc_state).R.sc_effects == (Option.get dead.D.sc_driver_state.D.sc_state).R.sc_effects &&
       after.D.sc_driver_state.D.dr_step_counter=dead.D.sc_driver_state.D.dr_step_counter &&
       after.D.sc_driver_state.D.core_state.T.thread_states == dead.D.sc_driver_state.D.core_state.T.thread_states
     | _ -> false)
let filesystems () =
  let src,dst,m=initial () in
  let owned=D.sc_request_state 0 (R.SC_memop Mem_common.Va_start) Core_run.empty_annotation m.D.sc_driver_state in
  let va,started=active (D.driver_liftMem (M.va_start [])) owned in
  let va=M.case_integer_value va Fun.id (fun () -> failwith "symbolic varargs id") in
  let m={m with D.sc_driver_state=started} in
  let ready=pending 3 (C.Step_tau2 ("interposed tau",Core_run.TSK_Misc,thread src 33))
    (pending 2 (fs_step src 2 (Core_run.FS_WRITE (Z.one,['Q'],Z.one)))
      (pending 1 (store_step src src 21) m)) in
  let perform ptr fmt=pending 0 (fs_step src 0 (Core_run.FS_VSNPRINTF (ptr,iv 4,fmt,va))) ready in
  let first=turn 0 (perform dst ['X']) in
  let interposed=turn 3 first in
  let second=turn 0 interposed in
  let finished=turn 0 second in
  check "paused filesystem service owns only filesystem scheduling"
    (first.D.sc_service_state.D.sc_filesystem_owner=Some 0 && List.map choice_thread (offered first)=[0;1;3]);
  check "filesystem completion retains interposed Core updates and counter"
    (saved_threads finished=[] && finished.D.sc_service_state.D.sc_filesystem_owner=None &&
     byte_at finished dst=Some 88 && byte_at finished (shift dst 1)=Some 0 &&
     finished.D.sc_driver_state.D.dr_step_counter=ready.D.sc_driver_state.D.dr_step_counter+2 &&
     snd (List.assoc 3 finished.D.sc_driver_state.D.core_state.T.thread_states)=thread src 33 &&
     List.exists (fun c -> choice_thread c=2) (offered finished));
  let bad_first=turn 0 (perform (shift dst 3) ['X';'Y']) in
  let bad_second=turn 0 bad_first in
  check "filesystem failure retains written prefix, ownership, and uncommitted completion"
    (match advance 0 bad_second with
     | N.NDkilled _,after -> byte_at after (shift dst 3)=Some 88 &&
       after.D.sc_service_state.D.sc_filesystem_owner=Some 0 &&
       after.D.sc_driver_state.D.fs_state == ready.D.sc_driver_state.D.fs_state &&
       after.D.sc_driver_state.D.dr_step_counter=ready.D.sc_driver_state.D.dr_step_counter &&
       after.D.sc_driver_state.D.core_state.T.thread_states == ready.D.sc_driver_state.D.core_state.T.thread_states
     | _ -> false)
let projections () =
  let _,_,base=initial () in
  let services={D.sc_empty_services with D.sc_filesystem_owner=Some 3} in
  let read=N.ND (fun m -> (N.NDactive (Option.value m.D.sc_service_state.D.sc_filesystem_owner ~default:99),m)) in
  let choose=N.ND (fun m -> (N.NDnd ("duplicates",["same",read;"same",read]),{m with D.sc_service_state=services})) in
  let projected=node (D.sc_project D.sc_empty_services choose) base.D.sc_driver_state in
  check "projection carries returned services into every duplicate branch"
    (match projected with
     | N.NDnd ("duplicates",choices),state -> List.length choices=2 &&
         List.for_all (fun (label,next) -> label="same" && fst (node next state)=N.NDactive 3) choices
     | _ -> false);
  let fail=N.ND (fun d -> (N.NDkilled (N.Other (D.DErr_other "original failure")),{d with D.dr_step_counter=91})) in
  check "captured failure retains full current machine and original reason"
    (match node (D.sc_capture_service 0 fail) {base with D.sc_service_state=services} with
     | N.NDkilled (N.Other (D.DErr_other "original failure")),after ->
         after.D.sc_service_state.D.sc_filesystem_owner=Some 3 && after.D.sc_driver_state.D.dr_step_counter=91
     | _ -> false)
let batch () =
  let src,dst,m=initial () in
  let pe v = Pexpr ([],(),PEval v) in
  let copy=Expr ([],Ememop (Core_run.empty_annotation,Mem_common.Memcpy,
    [pe (Vobject (OVpointer dst));pe (Vobject (OVpointer src));pe (Vobject (OVinteger (iv 1)))])) in
  let store=Expr ([],Eaction (Paction (Pos,Action (loc,Core_run.empty_annotation,
    Store0 (false,pe (Vctype byte),pe (Vobject (OVpointer src)),pe (core_value 21),Cmm_csem.NA))))) in
  let body=Expr ([],Epar [copy;store]) in
  let f={program with funs=Pmap.add main_sym (Proc (loc,None,BTy_unit,[],body)) (empty ())} in
  let d={m.D.sc_driver_state with D.core_file=f;
    D.core_state=(D.initial_driver_state (Z.of_int 0x10000) f Sibylfs.fs_initial_state).D.core_state} in
  let results=Smt2.runND Cerb_global.Exhaustive M.cs_module (D.drive_recorded true f ["SC test"]) d in
  let accesses d=List.filter (fun e -> match e.R.sc_effect_observation with
    | Mem_common.Observe_access (_,_,_,p,_,_,_,_,_) -> p=src || p=dst
    | _ -> false) (List.rev (Option.get d.D.sc_state).R.sc_effects) in
  let destinations=List.map (fun (_,_,d) -> byte_at {m with D.sc_driver_state=d} dst) results in
  check "batch scheduler exposes an interposed store inside an actual Core copy"
    (results<>[] && List.for_all (function N.Active r,_,d -> not r.D.dres_blocked && List.length (accesses d)=3 | _ -> false) results &&
     List.mem (Some 7) destinations && List.mem (Some 21) destinations &&
     List.exists (fun (_,_,d) -> match accesses d with
       | [read;interposed;write] ->
         read.R.sc_effect_request.R.sc_request_id=write.R.sc_effect_request.R.sc_request_id &&
         read.R.sc_effect_request.R.sc_request_thread<>interposed.R.sc_effect_request.R.sc_request_thread &&
         (match read.R.sc_effect_observation,interposed.R.sc_effect_observation,write.R.sc_effect_observation with
          | Mem_common.Observe_access (_,Mem_common.LoadAccess,_,_,_,_,_,_,_),
            Mem_common.Observe_access (_,Mem_common.StoreAccess,_,_,_,_,_,_,_),
            Mem_common.Observe_access (_,Mem_common.StoreAccess,_,_,_,_,_,_,_) -> true
          | _ -> false)
       | _ -> false) results)
let typed_faults () =
  let src,_,machine=initial () in
  let enabled=machine.D.sc_driver_state in
  let base={enabled with D.sc_state=None;D.layout_state=M.stop_observing enabled.D.layout_state} in
  let uninitialized=node (D.sc_step ()) (D.sc_machine_initial base) in
  check "uninitialized step keeps state and exposes the protocol identity"
    (match uninitialized with
     | N.NDkilled (N.Other (D.DErr_concurrency R.SC_fault_uninitialized)),after ->
         after.D.sc_driver_state.D.sc_state=None &&
         after.D.sc_driver_state.D.layout_state == base.D.layout_state &&
         after.D.sc_driver_state.D.dr_step_counter=base.D.dr_step_counter
     | _ -> false);
  let unowned=node (D.driver_liftMem (M.load loc byte src)) enabled in
  check "unowned memory failure exposes identity and preserves the actual read"
    (match unowned with
     | N.NDkilled (N.Other (D.DErr_concurrency reason)),after ->
         reason=R.SC_fault_unowned_memory_node && R.sc_fault_class reason=R.SC_failure_protocol &&
         R.sc_fault_message reason="SC port gap: unowned memory node" &&
         (match M.take_observations after.D.layout_state with
          | Some ([Mem_common.Observe_access (_,Mem_common.LoadAccess,_,_,_,_,_,_,_)],_) -> true
          | _ -> false)
     | _ -> false);
  let owned=D.sc_request_state 0 (R.SC_access (Cmm_csem.NA,Pos)) Core_run.empty_annotation enabled in
  let unavailable=D.sc_post_memory {owned with D.layout_state=M.stop_observing owned.D.layout_state} in
  check "missing observer has a separate observation identity"
    (match fst unavailable with Some (N.Other (D.DErr_concurrency reason)) ->
      reason=R.SC_fault_observer_unavailable && R.sc_fault_class reason=R.SC_failure_observation | _ -> false);
  let shape=node D.sc_cas_read_representation enabled in
  check "invalid direct CAS phase reports protocol failure without inventing a read"
    (match shape with N.NDkilled (N.Other (D.DErr_concurrency R.SC_fault_cas_read_shape)),after ->
      (Option.get after.D.sc_state).R.sc_effects=[] | _ -> false);
  let initial=D.initial_driver_state (Z.of_int 0x10000) program Sibylfs.fs_initial_state in
  let public=Smt2.runND Cerb_global.Exhaustive M.cs_module (D.drive true program ["typed fault control"]) initial in
  check "public entry remains explicit about pending checker after execution"
    (public<>[] && List.for_all (function N.Killed (_,N.Other (D.DErr_concurrency reason)),_,after ->
      reason=R.SC_fault_checker_pending && R.sc_fault_class reason=R.SC_failure_unimplemented &&
      (Option.get after.D.sc_state).R.sc_effects<>[] | _ -> false) public)

let diagnostic_cases = [
  (R.SC_fault_unowned_memory_node, "SC port gap: unowned memory node", R.SC_failure_protocol);
  (R.SC_fault_observer_unavailable, "SC port gap: memory observer unavailable", R.SC_failure_observation);
  (R.SC_fault_observer_lost, "SC port gap: observer state lost", R.SC_failure_protocol);
  (R.SC_fault_unowned_memory_effect, "SC port gap: unowned memory effect", R.SC_failure_protocol);
  (R.SC_fault_cas_no_owner, "SC compare-exchange phase has no owner", R.SC_failure_protocol);
  (R.SC_fault_cas_outside_mode, "SC compare-exchange requested outside SC mode", R.SC_failure_protocol);
  (R.SC_fault_rmw_no_owner, "SC ordinary RMW phase has no owner", R.SC_failure_protocol);
  (R.SC_fault_rmw_outside_mode, "SC ordinary RMW phase requested outside SC mode", R.SC_failure_protocol);
  (R.SC_fault_cas_read_shape, "SC compare-exchange has no unique completed read", R.SC_failure_protocol);
  (R.SC_fault_unspecified_representation, "SC representation gap: compare-exchange has unspecified bytes", R.SC_failure_representation);
  (R.SC_fault_representation_size, "SC representation gap: compare-exchange read sizes differ", R.SC_failure_representation);
  (R.SC_fault_fence_outside_mode, "SC fence requested outside SC mode", R.SC_failure_protocol);
  (R.SC_fault_fence_owner, "SC fence has no matching owned request", R.SC_failure_protocol);
  (R.SC_fault_order (R.SC_access (Cmm_csem.NA,Pos)), "SC model excludes the requested memory order", R.SC_failure_order);
  (R.SC_fault_uninitialized, "SC state is not initialized", R.SC_failure_protocol);
  (R.SC_fault_checker_pending, "SC port gap: atomic/race/fence checker integration pending", R.SC_failure_unimplemented);
  (R.SC_fault_suspension_unavailable, "SC port gap: memory suspension unavailable", R.SC_failure_observation);
  (R.SC_fault_resume_outside_mode, "SC service resumed without SC state", R.SC_failure_protocol);
  (R.SC_fault_suspend_outside_mode, "SC service suspended without SC state", R.SC_failure_protocol);
  (R.SC_fault_suspend_no_owner, "SC service suspension has no owner", R.SC_failure_protocol);
  (R.SC_fault_suspend_wrong_thread, "SC service suspension changed its thread owner", R.SC_failure_protocol);
]
let diagnostics () =
  check "all existing SC diagnostics retain their text and category"
    (List.length diagnostic_cases=21 && List.for_all (fun (fault,message,category) ->
      R.sc_fault_message fault=message && R.sc_fault_class fault=category) diagnostic_cases)

let () = Tags.set_tagDefs program.tagDefs; copies (); filesystems (); projections (); batch (); typed_faults (); diagnostics ()
