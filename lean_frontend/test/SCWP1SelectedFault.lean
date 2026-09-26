import Unit.SCWP1Stepping

/-! Negative control: the unchosen fault from the main probe really faults
    when selected. Run in a separate process with LEAN_ABORT_ON_PANIC=1. -/
open SCWP1Stepping
def selectedFault (fuel : Nat) : Nat :=
  letI := LemFuel.mk fuel
  let st := initial (fileFor done)
  let st := { st with core_state0 := { st.core_state0 with thread_states :=
    [(0, (none, th (Expr [] (Erun empty_annotation loopSym []))))] } }
  (step 0 (coreConfig st)).experiment_steps
#eval selectedFault 64
