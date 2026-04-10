/-
  Unit tests for CoreParser.
  Tests each parser combinator from the bottom up.
  Run: lake build CoreParserTest
-/

import CoreParser
open Std.Internal.Parsec.String

set_option autoImplicit true

namespace CoreParserTest

/-! ## Test helpers -/

def assertOk (name : String) (result : Except String α) : IO Unit :=
  match result with
  | .ok _ => IO.println s!"  ✓ {name}"
  | .error e => IO.println s!"  ✗ {name}: {e}"

def assertEq [BEq α] [Repr α] (name : String) (result : Except String α) (expected : α) : IO Unit :=
  match result with
  | .ok v => if v == expected
    then IO.println s!"  ✓ {name}"
    else IO.println s!"  ✗ {name}: got {repr v}, expected {repr expected}"
  | .error e => IO.println s!"  ✗ {name}: {e}"

def assertErr (name : String) (result : Except String α) : IO Unit :=
  match result with
  | .ok _ => IO.println s!"  ✗ {name}: expected error but got ok"
  | .error _ => IO.println s!"  ✓ {name}"

def run (p : Parser α) (input : String) : Except String α := p.run input

/-! ## Tests -/

def testLexer : IO Unit := do
  IO.println "=== Lexer ==="

  -- Integers
  assertEq "int positive" (run CoreParser.lexInt "42") 42
  assertEq "int negative" (run CoreParser.lexInt "-7") (-7)
  assertEq "int zero" (run CoreParser.lexInt "0") 0

  -- Identifiers
  assertEq "ident simple" (run CoreParser.lexIdent "hello") "hello"
  assertEq "ident underscore" (run CoreParser.lexIdent "_foo") "_foo"
  assertEq "ident with digits" (run CoreParser.lexIdent "x42") "x42"
  assertErr "ident starts digit" (run CoreParser.lexIdent "42x")

  -- Keywords
  assertOk "kw match" (run (CoreParser.lexKw "fun") "fun ")
  assertErr "kw partial" (run (CoreParser.lexKw "fun") "funky")

  -- Strings
  assertEq "string simple" (run CoreParser.lexStr "\"hello\"") "hello"
  assertEq "string escape" (run CoreParser.lexStr "\"a\\nb\"") "a\nb"

  -- Symbols
  assertOk "sym paren" (run (CoreParser.lexSym "(") "(")
  assertOk "sym assign" (run (CoreParser.lexSym ":=") ":=")

  -- Impl names
  assertEq "impl name" (run CoreParser.lexImpl "<bits_in_byte>") "bits_in_byte"

  -- Whitespace/comments
  assertEq "ws then int" (run (CoreParser.lexWs *> CoreParser.lexInt) "  42") 42
  assertEq "comment then int" (run (CoreParser.lexWs *> CoreParser.lexInt) "-- hi\n42") 42
  assertEq "block comment" (run (CoreParser.lexWs *> CoreParser.lexInt) "{- yo -}42") 42

def testTypes : IO Unit := do
  IO.println "=== Types ==="

  -- Core object types
  assertOk "obj integer" (run CoreParser.pCoreObjectType "integer")
  assertOk "obj floating" (run CoreParser.pCoreObjectType "floating")
  assertOk "obj pointer" (run CoreParser.pCoreObjectType "pointer")

  -- Core base types
  assertOk "base unit" (run CoreParser.pCoreBaseType "unit")
  assertOk "base boolean" (run CoreParser.pCoreBaseType "boolean")
  assertOk "base ctype" (run CoreParser.pCoreBaseType "ctype")
  assertOk "base integer" (run CoreParser.pCoreBaseType "integer")
  assertOk "base loaded integer" (run CoreParser.pCoreBaseType "loaded integer")

  -- Core type (with eff)
  assertOk "type eff" (run CoreParser.pCoreType "eff integer")
  assertOk "type base" (run CoreParser.pCoreType "integer")

  -- Ctypes
  assertOk "ctype void" (run CoreParser.pCtype "void")
  assertOk "ctype int" (run CoreParser.pCtype "signed int")
  assertOk "ctype char" (run CoreParser.pCtype "char")
  assertOk "ctype pointer" (run CoreParser.pCtype "void*")

def testValues : IO Unit := do
  IO.println "=== Values ==="

  assertOk "val unit" (run CoreParser.pValue "Unit")
  assertOk "val true" (run CoreParser.pValue "True")
  assertOk "val false" (run CoreParser.pValue "False")
  assertOk "val int" (run CoreParser.pValue "42")
  assertOk "val negative" (run CoreParser.pValue "-1")

def testPatterns : IO Unit := do
  IO.println "=== Patterns ==="

  assertOk "pat wildcard" (run CoreParser.pPattern "_ : integer")
  assertOk "pat named" (run CoreParser.pPattern "x : integer")

def testPexpr : IO Unit := do
  IO.println "=== Pure Expressions ==="

  -- Test pValue directly first (already passed above, but through pPexpr)
  assertOk "pe:value:42" (run CoreParser.pValue "42")

  -- Test pPexprAtom directly
  assertOk "pe:atom:42" (run CoreParser.pPexprAtom "42")
  -- Then the full pPexpr
  assertOk "pe int" (run CoreParser.pPexpr "42")
  -- If the above overflows, the rest will too
  assertOk "pe true" (run CoreParser.pPexpr "True")
  assertOk "pe unit" (run CoreParser.pPexpr "Unit")

def testExpr : IO Unit := do
  IO.println "=== Effectful Expressions ==="

  assertOk "expr pure" (run CoreParser.pExpr "pure(42)")

def testDeclarations : IO Unit := do
  IO.println "=== Declarations ==="

  assertOk "def impl inline" (CoreParser.parseFileSummary "def <bits_in_byte> : integer := 8\n")
  assertOk "def impl multiline" (CoreParser.parseFileSummary "def <bits_in_byte> : integer :=\n  8\n")
  assertOk "fun simple" (CoreParser.parseFileSummary "fun f (n: integer): integer := n\n")
  assertOk "two decls" (CoreParser.parseFileSummary
    "def <bits_in_byte> : integer :=\n  8\n\nfun <Integer.encode> (ty: ctype, n: integer) : integer :=\n  error(<<<integerEncode>>>, Unit)\n")
  assertOk "pe error" (run CoreParser.pPexpr "error(<<<integerEncode>>>, Unit)")
  assertOk "pe sym" (run CoreParser.pPexpr "x")
  assertOk "pe call0" (run CoreParser.pPexpr "f()")
  assertOk "pe call1" (run CoreParser.pPexpr "f(x)")
  assertOk "pe call2" (run CoreParser.pPexpr "f(x, y)")
  assertOk "pe wrapX" (run CoreParser.pPexpr "wrapX(ty, n)")
  assertOk "pe wrapI" (run CoreParser.pPexpr "wrapI(ty, n)")
  assertOk "pe with block comment" (CoreParser.parseFileSummary "fun f (n: integer): integer :=\n  wrapI(n, 0)\n{- comment -}\n")
  assertOk "impl 10 lines" (CoreParser.parseFileSummary
    "-- auto-generated\n\ndef <bits_in_byte> : integer :=\n  8\n\n\n-- GCC\nfun <Integer.encode> (ty: ctype, n: integer) : integer :=\n  error(<<<integerEncode>>>, Unit) -- encodeTwos\n")

def testFiles : IO Unit := do
  IO.println "=== Files ==="

  assertOk "empty" (CoreParser.parseFileSummary "")
  assertOk "comment only" (CoreParser.parseFileSummary "-- hello\n")

  -- Test actual file from disk
  let implPath := "../runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let fileExists ← System.FilePath.pathExists implPath
  if fileExists then
    let content ← IO.FS.readFile implPath
    -- Test just the first declaration
    let lines := content.splitOn "\n"
    let first5 := String.intercalate "\n" (lines.take 5)
    assertOk "impl first5" (CoreParser.parseFileSummary first5)
    let first15 := String.intercalate "\n" (lines.take 15)
    assertOk "impl first15" (CoreParser.parseFileSummary first15)
    let first30 := String.intercalate "\n" (lines.take 30)
    assertOk "impl first30" (CoreParser.parseFileSummary first30)
    let first50 := String.intercalate "\n" (lines.take 50)
    assertOk "impl first50" (CoreParser.parseFileSummary first50)
    assertOk "impl full" (CoreParser.parseFileSummary content)
    -- Test all runtime .core/.impl files
    let files := [
      ("std.core", "../runtime/libcore/std.core"),
      ("std_inner_arg_temps.core", "../runtime/libcore/std_inner_arg_temps.core"),
      ("gcc x86_64 impl", "../runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"),
      ("gcc i686 impl", "../runtime/libcore/impls/i686-apple-darwin10-gcc-4.2.1.impl")
    ]
    for (name, path) in files do
      let fileExists ← System.FilePath.pathExists path
      if fileExists then
        let content ← IO.FS.readFile path
        assertOk name (CoreParser.parseFileSummary content)
      else
        IO.println s!"  (skipping {name} — not found)"
  else
    IO.println "  (skipping file tests — runtime not found)"

end CoreParserTest

def main : IO Unit := do
  IO.println "CoreParser unit tests"
  IO.println ""
  CoreParserTest.testLexer
  CoreParserTest.testTypes
  CoreParserTest.testValues
  CoreParserTest.testPatterns
  CoreParserTest.testPexpr
  CoreParserTest.testExpr
  CoreParserTest.testDeclarations
  CoreParserTest.testFiles
  IO.println ""
  IO.println "Done."
