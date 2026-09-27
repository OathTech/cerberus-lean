import Unit.SCWP1Decision

namespace SCWP1DecisionProofs
open SCWP1Decision
variable [LemFuel]

theorem run_terminal (xs : List Nat) (c : Config) (h : experiment_terminal c.base = true) :
    run xs c = c := by
  cases xs <;> simp [run, h]

theorem step_count (i : Nat) (c : Config) (h : experiment_terminal c.base = false) :
    (step i c).base.experiment_steps = c.base.experiment_steps + 1 := by
  simp only [SCWP1Decision.step, h, Bool.false_eq_true, ↓reduceIte]

/-- Entire configuration, including pending callbacks/operands, shared memory,
    failure state, receipts, program continuation and resource counters. -/
theorem run_append (xs ys : List Nat) (c : Config) :
    run (xs ++ ys) c = run ys (run xs c) := by
  induction xs generalizing c with
  | nil => rfl
  | cons i xs ih =>
    cases h : experiment_terminal c.base with
    | true => simp [run, h, run_terminal ys c h]
    | false => simpa only [List.cons_append, run, h, Bool.false_eq_true, ↓reduceIte] using ih (step i c)

omit [LemFuel] in
/-- The chosen strategy's discovery stays structural with pending operations.
    It cannot depend on the shared memory, receipts, filesystem or supplies. -/
theorem choices_core_discovery (a b : driver_state) (ps : List Pending)
    (ka kb : driverM driver_result) (na nb : Nat)
    (h : a.core_state0.thread_states = b.core_state0.thread_states) :
    choices ⟨⟨Exp_core ka,a,na⟩,ps⟩ = choices ⟨⟨Exp_core kb,b,nb⟩,ps⟩ := by
  simp only [choices, experiment_runnable, experiment_contexts, h]

#print axioms run_append
#print axioms choices_core_discovery
end SCWP1DecisionProofs
