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
private def isIdentCont (c : Char) : Bool := c.isAlphanum || c == '_' || c == '\''

/-- Skip line comment (-- to end of line) -/
partial def skipLineComment : P Unit := do
  match ← peek? with
  | some '\n' | none => return
  | _ => skip; skipLineComment

/-- Skip block comment ({- ... -}) with nesting -/
partial def skipBlockComment : P Unit := do
  match ← peek? with
  | none => fail "unterminated block comment"
  | some '-' => skip; match ← peek? with
    | some '}' => skip
    | _ => skipBlockComment
  | some '{' => skip; match ← peek? with
    | some '-' => skip; skipBlockComment; skipBlockComment
    | _ => skipBlockComment
  | _ => skip; skipBlockComment

/-- Skip whitespace and comments -/
partial def lexWs : P Unit := do
  ws
  match ← peek? with
  | some '-' =>
    skip
    match ← peek? with
    | some '-' => skip; skipLineComment; lexWs
    | _ => return  -- just a minus sign, put back handled by attempt
  | some '{' =>
    skip
    match ← peek? with
    | some '-' => skip; skipBlockComment; lexWs
    | _ => return
  | _ => return

/-- Parse an identifier -/
def lexIdent : P String := do
  let c ← satisfy isIdentStart
  let rest ← manyChars (satisfy isIdentCont)
  let name := String.mk [c] ++ rest
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

/-- Parse an integer literal -/
def lexInt : P Int := do
  let neg ← match ← peek? with
    | some '-' => skip; pure true
    | _ => pure false
  let digits ← many1Chars digit
  lexWs
  let n := digits.foldl (fun acc c => acc * 10 + (c.toNat - '0'.toNat)) 0
  return if neg then -↑n else ↑n

/-- Parse a double-quoted string -/
partial def lexStr : P String := do
  skipChar '"'
  go ""
where
  go (acc : String) : P String := do
    let c ← any
    if c == '"' then lexWs; return acc
    else if c == '\\' then
      let c2 ← any
      let esc := match c2 with
        | 'n' => '\n' | 't' => '\t' | '\\' => '\\' | '"' => '"' | c => c
      go (acc.push esc)
    else go (acc.push c)

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

/-! ## Entry point -/

private partial def skipBody : P Unit := do
  match ← peek? with
  | none => return
  | some '\n' =>
    skip
    match ← peek? with
    | none => return
    | some c =>
      if isIdentStart c then return  -- next top-level declaration
      else skipBody
  | _ => skip; skipBody

private partial def countDecls (nFun nProc nDef nOther : Nat) : P String := do
  lexWs
  match ← peek? with
  | none => return s!"Core file: {nFun} fun, {nProc} proc, {nDef} def, {nOther} other"
  | _ =>
    match ← attempt (some <$> lexIdent) <|> (skip *> pure none) with
    | some "fun" => skipBody; countDecls (nFun + 1) nProc nDef nOther
    | some "proc" => skipBody; countDecls nFun (nProc + 1) nDef nOther
    | some "def" => skipBody; countDecls nFun nProc (nDef + 1) nOther
    | some "glob" => skipBody; countDecls nFun nProc nDef (nOther + 1)
    | some "builtin" => skipBody; countDecls nFun nProc nDef (nOther + 1)
    | some "struct" => skipBody; countDecls nFun nProc nDef (nOther + 1)
    | some "union" => skipBody; countDecls nFun nProc nDef (nOther + 1)
    | _ => countDecls nFun nProc nDef nOther

/-- Parse a .core file and return summary info.
    Full AST construction will be added incrementally. -/
def parseFile (input : String) : Except String String :=
  (countDecls 0 0 0 0).run input

end CoreParser
