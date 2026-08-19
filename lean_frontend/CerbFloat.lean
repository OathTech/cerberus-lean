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

/-! ## String → Float parsing

    Corresponds to: Cerb_floating.of_string (util/cerb_floating.ml:8-16),
    which strips one trailing 'f' and delegates to OCaml's
    `float_of_string` (strtod). The strings reaching this function are
    C floating literals, fed from exactly two places:

    * translation.lem:207-209 (`A.ConstantFloating (str, _)` →
      `Mem.str_fval str`): the raw C literal text from the C lexer —
      decimal forms `D+ [. D*] [(e|E) [+|-] D+]`, `. D+ ...`, and
      (legal C, unused by the current corpus) hex forms `0x H* [. H*]
      (p|P) [+|-] D+`, with an optional f/F/l/L suffix;
    * CoreParser.lean (lexNumLit): a normalized decimal
      `D+ . D+ [e[+|-]D+]` string, optionally negated.

    Lean core has no String.toFloat, so we parse by hand:
    decimal literals accumulate an exact integer mantissa and a base-10
    exponent and finish with `Float.ofScientific` (binary64); hex
    literals accumulate an exact hex mantissa and finish with
    `Float.scaleB`. Precision notes (deliberate, documented divergence
    from OCaml's strtod):
    * decimal: `Float.ofScientific` is Lean's standard decimal→binary64
      conversion; literals with ≤ 17 significant digits (all this
      pipeline produces) convert to the same double as strtod; extreme
      many-digit literals could differ in the last ulp;
    * hex: exact when the mantissa fits 53 bits (scaleB is exact);
      longer hex mantissas round differently from strtod's
      correct rounding.
    OCaml's float_of_string also accepts "inf"/"nan" — C has no such
    literals and neither feeding site can produce them, so (like any
    other malformed input) they take the parse-failure path: OCaml
    raises `Failure`, we mirror with `panic!` (same observable class:
    abort with a message; OCaml's exception also escapes — nothing
    catches it on this path). -/

/-- Decimal-digit run → (value, digit count). -/
private def digitsToNat (s : List Char) : Nat × Nat :=
  s.foldl (fun (acc, k) c => (acc * 10 + (c.toNat - '0'.toNat), k + 1)) (0, 0)

private def isHexDigit (c : Char) : Bool :=
  c.isDigit || ('a' ≤ c && c ≤ 'f') || ('A' ≤ c && c ≤ 'F')

private def hexVal (c : Char) : Nat :=
  if c.isDigit then c.toNat - '0'.toNat
  else if 'a' ≤ c && c ≤ 'f' then c.toNat - 'a'.toNat + 10
  else c.toNat - 'A'.toNat + 10

/-- Parse a decimal C floating literal (sign already stripped).
    Returns none on malformed input. -/
private def parseDecimal (cs : List Char) : Option Float := do
  let intPart := cs.takeWhile Char.isDigit
  let cs := cs.drop intPart.length
  let (fracPart, cs) :=
    match cs with
    | '.' :: rest => (rest.takeWhile Char.isDigit, rest.drop (rest.takeWhile Char.isDigit).length)
    | _ => ([], cs)
  if intPart.isEmpty && fracPart.isEmpty then failure
  let (expNeg, expDigits, cs) :=
    match cs with
    | 'e' :: rest | 'E' :: rest =>
      let (neg, rest) := match rest with
        | '+' :: r => (false, r)
        | '-' :: r => (true, r)
        | r => (false, r)
      (neg, rest.takeWhile Char.isDigit, rest.drop (rest.takeWhile Char.isDigit).length)
    | _ => (false, [], cs)
  -- exponent marker present but no digits → malformed
  if !cs.isEmpty then failure
  let (intVal, _) := digitsToNat intPart
  let (fracVal, fracLen) := digitsToNat fracPart
  let mantissa := intVal * 10 ^ fracLen + fracVal
  let exp10 : Int := (if expNeg then -(expDigits.foldl (fun a c => a * 10 + (c.toNat - '0'.toNat)) 0 : Int)
                      else (expDigits.foldl (fun a c => a * 10 + (c.toNat - '0'.toNat)) 0 : Int)) - fracLen
  -- Float.ofScientific m eNeg e = m * 10^(±e)
  if exp10 < 0 then
    return Float.ofScientific mantissa true exp10.natAbs
  else
    return Float.ofScientific mantissa false exp10.toNat

/-- Parse a hex C floating literal after the "0x" (sign already stripped):
    `H* [. H*] (p|P) [+|-] D+` — value = mantissa · 2^(p − 4·fracDigits). -/
private def parseHex (cs : List Char) : Option Float := do
  let intPart := cs.takeWhile isHexDigit
  let cs := cs.drop intPart.length
  let (fracPart, cs) :=
    match cs with
    | '.' :: rest => (rest.takeWhile isHexDigit, rest.drop (rest.takeWhile isHexDigit).length)
    | _ => ([], cs)
  if intPart.isEmpty && fracPart.isEmpty then failure
  let (expNeg, expDigits, cs) :=
    match cs with
    | 'p' :: rest | 'P' :: rest =>
      let (neg, rest) := match rest with
        | '+' :: r => (false, r)
        | '-' :: r => (true, r)
        | r => (false, r)
      (neg, rest.takeWhile Char.isDigit, rest.drop (rest.takeWhile Char.isDigit).length)
    | _ => (false, [], cs)  -- binary exponent is mandatory in C; tolerate absence as p0
  if !cs.isEmpty then failure
  let mantissa := (intPart ++ fracPart).foldl (fun a c => a * 16 + hexVal c) 0
  let p : Int := expDigits.foldl (fun a c => a * 10 + (c.toNat - '0'.toNat)) (0 : Int)
  let p := if expNeg then -p else p
  return Float.scaleB (Float.ofNat mantissa) (p - 4 * fracPart.length)

/-- Corresponds to: Cerb_floating.of_string (util/cerb_floating.ml:8-16):
    strips ONE trailing 'f' (OCaml checks only lowercase 'f'; we also
    accept F/l/L — the C-suffix forms float_of_string itself would
    otherwise reject; OCaml raises Failure on those, an upstream
    fragility, not behavior worth mirroring), then parses per
    float_of_string. Malformed input: OCaml raises Failure — mirrored
    with panic! (see module comment). -/
def of_string (s : String) : Float :=
  let s' := if s.endsWith "f" || s.endsWith "F" || s.endsWith "l" || s.endsWith "L"
    then s.dropRight 1
    else s
  let cs := s'.toList
  let (neg, cs) := match cs with
    | '-' :: rest => (true, rest)
    | '+' :: rest => (false, rest)
    | _ => (false, cs)
  let parsed := match cs with
    | '0' :: 'x' :: rest | '0' :: 'X' :: rest => parseHex rest
    | _ => parseDecimal cs
  match parsed with
  | some f => if neg then -f else f
  | none => panic! s!"CerbFloat.of_string: {s} (OCaml Cerb_floating.of_string raises Failure)"

/-- Corresponds to: string_of_float in OCaml -/
def string_of_float (f : Float) : String := toString f

/-- Truncate a Float toward zero to an integer — corresponds to zarith's
    `Z.of_float` (used by ivfromfloat, impl_mem.ml:2553-2554): truncation
    toward zero, keeping the sign; raises Z.Overflow on nan/inf (mirrored
    with panic! — nothing catches Z.Overflow on the OCaml path either).
    Implemented bit-exactly from the IEEE 754 representation (NOT via
    Float.toUInt64, which clamps negatives to 0). -/
def truncToInt (f : Float) : Int :=
  let bits := f.toBits
  let expBits := ((bits >>> 52) &&& 0x7FF).toNat
  let mantBits := (bits &&& 0xFFFFFFFFFFFFF).toNat
  if expBits == 0x7FF then
    panic! "CerbFloat.truncToInt: nan/inf (OCaml Z.of_float raises Z.Overflow)"
  else
    let mant := if expBits == 0 then mantBits else mantBits + (1 <<< 52)
    -- unbiased exponent minus mantissa width: value = mant · 2^(expBits−1075)
    let mag : Nat :=
      if expBits ≥ 1075 then mant <<< (expBits - 1075)
      else mant >>> (1075 - expBits)   -- floor of |f| = trunc toward 0 of f
    if bits >>> 63 == 1 then -(mag : Int) else (mag : Int)

/-- Corresponds to: int_of_float in OCaml (truncation toward zero). -/
def to_int (f : Float) : Int := truncToInt f

end CerbFloat
