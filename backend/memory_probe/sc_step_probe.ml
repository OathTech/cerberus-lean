(* Native half of the WP1 experiment. Fixtures/expected counts are mirrored
   in Unit.SCWP1Stepping; execution comes from the shared Lem module. *)
open Cerb_frontend
open Core
open Core_run
open Driver
open Nondeterminism
module M = Impl_mem
let loc = Cerb_location.other "wp1-stepping"
let digest = Digest.string "wp1-stepping"
let symbol n s = Symbol.Symbol (digest, n, Symbol.SD_Id s)
let main_sym = symbol 1 "main"
let loop_sym = symbol 2 "loop"
let glob_sym = symbol 3 "global"
let spin_sym = symbol 4 "spin"
let iv n = M.integer_ival (Z.of_int n)
let uc = Ctype.Ctype ([], Ctype.Basic (Ctype.Integer (Ctype.Unsigned Ctype.Ichar)))
let si = Ctype.Ctype ([], Ctype.Basic (Ctype.Integer (Ctype.Signed Ctype.Int_)))
let answer = Vloaded (LVspecified (OVinteger (iv 42)))
let done_ = Core_aux.mk_value_e answer
let loop = Expr ([], Esave ((loop_sym, (BTy_loaded OTy_integer)), [], Expr ([], Erun (empty_annotation, loop_sym, []))))
let rec bounds = function 0 -> done_ | n -> Expr ([], Ebound (bounds (n-1)))
let empty () = Pmap.empty compare
let sym_map xs = List.fold_left (fun m (k,v) -> Pmap.add k v m) (empty ()) xs
let file_for body = {
  main= Some main_sym; calling_convention= Normal_callconv;
  tagDefs= empty (); enumDefs= empty (); stdlib= empty (); impl= Pmap.empty compare; globs= [];
  funs= sym_map [main_sym, Proc (loc, None, (BTy_loaded OTy_integer), [], body)]; extern= empty ();
  funinfo= empty (); loop_attributes0= empty (); visible_objects_env= empty ();
}
let initial file = fst (initial_driver_state_given 5 (Z.of_int 65536) digest file Sibylfs.fs_initial_state)
let enable st = Option.get (M.begin_observing st)
let start file = let st = initial file in experiment_start file [] {st with layout_state= enable st.layout_state}
let require ok msg = if not ok then failwith msg
let count st = List.length (fst (Option.get (M.take_observations st.layout_state)))
let run n cfg = experiment_bounded (List.init n (fun _ -> 0)) cfg
let incomplete = function Exp_incomplete c -> c | _ -> failwith "expected incomplete"
let stopped = function Exp_stopped (c,xs) -> c,xs | _ -> failwith "expected stopped"
let eval (ND f) st = f st
let active m st = match eval m st with NDactive v, st -> v,st | _ -> failwith "fixture primitive failed"
let th arena = { arena; stack= Stack_empty; env= [empty ()]; errno= M.null_ptrval si;
  current_loc= loc; exec_loc= ELoc_globals; current_proc_opt= None }
let finalize_placeholder () = { dres_blocked=false; dres_concurrency_state=Cmm_op.symInitialState Cmm_op.symInitialPre;
  dres_driver_steps=0; dres_core_value=Vunit; dres_stdout=""; dres_stderr="" }
let core_cfg st = { experiment_phase= Exp_core (nd_return (finalize_placeholder ())); experiment_state=st; experiment_steps=0 }
let store_arena p = Expr ([], Eaction (Paction (Pos, Action (loc, empty_annotation,
  Store0 (false, Core_aux.mk_value_pe (Vctype uc), Core_aux.mk_value_pe (Vobject (OVpointer p)),
    Core_aux.mk_value_pe (Vobject (OVinteger (iv 42))), Cmm_csem.NA)))))
let load_arena p = Expr ([], Eaction (Paction (Pos, Action (loc, empty_annotation,
  Load0 (Core_aux.mk_value_pe (Vctype uc), Core_aux.mk_value_pe (Vobject (OVpointer p)), Cmm_csem.NA)))))

let () =
  Cerb_global.set_cerb_conf ~backend_name:"SC WP1 probe" ~exec:false Cerb_global.Exhaustive
    ~concurrency:false Cerb_global.Basic ~defacto:false ~permissive:false ~agnostic:false ~ignore_bitfields:false;
  Tags.set_tagDefs (empty ());
  let cold = start (file_for (bounds 3)) in
  let untouched = incomplete (run 0 cold) in
  require (untouched.experiment_steps=0 && count untouched.experiment_state=0 &&
    untouched.experiment_state.core_state.thread_states=[]) "zero budget executed startup";
  let entered = fst (experiment_run [0] cold) in
  require (match entered.experiment_phase with Exp_core _ -> true | _ -> false) "main continuation";
  require (entered.experiment_steps=1 && count entered.experiment_state=1) "errno init";
  let finished, unused = stopped (run 10 cold) in
  require (match finished.experiment_phase with Exp_done r -> r.dres_core_value=answer | _ -> false) "final value";
  require (finished.experiment_steps=6 && List.length unused=4 && finished.experiment_state.dr_step_counter=3) "budget";
  print_endline "lifecycle: zero budget passive; main entered; 3 tau steps; finalized 42; 4 choices unused";
  List.iter (fun budget ->
    let cfg = incomplete (run budget (start (file_for loop))) in
    require (cfg.experiment_steps=budget && experiment_choice_count cfg=1) "loop singleton/budget";
    require (cfg.experiment_state.dr_step_counter=budget-1 && count cfg.experiment_state=1) "loop reduction"
  ) [1;2;7;4096];
  print_endline "singleton Core loop: incomplete at 1, 2, 7, 4096 steps; call fuel does not count loop iterations";
  let f = file_for done_ in
  let gf = {f with globs=[glob_sym, GlobalDef (((BTy_loaded OTy_integer), si), bounds 2)]} in
  require (count (incomplete (run 1 (start gf))).experiment_state=0) "global startup";
  let global_done, unused = stopped (run 20 (start gf)) in
  require (match global_done.experiment_phase with Exp_done r -> r.dres_core_value = answer | _ -> false)
    "global program did not finalize with the main value";
  require (global_done.experiment_steps=7 && List.length unused=13 && count global_done.experiment_state=1) "global budget";
  require (match global_done.experiment_state.core_state.thread_states with
    | [_, (_, {env=env::_; _})] -> Pmap.lookup glob_sym env = Some answer | _ -> false) "global env";
  let sf = {f with
    funs=sym_map [main_sym, Proc (loc,None,(BTy_loaded OTy_integer),[],done_); spin_sym, Proc (loc,None,(BTy_loaded OTy_integer),[],loop)];
    globs=[glob_sym, GlobalDef (((BTy_loaded OTy_integer),si), Expr ([],Eproc (empty_annotation,Sym spin_sym,[])))] } in
  let spinning = incomplete (run 100 (start sf)) in
  require (spinning.experiment_steps=100 && count spinning.experiment_state=0) "spinning global entered main";
  print_endline "globals: suspended before main; environment retained; looping initializer incomplete at 100";
  let p, mem = active (M.allocate_region 0 (Symbol.PrefOther "wp1") (iv 1) (iv 1)) (M.initial_mem_state (Z.of_int 65536)) in
  let _, mem = active (M.store loc uc false p (M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv 0))) mem in
  let st = initial f in
  let st = {st with layout_state=enable mem; core_state={st.core_state with thread_states=
    [0,(None,th (store_arena p)); 1,(None,th (Expr ([],Erun (empty_annotation,loop_sym,[]))))]}} in
  let cfg = core_cfg st in
  require (experiment_choice_count cfg=2 && count st=0) "discovery effect";
  let stored = experiment_step 0 cfg in
  require (count stored.experiment_state=1) "store receipt";
  let (_, v), _ = active (M.load loc uc p) (M.stop_observing stored.experiment_state.layout_state) in
  require (v = M.integer_value_mval (Ctype.Unsigned Ctype.Ichar) (iv 42)) "store value";
  print_endline "discovery: two contexts; unchosen faulty Erun untouched; selected store writes 42 once";
  let with_threads ts = {st with core_state={st.core_state with thread_states=ts}} in
  let null = with_threads [0,(None,th (load_arena (M.null_ptrval uc)))] in
  require (match (experiment_step 0 (core_cfg null)).experiment_phase with
    | Exp_killed (Undef0 (_, [Undefined.UB019_lvalue_not_an_object])) -> true | _ -> false) "null load UB";
  require (match (experiment_step 0 (core_cfg (with_threads [0,(None,th (Expr ([],Ewait 99)))]))).experiment_phase with
    | Exp_blocked -> true | _ -> false) "blocked";
  require (match (experiment_step 0 (core_cfg (with_threads []))).experiment_phase with Exp_empty -> true | _ -> false) "empty";
  require (match (experiment_step 2 cfg).experiment_phase with Exp_bad_choice -> true | _ -> false) "invalid index";
  print_endline "outcomes: UB, blocked, empty, invalid choice, done and incomplete distinguished";
  let act = SeqRMW (false, Core_aux.mk_value_pe (Vctype uc),
    Core_aux.mk_value_pe (Vobject (OVpointer p)), glob_sym,
    Core_aux.mk_value_pe (Vobject (OVinteger (iv 1)))) in
  let rmw = Expr ([], Ebound (Expr ([], Eaction (Paction (Pos, Action (loc,empty_annotation,act)))))) in
  let refused = experiment_step 0 (core_cfg (with_threads [0,(None,th rmw)])) in
  require (match refused.experiment_phase with Exp_unsupported _ -> true | _ -> false) "SeqRMW atomic shortcut";
  require (count refused.experiment_state=0 && M.serialise_mem_state digest refused.experiment_state.layout_state =
    M.serialise_mem_state digest st.layout_state) "refused SeqRMW accessed memory";
  print_endline "SeqRMW: explicitly unsupported; no load/store performed";
  if Array.length Sys.argv > 1 && Sys.argv.(1) = "selected-fault" then
    ignore (experiment_step 1 cfg)
