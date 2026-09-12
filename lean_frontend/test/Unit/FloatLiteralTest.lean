/-
  Test: CerbFloat.of_string — correctly rounded C floating literals
  (semantics-audit repairs D1, 2026-09-11; record
  docs/2026-09-11_semantics-audit-repairs-record.md §D1).

  Executable bit-pattern assertions (untrusted-evaluator checks, not kernel
  proofs; no program-literal proof is stated). Each expected UInt64 is the
  IEEE 754-2019 binary64 encoding of the literal's correctly rounded value,
  taken from two independent correctly-rounded references before the Lean
  side was built: Python 3 `float()` / `float.fromhex()` and gcc (the record's
  D1 battery table). The differential pins against the fork oracle are
  tests/float/081-105; this exe pins what no C program can reach or what the
  lane cannot hold:
  * the SIGN path (`-…`): the C lexer strips the sign, so only
    CoreParser.lexNumLit (Core text) feeds a signed string to of_string —
    `-0.0` must be a negative zero (bit 63), not `0 - 0.0`;
  * the correctly rounded value of `0x8000000000000BFp-1082` (a 60-bit
    mantissa landing in the subnormal range), where the fork oracle's
    `caml_float_of_hex` double-rounds (record §D1, stop row 106) — the pin
    records THE CORRECTLY ROUNDED contract the charter fixed; the operator's
    ruling on the mirror question may move it (record §D1 open question);
  * the huge-exponent guards (`1e999999999`, `1e-999999999`) that keep the
    exact arithmetic bounded by the format.
-/
import CerbFloat

def hex64 (b : UInt64) : String :=
  let ds := Nat.toDigits 16 b.toNat
  "0x" ++ String.ofList (List.replicate (16 - ds.length) '0') ++ String.ofList ds

def pin (lit : String) (expected : UInt64) : IO Bool := do
  let got := (CerbFloat.of_string lit).toBits
  if got == expected then
    return true
  else
    IO.println s!"  ✗ FAIL {lit}: got {hex64 got}, expected {hex64 expected}"
    return false

def auditLiteral : String := "0x1" ++ String.ofList (List.replicate 260 '0') ++ "p-1040"

def main : IO UInt32 := do
  IO.println "test: CerbFloat.of_string binary64 bit patterns (correctly rounded, ties-to-even)"
  let cases : List (String × UInt64) := [
    -- zeros and the sign path (CoreParser-only)
    ("0.0", 0x0000000000000000), ("-0.0", 0x8000000000000000), ("+0.0", 0x0000000000000000),
    ("-0x0p0", 0x8000000000000000), ("-1.5", 0xBFF8000000000000), ("-0x1p-1075", 0x8000000000000000),
    ("-1e-999999999", 0x8000000000000000), ("-0x1p1024", 0xFFF0000000000000),
    -- ordinary values, both forms, suffixes
    ("1.0", 0x3FF0000000000000), ("0x1p0", 0x3FF0000000000000), ("0X1.8P1", 0x4008000000000000),
    ("0x.8p1", 0x3FF0000000000000), ("0x10p-4", 0x3FF0000000000000), ("1.5f", 0x3FF8000000000000),
    ("3.25L", 0x400A000000000000), ("0.1", 0x3FB999999999999A), ("1e23", 0x44B52D02C7E14AF6),
    (auditLiteral, 0x3FF0000000000000),
    -- ties and sticky bits at the 54th bit
    ("0x1.00000000000008p0", 0x3FF0000000000000), ("0x1.00000000000018p0", 0x3FF0000000000002),
    ("0x1.000000000000080000000000001p0", 0x3FF0000000000001),
    ("9007199254740993.0", 0x4340000000000000), ("9007199254740995.0", 0x4340000000000002),
    -- overflow boundary
    ("0x1.fffffffffffffp1023", 0x7FEFFFFFFFFFFFFF), ("1.7976931348623158e308", 0x7FEFFFFFFFFFFFFF),
    ("1.7976931348623159e308", 0x7FF0000000000000), ("0x1p1024", 0x7FF0000000000000),
    ("1e999999999", 0x7FF0000000000000),
    -- smallest normal and its neighbourhood
    ("0x1p-1022", 0x0010000000000000), ("0x0.fffffffffffffp-1022", 0x000FFFFFFFFFFFFF),
    ("2.2250738585072011e-308", 0x000FFFFFFFFFFFFF), ("2.2250738585072012e-308", 0x0010000000000000),
    -- subnormals, the half-quantum tie, underflow to zero
    ("0x1p-1074", 0x0000000000000001), ("5e-324", 0x0000000000000001), ("8.5e-324", 0x0000000000000002),
    ("0x1p-1075", 0x0000000000000000), ("0x1.8p-1075", 0x0000000000000001), ("0x1.8p-1074", 0x0000000000000002),
    ("2.4703282292062327e-324", 0x0000000000000000), ("2.4703282292062328e-324", 0x0000000000000001),
    ("1e-999999999", 0x0000000000000000),
    -- the double-rounding shape: the CORRECTLY ROUNDED value (record §D1, stop row 106)
    ("0x8000000000000BFp-1082", 0x0008000000000001)
  ]
  let mut ok := true
  for (lit, bits) in cases do
    ok := (← pin lit bits) && ok
  IO.println s!"{cases.length} literal pins checked"
  if ok then
    IO.println "All float-literal pins passed"
    return 0
  else
    IO.println "FAILED"
    return 1
