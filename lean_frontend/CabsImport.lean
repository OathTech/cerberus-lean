/-
  Cabs JSON deserializer: converts JSON (from cerberus --cabs-json) to Cabs types.

  Schema (matching backend/lean_export/cabs_json.ml):
  - Nullary constructors: JSON string "Name"
  - Non-nullary constructors: {"tag": "Name", "field1": val, ...}
  - Options: null or value
  - Lists: JSON arrays
  - Tuples: JSON arrays
  - Strings: JSON strings
  - Integers: JSON strings (arbitrary precision)
  - Bools: JSON bools
  - Locations: Cerb_location.to_json format
-/

import Lean.Data.Json
import Cabs
import CerbLocation

open Lean (Json ToJson FromJson)

set_option autoImplicit true

namespace CabsImport

/-! ## JSON helpers -/

def err (ctx : String) (msg : String) : Except String α :=
  .error s!"{ctx}: {msg}"

def getField (j : Json) (field : String) : Except String Json :=
  match j with
  | .obj m =>
    let rec findKey : List (String × Json) → Option Json
      | [] => none
      | (k, v) :: rest => if k == field then some v else findKey rest
    match findKey m.toList with
    | some v => .ok v
    | none => err "getField" s!"missing field '{field}'"
  | _ => err "getField" "expected object"

def getTag (j : Json) : Except String String :=
  match j with
  | .str s => .ok s  -- nullary constructor
  | .obj _ => do
    let tag ← getField j "tag"
    match tag with
    | .str s => .ok s
    | _ => err "getTag" "tag field is not a string"
  | _ => err "getTag" s!"expected string or object, got {j}"

def getStr (j : Json) : Except String String :=
  match j with
  | .str s => .ok s
  | _ => err "getStr" s!"expected string, got {j}"

def getInt (j : Json) : Except String Int :=
  match j with
  | .str s => match s.toInt? with
    | some n => .ok n
    | none => err "getInt" s!"invalid integer string: {s}"
  | .num n => .ok n.toFloat.toUInt64.toNat  -- fallback for small ints
  | _ => err "getInt" s!"expected integer string, got {j}"

def getNat (j : Json) : Except String Nat :=
  match j with
  | .num n => .ok n.toFloat.toUInt64.toNat
  | .str s => match s.toNat? with
    | some n => .ok n
    | none => err "getNat" s!"invalid nat string: {s}"
  | _ => err "getNat" s!"expected nat, got {j}"

def getBool (j : Json) : Except String Bool :=
  match j with
  | .bool b => .ok b
  | _ => err "getBool" s!"expected bool, got {j}"

def getArr (j : Json) : Except String (Array Json) :=
  match j with
  | .arr a => .ok a
  | _ => err "getArr" s!"expected array, got {j}"

def getOption (f : Json → Except String α) (j : Json) : Except String (Option α) :=
  match j with
  | .null => .ok none
  | _ => do let v ← f j; .ok (some v)

def getList (f : Json → Except String α) (j : Json) : Except String (List α) :=
  do let arr ← getArr j; arr.toList.mapM f

/-! ## Location deserialization -/

-- Match Cerb_location.to_json format
def jsonToLoc (j : Json) : Except String CerbLocation.Loc :=
  -- For now, use unknown — proper location parsing can be added later
  .ok CerbLocation.unknown

/-! ## Identifier -/

def jsonToIdentifier (j : Json) : Except String identifier := do
  let loc ← jsonToLoc (← getField j "loc")
  let name ← getStr (← getField j "name")
  .ok (Identifier loc name)

/-! ## Simple enums -/

def jsonToIntegerSuffix (j : Json) : Except String cabs_integer_suffix := do
  match ← getTag j with
  | "CabsSuffix_U" => .ok .CabsSuffix_U
  | "CabsSuffix_UL" => .ok .CabsSuffix_UL
  | "CabsSuffix_ULL" => .ok .CabsSuffix_ULL
  | "CabsSuffix_L" => .ok .CabsSuffix_L
  | "CabsSuffix_LL" => .ok .CabsSuffix_LL
  | t => err "jsonToIntegerSuffix" s!"unknown tag: {t}"

def jsonToFloatingSuffix (j : Json) : Except String cabs_floating_suffix := do
  match ← getTag j with
  | "CabsFloatingSuffix_F" => .ok .CabsFloatingSuffix_F
  | "CabsFloatingSuffix_L" => .ok .CabsFloatingSuffix_L
  | t => err "jsonToFloatingSuffix" s!"unknown tag: {t}"

def jsonToCharacterPrefix (j : Json) : Except String cabs_character_prefix := do
  match ← getTag j with
  | "CabsPrefix_L" => .ok .CabsPrefix_L
  | "CabsPrefix_u" => .ok .CabsPrefix_u
  | "CabsPrefix_U" => .ok .CabsPrefix_U
  | t => err "jsonToCharacterPrefix" s!"unknown tag: {t}"

def jsonToEncodingPrefix (j : Json) : Except String cabs_encoding_prefix := do
  match ← getTag j with
  | "CabsEncPrefix_u8" => .ok .CabsEncPrefix_u8
  | "CabsEncPrefix_u" => .ok .CabsEncPrefix_u
  | "CabsEncPrefix_U" => .ok .CabsEncPrefix_U
  | "CabsEncPrefix_L" => .ok .CabsEncPrefix_L
  | t => err "jsonToEncodingPrefix" s!"unknown tag: {t}"

/-! ## Constants -/

def jsonToIntegerConstant (j : Json) : Except String cabs_integer_constant := do
  let arr ← getArr j
  if h : arr.size = 2 then
    let s ← getStr arr[0]
    let suffix ← getOption jsonToIntegerSuffix arr[1]
    .ok (s, suffix)
  else err "jsonToIntegerConstant" "expected 2-element array"

def jsonToFloatingConstant (j : Json) : Except String cabs_floating_constant := do
  let arr ← getArr j
  if h : arr.size = 2 then
    let s ← getStr arr[0]
    let suffix ← getOption jsonToFloatingSuffix arr[1]
    .ok (s, suffix)
  else err "jsonToFloatingConstant" "expected 2-element array"

def jsonToCharacterConstant (j : Json) : Except String cabs_character_constant := do
  let arr ← getArr j
  if h : arr.size = 2 then
    let pfx ← getOption jsonToCharacterPrefix arr[0]
    let s ← getStr arr[1]
    .ok (pfx, s)
  else err "jsonToCharacterConstant" "expected 2-element array"

def jsonToConstant (j : Json) : Except String cabs_constant := do
  match ← getTag j with
  | "CabsInteger_const" => .ok (.CabsInteger_const (← jsonToIntegerConstant (← getField j "val")))
  | "CabsFloating_const" => .ok (.CabsFloating_const (← jsonToFloatingConstant (← getField j "val")))
  | "CabsCharacter_const" => .ok (.CabsCharacter_const (← jsonToCharacterConstant (← getField j "val")))
  | t => err "jsonToConstant" s!"unknown tag: {t}"

def jsonToStringLiteral (j : Json) : Except String cabs_string_literal := do
  let arr ← getArr j
  if h : arr.size = 2 then
    let enc ← getOption jsonToEncodingPrefix arr[0]
    let parts ← getList (fun partJ => do
      let partArr ← getArr partJ
      if h2 : partArr.size = 2 then
        let loc ← jsonToLoc partArr[0]
        let strs ← getList getStr partArr[1]
        .ok (loc, strs)
      else err "jsonToStringLiteral" "expected 2-element part"
    ) arr[1]
    .ok (enc, parts)
  else err "jsonToStringLiteral" "expected 2-element array"

/-! ## Operators -/

def jsonToUnaryOp (j : Json) : Except String cabs_unary_operator := do
  match ← getTag j with
  | "CabsAddress" => .ok .CabsAddress
  | "CabsIndirection" => .ok .CabsIndirection
  | "CabsPlus" => .ok .CabsPlus
  | "CabsMinus" => .ok .CabsMinus
  | "CabsBnot" => .ok .CabsBnot
  | "CabsNot" => .ok .CabsNot
  | t => err "jsonToUnaryOp" s!"unknown tag: {t}"

def jsonToBinaryOp (j : Json) : Except String cabs_binary_operator := do
  match ← getTag j with
  | "CabsMul" => .ok .CabsMul | "CabsDiv" => .ok .CabsDiv | "CabsMod" => .ok .CabsMod
  | "CabsAdd" => .ok .CabsAdd | "CabsSub" => .ok .CabsSub
  | "CabsShl" => .ok .CabsShl | "CabsShr" => .ok .CabsShr
  | "CabsLt" => .ok .CabsLt | "CabsGt" => .ok .CabsGt
  | "CabsLe" => .ok .CabsLe | "CabsGe" => .ok .CabsGe
  | "CabsEq" => .ok .CabsEq | "CabsNe" => .ok .CabsNe
  | "CabsBand" => .ok .CabsBand | "CabsBxor" => .ok .CabsBxor | "CabsBor" => .ok .CabsBor
  | "CabsAnd" => .ok .CabsAnd | "CabsOr" => .ok .CabsOr
  | t => err "jsonToBinaryOp" s!"unknown tag: {t}"

def jsonToAssignmentOp (j : Json) : Except String cabs_assignment_operator := do
  match ← getTag j with
  | "Assign" => .ok .Assign
  | "Assign_Mul" => .ok .Assign_Mul | "Assign_Div" => .ok .Assign_Div
  | "Assign_Mod" => .ok .Assign_Mod | "Assign_Add" => .ok .Assign_Add
  | "Assign_Sub" => .ok .Assign_Sub | "Assign_Shl" => .ok .Assign_Shl
  | "Assign_Shr" => .ok .Assign_Shr | "Assign_Band" => .ok .Assign_Band
  | "Assign_Bxor" => .ok .Assign_Bxor | "Assign_Bor" => .ok .Assign_Bor
  | t => err "jsonToAssignmentOp" s!"unknown tag: {t}"

/-! ## Expressions (mutually recursive) -/

-- Forward declarations for mutual types not yet serialized on OCaml side
def jsonToTypeName (_ : Json) : Except String type_name :=
  err "jsonToTypeName" "type_name deserialization not yet implemented"

def jsonToDesignator (_ : Json) : Except String designator :=
  err "jsonToDesignator" "designator deserialization not yet implemented"

def jsonToInitializer (_ : Json) : Except String initializer_ :=
  err "jsonToInitializer" "initializer deserialization not yet implemented"

def jsonToGnuBuiltin (_ : Json) : Except String gnu_builtin_function :=
  err "jsonToGnuBuiltin" "gnu_builtin deserialization not yet implemented"

def jsonToAttributes (_ : Json) : Except String attributes :=
  err "jsonToAttributes" "attributes deserialization not yet implemented"

def jsonToStatement (_ : Json) : Except String cabs_statement :=
  err "jsonToStatement" "statement deserialization not yet implemented"

mutual
partial def jsonToExpression (j : Json) : Except String cabs_expression := do
  let loc ← jsonToLoc (← getField j "loc")
  let expr ← jsonToExpression_ (← getField j "expr")
  .ok (CabsExpression loc expr)

partial def jsonToExpression_ (j : Json) : Except String cabs_expression_ := do
  match ← getTag j with
  | "CabsEident" => .ok (.CabsEident (← jsonToIdentifier (← getField j "id")))
  | "CabsEconst" => .ok (.CabsEconst (← jsonToConstant (← getField j "val")))
  | "CabsEstring" => .ok (.CabsEstring (← jsonToStringLiteral (← getField j "val")))
  | "CabsEgeneric" => .ok (.CabsEgeneric
      (← jsonToExpression (← getField j "expr"))
      (← getList jsonToGenericAssoc (← getField j "assocs")))
  | "CabsEsubscript" => .ok (.CabsEsubscript
      (← jsonToExpression (← getField j "arr"))
      (← jsonToExpression (← getField j "idx")))
  | "CabsEcall" => .ok (.CabsEcall
      (← jsonToExpression (← getField j "fun"))
      (← getList jsonToExpression (← getField j "args"))
      (← getOption jsonToAttributes (← getField j "attrs")))
  | "CabsEmemberof" => .ok (.CabsEmemberof
      (← jsonToExpression (← getField j "expr"))
      (← jsonToIdentifier (← getField j "member")))
  | "CabsEmemberofptr" => .ok (.CabsEmemberofptr
      (← jsonToExpression (← getField j "expr"))
      (← jsonToIdentifier (← getField j "member")))
  | "CabsEpostincr" => .ok (.CabsEpostincr (← jsonToExpression (← getField j "expr")))
  | "CabsEpostdecr" => .ok (.CabsEpostdecr (← jsonToExpression (← getField j "expr")))
  | "CabsEcompound" => .ok (.CabsEcompound
      (← jsonToTypeName (← getField j "type"))
      (← getList (fun initJ => do
        let arr ← getArr initJ
        if h : arr.size = 2 then
          let desigs ← getOption (getList jsonToDesignator) arr[0]
          let init ← jsonToInitializer arr[1]
          .ok (desigs, init)
        else err "compound" "expected 2-element init pair"
      ) (← getField j "inits")))
  | "CabsEpreincr" => .ok (.CabsEpreincr (← jsonToExpression (← getField j "expr")))
  | "CabsEpredecr" => .ok (.CabsEpredecr (← jsonToExpression (← getField j "expr")))
  | "CabsEunary" => .ok (.CabsEunary
      (← jsonToUnaryOp (← getField j "op"))
      (← jsonToExpression (← getField j "expr")))
  | "CabsEsizeof_expr" => .ok (.CabsEsizeof_expr (← jsonToExpression (← getField j "expr")))
  | "CabsEsizeof_type" => .ok (.CabsEsizeof_type (← jsonToTypeName (← getField j "type")))
  | "CabsEalignof" => .ok (.CabsEalignof (← jsonToTypeName (← getField j "type")))
  | "CabsEcast" => .ok (.CabsEcast
      (← jsonToTypeName (← getField j "type"))
      (← jsonToExpression (← getField j "expr")))
  | "CabsEbinary" => .ok (.CabsEbinary
      (← jsonToBinaryOp (← getField j "op"))
      (← jsonToExpression (← getField j "lhs"))
      (← jsonToExpression (← getField j "rhs")))
  | "CabsEcond" => .ok (.CabsEcond
      (← jsonToExpression (← getField j "cond"))
      (← jsonToExpression (← getField j "then_"))
      (← jsonToExpression (← getField j "else_")))
  | "CabsEassign" => .ok (.CabsEassign
      (← jsonToAssignmentOp (← getField j "op"))
      (← jsonToExpression (← getField j "lhs"))
      (← jsonToExpression (← getField j "rhs")))
  | "CabsEcomma" => .ok (.CabsEcomma
      (← jsonToExpression (← getField j "lhs"))
      (← jsonToExpression (← getField j "rhs")))
  | "CabsEassert" => .ok (.CabsEassert (← jsonToExpression (← getField j "expr")))
  | "CabsEoffsetof" => .ok (.CabsEoffsetof
      (← jsonToTypeName (← getField j "type"))
      (← jsonToIdentifier (← getField j "member")))
  | "CabsEva_start" => .ok (.CabsEva_start
      (← jsonToExpression (← getField j "expr"))
      (← jsonToIdentifier (← getField j "param")))
  | "CabsEva_copy" => .ok (.CabsEva_copy
      (← jsonToExpression (← getField j "dst"))
      (← jsonToExpression (← getField j "src")))
  | "CabsEva_arg" => .ok (.CabsEva_arg
      (← jsonToExpression (← getField j "expr"))
      (← jsonToTypeName (← getField j "type")))
  | "CabsEva_end" => .ok (.CabsEva_end (← jsonToExpression (← getField j "expr")))
  | "CabsEprint_type" => .ok (.CabsEprint_type (← jsonToExpression (← getField j "expr")))
  | "CabsEbmc_assume" => .ok (.CabsEbmc_assume (← jsonToExpression (← getField j "expr")))
  | "CabsEgcc_statement" => .ok (.CabsEgcc_statement
      (← getList jsonToStatement (← getField j "stmts")))
  | "CabsEcondGNU" => .ok (.CabsEcondGNU
      (← jsonToExpression (← getField j "cond"))
      (← jsonToExpression (← getField j "else_")))
  | "CabsEbuiltinGNU" => .ok (.CabsEbuiltinGNU (← jsonToGnuBuiltin (← getField j "builtin")))
  | t => err "jsonToExpression_" s!"unknown tag: {t}"

partial def jsonToGenericAssoc (j : Json) : Except String cabs_generic_association := do
  match ← getTag j with
  | "GA_type" => .ok (.GA_type
      (← jsonToTypeName (← getField j "type"))
      (← jsonToExpression (← getField j "expr")))
  | "GA_default" => .ok (.GA_default (← jsonToExpression (← getField j "expr")))
  | t => err "jsonToGenericAssoc" s!"unknown tag: {t}"
end

/-! ## External declarations -/

def jsonToExternalDeclaration (_ : Json) : Except String external_declaration :=
  -- TODO: full deserialization of function_definition, declaration, etc.
  err "jsonToExternalDeclaration" "not yet implemented"

/-! ## Translation unit (top-level) -/

def jsonToTranslationUnit (j : Json) : Except String translation_unit := do
  match ← getTag j with
  | "TUnit" =>
    let decls ← getList jsonToExternalDeclaration (← getField j "decls")
    .ok (TUnit decls)
  | t => err "jsonToTranslationUnit" s!"unknown tag: {t}"

/-! ## Entry point -/

def parseJson (input : String) : Except String translation_unit := do
  let json ← Json.parse input |>.mapError toString
  jsonToTranslationUnit json

end CabsImport
