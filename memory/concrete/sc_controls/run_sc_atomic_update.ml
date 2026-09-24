open Cerb_frontend
open Core
module Sc_runtime = Cerb_frontend.Sc_runtime
module M = Impl_mem
module N = Nondeterminism
module R = Sc_runtime
let empty () = Pmap.empty Stdlib.compare
let main_sym = Symbol.Symbol ("sc-protocol-control", 1, Symbol.SD_None)
let callee_sym = Symbol.Symbol ("sc-protocol-control", 40, Symbol.SD_None)
let loc = Cerb_location.other "SC ordering control"
let iv n = M.integer_ival (Z.of_int n)
let value n = Vloaded (LVspecified (OVinteger (iv n)))
let pe v = Pexpr ([], (), PEval v)
let pure v = Expr ([], Epure (pe v))
let par es = Expr ([], Epar es)
let pattern = Pattern ([], CaseBase (None, BTy_unit))
let sseq a b = Expr ([], Esseq (pattern, a, b))
let wseq a b = Expr ([], Ewseq (pattern, a, b))
let unseq es = Expr ([], Eunseq es)
let byte = Ctype.Ctype ([], Ctype.Basic (Ctype.Integer (Ctype.Unsigned Ctype.Ichar)))
let program body = {
  main=Some main_sym; calling_convention=Normal_callconv;
  tagDefs=empty (); stdlib=empty (); impl=empty (); globs=[];
  funs=Pmap.add main_sym (Proc (loc,None,BTy_unit,[],body)) (empty ());
  extern=empty (); funinfo=empty (); loop_attributes0=empty ();
  visible_objects_env=empty () }
let node (N.ND f) s = f s
let active m s = match node m s with
  | N.NDactive v, s -> v,s
  | _ -> failwith "SC control setup failed"
let initial f = Driver.initial_driver_state (Z.of_int 65536) f Sibylfs.fs_initial_state
let run f s =
  Smt2.runND Cerb_global.Exhaustive M.cs_module
    (N.nd_bind Driver.sc_enable (fun () -> Driver.drive_recorded true f ["SC test"])) s
let store ptr = Expr ([], Eaction (Paction (Pos, Action (loc, Core_run.empty_annotation,
  Store0 (false, pe (Vctype byte), pe (Vobject (OVpointer ptr)), pe (value 7), Cmm_csem.NA)))))
let atomic_byte = Ctype.Ctype ([], Ctype.Atomic byte)
let prepare_memory ?(unspecified=false) ?(readonly=false) f =
  let s = initial f in
  let a,m = active (M.allocate_object 0 (Symbol.PrefOther "first") (iv 1) atomic_byte None None) s.Driver.layout_state in
  let b,m = active (M.allocate_object 0 (Symbol.PrefOther "second") (iv 1) byte None None) m in
  let v = M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv 7) in
  let m = if unspecified then m else snd (active (M.store loc atomic_byte readonly a v) m) in
  let _,m = active (M.store loc byte false b v) m in
  a,b,{s with Driver.layout_state=m}
let effects a b s =
  let sc = Option.get s.Driver.sc_state in
  List.filter (fun e -> match e.R.sc_effect_observation with
    | Mem_common.Observe_access (_,_,_,p,_,_,_,_,_) -> p=a || p=b
    | _ -> false) (List.rev sc.R.sc_effects)
let before a b = Pset.mem (a.R.sc_effect_request.R.sc_request_thread,a.R.sc_effect_id)
    b.R.sc_effect_request.R.sc_request_annotation.Core_run_aux.sb_before
let check label good = Printf.printf "%s: %b\n%!" label good; if not good then exit 1
let update_sym = Symbol.Symbol ("sc-atomic-update-control", 50, Symbol.SD_None)
let atomic ?(update=pe (value 9)) ?(order=Cmm_csem.Seq_cst) forward pointer =
  Expr ([], Eaction (Paction (Pos, Action (loc, Core_run.empty_annotation,
    AtomicUpdate (forward, pe (Vctype byte), pe (Vobject (OVpointer pointer)), update_sym, update, order)))))
let run_body ?(unspecified=false) ?(readonly=false) make =
  let a,b,state = prepare_memory ~unspecified ~readonly (program (pure Vunit)) in
  let f = program (make a b) in
  a,b,run f {state with Driver.core_file=f}
let success = function
  | N.Active r,_,s -> not r.Driver.dres_blocked && s.Driver.sc_pending=[]
  | _ -> false
let byte_at pointer state =
  snd (fst (active (M.load loc atomic_byte pointer) (M.stop_observing state.Driver.layout_state)))
let stored n pointer state = byte_at pointer state = M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv n)
let labels a b state = List.map (fun e -> match e.R.sc_effect_request.R.sc_request_kind,e.R.sc_effect_observation with
  | R.SC_atomic_update Cmm_csem.Seq_cst, Mem_common.Observe_access (_,Mem_common.LoadAccess,_,_,_,_,_,_,_) -> "R"
  | R.SC_atomic_update Cmm_csem.Seq_cst, Mem_common.Observe_access (_,Mem_common.StoreAccess,_,_,_,_,_,_,_) -> "W"
  | _ -> "X") (effects a b state)
let grouped a b state =
  match List.filter (fun e -> match e.R.sc_effect_request.R.sc_request_kind with
    | R.SC_atomic_update _ -> true | _ -> false) (effects a b state) with
  | [r;w] -> r.R.sc_effect_request.R.sc_request_id=w.R.sc_effect_request.R.sc_request_id &&
      r.R.sc_effect_id<>w.R.sc_effect_id && not (before r w) && not (before w r)
  | _ -> false
let float_exchange bits =
  let ty = Ctype.Ctype ([], Ctype.Basic (Ctype.Floating (Ctype.RealFloating Ctype.Double))) in
  let atomic_ty = Ctype.Ctype ([], Ctype.Atomic ty) in
  let state = initial (program (pure Vunit)) in
  let u64 = Ctype.Ctype ([], Ctype.Basic (Ctype.Integer (Ctype.Unsigned Ctype.LongLong))) in
  let source,memory = active (M.allocate_object 0 (Symbol.PrefOther "bits") (iv 8) u64 None None)
    state.Driver.layout_state in
  let unsigned_bits = let z = Z.of_int64 bits in
    if Z.sign z < 0 then Z.add z (Z.shift_left Z.one 64) else z in
  let _,memory = active (M.store loc u64 false source
    (M.integer_value_mval (Ctype.Unsigned Ctype.LongLong) (M.integer_ival unsigned_bits))) memory in
  let temporary,memory = active (M.allocate_object 0 (Symbol.PrefOther "float bits") (iv 8) ty None None)
    memory in
  let _,memory = active (M.memcpy loc temporary source (iv 8)) memory in
  let (_,initial_value),memory = active (M.load loc ty temporary) memory in
  let pointer,memory = active (M.allocate_object 0 (Symbol.PrefOther "float") (iv 8) atomic_ty None None)
    memory in
  let _,memory = active (M.store loc atomic_ty false pointer initial_value) memory in
  let body = Expr ([], Eaction (Paction (Pos, Action (loc, Core_run.empty_annotation,
    AtomicUpdate (false,pe (Vctype ty),pe (Vobject (OVpointer pointer)),update_sym,
      pe (Vloaded (LVspecified (OVfloating M.one_fval))),Cmm_csem.Seq_cst))))) in
  let f=program body in
  let rows=run f {state with Driver.core_file=f;layout_state=memory} in
  rows<>[] && List.for_all (fun (outcome,_,s) -> grouped pointer pointer s &&
    match outcome with
    | N.Active r -> (match r.Driver.dres_core_value with
        | Vloaded (LVspecified (OVfloating old)) ->
            M.case_fval old (fun () -> false) (fun f -> Int64.bits_of_float f=bits)
        | _ -> false) &&
        snd (fst (active (M.load loc atomic_ty pointer) (M.stop_observing s.Driver.layout_state)))=
          M.floating_value_mval (Ctype.RealFloating Ctype.Double) M.one_fval
    | _ -> false) rows
let run_tests () =
  let action = Action (loc, (), AtomicUpdate (false, pe (Vctype byte),
    pe (Vobject (OVpointer (M.null_ptrval byte))), update_sym,
    Pexpr ([], (), PEsym update_sym), Cmm_csem.Seq_cst)) in
  let loaded = BTy_loaded OTy_integer in
  let accepted = function Exception.Result _ -> true | Exception.Exception _ -> false in
  check "Core inference returns the loaded value type"
    (match Core_typing.infer_action (empty ()) Core_typing_aux.empty_env action with
      | Exception.Result (ty, _) -> ty=loaded | _ -> false);
  check "Core checking accepts the update binder and loaded result"
    (accepted (Core_typing.typecheck_action (empty ()) Core_typing_aux.empty_env loaded action));
  check "Core checking rejects a unit result expectation"
    (not (accepted (Core_typing.typecheck_action (empty ()) Core_typing_aux.empty_env BTy_unit action)));
  let malformed = Action (loc, (), AtomicUpdate (false, pe (Vctype byte),
    pe (Vobject (OVpointer (M.null_ptrval byte))), update_sym, pe Vunit, Cmm_csem.Seq_cst)) in
  check "Core checking rejects an illtyped update"
    (not (accepted (Core_typing.typecheck_action (empty ()) Core_typing_aux.empty_env loaded malformed)));
  check "Core checking rejects negative atomic update polarity"
    (not (accepted (Core_typing.typecheck_expr Normal_callconv (empty ()) Core_typing_aux.empty_env
      loaded (Expr ([], Eaction (Paction (Neg, action)))))));
  List.iter (fun forward ->
    let a,b,rows=run_body (fun a _ -> atomic forward a) in
    check (Printf.sprintf "atomic update returns forward=%b with one completed group" forward)
      (rows<>[] && List.for_all (fun ((outcome,_,s) as row) -> success row && grouped a b s && stored 9 a s &&
        match outcome with N.Active r -> r.Driver.dres_core_value=value (if forward then 9 else 7) | _ -> false) rows)) [false;true];
  let a,b,rows=run_body (fun a b -> par [atomic false a;store b]) in
  check "atomic read and write cannot be separated by another thread"
    (rows<>[] && List.for_all (fun ((_,_,s) as row) -> success row && grouped a b s &&
        (labels a b s=["R";"W";"X"] || labels a b s=["X";"R";"W"])) rows &&
      List.exists (fun (_,_,s) -> labels a b s=["R";"W";"X"]) rows &&
      List.exists (fun (_,_,s) -> labels a b s=["X";"R";"W"]) rows);
  let a,b,rows=run_body (fun a _ -> Expr ([],Elet
      (Pattern ([],CaseBase (Some update_sym,BTy_loaded OTy_integer)), pe (value 99),
       atomic ~update:(Pexpr ([],(),PEsym update_sym)) false a))) in
  check "update binder shadows outer value and retains an equal-value write"
    (rows<>[] && List.for_all (fun ((outcome,_,s) as row) -> success row && grouped a b s && stored 7 a s &&
      match outcome with N.Active r -> r.Driver.dres_core_value=value 7 | _ -> false) rows);
  let a,b,rows=run_body ~unspecified:true (fun a _ -> atomic false a) in
  check "exchange of unspecified bytes does not introduce a CAS comparison"
    (rows<>[] && List.for_all (fun ((outcome,_,s) as row) -> success row && grouped a b s && stored 9 a s &&
      match outcome with
      | N.Active r -> (match r.Driver.dres_core_value with Vloaded (LVunspecified _) -> true | _ -> false)
      | _ -> false) rows);
  let a,b,rows=run_body (fun a _ -> atomic ~update:(pe Vunit) false a) in
  check "illformed update result retains the completed read and original bytes"
    (rows<>[] && List.for_all (fun (outcome,_,s) -> labels a b s=["R"] && stored 7 a s &&
      match outcome with
      | N.Killed (_,N.Other (Driver.DErr_core_run (Errors.Illformed_program message))) ->
          message="AtomicUpdate result does not match its object type"
      | _ -> false) rows);
  let a,b,rows=run_body ~readonly:true (fun a _ -> atomic false a) in
  check "atomic store failure retains its read and original bytes"
    (rows<>[] && List.for_all (fun (outcome,_,s) -> labels a b s=["R"] && stored 7 a s &&
      match outcome with N.Killed (_,N.Undef0 (_,[Undefined.UB064_modifying_const])) -> true | _ -> false) rows);
  check "every excluded atomic update order refuses before the object read"
    (List.for_all (fun order ->
      let a,b,rows=run_body (fun a _ -> atomic ~order false a) in
      rows<>[] && List.for_all (fun (outcome,_,s) -> effects a b s=[] && stored 7 a s &&
        match outcome with
        | N.Killed (_,N.Other (Driver.DErr_concurrency reason)) -> reason=R.SC_fault_order (R.SC_atomic_update order)
        | _ -> false) rows)
      [Cmm_csem.NA;Cmm_csem.Relaxed;Cmm_csem.Consume;Cmm_csem.Acquire;Cmm_csem.Release;Cmm_csem.Acq_rel]);
  List.iter (fun strong ->
    let a,b,rows=run_body (fun a b ->
      let pat=Pattern ([],CaseBase (None,BTy_loaded OTy_integer)) in
      Expr ([],if strong then Esseq (pat,atomic false a,store b) else Ewseq (pat,atomic false a,store b))) in
    check (Printf.sprintf "atomic completion transmits both effects across strong=%b continuation" strong)
      (rows<>[] && List.for_all (fun ((_,_,s) as row) -> success row && match effects a b s with
        | [r;w;next] -> before r next && before w next | _ -> false) rows)) [false;true];
  check "unconditional floating exchange retains identical NaN bits" (float_exchange 0x7ff8000000000001L);
  check "unconditional floating exchange retains negative zero bits" (float_exchange 0x8000000000000000L)
