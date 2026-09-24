import CerbSCOperational

/-! An external consumer of the initialized whole-C operational API. The linked
Core file is the one produced by the C pipeline. There is no replacement
semantics, fixed fuel, application logic, or claim that unfinished paths are safe. -/
namespace SCConsumer

/-- This is the actual initialized program, including its outer continuation. -/
def start (fuel supply : Nat) (top : Int)
    (file : generic_file Unit core_run_annotation) (filesystem : CerbFS.FsState)
    (origins : Option sc_link_origins) (args : List String) : sc_program :=
  (CerbSCOperational.start fuel supply top file filesystem origins args).1

/-- The consumer's bounded executions are precisely the public driver started
with the same file, initial state and semantic fuel. Exploration depth is an
independent explicit parameter; this does not hide fuel existentially. -/
theorem initialized_execution (fuel supply budget : Nat) (top : Int)
    (file : generic_file Unit core_run_annotation) (filesystem : CerbFS.FsState)
    (origins : Option sc_link_origins) (args : List String) :
    CerbSCOperational.outcomes budget (start fuel supply top file filesystem origins args) =
      let state := (initial_driver_state supply top file filesystem).1
      CerbND.runNDFuel budget (@drive ⟨fuel⟩ file.tagDefs true file args)
        { state with sc_origins := origins } := rfl

/-- A client can report a real operational fault without losing an assertion
about its failure-time memory, effect journal, or retained race findings. -/
theorem fault_retains_assertion (program : sc_program) (after : driver_state)
    (reason : kill_reason driver_error) (P : driver_state → Prop)
    (observed : sc_program_node program = (NDkilled reason, after)) (holds : P after) :
    ∃ reported, CerbSCOperational.terminal program = some (Killed reported reason, reported) ∧
      P reported :=
  ⟨after, CerbSCOperational.terminal_failure program reason after observed, holds⟩

/-- Taking an offered continuation uses its captured work and the returned
post-state. Reconstructing a program from `driver_state` would not satisfy this
connection: the actual continuation may retain paused services and later phases. -/
theorem selected_continuation (budget : Nat) (state : driver_state)
    (continuation : ndM driver_result step_kind driver_error
      (mem_constraint CerbMem.IntegerValue) driver_state) :
    CerbSCOperational.outcomes budget (sc_program_resume state continuation) =
      CerbND.runNDFuel budget continuation state := rfl

/-- Exhausting the exploration budget remains an explicit fault with the current
state, even if a client has not inspected the next semantic node yet. -/
theorem exhausted_budget (program : sc_program) :
    CerbSCOperational.outcomes 0 program =
      [(Killed program.sc_program_state CerbND.fuelExhaustedKill, [], program.sc_program_state)] := rfl

end SCConsumer
