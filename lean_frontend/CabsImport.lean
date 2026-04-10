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

/-! ## All Cabs types (mutually recursive) -/

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

-- Storage class specifiers
partial def jsonToStorageClass (j : Json) : Except String storage_class_specifier := do
  match ← getTag j with
  | "SC_typedef" => .ok .SC_typedef | "SC_extern" => .ok .SC_extern
  | "SC_static" => .ok .SC_static | "SC_Thread_local" => .ok .SC_Thread_local
  | "SC_auto" => .ok .SC_auto | "SC_register" => .ok .SC_register
  | t => err "jsonToStorageClass" s!"unknown tag: {t}"

-- Type qualifiers
partial def jsonToTypeQualifier (j : Json) : Except String cabs_type_qualifier := do
  match ← getTag j with
  | "Q_const" => .ok .Q_const | "Q_restrict" => .ok .Q_restrict
  | "Q_volatile" => .ok .Q_volatile | "Q_Atomic" => .ok .Q_Atomic
  | t => err "jsonToTypeQualifier" s!"unknown tag: {t}"

-- Function specifiers
partial def jsonToFunctionSpecifier (j : Json) : Except String function_specifier := do
  match ← getTag j with
  | "FS_inline" => .ok .FS_inline | "FS_Noreturn" => .ok .FS_Noreturn
  | t => err "jsonToFunctionSpecifier" s!"unknown tag: {t}"

-- Alignment specifiers
partial def jsonToAlignmentSpecifier (j : Json) : Except String alignment_specifier := do
  match ← getTag j with
  | "AS_type" => .ok (.AS_type (← jsonToTypeName (← getField j "type")))
  | "AS_expr" => .ok (.AS_expr (← jsonToExpression (← getField j "expr")))
  | t => err "jsonToAlignmentSpecifier" s!"unknown tag: {t}"

-- Type specifier (inner)
partial def jsonToTypeSpecifier_ (j : Json) : Except String cabs_type_specifier_ := do
  match ← getTag j with
  | "TSpec_void" => .ok .TSpec_void | "TSpec_char" => .ok .TSpec_char
  | "TSpec_short" => .ok .TSpec_short | "TSpec_int" => .ok .TSpec_int
  | "TSpec_long" => .ok .TSpec_long | "TSpec_float" => .ok .TSpec_float
  | "TSpec_double" => .ok .TSpec_double | "TSpec_signed" => .ok .TSpec_signed
  | "TSpec_unsigned" => .ok .TSpec_unsigned | "TSpec_Bool" => .ok .TSpec_Bool
  | "TSpec_Complex" => .ok .TSpec_Complex
  | "TSpec_Atomic" => .ok (.TSpec_Atomic (← jsonToTypeName (← getField j "type")))
  | "TSpec_struct" => .ok (.TSpec_struct
      (← jsonToAttributes (← getField j "attrs"))
      (← getOption jsonToIdentifier (← getField j "id"))
      (← getOption (getList jsonToStructDecl) (← getField j "members")))
  | "TSpec_union" => .ok (.TSpec_union
      (← jsonToAttributes (← getField j "attrs"))
      (← getOption jsonToIdentifier (← getField j "id"))
      (← getOption (getList jsonToStructDecl) (← getField j "members")))
  | "TSpec_enum" => .ok (.TSpec_enum
      (← getOption jsonToIdentifier (← getField j "id"))
      (← getOption (getList jsonToEnumerator) (← getField j "enumerators")))
  | "TSpec_name" => .ok (.TSpec_name (← jsonToIdentifier (← getField j "id")))
  | "TSpec_typeof_expr" => .ok (.TSpec_typeof_expr (← jsonToExpression (← getField j "expr")))
  | "TSpec_typeof_type" => .ok (.TSpec_typeof_type (← jsonToTypeName (← getField j "type")))
  | t => err "jsonToTypeSpecifier_" s!"unknown tag: {t}"

-- Type specifier (with location)
partial def jsonToTypeSpecifier (j : Json) : Except String cabs_type_specifier := do
  let loc ← jsonToLoc (← getField j "loc")
  let spec ← jsonToTypeSpecifier_ (← getField j "spec")
  .ok (TSpec loc spec)

-- Struct declaration
partial def jsonToStructDecl (j : Json) : Except String struct_declaration := do
  match ← getTag j with
  | "Struct_declaration" => .ok (.Struct_declaration
      (← jsonToAttributes (← getField j "attrs"))
      (← getList jsonToTypeSpecifier (← getField j "type_specifiers"))
      (← getList jsonToTypeQualifier (← getField j "type_qualifiers"))
      (← getList jsonToAlignmentSpecifier (← getField j "alignment_specifiers"))
      (← getList jsonToStructDeclarator (← getField j "declarators")))
  | "Struct_assert" => .ok (.Struct_assert (← jsonToStaticAssert (← getField j "assert")))
  | t => err "jsonToStructDecl" s!"unknown tag: {t}"

-- Struct declarator
partial def jsonToStructDeclarator (j : Json) : Except String struct_declarator := do
  match ← getTag j with
  | "SDecl_simple" => .ok (.SDecl_simple (← jsonToDeclarator (← getField j "declarator")))
  | "SDecl_bitfield" => .ok (.SDecl_bitfield
      (← getOption jsonToDeclarator (← getField j "declarator"))
      (← jsonToExpression (← getField j "width")))
  | t => err "jsonToStructDeclarator" s!"unknown tag: {t}"

-- Enumerator
partial def jsonToEnumerator (j : Json) : Except String (identifier × Option cabs_expression) := do
  let arr ← getArr j
  if h : arr.size = 2 then
    let id ← jsonToIdentifier arr[0]
    let expr ← getOption jsonToExpression arr[1]
    .ok (id, expr)
  else err "jsonToEnumerator" "expected 2-element array"

-- Pointer declarator
partial def jsonToPointerDecl (j : Json) : Except String pointer_declarator := do
  let loc ← jsonToLoc (← getField j "loc")
  let quals ← getList jsonToTypeQualifier (← getField j "type_qualifiers")
  let inner ← getOption jsonToPointerDecl (← getField j "pointer")
  .ok (PDecl loc quals inner)

-- Array declarator size
partial def jsonToArrayDeclSize (j : Json) : Except String array_declarator_size := do
  match ← getTag j with
  | "ADeclSize_expression" => .ok (.ADeclSize_expression (← jsonToExpression (← getField j "expr")))
  | "ADeclSize_asterisk" => .ok .ADeclSize_asterisk
  | t => err "jsonToArrayDeclSize" s!"unknown tag: {t}"

-- Array declarator
partial def jsonToArrayDecl (j : Json) : Except String array_declarator := do
  let loc ← jsonToLoc (← getField j "loc")
  let quals ← getList jsonToTypeQualifier (← getField j "type_qualifiers")
  let isStatic ← getBool (← getField j "is_static")
  let size ← getOption jsonToArrayDeclSize (← getField j "size")
  .ok (ADecl loc quals isStatic size)

-- Parameter type list
partial def jsonToParamTypeList (j : Json) : Except String parameter_type_list := do
  let params ← getList jsonToParamDecl (← getField j "params")
  let variadic ← getBool (← getField j "is_variadic")
  .ok (Params params variadic)

-- Parameter declaration
partial def jsonToParamDecl (j : Json) : Except String parameter_declaration := do
  match ← getTag j with
  | "PDeclaration_decl" => .ok (.PDeclaration_decl
      (← jsonToSpecifiers (← getField j "specifiers"))
      (← jsonToDeclarator (← getField j "declarator")))
  | "PDeclaration_abs_decl" => .ok (.PDeclaration_abs_decl
      (← jsonToSpecifiers (← getField j "specifiers"))
      (← getOption jsonToAbstractDeclarator (← getField j "abstract_declarator")))
  | t => err "jsonToParamDecl" s!"unknown tag: {t}"

-- Direct declarator
partial def jsonToDirectDecl (j : Json) : Except String direct_declarator := do
  match ← getTag j with
  | "DDecl_identifier" => .ok (.DDecl_identifier
      (← jsonToAttributes (← getField j "attrs"))
      (← jsonToIdentifier (← getField j "id")))
  | "DDecl_declarator" => .ok (.DDecl_declarator (← jsonToDeclarator (← getField j "declarator")))
  | "DDecl_array" => .ok (.DDecl_array
      (← jsonToDirectDecl (← getField j "direct"))
      (← jsonToArrayDecl (← getField j "array")))
  | "DDecl_function" => .ok (.DDecl_function
      (← jsonToDirectDecl (← getField j "direct"))
      (← jsonToParamTypeList (← getField j "params")))
  | t => err "jsonToDirectDecl" s!"unknown tag: {t}"

-- Declarator
partial def jsonToDeclarator (j : Json) : Except String declarator := do
  let ptr ← getOption jsonToPointerDecl (← getField j "pointer")
  let direct ← jsonToDirectDecl (← getField j "direct")
  .ok (Declarator ptr direct)

-- Abstract declarator
partial def jsonToAbstractDeclarator (j : Json) : Except String abstract_declarator := do
  match ← getTag j with
  | "AbsDecl_pointer" => .ok (.AbsDecl_pointer (← jsonToPointerDecl (← getField j "pointer")))
  | "AbsDecl_direct" => .ok (.AbsDecl_direct
      (← getOption jsonToPointerDecl (← getField j "pointer"))
      (← jsonToDirectAbstractDecl (← getField j "direct")))
  | t => err "jsonToAbstractDeclarator" s!"unknown tag: {t}"

-- Direct abstract declarator
partial def jsonToDirectAbstractDecl (j : Json) : Except String direct_abstract_declarator := do
  match ← getTag j with
  | "DAbs_abs_declarator" => .ok (.DAbs_abs_declarator
      (← jsonToAbstractDeclarator (← getField j "abstract_declarator")))
  | "DAbs_array" => .ok (.DAbs_array
      (← getOption jsonToDirectAbstractDecl (← getField j "direct"))
      (← jsonToArrayDecl (← getField j "array")))
  | "DAbs_function" => .ok (.DAbs_function
      (← getOption jsonToDirectAbstractDecl (← getField j "direct"))
      (← jsonToParamTypeList (← getField j "params")))
  | t => err "jsonToDirectAbstractDecl" s!"unknown tag: {t}"

-- Type name
partial def jsonToTypeName (j : Json) : Except String type_name := do
  let specs ← getList jsonToTypeSpecifier (← getField j "type_specifiers")
  let quals ← getList jsonToTypeQualifier (← getField j "type_qualifiers")
  let aligns ← getList jsonToAlignmentSpecifier (← getField j "alignment_specifiers")
  let absDecl ← getOption jsonToAbstractDeclarator (← getField j "abstract_declarator")
  .ok (Type_name specs quals aligns absDecl)

-- Designator
partial def jsonToDesignator (j : Json) : Except String designator := do
  match ← getTag j with
  | "Desig_array" => .ok (.Desig_array (← jsonToExpression (← getField j "expr")))
  | "Desig_member" => .ok (.Desig_member (← jsonToIdentifier (← getField j "member")))
  | t => err "jsonToDesignator" s!"unknown tag: {t}"

-- Initializer
partial def jsonToInitializer (j : Json) : Except String initializer_ := do
  match ← getTag j with
  | "Init_expr" => .ok (.Init_expr (← jsonToExpression (← getField j "expr")))
  | "Init_list" => .ok (.Init_list
      (← jsonToLoc (← getField j "loc"))
      (← getList (fun initJ => do
        let arr ← getArr initJ
        if h : arr.size = 2 then
          let desigs ← getOption (getList jsonToDesignator) arr[0]
          let init ← jsonToInitializer arr[1]
          .ok (desigs, init)
        else err "Init_list" "expected 2-element init pair"
      ) (← getField j "inits")))
  | t => err "jsonToInitializer" s!"unknown tag: {t}"

-- GNU builtins
partial def jsonToGnuBuiltin (j : Json) : Except String gnu_builtin_function := do
  match ← getTag j with
  | "GNUbuiltin_types_compatible_p" => .ok (.GNUbuiltin_types_compatible_p
      (← jsonToTypeName (← getField j "type1"))
      (← jsonToTypeName (← getField j "type2")))
  | "GNUbuiltin_choose_expr" => .ok (.GNUbuiltin_choose_expr
      (← jsonToExpression (← getField j "cond"))
      (← jsonToExpression (← getField j "then_"))
      (← jsonToExpression (← getField j "else_")))
  | t => err "jsonToGnuBuiltin" s!"unknown tag: {t}"

-- Attributes
partial def jsonToAttributes (j : Json) : Except String attributes := do
  match ← getTag j with
  | "Attrs" => .ok (.Attrs (← getList jsonToAttribute (← getField j "attrs")))
  | t => err "jsonToAttributes" s!"unknown tag: {t}"

partial def jsonToAttribute (j : Json) : Except String attribute0 := do
  .ok (attribute0.mk
    (← getOption jsonToIdentifier (← getField j "ns"))
    (← jsonToIdentifier (← getField j "id"))
    (← getList (fun argJ => do
      let arr ← getArr argJ
      if h : arr.size = 3 then
        let loc ← jsonToLoc arr[0]
        let s ← getStr arr[1]
        let tokens ← getList (fun tokJ => do
          let tokArr ← getArr tokJ
          if h2 : tokArr.size = 2 then
            let tokLoc ← jsonToLoc tokArr[0]
            let tokStr ← getStr tokArr[1]
            .ok (tokLoc, tokStr)
          else err "attr_token" "expected 2-element array"
        ) arr[2]
        .ok (loc, s, tokens)
      else err "attribute_arg" "expected 3-element array"
    ) (← getField j "args")))

-- Specifiers
partial def jsonToSpecifiers (j : Json) : Except String specifiers := do
  .ok (specifiers.mk
    (← getList jsonToStorageClass (← getField j "storage_classes"))
    (← getList jsonToTypeSpecifier (← getField j "type_specifiers"))
    (← getList jsonToTypeQualifier (← getField j "type_qualifiers"))
    (← getList jsonToFunctionSpecifier (← getField j "function_specifiers"))
    (← getList jsonToAlignmentSpecifier (← getField j "alignment_specifiers")))

-- Static assert
partial def jsonToStaticAssert (j : Json) : Except String static_assert_declaration := do
  .ok (.Static_assert
    (← jsonToExpression (← getField j "expr"))
    (← jsonToStringLiteral (← getField j "msg")))

-- Init declarator
partial def jsonToInitDecl (j : Json) : Except String init_declarator := do
  let loc ← jsonToLoc (← getField j "loc")
  let decl ← jsonToDeclarator (← getField j "declarator")
  let init ← getOption jsonToInitializer (← getField j "initializer")
  .ok (InitDecl loc decl init)

-- Declaration
partial def jsonToDeclaration (j : Json) : Except String cabs_declaration := do
  match ← getTag j with
  | "Declaration_base" => .ok (.Declaration_base
      (← jsonToAttributes (← getField j "attrs"))
      (← jsonToSpecifiers (← getField j "specifiers"))
      (← getList jsonToInitDecl (← getField j "init_declarators")))
  | "Declaration_static_assert" => .ok (.Declaration_static_assert
      (← jsonToStaticAssert (← getField j "assert")))
  | t => err "jsonToDeclaration" s!"unknown tag: {t}"

-- For clause
partial def jsonToForClause (j : Json) : Except String for_clause := do
  match ← getTag j with
  | "FC_expr" => .ok (.FC_expr (← jsonToExpression (← getField j "expr")))
  | "FC_decl" => .ok (.FC_decl
      (← jsonToLoc (← getField j "loc"))
      (← jsonToDeclaration (← getField j "decl")))
  | t => err "jsonToForClause" s!"unknown tag: {t}"

-- Statement (inner)
partial def jsonToStatement_ (j : Json) : Except String cabs_statement_ := do
  match ← getTag j with
  | "CabsSlabel" => .ok (.CabsSlabel
      (← jsonToIdentifier (← getField j "label"))
      (← jsonToStatement (← getField j "stmt")))
  | "CabsScase" => .ok (.CabsScase
      (← jsonToExpression (← getField j "expr"))
      (← jsonToStatement (← getField j "stmt")))
  | "CabsSdefault" => .ok (.CabsSdefault (← jsonToStatement (← getField j "stmt")))
  | "CabsSblock" => .ok (.CabsSblock (← getList jsonToStatement (← getField j "stmts")))
  | "CabsSdecl" => .ok (.CabsSdecl (← jsonToDeclaration (← getField j "decl")))
  | "CabsSnull" => .ok .CabsSnull
  | "CabsSexpr" => .ok (.CabsSexpr (← jsonToExpression (← getField j "expr")))
  | "CabsSif" => .ok (.CabsSif
      (← jsonToExpression (← getField j "cond"))
      (← jsonToStatement (← getField j "then_"))
      (← getOption jsonToStatement (← getField j "else_")))
  | "CabsSswitch" => .ok (.CabsSswitch
      (← jsonToExpression (← getField j "expr"))
      (← jsonToStatement (← getField j "stmt")))
  | "CabsSwhile" => .ok (.CabsSwhile
      (← jsonToExpression (← getField j "cond"))
      (← jsonToStatement (← getField j "body")))
  | "CabsSdo" => .ok (.CabsSdo
      (← jsonToExpression (← getField j "cond"))
      (← jsonToStatement (← getField j "body")))
  | "CabsSfor" => .ok (.CabsSfor
      (← getOption jsonToForClause (← getField j "init"))
      (← getOption jsonToExpression (← getField j "cond"))
      (← getOption jsonToExpression (← getField j "step"))
      (← jsonToStatement (← getField j "body")))
  | "CabsSgoto" => .ok (.CabsSgoto (← jsonToIdentifier (← getField j "label")))
  | "CabsScontinue" => .ok .CabsScontinue
  | "CabsSbreak" => .ok .CabsSbreak
  | "CabsSreturn" => .ok (.CabsSreturn (← getOption jsonToExpression (← getField j "expr")))
  | "CabsSpar" => .ok (.CabsSpar (← getList jsonToStatement (← getField j "stmts")))
  | "CabsSasm" => .ok (.CabsSasm
      (← getBool (← getField j "is_volatile"))
      (← getBool (← getField j "is_inline"))
      (← getList (fun partJ => do
        let arr ← getArr partJ
        if h : arr.size = 2 then
          let loc ← jsonToLoc arr[0]
          let strs ← getList getStr arr[1]
          .ok (loc, strs)
        else err "asm" "expected 2-element part"
      ) (← getField j "parts")))
  | "CabsScaseGNU" => .ok (.CabsScaseGNU
      (← jsonToExpression (← getField j "lo"))
      (← jsonToExpression (← getField j "hi"))
      (← jsonToStatement (← getField j "stmt")))
  | "CabsSmarker" => .ok (.CabsSmarker (← jsonToStatement (← getField j "stmt")))
  | t => err "jsonToStatement_" s!"unknown tag: {t}"

-- Statement (with location and attributes)
partial def jsonToStatement (j : Json) : Except String cabs_statement := do
  let loc ← jsonToLoc (← getField j "loc")
  let attrs ← jsonToAttributes (← getField j "attrs")
  let stmt ← jsonToStatement_ (← getField j "stmt")
  .ok (CabsStatement loc attrs stmt)

-- Function definition
partial def jsonToFunctionDef (j : Json) : Except String function_definition := do
  .ok (FunDef
    (← jsonToLoc (← getField j "loc"))
    (← jsonToAttributes (← getField j "attrs"))
    (← jsonToSpecifiers (← getField j "specifiers"))
    (← jsonToDeclarator (← getField j "declarator"))
    (← jsonToStatement (← getField j "body")))

-- External declaration
partial def jsonToExternalDeclaration (j : Json) : Except String external_declaration := do
  match ← getTag j with
  | "EDecl_func" => .ok (.EDecl_func (← jsonToFunctionDef (← getField j "def")))
  | "EDecl_decl" => .ok (.EDecl_decl (← jsonToDeclaration (← getField j "decl")))
  | "EDecl_magic" => do
    let loc ← jsonToLoc (← getField j "loc")
    let s ← getStr (← getField j "str")
    .ok (.EDecl_magic (loc, s))
  | t => err "jsonToExternalDeclaration" s!"unknown tag: {t}"

-- Translation unit
partial def jsonToTranslationUnit (j : Json) : Except String translation_unit := do
  match ← getTag j with
  | "TUnit" =>
    let decls ← getList jsonToExternalDeclaration (← getField j "decls")
    .ok (TUnit decls)
  | t => err "jsonToTranslationUnit" s!"unknown tag: {t}"

end

/-! ## Entry point -/

def parseJson (input : String) : Except String translation_unit := do
  let json ← Json.parse input |>.mapError toString
  jsonToTranslationUnit json

end CabsImport
