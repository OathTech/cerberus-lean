/-
  Unit tests for CoreParser.
  Tests each parser combinator from the bottom up, with emphasis on
  constructs that appear in real cerberus --pp core output.

  Run: cd lean_frontend && lake build core-parser-test && .lake/build/bin/core-parser-test
-/

import CoreParser
open Std.Internal.Parsec.String

set_option autoImplicit true

namespace CoreParserTest

/-! ## Test helpers -/

structure TestState where
  passed : Nat := 0
  failed : Nat := 0

abbrev TestM := StateRefT TestState IO

def pass (name : String) : TestM Unit := do
  IO.println s!"  ✓ {name}"
  modify fun s => { s with passed := s.passed + 1 }

def fail_ (name : String) (msg : String) : TestM Unit := do
  IO.println s!"  ✗ {name}: {msg}"
  modify fun s => { s with failed := s.failed + 1 }

def assertOk (name : String) (result : Except String α) : TestM Unit :=
  match result with
  | .ok _ => pass name
  | .error e => fail_ name e

def assertEq [BEq α] [Repr α] (name : String) (result : Except String α) (expected : α) : TestM Unit :=
  match result with
  | .ok v => if v == expected then pass name
             else fail_ name s!"got {repr v}, expected {repr expected}"
  | .error e => fail_ name e

def assertErr (name : String) (result : Except String α) : TestM Unit :=
  match result with
  | .ok _ => fail_ name "expected error but got ok"
  | .error _ => pass name

def run (p : Parser α) (input : String) : Except String α := p.run input

/-- Run parseFile and return the declaration counts as (fun, proc, impl, tag, glob, builtin). -/
def parseCounts (input : String) : Except String (Nat × Nat × Nat × Nat × Nat × Nat) :=
  match CoreParser.parseFile input with
  | .ok cf => .ok (cf.funs.length, cf.procs.length, cf.impls.length,
                   cf.tagDefs.length, cf.globs.length, cf.builtins.length)
  | .error e => .error e

/-- Assert that parseFile succeeds and has exactly the expected declaration counts. -/
def assertCounts (name : String) (input : String) (expected : Nat × Nat × Nat × Nat × Nat × Nat) : TestM Unit :=
  match parseCounts input with
  | .ok counts =>
    if counts == expected then pass name
    else fail_ name s!"counts {counts} ≠ expected {expected}"
  | .error e => fail_ name e

/-- Run parseFile and return the captured ailnames as
    (attribute-string, declared-symbol-name) pairs. -/
def parseAilnames (input : String) : Except String (List (String × String)) :=
  match CoreParser.parseFile input with
  | .ok cf => .ok (cf.ailnames.map (fun (name, s) =>
      match s with
      | Symbol _ _ (SD_Id declName) => (name, declName)
      | _ => (name, "<no-SD_Id>")))
  | .error e => .error e

/-- Assert parseFile succeeds with at least one declaration. -/
def assertSomeDecls (name : String) (input : String) : TestM Unit :=
  match parseCounts input with
  | .ok (f, p, i, t, g, b) =>
    if f + p + i + t + g + b > 0 then pass s!"{name} ({f}f {p}p {i}i {t}t {g}g {b}b)"
    else fail_ name "0 declarations"
  | .error e => fail_ name e

/-! ## Tests -/

def testLexer : TestM Unit := do
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
  assertEq "ident double underscore" (run CoreParser.lexIdent "__conv_int__") "__conv_int__"
  assertEq "ident with underscore mid" (run CoreParser.lexIdent "a_506") "a_506"

  -- Apostrophe handling (critical for 'ctype' parsing)
  assertEq "ident stops at quote" (run CoreParser.lexIdent "void'rest") "void"
  -- Does lexKw work when followed by '?
  assertOk "kw void before quote" (run (CoreParser.lexKw "void") "void'")

  -- Keywords
  assertOk "kw match" (run (CoreParser.lexKw "fun") "fun ")
  assertErr "kw partial" (run (CoreParser.lexKw "fun") "funky")

  -- Strings
  assertEq "string simple" (run CoreParser.lexStr "\"hello\"") "hello"
  -- escape sequences are kept VERBATIM, as the OCaml lexer's `cstring` keeps
  -- its lexemes (core_lexer.mll:257-274, :296-297; zero-discrepancy Z2-CP-07 —
  -- this used to decode `\n` to a newline)
  assertEq "string escape kept verbatim" (run CoreParser.lexStr "\"a\\nb\"") "a\\nb"
  assertEq "string escape \\\" kept" (run CoreParser.lexStr "\"a\\\"b\"") "a\\\"b"
  -- fail-closed: an escape outside the mll set, or a raw newline, is a lexer error
  assertErr "string unknown escape" (run CoreParser.lexStr "\"a\\qb\"")
  assertErr "string raw newline" (run CoreParser.lexStr "\"a\nb\"")

  -- Symbols
  assertOk "sym paren" (run (CoreParser.lexSym "(") "(")
  assertOk "sym assign" (run (CoreParser.lexSym ":=") ":=")
  assertOk "sym arrow" (run (CoreParser.lexSym "=>") "=>")
  assertOk "sym semicolon" (run (CoreParser.lexSym ";") ";")
  assertOk "sym double colon" (run (CoreParser.lexSym "::") "::")

  -- Impl names
  assertEq "impl name" (run CoreParser.lexImpl "<bits_in_byte>") "bits_in_byte"
  assertEq "impl name with dot" (run CoreParser.lexImpl "<Integer.encode>") "Integer.encode"

  -- Double angle (UB names)
  assertEq "ub name" (run CoreParser.lexDoubleAngle "<<UB036_exceptional_condition>>") "UB036_exceptional_condition"
  assertEq "ub name dummy" (run CoreParser.lexDoubleAngle "<<DUMMY(some text)>>") "DUMMY(some text)"

  -- Triple angle (error names)
  assertEq "error name" (run CoreParser.lexTripleAngle "<<<integerEncode>>>") "integerEncode"

  -- Whitespace/comments
  assertEq "ws then int" (run (CoreParser.lexWs *> CoreParser.lexInt) "  42") 42
  assertEq "comment then int" (run (CoreParser.lexWs *> CoreParser.lexInt) "-- hi\n42") 42
  assertEq "block comment" (run (CoreParser.lexWs *> CoreParser.lexInt) "{- yo -}42") 42
  assertEq "multiline comment" (run (CoreParser.lexWs *> CoreParser.lexInt) "{- multi\n  line -}\n42") 42

def testTypes : TestM Unit := do
  IO.println "=== Types ==="

  -- Core object types
  assertOk "obj integer" (run CoreParser.pCoreObjectType "integer")
  assertOk "obj floating" (run CoreParser.pCoreObjectType "floating")
  assertOk "obj pointer" (run CoreParser.pCoreObjectType "pointer")
  assertOk "obj array(integer)" (run CoreParser.pCoreObjectType "array(integer)")
  assertOk "obj struct tag" (run CoreParser.pCoreObjectType "struct foo")
  assertOk "obj union tag" (run CoreParser.pCoreObjectType "union bar")

  -- Core base types
  assertOk "base unit" (run CoreParser.pCoreBaseType "unit")
  assertOk "base boolean" (run CoreParser.pCoreBaseType "boolean")
  assertOk "base ctype" (run CoreParser.pCoreBaseType "ctype")
  assertOk "base storable" (run CoreParser.pCoreBaseType "storable")
  assertOk "base integer" (run CoreParser.pCoreBaseType "integer")
  assertOk "base pointer" (run CoreParser.pCoreBaseType "pointer")
  assertOk "base loaded integer" (run CoreParser.pCoreBaseType "loaded integer")
  assertOk "base list" (run CoreParser.pCoreBaseType "[integer]")
  assertOk "base tuple" (run CoreParser.pCoreBaseType "(integer, boolean)")
  assertOk "base loaded pointer" (run CoreParser.pCoreBaseType "loaded pointer")

  -- Core type (with eff)
  assertOk "type eff integer" (run CoreParser.pCoreType "eff integer")
  assertOk "type eff loaded integer" (run CoreParser.pCoreType "eff loaded integer")
  assertOk "type base" (run CoreParser.pCoreType "integer")

  -- Ctypes (these appear inside 'quotes' in Core)
  assertOk "ctype void" (run CoreParser.pCtype "void")
  assertOk "ctype signed int" (run CoreParser.pCtype "signed int")
  assertOk "ctype unsigned int" (run CoreParser.pCtype "unsigned int")
  assertOk "ctype char" (run CoreParser.pCtype "char")
  assertOk "ctype _Bool" (run CoreParser.pCtype "_Bool")
  assertOk "ctype void*" (run CoreParser.pCtype "void*")
  assertOk "ctype signed int*" (run CoreParser.pCtype "signed int*")
  assertOk "ctype const void*" (run CoreParser.pCtype "const void*")
  assertOk "ctype int[10]" (run CoreParser.pCtype "signed int[10]")
  assertOk "ctype struct tag" (run CoreParser.pCtype "struct foo")
  assertOk "ctype union tag" (run CoreParser.pCtype "union bar")
  -- enum ctype literal (2026-09-01 S-basket item 2; pp_core_ctype.ml:42
  -- emits `enum TAG` but upstream's core parser can't re-read it —
  -- see the pIntegerType arm's divergence note)
  (do -- structural check (no Repr for ctype; BEq is ctypeEqual)
    let expected : ctype :=
      Ctype [] (Basic (Integer (Enum0 (CoreParser.internSym "size"))))
    match run CoreParser.pCtype "enum size" with
    | .ok v =>
      if v == expected then pass "ctype enum tag"
      else fail_ "ctype enum tag" "parsed, but not Enum0 'size'"
    | .error e => fail_ "ctype enum tag" e)
  assertOk "ctype enum tag pointer" (run CoreParser.pCtype "enum size*")
  assertOk "ctype int8_t" (run CoreParser.pCtype "int8_t")
  assertOk "ctype uint64_t" (run CoreParser.pCtype "uint64_t")
  assertOk "ctype size_t" (run CoreParser.pCtype "size_t")
  assertOk "ctype ptrdiff_t" (run CoreParser.pCtype "ptrdiff_t")
  -- Function types
  assertOk "ctype function" (run CoreParser.pCtype "signed int (signed int, signed int)")
  assertOk "ctype function pointer" (run CoreParser.pCtype "signed int (*) (signed int, signed int)")

def testValues : TestM Unit := do
  IO.println "=== Values ==="

  assertOk "val unit" (run CoreParser.pValue "Unit")
  assertOk "val true" (run CoreParser.pValue "True")
  assertOk "val false" (run CoreParser.pValue "False")
  assertOk "val int 0" (run CoreParser.pValue "0")
  assertOk "val int 42" (run CoreParser.pValue "42")
  assertOk "val int negative" (run CoreParser.pValue "-1")
  assertOk "val NULL" (run CoreParser.pValue "NULL(void)")

  -- Ctype values: bisect the failure
  IO.println "  --- ctype value bisection ---"
  assertOk "val ctype void*" (run CoreParser.pValue "'void*'")
  assertOk "val ctype void" (run CoreParser.pValue "'void'")
  assertOk "val ctype signed int" (run CoreParser.pValue "'signed int'")

  -- Test pCtype on the inner content (no quotes)
  IO.println "  --- pCtype (no quotes) ---"
  assertOk "pCtype void" (run CoreParser.pCtype "void")
  assertOk "pCtype signed int" (run CoreParser.pCtype "signed int")
  assertOk "pCtype void*" (run CoreParser.pCtype "void*")

  -- Test: can we parse a quote char?
  IO.println "  --- lexSym quote ---"
  assertOk "lexSym quote" (run (CoreParser.lexSym "'") "'")
  -- Test: quote then ctype then quote
  assertOk "quote-ctype-quote void*" (run (do CoreParser.lexSym "'"; let _ ← CoreParser.pCtype; CoreParser.lexSym "'") "'void*'")
  assertOk "quote-ctype-quote void" (run (do CoreParser.lexSym "'"; let _ ← CoreParser.pCtype; CoreParser.lexSym "'") "'void'")
  assertOk "quote-ctype-quote signed int" (run (do CoreParser.lexSym "'"; let _ ← CoreParser.pCtype; CoreParser.lexSym "'") "'signed int'")

def testPatterns : TestM Unit := do
  IO.println "=== Patterns ==="

  assertOk "pat wildcard" (run CoreParser.pPattern "_ : integer")
  assertOk "pat named" (run CoreParser.pPattern "x : integer")
  assertOk "pat named underscore prefix" (run CoreParser.pPattern "_foo : ctype")
  assertOk "pat named numbered" (run CoreParser.pPattern "a_506 : integer")
  assertOk "pat tuple" (run CoreParser.pPattern "(x : integer, y : integer)")
  assertOk "pat ctor Specified" (run CoreParser.pPattern "Specified(x : integer)")
  assertOk "pat ctor Unspecified" (run CoreParser.pPattern "Unspecified(_ : ctype)")
  assertOk "pat empty list" (run CoreParser.pPattern "[] : [integer]")
  assertOk "pat cons" (run CoreParser.pPattern "x : integer :: xs : [integer]")
  assertOk "pat loaded integer tuple" (run CoreParser.pPattern "(a_506 : loaded integer, a_507 : loaded integer)")
  assertOk "pat wildcard loaded tuple" (run CoreParser.pPattern "_ : (loaded integer,loaded integer)")

def testPexprAtoms : TestM Unit := do
  IO.println "=== Pexpr atoms ==="

  -- Integers and basic values
  assertOk "pe int 42" (run CoreParser.pPexpr "42")
  assertOk "pe int 0" (run CoreParser.pPexpr "0")
  assertOk "pe negative" (run CoreParser.pPexpr "-1")
  assertOk "pe True" (run CoreParser.pPexpr "True")
  assertOk "pe False" (run CoreParser.pPexpr "False")
  assertOk "pe Unit" (run CoreParser.pPexpr "Unit")

  -- Symbol references
  assertOk "pe sym x" (run CoreParser.pPexpr "x")
  assertOk "pe sym a_506" (run CoreParser.pPexpr "a_506")

  -- Ctype values (the critical test!)
  assertOk "pe ctype signed int" (run CoreParser.pPexpr "'signed int'")
  assertOk "pe ctype void" (run CoreParser.pPexpr "'void'")
  assertOk "pe ctype void*" (run CoreParser.pPexpr "'void*'")
  assertOk "pe ctype unsigned int" (run CoreParser.pPexpr "'unsigned int'")
  assertOk "pe ctype char" (run CoreParser.pPexpr "'char'")

  -- Impl constants
  assertOk "pe impl" (run CoreParser.pPexpr "<bits_in_byte>")

  -- NULL
  assertOk "pe NULL(void)" (run CoreParser.pPexpr "NULL(void)")

def testPexprConstructors : TestM Unit := do
  IO.println "=== Pexpr constructors ==="

  assertOk "pe Specified(42)" (run CoreParser.pPexpr "Specified(42)")
  assertOk "pe Specified(0)" (run CoreParser.pPexpr "Specified(0)")
  assertOk "pe Unspecified('signed int')" (run CoreParser.pPexpr "Unspecified('signed int')")
  assertOk "pe Ivmax('signed int')" (run CoreParser.pPexpr "Ivmax('signed int')")
  assertOk "pe Ivmin('signed int')" (run CoreParser.pPexpr "Ivmin('signed int')")
  assertOk "pe Ivsizeof('signed int')" (run CoreParser.pPexpr "Ivsizeof('signed int')")
  assertOk "pe Ivalignof('signed int')" (run CoreParser.pPexpr "Ivalignof('signed int')")
  assertOk "pe IvCOMPL(x, y)" (run CoreParser.pPexpr "IvCOMPL(x, y)")
  assertOk "pe IvAND(x, y, z)" (run CoreParser.pPexpr "IvAND(x, y, z)")
  assertOk "pe IvOR(x, y, z)" (run CoreParser.pPexpr "IvOR(x, y, z)")
  assertOk "pe IvXOR(x, y, z)" (run CoreParser.pPexpr "IvXOR(x, y, z)")
  assertOk "pe Fvfromint(x)" (run CoreParser.pPexpr "Fvfromint(x)")
  assertOk "pe Ivfromfloat(x, y)" (run CoreParser.pPexpr "Ivfromfloat(x, y)")
  assertOk "pe Array(x, y)" (run CoreParser.pPexpr "Array(x, y)")
  assertOk "pe IvMaxAlignment" (run CoreParser.pPexpr "IvMaxAlignment")

def testPexprExpressions : TestM Unit := do
  IO.println "=== Pexpr compound expressions ==="

  -- Function calls
  assertOk "pe call 0 args" (run CoreParser.pPexpr "f()")
  assertOk "pe call 1 arg" (run CoreParser.pPexpr "f(x)")
  assertOk "pe call 2 args" (run CoreParser.pPexpr "f(x, y)")
  assertOk "pe call conv_loaded_int" (run CoreParser.pPexpr "conv_loaded_int('signed int', a_506)")
  assertOk "pe call conv_int" (run CoreParser.pPexpr "conv_int('signed int', x)")

  -- Impl function calls
  assertOk "pe impl call" (run CoreParser.pPexpr "<Integer.encode>(x, y)")

  -- Binary operators (with precedence)
  assertOk "pe add" (run CoreParser.pPexpr "x + y")
  assertOk "pe sub" (run CoreParser.pPexpr "x - y")
  assertOk "pe mul" (run CoreParser.pPexpr "x * y")
  assertOk "pe div" (run CoreParser.pPexpr "x / y")
  assertOk "pe eq" (run CoreParser.pPexpr "x = y")
  assertOk "pe gt" (run CoreParser.pPexpr "x > y")
  assertOk "pe lt" (run CoreParser.pPexpr "x < y")
  assertOk "pe ge" (run CoreParser.pPexpr "x >= y")
  assertOk "pe le" (run CoreParser.pPexpr "x <= y")
  assertOk "pe and" (run CoreParser.pPexpr "x /\\ y")
  assertOk "pe or" (run CoreParser.pPexpr "x \\/ y")
  assertOk "pe exp" (run CoreParser.pPexpr "x ^ y")

  -- Conv_int with operator (from real Core output)
  assertOk "pe conv_int eq" (run CoreParser.pPexpr "conv_int('signed int', a_511) = conv_int('signed int', a_512)")

  -- Cons
  assertOk "pe cons" (run CoreParser.pPexpr "x :: xs")

  -- List literals
  assertOk "pe empty list" (run CoreParser.pPexpr "[] : [integer]")
  assertOk "pe list literal" (run CoreParser.pPexpr "[x, y] : [integer]")

  -- Tuples
  assertOk "pe tuple" (run CoreParser.pPexpr "(x, y)")
  assertOk "pe tuple 3" (run CoreParser.pPexpr "(x, y, z)")

  -- not
  assertOk "pe not" (run CoreParser.pPexpr "not(x)")
  assertOk "pe not eq" (run CoreParser.pPexpr "not(a_508 = 1)")

  -- if-then-else (pexpr level)
  assertOk "pe if" (run CoreParser.pPexpr "if x then y else z")
  assertOk "pe if not eq" (run CoreParser.pPexpr "if not(a_508 = 1) then True else False")
  assertOk "pe if conv_int" (run CoreParser.pPexpr "if conv_int('signed int', x) = conv_int('signed int', y) then Specified(1) else Specified(0)")

  -- let (pexpr level)
  assertOk "pe let" (run CoreParser.pPexpr "let x : integer = 42 in x")

  -- case (pexpr level)
  assertOk "pe case simple" (run CoreParser.pPexpr "case x of | Specified(a : integer) => a | _ : loaded integer => 0 end")
  -- Real case from cerberus output:
  assertOk "pe case loaded pair" (run CoreParser.pPexpr
    "case (a_506, a_507) of | (Specified(a_508 : integer), Specified(a_509 : integer)) => Specified(catch_exceptional_condition_add('signed int', __conv_int__('signed int', a_508), __conv_int__('signed int', a_509))) | _ : (loaded integer,loaded integer) => undef(<<UB036_exceptional_condition>>) end")

  -- undef
  assertOk "pe undef" (run CoreParser.pPexpr "undef(<<UB036_exceptional_condition>>)")
  assertOk "pe undef reached_end" (run CoreParser.pPexpr "undef(<<UB088_reached_end_of_function>>)")

  -- error
  assertOk "pe error" (run CoreParser.pPexpr "error(<<<integerEncode>>>, Unit)")

  -- __conv_int__
  assertOk "pe __conv_int__" (run CoreParser.pPexpr "__conv_int__('signed int', a_508)")

  -- wrapI / catch_exceptional_condition
  assertOk "pe wrapI_add" (run CoreParser.pPexpr "wrapI_add('signed int', x, y)")
  assertOk "pe wrapI_sub" (run CoreParser.pPexpr "wrapI_sub('signed int', x, y)")
  assertOk "pe wrapI_mul" (run CoreParser.pPexpr "wrapI_mul('signed int', x, y)")
  assertOk "pe catch_add" (run CoreParser.pPexpr "catch_exceptional_condition_add('signed int', x, y)")
  assertOk "pe catch_sub" (run CoreParser.pPexpr "catch_exceptional_condition_sub('signed int', x, y)")
  assertOk "pe catch_mul" (run CoreParser.pPexpr "catch_exceptional_condition_mul('signed int', x, y)")

  -- Nested from real output: catch_exceptional_condition_add with __conv_int__ args
  assertOk "pe catch+conv" (run CoreParser.pPexpr "catch_exceptional_condition_add('signed int', __conv_int__('signed int', a_508), __conv_int__('signed int', a_509))")

  -- cfunction
  assertOk "pe cfunction" (run CoreParser.pPexpr "cfunction(x)")

  -- Struct/union
  assertOk "pe struct" (run CoreParser.pPexpr "(struct foo) {.x = 1, .y = 2}")
  assertOk "pe union" (run CoreParser.pPexpr "(union bar) {.x = 1}")

  -- array_shift, member_shift
  assertOk "pe array_shift" (run CoreParser.pPexpr "array_shift(p, 'signed int', i)")
  assertOk "pe member_shift" (run CoreParser.pPexpr "member_shift(p, foo, .bar)")

  -- is_scalar, is_integer, is_signed, is_unsigned, are_compatible
  assertOk "pe is_scalar" (run CoreParser.pPexpr "is_scalar(x)")
  assertOk "pe is_integer" (run CoreParser.pPexpr "is_integer(x)")
  assertOk "pe is_signed" (run CoreParser.pPexpr "is_signed(x)")
  assertOk "pe is_unsigned" (run CoreParser.pPexpr "is_unsigned(x)")
  assertOk "pe are_compatible" (run CoreParser.pPexpr "are_compatible(x, y)")

  -- Parenthesized pexpr
  assertOk "pe paren" (run CoreParser.pPexpr "(42)")
  assertOk "pe paren complex" (run CoreParser.pPexpr "(x + y)")

def testExprAtoms : TestM Unit := do
  IO.println "=== Expr atoms ==="

  -- pure
  assertOk "expr pure(42)" (run CoreParser.pExpr "pure(42)")
  assertOk "expr pure(Specified(42))" (run CoreParser.pExpr "pure(Specified(42))")
  assertOk "expr pure(Unit)" (run CoreParser.pExpr "pure(Unit)")
  assertOk "expr pure(x)" (run CoreParser.pExpr "pure(x)")
  assertOk "expr pure(a_507)" (run CoreParser.pExpr "pure(a_507)")
  assertOk "expr pure(Specified(0))" (run CoreParser.pExpr "pure(Specified(0))")

  -- Actions
  assertOk "expr create" (run CoreParser.pExpr "create(Ivalignof('signed int'), 'signed int')")
  assertOk "expr store" (run CoreParser.pExpr "store('signed int', x, y)")
  assertOk "expr store conv" (run CoreParser.pExpr "store('signed int', x, conv_loaded_int('signed int', a_507))")
  assertOk "expr load" (run CoreParser.pExpr "load('signed int', a_508)")
  assertOk "expr kill" (run CoreParser.pExpr "kill('signed int', x)")
  assertOk "expr free" (run CoreParser.pExpr "free(x)")
  assertOk "expr alloc" (run CoreParser.pExpr "alloc('signed int', x)")
  assertOk "expr fence" (run CoreParser.pExpr "fence(seq_cst)")
  assertOk "expr neg store" (run CoreParser.pExpr "neg(store('signed int', a_544, conv_loaded_int('signed int', a_552)))")
  assertOk "expr store mo" (run CoreParser.pExpr "store('signed int', x, y, seq_cst)")
  assertOk "expr load mo" (run CoreParser.pExpr "load('signed int', x, relaxed)")

  -- Seq_rmw (from real output)
  assertOk "expr seq_rmw" (run CoreParser.pExpr "seq_rmw('signed int', a_553, a_554 => case a_554 of | Specified(a_555 : integer) => Specified(conv_int('signed int', catch_exceptional_condition_add('signed int', conv_int('signed int', a_555), 1))) | Unspecified(_ : ctype) => Unspecified('signed int') end)")

  -- bound
  assertOk "expr bound pure" (run CoreParser.pExpr "bound(pure(Specified(42)))")
  assertOk "expr bound let" (run CoreParser.pExpr "bound(let weak a_508 : pointer = pure(x) in load('signed int', a_508))")

  -- unseq
  assertOk "expr unseq" (run CoreParser.pExpr "unseq(pure(Specified(1)), pure(Specified(2)))")

  -- nd
  assertOk "expr nd" (run CoreParser.pExpr "nd(pure(True), pure(False))")

  -- pcall
  assertOk "expr pcall" (run CoreParser.pExpr "pcall(f)")
  assertOk "expr pcall args" (run CoreParser.pExpr "pcall(f, x, y)")

  -- ccall
  assertOk "expr ccall" (run CoreParser.pExpr "ccall('signed int', f)")
  assertOk "expr ccall args" (run CoreParser.pExpr "ccall('signed int', f, x, y)")

  -- memop
  assertOk "expr memop PtrEq" (run CoreParser.pExpr "memop(PtrEq, x, y)")
  assertOk "expr memop IntFromPtr" (run CoreParser.pExpr "memop(IntFromPtr, x, y)")

def testExprCompound : TestM Unit := do
  IO.println "=== Expr compound ==="

  -- let
  assertOk "expr let" (run CoreParser.pExpr "let x : integer = 42 in pure(x)")
  assertOk "expr let strong" (run CoreParser.pExpr "let strong a_506 : loaded integer = bound(pure(Specified(42))) in pure(a_506)")
  assertOk "expr let weak" (run CoreParser.pExpr "let weak a_508 : pointer = pure(x) in load('signed int', a_508)")
  -- Let with pattern starting with 's' (was buggy before peek-guard removal)
  assertOk "expr let strong s" (run CoreParser.pExpr "let s : pointer = pure(x) in pure(s)")
  assertOk "expr let strong w" (run CoreParser.pExpr "let w : pointer = pure(x) in pure(w)")
  -- Let weak with tuple pattern
  assertOk "expr let weak tuple" (run CoreParser.pExpr "let weak (a_506 : loaded integer, a_507 : loaded integer) = unseq(pure(Specified(1)), pure(Specified(2))) in pure(a_506)")

  -- Semicolon sequencing
  assertOk "expr seq" (run CoreParser.pExpr "pure(Unit) ; pure(Unit)")
  assertOk "expr seq 3" (run CoreParser.pExpr "pure(Unit) ; pure(Unit) ; pure(Unit)")
  assertOk "expr store seq" (run CoreParser.pExpr "store('signed int', x, y) ; pure(Unit)")

  -- if
  assertOk "expr if" (run CoreParser.pExpr "if a_506 then pure(x) else pure(y)")

  -- case
  assertOk "expr case" (run CoreParser.pExpr "case a_507 of | Specified(a_508 : integer) => pure(if not(a_508 = 1) then True else False) | Unspecified(_ : ctype) => nd(pure(True), pure(False)) end")

  -- save/run
  assertOk "expr save run" (run CoreParser.pExpr "save ret_505 : loaded integer (a_507 : loaded integer := Specified(0)) in pure(a_507)")
  assertOk "expr run" (run CoreParser.pExpr "run ret_505(conv_loaded_int('signed int', a_506))")

  -- Combined: run then seq then save (from real output)
  assertOk "expr run;pure;save" (run CoreParser.pExpr "run ret_505(conv_loaded_int('signed int', a_506)) ; pure(Unit) ; save ret_505 : loaded integer (a_507 : loaded integer := Specified(0)) in pure(a_507)")

def testFullPrograms : TestM Unit := do
  IO.println "=== Full programs (from cerberus --pp core) ==="

  -- 001-return-literal.c
  assertSomeDecls "001-return-literal" "proc main (): eff loaded integer :=
  let strong a_506: loaded integer = bound(pure(Specified(42))) in
  run ret_505(conv_loaded_int('signed int', a_506)) ;
  pure(Unit) ;
  save ret_505: loaded integer (a_507: loaded integer:= Specified(0)) in
    pure(a_507)
"

  -- 003-arith-add.c
  assertSomeDecls "003-arith-add" "proc main (): eff loaded integer :=
  let strong a_511: loaded integer =
    bound(
      let weak (a_506: loaded integer, a_507: loaded integer) =
        unseq(pure(Specified(1)), pure(Specified(2))) in
      pure(
        case (a_506, a_507) of
          | (Specified(a_508: integer), Specified(a_509: integer)) =>
              Specified(catch_exceptional_condition_add('signed int', __conv_int__('signed int', a_508), __conv_int__('signed int', a_509)))
          | _: (loaded integer,loaded integer) =>
              undef(<<UB036_exceptional_condition>>)
        end
      )
    ) in
  run ret_505(conv_loaded_int('signed int', a_511)) ;
  pure(Unit) ;
  save ret_505: loaded integer (a_512: loaded integer:= Specified(0)) in
    pure(a_512)
"

  -- 007-local-var.c
  assertSomeDecls "007-local-var" "proc main (): eff loaded integer :=
  let strong x: pointer = create(Ivalignof('signed int'), 'signed int') in
  let strong a_507: loaded integer = bound(pure(Specified(5))) in
  store('signed int', x, conv_loaded_int('signed int', a_507)) ;
  let strong a_509: loaded integer =
    bound(
      let weak a_508: pointer = pure(x) in
      load('signed int', a_508)
    ) in
  kill('signed int', x) ;
  run ret_506(conv_loaded_int('signed int', a_509)) ;
  kill('signed int', x) ;
  pure(Unit) ;
  save ret_506: loaded integer (a_510: loaded integer:= Specified(0)) in
    pure(a_510)
"

  -- 009-if-true.c
  assertSomeDecls "009-if-true" "proc main (): eff loaded integer :=
  let strong a_507: loaded integer =
    bound(
      let weak (a_509: loaded integer, a_510: loaded integer) =
        unseq(pure(Specified(1)), pure(Specified(0))) in
      pure(
        case (a_509, a_510) of
          | (Specified(a_511: integer), Specified(a_512: integer)) =>
              if conv_int('signed int', a_511) = conv_int('signed int', a_512) then
                Specified(1)
              else
                Specified(0)
          | _: (loaded integer,loaded integer) =>
              Unspecified('signed int')
        end
      )
    ) in
  let strong a_506: boolean =
    case a_507 of
      | Specified(a_508: integer) =>
          pure(if not(a_508 = 1) then True else False)
      | Unspecified(_: ctype) =>
          nd(pure(True), pure(False))
    end in
  if a_506 then
    let strong a_514: loaded integer = bound(pure(Specified(10))) in
    run ret_505(conv_loaded_int('signed int', a_514)) ;
    pure(Unit)
  else
    pure(Unit) ;
  let strong a_515: loaded integer = bound(pure(Specified(20))) in
  run ret_505(conv_loaded_int('signed int', a_515)) ;
  pure(Unit) ;
  save ret_505: loaded integer (a_516: loaded integer:= Specified(0)) in
    pure(a_516)
"

def testDeclarations : TestM Unit := do
  IO.println "=== Declarations ==="

  assertCounts "def impl" "def <bits_in_byte> : integer := 8\n" (0, 0, 1, 0, 0, 0)
  assertCounts "fun impl" "fun <Integer.encode> (ty: ctype, n: integer) : integer := error(<<<integerEncode>>>, Unit)\n" (0, 0, 1, 0, 0, 0)
  assertCounts "fun simple" "fun f (n: integer): integer := n\n" (1, 0, 0, 0, 0, 0)
  assertCounts "proc simple" "proc f (): eff integer := pure(42)\n" (0, 1, 0, 0, 0, 0)
  assertCounts "builtin" "builtin __builtin_va_start (pointer, pointer): eff unit\n" (0, 0, 0, 0, 0, 1)
  assertCounts "two decls" "def <bits_in_byte> : integer := 8\nfun <Integer.encode> (ty: ctype, n: integer) : integer := error(<<<integerEncode>>>, Unit)\n" (0, 0, 2, 0, 0, 0)

  -- Proc with ctype argument (the critical test for pPexprValue)
  assertCounts "proc with ctype" "proc f (x: pointer): eff loaded integer := store('signed int', x, Specified(42))\n" (0, 1, 0, 0, 0, 0)

  -- Multiple declarations
  assertCounts "fun+proc" "fun f (n: integer): integer := n\nproc g (): eff integer := pure(42)\n" (1, 1, 0, 0, 0, 0)

  -- <builtin_X> impl tokens strip the prefix (OCaml scan_impl,
  -- core_lexer.mll:209-219): run-time dispatch matches the stripped name
  match CoreParser.pImplConstant "builtin_printf" with
  | .ok (BuiltinFunction "printf") => pass "impl builtin_ prefix stripped"
  | _ => fail_ "impl builtin_ prefix stripped" "unexpected constant"
  match CoreParser.pImplConstant "builtin_generic_ffs" with
  | .ok (BuiltinFunction "generic_ffs") => pass "impl builtin_generic_ffs"
  | _ => fail_ "impl builtin_generic_ffs" "unexpected constant"
  -- named impl-map constants resolve through the GENERATED Implementation.impl_map
  -- (zero-discrepancy Z2-CP-08): the keys are the OCaml lexemes, e.g. `<sizeof>`
  match CoreParser.pImplConstant "sizeof" with
  | .ok Sizeof => pass "impl <sizeof> via impl_map"
  | _ => fail_ "impl <sizeof> via impl_map" "unexpected constant"
  match CoreParser.pImplConstant "Ctype.min" with
  | .ok Ctype_min => pass "impl <Ctype.min> via impl_map"
  | _ => fail_ "impl <Ctype.min> via impl_map" "unexpected constant"
  -- fail-closed: an unknown name is Core_lexer_invalid_implname on the oracle
  -- (core_lexer.mll:209-219) — including the pre-Z2 hand table's `Sizeof` spelling
  match CoreParser.pImplConstant "Sizeof" with
  | .error _ => pass "impl <Sizeof> refused (not an impl_map key)"
  | .ok _ => fail_ "impl <Sizeof> refused" "accepted a non-key"
  match CoreParser.pImplConstant "frobnicate" with
  | .error _ => pass "impl <frobnicate> refused"
  | .ok _ => fail_ "impl <frobnicate> refused" "accepted an unknown name"

  -- [ailname = "..."] attribute capture (OCaml: core_parser.mly:157-159,
  -- :1037-1041 — attribute string ↦ proc symbol, procs only)
  assertEq "ailname captured"
    (parseAilnames "proc [ailname = \"malloc\"] malloc_proxy (): eff integer := pure(42)\n")
    [("malloc", "malloc_proxy")]
  -- std.core:398 spacing variant `ailname= "..."`
  assertEq "ailname tight spacing"
    (parseAilnames "proc [ailname= \"memcpy\"] memcpy_proxy (): eff integer := pure(42)\n")
    [("memcpy", "memcpy_proxy")]
  -- plain proc registers nothing
  assertEq "no ailname, no entry"
    (parseAilnames "proc f (): eff integer := pure(42)\n") []
  -- builtin declarations never register ailnames (core_parser.mly:1020-1026
  -- adds only a BuiltinDecl fun_map entry); fun declarations neither
  assertEq "builtin/fun register no ailname"
    (parseAilnames ("builtin printf ([integer], [(ctype, pointer)]): eff loaded integer\n" ++
      "fun f (n: integer): integer := n\n" ++
      "proc [ailname = \"__builtin_ffs\"] ffs_proxy (): eff integer := pure(42)\n"))
    [("__builtin_ffs", "ffs_proxy")]

/-! ## Arc-6 S1: libc dump grammar (each production cited at its
    implementation site in CoreParser.lean) -/

def testLibcProductions : TestM Unit := do
  IO.println "=== libc dump productions (arc-6 S1) ==="

  -- Bodyless ProcDecl (pp_core.ml:783-785; pp-only form, no mly production)
  assertCounts "procdecl bodyless" "proc __builtin_exit (pointer)\n" (0, 1, 0, 0, 0, 0)
  assertCounts "procdecl multi" "proc __builtin_vsnprintf (pointer, pointer, pointer, pointer)\n" (0, 1, 0, 0, 0, 0)
  match CoreParser.parseFile "proc __builtin_exit (pointer)\n" with
  | .ok cf =>
    match cf.procs with
    | [(_, ProcDecl _ _ [BTy_object OTy_pointer])] => pass "procdecl AST is ProcDecl"
    | _ => fail_ "procdecl AST is ProcDecl" "unexpected shape"
  | .error e => fail_ "procdecl AST is ProcDecl" e
  -- a zero-arg FULL proc must still parse as Proc (colon lookahead)
  match CoreParser.parseFile "proc tmpfile (): eff loaded pointer := pure(Specified(NULL(void*)))\n" with
  | .ok cf =>
    match cf.procs with
    | [(_, Proc _ _ _ _ _)] => pass "zero-arg full proc still Proc"
    | _ => fail_ "zero-arg full proc still Proc" "unexpected shape"
  | .error e => fail_ "zero-arg full proc still Proc" e

  -- Z2-CP-13 (pre-merge audit F7): an anonymous tag in OTy position (`a_N`, the
  -- pp's `to_string` spelling) interns to the file's declared
  -- `__cerbty_unnamed_tag_N`; a NAMED tag `a` printed `a_5` must NOT be captured
  -- by a declared anonymous tag 50 (exact-token match, not substring)
  match CoreParser.parseFile ("def struct __cerbty_unnamed_tag_50 :=\n  x: 'signed int'\n\n" ++
      "def struct a :=\n  y: 'signed int'\n\n" ++
      "proc f (p: pointer): eff loaded integer :=\n" ++
      "  let strong v: loaded struct a_5 = load('struct a', p) in\n" ++
      "  let strong w: loaded struct a_50 = load('struct __cerbty_unnamed_tag_50', p) in\n" ++
      "  pure(Specified(0))\n") with
  | .ok cf =>
    match cf.procs with
    | [(_, Proc _ _ _ _ (Expr _ (Esseq (Pattern _ (CaseBase (_, BTy_loaded (OTy_struct s1)))) _
          (Expr _ (Esseq (Pattern _ (CaseBase (_, BTy_loaded (OTy_struct s2)))) _ _)))))] =>
      if s1 == CoreParser.internSym "a" then pass "CP-13 named tag a_5 → a (tag 50 coexists)"
      else fail_ "CP-13 named tag a_5 → a (tag 50 coexists)" "a_5 captured by the anonymous tag"
      if s2 == CoreParser.internSym "__cerbty_unnamed_tag_50" then pass "CP-13 anonymous a_50 → __cerbty_unnamed_tag_50"
      else fail_ "CP-13 anonymous a_50 → __cerbty_unnamed_tag_50" "not resolved to the declared tag"
    | _ => fail_ "CP-13 tags 5/50" "unexpected AST shape"
  | .error e => fail_ "CP-13 tags 5/50" e
  -- an invalid impl-constant declaration is a lexer error on the oracle
  -- (scan_impl, core_lexer.mll:218) — refused at the declaration here too (audit F2)
  assertErr "impl decl <bogus> refused" (CoreParser.parseFile "def <bogus>: integer := 0\n")
  assertOk "impl decl <sizeof> accepted" (CoreParser.parseFile "def <sizeof>: integer := 0\n")

  -- glob with function-pointer-array ail_ctype (the sighandler/funcs globs)
  assertCounts "glob fn-ptr array ail_ctype"
    "glob sighandler: pointer [ail_ctype = 'void (signed int)*[8]'] := pure(Unit)\n" (0, 0, 0, 0, 1, 0)
  assertCounts "glob empty-params fn ail_ctype"
    "glob funcs: pointer [ail_ctype = 'void ()*[32]'] := pure(Unit)\n" (0, 0, 0, 0, 1, 0)

  -- AIL-dialect ctype literals (Pp_ail.pp_ctype, pp_core.ml:332):
  -- space spellings, post-star qualifiers, (*)/(*[N]) declarators, `...`
  let pexprOf (cf : CoreParser.CoreFile) : Option (generic_pexpr Unit sym) :=
    match cf.procs with
    | [(_, Proc _ _ _ _ (Expr _ (Epure pe)))] => some pe
    | _ => none
  let parseCtypeVal (name lit : String) (check : ctype → Bool) : TestM Unit :=
    match CoreParser.parseFile s!"proc f (): eff ctype := pure({lit})\n" with
    | .ok cf =>
      match pexprOf cf with
      | some (Pexpr _ _ (PEval (Vctype ty))) =>
        if check ty then pass name else fail_ name "ctype AST shape mismatch"
      | _ => fail_ name "not a Vctype pexpr"
    | .error e => fail_ name e
  parseCtypeVal "space long long" "'signed long long'"
    (fun ty => match ty with
      | Ctype _ (Basic (Integer (Signed LongLong))) => true | _ => false)
  parseCtypeVal "space long double" "'long double'"
    (fun ty => match ty with
      | Ctype _ (Basic (Floating (RealFloating LongDouble))) => true | _ => false)
  -- restrict lands in the parameter TRIPLE of the function type
  -- (pp_ail.ml Pointer case prints star ^^ pp_qualifiers of the
  -- parameter's qualifiers), `...` sets the variadic flag, and the
  -- pointee `const` lands in Pointer's own qualifiers
  parseCtypeVal "fn-ptr restrict + variadic"
    "'signed int (*) (const char*restrict , ...)'"
    (fun ty => match ty with
      | Ctype _ (Pointer _ (Ctype _ (Function _ [(qs, Ctype _ (Pointer pqs (Ctype _ (Basic (Integer Char0)))), _)] true))) =>
        qs.restrict && !qs.const && pqs.const
      | _ => false)
  -- (void) is an EMPTY prototype (pp_ail.ml:268-270)
  parseCtypeVal "(void) empty prototype" "'void (*) (void)'"
    (fun ty => match ty with
      | Ctype _ (Pointer _ (Ctype _ (Function _ [] false))) => true | _ => false)
  -- (*[N]): array of function pointers
  parseCtypeVal "(*[32]) array of fn ptrs" "'void (*[32]) (void)'"
    (fun ty => match ty with
      | Ctype _ (Array0 (Ctype _ (Pointer _ (Ctype _ (Function _ [] false)))) (some 32)) => true
      | _ => false)
  -- char*const *: pointer to const-qualified pointer to char
  parseCtypeVal "char*const *" "'char*const *'"
    (fun ty => match ty with
      | Ctype _ (Pointer qs (Ctype _ (Pointer _ (Ctype _ (Basic (Integer Char0)))))) => qs.const
      | _ => false)
  -- CORE-dialect empty parens = Function [] (prototyped; see the
  -- pp_core_ctype ambiguity note in CoreParser)
  match CoreParser.parseFile "proc f (x: pointer): eff unit := kill('void ()*', x)\n" with
  | .ok _ => pass "CORE-dialect 'void ()*'"
  | .error e => fail_ "CORE-dialect 'void ()*'" e

  -- OTy_struct raw-symbol suffix strip (Pp_symbol.to_string,
  -- pp_symbol.ml:5-10 via pp_core.ml:186-189): `struct fl_331` interns
  -- to the same tag symbol as ctype-position `struct fl`
  match CoreParser.parseFile
      "proc f (): eff loaded struct fl_331 := pure(Specified(Ivsizeof('struct fl')))\n" with
  | .ok cf =>
    match cf.procs with
    | [(_, Proc _ _ (BTy_loaded (OTy_struct tagSym)) _ _)] =>
      if tagSym == CoreParser.internSym "fl" then pass "OTy strip _<num> suffix"
      else fail_ "OTy strip _<num> suffix" "tag symbol differs from interned 'fl'"
    | _ => fail_ "OTy strip _<num> suffix" "unexpected shape"
  | .error e => fail_ "OTy strip _<num> suffix" e

  -- Cfunction(sym) is a real function pointer value (impl_mem.ml:567-568),
  -- not the old null punt
  match CoreParser.parseFile "proc f (): eff loaded pointer := pure(Specified(Cfunction(exit_proxy)))\n" with
  | .ok cf =>
    match pexprOf cf with
    | some (Pexpr _ _ (PEctor Cspecified [Pexpr _ _ (PEval (Vobject (OVpointer pv)))])) =>
      -- PVfunction carries the interned sym
      match pv with
      | .PV _ (.PVfunction s) =>
        if s == CoreParser.internSym "exit_proxy" then pass "Cfunction → PVfunction"
        else fail_ "Cfunction → PVfunction" "wrong symbol"
      | _ => fail_ "Cfunction → PVfunction" "not a PVfunction"
    | _ => fail_ "Cfunction → PVfunction" "unexpected pexpr shape"
  | .error e => fail_ "Cfunction → PVfunction" e

  -- unannotated Vlist literal (pp_core.ml:327-329 — no `: type` suffix)
  assertCounts "unannotated list literal"
    "proc f (x: pointer): eff unit := ccall('void (*) (signed int, ...)', x, x, [('signed int', x)])\n"
    (0, 1, 0, 0, 0, 0)

  -- error("...", pe): dquoted string form (pp_core.ml:444-445 / mly:1572)
  assertCounts "error dquoted"
    "fun f (): unit := error(\"assert() failure\", Unit)\n" (1, 0, 0, 0, 0, 0)

  -- PEif reparse ambiguity (see CoreParser's note): binop-RHS if is
  -- operand-bounded, so `a = if …` keeps the comparison at the top
  match CoreParser.parseFile
      ("fun f (a: integer, b: integer): integer :=\n" ++
       "  if conv_int('signed int', a) = if all_values_representable_in('size_t', 'signed int') then conv_int('signed int', b) else conv_int('unsigned int', b) then 1 else 0\n") with
  | .ok cf =>
    match cf.funs with
    | [(_, Fun _ _ (Pexpr _ _ (PEif (Pexpr _ _ (PEop OpEq _ (Pexpr _ _ (PEif _ _ _)))) _ _)))] =>
      pass "bounded if as binop RHS"
    | _ => fail_ "bounded if as binop RHS" "unexpected AST shape"
  | .error e => fail_ "bounded if as binop RHS" e
  -- …and hand-written-style greedy branches still work (std.core:143)
  match CoreParser.parseFile
      "fun f (n: integer, width: integer): integer := if n = 0 then n else 2^width + n\n" with
  | .ok cf =>
    match cf.funs with
    | [(_, Fun _ _ (Pexpr _ _ (PEif _ _ (Pexpr _ _ (PEop OpAdd _ _)))))] =>
      pass "greedy else keeps binop branch"
    | _ => fail_ "greedy else keeps binop branch" "unexpected AST shape"
  | .error e => fail_ "greedy else keeps binop branch" e

  -- layout-sensitive `;` (see CoreParser's pExprSeq note): an outdented
  -- sequel after an if belongs to the enclosing sequence, not the else
  match CoreParser.parseFile
      ("proc f (x: pointer): eff loaded integer :=\n" ++
       "  if True then\n" ++
       "    kill('signed int', x) ;\n" ++
       "    run ret_1(Specified(0))\n" ++
       "  else\n" ++
       "    pure(Unit) ;\n" ++
       "  pure(Specified(1))\n") with
  | .ok cf =>
    match cf.procs with
    | [(_, Proc _ _ _ _ (Expr _ (Esseq _ (Expr _ (Eif _ _ (Expr _ (Epure _)))) _)))] =>
      pass "outdented ;-sequel attaches to sequence"
    | _ => fail_ "outdented ;-sequel attaches to sequence" "unexpected AST shape"
  | .error e => fail_ "outdented ;-sequel attaches to sequence" e
  -- …while an INDENTED sequel stays inside the branch
  match CoreParser.parseFile
      ("proc f (x: pointer): eff unit :=\n" ++
       "  if True then\n" ++
       "    pure(Unit)\n" ++
       "  else\n" ++
       "    kill('signed int', x) ;\n" ++
       "    pure(Unit)\n") with
  | .ok cf =>
    match cf.procs with
    | [(_, Proc _ _ _ _ (Expr _ (Eif _ _ (Expr _ (Esseq _ _ _)))))] =>
      pass "indented ;-sequel stays in branch"
    | _ => fail_ "indented ;-sequel stays in branch" "unexpected AST shape"
  | .error e => fail_ "indented ;-sequel stays in branch" e

def testFiles : TestM Unit := do
  IO.println "=== Runtime files ==="

  -- Test actual file from disk
  let implPath := "../runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"
  let fileExists ← System.FilePath.pathExists implPath
  if fileExists then
    let content ← IO.FS.readFile implPath
    -- Test incrementally
    let lines := content.splitOn "\n"
    let first5 := String.intercalate "\n" (lines.take 5)
    assertOk "impl first5" (CoreParser.parseFileSummary first5)
    let first15 := String.intercalate "\n" (lines.take 15)
    assertOk "impl first15" (CoreParser.parseFileSummary first15)
    let first28 := String.intercalate "\n" (lines.take 28)
    assertOk "impl first28" (CoreParser.parseFileSummary first28)
    let first50 := String.intercalate "\n" (lines.take 50)
    assertOk "impl first50" (CoreParser.parseFileSummary first50)
    assertOk "impl full" (CoreParser.parseFileSummary content)
    -- Test all runtime .core/.impl files
    let files := [
      ("std.core", "../runtime/libcore/std.core"),
      ("std_inner_arg_temps.core", "../runtime/libcore/std_inner_arg_temps.core"),
      ("gcc x86_64 impl", "../runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl"),
      -- i686 impl uses old incompatible syntax (Cerberus bug): "def bits_in_byte = 8" vs "def <bits_in_byte> : integer := 8"
      -- ("gcc i686 impl", "../runtime/libcore/impls/i686-apple-darwin10-gcc-4.2.1.impl")
    ]
    for (name, path) in files do
      let fileExists ← System.FilePath.pathExists path
      if fileExists then
        let content ← IO.FS.readFile path
        assertOk name (CoreParser.parseFileSummary content)
      else
        IO.println s!"  (skipping {name} — not found)"
    -- std.core ailname surface: 46 attribute-tagged proxies (grep-verified),
    -- keyed by C name, mapped to the proxy symbol — incl. printf ↦
    -- printf_proxy (std.core:289), NOT the `builtin printf` decl (:283)
    let stdPath := "../runtime/libcore/std.core"
    if ← System.FilePath.pathExists stdPath then
      let stdContent ← IO.FS.readFile stdPath
      match parseAilnames stdContent with
      | .ok pairs =>
        if pairs.length == 46 then pass "std.core ailnames count 46"
        else fail_ "std.core ailnames count 46" s!"got {pairs.length}"
        for (c, p) in [("malloc", "malloc_proxy"), ("printf", "printf_proxy"),
                       ("__builtin_errno", "errno_proxy"), ("memcpy", "memcpy_proxy")] do
          if pairs.contains (c, p) then pass s!"std.core ailname {c} ↦ {p}"
          else fail_ s!"std.core ailname {c} ↦ {p}" s!"missing (have: {pairs.lookup c})"
      | .error e => fail_ "std.core ailnames" e
  else
    IO.println "  (skipping file tests — runtime not found)"

  -- Arc-6 S1 parse bar: the ENTIRE pinned libc dump parses, with the
  -- exact declaration census (191 proc — 188 unique names + the
  -- __procfdname duplicate and the __strtox/__strtoxd decl+def pairs —
  -- 68 globs, 1 surviving tagDef `fl`; see scripts/libc_prep.sh).
  let libcPath := "../tests/libc/libc.core"
  if ← System.FilePath.pathExists libcPath then
    let content ← IO.FS.readFile libcPath
    match CoreParser.parseFile content with
    | .ok cf =>
      if cf.procs.length == 191 then pass "libc.core 191 procs"
      else fail_ "libc.core 191 procs" s!"got {cf.procs.length}"
      if cf.globs.length == 68 then pass "libc.core 68 globs"
      else fail_ "libc.core 68 globs" s!"got {cf.globs.length}"
      if cf.tagDefs.length == 1 then pass "libc.core 1 tagDef (fl)"
      else fail_ "libc.core 1 tagDef (fl)" s!"got {cf.tagDefs.length}"
      if cf.funs.length == 0 && cf.builtins.length == 0 && cf.impls.length == 0 then
        pass "libc.core no fun/builtin/impl decls"
      else fail_ "libc.core no fun/builtin/impl decls" "unexpected extra decls"
      -- symbol-invariant re-verification (arc-5 note; charter risk item):
      -- every top-level libc symbol id must stay ≥ 2^20 (above the
      -- desugar-threaded id band) and the name-hash interning must be
      -- collision-free across libc ∪ std.core top-level names
      let stdPath := "../runtime/libcore/std.core"
      let stdNames ← do
        if ← System.FilePath.pathExists stdPath then
          match CoreParser.parseFile (← IO.FS.readFile stdPath) with
          | .ok scf => pure ((scf.funs ++ scf.procs ++ scf.builtins).map (·.1))
          | .error _ => pure []
        else pure []
      let allSyms := (cf.procs.map (·.1)) ++ (cf.globs.map (·.1)) ++ stdNames
      let mut belowFloor := 0
      let mut collisions := 0
      let mut seen : List (Nat × String) := []
      for s in allSyms do
        match s with
        | Symbol _ n (SD_Id name) =>
          if n < (1 <<< 20) then belowFloor := belowFloor + 1
          match seen.find? (fun p => p.1 == n) with
          | some (_, other) =>
            if other != name then collisions := collisions + 1
          | none => seen := (n, name) :: seen
        | _ => pure ()
      if belowFloor == 0 then pass "libc∪std sym ids ≥ 2^20 (arc-5 invariant)"
      else fail_ "libc∪std sym ids ≥ 2^20 (arc-5 invariant)" s!"{belowFloor} below floor"
      if collisions == 0 then pass "libc∪std name-hash collision-free"
      else fail_ "libc∪std name-hash collision-free" s!"{collisions} collisions"
      -- the strip-rule precondition: no top-level name ends in _<digits>
      -- that would alias another name after stripping (OTy positions)
      let stripped := fun (s : String) =>
        let cs := s.toList.reverse
        let ds := cs.takeWhile (·.isDigit)
        if ds.isEmpty then none
        else match cs.drop ds.length with
          | '_' :: rest => if rest.isEmpty then none else some (String.ofList rest.reverse)
          | _ => none
      let names := allSyms.filterMap (fun s => match s with
        | Symbol _ _ (SD_Id n) => some n | _ => none)
      let aliased := names.filter (fun n => (stripped n).isSome &&
        names.contains ((stripped n).getD ""))
      if aliased.isEmpty then pass "no top-level name aliases under _<num> strip"
      else fail_ "no top-level name aliases under _<num> strip" s!"{aliased}"
    | .error e => fail_ "libc.core parses" e
  else
    IO.println "  (skipping libc.core tests — pin not found)"

end CoreParserTest

def runTests : CoreParserTest.TestM Unit := do
  CoreParserTest.testLexer
  CoreParserTest.testTypes
  CoreParserTest.testValues
  CoreParserTest.testPatterns
  CoreParserTest.testPexprAtoms
  CoreParserTest.testPexprConstructors
  CoreParserTest.testPexprExpressions
  CoreParserTest.testExprAtoms
  CoreParserTest.testExprCompound
  CoreParserTest.testFullPrograms
  CoreParserTest.testDeclarations
  CoreParserTest.testLibcProductions
  CoreParserTest.testFiles

def main : IO Unit := do
  IO.println "CoreParser unit tests"
  IO.println ""
  let ((), state) ← StateRefT'.run runTests {}
  IO.println ""
  IO.println s!"Done: {state.passed} passed, {state.failed} failed"
  if state.failed > 0 then
    IO.Process.exit 1
