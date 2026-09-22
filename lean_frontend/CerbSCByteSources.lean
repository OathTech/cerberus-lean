import Sc_byte_sources

set_option autoImplicit true

/-! Physical source-accounting laws for the actual generated operations.
These do not identify C memory locations or establish Cmm consistency. -/
namespace CerbSCByteSources

theorem no_history (storage address : Int) :
    sc_byte_source_at storage address [] = SC_byte_no_observed_source := rfl

/-- A later read does not replace any byte's writer. -/
theorem ignore_read (storage address : Int) (effect : sc_effect) older
    loc ty ptr owner base size bytes value :
    sc_byte_source_at storage address
      ({ effect with sc_effect_observation :=
          Observe_access loc LoadAccess ty ptr owner base size bytes value } :: older) =
    sc_byte_source_at storage address older := rfl

/-- The newest covering store wins independently of its stored value. -/
theorem newest_store (storage address base size : Int) (effect : sc_effect) older
    loc ty ptr bytes value (covers : sc_contains_address base size address = true) :
    sc_byte_source_at storage address
      ({ effect with sc_effect_observation :=
          Observe_access loc StoreAccess ty ptr (some storage) base size bytes value } :: older) =
    SC_byte_store effect.sc_effect_id (address - base) := by
  simp [sc_byte_source_at, covers, BEq.beq, Lem_Basic_classes.isEqual,
    Lem_Basic_classes.setElemCompare, defaultCompare]

/-- Destruction ends that storage instance's physical source history. -/
theorem after_deallocation (storage address : Int) (effect : sc_effect) older loc dyn ptr range :
    sc_byte_source_at storage address
      ({ effect with sc_effect_observation :=
          Observe_deallocation loc dyn ptr storage range } :: older) =
    SC_byte_after_deallocation effect.sc_effect_id := by
  simp [sc_byte_source_at, BEq.beq, Lem_Basic_classes.isEqual,
    Lem_Basic_classes.setElemCompare, defaultCompare]

private theorem fold_length {α : Type} (f : Int → sc_byte_source) (bytes : List α)
    (address : Int) (sources : List sc_byte_source) :
    (List.foldl (fun (p : Int × List sc_byte_source) (x : α) =>
      match p, x with
      | (address, sources), _ => (address - 1, f address :: sources))
      (address, sources) bytes).2.length =
    bytes.length + sources.length := by
  induction bytes generalizing address sources with
  | nil => simp only [List.foldl_nil, List.length_nil, Nat.zero_add]
  | cons byte bytes ih =>
      simp only [List.foldl_cons, ih, List.length_cons]
      omega

/-- One result for every captured byte; reported size is not substituted. -/
theorem sources_length {α : Type} storage base (bytes : List α) older :
    (sc_byte_sources storage base bytes older).length = bytes.length := by
  cases storage with
  | none =>
      simpa only [sc_byte_sources, List.length_reverse, List.length_nil, Nat.add_zero] using
        fold_length (fun _ => SC_byte_storage_unresolved)
          bytes.reverse (base + Int.ofNat bytes.length - 1) []
  | some owner =>
      simpa only [sc_byte_sources, List.length_reverse, List.length_nil, Nat.add_zero] using
        fold_length (fun address => sc_byte_source_at owner address older)
          bytes.reverse (base + Int.ofNat bytes.length - 1) []

end CerbSCByteSources
