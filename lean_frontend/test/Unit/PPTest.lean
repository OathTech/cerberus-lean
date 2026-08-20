/-
  Test: arc-10 S3 pretty-printer mirrors vs recorded ORACLE outputs.

  Every expected string below is a RECORDED REFERENCE OUTPUT:
  * float formatting: generated 2026-08-20 with the project opam switch's
    OCaml 5.4.0 (`string_of_float` / `Printf.sprintf "%.*f"`, i.e. glibc
    printf) — the literal transcript is in the S3 slice record;
  * ctype/value texts: the Pp_core_ctype / Pp_core printer semantics
    (pp_core_ctype.ml:18-90, pp_core.ml:276-337), whose end-to-end
    anchor is the ci 0006/0007/0046 differential flip.

  These are TESTS (untrusted-evaluator checks), not kernel proofs.
-/

import CerbPP

open CerbPP

def check (label : String) (got expected : String) : IO Bool := do
  if got == expected then
    return true
  else
    IO.println s!"  ✗ FAIL {label}: got {repr got}, expected {repr expected}"
    return false

def mkCtype (ty : ctype_) : ctype := .Ctype [] ty

def signedInt : ctype := mkCtype (.Basic (.Integer (.Signed .Int_)))

def testCtype : IO Bool := do
  IO.println "test: ppCtype mirrors Pp_core_ctype.pp_ctype"
  let sym1 : sym := .Symbol "" 3 (.SD_Id "s")
  let anon : sym := .Symbol "" 7 .SD_None
  let cases : List (String × ctype × String) := [
    ("signed int", signedInt, "signed int"),
    ("void", mkCtype .Void0, "void"),
    ("char", mkCtype (.Basic (.Integer .Char0)), "char"),
    ("_Bool", mkCtype (.Basic (.Integer .Bool0)), "_Bool"),
    ("unsigned long", mkCtype (.Basic (.Integer (.Unsigned .Long))), "unsigned long"),
    ("uint8_t", mkCtype (.Basic (.Integer (.Unsigned (.IntN_t 8)))), "uint8_t"),
    ("int64_t", mkCtype (.Basic (.Integer (.Signed (.IntN_t 64)))), "int64_t"),
    ("size_t", mkCtype (.Basic (.Integer .Size_t)), "size_t"),
    ("double", mkCtype (.Basic (.Floating (.RealFloating .Double))), "double"),
    ("long_double", mkCtype (.Basic (.Floating (.RealFloating .LongDouble))), "long_double"),
    ("ptr", mkCtype (.Pointer default signedInt), "signed int*"),
    ("array", mkCtype (.Array0 signedInt (some 4)), "signed int[4]"),
    ("array-noN", mkCtype (.Array0 signedInt none), "signed int[]"),
    ("fn", mkCtype (.Function (default, signedInt) [(default, mkCtype (.Basic (.Integer .Char0)), false)] false),
      "signed int (char)"),
    ("fn-variadic", mkCtype (.Function (default, signedInt) [(default, signedInt, false), (default, mkCtype .Void0, false)] true),
      "signed int (signed int, void, ...)"),
    ("fn-noparams", mkCtype (.FunctionNoParams (default, signedInt)), "signed int ()"),
    ("atomic", mkCtype (.Atomic signedInt), "_Atomic (signed int)"),
    ("struct", mkCtype (.Struct sym1), "struct s"),
    ("union-anon", mkCtype (.Union0 anon), "union a_7"),
    ("enum", mkCtype (.Basic (.Integer (.Enum0 sym1))), "enum s"),
    ("byte", mkCtype .Byte, "byte")
  ]
  let mut ok := true
  for (label, ty, expected) in cases do
    ok := (← check s!"ctype/{label}" (stringFromCtype ty) expected) && ok
  if ok then IO.println "  ✓ PASS"
  return ok

def testCoreValue : IO Bool := do
  IO.println "test: stringFromCore_value mirrors Pp_core.pp_value"
  let iv42 : CerbMem.IntegerValue := .IV .Prov_none 42
  let cases : List (String × value × String) := [
    ("unit", .Vunit, "Unit"),
    ("true", .Vtrue, "True"),
    ("false", .Vfalse, "False"),
    ("specified-int", .Vloaded (.LVspecified (.OVinteger iv42)), "Specified(42)"),
    ("unspecified", .Vloaded (.LVunspecified signedInt), "Unspecified('signed int')"),
    ("tuple", .Vtuple [.Vtrue, .Vloaded (.LVspecified (.OVinteger iv42))], "(True, Specified(42))"),
    ("list", .Vlist .BTy_boolean [.Vtrue, .Vfalse], "[True, False]"),
    ("null-ptr", .Vobject (.OVpointer (.PV .Prov_none (.PVnull signedInt))), "NULL(signed int)"),
    ("concrete-ptr", .Vobject (.OVpointer (.PV (.Prov_some 2) (.PVconcrete none 189))), "(@2, 0xbd)"),
    ("funptr", .Vobject (.OVpointer (.PV .Prov_none (.PVfunction (.Symbol "" 1 (.SD_Id "f"))))), "Cfunction(f)")
  ]
  let mut ok := true
  for (label, v, expected) in cases do
    ok := (← check s!"value/{label}" (stringFromCore_value v) expected) && ok
  -- mem-value payloads (impl_mem.ml:591-615 pp_mem_value shapes)
  let mv : CerbMem.MemValue := .MVarray [.MVinteger (.Signed .Int_) (.IV .Prov_none 1),
                                         .MVinteger (.Signed .Int_) (.IV .Prov_none 2)]
  ok := (← check "memvalue/array" (stringFromMemValue mv) "{1, 2}") && ok
  let mvs : CerbMem.MemValue := .MVstruct (.Symbol "" 4 (.SD_Id "st"))
    [(.Identifier default "x", signedInt, .MVinteger (.Signed .Int_) (.IV .Prov_none 7)),
     (.Identifier default "y", signedInt, .MVunspecified signedInt)]
  ok := (← check "memvalue/struct" (stringFromMemValue mvs) "(struct st){.x= 7, .y= UNSPEC}") && ok
  ok := (← check "prefix/malloc" (stringFromSymbol_prefix .PrefMalloc) "{malloc'd}") && ok
  ok := (← check "prefix/source" (stringFromSymbol_prefix (.PrefSource default [.Symbol "" 1 (.SD_Id "main"), .Symbol "" 2 (.SD_Id "x")])) "{main.x}") && ok
  if ok then IO.println "  ✓ PASS"
  return ok

/-- OCaml 5.4.0 reference transcript (string_of_float), 2026-08-20. -/
def sfCases : List (Float × String) := [
  (1.0, "1."),
  (0.5, "0.5"),
  (3.14, "3.14"),
  (1e30, "1e+30"),
  (1e-5, "1e-05"),
  (0.001, "0.001"),
  (0.1, "0.1"),
  (-0.0, "-0."),
  (0.0, "0."),
  (1234567890123456.0, "1.23456789012e+15"),
  (2.5, "2.5"),
  (5e-324, "4.94065645841e-324"),
  (1.7976931348623157e308, "1.79769313486e+308"),
  (123456789012.0, "123456789012."),
  (0.0001, "0.0001"),
  (3.0e7, "30000000."),
  (6.02214076e23, "6.02214076e+23"),
  (-42.75, "-42.75")
]

/-- OCaml 5.4.0 reference transcript (Printf.sprintf "%.*f"), 2026-08-20. -/
def ffCases : List (Nat × Float × String) := [
  (6, 3.14, "3.140000"),
  (0, 2.5, "2"),      -- half-even down
  (0, 3.5, "4"),      -- half-even up
  (2, 0.125, "0.12"), -- exact tie → even
  (2, 0.135, "0.14"), -- 0.135 is 0.1350000...01 in binary → up (exact-value rounding)
  (6, 0.1, "0.100000"),
  (1, 0.25, "0.2"),
  (6, -0.0, "-0.000000"),
  (6, 1e-7, "0.000000"),
  (3, 1234.5678, "1234.568"),
  (6, 1e20, "100000000000000000000.000000"),
  (0, 0.5, "0")
]

def testFloats : IO Bool := do
  IO.println "test: CerbFloat.string_of_float / formatFixed vs OCaml transcript"
  let mut ok := true
  for (f, expected) in sfCases do
    ok := (← check s!"string_of_float {expected}" (CerbFloat.string_of_float f) expected) && ok
  for (p, f, expected) in ffCases do
    ok := (← check s!"%.{p}f {expected}" (format_string_of_float p f) expected) && ok
  -- non-finite (glibc %f semantics; NaN-sign caveat documented in CerbFloat)
  ok := (← check "inf" (CerbFloat.string_of_float (1.0 / 0.0)) "inf") && ok
  ok := (← check "-inf" (CerbFloat.string_of_float (-1.0 / 0.0)) "-inf") && ok
  ok := (← check "nan" (CerbFloat.string_of_float (0.0 / 0.0)) "nan") && ok
  ok := (← check "%f inf" (format_string_of_float 6 (1.0 / 0.0)) "inf") && ok
  if ok then IO.println "  ✓ PASS"
  return ok

def main : IO UInt32 := do
  IO.println "=== PPTest: arc-10 S3 pretty-printer mirrors ==="
  let r1 ← testCtype
  let r2 ← testCoreValue
  let r3 ← testFloats
  if r1 && r2 && r3 then
    IO.println "All PP tests passed"
    return 0
  else
    IO.println "PP TESTS FAILED"
    return 1
