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
  assertEq "string escape" (run CoreParser.lexStr "\"a\\nb\"") "a\nb"

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
  else
    IO.println "  (skipping file tests — runtime not found)"

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
  CoreParserTest.testFiles

def main : IO Unit := do
  IO.println "CoreParser unit tests"
  IO.println ""
  let ((), state) ← StateRefT'.run runTests {}
  IO.println ""
  IO.println s!"Done: {state.passed} passed, {state.failed} failed"
  if state.failed > 0 then
    IO.Process.exit 1
