/-
  Core text parser for Cerberus .core and .impl files.
  Uses Lean's Std.Internal.Parsec.String combinator library.

  Parses the Core IR text format as defined by parsers/core/core_parser.mly.
-/

import Std.Internal.Parsec
import Std.Internal.Parsec.String
import Std.Data.HashMap
import Core
import Ctype

set_option autoImplicit true

namespace CoreParser

abbrev P := Std.Internal.Parsec.String.Parser

open Std.Internal.Parsec Std.Internal.Parsec.String

/-! ## Lexer -/

section Lexer

private def isIdentStart (c : Char) : Bool := c.isAlpha || c == '_'
private def isIdentCont (c : Char) : Bool :=
  c.isAlpha || c.isDigit || c == '_'

/-- Skip line comment (-- to end of line) -/
partial def skipLineComment : P Unit := do
  match ← peek? with
  | some '\n' | none => return
  | _ => skip; skipLineComment

/-- Skip block comment ({- ... -}), no nesting (matches OCaml lexer) -/
partial def skipBlockComment : P Unit := do
  match ← peek? with
  | none => fail "unterminated block comment"
  | some '-' => skip; match ← peek? with
    | some '}' => skip
    | _ => skipBlockComment
  | _ => skip; skipBlockComment

/-- Skip whitespace and comments -/
partial def lexWs : P Unit := do
  ws
  -- Try to consume a line comment (--)
  let commentFound ← attempt (do
    skipChar '-'; skipChar '-'; skipLineComment; pure true) <|> pure false
  if commentFound then lexWs; return
  -- Try to consume a block comment ({- ... -})
  let blockFound ← attempt (do
    skipChar '{'; skipChar '-'; skipBlockComment; pure true) <|> pure false
  if blockFound then lexWs; return

/-- Is c in [a-zA-Z_]? Uses explicit ranges to avoid compiler char-class interference. -/
@[noinline] private def isIdentStartChar (c : Char) : Bool :=
  (c.val ≥ 97 && c.val ≤ 122) || (c.val ≥ 65 && c.val ≤ 90) || c.val == 95

/-- Is c in [a-zA-Z0-9_]? Uses explicit ranges. -/
@[noinline] private def isIdentContChar (c : Char) : Bool :=
  (c.val ≥ 97 && c.val ≤ 122) || (c.val ≥ 65 && c.val ≤ 90) ||
  (c.val ≥ 48 && c.val ≤ 57) || c.val == 95

/-- Parse an identifier: [a-zA-Z_][a-zA-Z0-9_]* -/
def lexIdent : P String := do
  let c ← satisfy isIdentStartChar
  let rest ← manyChars (satisfy isIdentContChar)
  let name := String.singleton c ++ rest
  lexWs
  return name

/-- Parse a keyword (identifier that must match exactly) -/
def lexKw (s : String) : P Unit := do
  let id ← attempt lexIdent
  if id != s then fail s!"expected '{s}', got '{id}'"

/-- Parse a symbol/punctuation and skip trailing whitespace -/
def lexSym (s : String) : P Unit := do
  let _ ← pstring s
  lexWs

/-- Result of parsing a numeric literal: either integer or floating-point. -/
inductive NumLit where
  | int : Int → NumLit
  | float : Float → NumLit

/-- Parse a numeric literal (integer or float).
    Integer: [0-9]+
    Float: [0-9]+.[0-9]* or [0-9]+[eE][+-]?[0-9]+ or [0-9]+.[0-9]*[eE][+-]?[0-9]+
    Matches what OCaml's string_of_float produces: 0., 3.14, 1e-06, 1e+308, etc. -/
partial def lexNumLit : P NumLit := do
  let neg ← match ← peek? with
    | some '-' => skip; pure true
    | _ => pure false
  let intPart ← many1Chars digit
  -- Check for fractional part or exponent (makes it a float)
  let mut isFloat := false
  let mut acc := intPart
  match ← peek? with
  | some '.' =>
    skip; isFloat := true
    let fracPart ← manyChars digit
    acc := acc ++ "." ++ fracPart
  | _ => pure ()
  match ← peek? with
  | some 'e' | some 'E' =>
    skip; isFloat := true
    let sign ← match ← peek? with
      | some '+' => skip; pure "+"
      | some '-' => skip; pure "-"
      | _ => pure ""
    let expPart ← manyChars digit
    acc := acc ++ "e" ++ sign ++ expPart
  | _ => pure ()
  lexWs
  if isFloat then
    let s := if neg then "-" ++ acc else acc
    return .float (CerbFloat.of_string s)
  else
    let n := intPart.foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0
    return .int (if neg then -↑n else ↑n)

/-- Parse an integer literal. Fails on float literals. -/
def lexInt : P Int := do
  match ← lexNumLit with
  | .int n => return n
  | .float _ => fail "expected integer, got float"

/-- Helper for lexStr: parse string body after opening quote -/
private partial def lexStrGo (acc : String) : P String := do
  let c ← any
  if c == '"' then lexWs; return acc
  else if c == '\\' then
    let c2 ← any
    let esc := match c2 with
      | 'n' => '\n' | 't' => '\t' | '\\' => '\\' | '"' => '"' | c => c
    lexStrGo (acc.push esc)
  else lexStrGo (acc.push c)

/-- Parse a double-quoted string -/
partial def lexStr : P String := do
  skipChar '"'
  lexStrGo ""

/-- Parse a triple-angle-bracket string <<<name>>> -/
def lexTripleAngle : P String := do
  lexSym "<<<"
  let name ← manyChars (satisfy (· != '>'))
  lexSym ">>>"
  return name

/-- Parse an angle-bracket string <<name>> -/
def lexDoubleAngle : P String := do
  lexSym "<<"
  let name ← manyChars (satisfy (· != '>'))
  lexSym ">>"
  return name

/-- Parse an impl constant <name> -/
def lexImpl : P String := do
  skipChar '<'
  let name ← manyChars (satisfy (· != '>'))
  skipChar '>'
  lexWs
  return name

end Lexer

/-! ## Helper utilities -/

/-- Column (0-based, in characters) of raw position `p` within `s`
    (layout-sensitive `;` sequencing — see the note above pExprSeq). -/
private partial def colOfAux (s : String) (p : _root_.String.Pos.Raw) (n : Nat) : Nat :=
  if p.byteIdx == 0 then n
  else
    let p' := s.prev p
    if s.get p' == '\n' then n else colOfAux s p' (n + 1)

/-- Current column (whitespace/comments already consumed by the previous
    token's trailing lexWs, so this is the next token's column). The
    parser state is `Sigma String.Pos` (Std.Internal.Parsec.String). -/
private def getCol : P Nat := fun it =>
  .success it (colOfAux it.1 it.2.offset 0)

/-- Construct a symbol from a parsed identifier string.
    Uses the string's hash as the number so distinct names get distinct
    IDs (symbol equality ignores the description — see symbolEqual in
    symbol.lem).  This sidesteps Lean's CSE of pure `Unit → Nat` calls. -/
private def mkSym (name : String) : sym :=
  Symbol "" name.hash.toNat (SD_Id name)

/-- Public name-interning entry: the symbol a given name parses to
    anywhere in a CoreParser-parsed file. Used by the libc loader
    (Main.loadLibc, arc-6 S1) to rekey oracle-side metadata onto the
    symbols the parsed libc bodies reference. -/
def internSym (name : String) : sym := mkSym name

/-- The unknown location placeholder. -/
private def loc0 : CerbLocation.Loc := CerbLocation.unknown

/-- Default annotation list with unknown location. -/
private def annots0 : List annot := [Aloc loc0]

/-- Parse an identifier into a `sym`. -/
private def lexSymId : P sym := do
  let name ← lexIdent
  -- TRIPWIRE (zero-discrepancy Z2-CP-01): in atom position `inf`/`nan` are
  -- the pp's spellings of the IEEE infinities/NaN (pPexprAtom below), so a
  -- BINDER or declared name spelled that way would be silently shadowed
  -- by a float value — refuse the parse instead.
  if name == "inf" || name == "nan" then
    fail s!"CoreParser: the name `{name}` is reserved — the pretty-printer renders the float infinities/NaN as this identifier (pp_core.ml:279-282 string_of_float; zero-discrepancy Z2-CP-01)"
  return mkSym name

/-- Parse a comma-separated list using the given element parser. -/
private partial def sepByComma (p : P α) : P (List α) := do
  match ← attempt (some <$> p) <|> pure none with
  | none => return []
  | some first =>
    let mut acc := [first]
    while true do
      match ← attempt (some <$> (do lexSym ","; p)) <|> pure none with
      | some x => acc := acc ++ [x]
      | none => break
    return acc

/-- Parse a non-empty comma-separated list using the given element parser. -/
private partial def sepByComma1 (p : P α) : P (List α) := do
  let first ← p
  let mut acc := [first]
  while true do
    match ← attempt (some <$> (do lexSym ","; p)) <|> pure none with
    | some x => acc := acc ++ [x]
    | none => break
  return acc

/-- Extract inner type from BTy_list. -/
private def ensureListBTy : core_base_type → core_base_type
  | BTy_list bTy => bTy
  | bTy => bTy  -- fallback: just use it as-is

/-- Build a list pattern from a list of patterns. -/
private def mkListPat (bTy : core_base_type) : List (generic_pattern sym) → generic_pattern sym
  | [] => Pattern [] (CaseCtor (Cnil bTy) [])
  | p :: ps => Pattern [] (CaseCtor Ccons [p, mkListPat bTy ps])

/-- Map an impl constant name string to implementation_constant. -/
def pImplConstant (s : String) : implementation_constant :=
  if s == "Sizeof" then Sizeof
  else if s == "Alignof" then Alignof
  else if s == "Ctype_min" then Ctype_min
  else if s == "Ctype_max" then Ctype_max
  else if s == "SHR_signed_negative" then SHR_signed_negative
  else if s == "Bitwise_complement" then Bitwise_complement
  -- Double-underscore format (legacy)
  else if s == "Integer__encode" then Integer__encode
  else if s == "Integer__decode" then Integer__decode
  else if s == "Integer__conv_nonrepresentable_signed_integer" then
    Integer__conv_nonrepresentable_signed_integer
  else if s == "Characters__bits_in_byte" then Characters__bits_in_byte
  else if s == "Characters__plain_char_is_signed" then Characters__plain_char_is_signed
  -- Dot format (actual file format)
  else if s == "Integer.encode" then Integer__encode
  else if s == "Integer.decode" then Integer__decode
  else if s == "Integer.conv_nonrepresentable_signed_integer" then
    Integer__conv_nonrepresentable_signed_integer
  else if s == "bits_in_byte" then Characters__bits_in_byte
  else if s == "plain_char_is_signed" then Characters__plain_char_is_signed
  else if s == "Plain_bitfield_sign" then Plain_bitfield_sign
  -- OCaml scan_impl (parsers/core/core_lexer.mll:209-219): names not in
  -- Implementation.impl_map must carry a `builtin_` prefix, which is
  -- STRIPPED (`remove_prefix ~prefix:"<builtin_"`) — `<builtin_printf>`
  -- lexes to `Impl (BuiltinFunction "printf")`. The run-time dispatchers
  -- match the STRIPPED name (core_reduction.lem:963-1084 "errno"/
  -- "generic_ffs"/..., core_reduction_aux.lem:8-42 is_fs_function
  -- "printf"/...); an unstripped "builtin_printf" matches nothing and
  -- falls into the process_impl_proc catch-all error.
  --
  -- PRECISE DIVERGENCE SCOPE (arc-5 audit 1, F3): the final fallback
  -- below FAILS OPEN — any unknown non-builtin name parses as
  -- `BuiltinFunction s`, where OCaml's scan_impl RAISES
  -- (Core_lexer_invalid_implname, core_lexer.mll:209-219). Moreover the
  -- OCaml impl_map keys beyond the ones matched above — `<sizeof>`,
  -- `<alignof>`, `<Ctype.min>`/`<Ctype.max>`, the dotted
  -- `<Characters.*>` forms, `<Environment.*>`, `<Bitfield_other_types>`,
  -- `<Atomic_bitfield_permitted>` (implementation.lem:306-337) — hit
  -- that fallback and parse to the WRONG constructor. All confirmed
  -- unreachable from the shipped std.core + gcc impl by exhaustive
  -- enumeration of the `<...>` tokens they contain (arc-5 audit 1).
  else if s.startsWith "builtin_" then
    BuiltinFunction (s.drop "builtin_".length).toString
  else BuiltinFunction s

/-- Helper for strContains: check substring match -/
private def strContainsGo : List Char → List Char → Nat → Bool
  | [], _, _ => false
  | hs, n, nLen =>
    if hs.length < nLen then false
    else if hs.take nLen == n then true
    else match hs with
      | [] => false
      | _ :: rest => strContainsGo rest n nLen

/-- Check if needle appears as a substring of haystack. -/
private def strContains (haystack needle : String) : Bool :=
  let h := haystack.toList
  let n := needle.toList
  let nLen := n.length
  h.length >= nLen && strContainsGo h n nLen

/-- Helper: parse iop from wrapI/catch token suffix. -/
private def pIopFromStr (s : String) : iop :=
  if strContains s "_add" then IOpAdd
  else if strContains s "_sub" then IOpSub
  else if strContains s "_mul" then IOpMul
  else if strContains s "_shl" then IOpShl
  else if strContains s "_shr" then IOpShr
  else IOpAdd

-- Type abbreviations for readability
private abbrev PE := generic_pexpr Unit sym
private abbrev PE_ := generic_pexpr_ Unit sym
private abbrev Pat := generic_pattern sym
private abbrev Expr' := generic_expr Unit Unit sym
private abbrev Expr'_ := generic_expr_ Unit Unit sym
private abbrev Act := generic_action_ Unit sym
private abbrev PAct := generic_paction Unit Unit sym

/-- Make a pexpr node. -/
private def mkPE (pe_ : PE_) : PE :=
  Pexpr annots0 () pe_

/-- Make an expr node. -/
private def mkE (e_ : Expr'_) : Expr' :=
  Expr annots0 e_

/-- Build a list pexpr from element pexprs. -/
private def mkListPE (bTy : core_base_type) : List PE → PE
  | [] => mkPE (PEctor (Cnil bTy) [])
  | pe :: pes => mkPE (PEctor Ccons [pe, mkListPE bTy pes])

/-! ## Type Parsers -/

/-- Parse an integer base type (ichar/char, short, int, long, long_long).
    Note: cerberus --pp core generates "unsigned char" / "signed char"
    even though the grammar formally only has "ichar". We accept both.

    TWO printer dialects feed this parser (arc-6 S1): ctypes embedded in
    the Core AST print via Pp_core_ctype.pp_ctype ("long_long",
    pp_core_ctype.ml:24), but ctype VALUES (Vctype) print via
    Pp_ail.pp_ctype ("long long" with a space,
    pp_ail.ml string_of_integerBaseType). We accept the union: after
    "long", a second "long" token upgrades to LongLong. -/
private def pIntegerBaseType : P integerBaseType :=
      (attempt (lexKw "ichar") *> pure Ichar)
  <|> (attempt (lexKw "char") *> pure Ichar)
  <|> (attempt (lexKw "short") *> pure Short)
  <|> (attempt (lexKw "long_long") *> pure LongLong)
  <|> (attempt (do lexKw "long"
                   (attempt (lexKw "long") *> pure LongLong) <|> pure Long))
  <|> (attempt (lexKw "int") *> pure Int_)

/-- Parse an integer type. -/
private def pIntegerType : P integerType :=
      (attempt (lexKw "char") *> pure Char0)
  <|> (attempt (lexKw "_Bool") *> pure Bool0)
  <|> (attempt (lexKw "int8_t") *> pure (Signed (IntN_t 8)))
  <|> (attempt (lexKw "int16_t") *> pure (Signed (IntN_t 16)))
  <|> (attempt (lexKw "int32_t") *> pure (Signed (IntN_t 32)))
  <|> (attempt (lexKw "int64_t") *> pure (Signed (IntN_t 64)))
  <|> (attempt (lexKw "uint8_t") *> pure (Unsigned (IntN_t 8)))
  <|> (attempt (lexKw "uint16_t") *> pure (Unsigned (IntN_t 16)))
  <|> (attempt (lexKw "uint32_t") *> pure (Unsigned (IntN_t 32)))
  <|> (attempt (lexKw "uint64_t") *> pure (Unsigned (IntN_t 64)))
  <|> (attempt (lexKw "intmax_t") *> pure (Signed Intmax_t))
  <|> (attempt (lexKw "intptr_t") *> pure (Signed Intptr_t))
  <|> (attempt (lexKw "uintmax_t") *> pure (Unsigned Intmax_t))
  <|> (attempt (lexKw "uintptr_t") *> pure (Unsigned Intptr_t))
  <|> (attempt (lexKw "size_t") *> pure Size_t)
  <|> (attempt (lexKw "ptrdiff_t") *> pure Ptrdiff_t)
  <|> (attempt (do lexKw "signed"; let ibty ← pIntegerBaseType; return (Signed ibty)))
  <|> (attempt (do lexKw "unsigned"; let ibty ← pIntegerBaseType; return (Unsigned ibty)))
  -- `enum TAG` (2026-09-01 S-basket item 2): both printer dialects emit
  -- it — Pp_core_ctype.pp_integer_ctype (pp_core_ctype.ml:42,
  -- `| Enum sym -> !^ "enum" ^^^ pp_symbol sym`) and Pp_ail
  -- (pp_ail.ml:190-191). Tag symbol interned by name like the
  -- struct/union tag arms (pCtypeAtom; same to_string_pretty channel).
  -- DELIBERATE DIVERGENCE NOTE: upstream's own Core text parser has NO
  -- enum arm (core_lexer.mll:20 keeps the "enum" token commented out),
  -- so `--pp core` output containing enum ctypes is not
  -- oracle-reparseable; this parser consumes the pp output and accepts
  -- it (a documented superset of the OCaml core grammar, not a mirror
  -- gap).
  <|> (attempt (do lexKw "enum"; let tag ← lexIdent; return (Enum0 (mkSym tag))))

/-- Parse a floating type. "long_double" is the Pp_core_ctype spelling
    (pp_core_ctype.ml:57); "long double" (space) is the Pp_ail spelling
    (pp_ail.ml pp_realFloatingType) appearing in Vctype literals. -/
private def pFloatingType : P floatingType :=
      (attempt (lexKw "long_double") *> pure (RealFloating LongDouble))
  <|> (attempt (do lexKw "long"; lexKw "double"; pure (RealFloating LongDouble)))
  <|> (attempt (lexKw "float") *> pure (RealFloating Float0))
  <|> (attempt (lexKw "double") *> pure (RealFloating Double))

/-- Parse a basic type (integer or floating). -/
private def pBasicType : P basicType :=
      (attempt (Floating <$> pFloatingType))
  <|> (Integer <$> pIntegerType)

/-! ## Ctype Parser (mutual block for self-recursion)

TWO ctype printer dialects appear in `--pp core` output (arc-6 S1):

* CORE dialect — `Pp_core_ctype.pp_ctype` (pp_core.ml:227-228): ctypes
  embedded in the Core AST (kill/array_shift/Unspecified/NULL(...)
  [impl_mem.ml:565-566], struct/union def fields [pp_core.ml:760-762],
  ail_ctype glob attributes [pp_core.ml:837]). Spellings: `long_long`,
  `long_double`, `ichar`; qualifiers are NEVER printed
  (pp_core_ctype.ml — the qs TODOs); function types print POSTFIX
  (`ret (params)` then suffixes, pp_core_ctype.ml:73-84); an empty
  parameter list prints `()` for both `Function _ [] _` and
  `FunctionNoParams _` (irreducible ambiguity — we choose
  `Function [] false`, the only form C11-prototyped libc code produces).

* AIL dialect — `Pp_ail.pp_ctype no_qualifiers` (pp_core.ml:332): ctype
  VALUES (`Vctype`) inside pexprs, i.e. every quoted type in
  create/store/ccall/are_compatible argument position. C-declarator
  style (pp_ail.ml:238-317): `long long` / `long double` (spaces),
  `char` for Ichar, pointer-to-function prints `ret (*) (params)`,
  array-of-pointer-to-function prints `ret (*[N]) (params)`, a BARE
  function type prints `ret () (params)` (the empty declarator parens),
  empty parameter lists print `(void)` (pp_ail.ml:268-270), variadic
  prints `, ...`, and pointer qualifiers print AFTER the star
  (`char*restrict` — pp_ail.ml Pointer case: star ^^ pp_qualifiers qs,
  order const/restrict/volatile per pp_qualifiers, pp_ail.ml:119-124).
  `()` (empty params, no following parens) = `FunctionNoParams`
  (pp_ail.ml FunctionNoParams case).

The grammar below accepts the UNION of both dialects; the `ail` flag
forks only the genuinely ambiguous empty-parens case. Struct/union tags
are interned by NAME HASH (`mkSym`), mirroring OCaml's symbolify_ctype
which resolves a tag name to the single registered tag symbol
(core_parser.mly symbolify paths); `--pp core` prints tags in ctype
position via Pp_symbol.to_string_pretty (plain name, pp_core_ctype.ml:15).

Pointer-qualifier representation (mirrors Ctype.Pointer (qs, ty) where
qs are the qualifiers OF THE POINTED-TO type, and function-parameter
triples (qs, ty, _) where qs are the parameter's own qualifiers —
pp_ail.ml:266-292): the suffix loop carries `pend`, the qualifiers seen
since the last completed type; a following `*` makes them the new
pointer's pointee qualifiers; if the type ends inside a parameter list
they become the parameter-triple qualifiers; at top level they are
dropped (OCaml top-level positions always print with no_qualifiers, so
well-formed dump text never has them). -/

/-- Parse zero or more qualifier keywords (const/restrict/volatile) into
    a qualifiers record; backtracks on a non-qualifier identifier.
    Print order is const,restrict,volatile (pp_ail.ml:119-124) but we
    accept any order. -/
private partial def pCtypeQualsOpt : P qualifiers := do
  let mut qs : qualifiers := no_qualifiers
  while true do
    let q ← (attempt (do lexKw "const"; pure (some "c")))
        <|> (attempt (do lexKw "restrict"; pure (some "r")))
        <|> (attempt (do lexKw "volatile"; pure (some "v")))
        <|> pure none
    match q with
    | some "c" => qs := { qs with const := true }
    | some "r" => qs := { qs with restrict := true }
    | some "v" => qs := { qs with volatile := true }
    | _ => break
  return qs

mutual

/-- Parse a ctype atom (base case). Leading qualifiers are handled by
    the caller (pCtypeQ). -/
partial def pCtypeAtom (ail : Bool) : P ctype :=
      (attempt (lexKw "void") *> pure (Ctype [] Void0))
  <|> (attempt (do
        lexKw "_Atomic"
        lexSym "("
        let ty ← pCtypeD ail
        lexSym ")"
        return (Ctype [] (Atomic ty))))
  <|> (attempt (do
        lexKw "struct"
        let tag ← lexIdent
        return (Ctype [] (Struct (mkSym tag)))))
  <|> (attempt (do
        lexKw "union"
        let tag ← lexIdent
        return (Ctype [] (Union0 (mkSym tag)))))
  <|> (attempt (do
        let bty ← pBasicType
        return (Ctype [] (Basic bty))))
  <|> (do -- fallback: try identifier as builtin typename
        let name ← attempt lexIdent
        fail s!"unknown ctype '{name}'")

/-- Parse a function parameter list body after the opening paren:
    comma-separated (qualified) ctypes, optionally terminated by `, ...`
    (variadic — pp_ail.ml:270-272 / pp_core_ctype.ml:78-80), closing
    paren consumed. `(void)` (single bare void, AIL spelling of an empty
    prototype, pp_ail.ml:268-269) yields ([], false). -/
partial def pCtypeParams (ail : Bool) :
    P (List (qualifiers × ctype × Bool) × Bool) := do
  -- empty list?
  match ← attempt (some <$> lexSym ")") <|> pure none with
  | some _ => return ([], false)
  | none =>
  let mut params : List (qualifiers × ctype × Bool) := []
  let mut variadic := false
  while true do
    -- `...` (only valid as the last element)
    match ← attempt (some <$> lexSym "...") <|> pure none with
    | some _ => variadic := true; break
    | none => pure ()
    let (qs, ty) ← pCtypeQ ail
    params := params ++ [(qs, ty, false)]
    match ← attempt (some <$> lexSym ",") <|> pure none with
    | some _ => pure ()
    | none => break
  lexSym ")"
  -- `(void)`: an empty prototype, not a void parameter
  match params, variadic with
  | [(_, Ctype _ Void0, _)], false => return ([], false)
  | _, _ => return (params, variadic)

/-- Parse ctype suffixes: pointer (*), post-star qualifiers, array ([n]),
    function ((params)), fn-pointer declarators ((*) / (*[N]) / ()).
    `pend` carries qualifiers seen since the last completed type (see
    module note). Returns the type and any still-pending qualifiers. -/
partial def pCtypeSuffix (ail : Bool) (ty : ctype) (pend : qualifiers) :
    P (ctype × qualifiers) := do
  let c? ← peek?
  match c? with
  | some '*' =>
    skip; lexWs
    -- post-star qualifiers belong to THIS pointer (pp_ail.ml Pointer
    -- case prints star ^^ pp_qualifiers qs); they become `pend` and are
    -- consumed by the NEXT star (as its pointee qualifiers), the
    -- enclosing parameter triple, or dropped at top level.
    let qs ← pCtypeQualsOpt
    pCtypeSuffix ail (Ctype [] (Pointer pend ty)) qs
  | some '[' =>
    skip; lexWs
    let c2? ← peek?
    let nOpt ← match c2? with
      | some c =>
        if c.isDigit then do
          let n ← lexInt
          pure (some n)
        else
          pure none
      | none => pure none
    lexSym "]"
    pCtypeSuffix ail (Ctype [] (Array0 ty nOpt)) pend
  | some '(' =>
    skip; lexWs
    -- (*) or (*[N]) fn-pointer declarator (AIL dialect,
    -- pp_ail.ml:283-289: Pointer-to-Function prints
    -- `ret (* k) (params)` where k is the enclosing declarator — an
    -- array bound for array-of-fn-pointer)
    let fnPtr ← attempt (do
        lexSym "*"
        let arr ← (attempt (do
            lexSym "["
            let n ← lexInt
            lexSym "]"
            pure (some n))) <|> pure none
        lexSym ")"
        pure (some arr)) <|> pure none
    match fnPtr with
    | some arrOpt =>
      lexSym "("
      let (params, variadic) ← pCtypeParams ail
      let fnTy := Ctype [] (Function (no_qualifiers, ty) params variadic)
      let ptrTy := Ctype [] (Pointer no_qualifiers fnTy)
      let ty' := match arrOpt with
        | some n => Ctype [] (Array0 ptrTy (some n))
        | none => ptrTy
      pCtypeSuffix ail ty' no_qualifiers
    | none =>
      -- `ret () (params)`: AIL print of a BARE function type — the first
      -- () is the empty declarator (pp_ail.ml Function case:
      -- `aux ret ^^^ P.parens k ^^ P.parens (params)` with k empty)
      let bareFn ← if ail then
          attempt (do lexSym ")"; lexSym "("; pure true) <|> pure false
        else pure false
      if bareFn then
        let (params, variadic) ← pCtypeParams ail
        pCtypeSuffix ail (Ctype [] (Function (no_qualifiers, ty) params variadic)) no_qualifiers
      else
        let (params, variadic) ← pCtypeParams ail
        -- empty parens: AIL = FunctionNoParams (pp_ail.ml
        -- FunctionNoParams case); CORE = Function [] false (see module
        -- note on the pp_core_ctype ambiguity)
        let ty' := if ail && params.isEmpty && !variadic then
            Ctype [] (FunctionNoParams (no_qualifiers, ty))
          else
            Ctype [] (Function (no_qualifiers, ty) params variadic)
        pCtypeSuffix ail ty' pend
  | _ => return (ty, pend)

/-- Parse a C type with pending-qualifier result (parameter position). -/
partial def pCtypeQ (ail : Bool) : P (qualifiers × ctype) := do
  let lead ← pCtypeQualsOpt
  let base ← pCtypeAtom ail
  let (ty, pend) ← pCtypeSuffix ail base lead
  return (pend, ty)

/-- Parse a C type in the given dialect, dropping trailing qualifiers
    (top-level positions always print with no_qualifiers). -/
partial def pCtypeD (ail : Bool) : P ctype := do
  let (_, ty) ← pCtypeQ ail
  return ty

end

/-- Parse a C type (CORE dialect — embedded AST ctypes). -/
partial def pCtype : P ctype := pCtypeD false

/-- Parse a ctype enclosed in single quotes: 'ctype' (CORE dialect —
    kill/array_shift/struct-field/ail_ctype positions, printed by
    Pp_core_ctype via pp_core.ml:227-228). -/
private partial def pCoreCtype : P ctype := do
  lexSym "'"
  let ty ← pCtype
  lexSym "'"
  return ty

/-- Parse a ctype enclosed in single quotes at ctype-VALUE (Vctype)
    position (AIL dialect — printed by Pp_ail.pp_ctype via
    pp_core.ml:332). The grammar accepts the spelling union of both
    dialects (Unspecified(...) values embed a Pp_core_ctype-printed type,
    pp_core.ml:308); the flag only resolves empty-parens ambiguity. -/
private partial def pCoreCtypeAil : P ctype := do
  lexSym "'"
  let ty ← pCtypeD true
  lexSym "'"
  return ty

/-- Parse an integer type enclosed in single quotes: 'integer_type' -/
private partial def pCoreIntegerType : P integerType := do
  lexSym "'"
  let ity ← pIntegerType
  lexSym "'"
  return ity

/-- Strip the `_<num>` suffix from a raw-printed symbol name.
    OTy_struct/OTy_union tags print via Pp_symbol.to_string
    (pp_core.ml:186-189), which is `name ^ "_" ^ string_of_int n`
    (pp_symbol.ml:5-10) — unlike every other symbol position, which
    prints to_string_pretty (plain name). Stripping one trailing
    `_[0-9]+` group recovers the name so the tag interns to the SAME
    name-hash symbol as its ctype-position occurrences (`struct
    _IO_FILE_331` ≡ `'struct _IO_FILE'`). A tag whose source name itself
    ends in `_<digits>` would be mis-stripped — none exist in the
    shipped std.core/libc corpus (asserted by the libc unit test). -/
private def stripRawSymSuffix (s : String) : String :=
  let cs := s.toList.reverse
  let digits := cs.takeWhile (·.isDigit)
  if digits.isEmpty then s
  else match cs.drop digits.length with
    | '_' :: rest => if rest.isEmpty then s else String.mk rest.reverse
    | _ => s

/-- Parse a core object type. -/
partial def pCoreObjectType : P core_object_type :=
      (attempt (lexKw "integer") *> pure OTy_integer)
  <|> (attempt (lexKw "floating") *> pure OTy_floating)
  <|> (attempt (lexKw "pointer") *> pure OTy_pointer)
  <|> (attempt (do
        lexKw "array"
        lexSym "("
        let oTy ← pCoreObjectType
        lexSym ")"
        return (OTy_array oTy)))
  <|> (attempt (do
        lexKw "struct"
        let tag ← lexIdent
        return (OTy_struct (mkSym (stripRawSymSuffix tag)))))
  <|> (attempt (do
        lexKw "union"
        let tag ← lexIdent
        return (OTy_union (mkSym (stripRawSymSuffix tag)))))

/-- Parse a core base type. -/
partial def pCoreBaseType : P core_base_type :=
      (attempt (lexKw "unit") *> pure BTy_unit)
  <|> (attempt (lexKw "boolean") *> pure BTy_boolean)
  <|> (attempt (lexKw "ctype") *> pure BTy_ctype)
  <|> (attempt (lexKw "storable") *> pure BTy_storable)
  <|> (attempt (do
        lexKw "loaded"
        let oTy ← pCoreObjectType
        return (BTy_loaded oTy)))
  <|> (attempt (do
        -- list type: [baseTy]
        lexSym "["
        let bTy ← pCoreBaseType
        lexSym "]"
        return (BTy_list bTy)))
  <|> (attempt (do
        -- tuple type: (bTy1, bTy2, ...)
        lexSym "("
        let bTys ← sepByComma pCoreBaseType
        lexSym ")"
        return (BTy_tuple bTys)))
  <|> (BTy_object <$> pCoreObjectType)

/-- Parse a core type (base or effectful). -/
partial def pCoreType : P core_base_type :=
      (attempt (do lexKw "eff"; pCoreBaseType))
  <|> pCoreBaseType

/-! ## Constructor Keyword Parser -/

/-- Parse a constructor keyword. -/
private def pCtorKw : P ctor :=
      (attempt (lexKw "Array") *> pure Carray)
  <|> (attempt (lexKw "Ivmax") *> pure Civmax)
  <|> (attempt (lexKw "Ivmin") *> pure Civmin)
  <|> (attempt (lexKw "Ivsizeof") *> pure Civsizeof)
  <|> (attempt (lexKw "Ivalignof") *> pure Civalignof)
  <|> (attempt (lexKw "Specified") *> pure Cspecified)
  <|> (attempt (lexKw "Unspecified") *> pure Cunspecified)
  <|> (attempt (lexKw "Fvfromint") *> pure Cfvfromint)
  <|> (attempt (lexKw "Ivfromfloat") *> pure Civfromfloat)
  -- Zero-discrepancy Z2-CP-21 (found by the Z2 fix phase): the pretty-printer
  -- spells these two ctors `Cfvfromint`/`Civfromfloat` (pp_core.ml:367-370
  -- pp_datactor) while the OCaml lexer's keywords are `Fvfromint`/
  -- `Ivfromfloat` (core_lexer.mll:83-84) — the oracle cannot re-read its
  -- own dump here (tray candidate). The pinned dump tests/libc/libc.core
  -- carries the pp spelling at 29 sites (e.g. :53901 `Cfvfromint(a_26866)`
  -- in proc decfloat); the oracle's in-memory libc.co holds `PEctor
  -- Cfvfromint`, so the pp spelling is given that AST here.
  <|> (attempt (lexKw "Cfvfromint") *> pure Cfvfromint)
  <|> (attempt (lexKw "Civfromfloat") *> pure Civfromfloat)
  <|> (attempt (lexKw "IvCOMPL") *> pure CivCOMPL)
  <|> (attempt (lexKw "IvAND") *> pure CivAND)
  <|> (attempt (lexKw "IvOR") *> pure CivOR)
  <|> (attempt (lexKw "IvXOR") *> pure CivXOR)

/-! ## Name Parser -/

/-- Parse a name (symbol or impl constant). -/
private partial def pName : P (generic_name sym) :=
      (attempt (do
        let iCst ← lexImpl
        return (Impl (pImplConstant iCst))))
  <|> (do
        let s ← lexSymId
        return (generic_name.Sym s))

/-! ## Identifier Parser -/

/-- Parse a cabs_id (.name) -/
private def pCabsId : P identifier := do
  let name ← lexIdent
  return (Identifier loc0 name)

/-! ## Binary Operator Parser -/

/-- Get (precedence, nextMinPrec) for a binop.
    Precedence matches OCaml Menhir (higher = tighter binding):
    \/ (1,right) /\ (2,right) =><>=<= (3,left) +- (4,left) :: (5,right) */rem (6,left) ^ (7,nonassoc) -/
private def opPrecInfo : binop → Nat × Nat
  | OpOr => (1, 1)              -- right-assoc: nextMin = prec
  | OpAnd => (2, 2)             -- right-assoc
  | OpEq | OpGt | OpLt
  | OpGe | OpLe => (3, 4)       -- left-assoc: nextMin = prec + 1
  | OpAdd | OpSub => (4, 5)     -- left-assoc
  | OpMul | OpDiv
  | OpRem_t | OpRem_f => (6, 7) -- left-assoc
  | OpExp => (7, 8)             -- nonassoc: nextMin = prec + 1

/-- Parse a binary operator token. -/
private def pBinop : P binop :=
      (attempt (lexSym "/\\" *> pure OpAnd))
  <|> (attempt (lexSym "\\/" *> pure OpOr))
  <|> (attempt (lexSym ">=" *> pure OpGe))
  <|> (attempt (lexSym "<=" *> pure OpLe))
  <|> (attempt (lexSym "+" *> pure OpAdd))
  <|> (attempt (lexSym "-" *> pure OpSub))
  <|> (attempt (lexSym "*" *> pure OpMul))
  <|> (attempt (lexKw "rem_t" *> pure OpRem_t))
  <|> (attempt (lexKw "rem_f" *> pure OpRem_f))
  <|> (attempt (lexSym "/" *> pure OpDiv))
  <|> (attempt (lexSym "^" *> pure OpExp))
  <|> (attempt (lexSym "=" *> pure OpEq))
  <|> (attempt (lexSym ">" *> pure OpGt))
  <|> (attempt (lexSym "<" *> pure OpLt))

/-! ## Memory Order Parser -/

private def pMemoryOrder : P memory_order :=
      (attempt (lexKw "seq_cst") *> pure Seq_cst)
  <|> (attempt (lexKw "relaxed") *> pure Relaxed)
  <|> (attempt (lexKw "release") *> pure Release)
  <|> (attempt (lexKw "acquire") *> pure Acquire)
  <|> (attempt (lexKw "consume") *> pure Consume)
  <|> (attempt (lexKw "acq_rel") *> pure Acq_rel)

/-! ## IOP Parser -/

private def pIop : P iop :=
      (attempt (lexKw "IOpAdd") *> pure IOpAdd)
  <|> (attempt (lexKw "IOpSub") *> pure IOpSub)
  <|> (attempt (lexKw "IOpMul") *> pure IOpMul)
  <|> (attempt (lexKw "IOpShl") *> pure IOpShl)
  <|> (attempt (lexKw "IOpShr") *> pure IOpShr)
  <|> (attempt (lexKw "IOpDiv") *> pure IOpDiv)
  <|> (attempt (lexKw "IOpRem_t") *> pure IOpRem_t)

/-! ## Memop Parser -/

private partial def pMemopOp : P (generic_memop sym) :=
      (attempt (lexKw "PtrEq") *> pure PtrEq)
  <|> (attempt (lexKw "PtrNe") *> pure PtrNe)
  <|> (attempt (lexKw "PtrLt") *> pure PtrLt)
  <|> (attempt (lexKw "PtrGt") *> pure PtrGt)
  <|> (attempt (lexKw "PtrLe") *> pure PtrLe)
  <|> (attempt (lexKw "PtrGe") *> pure PtrGe)
  <|> (attempt (lexKw "Ptrdiff") *> pure Ptrdiff)
  <|> (attempt (lexKw "IntFromPtr") *> pure IntFromPtr)
  <|> (attempt (lexKw "PtrFromInt") *> pure PtrFromInt)
  <|> (attempt (lexKw "PtrValidForDeref") *> pure PtrValidForDeref)
  <|> (attempt (lexKw "PtrWellAligned") *> pure PtrWellAligned)
  <|> (attempt (lexKw "PtrArrayShift") *> pure PtrArrayShift)
  <|> (attempt (lexKw "Memcpy") *> pure Memcpy)
  <|> (attempt (lexKw "Memcmp") *> pure Memcmp)
  <|> (attempt (lexKw "Realloc") *> pure Realloc)
  <|> (attempt (lexKw "Va_start") *> pure Va_start)
  <|> (attempt (lexKw "Va_copy") *> pure Va_copy)
  <|> (attempt (lexKw "Va_arg") *> pure Va_arg)
  <|> (attempt (lexKw "Va_end") *> pure Va_end)
  <|> (attempt (lexKw "Copy_alloc_id") *> pure Copy_alloc_id)
  <|> (attempt (do
        lexKw "PtrMemberShift"
        lexSym "["
        let s ← lexSymId
        lexSym ","
        lexSym "."
        let cid ← pCabsId
        lexSym "]"
        return (PtrMemberShift s cid)))

/-- Parse a pure_memop. -/
private def pPureMemop : P pure_memop :=
      (attempt (lexKw "CapAssignValue") *> pure CapAssignValue)
  <|> (attempt (lexKw "Ptr_tIntValue") *> pure Ptr_tIntValue)
  <|> (attempt (lexKw "ByteFromInt") *> pure ByteFromInt)
  <|> (attempt (lexKw "IntFromByte") *> pure IntFromByte)

/-! ## Value Parser -/

/-- Parse a Core value. -/
partial def pValue : P value :=
      (attempt (do lexKw "Unit"; return Vunit))
  <|> (attempt (do lexKw "True"; return Vtrue))
  <|> (attempt (do lexKw "False"; return Vfalse))
  <|> (attempt (do
        lexKw "NULL"
        lexSym "("
        let ty ← pCtype
        lexSym ")"
        return (Vobject (OVpointer (CerbMem.nullPtrval ty)))))
  <|> (attempt (do
        lexKw "Cfunction_value"
        lexSym "("
        let nm ← pName
        lexSym ")"
        -- grammar-form function pointer value (core_parser.mly:1540);
        -- note upstream's own semantic action punts to null_ptrval
        -- (mly:1541 TODO) — we build the real PVfunction instead, since
        -- exec depends on it (arc-6 S1)
        match nm with
        | generic_name.Sym s =>
          return (Vobject (OVpointer (CerbMem.funPtrval s)))
        | Impl _ => fail "Cfunction_value of an impl constant"))
  <|> (attempt (do
        lexKw "Ivmax_alignment"
        return (Vobject (OVinteger (CerbMem.integerIval 16)))))
  <|> (attempt (do
        let ty ← pCoreCtypeAil
        return (Vctype ty)))
  <|> (do
        match ← attempt lexNumLit with
        | .int n => return (Vobject (OVinteger (CerbMem.integerIval n)))
        | .float f => return (Vobject (OVfloating (f))))

/-! ## Pattern pair helper -/

/-- Parse a pattern pair: | pat => body -/
private partial def pPatternPair (pBody : P α) (pPat : P Pat) : P (Pat × α) := do
  lexSym "|"
  let pat ← pPat
  lexSym "=>"
  let body ← pBody
  return (pat, body)

/-! ## Pattern mutual block -/

mutual

-- Pattern helpers

private partial def pPatternNamed : P Pat := do
  let s ← lexSymId
  lexSym ":"
  let bTy ← pCoreBaseType
  -- Fix 3: wildcard pattern `_`
  let base := match s with
    | Symbol _ _ (SD_Id "_") => CaseBase (none, bTy)
    | _ => CaseBase (some s, bTy)
  return (Pattern annots0 base)

private partial def pPatternWildcard : P Pat := do
  lexSym "_"
  lexSym ":"
  let bTy ← pCoreBaseType
  return (Pattern annots0 (CaseBase (none, bTy)))

private partial def pPatternTuple : P Pat := do
  lexSym "("
  let first ← pPattern
  lexSym ","
  let rest ← sepByComma1 pPattern
  lexSym ")"
  return (Pattern annots0 (CaseCtor Ctuple (first :: rest)))

private partial def pPatternCtor : P Pat := do
  let c ← pCtorKw
  lexSym "("
  let pats ← sepByComma pPattern
  lexSym ")"
  return (Pattern annots0 (CaseCtor c pats))

private partial def pPatternListEmpty : P Pat := do
  lexSym "[]"
  lexSym ":"
  let bTy ← pCoreBaseType
  let innerBTy := ensureListBTy bTy
  return (Pattern annots0 (CaseCtor (Cnil innerBTy) []))

private partial def pPatternListLiteral : P Pat := do
  lexSym "["
  let pats ← sepByComma pPattern
  lexSym "]"
  lexSym ":"
  let bTy ← pCoreBaseType
  let innerBTy := ensureListBTy bTy
  return (mkListPat innerBTy pats)

/-- Parse a pattern atom (everything except ::). -/
private partial def pPatternAtom : P Pat :=
      (attempt pPatternTuple)
  <|> (attempt pPatternCtor)
  <|> (attempt pPatternListLiteral)
  <|> (attempt pPatternListEmpty)
  <|> (attempt pPatternNamed)
  <|> pPatternWildcard

/-- Parse a pattern. Handles right-associative :: cons. -/
partial def pPattern : P Pat := do
  let p1 ← pPatternAtom
  match ← attempt (some <$> lexSym "::") <|> pure none with
  | some _ =>
    let p2 ← pPattern
    return (Pattern annots0 (CaseCtor Ccons [p1, p2]))
  | none => return p1

end

/-- Parse a value as a pexpr. Defined outside the mutual block since it only calls pValue. -/
partial def pPexprValue : P (generic_pexpr Unit sym) := do
  let v ← pValue
  return (mkPE (PEval v))

/-! ## Pexpr mutual block -/

mutual

-- Pexpr helpers (only those called from pPexprAtom dispatch)

private partial def pPexprParen : P PE := do
  lexSym "("
  let pe ← pPexpr
  lexSym ")"
  return pe

private partial def pPexprMinus : P PE := do
  lexSym "-"
  -- Zero-discrepancy Z2-CP-01: `-inf` / `-nan` are single float VALUES in the
  -- pp's output (`string_of_float neg_infinity` = "-inf"), not `0 - inf`.
  let special ← attempt (do
      let id ← lexIdent
      if id == "inf" then pure (some (-(1.0 / 0.0 : Float)))
      else if id == "nan" then pure (some (-(0.0 / 0.0 : Float)))
      else fail "not a float special") <|> pure none
  match special with
  | some f => return (mkPE (PEval (Vobject (OVfloating f))))
  | none =>
  let pe ← pPexprAtom
  return (mkPE (PEop OpSub (mkPE (PEval (Vobject (OVinteger (CerbMem.integerIval 0))))) pe))

private partial def pPexprStruct : P PE := do
  lexSym "("
  lexKw "struct"
  let s ← lexSymId
  lexSym ")"
  lexSym "{"
  let mems ← sepByComma (do
    lexSym "."
    let cid ← pCabsId
    lexSym "="
    let pe ← pPexpr
    return (cid, pe))
  lexSym "}"
  return (mkPE (PEstruct s mems))

private partial def pPexprUnion : P PE := do
  lexSym "("
  lexKw "union"
  let s ← lexSymId
  lexSym ")"
  lexSym "{"
  lexSym "."
  let cid ← pCabsId
  lexSym "="
  let pe ← pPexpr
  lexSym "}"
  return (mkPE (PEunion s cid pe))

private partial def pPexprListEmpty : P PE := do
  lexSym "[]"
  lexSym ":"
  let bTy ← pCoreBaseType
  let innerBTy := ensureListBTy bTy
  return (mkPE (PEctor (Cnil innerBTy) []))

private partial def pPexprListLiteral : P PE := do
  lexSym "["
  let pes ← sepByComma pPexpr
  lexSym "]"
  lexSym ":"
  let bTy ← pCoreBaseType
  let innerBTy := ensureListBTy bTy
  return (mkListPE innerBTy pes)

private partial def pPexprTuple : P PE := do
  lexSym "("
  let first ← pPexpr
  lexSym ","
  let rest ← sepByComma1 pPexpr
  lexSym ")"
  return (mkPE (PEctor Ctuple (first :: rest)))

/-- List literal WITHOUT a `: type` annotation. pp_value prints Vlist as
    bare brackets (pp_core.ml:327-329 — no type annotation), unlike the
    grammar's annotated list form (which the two parsers above handle);
    this occurs for variadic argument lists in `--pp core` output of
    elaborated code (`[('signed int', a_9552)]`). The element base type
    is not recoverable from the text; we record BTy_unit in the Cnil —
    consumers never read it (match_pattern ignores the Cnil/Vlist type
    arguments, core_aux.lem:2028-2035, 2426-2429). -/
private partial def pPexprListNoAnnot : P PE := do
  lexSym "["
  let pes ← sepByComma pPexpr
  lexSym "]"
  return (mkListPE BTy_unit pes)

partial def pPexprAtom (minPrec : Nat := 0) : P PE := do
  -- Dispatch on first character to avoid trying all alternatives
  let c ← peek?
  match c with
  | some '(' => (attempt pPexprParen) <|> (attempt pPexprTuple) <|> (attempt pPexprStruct) <|> pPexprUnion
  | some '[' => (attempt pPexprListLiteral) <|> (attempt pPexprListEmpty) <|> pPexprListNoAnnot
  | some '-' => pPexprMinus
  | some '<' =>
      -- Fix 4: impl constant or impl function call <name>(args)
      let iCst ← lexImpl
      let ic := pImplConstant iCst
      match ← peek? with
      | some '(' =>
        lexSym "("
        let args ← sepByComma pPexpr
        lexSym ")"
        return (mkPE (PEcall (Impl ic) args))
      | _ => return (mkPE (PEimpl ic))
  | some '\'' => pPexprValue  -- ctype value in quotes
  | _ =>
    -- Keyword-based dispatch
    let id ← attempt (some <$> lexIdent) <|> pure none
    match id with
    | some "undef" =>
      lexSym "("
      let ubStr ← lexDoubleAngle
      lexSym ")"
      -- Mirror OCaml scan_ub (parsers/core/core_lexer.mll:221-232): the
      -- <<...>> payload is first looked up in Undefined.ub_str_bimap (known
      -- UB names round-trip to their constructors); an unknown name is
      -- accepted only in the DUMMY(<str>) spelling, unwrapping to DUMMY
      -- <str> (remove_prefix "<<DUMMY(" / trim_end 3 there ≡ dropping
      -- "DUMMY(" and ")" here, since lexDoubleAngle already stripped the
      -- angles); anything else raises Core_lexer_invalid_ubname there and
      -- fails here. Previously we wrapped the payload in DUMMY
      -- unconditionally, so std.core's undef(<<DUMMY(align_alloc)>>)
      -- rendered DUMMY(DUMMY(align_alloc)) — the cn_coverage mask_ptr.c
      -- UB_DIFF.
      -- DELIBERATE DIVERGENCE (registered, arc4-seam-survey): OCaml's
      -- ub_name lexeme (core_lexer.mll:250-251) admits '<'/'>' INSIDE a
      -- DUMMY(...) payload; lexDoubleAngle above stops at the first '>',
      -- so such a payload fails here with a loud parse error instead of
      -- parsing. No payload in runtime/libcore or any in-tree DUMMY
      -- string contains '>' (tree-wide sweep, 2026-08-22 cn-coverage
      -- audit), and the failure mode is fail-closed, never silent.
      match lookupR ubStr ub_str_bimap with
      | some ub => return (mkPE (PEundef loc0 ub))
      | none =>
        if ubStr.startsWith "DUMMY(" && ubStr.endsWith ")" then
          return (mkPE (PEundef loc0 (DUMMY ((ubStr.drop 6).dropRight 1).toString)))
        else
          fail s!"invalid ub name: <<{ubStr}>>"
    | some "error" =>
      lexSym "("
      -- PEerror's string prints DQUOTED (pp_core.ml:444-445, matching the
      -- grammar's STRING token, core_parser.mly:1572); the <<<...>>> form
      -- is the hand-written std.core spelling. Accept both.
      let msg ← match ← peek? with
        | some '"' => lexStr
        | _ => lexTripleAngle
      lexSym ","
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEerror msg pe))
    | some "not" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEnot pe))
    | some "memop" =>
      lexSym "("
      let memop ← pPureMemop
      lexSym ","
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEmemop memop pes))
    | some "array_shift" =>
      lexSym "("
      let pe1 ← pPexpr
      lexSym ","
      let ty ← pCoreCtype
      lexSym ","
      let pe2 ← pPexpr
      lexSym ")"
      return (mkPE (PEarray_shift pe1 ty pe2))
    | some "member_shift" =>
      lexSym "("
      let pe1 ← pPexpr
      lexSym ","
      let s ← lexSymId
      lexSym ","
      lexSym "."
      let cid ← pCabsId
      lexSym ")"
      return (mkPE (PEmember_shift pe1 s cid))
    | some "is_scalar" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEis_scalar pe))
    | some "is_integer" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEis_integer pe))
    | some "is_signed" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEis_signed pe))
    | some "is_unsigned" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEis_unsigned pe))
    | some "are_compatible" =>
      lexSym "("
      let pe1 ← pPexpr
      lexSym ","
      let pe2 ← pPexpr
      lexSym ")"
      return (mkPE (PEare_compatible pe1 pe2))
    | some "let" =>
      let pat ← pPattern
      lexSym "="
      let pe1 ← pPexpr
      lexKw "in"
      let pe2 ← pPexpr
      return (mkPE (PElet pat pe1 pe2))
    | some "if" =>
      pPexprIfTail (minPrec > 0)
    | some "case" =>
      let pe ← pPexpr
      lexKw "of"
      let mut pairs := #[]
      while true do
        match ← attempt (some <$> pPatternPair pPexpr pPattern) <|> pure none with
        | some p => pairs := pairs.push p
        | none => break
      lexKw "end"
      return (mkPE (PEcase pe pairs.toList))
    | some "True" => return (mkPE (PEval Vtrue))
    | some "False" => return (mkPE (PEval Vfalse))
    | some "Unit" => return (mkPE (PEval Vunit))
    -- Constructor keywords (must match OCaml lexer keywords exactly)
    | some "Specified" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Cspecified pes))
    | some "Unspecified" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Cunspecified pes))
    | some "Ivmax" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Civmax pes))
    | some "Ivmin" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Civmin pes))
    | some "Ivsizeof" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Civsizeof pes))
    | some "Ivalignof" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Civalignof pes))
    | some "IvCOMPL" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor CivCOMPL pes))
    | some "IvAND" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor CivAND pes))
    | some "IvOR" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor CivOR pes))
    | some "IvXOR" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor CivXOR pes))
    | some "Fvfromint" | some "Cfvfromint" =>   -- `Cfvfromint` = the pp spelling (Z2-CP-21, see pCtorName)
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Cfvfromint pes))
    | some "Ivfromfloat" | some "Civfromfloat" =>   -- `Civfromfloat` = the pp spelling (Z2-CP-21)
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Civfromfloat pes))
    | some "Array" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Carray pes))
    -- Value keywords
    | some "NULL" =>
      lexSym "("
      let ty ← pCtype
      lexSym ")"
      return (mkPE (PEval (Vobject (OVpointer (CerbMem.nullPtrval ty)))))
    | some "Cfunction" =>
      lexSym "("
      let nm ← pName
      lexSym ")"
      -- `Cfunction(sym)` is the pp of a PVfunction pointer value
      -- (impl_mem.ml:567-568 pp_pointer_value) — a pp-only form (the
      -- OCaml core grammar has no production for it). Parse it to the
      -- real function pointer; exec resolves it via funinfo/call_proc
      -- (arc-6 S1; the previous null_ptrval punt made every libc-internal
      -- call die with "null function pointer").
      match nm with
      | generic_name.Sym s =>
        return (mkPE (PEval (Vobject (OVpointer (CerbMem.funPtrval s)))))
      | Impl _ => fail "Cfunction of an impl constant"
    | some "IvMaxAlignment" =>
      -- core_parser.mly:1536-1537: `integer_ival (Z.of_int
      -- (Ocaml_implementation.(get ()).max_alignment))` — the IMPLEMENTATION
      -- record's value (DefaultImpl.max_alignment = 8,
      -- ocaml_implementation.ml:151-152; MorelloImpl's 16 only under CHERI,
      -- refused). Zero-discrepancy Z-76 (dynamic-addrs record §6): this was
      -- the literal 16 while CerberusImpl.max_alignment declared 8, so every
      -- Lean malloc/realloc (std.core `alloc(IvMaxAlignment, …)`) was
      -- 16-aligned against the oracle's 8 (da_offset.c 16 vs 8).
      return (mkPE (PEval (Vobject (OVinteger
        (CerbMem.integerIval (CerberusImpl.max_alignment : Int))))))
    -- Expression keywords
    | some "cfunction" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEcfunction pe))
    | some id =>
      -- Zero-discrepancy Z2-CP-01: the pp prints an `OVfloating` through
      -- OCaml `string_of_float` (pp_core.ml:279-282), which renders the
      -- IEEE infinities and NaN as the IDENTIFIER-shaped `inf`, `-inf`,
      -- `nan`; the OCaml Core grammar has NO float literal at all
      -- (core_lexer.mll:290-291 — the oracle never re-reads its own dumps,
      -- it runs the in-memory libc.co), so the pinned `--pp=core` dump
      -- tests/libc/libc.core carries `pure(Specified(inf))` at
      -- :53897/:53906/:64081/:64090 (proc decfloat's overflow path) and this
      -- parser lexed it as an UNBOUND symbol — every strtod/strtof overflow
      -- in libc mode was `Error {msg: "Unresolved_symbol: …"}` where the
      -- oracle answers a value (pin tests/immaculate/libc/zd-z2cp01-strtod-inf.c).
      -- Mapped to the value the oracle's AST holds. NaN payload/sign are not
      -- recoverable from the text (the pp loses them) — the sign of a printed
      -- `nan` is taken as positive, `-nan` as negative (pPexprMinus).
      if id == "inf" then return (mkPE (PEval (Vobject (OVfloating (1.0 / 0.0 : Float)))))
      else if id == "nan" then return (mkPE (PEval (Vobject (OVfloating (0.0 / 0.0 : Float)))))
      -- Handle __conv_int__
      else if id == "__conv_int__" then
        lexSym "("
        let ity ← pCoreIntegerType
        lexSym ","
        let pe ← pPexpr
        lexSym ")"
        return (mkPE (PEconv_int ity pe))
      -- Handle wrapI_* and catch_exceptional_condition_* variants
      else if id.startsWith "wrapI_" then
        let iop' := pIopFromStr id
        lexSym "("
        let ity ← pCoreIntegerType
        lexSym ","
        let pe1 ← pPexpr
        lexSym ","
        let pe2 ← pPexpr
        lexSym ")"
        return (mkPE (PEwrapI ity iop' pe1 pe2))
      else if id.startsWith "catch_exceptional_condition_" then
        let iop' := pIopFromStr id
        lexSym "("
        let ity ← pCoreIntegerType
        lexSym ","
        let pe1 ← pPexpr
        lexSym ","
        let pe2 ← pPexpr
        lexSym ")"
        return (mkPE (PEcatch_exceptional_condition ity iop' pe1 pe2))
      else
        -- Could be a symbol or a call
        let s := mkSym id
        match ← peek? with
        | some '(' => -- function call
          lexSym "("
          let args ← sepByComma pPexpr
          lexSym ")"
          return (mkPE (PEcall (Sym s) args))
        | _ => return (mkPE (PEsym s))  -- just a variable
    | none =>
      -- Try numeric literal (integer or float)
      match ← lexNumLit with
      | .int n => return (mkPE (PEval (Vobject (OVinteger (CerbMem.integerIval n)))))
      | .float f => return (mkPE (PEval (Vobject (OVfloating (f)))))

/- ### The PEif reparse ambiguity (arc-6 S1)

`--pp core` NEVER parenthesizes a PEif: precedence_pexpr gives PEif
`None` (pp_core.ml:69-98) and `compare_precedence None _ = true`
(pp_core.ml:161-164), so `PEop(op, PEif …, rhs)` prints exactly like
`PEif(…, else-branch = PEop(op, …, rhs))`. The ONLY generator of
PEif-as-binop-operand in our corpora is the elaborator's integer
promotion wrapper `if all_values_representable_in(T1,T2) then
conv_int(…) else conv_int(…)` (its branches are always calls — atoms),
appearing either as a binop RHS (`conv_int(…) < if …`) or as the FIRST
atom of an if condition (`if if …`, 39 sites in the pinned libc dump).
Hand-written std.core has NEITHER shape (verified: no binop-then-`if`
and no `if if`), but DOES have if-branches that are binop expressions
(`else 2^width + n`, std.core:143), so if-branches must stay greedy by
default. Resolution: an `if` parsed as a binop operand (minPrec > 0) or
as the leading atom of an if-CONDITION gets ATOM-BOUNDED branches
(pPexprPrec 8 — no binops, no cons); all other ifs parse greedily. -/

/-- Parse `cond then e1 else e2` after the `if` keyword; `bounded`
    restricts the branches to atoms (see the ambiguity note above). -/
private partial def pPexprIfTail (bounded : Bool) : P PE := do
  let pe1 ← pPexprCondChain
  lexKw "then"
  let pe2 ← if bounded then pPexprPrec 8 else pPexpr
  lexKw "else"
  let pe3 ← if bounded then pPexprPrec 8 else pPexpr
  return (mkPE (PEif pe1 pe2 pe3))

/-- Parse an if-condition: a leading `if` atom is the promotion wrapper
    (operand-bounded), continued by the ordinary binop chain. -/
private partial def pPexprCondChain : P PE := do
  match ← attempt (some <$> (do lexKw "if"; pPexprIfTail true)) <|> pure none with
  | some lhs => pPexprBinopLoop lhs 0
  | none => pPexpr

/-- Binop / cons precedence-climbing loop continuing from a parsed lhs. -/
private partial def pPexprBinopLoop (lhs0 : PE) (minPrec : Nat) : P PE := do
  let mut lhs := lhs0
  while true do
    -- Phase 1: try to match operator with sufficient precedence (with backtracking)
    let opOpt ← attempt (some <$> do
      -- Try :: first (precedence 5, right-associative)
      let isConsOp ← (attempt (lexSym "::" *> pure true)) <|> pure false
      if isConsOp then
        if 5 < minPrec then fail "prec"
        return (none, 5)  -- (none = cons op, nextMin = 5 for right-assoc)
      else
        let op ← pBinop
        let (prec, nextMin) := opPrecInfo op
        if prec < minPrec then fail "prec"
        return (some op, nextMin)
    ) <|> pure none
    -- Phase 2: parse RHS (committed) or break
    match opOpt with
    | none => break
    | some (opOpt, nextMin) =>
      let rhs ← pPexprPrec nextMin
      match opOpt with
      | none => lhs := mkPE (PEctor Ccons [lhs, rhs])
      | some op => lhs := mkPE (PEop op lhs rhs)
  return lhs

/-- Precedence climbing parser for binary operators and :: cons. -/
private partial def pPexprPrec (minPrec : Nat) : P PE := do
  let lhs ← pPexprAtom minPrec
  pPexprBinopLoop lhs minPrec

/-- Parse a pure expression with full operator precedence. -/
partial def pPexpr : P PE := pPexprPrec 0

end

/-! ## Action/Paction/Expr mutual block -/

mutual

-- Action helpers

private partial def pActionCreate : P Act := do
  lexKw "create"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ")"
  return (Create pe1 pe2 (PrefOther "Core"))

private partial def pActionCreateReadOnly : P Act := do
  lexKw "create_readonly"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ","
  let pe3 ← pPexpr
  lexSym ")"
  return (CreateReadOnly pe1 pe2 pe3 (PrefOther "Core"))

private partial def pActionAlloc : P Act := do
  lexKw "alloc"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ")"
  return (Alloc0 pe1 pe2 (PrefOther "Core"))

private partial def pActionFree : P Act := do
  lexKw "free"
  lexSym "("
  let pe ← pPexpr
  lexSym ")"
  return (Kill Dynamic0 pe)

private partial def pActionKill : P Act := do
  lexKw "kill"
  lexSym "("
  let ct ← pCoreCtype
  lexSym ","
  let pe ← pPexpr
  lexSym ")"
  return (Kill (Static0 ct) pe)

private partial def pActionStore : P Act := do
  lexKw "store"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ","
  let pe3 ← pPexpr
  let mo ← (attempt (do lexSym ","; pMemoryOrder)) <|> pure NA
  lexSym ")"
  return (Store0 false pe1 pe2 pe3 mo)

private partial def pActionStoreLock : P Act := do
  lexKw "store_lock"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ","
  let pe3 ← pPexpr
  let mo ← (attempt (do lexSym ","; pMemoryOrder)) <|> pure NA
  lexSym ")"
  return (Store0 true pe1 pe2 pe3 mo)

private partial def pActionLoad : P Act := do
  lexKw "load"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  let mo ← (attempt (do lexSym ","; pMemoryOrder)) <|> pure NA
  lexSym ")"
  return (Load0 pe1 pe2 mo)

private partial def pActionSeqRMW : P Act := do
  lexKw "seq_rmw"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ","
  let s ← lexSymId
  lexSym "=>"
  let pe3 ← pPexpr
  lexSym ")"
  return (SeqRMW false pe1 pe2 s pe3)

private partial def pActionSeqRMWForward : P Act := do
  lexKw "seq_rmw_with_forward"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ","
  let s ← lexSymId
  lexSym "=>"
  let pe3 ← pPexpr
  lexSym ")"
  return (SeqRMW true pe1 pe2 s pe3)

private partial def pActionRMW : P Act := do
  lexKw "rmw"
  lexSym "("
  let pe1 ← pPexpr
  lexSym ","
  let pe2 ← pPexpr
  lexSym ","
  let pe3 ← pPexpr
  lexSym ","
  let pe4 ← pPexpr
  lexSym ","
  let mo1 ← pMemoryOrder
  lexSym ","
  let mo2 ← pMemoryOrder
  lexSym ")"
  return (RMW0 pe1 pe2 pe3 pe4 mo1 mo2)

private partial def pActionFence : P Act := do
  lexKw "fence"
  lexSym "("
  let mo ← pMemoryOrder
  lexSym ")"
  return (Fence0 mo)

/-- Parse a memory action. -/
private partial def pAction : P Act := do
  -- Peek at first char to narrow alternatives
  let c ← peek?
  match c with
  | some 'c' => (attempt pActionCreate) <|> pActionCreateReadOnly
  | some 'a' => pActionAlloc
  | some 'f' => (attempt pActionFree) <|> pActionFence
  | some 'k' => pActionKill
  | some 's' => (attempt pActionStoreLock) <|> (attempt pActionStore) <|> (attempt pActionSeqRMWForward) <|> pActionSeqRMW
  | some 'l' => pActionLoad
  | some 'r' => pActionRMW
  | _ => fail "expected action keyword"

/-- Parse a paction (action with polarity). -/
private partial def pPaction : P PAct :=
      (attempt (do
        lexKw "neg"
        lexSym "("
        let act ← pAction
        lexSym ")"
        return (Paction Neg0 (Action loc0 () act))))
  <|> (do
        let act ← pAction
        return (Paction Pos (Action loc0 () act)))

-- Expr helpers

private partial def pExprParen : P Expr' := do
  lexSym "("
  let e ← pExpr
  lexSym ")"
  return e

private partial def pExprPure : P Expr' := do
  lexKw "pure"
  lexSym "("
  let pe ← pPexpr
  lexSym ")"
  return (mkE (Epure pe))

private partial def pExprMemop : P Expr' := do
  lexKw "memop"
  lexSym "("
  let memop ← pMemopOp
  lexSym ","
  let pes ← sepByComma pPexpr
  lexSym ")"
  return (mkE (Ememop memop pes))

private partial def pExprLet : P Expr' := do
  lexKw "let"
  let pat ← pPattern
  lexSym "="
  let pe ← pPexpr
  lexKw "in"
  let e ← pExpr
  return (mkE (Elet pat pe e))

private partial def pExprLetWeak : P Expr' := do
  lexKw "let"
  lexKw "weak"
  let pat ← pPattern
  lexSym "="
  let e1 ← pExpr
  lexKw "in"
  let e2 ← pExpr
  return (mkE (Ewseq pat e1 e2))

private partial def pExprLetStrong : P Expr' := do
  lexKw "let"
  lexKw "strong"
  let pat ← pPattern
  lexSym "="
  let e1 ← pExpr
  lexKw "in"
  let e2 ← pExpr
  return (mkE (Esseq pat e1 e2))

private partial def pExprIf : P Expr' := do
  lexKw "if"
  let pe ← pPexpr
  lexKw "then"
  let e2 ← pExpr
  lexKw "else"
  let e3 ← pExpr
  return (mkE (Eif pe e2 e3))

private partial def pExprCase : P Expr' := do
  lexKw "case"
  let pe ← pPexpr
  lexKw "of"
  let mut pairs := #[]
  while true do
    match ← attempt (some <$> pPatternPair pExpr pPattern) <|> pure none with
    | some p => pairs := pairs.push p
    | none => break
  lexKw "end"
  return (mkE (Ecase pe pairs.toList))

private partial def pExprPcall : P Expr' := do
  lexKw "pcall"
  lexSym "("
  let nm ← pName
  -- Arguments are optional
  let pes ← (attempt (do lexSym ","; sepByComma1 pPexpr)) <|> pure []
  lexSym ")"
  return (mkE (Eproc () nm pes))

private partial def pExprCcall : P Expr' := do
  lexKw "ccall"
  lexSym "("
  let peTy ← pPexpr
  lexSym ","
  let pe ← pPexpr
  let pes ← (attempt (do lexSym ","; sepByComma1 pPexpr)) <|> pure []
  lexSym ")"
  return (mkE (Eccall () peTy pe pes))

private partial def pExprUnseq : P Expr' := do
  lexKw "unseq"
  lexSym "("
  let es ← sepByComma pExpr
  lexSym ")"
  return (mkE (Eunseq es))

private partial def pExprBound : P Expr' := do
  lexKw "bound"
  lexSym "("
  let e ← pExpr
  lexSym ")"
  return (mkE (Ebound e))

private partial def pExprSave : P Expr' := do
  lexKw "save"
  let s ← lexSymId
  lexSym ":"
  let bTy ← pCoreBaseType
  lexSym "("
  let xs ← sepByComma (do
    let s' ← lexSymId
    lexSym ":"
    let bTy' ← pCoreBaseType
    lexSym ":="
    let pe ← pPexpr
    return (s', ((bTy', none), pe)))
  lexSym ")"
  lexKw "in"
  let e ← pExpr
  return (mkE (Esave (s, bTy) xs e))

private partial def pExprRun : P Expr' := do
  lexKw "run"
  let s ← lexSymId
  lexSym "("
  let pes ← sepByComma pPexpr
  lexSym ")"
  return (mkE (Erun () s pes))

private partial def pExprNd : P Expr' := do
  lexKw "nd"
  lexSym "("
  let es ← sepByComma pExpr
  lexSym ")"
  return (mkE (End es))

private partial def pExprPar : P Expr' := do
  lexKw "par"
  lexSym "("
  let es ← sepByComma pExpr
  lexSym ")"
  return (mkE (Epar es))

private partial def pExprNeg : P Expr' := do
  lexKw "neg"
  lexSym "("
  let act ← pAction
  lexSym ")"
  return (mkE (Eaction (Paction Neg0 (Action loc0 () act))))

private partial def pExprAction : P Expr' := do
  let pact ← pPaction
  return (mkE (Eaction pact))

private partial def pExprAtom : P Expr' := do
  -- First-char dispatch to reduce attempt chains
  let c ← peek?
  match c with
  | some '(' => pExprParen
  | some 'u' => (attempt pExprUnseq) <|> pExprAction
  | some 'p' => (attempt pExprPure) <|> (attempt pExprPcall) <|> (attempt pExprPar) <|> pExprAction
  | some 'm' => (attempt pExprMemop) <|> pExprAction
  | some 'l' => (attempt pExprLetWeak) <|> (attempt pExprLetStrong) <|> (attempt pExprLet) <|> pExprAction
  | some 'i' => (attempt pExprIf) <|> pExprAction
  | some 'c' => (attempt pExprCase) <|> (attempt pExprCcall) <|> pExprAction
  | some 'b' => (attempt pExprBound) <|> pExprAction
  | some 's' => (attempt pExprSave) <|> pExprAction
  | some 'r' => (attempt pExprRun) <|> pExprAction
  | some 'n' => (attempt pExprNeg) <|> (attempt pExprNd) <|> pExprAction
  | _ => pExprAction

/- ### Layout-sensitive `;` sequencing (arc-6 S1)

pp_expr prints unit-pattern Esseq as `(pp e1 ^^^ P.semi) ^^ P.hardline
^^ pp e2` (pp_core.ml:648-649) with NO parentheses ever placed around
e1, while Eif/Esave branch bodies are printed under `P.nest 2`
(pp_if/pp_let, pp_core.ml:655-664/619-629). The token stream alone is
therefore ambiguous: in

    if c then
      kill(…) ;
      run l(…)
    else
      pure(Unit) ;
    rest

the `; rest` sequel belongs to the SEQUENCE CONTAINING THE IF, not to
the else branch — distinguishable only by layout: hardline puts every
Esseq sequel on a new line at the SEQUENCE's own indentation, whereas
branch bodies sit strictly deeper (and one-lined groups keep the sequel
on the next line at the outer indent, since hardline never flattens).
A greedy `;` would silently re-associate the rest of a procedure body
into the else branch — wrong AST, wrong execution (found via the libc
fwrite path, arc-6 S1). RULE: a `;`-sequel is consumed only if its
first token's column is ≥ the column at which the current sequence's
first expression started; otherwise the `;` is left for the enclosing
(shallower) sequence. -/

-- Handle semicolon sequencing: e1 ; e2 (layout rule above)
private partial def pExprSeq (startCol : Nat) (lhs : Expr') : P Expr' := do
  let seq ← attempt (do
      lexSym ";"
      let c ← getCol
      if c < startCol then fail "outdented ;-sequel belongs to an enclosing sequence"
      pure true) <|> pure false
  if seq then
    let rhs ← pExpr
    return (mkE (Esseq (Pattern [] (CaseBase (none, BTy_unit))) lhs rhs))
  else return lhs

/-- Parse an effectful expression. -/
partial def pExpr : P Expr' := do
  let col ← getCol
  let lhs ← pExprAtom
  pExprSeq col lhs

end

/-! ## Top-level Declaration Parsers -/

/-- Result of parsing a single declaration.

    `procDecl` carries the optional `[ailname = "..."]` attribute string:
    OCaml's core parser attaches the attribute list to `Proc_decl`
    (core_parser.mly:39, grammar :1804) and registers it in the
    StdMode ailnames map at symbolification (core_parser.mly:1037-1041 →
    `register_ailname`, :157-159). -/
inductive Decl where
  | funDecl : sym → generic_fun_map_decl Unit Unit → Decl
  | procDecl : sym → Option String → generic_fun_map_decl Unit Unit → Decl
  | implDecl : String → generic_impl_decl Unit → Decl
  | globDecl : sym → generic_globs Unit Unit → Decl
  | tagDecl : sym → (CerbLocation.Loc × tag_definition) → Decl
  | builtinDecl : sym → generic_fun_map_decl Unit Unit → Decl

/-- Parse a parameter list: (sym1 : bTy1, sym2 : bTy2, ...) -/
private partial def pParamList : P (List (sym × core_base_type)) := do
  lexSym "("
  let params ← sepByComma (do
    let s ← lexSymId
    lexSym ":"
    let bTy ← pCoreBaseType
    return (s, bTy))
  lexSym ")"
  return params

/-- Parse a single struct/union field: name : 'ctype' (no dot prefix per OCaml grammar) -/
private partial def pDefField : P (identifier × (attributes × Option alignment × qualifiers × ctype)) := do
  let cid ← pCabsId
  lexSym ":"
  let ty ← pCoreCtype
  return (cid, (no_attributes, none, no_qualifiers, ty))

/-- Parse struct/union field definitions. Returns (fields, optional flex member). -/
private partial def pDefFields : P (List (identifier × (attributes × Option alignment × qualifiers × ctype)) × Option flexible_array_member) := do
  let mut fields : List (identifier × (attributes × Option alignment × qualifiers × ctype)) := []
  while true do
    match ← attempt (some <$> pDefField) <|> pure none with
    | some f => fields := fields ++ [f]
    | none => break
  -- Check if last field is a flexible array member
  match fields.getLast? with
  | some (ident, (attrs, _, qs, Ctype _ (Array0 elemTy none))) =>
    let init := fields.dropLast
    return (init, some (FlexibleArrayMember attrs ident qs elemTy))
  | _ => return (fields, none)

/-- Parse a fun declaration. -/
private partial def pFunDecl : P Decl := do
  lexKw "fun"
  -- Check if this is an impl fun (next token is <...>)
  let c? ← peek?
  match c? with
  | some '<' =>
    let iCst ← lexImpl
    let params ← pParamList
    lexSym ":"
    let bTy ← pCoreBaseType
    lexSym ":="
    let body ← pPexpr
    return (Decl.implDecl iCst (IFun bTy params body))
  | _ =>
    let s ← lexSymId
    let params ← pParamList
    lexSym ":"
    let bTy ← pCoreBaseType
    lexSym ":="
    let body ← pPexpr
    return (Decl.funDecl s (Fun bTy params body))

/-- Parse a proc declaration.

    The optional `[ailname = "..."]` attribute is CAPTURED, not discarded:
    it binds a C name to this proc symbol for the stdlib ailnames map
    (OCaml: grammar core_parser.mly:1804 `PROC attrs_opt= attribute?`,
    attribute :1222-1227 = bracketed comma-separated `ailname = "str"`
    pairs; consumed by `hasAilname` :48-52, which takes the HEAD attribute,
    at Proc_decl symbolification :1037-1041). Spacing like `ailname= "x"`
    (std.core:398) is tolerated because lexing skips whitespace. -/
private partial def pProcDecl : P Decl := do
  lexKw "proc"
  -- optional attributes
  let attrs ← (attempt (do
    lexSym "["
    let pairs ← sepByComma (do
      lexKw "ailname"
      lexSym "="
      let s ← lexStr
      return s)
    lexSym "]"
    return pairs)) <|> pure []
  let s ← lexSymId
  -- Bodyless declaration form: `proc name (bTy, ...)` with UNNAMED
  -- parameter types, no return type, no body. This is how pp_core prints
  -- a ProcDecl fun-map entry (pp_core.ml:783-785: symbol + parens'd
  -- comma-list of core_base_types only) — a PP-ONLY form:
  -- core_parser.mly has NO production for it (proc_declaration
  -- :1803-1809 requires named params, `: eff bTy` and a body). The
  -- declared return base type is NOT printed and hence unrecoverable
  -- from text; we record BTy_unit. Consumers never read it: a decl-only
  -- symbol reaching call_proc yields Nothing (core_run.lem:46-51,
  -- ProcDecl is not a Proc), and for def+decl duplicate names
  -- (__strtox/__strtoxd) the loader's fun-map construction lets the
  -- Proc definition win (see Main.loadLibc).
  match ← attempt (some <$> (do
      lexSym "("
      let tys ← sepByComma pCoreBaseType
      lexSym ")"
      -- a following ':' would mean this was really a zero-arg full proc
      match ← peek? with
      | some ':' => fail "full proc, not a decl"
      | _ => pure tys)) <|> pure none with
  | some tys =>
    return (Decl.procDecl s attrs.head? (ProcDecl loc0 BTy_unit tys))
  | none =>
  let params ← pParamList
  lexSym ":"
  lexKw "eff"
  let bTy ← pCoreBaseType
  lexSym ":="
  let body ← pExpr
  -- hasAilname (core_parser.mly:48-52): first attribute wins
  return (Decl.procDecl s attrs.head? (Proc loc0 none bTy params body))

/-- Parse a struct definition: def struct name := fields -/
private partial def pDefStruct : P Decl := do
  lexKw "struct"
  let tag ← lexSymId
  lexSym ":="
  let (fields, flexOpt) ← pDefFields
  return (Decl.tagDecl tag (loc0, StructDef fields flexOpt))

/-- Parse a union definition: def union name := fields -/
private partial def pDefUnion : P Decl := do
  lexKw "union"
  let tag ← lexSymId
  lexSym ":="
  let (fields, _) ← pDefFields
  return (Decl.tagDecl tag (loc0, UnionDef fields))

/-- Parse a def declaration (impl constant or struct/union). -/
private partial def pDefDecl : P Decl := do
  lexKw "def"
  -- Check what follows: <impl>, struct, union
  let c? ← peek?
  match c? with
  | some '<' =>
    let iCst ← lexImpl
    lexSym ":"
    let bTy ← pCoreBaseType
    lexSym ":="
    let body ← pPexpr
    return (Decl.implDecl iCst (Def bTy body))
  | _ =>
    (attempt pDefStruct) <|> pDefUnion

/-- Parse a glob declaration. -/
private partial def pGlobDecl : P Decl := do
  lexKw "glob"
  let s ← lexSymId
  lexSym ":"
  let bTy ← pCoreType
  -- Parse required [ailctype = 'ctype'] attribute
  lexSym "["
  lexKw "ail_ctype"
  lexSym "="
  let ct ← pCoreCtype
  lexSym "]"
  lexSym ":="
  let body ← pExpr
  return (Decl.globDecl s (GlobalDef (bTy, ct) body))

/-- Parse a builtin declaration. -/
private partial def pBuiltinDecl : P Decl := do
  lexKw "builtin"
  let s ← lexSymId
  lexSym "("
  let paramTys ← sepByComma pCoreBaseType
  lexSym ")"
  lexSym ":"
  lexKw "eff"
  let bTy ← pCoreBaseType
  return (Decl.builtinDecl s (BuiltinDecl loc0 bTy paramTys))

/-- Parse a single top-level declaration. -/
private partial def pDeclaration : P Decl :=
      (attempt pFunDecl)
  <|> (attempt pProcDecl)
  <|> (attempt pDefDecl)
  <|> (attempt pGlobDecl)
  <|> (attempt pBuiltinDecl)

/-! ## CoreFile output structure -/

/-- The parsed Core file result.

    `ailnames` mirrors the StdMode symbolify state's ailnames map
    (core_parser.mly:77, returned as `Rstd (st.ailnames, fun_map)`
    :1076-1080): C-name → proc symbol, populated ONLY from `[ailname]`
    attributes on proc declarations (`register_ailname`,
    core_parser.mly:157-159, invoked at :1037-1041). `fun`/`builtin`
    declaration names are never registered. -/
structure CoreFile where
  funs : List (sym × generic_fun_map_decl Unit Unit) := []
  procs : List (sym × generic_fun_map_decl Unit Unit) := []
  impls : List (String × generic_impl_decl Unit) := []
  tagDefs : List (sym × (CerbLocation.Loc × tag_definition)) := []
  globs : List (sym × generic_globs Unit Unit) := []
  builtins : List (sym × generic_fun_map_decl Unit Unit) := []
  ailnames : List (String × sym) := []

/-- Recursive declaration loop — errors propagate immediately (no while-loop swallowing). -/
private partial def pCoreFileGo (result : CoreFile) : P CoreFile := do
  lexWs
  match ← peek? with
  | none => return result  -- EOF
  | some c =>
    let decl ← pDeclaration
    let result := match decl with
      | Decl.funDecl s d => { result with funs := result.funs ++ [(s, d)] }
      | Decl.procDecl s ailname? d =>
        -- register_ailname (core_parser.mly:157-159, called :1037-1041):
        -- only attribute-carrying procs land in ailnames.
        -- DUPLICATE-ailname divergence (arc-5 audit 2, F4,
        -- documented-deliberate): OCaml registers declarations via foldrM
        -- (core_parser.mly:135-137) — the list is folded from the RIGHT,
        -- so on duplicate ailnames the FIRST-in-file registration is
        -- Pmap.add'ed last and WINS. We collect in file order here and
        -- Main.lean builds the map with a foldl fromList, so LAST-in-file
        -- wins. std.core is ailname-duplicate-free (verified), so the
        -- divergence is unreachable today; align only if a real need
        -- appears.
        { result with
          procs := result.procs ++ [(s, d)],
          ailnames := match ailname? with
            | some str => result.ailnames ++ [(str, s)]
            | none => result.ailnames }
      | Decl.implDecl name d => { result with impls := result.impls ++ [(name, d)] }
      | Decl.globDecl s g => { result with globs := result.globs ++ [(s, g)] }
      | Decl.tagDecl s td => { result with tagDefs := result.tagDefs ++ [(s, td)] }
      | Decl.builtinDecl s d => { result with builtins := result.builtins ++ [(s, d)] }
    pCoreFileGo result

/-- Parse all declarations and collect into a CoreFile.
    Dies loudly if any declaration fails to parse. -/
private partial def pCoreFile : P CoreFile :=
  pCoreFileGo {}

/-! ## Entry point -/

/-! ### The symbol-hash collision tripwire (arc-14 S1 F3, sem:G6)

Core-text symbol identity is the name's 64-bit hash (`mkSym` above):
probabilistic injectivity, not an invariant. Lean's `String.hash` is
MurmurHash64A(seed=11), for which collisions are CONSTRUCTIBLE — the
arc-14 S0 probe (tests/immaculate/g6-hash-collision.lean) exhibits an
identifier-charset pair — so "distinct names get distinct numbers" is a
margin. The scan below makes the margin FAIL-CLOSED, in the
CERB_FRESH_BASE floor-probe pattern: before parsing, every
identifier-shaped token in the input (comments and quoted strings
skipped — the lexical classes lexWs and the string lexer consume) is
hashed; two DISTINCT names with EQUAL hash abort the parse loudly.
Sound over-approximation: every identifier the parser interns is such a
token — including the SUFFIX-STRIPPED tag names minted via
`mkSym (stripRawSymSuffix tag)`, whose stripped form is scanned
alongside the raw token (R1, arc-14 re-mark); the extra tokens scanned
(keywords, impl-constant bodies) only make the check stricter.
SCOPE (the second-preimage boundary, stated precisely): the tripwire
quantifies over ONE parseFile input — it rules out silent conflation
WITHIN each scanned file. A hash second preimage split ACROSS parseFile
calls (a name in std.core colliding with a different name in libc.core
or a TU) is outside this scan's premise; it is covered only by the
64-bit margin plus the fact that cross-file symbol AGREEMENT is
by-name interning (same name = same hash is intended there). Residual
envelope (documented, accepted): `internSym` calls that rekey
oracle-side metadata names (Main.loadLibc) are covered only insofar as
those names also appear in a scanned file — they do, by construction:
metadata names rekey onto symbols of parsed dumps. -/

private structure ScanSt where
  seen : Std.HashMap UInt64 String := {}
  collision : Option (String × String) := none
  deriving Inhabited

/-- Skip a block comment body to past `-}` (no nesting, matching the
    lexer); structural recursion. -/
private def scanToBlockClose : List Char → List Char
  | [] => []
  | '-' :: '}' :: r => r
  | _ :: r => scanToBlockClose r

/-- Skip a string-literal body to past the closing quote (honoring
    backslash escapes); structural recursion. -/
private def scanToQuote : List Char → List Char
  | [] => []
  | '\\' :: [] => []
  | '\\' :: _ :: r => scanToQuote r
  | '"' :: r => r
  | _ :: r => scanToQuote r

/-- One scanner step, fuel-totalized (house pattern): every step consumes
    at least one char, so fuel = input length + 1 can never exhaust; the
    exhaustion arm is a loud panic, not a silent pass. -/
private def scanStep (fuel : Nat) (st : ScanSt) (l : List Char) : ScanSt :=
  match fuel with
  | 0 => panic! "CoreParser.scanHashCollisions: fuel exhausted (unreachable: fuel = input length + 1)"
  | fuel + 1 =>
    match l with
    | [] => st
    | '-' :: '-' :: rest =>
      scanStep fuel st (rest.dropWhile (· != '\n'))     -- line comment
    | '{' :: '-' :: rest =>
      scanStep fuel st (scanToBlockClose rest)          -- block comment
    | '"' :: rest =>
      scanStep fuel st (scanToQuote rest)               -- string literal
    | c :: rest =>
      if isIdentStart c then
        let tok : String := (c :: rest.takeWhile isIdentCont).asString
        let rest' := rest.dropWhile isIdentCont
        -- R1 (arc-14 re-mark, professor A): the parser ALSO interns
        -- SUFFIX-STRIPPED names (mkSym (stripRawSymSuffix tag) on
        -- struct/union tags), so a raw token can mint a SECOND hash the
        -- raw-token scan alone would never see — both forms enter the
        -- seen-map.
        let checkOne (st : ScanSt) (t : String) : ScanSt :=
          match st.seen.get? t.hash with
          | some prev =>
            if prev != t && st.collision.isNone then
              { st with collision := some (prev, t) }
            else st
          | none => { st with seen := st.seen.insert t.hash t }
        let stripped := stripRawSymSuffix tok
        let st := checkOne st tok
        let st := if stripped == tok then st else checkOne st stripped
        scanStep fuel st rest'
      else if isIdentCont c then
        -- digit-led runs (number literals): consume the whole run so a
        -- trailing letter is not misread as an identifier start
        scanStep fuel st (rest.dropWhile isIdentCont)
      else
        scanStep fuel st rest

/-- Scan the whole input; `some (a, b)` = two distinct identifiers with
    colliding hashes (symbol conflation would be silent — fail-stop). -/
private def scanHashCollisions (input : String) : Option (String × String) :=
  (scanStep (input.length + 1) {} input.toList).collision

/-- Parse a .core file and return a CoreFile with all declarations.
    Fails if parsing produces an error or if a non-empty file yields zero
    declarations. FAIL-STOPS (arc-14 F3, sem:G6) if the input contains
    two distinct hash-colliding identifiers — see the tripwire note
    above. -/
def parseFile (input : String) : Except String CoreFile :=
  match scanHashCollisions input with
  | some (a, b) =>
    .error s!"SYMBOL-HASH COLLISION (fail-stop): distinct Core identifiers '{a}' and '{b}' share String.hash {a.hash}; CoreParser symbol identity (mkSym) would silently conflate them (arc-14 F3 tripwire, cf. the CERB_FRESH_BASE floor probe)"
  | none =>
    match pCoreFile.run input with
    | .ok cf => .ok cf
    | .error e => .error s!"parse error: {e}"

/-! ## Library-file location stamping (zero-discrepancy Z-01, noodle D1)

The OCaml Core parser stamps every node of a parsed `.core` file with a
region located IN that file: `core_parser.mly:1571` `Aloc (region
($startpos, $endpos) NoCursor)` / `PEundef (region …, ub)`, `:1744/1746`
`Action (region …)`, and the `decl_loc`s of `Proc`/`ProcDecl`/tag
definitions. std.core is loaded from `Cerb_runtime.in_runtime
"libcore/std.core"`, so `Loc.is_library_location` holds for its nodes and
the shared model (a) substitutes the enclosing C location for a
library-located UB (`core_eval.lem:602`, `core_run.lem:476`) and (b)
refuses to overwrite a thread's `current_loc` with a library location
(`core_run.lem:781`). This parser stamped `Loc.unknown` everywhere
(`loc0`/`annots0`), so `isLibraryLocation` was false, (a) kept `unknown`
and (b) overwrote `current_loc` with `unknown` whenever std.core code ran:
every UB raised while executing std.core — UB017 (`loaded_ivfromfloat`),
the printf family (UB153a/b, UB158), the free proxy's UB179*, the 47
`undef(<<DUMMY>>)` sites, every memory-op UB inside a std.core proc —
reported `unknown location` where the oracle reports the C site.

`stampLibraryFile` is the post-parse mirror: every `Aloc unknown`,
`PEundef unknown`, `Action unknown`, `Proc`/`ProcDecl`/`BuiltinDecl` loc
and tag-definition loc of the parsed file becomes `Loc.region p p
.noCursor` with `p` in `file`. DOCUMENTED DIVERGENCE (deliberate, in the
Pos payload only): line and column are NOT tracked — the Parsec iterator
carries no line table and this parse is on every driver run's hot path —
so `p = ⟨file, 0, 0⟩`. Only the FILE component is behaviour-bearing:
`is_library_location` tests the path's directory alone
(`util/cerb_location.ml:512-520`), every execution-path consumer of a
library-located loc dispatches on that predicate (the three cites above),
and no std.core position is ever printed on the batch path. Not stamped:
`Symbol.Identifier` locs inside member names/ctypes (never consulted on an
execution path). `--libc` bodies are NOT stamped (the oracle's libc.co
carries the libc C-source locations, which the Core text dump does not
preserve — a separate, recorded gap: UB raised inside a libc body prints
`unknown location` on Lean; both sides classify those locs non-library).
-/

private def libLoc (file : String) : CerbLocation.Loc :=
  let p : CerbLocation.Pos := { file := file, line := 0, col := 0 }
  .region p p .noCursor

private def relocLoc (file : String) : CerbLocation.Loc → CerbLocation.Loc
  | .unknown => libLoc file
  | l => l

private def relocAnnots (file : String) (annots : List annot) : List annot :=
  annots.map fun a => match a with
    | Aloc l => Aloc (relocLoc file l)
    | a => a

private partial def relocPat (file : String) : Pat → Pat
  | Pattern annots pat_ =>
    Pattern (relocAnnots file annots) (match pat_ with
      | CaseBase x => CaseBase x
      | CaseCtor c pats => CaseCtor c (pats.map (relocPat file)))

private partial def relocPE (file : String) : PE → PE
  | Pexpr annots bty pe_ =>
    let r := relocPE file
    Pexpr (relocAnnots file annots) bty (match pe_ with
      | PEsym s => PEsym s
      | PEimpl c => PEimpl c
      | PEval v => PEval v
      | PEconstrained xs => PEconstrained (xs.map fun (c, pe) => (c, r pe))
      | PEundef loc ub => PEundef (relocLoc file loc) ub
      | PEerror str pe => PEerror str (r pe)
      | PEctor c pes => PEctor c (pes.map r)
      | PEcase pe alts => PEcase (r pe) (alts.map fun (pat, pe) => (relocPat file pat, r pe))
      | PEarray_shift pe1 ty pe2 => PEarray_shift (r pe1) ty (r pe2)
      | PEmember_shift pe s id => PEmember_shift (r pe) s id
      | PEmemop op pes => PEmemop op (pes.map r)
      | PEnot pe => PEnot (r pe)
      | PEop op pe1 pe2 => PEop op (r pe1) (r pe2)
      | PEconv_int ity pe => PEconv_int ity (r pe)
      | PEwrapI ity iop pe1 pe2 => PEwrapI ity iop (r pe1) (r pe2)
      | PEcatch_exceptional_condition ity iop pe1 pe2 =>
        PEcatch_exceptional_condition ity iop (r pe1) (r pe2)
      | PEstruct s fields => PEstruct s (fields.map fun (id, pe) => (id, r pe))
      | PEunion s id pe => PEunion s id (r pe)
      | PEcfunction pe => PEcfunction (r pe)
      | PEmemberof s id pe => PEmemberof s id (r pe)
      | PEcall nm pes => PEcall nm (pes.map r)
      | PElet pat pe1 pe2 => PElet (relocPat file pat) (r pe1) (r pe2)
      | PEif pe1 pe2 pe3 => PEif (r pe1) (r pe2) (r pe3)
      | PEis_scalar pe => PEis_scalar (r pe)
      | PEis_integer pe => PEis_integer (r pe)
      | PEis_signed pe => PEis_signed (r pe)
      | PEis_unsigned pe => PEis_unsigned (r pe)
      | PEbmc_assume pe => PEbmc_assume (r pe)
      | PEare_compatible pe1 pe2 => PEare_compatible (r pe1) (r pe2))

private def relocAct (file : String) (act : Act) : Act :=
  let r := relocPE file
  match act with
  | Create pe1 pe2 pref => Create (r pe1) (r pe2) pref
  | CreateReadOnly pe1 pe2 pe3 pref => CreateReadOnly (r pe1) (r pe2) (r pe3) pref
  | Alloc0 pe1 pe2 pref => Alloc0 (r pe1) (r pe2) pref
  | Kill k pe => Kill k (r pe)
  | Store0 b pe1 pe2 pe3 mo => Store0 b (r pe1) (r pe2) (r pe3) mo
  | Load0 pe1 pe2 mo => Load0 (r pe1) (r pe2) mo
  | SeqRMW b pe1 pe2 s pe3 => SeqRMW b (r pe1) (r pe2) s (r pe3)
  | RMW0 pe1 pe2 pe3 pe4 mo1 mo2 => RMW0 (r pe1) (r pe2) (r pe3) (r pe4) mo1 mo2
  | Fence0 mo => Fence0 mo
  | CompareExchangeStrong pe1 pe2 pe3 pe4 mo1 mo2 =>
    CompareExchangeStrong (r pe1) (r pe2) (r pe3) (r pe4) mo1 mo2
  | CompareExchangeWeak pe1 pe2 pe3 pe4 mo1 mo2 =>
    CompareExchangeWeak (r pe1) (r pe2) (r pe3) (r pe4) mo1 mo2
  | LinuxFence mo => LinuxFence mo
  | LinuxLoad pe1 pe2 mo => LinuxLoad (r pe1) (r pe2) mo
  | LinuxStore pe1 pe2 pe3 mo => LinuxStore (r pe1) (r pe2) (r pe3) mo
  | LinuxRMW pe1 pe2 pe3 mo => LinuxRMW (r pe1) (r pe2) (r pe3) mo

private def relocAction (file : String) : generic_action Unit Unit sym → generic_action Unit Unit sym
  | Action loc a act => Action (relocLoc file loc) a (relocAct file act)

private partial def relocE (file : String) : Expr' → Expr'
  | Expr annots e_ =>
    let r := relocE file
    let rp := relocPE file
    Expr (relocAnnots file annots) (match e_ with
      | Epure pe => Epure (rp pe)
      | Ememop op pes => Ememop op (pes.map rp)
      | Eaction (Paction pol act) => Eaction (Paction pol (relocAction file act))
      | Ecase pe alts => Ecase (rp pe) (alts.map fun (pat, e) => (relocPat file pat, r e))
      | Elet pat pe e => Elet (relocPat file pat) (rp pe) (r e)
      | Eif pe e1 e2 => Eif (rp pe) (r e1) (r e2)
      | Eccall a pe1 pe2 pes => Eccall a (rp pe1) (rp pe2) (pes.map rp)
      | Eproc a nm pes => Eproc a nm (pes.map rp)
      | Eunseq es => Eunseq (es.map r)
      | Ewseq pat e1 e2 => Ewseq (relocPat file pat) (r e1) (r e2)
      | Esseq pat e1 e2 => Esseq (relocPat file pat) (r e1) (r e2)
      | Ebound e => Ebound (r e)
      | End es => End (es.map r)
      | Esave sb params e =>
        Esave sb (params.map fun (s, (tyinfo, pe)) => (s, (tyinfo, rp pe))) (r e)
      | Erun a s pes => Erun a s (pes.map rp)
      | Epar es => Epar (es.map r)
      | Ewait tid => Ewait tid
      | Eannot dyns e => Eannot dyns (r e)
      | Eexcluded n act => Eexcluded n (relocAction file act))

private def relocFunDecl (file : String) : generic_fun_map_decl Unit Unit → generic_fun_map_decl Unit Unit
  | Fun bty params pe => Fun bty params (relocPE file pe)
  | Proc loc me bty params e => Proc (relocLoc file loc) me bty params (relocE file e)
  | ProcDecl loc bty tys => ProcDecl (relocLoc file loc) bty tys
  | BuiltinDecl loc bty tys => BuiltinDecl (relocLoc file loc) bty tys

private def relocImplDecl (file : String) : generic_impl_decl Unit → generic_impl_decl Unit
  | Def bty pe => Def bty (relocPE file pe)
  | IFun bty params pe => IFun bty params (relocPE file pe)

private def relocGlob (file : String) : generic_globs Unit Unit → generic_globs Unit Unit
  | GlobalDef tys e => GlobalDef tys (relocE file e)
  | GlobalDecl tys => GlobalDecl tys

/-- Stamp every unknown location of a parsed file with a region in `file`
    (see the section comment). -/
def stampLibraryFile (file : String) (cf : CoreFile) : CoreFile :=
  let fd := fun (p : sym × generic_fun_map_decl Unit Unit) => (p.1, relocFunDecl file p.2)
  { cf with
    funs := cf.funs.map fd
    procs := cf.procs.map fd
    builtins := cf.builtins.map fd
    impls := cf.impls.map fun (n, d) => (n, relocImplDecl file d)
    tagDefs := cf.tagDefs.map fun (s, (loc, td)) => (s, (relocLoc file loc, td))
    globs := cf.globs.map fun (s, g) => (s, relocGlob file g) }

/-- Parse a LIBRARY `.core`/`.impl` file loaded from `file` (the runtime
    tree: std.core, the impl file) and stamp its nodes with that file
    — the mirror of the OCaml parser's `region ($startpos, $endpos)` at the
    granularity that is behaviour-bearing (the section comment). -/
def parseLibraryFile (file : String) (input : String) : Except String CoreFile :=
  (parseFile input).map (stampLibraryFile file)

/-- Parse a .core file and return a human-readable summary. -/
def parseFileSummary (input : String) : Except String String :=
  match parseFile input with
  | .ok cf =>
    let nFun := cf.funs.length
    let nProc := cf.procs.length
    let nImpl := cf.impls.length
    let nTag := cf.tagDefs.length
    let nGlob := cf.globs.length
    let nBuiltin := cf.builtins.length
    .ok s!"Core file: {nFun} fun, {nProc} proc, {nImpl} def/impl, {nTag} struct/union, {nGlob} glob, {nBuiltin} builtin"
  | .error e => .error e

end CoreParser
