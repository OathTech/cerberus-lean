import Sc_spawn
import Sc_call_scope
import Core_reduction

set_option autoImplicit true
namespace CerbSCSpawn
theorem lexical_owner parent expression :
    (sc_spawn_child parent expression).current_proc_opt = parent.current_proc_opt := rfl
theorem nested_owner parent first second :
    (sc_spawn_child (sc_spawn_child parent first) second).current_proc_opt = parent.current_proc_opt := rfl
theorem environment parent expression :
    (sc_spawn_child parent expression).env = parent.env := rfl
theorem empty_stack parent expression :
    (sc_spawn_child parent expression).stack0 = Stack_empty := rfl
theorem depth_zero parent expression :
    sc_stack_depth (sc_spawn_child parent expression).stack0 = some 0 := rfl
theorem nested_not_call parent first second :
    sc_call_boundary0 (sc_spawn_child parent first)
      (sc_spawn_child (sc_spawn_child parent first) second) = SC_call_unchanged 0 := rfl
theorem original_expression parent expression :
    (sc_spawn_child parent expression).arena = expression := rfl
/-- The real reducer obtains the spawned states from the shared constructor.
The premise names its context-decomposition result, without restricting branch bodies. -/
theorem producer [LemFuel] tags context memory file extern tid parentTid
    (parent : thread_state) annotations children
    (selected : get_ctx parent.arena = [(CTX, Expr annotations (Epar children))]) :
    ∃ resume spawned, step_ctx_with tags context memory file extern tid (parentTid, parent) =
      [Step_spawn_threads2 resume spawned] ∧
      spawned.map thread_state.current_proc_opt = children.map (fun _ => parent.current_proc_opt) ∧
      spawned.map thread_state.stack0 = children.map (fun _ => Stack_empty) := by
  simp only [step_ctx_with, selected, List.map_cons, List.map_nil]
  refine ⟨_, _, rfl, ?_, ?_⟩
  · simp only [List.map_map, Function.comp_def, sc_spawn_child]
    cases h : get_loc annotations with
    | none => rfl
    | some loc => cases b : CerbLocation.isLibraryLocation loc <;> simp only [b, Bool.false_eq_true, ↓reduceIte]
  · simp only [List.map_map, Function.comp_def, sc_spawn_child]
theorem decompose_parallel annotations children :
    get_ctx (Expr annotations (Epar children)) = [(CTX, Expr annotations (Epar children))] := by
  unfold get_ctx
  cases h : CerbCoreMeasure.getCtxBound (Sum.inl (Expr annotations (Epar children))) with
  | zero =>
    have positive := CerbCoreMeasure.getCtxBound_pos (Sum.inl (Expr annotations (Epar children)))
    omega
  | succ fuel =>
    simp only [get_ctx_lemFuel]
    split <;> rfl

theorem parallel_producer [LemFuel] tags context memory file extern tid parentTid
    (parent : thread_state) annotations children :
    ∃ resume spawned,
      step_ctx_with tags context memory file extern tid
        (parentTid, {parent with arena := Expr annotations (Epar children)}) =
        [Step_spawn_threads2 resume spawned] ∧
      spawned.map thread_state.current_proc_opt = children.map (fun _ => parent.current_proc_opt) ∧
      spawned.map thread_state.stack0 = children.map (fun _ => Stack_empty) :=
  producer tags context memory file extern tid parentTid _ annotations children
    (decompose_parallel annotations children)
end CerbSCSpawn
