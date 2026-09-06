import Unit.FuelExemplar
import LemLibPmapLaws

/- Provider-owned consumer of the actual shipped drive/runND entry.
   The fixture and its compositional lemmas are exported by CerberusLeanTest.
   Preconditions are deliberately concrete: the fixture's closed Core file,
   empty tag map, initial filesystem, argv ["cmdname"], and ambient fuel ≥ 2.
   This does not establish a theorem for arbitrary C, parsing, or libc. -/
namespace ProviderSmoke
open FuelExemplar FuelExemplar.Round

/-- An actual completed result exists, and is the only exploration result.
    This cannot be satisfied by a runner that always exhausts or fails. -/
theorem completed (k : Nat) :
    ∃ r st, run (Nat.succ (Nat.succ k)) = [(Active r, [], st)] ∧
      r.dres_core_value = fortyTwo := by
  obtain ⟨thF, hdrv2⟩ := round_done k
  have hrun := drive_after_setup k _ hdrv2
  refine ⟨_, _, runND_active hrun, ?_⟩
  exact finalize_done fmapEmpty _ _ _ fortyTwo rfl rfl

/-- A delivered map law instantiated with semantic results, under the
    library's actual strict-weak-order and tree well-formedness conditions. -/
theorem remember_result (key : Nat) (r : driver_result) (m : Pmap Nat driver_result)
    (hw : Pmap.WF defaultCompare m) :
    Pmap.find? defaultCompare key (Pmap.add defaultCompare key r m) = some r :=
  Pmap.find?_add_same Pmap.cmpLaws_of_transOrd key r m hw

#print axioms completed
#print axioms remember_result
end ProviderSmoke
