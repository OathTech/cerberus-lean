open Cerb_frontend
open Lem_pervasives
let sc_sequence_fixture id1 request thread kind access annotation:Sc_runtime.sc_effect=  ({
  Sc_runtime.sc_effect_id= id1;
  Sc_runtime.sc_effect_request= ({
    Sc_runtime.sc_request_id= request; Sc_runtime.sc_request_thread= thread;
    Sc_runtime.sc_request_kind= kind; Sc_runtime.sc_request_scopes= ([]);
    Sc_runtime.sc_request_annotation= annotation });
  Sc_runtime.sc_effect_observation= (Mem_common.Observe_access( Cerb_location.unknown, access,
    Ctype.signed_int, (Impl_mem.null_ptrval Ctype.signed_int), (Some( (Nat_big_num.of_int 7))),( (Nat_big_num.of_int 100)),( (Nat_big_num.of_int 4)), [],
    (Impl_mem.unspecified_mval Ctype.signed_int)));
})
let sc_sequence_ids graph history:(int*int)list=  (Lem_list.map (fun w ->
  (w.Sc_access_sequencing.sc_sequence_left.Sc_runtime.sc_effect_id,
   w.Sc_access_sequencing.sc_sequence_right.Sc_runtime.sc_effect_id))
  (Sc_access_sequencing.sc_access_sequence_witnesses graph history))
let sc_sequence_graph effects:Sc_graph.sc_source_graph=  (Sc_graph.sc_build_source_graph
  (Lem_list.map Sc_graph.sc_effect_node effects))
let sc_sequence_checks ():(string*bool)list=
   (let annotation0 = Core_run_aux.empty_annotation in
  let order = (Sc_runtime.SC_access( Cmm_csem.Seq_cst, Core.Pos)) in
  let ordinary = (Sc_runtime.SC_access( Cmm_csem.NA, Core.Pos)) in
  let read1 = (sc_sequence_fixture 1 10 0 order Mem_common.LoadAccess annotation0) in
  let second1 = (sc_sequence_fixture 3 11 0 order Mem_common.LoadAccess annotation0) in
  let modify1 annotation e=  ({ e with Sc_runtime.sc_effect_request=
    ({ e.Sc_runtime.sc_effect_request with Sc_runtime.sc_request_annotation= annotation }) }) in
  let before id1=  ({ annotation0 with Core_run_aux.sb_before=(Pset.from_list (pairCompare compare compare) [(0,id1)]) }) in
  let history = ([read1; second1]) in
  let query h=  (sc_sequence_ids (sc_sequence_graph h) h) in
  let nread = (sc_sequence_fixture 1 10 0 ordinary Mem_common.LoadAccess annotation0) in
  let nsecond = (sc_sequence_fixture 3 11 0 ordinary Mem_common.LoadAccess annotation0) in
  let middle = ({ read1 with Sc_runtime.sc_effect_id= 2;
    Sc_runtime.sc_effect_observation= (Mem_common.Observe_varargs( Mem_common.Varargs_read,( (Nat_big_num.of_int 9)))) }) in
  let update1 = (sc_sequence_fixture 1 10 0 (Sc_runtime.SC_atomic_update Cmm_csem.Seq_cst)
    Mem_common.LoadAccess annotation0) in
  let write = ({ update1 with Sc_runtime.sc_effect_id= 2;
    Sc_runtime.sc_effect_observation= (Mem_common.Observe_access( Cerb_location.unknown, Mem_common.StoreAccess,
      Ctype.signed_int, (Impl_mem.null_ptrval Ctype.signed_int), (Some( (Nat_big_num.of_int 7))),( (Nat_big_num.of_int 100)),( (Nat_big_num.of_int 4)), [],
      (Impl_mem.unspecified_mval Ctype.signed_int))) }) in
  let other = (sc_sequence_fixture 3 11 1 order Mem_common.LoadAccess annotation0) in
  let bridged = ([read1;
    sc_sequence_fixture 2 12 1 ordinary Mem_common.LoadAccess
      { annotation0 with Core_run_aux.asw_before=(Pset.from_list compare [1]) };
    modify1 { annotation0 with Core_run_aux.asw_before=(Pset.from_list compare [2]) } second1]) in
  let graph = (sc_sequence_graph bridged) in
  let broken = ([read1; modify1 (before 99) second1]) in
  [
    ("unordered SC pair retains one orientation", (listEqualBy (Lem.pair_equal (=) (=)) (query history) [(1,3)]));
    ("journal reversal does not invent ordering", (listEqualBy (Lem.pair_equal (=) (=)) (query (List.rev history)) [(1,3)]));
    ("ordinary pair is outside this sufficient query", (listEqualBy (Lem.pair_equal (=) (=)) (query [nread;nsecond]) []));
    ("mixed unordered pair is retained", (listEqualBy (Lem.pair_equal (=) (=)) (query [nread;second1]) [(1,3)]));
    ("forward source edge removes witness", (listEqualBy (Lem.pair_equal (=) (=)) (query [read1;modify1 (before 1) second1]) []));
    ("reverse source edge removes witness", (listEqualBy (Lem.pair_equal (=) (=)) (query [modify1 (before 3) read1;second1]) []));
    ("source closure passes through metadata", (listEqualBy (Lem.pair_equal (=) (=)) (query [read1;modify1 (before 1) middle;
      modify1 (before 2) second1]) []));
    ("additional-sw closure is not substituted for source order",
      (Pset.mem(1,3) graph.Sc_graph.sc_graph_sbasw && (listEqualBy (Lem.pair_equal (=) (=))
      (sc_sequence_ids graph bridged) [(1,3)])));
    ("data dependency is not source order", (listEqualBy (Lem.pair_equal (=) (=)) (query [read1;
      modify1 { annotation0 with Core_run_aux.dd_before=(Pset.from_list compare [1]) } second1]) [(1,3)]));
    ("same atomic compound is not two actions", (listEqualBy (Lem.pair_equal (=) (=)) (query [update1;write]) []));
    ("compound occurrences retain external witnesses", (listEqualBy (Lem.pair_equal (=) (=)) (query [update1;write;second1]) [(1,3);(2,3)]));
    ("cross-thread pair is outside sequencing assumption", (listEqualBy (Lem.pair_equal (=) (=)) (query [read1;other]) []));
    ("metadata does not inherit an access role", (listEqualBy (Lem.pair_equal (=) (=)) (query [middle;second1]) []));
    ("weak access order remains unavailable", (listEqualBy (Lem.pair_equal (=) (=)) (query [read1;
      sc_sequence_fixture 3 11 0 (Sc_runtime.SC_access( Cmm_csem.Relaxed, Core.Pos))
        Mem_common.LoadAccess annotation0]) []));
    ("out-of-model CAS expected phase remains unavailable", (Lem.option_equal (=)
      (Sc_access_sequencing.sc_access_request_order
        (Sc_runtime.SC_cas_expected( Cmm_csem.Seq_cst, Cmm_csem.Relaxed, Core.Pos))) None));
    ("NA expected load retains its actual role", (Lem.option_equal (=)
      (Sc_access_sequencing.sc_access_request_order
        (Sc_runtime.SC_cas_expected( Cmm_csem.Seq_cst, Cmm_csem.Seq_cst, Core.Pos))) (Some Cmm_csem.NA)));
    ("failed CAS object read retains SC role", (listEqualBy (Lem.pair_equal (=) (=)) (query [
      sc_sequence_fixture 1 10 0 (Sc_runtime.SC_cas_object Core.Pos) Mem_common.LoadAccess annotation0;
      nsecond]) [(1,3)]));
    ("protocol issues remain distinct from sequence witnesses",
      (not (Lem_list.list_null (sc_sequence_graph broken).Sc_graph.sc_graph_issues) && (listEqualBy (Lem.pair_equal (=) (=))
      (query broken) [(1,3)])))
  ])

let () =
  let checks = sc_sequence_checks () in
  List.iter (fun (label, ok) -> Printf.printf "%s: %b\n" label ok) checks;
  if not (List.for_all snd checks) then exit 1
