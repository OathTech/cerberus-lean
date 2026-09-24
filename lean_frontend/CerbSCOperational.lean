import Driver
import Sc_order_auxiliary
import CerbNDObserveProofs
import CerbND

/-! Laws for the actual SC draft operations. These give no axiomatic-Cmm or
whole-program definedness claim. Caller-selected fuel remains explicit. -/
namespace CerbSCOperational
open Lem_Set Lem_Basic_classes

/-- Initialize the actual whole-program SC computation over the linked Core
file produced by the C pipeline. Fuel and address space are caller parameters;
the returned supply is the real constructor's remaining fresh-name supply.
Missing origin evidence is retained as `none`, with the driver's usual refusal.
The computation includes global initialization, main and finalization. -/
def start (fuel supply : Nat) (addressSpaceTop : Int)
    (file : generic_file Unit core_run_annotation) (filesystem : CerbFS.FsState)
    (origins : Option sc_link_origins) (args : List String) : sc_program × Nat :=
  @sc_program_start ⟨fuel⟩ file.tagDefs supply addressSpaceTop file args filesystem origins

/-- The existing bounded runner over that same configuration. `budget` bounds
ND-tree depth; the semantic workers retain the fuel captured at initialization.
The CLI chooses the same number for both bounds. No fuel is renewed at resume. -/
def outcomes (budget : Nat) (program : sc_program) :=
  CerbND.runNDFuel budget program.sc_program_continuation program.sc_program_state

/-- Only a result of the outer computation is terminal. Blocking is the original
`dres_blocked` flag. A kill keeps its exact typed UB/fault/unsupported cause or
the distinguished fuel-exhaustion reason, together with all prefix findings.
The raw `sc_program_node` also preserves empty choices and constraints. -/
def terminal (program : sc_program) :
    Option (nd_status driver_result driver_error driver_state × driver_state) :=
  let (action, after) := sc_program_node program
  match action with
  | NDactive result => some (Active result, after)
  | NDkilled reason => some (Killed after reason, after)
  | _ => none

/-- This is the actual CLI computation at the same parameters, not a separate
transition system or an existential claim about sufficiently large fuel. -/
theorem outcomes_entry [LemFuel] tags state args :
    outcomes LemFuel.fuel (sc_program_entry tags state args) =
      CerbND.runND (drive tags true state.core_file args) state := rfl

/-- A suspended or selected computation is reused verbatim, retaining the
services and outer initialization/main/finalization binds in its closure. -/
theorem resumed_node state continuation :
    sc_program_node (sc_program_resume state continuation) =
      (match continuation with | ND run => run state) := rfl

theorem terminal_failure program reason after
    (observed : sc_program_node program = (NDkilled reason, after)) :
    terminal program = some (Killed after reason, after) := by
  simp only [terminal, observed]

/-- Observe the next ND node, retaining its action and failure-time state. -/
def node {α info err cs st : Type} (m : ndM α info err cs st) (s : st) :=
  match m with | ND run => run s

theorem lift_disabled {α : Type} [LemFuel]
    (m : ndM α String mem_error (mem_constraint CerbMem.IntegerValue) CerbMem.MemState)
    (s : driver_state) (h : s.sc_state0 = none) :
    node (driver_liftMem m) s = node (liftMem m) s := by
  cases hm : liftMem m with
  | ND run =>
    simp only [liftMem] at hm
    simp only [node, driver_liftMem, h, liftMem, hm]

theorem post_memory_disabled (s : driver_state) (h : s.sc_state0 = none) :
    sc_post_memory s = (none, s) := by simp only [sc_post_memory, h]

/-- Unsequenced siblings acquire no edge merely from scheduling the hole. -/
theorem context_unseq (preds : sc_predecessors) annotations left inner right :
    sc_add_before_context preds (Cunseq annotations left inner right) =
      let result := sc_add_before_context preds inner
      (result.1, Cunseq annotations left result.2 right) := by
  simp only [sc_add_before_context]

/-- Weak sequencing only carries positive effects into its continuation. -/
theorem context_weak (preds : sc_predecessors) annotations pattern second :
    sc_add_before_context preds (Cwseq annotations pattern CTX second) =
      (preds, Cwseq annotations pattern CTX
        (sc_add_before_expr (sc_positive preds) second)) := rfl

/-- A strong boundary completes negative effects, including for outer contexts. -/
theorem context_strong (preds : sc_predecessors) annotations pattern second :
    sc_add_before_context preds (Csseq annotations pattern CTX second) =
      (sc_promote preds, Csseq annotations pattern CTX
        (sc_add_before_expr (sc_promote preds) second)) := rfl

theorem caller_unseq (preds : sc_predecessors) annotations left inner right :
    sc_add_before_caller preds (Cunseq annotations left inner right) =
      Cunseq annotations (List.map (sc_add_before_expr (sc_promote preds)) left)
        (sc_add_before_caller (sc_promote preds) inner)
        (List.map (sc_add_before_expr (sc_promote preds)) right) := rfl

/-- Completion retains joined descendants even with no intervening own effect. -/
theorem completed_effects tid parent value (s : sc_state) :
    (sc_complete_child tid parent value s).sc_completed =
      {sc_child_id := tid, sc_child_parent := parent, sc_child_value := value,
       sc_child_effects := sc_thread_effects tid s} :: s.sc_completed := rfl

/-- Core component enumeration. The complete machine additionally selects saved
helper services and applies filesystem ownership; see its separate choice law. -/
theorem choices_iff [LemFuel] tags (sc : sc_state) (s : driver_state)
    (choice : Nat × core_step2) :
    choice ∈ sc_choices tags sc s ↔
      ∃ thInfo, (choice.1, thInfo) ∈ s.core_state0.thread_states ∧
        (match Lem_List.lookupBy (fun x y : Nat => x == y) choice.1 s.sc_pending with
        | some pending => choice.2 = pending
        | none => choice.2 ∈ step_ctx_with tags (some (sc_control choice.1 sc))
            s.layout_state s.core_file s.core_extern choice.1 thInfo ∧
            (match choice.2 with | Step_blocked2 => false | _ => true) = true) := by
  rcases choice with ⟨tid, step⟩
  simp only [sc_choices, sc_thread_choices]
  constructor
  · intro h
    rcases List.mem_flatten.mp h with ⟨xs, hxs, hx⟩
    rcases List.mem_map.mp hxs with ⟨⟨other, thInfo⟩, hthread, rfl⟩
    cases found : Lem_List.lookupBy (fun x y : Nat => x == y) other s.sc_pending with
    | some pending =>
      simp only [found, List.mem_singleton] at hx
      cases hx
      exact ⟨thInfo, hthread, by simp only [found]⟩
    | none =>
      simp only [found] at hx
      rcases List.mem_map.mp hx with ⟨offered, hoffered, heq⟩
      rcases List.mem_filter.mp hoffered with ⟨hstep, hrunnable⟩
      cases heq
      refine ⟨thInfo, hthread, ?_⟩
      simp only [found]
      refine ⟨hstep, ?_⟩
      cases step <;> exact hrunnable
  · rintro ⟨thInfo, hthread, hstep⟩
    apply List.mem_flatten.mpr
    refine ⟨_, List.mem_map.mpr ⟨(tid, thInfo), hthread, rfl⟩, ?_⟩
    cases found : Lem_List.lookupBy (fun x y : Nat => x == y) tid s.sc_pending with
    | some pending =>
      simp only [found] at hstep ⊢
      cases hstep
      exact List.mem_singleton_self _
    | none =>
      simp only [found] at hstep ⊢
      exact List.mem_map.mpr ⟨step, List.mem_filter.mpr hstep, rfl⟩


/-- Recording an effect preserves its owning request. -/
theorem ownership_retained aid observed (state after : sc_state)
    (h : sc_record_effect aid observed state = some after) :
    after.sc_current_request = state.sc_current_request := by
  cases owner : state.sc_current_request with
  | none => simp [sc_record_effect, owner] at h
  | some request =>
    simp only [sc_record_effect, owner, Option.some.injEq] at h
    cases h
    rfl

/-- Earlier occurrences survive exactly, including equal-valued effects. -/
theorem older_history_retained aid observed (state after : sc_state)
    (h : sc_record_effect aid observed state = some after) :
    after.sc_effects.tail = state.sc_effects := by
  cases owner : state.sc_current_request with
  | none => simp [sc_record_effect, owner] at h
  | some request =>
    simp only [sc_record_effect, owner, Option.some.injEq] at h
    cases h
    rfl

theorem one_more_occurrence aid observed (state after : sc_state)
    (h : sc_record_effect aid observed state = some after) :
    after.sc_effects.length = state.sc_effects.length + 1 := by
  cases owner : state.sc_current_request with
  | none => simp [sc_record_effect, owner] at h
  | some request =>
    simp only [sc_record_effect, owner, Option.some.injEq] at h
    cases h
    rfl

end CerbSCOperational
