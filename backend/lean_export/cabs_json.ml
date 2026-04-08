(* Cabs AST to JSON serializer for the Lean backend.

   Schema: every constructor becomes {"tag": "Name", "args": [...]}
   Atoms: strings → JSON strings, integers → JSON strings (arbitrary precision),
   bools → JSON bools, options → null or value, lists → JSON arrays,
   tuples → JSON arrays, locations → Cerb_location.to_json.

   This is a mechanical translation of the Cabs type definitions. *)

open Cerb_frontend
open Cabs

let tag name args = `Assoc (("tag", `String name) :: args)
let tag0 name = `String name  (* nullary constructor *)

(* === Locations === *)

let json_of_loc = Cerb_location.to_json

(* === Identifiers === *)

let json_of_identifier (Symbol.Identifier (loc, s)) =
  `Assoc [("loc", json_of_loc loc); ("name", `String s)]

(* === Basic types === *)

let json_of_option f = function
  | None -> `Null
  | Some x -> f x

let json_of_list f xs = `List (List.map f xs)

let json_of_string s = `String s

let json_of_integer n = `String (Nat_big_num.to_string n)

let json_of_bool b = `Bool b

let json_of_nat n = `Int n

(* === Cabs types === *)

let json_of_cabs_integer_suffix = function
  | CabsSuffix_U -> tag0 "CabsSuffix_U"
  | CabsSuffix_UL -> tag0 "CabsSuffix_UL"
  | CabsSuffix_ULL -> tag0 "CabsSuffix_ULL"
  | CabsSuffix_L -> tag0 "CabsSuffix_L"
  | CabsSuffix_LL -> tag0 "CabsSuffix_LL"

let json_of_cabs_integer_constant (s, suffix_opt) =
  `List [`String s; json_of_option json_of_cabs_integer_suffix suffix_opt]

let json_of_cabs_floating_suffix = function
  | CabsFloatingSuffix_F -> tag0 "CabsFloatingSuffix_F"
  | CabsFloatingSuffix_L -> tag0 "CabsFloatingSuffix_L"

let json_of_cabs_floating_constant (s, suffix_opt) =
  `List [`String s; json_of_option json_of_cabs_floating_suffix suffix_opt]

let json_of_cabs_character_prefix = function
  | CabsPrefix_L -> tag0 "CabsPrefix_L"
  | CabsPrefix_u -> tag0 "CabsPrefix_u"
  | CabsPrefix_U -> tag0 "CabsPrefix_U"

let json_of_cabs_character_constant (prefix_opt, s) =
  `List [json_of_option json_of_cabs_character_prefix prefix_opt; `String s]

let json_of_cabs_constant = function
  | CabsInteger_const ic -> tag "CabsInteger_const" [("val", json_of_cabs_integer_constant ic)]
  | CabsFloating_const fc -> tag "CabsFloating_const" [("val", json_of_cabs_floating_constant fc)]
  | CabsCharacter_const cc -> tag "CabsCharacter_const" [("val", json_of_cabs_character_constant cc)]

let json_of_cabs_encoding_prefix = function
  | CabsEncPrefix_u8 -> tag0 "CabsEncPrefix_u8"
  | CabsEncPrefix_u -> tag0 "CabsEncPrefix_u"
  | CabsEncPrefix_U -> tag0 "CabsEncPrefix_U"
  | CabsEncPrefix_L -> tag0 "CabsEncPrefix_L"

let json_of_cabs_string_literal (enc_opt, parts) =
  `List [
    json_of_option json_of_cabs_encoding_prefix enc_opt;
    json_of_list (fun (loc, strs) ->
      `List [json_of_loc loc; json_of_list json_of_string strs]
    ) parts
  ]

(* Forward declarations for mutual recursion *)
let rec json_of_cabs_expression (CabsExpression (loc, expr_)) =
  tag "CabsExpression" [
    ("loc", json_of_loc loc);
    ("expr", json_of_cabs_expression_ expr_)
  ]

and json_of_cabs_expression_ = function
  | CabsEident id -> tag "CabsEident" [("id", json_of_identifier id)]
  | CabsEconst c -> tag "CabsEconst" [("val", json_of_cabs_constant c)]
  | CabsEstring sl -> tag "CabsEstring" [("val", json_of_cabs_string_literal sl)]
  | CabsEgeneric (e, assocs) ->
    tag "CabsEgeneric" [
      ("expr", json_of_cabs_expression e);
      ("assocs", json_of_list json_of_generic_association assocs)
    ]
  | CabsEsubscript (e1, e2) ->
    tag "CabsEsubscript" [
      ("arr", json_of_cabs_expression e1);
      ("idx", json_of_cabs_expression e2)
    ]
  | CabsEcall (f, args, attrs_opt) ->
    tag "CabsEcall" [
      ("fun", json_of_cabs_expression f);
      ("args", json_of_list json_of_cabs_expression args);
      ("attrs", json_of_option json_of_attributes attrs_opt)
    ]
  | CabsEmemberof (e, id) ->
    tag "CabsEmemberof" [("expr", json_of_cabs_expression e); ("member", json_of_identifier id)]
  | CabsEmemberofptr (e, id) ->
    tag "CabsEmemberofptr" [("expr", json_of_cabs_expression e); ("member", json_of_identifier id)]
  | CabsEpostincr e -> tag "CabsEpostincr" [("expr", json_of_cabs_expression e)]
  | CabsEpostdecr e -> tag "CabsEpostdecr" [("expr", json_of_cabs_expression e)]
  | CabsEcompound (tn, inits) ->
    tag "CabsEcompound" [
      ("type", json_of_type_name tn);
      ("inits", json_of_list (fun (desig_opt, init) ->
        `List [
          json_of_option (json_of_list json_of_designator) desig_opt;
          json_of_initializer_ init
        ]) inits)
    ]
  | CabsEpreincr e -> tag "CabsEpreincr" [("expr", json_of_cabs_expression e)]
  | CabsEpredecr e -> tag "CabsEpredecr" [("expr", json_of_cabs_expression e)]
  | CabsEunary (op, e) ->
    tag "CabsEunary" [("op", json_of_unary_op op); ("expr", json_of_cabs_expression e)]
  | CabsEsizeof_expr e -> tag "CabsEsizeof_expr" [("expr", json_of_cabs_expression e)]
  | CabsEsizeof_type tn -> tag "CabsEsizeof_type" [("type", json_of_type_name tn)]
  | CabsEalignof tn -> tag "CabsEalignof" [("type", json_of_type_name tn)]
  | CabsEcast (tn, e) ->
    tag "CabsEcast" [("type", json_of_type_name tn); ("expr", json_of_cabs_expression e)]
  | CabsEbinary (op, e1, e2) ->
    tag "CabsEbinary" [
      ("op", json_of_binary_op op);
      ("lhs", json_of_cabs_expression e1);
      ("rhs", json_of_cabs_expression e2)
    ]
  | CabsEcond (e1, e2, e3) ->
    tag "CabsEcond" [
      ("cond", json_of_cabs_expression e1);
      ("then_", json_of_cabs_expression e2);
      ("else_", json_of_cabs_expression e3)
    ]
  | CabsEassign (op, e1, e2) ->
    tag "CabsEassign" [
      ("op", json_of_assignment_op op);
      ("lhs", json_of_cabs_expression e1);
      ("rhs", json_of_cabs_expression e2)
    ]
  | CabsEcomma (e1, e2) ->
    tag "CabsEcomma" [("lhs", json_of_cabs_expression e1); ("rhs", json_of_cabs_expression e2)]
  | CabsEassert e -> tag "CabsEassert" [("expr", json_of_cabs_expression e)]
  | CabsEoffsetof (tn, id) ->
    tag "CabsEoffsetof" [("type", json_of_type_name tn); ("member", json_of_identifier id)]
  | CabsEva_start (e, id) ->
    tag "CabsEva_start" [("expr", json_of_cabs_expression e); ("param", json_of_identifier id)]
  | CabsEva_copy (e1, e2) ->
    tag "CabsEva_copy" [("dst", json_of_cabs_expression e1); ("src", json_of_cabs_expression e2)]
  | CabsEva_arg (e, tn) ->
    tag "CabsEva_arg" [("expr", json_of_cabs_expression e); ("type", json_of_type_name tn)]
  | CabsEva_end e -> tag "CabsEva_end" [("expr", json_of_cabs_expression e)]
  | CabsEprint_type e -> tag "CabsEprint_type" [("expr", json_of_cabs_expression e)]
  | CabsEbmc_assume e -> tag "CabsEbmc_assume" [("expr", json_of_cabs_expression e)]
  | CabsEgcc_statement stmts ->
    tag "CabsEgcc_statement" [("stmts", json_of_list json_of_cabs_statement stmts)]
  | CabsEcondGNU (e1, e2) ->
    tag "CabsEcondGNU" [("cond", json_of_cabs_expression e1); ("else_", json_of_cabs_expression e2)]
  | CabsEbuiltinGNU b -> tag "CabsEbuiltinGNU" [("builtin", json_of_gnu_builtin b)]

and json_of_generic_association = function
  | GA_type (tn, e) -> tag "GA_type" [("type", json_of_type_name tn); ("expr", json_of_cabs_expression e)]
  | GA_default e -> tag "GA_default" [("expr", json_of_cabs_expression e)]

and json_of_unary_op = function
  | CabsAddress -> tag0 "CabsAddress"
  | CabsIndirection -> tag0 "CabsIndirection"
  | CabsPlus -> tag0 "CabsPlus"
  | CabsMinus -> tag0 "CabsMinus"
  | CabsBnot -> tag0 "CabsBnot"
  | CabsNot -> tag0 "CabsNot"

and json_of_binary_op = function
  | CabsMul -> tag0 "CabsMul" | CabsDiv -> tag0 "CabsDiv" | CabsMod -> tag0 "CabsMod"
  | CabsAdd -> tag0 "CabsAdd" | CabsSub -> tag0 "CabsSub"
  | CabsShl -> tag0 "CabsShl" | CabsShr -> tag0 "CabsShr"
  | CabsLt -> tag0 "CabsLt" | CabsGt -> tag0 "CabsGt"
  | CabsLe -> tag0 "CabsLe" | CabsGe -> tag0 "CabsGe"
  | CabsEq -> tag0 "CabsEq" | CabsNe -> tag0 "CabsNe"
  | CabsBand -> tag0 "CabsBand" | CabsBxor -> tag0 "CabsBxor" | CabsBor -> tag0 "CabsBor"
  | CabsAnd -> tag0 "CabsAnd" | CabsOr -> tag0 "CabsOr"

and json_of_assignment_op = function
  | Assign -> tag0 "Assign"
  | Assign_Mul -> tag0 "Assign_Mul" | Assign_Div -> tag0 "Assign_Div"
  | Assign_Mod -> tag0 "Assign_Mod" | Assign_Add -> tag0 "Assign_Add"
  | Assign_Sub -> tag0 "Assign_Sub" | Assign_Shl -> tag0 "Assign_Shl"
  | Assign_Shr -> tag0 "Assign_Shr" | Assign_Band -> tag0 "Assign_Band"
  | Assign_Bxor -> tag0 "Assign_Bxor" | Assign_Bor -> tag0 "Assign_Bor"

(* Statements, declarations, type specifiers — these are large but mechanical.
   For now, serialize as opaque JSON to get the pipeline working.
   TODO: expand to full structural serialization. *)

and json_of_cabs_statement _ =
  `String "TODO:statement"

and json_of_type_name _ =
  `String "TODO:type_name"

and json_of_designator _ =
  `String "TODO:designator"

and json_of_initializer_ _ =
  `String "TODO:initializer"

and json_of_gnu_builtin _ =
  `String "TODO:gnu_builtin"

and json_of_attributes _ =
  `String "TODO:attributes"

(* === Top-level === *)

let json_of_external_declaration = function
  | EDecl_func _ -> tag "EDecl_func" [("def", `String "TODO:function_definition")]
  | EDecl_decl _ -> tag "EDecl_decl" [("decl", `String "TODO:declaration")]
  | _ -> `String "TODO:other_external_declaration"

let json_of_translation_unit (TUnit decls) =
  tag "TUnit" [("decls", json_of_list json_of_external_declaration decls)]

(* Entry point *)
let to_json = json_of_translation_unit
