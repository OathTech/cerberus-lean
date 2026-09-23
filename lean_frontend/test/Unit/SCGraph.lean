import CerbSCGraph
import Unit.SCProtocolSupport

open Lem_Basic_classes

private def annotation (sb : List (Nat × Nat)) (asw dd : List Nat) : core_run_annotation :=
  ⟨setFromListBy setElemCompare sb, setFromListBy setElemCompare dd, setFromListBy setElemCompare asw⟩
private def node (id thread : Nat) (sb : List (Nat × Nat) := [])
    (asw : List Nat := []) (dd : List Nat := []) : sc_graph_node :=
  ⟨id, thread, annotation sb asw dd⟩
private def edges := setFromListBy (α := Nat × Nat) setElemCompare
private def ids := setFromListBy (α := Nat) setElemCompare
private def has (edge : Nat × Nat) (graph : sc_source_graph) :=
  setMemberBy setElemCompare edge graph.sc_graph_sbasw
private def equalEdges (xs : List (Nat × Nat)) (ys : Pset (Nat × Nat)) :=
  setEqualBy setElemCompare (edges xs) ys

private def request (id thread : Nat) (sb : List (Nat × Nat)) (asw : List Nat)
    (kind : sc_request_kind) : sc_request := ⟨id, thread, annotation sb asw [], kind, []⟩
private def effect (id : Nat) (req : sc_request) (obs : CerbMem.MemoryObservation) : sc_effect :=
  ⟨id, req, obs⟩

private def checks : List (String × Bool) := Id.run do
  let independent := sc_build_source_graph [node 30 0, node 20 0, node 10 1]
  let chain := sc_build_source_graph [node 40 0 [(0,30)], node 30 0 [] [20],
    node 20 1 [] [10], node 10 0]
  let dataOnly := sc_build_source_graph [node 2 0 [] [] [1], node 1 0]
  let duplicate := sc_build_source_graph [node 1 0, node 1 1]
  let missing := sc_build_source_graph [node 2 0 [(0,1)] [3] [4]]
  let owner := sc_build_source_graph [node 3 0 [(0,2)], node 2 1, node 1 0]
  let label := sc_build_source_graph [node 2 0 [(9,1)], node 1 0]
  let localAsw := sc_build_source_graph [node 2 0 [] [1], node 1 0]
  let cyclic := sc_build_source_graph [node 2 0 [(0,1)], node 1 0 [(0,2)]]
  let req := request 99 0 [] [] (SC_lifetime Pos)
  let obs := Observe_varargs Varargs_create 0
  let first := effect 1 req obs
  let fence := request 2 0 [(0,1)] [] (SC_fence Seq_cst)
  let last := effect 3 (request 100 0 [(0,2)] [] (SC_runtime "after fence")) obs
  let state := { sc_initial_state with sc_effects := [last,first], sc_fences := [fence] }
  let graph := sc_prefix_graph state
  let onlyFences := sc_prefix_graph { sc_initial_state with sc_fences :=
    [request 2 1 [] [] (SC_fence Seq_cst), request 1 0 [] [] (SC_fence Seq_cst)] }
  return [
    ("journal order and fresh IDs do not create source edges", equalEdges [] independent.sc_graph_sbasw && independent.sc_graph_issues.isEmpty),
    ("closure crosses intermediate lifetime/thread vertices", chain.sc_graph_issues.isEmpty && has (10,40) chain &&
      equalEdges [(10,40)] (sc_project_sbasw (ids [10,40]) chain)),
    ("reordering the node list preserves the source relation", equalEdges
      (setToList chain.sc_graph_sbasw)
      (sc_build_source_graph chain.sc_graph_nodes.reverse).sc_graph_sbasw),
    ("data dependency is retained but does not alone create sb/asw", equalEdges [(1,2)] dataOnly.sc_graph_dd &&
      equalEdges [] dataOnly.sc_graph_sbasw && dataOnly.sc_graph_issues.isEmpty),
    ("duplicate IDs are diagnosed without deleting occurrences", duplicate.sc_graph_nodes.length == 2 &&
      duplicate.sc_graph_issues == [SC_graph_duplicate_id 1]),
    ("missing sb asw and dd predecessors remain visible", missing.sc_graph_issues ==
      [SC_graph_missing_source SC_edge_sb 1 2, SC_graph_missing_source SC_edge_asw 3 2,
       SC_graph_missing_source SC_edge_dd 4 2] && has (1,2) missing && has (3,2) missing),
    ("cross-thread sb and incorrect thread labels remain distinct", owner.sc_graph_issues ==
      [SC_graph_sb_thread_label 2 3, SC_graph_cross_thread_sb 2 3] &&
      label.sc_graph_issues == [SC_graph_sb_thread_label 1 2]),
    ("same-thread additional-sw is diagnosed", localAsw.sc_graph_issues == [SC_graph_same_thread_asw 1 2]),
    ("cycles remain diagnostic with their closure retained", cyclic.sc_graph_issues ==
      [SC_graph_cycle 1, SC_graph_cycle 2] && has (1,1) cyclic && has (2,2) cyclic),
    ("completed fences transmit source order between effects", graph.sc_graph_nodes.length == 3 &&
      graph.sc_graph_issues.isEmpty && has (1,3) graph &&
      equalEdges [(1,3)] (sc_project_sbasw (ids [1,3]) graph)),
    ("SC fences alone do not create inter-thread happens-before", onlyFences.sc_graph_nodes.length == 2 &&
      equalEdges [] onlyFences.sc_graph_sbasw && onlyFences.sc_graph_issues.isEmpty),
    ("representation-equal observations keep distinct event IDs", (sc_prefix_nodes state).map (·.sc_node_id) == [3,1,2])]

private def integration (fuel : Nat) : List (String × Bool) :=
  letI := LemFuel.mk fuel
  Id.run do
    let fence := Expr [] (Eaction (Paction Pos (Action (CerbLocation.other "graph fence")
      empty_annotation (Fence0 Seq_cst))))
    let sequence := fun a b => Expr [] (Esseq (Pattern [] (CaseBase (none, BTy_unit))) a b)
    let store := SCProtocolControls.storeExpr 20 200
    let bodies := [
      ("actual fence source paths", sequence store (sequence fence store)),
      ("actual unsequenced fence alternatives", Expr [] (Eunseq [fence,fence])),
      ("actual nested spawn/join lifetime paths", sequence
        (SCProtocolControls.parExpr [SCProtocolControls.parExpr [fence], store]) store),
      ("actual fault prefix", sequence store (SCProtocolControls.storeExpr 20 201))]
    let mut results := []
    for (label,body) in bodies do
      let traces := SCProtocolControls.runProgram (SCProtocolControls.program body) SCProtocolControls.memorySetup
      let valid := !traces.isEmpty && traces.all (fun (_, _, s) => match s.sc_state0 with
        | none => false
        | some sc =>
          let g := sc_prefix_graph sc
          g.sc_graph_issues.isEmpty && g.sc_graph_nodes.length == sc.sc_effects.length + sc.sc_fences.length)
      let active := traces.any (fun (o,_,_) => match o with | Active _ => true | _ => false)
      let fault := traces.any (fun (o,_,_) => match o with | Killed _ _ => true | _ => false)
      results := results ++ [(label,valid && if label == "actual fault prefix" then fault && !active else active && !fault)]
    return results

def main (args : List String) : IO UInt32 := do
  let [arg] := args | return 2
  let some fuel := arg.toNat? | return 2
  let mut good := true
  for (label, ok) in checks ++ integration fuel do
    IO.println s!"{label}: {ok}"
    good := good && ok
  return if good then 0 else 1
