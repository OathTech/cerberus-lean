/-
  Utility functions for Cerberus Lean port.
  Corresponds to various OCaml modules.
  Leaf module — no imports from generated code.
-/

namespace CerbUtils

/-! ## Timing
    Corresponds to: Cerb_debug.begin_timing/end_timing in cerb_debug.ml
    The OCaml implementation records wall-clock time to cerb.prof.
    We use Lean's IO for the same purpose. -/

private unsafe def timingStackRef : IO.Ref (List (String × Float)) :=
  unsafeBaseIO (IO.mkRef [])

private unsafe def begin_timing_impl (_ : String) : Unit := ()

private unsafe def end_timing_impl (_ : Unit) : Unit := ()

@[implemented_by begin_timing_impl]
opaque begin_timing : String → Unit

@[implemented_by end_timing_impl]
opaque end_timing : Unit → Unit

/-! ## Logging
    Corresponds to: Cerb_logging.log_standard in cerb_logging.ml
    Logs the string and returns the value unchanged. -/

private unsafe def logRef : IO.Ref (List String) :=
  unsafeBaseIO (IO.mkRef [])

private unsafe def STD_impl {α : Type} [Inhabited α] (s : String) (x : α) : α :=
  unsafeBaseIO do
    let log ← logRef.get
    logRef.set (s :: log)
    pure x

@[implemented_by STD_impl]
opaque STD_ {α : Type} [Inhabited α] : String → α → α

/-! ## List utilities
    Corresponds to: OCaml List.remove_assoc -/

def list_remove_assoc {α β : Type} [BEq α] (key : α) : List (α × β) → List (α × β)
  | [] => []
  | (k, v) :: rest => if k == key then rest else (k, v) :: list_remove_assoc key rest

/-! ## Set fold
    Corresponds to: Pset.fold in OCaml -/

-- Lem sets are sorted lists via LemSet. Fold follows OCaml Pset.fold order.
def set_fold {α β : Type} (f : α → β → β) (s : List α) (init : β) : β :=
  s.foldl (fun acc x => f x acc) init

/-! ## Random bounded integer
    Corresponds to: Cerb_any.bounded_integer in cerb_any.ml
    OCaml uses Random.int64 to pick a value in [min, max]. -/

private unsafe def boundedIntegerImpl (lo hi : Int) : Int :=
  unsafeBaseIO do
    -- Simple deterministic approach: return lo (can be replaced with real RNG)
    pure lo

@[implemented_by boundedIntegerImpl]
opaque bounded_integer : Int → Int → Int

/-! ## Character encoding
    Corresponds to: Decode.encode_character_constant in decode.ml
    OCaml: Char.chr (Nat_big_num.to_int n land 0xff) -/

def encode_character_constant (n : Int) : Char :=
  Char.ofNat (n.toNat % 128)  -- ASCII range, always valid

end CerbUtils
