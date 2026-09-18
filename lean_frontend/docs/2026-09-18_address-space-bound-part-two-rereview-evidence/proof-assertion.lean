-- Independent review assertion against the production runner/driver/cold state.
-- The entire source above is copied unmodified, so this file re-elaborates the fixes.
theorem review_quantified_production_run (fuel : Nat) (top : Int) (h : 8 ≤ top) :
    ∀ o ∈ @CerbND.runND _ _ _ _ _ ⟨fuel⟩
      (@drive ⟨fuel⟩ fmapEmpty false FuelExemplar.exemplarFile ["cmdname"])
      ((initial_driver_state 0 top FuelExemplar.exemplarFile CerbFS.fs_initial_state).1),
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨
      (∃ r, o.1 = Active r ∧ r.dres_core_value = FuelExemplar.fortyTwo) := by
  simpa only [FuelExemplar.run, FuelExemplar.dst₀, FuelExemplar.post] using
    FuelExemplar.exemplar_certified_shipped_forall fuel top h

#print axioms review_quantified_production_run
#print axioms FuelExemplar.exemplar_certified_shipped_forall
#print axioms FuelExemplar.errnoAction_active
#print axioms FuelExemplar.drive_after_setup
#print axioms FuelExemplar.round_done
#print FuelExemplar.run
#check review_quantified_production_run
