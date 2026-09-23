import Sc_atomic_sources

set_option autoImplicit true
namespace CerbSCAtomicSources

/-- Diagnostics cannot replace or erase the original completed read. -/
theorem read_retained aliases observed older :
    (sc_atomic_source_for aliases observed older).sc_atomic_read = observed := rfl

/-- Every captured byte retains its actual source query result, even on failure. -/
theorem byte_sources_retained aliases (observed : sc_effect) older loc ty pointer storage base size bytes value
    (shape : observed.sc_effect_observation = Observe_access loc LoadAccess ty pointer storage base size bytes value) :
    (sc_atomic_source_for aliases observed older).sc_atomic_read_bytes =
      sc_byte_sources storage base bytes older := by
  simp only [sc_atomic_source_for, shape]

theorem ordinary_head_omitted aliases observed older
    (ordinary : sc_is_atomic_read observed = false) :
    sc_atomic_source_history aliases (observed :: older) = sc_atomic_source_history aliases older := by
  simp only [sc_atomic_source_history, ordinary, Bool.false_eq_true, ↓reduceIte]

theorem atomic_head_uses_older_suffix aliases observed older
    (atomic : sc_is_atomic_read observed = true) :
    sc_atomic_source_history aliases (observed :: older) =
      sc_atomic_source_for aliases observed older :: sc_atomic_source_history aliases older := by
  simp only [sc_atomic_source_history, atomic, ↓reduceIte]

theorem history_reads_retained aliases history :
    (sc_atomic_source_history aliases history).map sc_atomic_source_receipt.sc_atomic_read =
      history.filter sc_is_atomic_read := by
  induction history with
  | nil => rfl
  | cons observed older ih =>
    cases h : sc_is_atomic_read observed <;>
      simp only [sc_atomic_source_history, h, Bool.false_eq_true, ↓reduceIte,
        List.filter_cons, List.map_cons, read_retained, ih]

end CerbSCAtomicSources
