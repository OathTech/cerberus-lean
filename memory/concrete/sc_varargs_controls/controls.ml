open Cerb_frontend
module V=Sc_varargs
let set xs=List.fold_left(fun s x->Pset.add x s)(Pset.empty Stdlib.compare)xs
let event aid tid id op={V.sc_va_occurrence=aid;sc_va_request=aid-1;sc_va_thread=tid;
  sc_va_identity=Z.of_int id;sc_va_operation=op}
let read=Mem_common.Varargs_read
let kinds=[Mem_common.Varargs_create;read;Mem_common.Varargs_advance;Mem_common.Varargs_delete]
let check name good=Printf.printf "%s: %b\n%!" name good;if not good then exit 1
let observed e = {Sc_runtime.sc_effect_id=e.V.sc_va_occurrence;
  sc_effect_request={Sc_runtime.sc_request_id=e.V.sc_va_request;sc_request_thread=e.V.sc_va_thread;sc_request_scopes=[];
    sc_request_annotation={Core_run_aux.sb_before=set[];asw_before=set[];dd_before=set[]};
    sc_request_kind=Sc_runtime.SC_runtime "metadata control"};
  sc_effect_observation=Mem_common.Observe_varargs(e.V.sc_va_operation,e.V.sc_va_identity)}
let () =
 check "all sixteen operation combinations" (List.for_all(fun a->List.for_all(fun b->
   V.sc_varargs_conflict (event 2 0 0 a) (event 4 1 0 b) = (a<>read || b<>read))kinds)kinds);
 check "distinct metadata identities do not conflict" (List.for_all(fun a->List.for_all(fun b->
   not(V.sc_varargs_conflict (event 2 0 0 a) (event 4 1 1 b)))kinds)kinds);
 let a=event 2 0 0 Mem_common.Varargs_advance and b=event 4 1 0 read in
 check "forward source order suppresses pair" (V.sc_varargs_unordered_pair (set[2,4]) a b=None);
 check "reverse source order suppresses pair" (V.sc_varargs_unordered_pair (set[4,2]) a b=None);
 check "occurrence ordering is only deduplication" (V.sc_varargs_unordered_pair (set[]) b a=None);
 check "unordered interthread witness" (match V.sc_varargs_unordered_pair (set[]) a b with
   Some w->w.V.sc_va_conflict_kind=V.SC_va_interthread && w.V.sc_va_conflict_left=a && w.V.sc_va_conflict_right=b|_->false);
 check "unordered same-thread witness" (match V.sc_varargs_unordered_pair (set[]) a {b with V.sc_va_thread=0} with
   Some w->w.V.sc_va_conflict_kind=V.SC_va_unsequenced|_->false);
 let unrelated={ (observed a) with Sc_runtime.sc_effect_observation=Mem_common.Observe_allocation
   (Impl_mem.null_ptrval (Ctype.Ctype([],Ctype.Void)),Z.one,Z.of_int 100,Z.of_int 4,None,None,[])} in
 let history=[observed b;unrelated;observed a;observed a] in
 check "extraction preserves order multiplicity and metadata while filtering object effects"
   (V.sc_varargs_events history=[b;a;a]);
 check "pair collection retains repeated occurrences and ignores unrelated object effects"
   (List.length(V.sc_varargs_unordered_pairs(set[])history)=2 &&
    V.sc_varargs_unordered_pairs(set[])[observed b;unrelated;observed a]=
    V.sc_varargs_unordered_pairs(set[])[observed b;observed a]);
 check "an independent later cursor leaves prior witnesses intact"
   (V.sc_varargs_unordered_pairs(set[])[observed(event 6 1 1 Mem_common.Varargs_advance);observed b;observed a]=
    V.sc_varargs_unordered_pairs(set[])[observed b;observed a])
