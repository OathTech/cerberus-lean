import Sc_graph

/-! Laws over the generated graph adapter. Source order only: no claim of full
hb, location interpretation, Cmm consistency or a whole-program verdict. -/
namespace CerbSCGraph

/-- The graph retains every input occurrence, even when diagnostics exist. -/
theorem nodes_retained (nodes : List sc_graph_node) :
    (sc_build_source_graph nodes).sc_graph_nodes = nodes := rfl

/-- Representation payloads never identify or deduplicate vertices. -/
theorem observation_independent (effect : sc_effect) observation :
    sc_effect_node { effect with sc_effect_observation := observation } =
      sc_effect_node effect := rfl

/-- Effect vertices precede fence vertices only in this returned list. The
adapter does not interpret that list order as a relation. -/
theorem prefix_nodes (state : sc_state) :
    (sc_prefix_graph state).sc_graph_nodes =
      state.sc_effects.map sc_effect_node ++ state.sc_fences.map sc_fence_node := rfl

theorem occurrence_count (state : sc_state) :
    (sc_prefix_graph state).sc_graph_nodes.length =
      state.sc_effects.length + state.sc_fences.length := by
  simp only [prefix_nodes, List.length_append, List.length_map]

/-- An owned pending request or its in-progress receipt is not a completed
extra occurrence. Its completed effects already appear in the journal. -/
theorem pending_independent (state : sc_state) request receipt :
    sc_prefix_graph { state with sc_current_request := request, sc_current_effects := receipt } =
      sc_prefix_graph state := rfl

end CerbSCGraph
