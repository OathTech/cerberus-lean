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
/-- DOCUMENTED-DELIBERATE DIVERGENCE (upstream cerberus bug, recorded in
    lembugs/2026-08-19_upstream-float-mul.md): the OCaml target of lem's
    `Float.floatMul` is `Cerb_floating.mul`, which upstream defines as
    `(+.)` — literally addition (util/cerb_floating.ml:5; add/sub/div on
    the neighboring lines are correct, so this is a copy-paste slip).
    We implement real multiplication. Consequence: the FIRST differential
    test whose verdict flows through lem-level float multiplication
    (e.g. the generated Defacto_memory op_fval, or any future lem code
    using `*` on floats) will show the OCAML side wrong, not ours.
    The concrete model's own op_fval (impl_mem.ml:2529-2537, mirrored by
    CerbMem.opFval) uses `*.` directly and is NOT affected — which is
    why today's corpus doesn't surface it. -/
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

/-! ## Exact decimal formatting (arc-10 S3, pp-placeholder text class)

OCaml's float→text goes through C printf: `string_of_float f =
valid_float_lexem (format_float "%.12g" f)` (OCaml stdlib.ml) and
`Decode.format_string_of_float prec f = Printf.sprintf "%.<prec>f" f`
(ocaml_frontend/decode.ml:228-232). glibc prints the CORRECTLY-ROUNDED
decimal form of the exact binary value (ties: round-half-even). We
reproduce that exactly with integer arithmetic on the IEEE-754
decomposition: |f| = m·2^e with m,e integers, so any scaled value
m·2^e·10^p is a ratio of integers and can be rounded half-even exactly.
Verified against OCaml 5.4.0 (= glibc printf) reference outputs in
test/Unit/PPTest.lean. -/

/-- IEEE-754 double decomposition: (sign, m, e) with |f| = m·2^e (m = 0
    iff f = ±0). Finite inputs only (callers branch on nan/inf first). -/
private def decomposeFinite (f : Float) : Bool × Nat × Int :=
  let bits := f.toBits
  let sign := bits >>> 63 == 1
  let expField := ((bits >>> 52) &&& 0x7FF).toNat
  let mantissa := (bits &&& 0xFFFFFFFFFFFFF).toNat
  if expField == 0 then (sign, mantissa, -1074)          -- subnormal / zero
  else (sign, mantissa + (1 <<< 52), (expField : Int) - 1075)

/-- round-half-even of m·2^e·10^p (all exact) to a Nat. -/
private def scaledRound (m : Nat) (e : Int) (p : Int) : Nat :=
  let num := m * (if e ≥ 0 then 2 ^ e.toNat else 1)
               * (if p ≥ 0 then 10 ^ p.toNat else 1)
  let den := (if e < 0 then 2 ^ (-e).toNat else 1)
               * (if p < 0 then 10 ^ (-p).toNat else 1)
  let q := num / den
  let r := num % den
  if 2 * r > den then q + 1
  else if 2 * r < den then q
  else if q % 2 == 0 then q else q + 1

/-- C printf `%.<prec>f` of a double, exactly (glibc: correctly rounded,
    half-even on the exact binary value). Mirror target:
    Decode.format_string_of_float (ocaml_frontend/decode.ml:228-232).
    nan/inf: "nan"/"inf"/"-inf" like glibc %f, except that a negative
    NaN's "-nan" is not reproduced (DELIBERATE: Lean gives no portable
    NaN sign access; unobservable in the corpora). -/
def formatFixed (prec : Nat) (f : Float) : String :=
  if f.isNaN then "nan"
  else if f.isInf then (if f < 0 then "-inf" else "inf")
  else
    let (sign, m, e) := decomposeFinite f
    let scaled := scaledRound m e (prec : Int)
    let ip := scaled / 10 ^ prec
    let fp := scaled % 10 ^ prec
    let sgn := if sign then "-" else ""
    if prec == 0 then sgn ++ toString ip
    else
      let fpStr := toString fp
      let pad := String.ofList (List.replicate (prec - fpStr.length) '0')
      sgn ++ toString ip ++ "." ++ pad ++ fpStr

/-- Number of decimal digits of a Nat (1 for 0). -/
private def numDigits (n : Nat) : Nat := (toString n).length

/-- Corresponds to: string_of_float in OCaml — EXACT mirror of
    `valid_float_lexem (format_float "%.12g" f)` (OCaml stdlib.ml):
    C `%.12g` = round to 12 significant decimal digits (half-even on the
    exact value); use `%e` style iff the decimal exponent X < -4 or
    X ≥ 12; strip trailing fraction zeros; exponent `e±dd` (≥ 2 digits);
    then valid_float_lexem appends "." iff the result is a plain integer
    lexeme. NaN sign caveat as in formatFixed. -/
def string_of_float (f : Float) : String :=
  if f.isNaN then "nan"
  else if f.isInf then (if f < 0 then "-inf" else "inf")
  else
    let (sign, m, e) := decomposeFinite f
    let sgn := if sign then "-" else ""
    if m == 0 then sgn ++ "0."
    else
      -- decimal exponent X (10^X ≤ |f| < 10^(X+1)): probe at a fixed wide
      -- scale (10^400 puts even the smallest subnormal ≥ 10^76), then
      -- correct after the 12-digit rounding.
      let probe := scaledRound m e 400
      let X0 : Int := (numDigits probe : Int) - 1 - 400
      let n0 := scaledRound m e (11 - X0)
      let (n1, X) : Nat × Int :=
        if numDigits n0 > 12 then (n0 / 10, X0 + 1)      -- overflow: n0 = 10^12
        else if numDigits n0 < 12 then (scaledRound m e (11 - (X0 - 1)), X0 - 1)
        else (n0, X0)
      -- strip trailing zeros (%g without '#')
      let rec strip (n : Nat) (fuel : Nat) : Nat :=
        match fuel with
        | 0 => n
        | fuel + 1 => if n % 10 == 0 && n ≥ 10 then strip (n / 10) fuel else n
      let ds := toString (strip n1 12)
      if X < -4 || X ≥ 12 then
        -- %e style: d[.ddd]e±XX
        let mant :=
          if ds.length == 1 then ds
          else (ds.take 1).toString ++ "." ++ (ds.drop 1).toString
        let xa := (if X < 0 then -X else X).toNat
        let xs := toString xa
        let xs := if xs.length < 2 then "0" ++ xs else xs
        sgn ++ mant ++ "e" ++ (if X < 0 then "-" else "+") ++ xs
      else if X ≥ 0 then
        if (ds.length : Int) ≤ X then
          -- all digits before the point; valid_float_lexem appends "."
          sgn ++ ds ++ String.ofList (List.replicate (X + 1 - ds.length).toNat '0') ++ "."
        else if (ds.length : Int) == X + 1 then
          sgn ++ ds ++ "."
        else
          sgn ++ (ds.take (X + 1).toNat).toString ++ "." ++ (ds.drop (X + 1).toNat).toString
      else
        -- -4 ≤ X < 0: 0.00ddd
        sgn ++ "0." ++ String.ofList (List.replicate (-X - 1).toNat '0') ++ ds

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
