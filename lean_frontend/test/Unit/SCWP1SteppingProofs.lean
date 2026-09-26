import Driver
import Unit.SCWP1ContextProofs

/-! Kernel laws for the actual shared-Lem experiment. These establish
    operational budget/composition facts, not correspondence to SC axioms. -/
namespace SCWP1SteppingProofs

variable [LemFuel]
variable (ed : Fmap sym integerType)
variable (td : Fmap sym (CerbLocation.Loc × tag_definition))

theorem run_terminal (xs : List Nat) (c : experiment_config)
    (h : experiment_terminal c = true) :
    experiment_run ed td xs c = (c, xs) := by
  cases xs <;> simp [experiment_run, h]

theorem step_count (i : Nat) (c : experiment_config)
    (h : experiment_terminal c = false) :
    (experiment_step ed td i c).experiment_steps = c.experiment_steps + 1 := by
  simp only [experiment_step, h, Bool.false_eq_true, ↓reduceIte]

/-- The *entire* configuration is equal: continuations, memory, receipt buffer,
    run-state supplies, I/O and step count, together with unconsumed schedule.
    This is stronger than comparing a runtime state digest. -/
theorem run_append (xs ys : List Nat) (c : experiment_config) :
    experiment_run ed td (xs ++ ys) c =
      let (c', unused) := experiment_run ed td xs c
      if experiment_terminal c' then (c', unused ++ ys)
      else experiment_run ed td ys c' := by
  induction xs generalizing c with
  | nil =>
      simp only [List.nil_append, experiment_run]
      split
      · exact run_terminal ed td ys c (by assumption)
      · rfl
  | cons i xs ih =>
      cases h : experiment_terminal c with
      | true => simp [run_terminal ed td _ c h, h]
      | false => simpa only [List.cons_append, experiment_run, h,
          Bool.false_eq_true, ↓reduceIte] using ih (experiment_step ed td i c)

/-- Every consumed entry pays for exactly one step; early stopping returns
    the remainder. No generated-call fuel occurs in this accounting. -/
theorem run_budget (xs : List Nat) (c : experiment_config) :
    (experiment_run ed td xs c).1.experiment_steps +
      (experiment_run ed td xs c).2.length = c.experiment_steps + xs.length := by
  induction xs generalizing c with
  | nil => simp [experiment_run]
  | cons i xs ih =>
      cases h : experiment_terminal c with
      | true => simp [run_terminal ed td _ c h]
      | false =>
          simp only [experiment_run, h, Bool.false_eq_true, ↓reduceIte]
          rw [ih, step_count ed td i c h]
          simp [Nat.add_assoc, Nat.add_comm, Nat.add_left_comm]

/-- Choice discovery cannot depend on memory, run-state supplies, filesystem,
    observations, or the saved lifecycle program. Only thread Core states are
    inspected. This covers arbitrary values of all the excluded fields. -/
theorem core_discovery (a b : driver_state) (ka kb : driverM driver_result)
    (na nb : Nat) (h : a.core_state0.thread_states = b.core_state0.thread_states) :
    experiment_choice_count ⟨Exp_core ka, a, na⟩ =
      experiment_choice_count ⟨Exp_core kb, b, nb⟩ := by
  simp only [experiment_choice_count, experiment_runnable, experiment_contexts, h]

end SCWP1SteppingProofs
