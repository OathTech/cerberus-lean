import CerbSCOperational
import CerbSCByteSources
import CerbSCServices
import CerbSCFaults

/-! An external consumer of the actual operational definitions. No application
logic, replacement transition system, fixed fuel or provider axiom is used. -/
namespace SCConsumer

/-- A client's invariant about earlier observations survives a new occurrence. -/
theorem history_invariant (event : Nat) (observed : CerbMem.MemoryObservation)
    (before after : sc_state) (P : sc_effect → Prop)
    (recorded : sc_record_effect event observed before = some after)
    (prior : ∀ e ∈ before.sc_effects, P e) :
    ∀ e ∈ after.sc_effects.tail, P e := by
  rw [CerbSCOperational.older_history_retained event observed before after recorded]
  exact prior

/-- A claimed engine choice must belong to a currently installed thread. -/
theorem offered_thread_exists [LemFuel]
    (tags : Fmap sym (CerbLocation.Loc × tag_definition))
    (sc : sc_state) (state : driver_state) (choice : Nat × core_step2)
    (offered : choice ∈ sc_choices tags sc state) :
    ∃ info, (choice.1, info) ∈ state.core_state0.thread_states := by
  obtain ⟨info, present, _⟩ := (CerbSCOperational.choices_iff tags sc state choice).mp offered
  exact ⟨info, present⟩

/-- Clients can account for the exact captured representation length. This is
physical accounting and makes no C location or reads-from consistency claim. -/
theorem sources_cover_captured_bytes (owner : Option Int) (address : Int)
    (bytes : List CerbMem.AbsByte) (older : List sc_effect) :
    (sc_byte_sources owner address bytes older).length = bytes.length :=
  CerbSCByteSources.sources_length owner address bytes older

/-- Disabled SC observation reuses the original memory lifting operation. -/
theorem ordinary_memory_node [LemFuel]
    (operation : ndM Unit String mem_error (mem_constraint CerbMem.IntegerValue) CerbMem.MemState)
    (state : driver_state) (disabled : state.sc_state0 = none) :
    CerbSCOperational.node (driver_liftMem operation) state =
      CerbSCOperational.node (liftMem operation) state :=
  CerbSCOperational.lift_disabled operation state disabled

/-- Restoring ownership metadata preserves a client's memory assertion. The
following resumed primitive can change memory; this is the restoration step. -/
theorem restored_memory_assertion (saved : sc_saved_service)
    (before after : driver_state) (failure : Option driver_error)
    (restored : sc_restore_service saved before = (failure, after))
    (P : CerbMem.MemState → Prop) (prior : P before.layout_state) :
    P after.layout_state := by
  cases owner : before.sc_state0 with
  | none =>
    simp only [sc_restore_service, owner, Prod.mk.injEq] at restored
    rw [← restored.2]
    exact prior
  | some current =>
    simp only [sc_restore_service, owner, Prod.mk.injEq] at restored
    rw [← restored.2]
    exact prior

/-- A customer can distinguish a model fault from ISO UB structurally. -/
theorem model_fault_is_not_ub (fault : sc_fault) (where_ : CerbLocation.Loc)
    (causes : List undefined_behaviour) :
    (Other (DErr_concurrency fault) : kill_reason driver_error) ≠ Undef0 where_ causes :=
  CerbSCFaults.not_undefined fault where_ causes

end SCConsumer
