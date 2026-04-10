(* Cabs AST to JSON serializer for the Lean backend.

   Schema: every constructor becomes {"tag": "Name", "args": [...]}
   Atoms: strings -> JSON strings, integers -> JSON strings (arbitrary precision),
   bools -> JSON bools, options -> null or value, lists -> JSON arrays,
   tuples -> JSON arrays, locations -> Cerb_location.to_json.

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

(* === Statements === *)

and json_of_cabs_statement (CabsStatement (loc, attrs, stmt_)) =
  tag "CabsStatement" [
    ("loc", json_of_loc loc);
    ("attrs", json_of_attributes attrs);
    ("stmt", json_of_cabs_statement_ stmt_)
  ]

and json_of_cabs_statement_ = function
  | CabsSlabel (id, stmt) ->
    tag "CabsSlabel" [("label", json_of_identifier id); ("stmt", json_of_cabs_statement stmt)]
  | CabsScase (e, stmt) ->
    tag "CabsScase" [("expr", json_of_cabs_expression e); ("stmt", json_of_cabs_statement stmt)]
  | CabsSdefault stmt ->
    tag "CabsSdefault" [("stmt", json_of_cabs_statement stmt)]
  | CabsSblock stmts ->
    tag "CabsSblock" [("stmts", json_of_list json_of_cabs_statement stmts)]
  | CabsSdecl decl ->
    tag "CabsSdecl" [("decl", json_of_cabs_declaration decl)]
  | CabsSnull -> tag0 "CabsSnull"
  | CabsSexpr e ->
    tag "CabsSexpr" [("expr", json_of_cabs_expression e)]
  | CabsSif (e, then_stmt, else_opt) ->
    tag "CabsSif" [
      ("cond", json_of_cabs_expression e);
      ("then_", json_of_cabs_statement then_stmt);
      ("else_", json_of_option json_of_cabs_statement else_opt)
    ]
  | CabsSswitch (e, stmt) ->
    tag "CabsSswitch" [("expr", json_of_cabs_expression e); ("stmt", json_of_cabs_statement stmt)]
  | CabsSwhile (e, stmt) ->
    tag "CabsSwhile" [("cond", json_of_cabs_expression e); ("body", json_of_cabs_statement stmt)]
  | CabsSdo (e, stmt) ->
    tag "CabsSdo" [("cond", json_of_cabs_expression e); ("body", json_of_cabs_statement stmt)]
  | CabsSfor (fc_opt, cond_opt, step_opt, body) ->
    tag "CabsSfor" [
      ("init", json_of_option json_of_for_clause fc_opt);
      ("cond", json_of_option json_of_cabs_expression cond_opt);
      ("step", json_of_option json_of_cabs_expression step_opt);
      ("body", json_of_cabs_statement body)
    ]
  | CabsSgoto id ->
    tag "CabsSgoto" [("label", json_of_identifier id)]
  | CabsScontinue -> tag0 "CabsScontinue"
  | CabsSbreak -> tag0 "CabsSbreak"
  | CabsSreturn e_opt ->
    tag "CabsSreturn" [("expr", json_of_option json_of_cabs_expression e_opt)]
  | CabsSpar stmts ->
    tag "CabsSpar" [("stmts", json_of_list json_of_cabs_statement stmts)]
  | CabsSasm (is_volatile, is_inline, parts) ->
    tag "CabsSasm" [
      ("is_volatile", json_of_bool is_volatile);
      ("is_inline", json_of_bool is_inline);
      ("parts", json_of_list (fun (loc, strs) ->
        `List [json_of_loc loc; json_of_list json_of_string strs]
      ) parts)
    ]
  | CabsScaseGNU (lo, hi, stmt) ->
    tag "CabsScaseGNU" [
      ("lo", json_of_cabs_expression lo);
      ("hi", json_of_cabs_expression hi);
      ("stmt", json_of_cabs_statement stmt)
    ]
  | CabsSmarker stmt ->
    tag "CabsSmarker" [("stmt", json_of_cabs_statement stmt)]

and json_of_for_clause = function
  | FC_expr e -> tag "FC_expr" [("expr", json_of_cabs_expression e)]
  | FC_decl (loc, decl) ->
    tag "FC_decl" [("loc", json_of_loc loc); ("decl", json_of_cabs_declaration decl)]

(* === Type names === *)

and json_of_type_name (Type_name (tspecs, tquals, aspecs, abs_decl_opt)) =
  tag "Type_name" [
    ("type_specifiers", json_of_list json_of_cabs_type_specifier tspecs);
    ("type_qualifiers", json_of_list json_of_cabs_type_qualifier tquals);
    ("alignment_specifiers", json_of_list json_of_alignment_specifier aspecs);
    ("abstract_declarator", json_of_option json_of_abstract_declarator abs_decl_opt)
  ]

(* === Type specifiers === *)

and json_of_cabs_type_specifier (TSpec (loc, tspec_)) =
  tag "TSpec" [
    ("loc", json_of_loc loc);
    ("spec", json_of_cabs_type_specifier_ tspec_)
  ]

and json_of_cabs_type_specifier_ = function
  | TSpec_void -> tag0 "TSpec_void"
  | TSpec_char -> tag0 "TSpec_char"
  | TSpec_short -> tag0 "TSpec_short"
  | TSpec_int -> tag0 "TSpec_int"
  | TSpec_long -> tag0 "TSpec_long"
  | TSpec_float -> tag0 "TSpec_float"
  | TSpec_double -> tag0 "TSpec_double"
  | TSpec_signed -> tag0 "TSpec_signed"
  | TSpec_unsigned -> tag0 "TSpec_unsigned"
  | TSpec_Bool -> tag0 "TSpec_Bool"
  | TSpec_Complex -> tag0 "TSpec_Complex"
  | TSpec_Atomic tn ->
    tag "TSpec_Atomic" [("type", json_of_type_name tn)]
  | TSpec_struct (attrs, id_opt, members_opt) ->
    tag "TSpec_struct" [
      ("attrs", json_of_attributes attrs);
      ("id", json_of_option json_of_identifier id_opt);
      ("members", json_of_option (json_of_list json_of_struct_declaration) members_opt)
    ]
  | TSpec_union (attrs, id_opt, members_opt) ->
    tag "TSpec_union" [
      ("attrs", json_of_attributes attrs);
      ("id", json_of_option json_of_identifier id_opt);
      ("members", json_of_option (json_of_list json_of_struct_declaration) members_opt)
    ]
  | TSpec_enum (id_opt, enumerators_opt) ->
    tag "TSpec_enum" [
      ("id", json_of_option json_of_identifier id_opt);
      ("enumerators", json_of_option (json_of_list (fun (id, e_opt) ->
        `List [json_of_identifier id; json_of_option json_of_cabs_expression e_opt]
      )) enumerators_opt)
    ]
  | TSpec_name id ->
    tag "TSpec_name" [("id", json_of_identifier id)]
  | TSpec_typeof_expr e ->
    tag "TSpec_typeof_expr" [("expr", json_of_cabs_expression e)]
  | TSpec_typeof_type tn ->
    tag "TSpec_typeof_type" [("type", json_of_type_name tn)]

(* === Struct declarations === *)

and json_of_struct_declaration = function
  | Struct_declaration (attrs, tspecs, tquals, aspecs, sdecls) ->
    tag "Struct_declaration" [
      ("attrs", json_of_attributes attrs);
      ("type_specifiers", json_of_list json_of_cabs_type_specifier tspecs);
      ("type_qualifiers", json_of_list json_of_cabs_type_qualifier tquals);
      ("alignment_specifiers", json_of_list json_of_alignment_specifier aspecs);
      ("declarators", json_of_list json_of_struct_declarator sdecls)
    ]
  | Struct_assert sa ->
    tag "Struct_assert" [("assert", json_of_static_assert_declaration sa)]

and json_of_struct_declarator = function
  | SDecl_simple decl ->
    tag "SDecl_simple" [("declarator", json_of_declarator decl)]
  | SDecl_bitfield (decl_opt, e) ->
    tag "SDecl_bitfield" [
      ("declarator", json_of_option json_of_declarator decl_opt);
      ("width", json_of_cabs_expression e)
    ]

(* === Type qualifiers === *)

and json_of_cabs_type_qualifier = function
  | Q_const -> tag0 "Q_const"
  | Q_restrict -> tag0 "Q_restrict"
  | Q_volatile -> tag0 "Q_volatile"
  | Q_Atomic -> tag0 "Q_Atomic"

(* === Function specifiers === *)

and json_of_function_specifier = function
  | FS_inline -> tag0 "FS_inline"
  | FS_Noreturn -> tag0 "FS_Noreturn"

(* === Alignment specifiers === *)

and json_of_alignment_specifier = function
  | AS_type tn -> tag "AS_type" [("type", json_of_type_name tn)]
  | AS_expr e -> tag "AS_expr" [("expr", json_of_cabs_expression e)]

(* === Storage class specifiers === *)

and json_of_storage_class_specifier = function
  | SC_typedef -> tag0 "SC_typedef"
  | SC_extern -> tag0 "SC_extern"
  | SC_static -> tag0 "SC_static"
  | SC_Thread_local -> tag0 "SC_Thread_local"
  | SC_auto -> tag0 "SC_auto"
  | SC_register -> tag0 "SC_register"

(* === Specifiers record === *)

and json_of_specifiers (s : specifiers) =
  tag "Specifiers" [
    ("storage_classes", json_of_list json_of_storage_class_specifier s.storage_classes);
    ("type_specifiers", json_of_list json_of_cabs_type_specifier s.type_specifiers);
    ("type_qualifiers", json_of_list json_of_cabs_type_qualifier s.type_qualifiers);
    ("function_specifiers", json_of_list json_of_function_specifier s.function_specifiers);
    ("alignment_specifiers", json_of_list json_of_alignment_specifier s.alignment_specifiers)
  ]

(* === Declarators === *)

and json_of_declarator (Declarator (ptr_opt, ddecl)) =
  tag "Declarator" [
    ("pointer", json_of_option json_of_pointer_declarator ptr_opt);
    ("direct", json_of_direct_declarator ddecl)
  ]

and json_of_direct_declarator = function
  | DDecl_identifier (attrs, id) ->
    tag "DDecl_identifier" [
      ("attrs", json_of_attributes attrs);
      ("id", json_of_identifier id)
    ]
  | DDecl_declarator decl ->
    tag "DDecl_declarator" [("declarator", json_of_declarator decl)]
  | DDecl_array (ddecl, adecl) ->
    tag "DDecl_array" [
      ("direct", json_of_direct_declarator ddecl);
      ("array", json_of_array_declarator adecl)
    ]
  | DDecl_function (ddecl, ptl) ->
    tag "DDecl_function" [
      ("direct", json_of_direct_declarator ddecl);
      ("params", json_of_parameter_type_list ptl)
    ]

and json_of_array_declarator (ADecl (loc, tquals, is_static, size_opt)) =
  tag "ADecl" [
    ("loc", json_of_loc loc);
    ("type_qualifiers", json_of_list json_of_cabs_type_qualifier tquals);
    ("is_static", json_of_bool is_static);
    ("size", json_of_option json_of_array_declarator_size size_opt)
  ]

and json_of_array_declarator_size = function
  | ADeclSize_expression e ->
    tag "ADeclSize_expression" [("expr", json_of_cabs_expression e)]
  | ADeclSize_asterisk -> tag0 "ADeclSize_asterisk"

and json_of_pointer_declarator (PDecl (loc, tquals, ptr_opt)) =
  tag "PDecl" [
    ("loc", json_of_loc loc);
    ("type_qualifiers", json_of_list json_of_cabs_type_qualifier tquals);
    ("pointer", json_of_option json_of_pointer_declarator ptr_opt)
  ]

and json_of_parameter_type_list (Params (params, is_variadic)) =
  tag "Params" [
    ("params", json_of_list json_of_parameter_declaration params);
    ("is_variadic", json_of_bool is_variadic)
  ]

and json_of_parameter_declaration = function
  | PDeclaration_decl (specs, decl) ->
    tag "PDeclaration_decl" [
      ("specifiers", json_of_specifiers specs);
      ("declarator", json_of_declarator decl)
    ]
  | PDeclaration_abs_decl (specs, abs_decl_opt) ->
    tag "PDeclaration_abs_decl" [
      ("specifiers", json_of_specifiers specs);
      ("abstract_declarator", json_of_option json_of_abstract_declarator abs_decl_opt)
    ]

(* === Abstract declarators === *)

and json_of_abstract_declarator = function
  | AbsDecl_pointer ptr ->
    tag "AbsDecl_pointer" [("pointer", json_of_pointer_declarator ptr)]
  | AbsDecl_direct (ptr_opt, dabs) ->
    tag "AbsDecl_direct" [
      ("pointer", json_of_option json_of_pointer_declarator ptr_opt);
      ("direct", json_of_direct_abstract_declarator dabs)
    ]

and json_of_direct_abstract_declarator = function
  | DAbs_abs_declarator abs ->
    tag "DAbs_abs_declarator" [("abstract_declarator", json_of_abstract_declarator abs)]
  | DAbs_array (dabs_opt, adecl) ->
    tag "DAbs_array" [
      ("direct", json_of_option json_of_direct_abstract_declarator dabs_opt);
      ("array", json_of_array_declarator adecl)
    ]
  | DAbs_function (dabs_opt, ptl) ->
    tag "DAbs_function" [
      ("direct", json_of_option json_of_direct_abstract_declarator dabs_opt);
      ("params", json_of_parameter_type_list ptl)
    ]

(* === Designators === *)

and json_of_designator = function
  | Desig_array e ->
    tag "Desig_array" [("expr", json_of_cabs_expression e)]
  | Desig_member id ->
    tag "Desig_member" [("member", json_of_identifier id)]

(* === Initializers === *)

and json_of_initializer_ = function
  | Init_expr e ->
    tag "Init_expr" [("expr", json_of_cabs_expression e)]
  | Init_list (loc, inits) ->
    tag "Init_list" [
      ("loc", json_of_loc loc);
      ("inits", json_of_list (fun (desig_opt, init) ->
        `List [
          json_of_option (json_of_list json_of_designator) desig_opt;
          json_of_initializer_ init
        ]) inits)
    ]

(* === GNU builtins === *)

and json_of_gnu_builtin = function
  | GNUbuiltin_types_compatible_p (tn1, tn2) ->
    tag "GNUbuiltin_types_compatible_p" [
      ("type1", json_of_type_name tn1);
      ("type2", json_of_type_name tn2)
    ]
  | GNUbuiltin_choose_expr (e1, e2, e3) ->
    tag "GNUbuiltin_choose_expr" [
      ("cond", json_of_cabs_expression e1);
      ("then_", json_of_cabs_expression e2);
      ("else_", json_of_cabs_expression e3)
    ]

(* === Attributes === *)

and json_of_attribute (attr : Annot.attribute) =
  tag "Attribute" [
    ("ns", json_of_option json_of_identifier attr.attr_ns);
    ("id", json_of_identifier attr.attr_id);
    ("args", json_of_list (fun (loc, s, inner) ->
      `List [
        json_of_loc loc;
        json_of_string s;
        json_of_list (fun (iloc, is) ->
          `List [json_of_loc iloc; json_of_string is]
        ) inner
      ]) attr.attr_args)
  ]

and json_of_attributes (Annot.Attrs attrs) =
  tag "Attrs" [("attrs", json_of_list json_of_attribute attrs)]

(* === Declarations === *)

and json_of_cabs_declaration = function
  | Declaration_base (attrs, specs, init_decls) ->
    tag "Declaration_base" [
      ("attrs", json_of_attributes attrs);
      ("specifiers", json_of_specifiers specs);
      ("init_declarators", json_of_list json_of_init_declarator init_decls)
    ]
  | Declaration_static_assert sa ->
    tag "Declaration_static_assert" [("assert", json_of_static_assert_declaration sa)]

and json_of_init_declarator (InitDecl (loc, decl, init_opt)) =
  tag "InitDecl" [
    ("loc", json_of_loc loc);
    ("declarator", json_of_declarator decl);
    ("initializer", json_of_option json_of_initializer_ init_opt)
  ]

and json_of_static_assert_declaration (Static_assert (e, sl)) =
  tag "Static_assert" [
    ("expr", json_of_cabs_expression e);
    ("msg", json_of_cabs_string_literal sl)
  ]

(* === Function definitions === *)

and json_of_function_definition (FunDef (loc, attrs, specs, decl, body)) =
  tag "FunDef" [
    ("loc", json_of_loc loc);
    ("attrs", json_of_attributes attrs);
    ("specifiers", json_of_specifiers specs);
    ("declarator", json_of_declarator decl);
    ("body", json_of_cabs_statement body)
  ]

(* === Top-level === *)

let json_of_external_declaration = function
  | EDecl_func fdef ->
    tag "EDecl_func" [("def", json_of_function_definition fdef)]
  | EDecl_decl decl ->
    tag "EDecl_decl" [("decl", json_of_cabs_declaration decl)]
  | EDecl_magic (loc, s) ->
    tag "EDecl_magic" [("loc", json_of_loc loc); ("str", json_of_string s)]
  | EDecl_funcCN _ -> tag0 "EDecl_funcCN"
  | EDecl_lemmaCN _ -> tag0 "EDecl_lemmaCN"
  | EDecl_predCN _ -> tag0 "EDecl_predCN"
  | EDecl_datatypeCN _ -> tag0 "EDecl_datatypeCN"
  | EDecl_type_synCN _ -> tag0 "EDecl_type_synCN"
  | EDecl_fun_specCN _ -> tag0 "EDecl_fun_specCN"

let json_of_translation_unit (TUnit decls) =
  tag "TUnit" [("decls", json_of_list json_of_external_declaration decls)]

(* Entry point *)
let to_json = json_of_translation_unit
