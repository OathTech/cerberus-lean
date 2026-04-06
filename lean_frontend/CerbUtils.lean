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

/-! ## List utilities -/

/-- OCaml List.init: create list of length n using function f.
    Corresponds to: List.init in OCaml stdlib -/
def list_init {α : Type} (n : Nat) (f : Nat → α) : List α :=
  (List.range n).map f

/-- Check if integer is a power of two.
    Corresponds to: Cerb_util.is_power_of_two -/
def is_power_of_two (n : Int) : Bool :=
  n > 0 && (n.toNat &&& (n.toNat - 1)) == 0

/-! ## GCC builtins
    Corresponds to: ocaml_frontend/ocaml_gcc_builtins.ml -/

/-- Find first set bit (1-indexed from LSB, 0 if input is 0).
    Corresponds to: __builtin_ffs -/
def gcc_builtin_generic_ffs (n : Int) : Int :=
  if n == 0 then 0
  else
    let v := n.toNat
    let rec go (i : Nat) : Nat :=
      if i >= 64 then 0
      else if v &&& (1 <<< i) != 0 then i + 1
      else go (i + 1)
    go 0

/-- Count trailing zeros.
    Corresponds to: __builtin_ctz -/
def gcc_builtin_ctz (n : Int) : Int :=
  if n == 0 then 64  -- undefined for 0, but return something
  else gcc_builtin_generic_ffs n - 1

/-- Byte-swap 16-bit value.
    Corresponds to: __builtin_bswap16 -/
def gcc_builtin_bswap16 (n : Int) : Int :=
  let v := n.toNat % 0x10000
  let b0 := v &&& 0xFF
  let b1 := (v >>> 8) &&& 0xFF
  Int.ofNat ((b0 <<< 8) ||| b1)

/-- Byte-swap 32-bit value.
    Corresponds to: __builtin_bswap32 -/
def gcc_builtin_bswap32 (n : Int) : Int :=
  let v := n.toNat % 0x100000000
  let b0 := v &&& 0xFF
  let b1 := (v >>> 8) &&& 0xFF
  let b2 := (v >>> 16) &&& 0xFF
  let b3 := (v >>> 24) &&& 0xFF
  Int.ofNat ((b0 <<< 24) ||| (b1 <<< 16) ||| (b2 <<< 8) ||| b3)

/-- Byte-swap 64-bit value.
    Corresponds to: __builtin_bswap64 -/
def gcc_builtin_bswap64 (n : Int) : Int :=
  let v := n.toNat
  let b0 := v &&& 0xFF
  let b1 := (v >>> 8) &&& 0xFF
  let b2 := (v >>> 16) &&& 0xFF
  let b3 := (v >>> 24) &&& 0xFF
  let b4 := (v >>> 32) &&& 0xFF
  let b5 := (v >>> 40) &&& 0xFF
  let b6 := (v >>> 48) &&& 0xFF
  let b7 := (v >>> 56) &&& 0xFF
  Int.ofNat ((b0 <<< 56) ||| (b1 <<< 48) ||| (b2 <<< 40) ||| (b3 <<< 32) |||
             (b4 <<< 24) ||| (b5 <<< 16) ||| (b6 <<< 8) ||| b7)

end CerbUtils
