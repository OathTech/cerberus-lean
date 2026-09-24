open Cerb_frontend
module M=Impl_mem
let active m s = let Nondeterminism.ND f=m in match f s with
 | Nondeterminism.NDactive v, after -> v,after
 | _ -> failwith "byte fixture memory operation failed"
let run_tests () =
 let iv n=M.integer_ival (Z.of_int n) in
 let ty=Ctype.Ctype([],Ctype.Basic(Ctype.Integer(Ctype.Unsigned Ctype.Ichar))) in
 let p,s=active (M.allocate_region 0 (Symbol.PrefOther "atomic-source") (iv 1) (iv 1)) (M.initial_mem_state (Z.of_int 65536)) in
 let s=Option.get(M.begin_observing s) in
 let _,s=active(M.store (Cerb_location.other "atomic-source") ty false p
   (M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv 7)))s in
 let observations,_=Option.get(M.take_observations s) in
 let byte=match observations with
 | [Mem_common.Observe_access(_,Mem_common.StoreAccess,_,_,_,_,_,[byte],_)]->byte
 | _ -> failwith "missing actual fixture byte" in
 let atomic_checks=Sc_atomic_source_controls.sc_atomic_source_checks byte in
 let sync_checks=Sc_synchronization_controls.sc_sync_checks byte in
 let checks=atomic_checks @ sync_checks in
 List.iter(fun(name,ok)->Printf.printf "%s: %b\n" name ok)checks;
 if List.length atomic_checks <> 16 || List.length sync_checks <> 14 || not(List.for_all snd checks)then exit 1
