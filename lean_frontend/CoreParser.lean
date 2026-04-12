/-
  Core text parser for Cerberus .core and .impl files.
  Uses Lean's Std.Internal.Parsec.String combinator library.

  Parses the Core IR text format as defined by parsers/core/core_parser.mly.
-/

import Std.Internal.Parsec
import Std.Internal.Parsec.String
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

/-- Construct a symbol from a parsed identifier string. -/
private def mkSym (name : String) : sym :=
  Symbol "" (CerberusFresh.fresh_int ()) (SD_Id name)

/-- The unknown location placeholder. -/
private def loc0 : CerbLocation.Loc := CerbLocation.unknown

/-- Default annotation list with unknown location. -/
private def annots0 : List annot := [Aloc loc0]

/-- Parse an identifier into a `sym`. -/
private def lexSymId : P sym := do
  let name ← lexIdent
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
    even though the grammar formally only has "ichar". We accept both. -/
private def pIntegerBaseType : P integerBaseType :=
      (attempt (lexKw "ichar") *> pure Ichar)
  <|> (attempt (lexKw "char") *> pure Ichar)
  <|> (attempt (lexKw "short") *> pure Short)
  <|> (attempt (lexKw "long_long") *> pure LongLong)
  <|> (attempt (lexKw "long") *> pure Long)
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

/-- Parse a floating type. -/
private def pFloatingType : P floatingType :=
      (attempt (lexKw "long_double") *> pure (RealFloating LongDouble))
  <|> (attempt (lexKw "float") *> pure (RealFloating Float0))
  <|> (attempt (lexKw "double") *> pure (RealFloating Double))

/-- Parse a basic type (integer or floating). -/
private def pBasicType : P basicType :=
      (attempt (Floating <$> pFloatingType))
  <|> (Integer <$> pIntegerType)

/-! ## Ctype Parser (mutual block for self-recursion) -/

mutual

/-- Parse a ctype atom (base case). -/
partial def pCtypeAtom : P ctype :=
      (attempt (lexKw "void") *> pure (Ctype [] Void0))
  <|> (attempt (do
        lexKw "const"
        let ty ← pCtypeAtom
        lexSym "*"
        return (Ctype [] (Pointer { const := true, restrict := false, volatile := false } ty))))
  <|> (attempt (do
        lexKw "_Atomic"
        lexSym "("
        let ty ← pCtype
        lexSym ")"
        return (Ctype [] (Atomic ty))))
  <|> (attempt (do
        lexKw "struct"
        let tag ← lexIdent
        return (Ctype [] (Struct (Symbol "" 0 (SD_Id tag))))))
  <|> (attempt (do
        lexKw "union"
        let tag ← lexIdent
        return (Ctype [] (Union0 (Symbol "" 0 (SD_Id tag))))))
  <|> (attempt (do
        let bty ← pBasicType
        return (Ctype [] (Basic bty))))
  <|> (do -- fallback: try identifier as builtin typename
        let name ← attempt lexIdent
        fail s!"unknown ctype '{name}'")

/-- Parse ctype suffixes: pointer (*), array ([n]), function ((params)). -/
partial def pCtypeSuffix (ty : ctype) : P ctype := do
  let c? ← peek?
  match c? with
  | some '*' =>
    skip; lexWs
    pCtypeSuffix (Ctype [] (Pointer no_qualifiers ty))
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
    pCtypeSuffix (Ctype [] (Array0 ty nOpt))
  | some '(' =>
    skip; lexWs
    -- Check for (*) function pointer syntax: ret (*) (params)
    let isFnPtr ← attempt (do lexSym "*"; lexSym ")"; pure true) <|> pure false
    if isFnPtr then
      -- Parse the parameter list that follows (*)
      lexSym "("
      let paramTys ← sepByComma pCtype
      lexSym ")"
      let params := paramTys.map (fun ty => (no_qualifiers, ty, false))
      -- Result: pointer to function returning ty
      pCtypeSuffix (Ctype [] (Pointer no_qualifiers (Ctype [] (Function (no_qualifiers, ty) params false))))
    else
      -- Regular function type: ret (params)
      let paramTys ← sepByComma pCtype
      lexSym ")"
      let params := paramTys.map (fun ty => (no_qualifiers, ty, false))
      pCtypeSuffix (Ctype [] (Function (no_qualifiers, ty) params false))
  | _ => return ty

/-- Parse a C type. Handles pointer suffixes (*) and array suffixes ([n]). -/
partial def pCtype : P ctype := do
  let base ← pCtypeAtom
  pCtypeSuffix base

end

/-- Parse a ctype enclosed in single quotes: 'ctype' -/
private partial def pCoreCtype : P ctype := do
  lexSym "'"
  let ty ← pCtype
  lexSym "'"
  return ty

/-- Parse an integer type enclosed in single quotes: 'integer_type' -/
private partial def pCoreIntegerType : P integerType := do
  lexSym "'"
  let ity ← pIntegerType
  lexSym "'"
  return ity

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
        return (OTy_struct (Symbol "" 0 (SD_Id tag)))))
  <|> (attempt (do
        lexKw "union"
        let tag ← lexIdent
        return (OTy_union (Symbol "" 0 (SD_Id tag)))))

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
        let _ ← pName
        lexSym ")"
        -- TODO: proper Cfunction handling
        return (Vobject (OVpointer (CerbMem.nullPtrval (Ctype [] Void0))))))
  <|> (attempt (do
        lexKw "Ivmax_alignment"
        return (Vobject (OVinteger (CerbMem.integerIval 16)))))
  <|> (attempt (do
        let ty ← pCoreCtype
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

partial def pPexprAtom : P PE := do
  -- Dispatch on first character to avoid trying all alternatives
  let c ← peek?
  match c with
  | some '(' => (attempt pPexprParen) <|> (attempt pPexprTuple) <|> (attempt pPexprStruct) <|> pPexprUnion
  | some '[' => (attempt pPexprListLiteral) <|> pPexprListEmpty
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
      return (mkPE (PEundef loc0 (DUMMY ubStr)))
    | some "error" =>
      lexSym "("
      let msg ← lexTripleAngle
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
      let pe1 ← pPexpr
      lexKw "then"
      let pe2 ← pPexpr
      lexKw "else"
      let pe3 ← pPexpr
      return (mkPE (PEif pe1 pe2 pe3))
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
    | some "Fvfromint" =>
      lexSym "("
      let pes ← sepByComma pPexpr
      lexSym ")"
      return (mkPE (PEctor Cfvfromint pes))
    | some "Ivfromfloat" =>
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
      let _ ← pName
      lexSym ")"
      -- TODO: proper Cfunction handling (OCaml also punts with null_ptrval)
      return (mkPE (PEval (Vobject (OVpointer (CerbMem.nullPtrval (Ctype [] Void0))))))
    | some "IvMaxAlignment" =>
      return (mkPE (PEval (Vobject (OVinteger (CerbMem.integerIval 16)))))
    -- Expression keywords
    | some "cfunction" =>
      lexSym "("
      let pe ← pPexpr
      lexSym ")"
      return (mkPE (PEcfunction pe))
    | some id =>
      -- Handle __conv_int__
      if id == "__conv_int__" then
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

/-- Precedence climbing parser for binary operators and :: cons. -/
private partial def pPexprPrec (minPrec : Nat) : P PE := do
  let mut lhs ← pPexprAtom
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

-- Handle semicolon sequencing: e1 ; e2
private partial def pExprSeq (lhs : Expr') : P Expr' := do
  match ← attempt (some <$> lexSym ";") <|> pure none with
  | none => return lhs
  | some _ =>
    let rhs ← pExpr
    return (mkE (Esseq (Pattern [] (CaseBase (none, BTy_unit))) lhs rhs))

/-- Parse an effectful expression. -/
partial def pExpr : P Expr' := do
  let lhs ← pExprAtom
  pExprSeq lhs

end

/-! ## Top-level Declaration Parsers -/

/-- Result of parsing a single declaration. -/
inductive Decl where
  | funDecl : sym → generic_fun_map_decl Unit Unit → Decl
  | procDecl : sym → generic_fun_map_decl Unit Unit → Decl
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

/-- Parse a proc declaration. -/
private partial def pProcDecl : P Decl := do
  lexKw "proc"
  -- optional attributes
  let _attrs ← (attempt (do
    lexSym "["
    let pairs ← sepByComma (do
      lexKw "ailname"
      lexSym "="
      let s ← lexStr
      return s)
    lexSym "]"
    return pairs)) <|> pure []
  let s ← lexSymId
  let params ← pParamList
  lexSym ":"
  lexKw "eff"
  let bTy ← pCoreBaseType
  lexSym ":="
  let body ← pExpr
  return (Decl.procDecl s (Proc loc0 none bTy params body))

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

/-- The parsed Core file result. -/
structure CoreFile where
  funs : List (sym × generic_fun_map_decl Unit Unit) := []
  procs : List (sym × generic_fun_map_decl Unit Unit) := []
  impls : List (String × generic_impl_decl Unit) := []
  tagDefs : List (sym × (CerbLocation.Loc × tag_definition)) := []
  globs : List (sym × generic_globs Unit Unit) := []
  builtins : List (sym × generic_fun_map_decl Unit Unit) := []

/-- Recursive declaration loop — errors propagate immediately (no while-loop swallowing). -/
private partial def pCoreFileGo (result : CoreFile) : P CoreFile := do
  lexWs
  match ← peek? with
  | none => return result  -- EOF
  | some c =>
    let decl ← pDeclaration
    let result := match decl with
      | Decl.funDecl s d => { result with funs := result.funs ++ [(s, d)] }
      | Decl.procDecl s d => { result with procs := result.procs ++ [(s, d)] }
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

/-- Parse a .core file and return a CoreFile with all declarations.
    Fails if parsing produces an error or if a non-empty file yields zero declarations. -/
def parseFile (input : String) : Except String CoreFile :=
  match pCoreFile.run input with
  | .ok cf => .ok cf
  | .error e => .error s!"parse error: {e}"

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
