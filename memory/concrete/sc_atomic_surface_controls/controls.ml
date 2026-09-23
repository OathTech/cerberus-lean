(* Paired with Unit.SCAtomicSurface: actual production driver, retained prefixes,
   typed refusals and source ordering. No public SC verdict is inferred. *)
open Cerb_frontend
open Core
module M = Impl_mem
module N = Nondeterminism
module S = Sc_runtime
let empty () = Pmap.empty Stdlib.compare
let loc = Cerb_location.other "SC model-gap control"
let main_sym = Symbol.Symbol ("sc-surface-control",1,Symbol.SD_None)
let update_sym = Symbol.Symbol ("sc-surface-control",70,Symbol.SD_None)
let iv n = M.integer_ival (Z.of_int n)
let value n = Vloaded (LVspecified (OVinteger (iv n)))
let pe v = Pexpr ([],(),PEval v)
let pure v = Expr ([],Epure (pe v))
let pattern = Pattern ([],CaseBase (None,BTy_unit))
let seq a b = Expr ([],Esseq (pattern,a,b))
let byte = Ctype.Ctype ([],Ctype.Basic (Ctype.Integer (Ctype.Unsigned Ctype.Ichar)))
let atomic_byte = Ctype.Ctype ([],Ctype.Atomic byte)
let program body = {
  main=Some main_sym; calling_convention=Normal_callconv;
  tagDefs=empty (); stdlib=empty (); impl=empty (); globs=[];
  funs=Pmap.add main_sym (Proc (loc,None,BTy_unit,[],body)) (empty ());
  extern=empty (); funinfo=empty (); loop_attributes0=empty ();
  visible_objects_env=empty () }
let active (N.ND f) s = match f s with
  | N.NDactive v,s -> v,s | _ -> failwith "surface setup failed"
let run ?(atomic=false) make =
  let object_type = if atomic then atomic_byte else byte in
  let s = Driver.initial_driver_state (Z.of_int 65536) (program (pure Vunit)) Sibylfs.fs_initial_state in
  let a,m = active (M.allocate_object 0 (Symbol.PrefOther "first") (iv 1) object_type None None) s.Driver.layout_state in
  let b,m = active (M.allocate_object 0 (Symbol.PrefOther "second") (iv 1) byte None None) m in
  let v = M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv 7) in
  let _,m = active (M.store loc object_type false a v) m in
  let _,m = active (M.store loc byte false b v) m in
  let file = program (make a b) in
  let rows = Smt2.runND Cerb_global.Exhaustive M.cs_module
    (N.nd_bind Driver.sc_enable (fun () -> Driver.drive_recorded true file ["SC surface test"]))
    {s with Driver.core_file=file;layout_state=m} in
  a,b,rows
let effects a b s = List.filter (fun e -> match e.S.sc_effect_observation with
  | Mem_common.Observe_access (_,_,_,p,_,_,_,_,_) -> p=a || p=b
  | _ -> false) (List.rev (Option.get s.Driver.sc_state).S.sc_effects)
let stored ?(atomic=false) a s =
  let (_,v),_ = active (M.load loc (if atomic then atomic_byte else byte) a) (M.stop_observing s.Driver.layout_state) in
  v=M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv 7)
let store a = Expr ([],Eaction (Paction (Pos,Action (loc,Core_run.empty_annotation,
  Store0 (false,pe (Vctype byte),pe (Vobject (OVpointer a)),pe (value 7),Cmm_csem.NA)))))
let gap_pe gap = Pexpr ([],(),PEmodel_gap (loc,gap))
let gap_expr gap = Expr ([],Epure (gap_pe gap))
let signal order = Expr ([],Eaction (Paction (Pos,Action (loc,Core_run.empty_annotation,SignalFence order))))
let is_gap gap = function
  | N.Killed (_,N.Other (Driver.DErr_core_run (Errors.Model_gap (at,actual)))),_,_ -> at=loc && actual=gap
  | _ -> false
let successful = function N.Active r,_,_ -> not r.Driver.dres_blocked | _ -> false
let all pred xs = xs<>[] && List.for_all pred xs
let check label pass = Printf.printf "%s: %b\n%!" label pass; if not pass then exit 1
let before a b = Pset.mem (a.S.sc_effect_request.S.sc_request_thread,a.S.sc_effect_id)
  b.S.sc_effect_request.S.sc_request_annotation.Core_run_aux.sb_before
let () =
  Tags.set_tagDefs (empty ());
  List.iter (fun gap ->
    let name = Core.core_model_gap_name gap in
    let a,b,rows=run (fun _ _ -> gap_expr gap) in
    check (name^": direct typed refusal") (all (fun ((_,_,s) as row) -> is_gap gap row && effects a b s=[] && stored a s) rows);
    let a,b,rows=run (fun a _ -> seq (store a)
      (Expr ([],Elet (pattern,gap_pe gap,pure Vunit)))) in
    check (name^": unused result retains prior equal-value write")
      (all (fun ((_,_,s) as row)->is_gap gap row && List.length(effects a b s)=1 && stored a s) rows);
    let _,_,rows=run (fun _ _ -> Expr ([],Epure (Pexpr ([],(),PEctor (Ctuple,[pe Vunit;gap_pe gap]))))) in
    check (name^": constructor traversal preserves refusal") (all (is_gap gap) rows);
    let a,b,rows=run (fun _ _ -> Expr ([],Eif (pe Vfalse,gap_expr gap,pure (value 3)))) in
    check (name^": unselected branch remains executable") (all (function
      | N.Active r,_,s -> r.Driver.dres_core_value=value 3 && effects a b s=[] | _ -> false) rows);
    let a,b,rows=run (fun a _ -> Expr ([],Eunseq [gap_expr gap;store a])) in
    check (name^": unsequenced alternatives retain their own prefixes")
      (all (fun ((_,_,s) as row)->is_gap gap row && stored a s) rows &&
       List.exists (fun (_,_,s)->effects a b s=[]) rows &&
       List.exists (fun (_,_,s)->List.length(effects a b s)=1) rows);
    let a,b,rows=run ~atomic:true (fun a _ -> Expr ([],Eaction (Paction (Pos,Action (loc,Core_run.empty_annotation,
      AtomicUpdate (false,pe (Vctype byte),pe (Vobject (OVpointer a)),update_sym,gap_pe gap,Cmm_csem.Seq_cst)))))) in
    check (name^": failed atomic update retains read without store")
      (all (fun ((_,_,s) as row)->is_gap gap row && stored ~atomic:true a s && match effects a b s with
        | [{S.sc_effect_observation=Mem_common.Observe_access (_,Mem_common.LoadAccess,_,_,_,_,_,_,_);_}] -> true
        | _ -> false) rows);
    let _,_,rows=run (fun _ _ -> seq (Expr ([],Epure (Pexpr ([],(),PEundef (loc,Undefined.UB045a_division_by_zero))))) (gap_expr gap)) in
    check (name^": prior C fault remains C fault") (all (function
      | N.Killed (_,N.Undef0 (_,[Undefined.UB045a_division_by_zero])),_,_ -> true | _ -> false) rows)
  ) [Model_gap_unspecified_atomic_order;Model_gap_pointer_atomic_fetch];
  let open Cmm_csem in
  let orders=[Relaxed;Consume;Acquire;Release;Acq_rel;Seq_cst] in
  check "all six signal orders retain exact occurrences without memory effects"
    (List.for_all (fun order -> let a,b,rows=run(fun _ _->signal order) in
      all (fun ((_,_,s) as row)->successful row && effects a b s=[] &&
        match (Option.get s.Driver.sc_state).S.sc_fences with
        | [r] -> r.S.sc_request_kind=S.SC_signal_fence order | _ -> false) rows) orders);
  let a,b,rows=run(fun a b->seq (store a) (seq (signal Seq_cst) (store b))) in
  check "signal occurrence transmits source order between actual accesses"
    (all(fun ((_,_,s) as row)->successful row && match effects a b s,(Option.get s.Driver.sc_state).S.sc_fences with
      | [a;b],[f] -> before a b &&
        Pset.mem (a.S.sc_effect_request.S.sc_request_thread,a.S.sc_effect_id) f.S.sc_request_annotation.Core_run_aux.sb_before &&
        Pset.mem (f.S.sc_request_thread,f.S.sc_request_id) b.S.sc_effect_request.S.sc_request_annotation.Core_run_aux.sb_before
      | _ -> false) rows);
  let _,_,rows=run(fun _ _->Expr ([],Epar [signal Relaxed;signal Seq_cst])) in
  check "parallel signal fences do not acquire source synchronization"
    (all(fun ((_,_,s) as row)->successful row &&
      let sc=Option.get s.Driver.sc_state in let g=Sc_graph.sc_prefix_graph sc in
      g.Sc_graph.sc_graph_issues=[] &&
      List.length g.Sc_graph.sc_graph_nodes=List.length sc.S.sc_effects+List.length sc.S.sc_fences &&
      match sc.S.sc_fences with
      | [a;b] -> a.S.sc_request_thread<>b.S.sc_request_thread &&
        not(Pset.mem a.S.sc_request_id b.S.sc_request_annotation.Core_run_aux.asw_before) &&
        not(Pset.mem b.S.sc_request_id a.S.sc_request_annotation.Core_run_aux.asw_before)
      | _ -> false) rows);
  let expected=[[Relaxed];[Relaxed;Consume];[Relaxed;Consume;Acquire];
    [Relaxed];[Relaxed;Consume;Acquire];[Relaxed;Consume;Acquire;Seq_cst]] in
  check "all 36 CAS order pairs match the independent strength table"
    (List.for_all2 (fun success allowed->List.for_all(fun failure->
      Atomic_order.atomic_compare_orders_error success failure =
      if List.mem failure allowed then None else Some Undefined.UB207_atomic_compare_exchange_memorder) orders) orders expected)
