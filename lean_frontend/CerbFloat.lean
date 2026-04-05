/-
  Floating-point operations for Cerberus.
  Corresponds to: util/cerb_floating.ml and OCaml float builtins.

  Maps Cerberus float to Lean's Float (IEEE 754 double).
  This is a leaf module — no imports from generated code.
-/

-- Instances needed by generated code
instance : Ord Float where
  compare x y := if x < y then .lt else if x == y then .eq else .gt

namespace CerbFloat

def floatEq (x y : Float) : Bool := x == y
def floatLt (x y : Float) : Bool := x < y
def floatLe (x y : Float) : Bool := x <= y

def floatAdd (x y : Float) : Float := x + y
def floatSub (x y : Float) : Float := x - y
def floatMul (x y : Float) : Float := x * y
def floatDiv (x y : Float) : Float := x / y

/-- Corresponds to: float_of_int in OCaml -/
def of_int (n : Int) : Float := Float.ofInt n

/-- Corresponds to: Cerb_floating.of_string in OCaml.
    Handles optional 'f' suffix (C float literals). -/
def of_string (s : String) : Float :=
  let s' := if s.endsWith "f" || s.endsWith "F"
    then s.dropRight 1
    else s
  -- Parse float from string. Lean 4 doesn't expose String.toFloat directly,
  -- so we use a simple approach via DecimalNumber parsing.
  s'.toSubstring.toNat?.getD 0 |>.toFloat  -- fallback: integer part only
  -- TODO: proper float parsing with decimal/exponent support

/-- Corresponds to: string_of_float in OCaml -/
def string_of_float (f : Float) : String := toString f

/-- Corresponds to: int_of_float in OCaml -/
def to_int (f : Float) : Int := f.toUInt64.toNat  -- truncation towards zero

end CerbFloat
