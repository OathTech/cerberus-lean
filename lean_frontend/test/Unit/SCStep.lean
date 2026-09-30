import Unit.SCStepProofs

/-! # sc-step-test — the SC S1a kernel laws, compiled on every test_unit.sh run

`Unit.SCStepProofs` states L1–L6 over the generated SC step API (charter §3.9); this
executable exists so that every `test_unit.sh` run compiles those theorems (the WP0
`memory-access-test`/`MemoryAccessProofs` pattern: no new seam, no manifest change). It
prints the names of the compiled laws and exits 0; a proof that no longer compiles fails
the build, never this exit. -/

def main : IO Unit := do
  IO.println "sc-step-test: kernel laws compiled — L1 sc_run_zero/sc_run_exhausted_transitions/sc_run_reductions_le_transitions(+_from_start); L2 sc_run_succ/sc_step_transitions; L3 sc_step_final/sc_run_stable; L4 sc_step_bad_choice_*/sc_step_choice_required_*/sc_step_no_alternatives_*/sc_step_chosen_*; L5 sc_perform_advance/sc_perform_pick; L6 TraceGrows/sc_events_append/sc_step_state_from_action/HMono toolbox"
