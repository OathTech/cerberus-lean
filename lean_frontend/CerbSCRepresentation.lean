import Sc_representation

open Lem_List

theorem sc_specified_bytes_cons {α : Type} (byte : Option α) (bytes : List (Option α)) :
    sc_specified_bytes (byte :: bytes) =
      (match byte, sc_specified_bytes bytes with
        | some value, some values => some (value :: values)
        | _, _ => none) := by
  simp [sc_specified_bytes, lemListFoldr]
  rfl

theorem sc_specified_bytes_map_some {α : Type} (bytes : List α) :
    sc_specified_bytes (bytes.map some) = some bytes := by
  induction bytes with
  | nil => rfl
  | cons byte bytes ih =>
    rw [List.map_cons, sc_specified_bytes_cons, ih]

theorem sc_specified_bytes_none_of_mem {α : Type} (bytes : List (Option α))
    (h : none ∈ bytes) : sc_specified_bytes bytes = none := by
  induction bytes with
  | nil => simp at h
  | cons byte bytes ih =>
    cases byte with
    | none => rw [sc_specified_bytes_cons]
    | some value =>
      have tail : none ∈ bytes := by simpa using h
      rw [sc_specified_bytes_cons, ih tail]

theorem sc_compare_representation_unspecified_left (left right : List (Option Int))
    (size : left.length = right.length) (unknown : none ∈ left) :
    sc_compare_representation left right = .SC_unspecified_representation := by
  simp [sc_compare_representation, size, sc_specified_bytes_none_of_mem left unknown]
  simp [BEq.beq, Lem_Basic_classes.isEqual, Lem_Basic_classes.setElemCompare, defaultCompare]

theorem sc_compare_representation_unspecified_right (left right : List (Option Int))
    (size : left.length = right.length) (unknown : none ∈ right) :
    sc_compare_representation left right = .SC_unspecified_representation := by
  simp [sc_compare_representation, size, sc_specified_bytes_none_of_mem right unknown]
  simp [BEq.beq, Lem_Basic_classes.isEqual, Lem_Basic_classes.setElemCompare, defaultCompare]

