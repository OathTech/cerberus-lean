(* Actual production Driver and ND, not a replacement runner. *)
open Cerb_frontend
open Core
module D=Driver
module N=Nondeterminism
module T=Core_run_aux
module M=Impl_mem
module R=Sc_runtime
let loc=Cerb_location.other "filesystem Driver controls"
let n=Z.of_int
let iv k=M.integer_ival(n k)
let byte=Ctype.Ctype([],Ctype.Basic(Ctype.Integer(Ctype.Unsigned Ctype.Ichar)))
let value k=M.integer_value_mval(Ctype.Unsigned Ctype.Ichar)(iv k)
let core_value k=Vloaded(LVspecified(OVinteger(iv k)))
let pure v=Expr([],Epure(Pexpr([],(),PEval v)))
let empty ()=Pmap.empty Stdlib.compare
let main_sym=Symbol.Symbol("filesystem Driver controls",1,Symbol.SD_None)
let program={main=Some main_sym;calling_convention=Normal_callconv;tagDefs=empty();
 stdlib=empty();impl=empty();globs=[];
 funs=Pmap.add main_sym(Proc(loc,None,BTy_unit,[],pure Vunit))(empty());
 extern=empty();funinfo=empty();loop_attributes0=empty();visible_objects_env=empty()}
let thread={T.arena=pure(core_value 17);stack=T.Stack_empty;errno=M.null_ptrval Ctype.signed_int;
 env=[];current_proc_opt=None;exec_loc=T.ELoc_globals;current_loc=loc}
let node (N.ND run) state=run state
let active operation state=match node operation state with
 | N.NDactive value,after -> value,after | _ -> failwith "control setup failed"
let check label good=Printf.printf "%s: %b\n%!" label good;if not good then exit 1
let same_fs left right=Sexplib.Sexp.to_string(Sibylfs.sexp_of_fs_state left)=
 Sexplib.Sexp.to_string(Sibylfs.sexp_of_fs_state right)
let history state=List.filter(fun e->match e.R.sc_effect_observation with
 | Mem_common.Observe_access _ -> true | _ -> false)(Option.get state.D.sc_state).R.sc_effects
let operation state op=D.drive_fs_step_with(fun _ th->{th with T.arena=pure(core_value 99)}) 0 thread state op
let memory_fault=function N.NDkilled(N.Undef0 _)->true | _->false
let fs_fault=function N.NDkilled(N.Other(D.DErr_filesystem _))->true | _->false
let byte_at state ptr=
 let (_,read),_=active(M.load loc byte ptr)(M.stop_observing state.D.layout_state)in
 List.find_opt(fun k->read=value k)(List.init 256 Fun.id)
let run_tests () =
 let fs,_=Sibylfs.run_open Sibylfs.fs_initial_state "/file"(n 40)(Some(n 420))in
 let fs,_=Sibylfs.run_write fs(n 3)['A';'B'](n 2)in
 let fs,_=Sibylfs.run_lseek fs(n 3)(n 0)(n 0)in
 let base=D.initial_driver_state(n 65536)program fs in
 let src,mem=active(M.allocate_region 0(Symbol.PrefOther "source")(iv 1)(iv 1))base.D.layout_state in
 let dst,mem=active(M.allocate_region 0(Symbol.PrefOther "destination")(iv 1)(iv 1))mem in
 let base={base with D.layout_state=mem;D.dr_step_counter=7;D.core_state={T.thread_states=[0,(None,thread)];T.io={base.D.core_state.T.io with T.stdout=Dlist.singleton "prefix"}}}in
 let _,enabled=active D.sc_enable base in
 let ready=D.sc_request_state 0(R.SC_runtime "filesystem control")Core_run.empty_annotation enabled in
 let _,state=active(D.driver_liftMem(M.store loc byte false src(value 9)))ready in
 let umask,umask_st=node(operation state(Core_run.FS_UMASK(n 63)))state in
 let special,special_st=node(operation state(Core_run.FS_OPEN("/file",n 64,None)))state in
 let short,short_st=node(operation state(Core_run.FS_WRITE(n 3,['x'],n 2)))state in
 let faults=[umask_st;special_st;short_st]in
 check "prior memory store is recorded"(byte_at state src=Some 9 && List.length(history state)=1);
 check "umask fails with completed leaf state"(fs_fault umask && match umask_st.D.fs_boundary_failure with
 | Some(receipt,Fs_checked.Upstream_decode("return_nat","(RV_file_perm(File_perm 18))"))->
   let expected,_=Fs_checked.run_umask fs(n 63)in same_fs receipt expected
 | _->false);
 check "open special remains distinct"(match special with
 | N.NDkilled(N.Other(D.DErr_filesystem(Fs_checked.Upstream_special(Fs_checked.Tau,Fs_spec.Fs_types.Undefined,_))))->true | _->false);
 check "short-buffer leaf remains distinct"(match short with
 | N.NDkilled(N.Other(D.DErr_filesystem(Fs_checked.Upstream_leaf(Fs_checked.Tau,_))))->true | _->false);
 check "faults retain committed filesystem"(List.for_all(fun st->same_fs st.D.fs_state state.D.fs_state)faults);
 check "faults retain prior memory and effects"(List.for_all(fun st->byte_at st src=Some 9 && st.D.sc_state==state.D.sc_state)faults);
 check "faults retain output prefix"(List.for_all(fun st->Dlist.toList st.D.core_state.T.io.T.stdout=["prefix"])faults);
 check "faults do not complete Core or increment counter"(List.for_all(fun st->st.D.core_state==state.D.core_state && st.D.dr_step_counter=7)faults);
 let buffer,buffer_st=node(operation state(Core_run.FS_READ(n 3,dst,n 2)))state in
 check "read buffer fault retains completed first store"(memory_fault buffer && byte_at buffer_st dst=Some 65 && List.length(history buffer_st)=2);
 check "read buffer fault retains old filesystem commit"(same_fs buffer_st.D.fs_state state.D.fs_state && buffer_st.D.fs_boundary_failure=None && buffer_st.D.dr_step_counter=7);
 let errno,errno_st=node(operation state(Core_run.FS_CLOSE(n 77)))state in
 check "errno store fault is not a filesystem boundary"(memory_fault errno && errno_st.D.fs_boundary_failure=None && same_fs errno_st.D.fs_state state.D.fs_state && errno_st.D.dr_step_counter=7);
 let output,output_st=node(operation state(Core_run.FS_WRITE(n 1,['o';'k'],n 2)))state in
 check "numeric stdout routing stays in Driver"(match output with N.NDactive()->
 Dlist.toList output_st.D.core_state.T.io.T.stdout=["prefix";"ok"] && same_fs output_st.D.fs_state state.D.fs_state && output_st.D.fs_boundary_failure=None | _->false);
 let good,good_st=node(operation state(Core_run.FS_LSEEK(n 3,n 1,n 0)))state in
 let _,position=Sibylfs.run_lseek good_st.D.fs_state(n 3)(n 0)(n 1)in
 check "successful seek commits and invokes completion"(match good with N.NDactive()->
 good_st.D.dr_step_counter=8 && position=Either.Right 1 &&
 (snd(List.assoc 0 good_st.D.core_state.T.thread_states)).T.arena=pure(core_value 99) | _->false);
 let alternatives=N.ND(fun st->N.NDnd(D.SK_misc["filesystem alternatives"],[
 D.SK_done,operation st(Core_run.FS_UMASK(n 63));
 D.SK_done,operation st(Core_run.FS_READ(n 3,dst,n 2));
 D.SK_done,operation st(Core_run.FS_LSEEK(n 3,n 1,n 0));
 D.SK_done,operation st(Core_run.FS_UMASK(n 63))]),st)in
 let rows=Smt2.runND Cerb_global.Exhaustive M.cs_module alternatives state in
 let kinds=List.map(fun(status,_,_)->match status with
 | N.Active _->"active" | N.Killed(_,N.Other(D.DErr_filesystem _))->"filesystem"
 | N.Killed(_,N.Undef0 _)->"memory" | N.Killed _->"other")rows in
 check "exhaustive runner preserves faults success duplicates and order"
 (kinds=["filesystem";"active";"memory";"filesystem"])
