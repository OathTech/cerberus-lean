open Cerb_frontend
module G = Sc_graph
module S = Sc_runtime
let set xs = List.fold_left (fun s x -> Pset.add x s) (Pset.empty Stdlib.compare) xs
let annotation sb asw dd = {Core_run_aux.sb_before=set sb;asw_before=set asw;dd_before=set dd}
let node ?(sb=[]) ?(asw=[]) ?(dd=[]) id thread =
  {G.sc_node_id=id;sc_node_thread=thread;sc_node_annotation=annotation sb asw dd}
let graph = G.sc_build_source_graph
let equal xs s = Pset.equal (set xs) s
let has edge g = Pset.mem edge g.G.sc_graph_sbasw
let request id thread sb asw kind = {S.sc_request_id=id;sc_request_thread=thread;sc_request_scopes=[];
  sc_request_annotation=annotation sb asw [];sc_request_kind=kind}
let observed id req obs = {S.sc_effect_id=id;sc_effect_request=req;sc_effect_observation=obs}
let () =
  let independent=graph [node 30 0;node 20 0;node 10 1] in
  let chain=graph [node ~sb:[0,30] 40 0;node ~asw:[20] 30 0;
    node ~asw:[10] 20 1;node 10 0] in
  let data=graph [node ~dd:[1] 2 0;node 1 0] in
  let duplicate=graph [node 1 0;node 1 1] in
  let missing=graph [node ~sb:[0,1] ~asw:[3] ~dd:[4] 2 0] in
  let owner=graph [node ~sb:[0,2] 3 0;node 2 1;node 1 0] in
  let label=graph [node ~sb:[9,1] 2 0;node 1 0] in
  let local_asw=graph [node ~asw:[1] 2 0;node 1 0] in
  let cyclic=graph [node ~sb:[0,1] 2 0;node ~sb:[0,2] 1 0] in
  let req=request 99 0 [] [] (S.SC_lifetime Core.Pos) in
  let obs=Mem_common.Observe_varargs(Mem_common.Varargs_create,Z.zero) in
  let first=observed 1 req obs in
  let fence=request 2 0 [0,1] [] (S.SC_fence Cmm_csem.Seq_cst) in
  let last=observed 3 (request 100 0 [0,2] [] (S.SC_runtime "after fence")) obs in
  let state={S.sc_initial_state with S.sc_effects=[last;first];sc_fences=[fence]} in
  let g=G.sc_prefix_graph state in
  let only_fences=G.sc_prefix_graph {S.sc_initial_state with S.sc_fences=
    [request 2 1 [] [] (S.SC_fence Cmm_csem.Seq_cst);request 1 0 [] [] (S.SC_fence Cmm_csem.Seq_cst)]} in
  let checks=[
    "journal order and fresh IDs do not create source edges",equal [] independent.G.sc_graph_sbasw && independent.G.sc_graph_issues=[];
    "closure crosses intermediate lifetime/thread vertices",chain.G.sc_graph_issues=[] && has(10,40)chain && equal [10,40](G.sc_project_sbasw(set[10;40])chain);
    "reordering the node list preserves the source relation",Pset.equal chain.G.sc_graph_sbasw (graph(List.rev chain.G.sc_graph_nodes)).G.sc_graph_sbasw;
    "data dependency is retained but does not alone create sb/asw",equal [1,2] data.G.sc_graph_dd && equal [] data.G.sc_graph_sbasw && data.G.sc_graph_issues=[];
    "duplicate IDs are diagnosed without deleting occurrences",List.length duplicate.G.sc_graph_nodes=2 && duplicate.G.sc_graph_issues=[G.SC_graph_duplicate_id 1];
    "missing sb asw and dd predecessors remain visible",missing.G.sc_graph_issues=[G.SC_graph_missing_source(G.SC_edge_sb,1,2);G.SC_graph_missing_source(G.SC_edge_asw,3,2);G.SC_graph_missing_source(G.SC_edge_dd,4,2)] && has(1,2)missing && has(3,2)missing;
    "cross-thread sb and incorrect thread labels remain distinct",owner.G.sc_graph_issues=[G.SC_graph_sb_thread_label(2,3);G.SC_graph_cross_thread_sb(2,3)] && label.G.sc_graph_issues=[G.SC_graph_sb_thread_label(1,2)];
    "same-thread additional-sw is diagnosed",local_asw.G.sc_graph_issues=[G.SC_graph_same_thread_asw(1,2)];
    "cycles remain diagnostic with their closure retained",cyclic.G.sc_graph_issues=[G.SC_graph_cycle 1;G.SC_graph_cycle 2] && has(1,1)cyclic && has(2,2)cyclic;
    "completed fences transmit source order between effects",List.length g.G.sc_graph_nodes=3 && g.G.sc_graph_issues=[] && has(1,3)g && equal [1,3](G.sc_project_sbasw(set[1;3])g);
    "SC fences alone do not create inter-thread happens-before",List.length only_fences.G.sc_graph_nodes=2 && equal [] only_fences.G.sc_graph_sbasw && only_fences.G.sc_graph_issues=[];
    "representation-equal observations keep distinct event IDs",List.map(fun n->n.G.sc_node_id)(G.sc_prefix_nodes state)=[3;1;2]] in
  List.iter(fun(label,ok)->Printf.printf "%s: %b\n" label ok)checks;
  if not(List.for_all snd checks)then exit 1
