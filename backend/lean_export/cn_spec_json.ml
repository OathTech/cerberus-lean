(* CN specification AST to JSON exporter (--cn-spec-json).

   Purpose: for a C file carrying CN magic-comment annotations
   (/*@ ... @*/, lexed under the at_magic_comments switch), emit the CN
   SYNTAX AST as JSON: function specs (requires/ensures/trusted/
   accesses), loop invariants, proof-guidance statements, call-site
   ghost arguments, and the toplevel CN definitions (functions,
   predicates, datatypes, lemmas, type synonyms, prototype specs).

   This is the Cabs-JSON precedent applied to specs: OCaml parses, a
   downstream consumer decodes.  NO checking, NO elaboration — the
   export is syntax-faithful (what was written, not an interpretation).

   Sources of truth:
   - the CN AST is Cn (ocaml_frontend/generated/cn.ml, lem-generated
     from frontend/model/cn.lem), instantiated by the parser at
     'a = Symbol.identifier, 'ty = Cabs.type_name;
   - the C parser attaches CN payloads at exactly four sites (see
     parsers/c/c_parser.mly): toplevel comments arrive ALREADY parsed
     as EDecl_*CN external declarations (parse_loc_string over the
     cn_toplevel start symbol, parsers/c/c_parser_driver.ml:118-141);
     function definitions, loops and block-item statements carry a
     cerb::magic attribute with the raw payload string; calls carry an
     optional cerb::magic attribute (ghost arguments).  The raw-string
     sites are parsed here with the corresponding start symbols
     (fundef_spec / loop_spec / cn_statements / cn_ghost_args), the
     same contract CN itself uses (reference: rems-project/cn
     lib/parse.ml, BSD-2; behavioral reference only, no code taken).

   Fail-closed rules (all fatal, none silently omitted):
   - a CN payload that fails to parse propagates the parser's own
     error (Errors.CPARSER) with its location;
   - >= 2 magic comments on one function/loop ("split specs") are
     rejected, mirroring CN's allow_split_magic_comments = false
     default (cn lib/parse.ml:122-125); the snippet-joining escape
     hatch is deliberately not adopted;
   - a magic attribute in a position the grammar cannot produce (only
     reachable by hand-written [[cerb::magic(...)]] attributes) is an
     error;
   - CN payloads found outside any function body (e.g. inside a
     toplevel initializer via a GNU statement-expression) are exported
     under "stray", never dropped;
   - the Cabs traversal below is EXHAUSTIVE (no wildcard on the
     statement/expression/declaration constructors): a new upstream
     constructor is a compile error here, not a silent omission.

   Schema (v1): see lean_frontend/docs/2026-08-24_cn0-spec-export.md.
   Envelope: {"cn_spec_json_version": 1, "file": ..., "toplevel": [...],
   "functions": [...], "stray": {...}}.  Constructor convention shared
   with Cabs_json: {"tag": Name, <fields>}, nullary constructors as
   bare strings, options as null-or-value, locations in Cabs_json's
   lossless format, arbitrary-precision integers as strings. *)

open Cerb_frontend
open Cn

let tag name args = `Assoc (("tag", `String name) :: args)
let tag0 name = `String name  (* nullary constructor *)

let json_of_loc = Cabs_json.json_of_loc
let json_of_identifier = Cabs_json.json_of_identifier
let json_of_option = Cabs_json.json_of_option
let json_of_list = Cabs_json.json_of_list
let json_of_type_name = Cabs_json.json_of_type_name

let json_of_bignum n = `String (Nat_big_num.to_string n)

(* === CN AST serializers ===================================================
   Mechanical translation of the type definitions in
   ocaml_frontend/generated/cn.ml ('a = Symbol.identifier,
   'ty = Cabs.type_name throughout — the parser's instantiation). *)

let json_of_sign = function
  | CN_unsigned -> tag0 "CN_unsigned"
  | CN_signed -> tag0 "CN_signed"

let rec json_of_base_type = function
  | CN_unit -> tag0 "CN_unit"
  | CN_bool -> tag0 "CN_bool"
  | CN_integer -> tag0 "CN_integer"
  | CN_bits (sign, n) ->
    tag "CN_bits" [("sign", json_of_sign sign); ("width", `Int n)]
  | CN_real -> tag0 "CN_real"
  | CN_loc -> tag0 "CN_loc"
  | CN_alloc_id -> tag0 "CN_alloc_id"
  | CN_struct id -> tag "CN_struct" [("tag_name", json_of_identifier id)]
  | CN_record fields ->
    tag "CN_record" [("fields", json_of_list json_of_field fields)]
  | CN_datatype id -> tag "CN_datatype" [("name", json_of_identifier id)]
  | CN_map (k, v) ->
    tag "CN_map" [("key", json_of_base_type k); ("value", json_of_base_type v)]
  | CN_list bt -> tag "CN_list" [("elem", json_of_base_type bt)]
  | CN_tuple bts -> tag "CN_tuple" [("elems", json_of_list json_of_base_type bts)]
  | CN_set bt -> tag "CN_set" [("elem", json_of_base_type bt)]
  | CN_user_type_name id -> tag "CN_user_type_name" [("name", json_of_identifier id)]
  | CN_c_typedef_name id -> tag "CN_c_typedef_name" [("name", json_of_identifier id)]

and json_of_field (id, bt) =
  `Assoc [("name", json_of_identifier id); ("type", json_of_base_type bt)]

(* an ('a * 'a cn_base_type) binder, as used for args/vars lists *)
let json_of_cn_arg (id, bt) =
  `Assoc [("name", json_of_identifier id); ("type", json_of_base_type bt)]

let json_of_binop = function
  | CN_add -> tag0 "CN_add"
  | CN_sub -> tag0 "CN_sub"
  | CN_mul -> tag0 "CN_mul"
  | CN_div -> tag0 "CN_div"
  | CN_mod -> tag0 "CN_mod"
  | CN_equal -> tag0 "CN_equal"
  | CN_inequal -> tag0 "CN_inequal"
  | CN_lt -> tag0 "CN_lt"
  | CN_le -> tag0 "CN_le"
  | CN_gt -> tag0 "CN_gt"
  | CN_ge -> tag0 "CN_ge"
  | CN_or -> tag0 "CN_or"
  | CN_and -> tag0 "CN_and"
  | CN_implies -> tag0 "CN_implies"
  | CN_map_get -> tag0 "CN_map_get"
  | CN_band -> tag0 "CN_band"
  | CN_bor -> tag0 "CN_bor"
  | CN_bxor -> tag0 "CN_bxor"

let json_of_const = function
  | CNConst_NULL -> tag0 "CNConst_NULL"
  | CNConst_integer n -> tag "CNConst_integer" [("value", json_of_bignum n)]
  | CNConst_bits ((sign, w), n) ->
    tag "CNConst_bits" [
      ("sign", json_of_sign sign);
      ("width", `Int w);
      ("value", json_of_bignum n)
    ]
  | CNConst_bool b -> tag "CNConst_bool" [("value", `Bool b)]
  | CNConst_unit -> tag0 "CNConst_unit"

let json_of_c_kind = function
  | C_kind_var -> tag0 "C_kind_var"
  | C_kind_enum -> tag0 "C_kind_enum"

let rec json_of_pat (CNPat (loc, pat_)) =
  `Assoc [("loc", json_of_loc loc); ("pat", json_of_pat_ pat_)]

and json_of_pat_ = function
  | CNPat_sym id -> tag "CNPat_sym" [("name", json_of_identifier id)]
  | CNPat_wild -> tag0 "CNPat_wild"
  | CNPat_constructor (id, args) ->
    tag "CNPat_constructor" [
      ("name", json_of_identifier id);
      ("args", json_of_list (fun (fld, p) ->
        `Assoc [("field", json_of_identifier fld); ("pat", json_of_pat p)]) args)
    ]

let rec json_of_cn_expr (CNExpr (loc, e_)) =
  `Assoc [("loc", json_of_loc loc); ("expr", json_of_cn_expr_ e_)]

and json_of_cn_expr_ = function
  | CNExpr_const c -> tag "CNExpr_const" [("const", json_of_const c)]
  | CNExpr_var id -> tag "CNExpr_var" [("name", json_of_identifier id)]
  | CNExpr_list es -> tag "CNExpr_list" [("elems", json_of_list json_of_cn_expr es)]
  | CNExpr_memberof (e, member) ->
    tag "CNExpr_memberof" [("expr", json_of_cn_expr e); ("member", json_of_identifier member)]
  | CNExpr_arrow (e, member) ->
    tag "CNExpr_arrow" [("expr", json_of_cn_expr e); ("member", json_of_identifier member)]
  | CNExpr_record fields ->
    tag "CNExpr_record" [("fields", json_of_list json_of_member_expr fields)]
  | CNExpr_struct (id, fields) ->
    tag "CNExpr_struct" [
      ("tag_name", json_of_identifier id);
      ("fields", json_of_list json_of_member_expr fields)
    ]
  | CNExpr_memberupdates (e, updates) ->
    tag "CNExpr_memberupdates" [
      ("expr", json_of_cn_expr e);
      ("updates", json_of_list json_of_member_expr updates)
    ]
  | CNExpr_arrayindexupdates (e, updates) ->
    tag "CNExpr_arrayindexupdates" [
      ("expr", json_of_cn_expr e);
      ("updates", json_of_list (fun (i, v) ->
        `Assoc [("index", json_of_cn_expr i); ("value", json_of_cn_expr v)]) updates)
    ]
  | CNExpr_binop (op, e1, e2) ->
    tag "CNExpr_binop" [
      ("op", json_of_binop op);
      ("e1", json_of_cn_expr e1);
      ("e2", json_of_cn_expr e2)
    ]
  | CNExpr_sizeof ty -> tag "CNExpr_sizeof" [("type", json_of_type_name ty)]
  | CNExpr_offsetof (id, member) ->
    tag "CNExpr_offsetof" [("tag_name", json_of_identifier id); ("member", json_of_identifier member)]
  | CNExpr_membershift (e, ty_opt, member) ->
    tag "CNExpr_membershift" [
      ("expr", json_of_cn_expr e);
      ("type", json_of_option json_of_type_name ty_opt);
      ("member", json_of_identifier member)
    ]
  | CNExpr_addr id -> tag "CNExpr_addr" [("name", json_of_identifier id)]
  | CNExpr_cast (bt, e) ->
    tag "CNExpr_cast" [("type", json_of_base_type bt); ("expr", json_of_cn_expr e)]
  | CNExpr_array_shift (base, ty_opt, index) ->
    tag "CNExpr_array_shift" [
      ("base", json_of_cn_expr base);
      ("type", json_of_option json_of_type_name ty_opt);
      ("index", json_of_cn_expr index)
    ]
  | CNExpr_call (id, args) ->
    tag "CNExpr_call" [("name", json_of_identifier id); ("args", json_of_list json_of_cn_expr args)]
  | CNExpr_cons (id, args) ->
    tag "CNExpr_cons" [
      ("name", json_of_identifier id);
      ("args", json_of_list json_of_member_expr args)
    ]
  | CNExpr_each (id, bt, (lo, hi), body) ->
    tag "CNExpr_each" [
      ("var", json_of_identifier id);
      ("type", json_of_base_type bt);
      ("lo", json_of_bignum lo);
      ("hi", json_of_bignum hi);
      ("body", json_of_cn_expr body)
    ]
  | CNExpr_let (id, e1, e2) ->
    tag "CNExpr_let" [
      ("var", json_of_identifier id);
      ("value", json_of_cn_expr e1);
      ("body", json_of_cn_expr e2)
    ]
  | CNExpr_match (e, cases) ->
    tag "CNExpr_match" [
      ("scrutinee", json_of_cn_expr e);
      ("cases", json_of_list (fun (p, body) ->
        `Assoc [("pat", json_of_pat p); ("body", json_of_cn_expr body)]) cases)
    ]
  | CNExpr_ite (c, t, e) ->
    tag "CNExpr_ite" [
      ("cond", json_of_cn_expr c);
      ("then", json_of_cn_expr t);
      ("else", json_of_cn_expr e)
    ]
  | CNExpr_good (ty, e) ->
    tag "CNExpr_good" [("type", json_of_type_name ty); ("expr", json_of_cn_expr e)]
  | CNExpr_deref e -> tag "CNExpr_deref" [("expr", json_of_cn_expr e)]
  | CNExpr_value_of_c_atom (id, kind) ->
    tag "CNExpr_value_of_c_atom" [("name", json_of_identifier id); ("kind", json_of_c_kind kind)]
  | CNExpr_unchanged e -> tag "CNExpr_unchanged" [("expr", json_of_cn_expr e)]
  | CNExpr_at_env (e, env) ->
    tag "CNExpr_at_env" [("expr", json_of_cn_expr e); ("env", `String env)]
  | CNExpr_not e -> tag "CNExpr_not" [("expr", json_of_cn_expr e)]
  | CNExpr_negate e -> tag "CNExpr_negate" [("expr", json_of_cn_expr e)]
  | CNExpr_default bt -> tag "CNExpr_default" [("type", json_of_base_type bt)]
  | CNExpr_bnot e -> tag "CNExpr_bnot" [("expr", json_of_cn_expr e)]

and json_of_member_expr (id, e) =
  `Assoc [("field", json_of_identifier id); ("value", json_of_cn_expr e)]

let json_of_cn_pred = function
  | CN_owned ty_opt -> tag "CN_owned" [("type", json_of_option json_of_type_name ty_opt)]
  | CN_block ty_opt -> tag "CN_block" [("type", json_of_option json_of_type_name ty_opt)]
  | CN_named id -> tag "CN_named" [("name", json_of_identifier id)]

let json_of_resource = function
  | CN_pred (loc, pred, args) ->
    tag "CN_pred" [
      ("loc", json_of_loc loc);
      ("pred", json_of_cn_pred pred);
      ("args", json_of_list json_of_cn_expr args)
    ]
  | CN_each (id, bt, guard, loc, pred, args) ->
    tag "CN_each" [
      ("var", json_of_identifier id);
      ("type", json_of_base_type bt);
      ("guard", json_of_cn_expr guard);
      ("loc", json_of_loc loc);
      ("pred", json_of_cn_pred pred);
      ("args", json_of_list json_of_cn_expr args)
    ]

let json_of_assertion = function
  | CN_assert_exp e -> tag "CN_assert_exp" [("expr", json_of_cn_expr e)]
  | CN_assert_qexp (id, bt, guard, body) ->
    tag "CN_assert_qexp" [
      ("var", json_of_identifier id);
      ("type", json_of_base_type bt);
      ("guard", json_of_cn_expr guard);
      ("body", json_of_cn_expr body)
    ]

let rec json_of_clause = function
  | CN_letResource (loc, id, res, rest) ->
    tag "CN_letResource" [
      ("loc", json_of_loc loc);
      ("name", json_of_identifier id);
      ("resource", json_of_resource res);
      ("rest", json_of_clause rest)
    ]
  | CN_letExpr (loc, id, e, rest) ->
    tag "CN_letExpr" [
      ("loc", json_of_loc loc);
      ("name", json_of_identifier id);
      ("value", json_of_cn_expr e);
      ("rest", json_of_clause rest)
    ]
  | CN_assert (loc, assertion, rest) ->
    tag "CN_assert" [
      ("loc", json_of_loc loc);
      ("assertion", json_of_assertion assertion);
      ("rest", json_of_clause rest)
    ]
  | CN_return (loc, e) ->
    tag "CN_return" [("loc", json_of_loc loc); ("expr", json_of_cn_expr e)]

let rec json_of_clauses = function
  | CN_clause (loc, clause) ->
    tag "CN_clause" [("loc", json_of_loc loc); ("clause", json_of_clause clause)]
  | CN_if (loc, cond, then_clause, else_clauses) ->
    tag "CN_if" [
      ("loc", json_of_loc loc);
      ("cond", json_of_cn_expr cond);
      ("then", json_of_clause then_clause);
      ("else", json_of_clauses else_clauses)
    ]

let json_of_condition = function
  | CN_cletResource (loc, id, res) ->
    tag "CN_cletResource" [
      ("loc", json_of_loc loc);
      ("name", json_of_identifier id);
      ("resource", json_of_resource res)
    ]
  | CN_cletExpr (loc, id, e) ->
    tag "CN_cletExpr" [
      ("loc", json_of_loc loc);
      ("name", json_of_identifier id);
      ("value", json_of_cn_expr e)
    ]
  | CN_cconstr (loc, assertion) ->
    tag "CN_cconstr" [("loc", json_of_loc loc); ("assertion", json_of_assertion assertion)]

let json_of_cn_function (f : (Symbol.identifier, Cabs.type_name) cn_function) =
  tag "CN_function" [
    ("magic_loc", json_of_loc f.cn_func_magic_loc);
    ("loc", json_of_loc f.cn_func_loc);
    ("name", json_of_identifier f.cn_func_name);
    ("attrs", json_of_list json_of_identifier f.cn_func_attrs);
    ("args", json_of_list json_of_cn_arg f.cn_func_args);
    ("body", json_of_option json_of_cn_expr f.cn_func_body);
    ("return_type", json_of_base_type f.cn_func_return_bty)
  ]

let json_of_cn_lemma (l : (Symbol.identifier, Cabs.type_name) cn_lemma) =
  tag "CN_lemma" [
    ("magic_loc", json_of_loc l.cn_lemma_magic_loc);
    ("loc", json_of_loc l.cn_lemma_loc);
    ("name", json_of_identifier l.cn_lemma_name);
    ("args", json_of_list json_of_cn_arg l.cn_lemma_args);
    ("requires", json_of_list json_of_condition l.cn_lemma_requires);
    ("ensures", json_of_list json_of_condition l.cn_lemma_ensures)
  ]

let json_of_cn_predicate (p : (Symbol.identifier, Cabs.type_name) cn_predicate) =
  let (out_loc, out_bty) = p.cn_pred_output in
  tag "CN_predicate" [
    ("magic_loc", json_of_loc p.cn_pred_magic_loc);
    ("loc", json_of_loc p.cn_pred_loc);
    ("name", json_of_identifier p.cn_pred_name);
    ("attrs", json_of_list json_of_identifier p.cn_pred_attrs);
    ("output_loc", json_of_loc out_loc);
    ("output_type", json_of_base_type out_bty);
    ("iargs", json_of_list json_of_cn_arg p.cn_pred_iargs);
    ("clauses", json_of_option json_of_clauses p.cn_pred_clauses)
  ]

let json_of_cn_datatype (dt : Symbol.identifier cn_datatype) =
  tag "CN_datatype" [
    ("magic_loc", json_of_loc dt.cn_dt_magic_loc);
    ("loc", json_of_loc dt.cn_dt_loc);
    ("name", json_of_identifier dt.cn_dt_name);
    ("cases", json_of_list (fun (ctor, fields) ->
      `Assoc [
        ("name", json_of_identifier ctor);
        ("fields", json_of_list json_of_field fields)
      ]) dt.cn_dt_cases)
  ]

let json_of_cn_type_synonym (ts : Symbol.identifier cn_type_synonym) =
  tag "CN_type_synonym" [
    ("magic_loc", json_of_loc ts.cn_tysyn_magic_loc);
    ("loc", json_of_loc ts.cn_tysyn_loc);
    ("name", json_of_identifier ts.cn_tysyn_name);
    ("rhs", json_of_base_type ts.cn_tysyn_rhs)
  ]

let json_of_acc_func = function
  | CN_accesses ids -> tag "CN_accesses" [("names", json_of_list json_of_identifier ids)]
  | CN_mk_function id -> tag "CN_mk_function" [("name", json_of_identifier id)]

let json_of_cond_block (loc, (vars, conds)) =
  `Assoc [
    ("loc", json_of_loc loc);
    ("vars", json_of_list json_of_cn_arg vars);
    ("conditions", json_of_list json_of_condition conds)
  ]

let json_of_func_spec (s : (Symbol.identifier, Cabs.type_name) cn_func_spec) =
  tag "CN_func_spec" [
    ("trusted", json_of_option json_of_loc s.cn_func_trusted);
    ("acc_func", json_of_option (fun (loc, af) ->
      `Assoc [("loc", json_of_loc loc); ("func", json_of_acc_func af)]) s.cn_func_acc_func);
    ("requires", json_of_option json_of_cond_block s.cn_func_requires);
    ("ensures", json_of_option json_of_cond_block s.cn_func_ensures)
  ]

let json_of_cn_decl_spec (s : (Symbol.identifier, Cabs.type_name) cn_decl_spec) =
  tag "CN_decl_spec" [
    ("loc", json_of_loc s.cn_decl_loc);
    ("name", json_of_identifier s.cn_decl_name);
    ("args", json_of_list json_of_cn_arg s.cn_decl_args);
    ("spec", json_of_func_spec s.cn_func_spec)
  ]

let json_of_pack_unpack = function
  | Pack -> tag0 "Pack"
  | Unpack -> tag0 "Unpack"

let json_of_to_from = function
  | To -> tag0 "To"
  | From -> tag0 "From"

let json_of_to_instantiate = function
  | I_Function id -> tag "I_Function" [("name", json_of_identifier id)]
  | I_Good ty -> tag "I_Good" [("type", json_of_type_name ty)]
  | I_Everything -> tag0 "I_Everything"

let json_of_to_extract = function
  | E_Pred pred -> tag "E_Pred" [("pred", json_of_cn_pred pred)]
  | E_Everything -> tag0 "E_Everything"

let json_of_cn_statement (CN_statement (loc, stmt_)) =
  let body = match stmt_ with
    | CN_pack_unpack (pu, pred, args_opt) ->
      tag "CN_pack_unpack" [
        ("kind", json_of_pack_unpack pu);
        ("pred", json_of_cn_pred pred);
        ("args", json_of_option (json_of_list json_of_cn_expr) args_opt)
      ]
    | CN_to_from_bytes (tf, pred, args) ->
      tag "CN_to_from_bytes" [
        ("kind", json_of_to_from tf);
        ("pred", json_of_cn_pred pred);
        ("args", json_of_list json_of_cn_expr args)
      ]
    | CN_have assertion -> tag "CN_have" [("assertion", json_of_assertion assertion)]
    | CN_instantiate (ti, e) ->
      tag "CN_instantiate" [
        ("target", json_of_to_instantiate ti);
        ("expr", json_of_cn_expr e)
      ]
    | CN_split_case assertion -> tag "CN_split_case" [("assertion", json_of_assertion assertion)]
    | CN_extract (attrs, te, e) ->
      tag "CN_extract" [
        ("attrs", json_of_list json_of_identifier attrs);
        ("target", json_of_to_extract te);
        ("expr", json_of_cn_expr e)
      ]
    | CN_unfold (id, args) ->
      tag "CN_unfold" [("name", json_of_identifier id); ("args", json_of_list json_of_cn_expr args)]
    | CN_assert_stmt assertion -> tag "CN_assert_stmt" [("assertion", json_of_assertion assertion)]
    | CN_apply (id, args) ->
      tag "CN_apply" [("name", json_of_identifier id); ("args", json_of_list json_of_cn_expr args)]
    | CN_inline ids -> tag "CN_inline" [("names", json_of_list json_of_identifier ids)]
    | CN_print e -> tag "CN_print" [("expr", json_of_cn_expr e)]
    | CN_derive_constraints preds ->
      tag "CN_derive_constraints" [
        ("preds", json_of_list (fun (pred, args_opt) ->
          `Assoc [
            ("pred", json_of_cn_pred pred);
            ("args", json_of_option (json_of_list json_of_cn_expr) args_opt)
          ]) preds)
      ]
  in
  `Assoc [("loc", json_of_loc loc); ("stmt", body)]

(* === The walk =============================================================
   Finds the raw-string cerb::magic attachment sites in Cabs and parses
   them with the fork's own CN start symbols.  Errors are raised as
   Export_error and converted to the pipeline exception monad at the
   export boundary (fail-closed: no payload is ever skipped). *)

exception Export_error of Cerb_location.t * Errors.cause

let export_error loc msg = raise (Export_error (loc, Errors.UNSUPPORTED msg))

let parse_magic start pair =
  match C_parser_driver.parse_loc_string start pair with
  | Exception.Result r -> r
  | Exception.Exception (loc, cause) -> raise (Export_error (loc, cause))

(* the (loc, payload-string) pairs of the cerb::magic attributes *)
let magic_of_attrs attrs = Annot.get_cerb_magic_attr [Annot.Aattrs attrs]

(* CN payloads collected from one function body (or from outside all
   function bodies, the "stray" bucket) *)
type collected = {
  mutable loops : Yojson.Safe.t list;        (* reversed *)
  mutable magic_stmts : Yojson.Safe.t list;  (* reversed *)
  mutable ghost_calls : Yojson.Safe.t list;  (* reversed *)
}

let fresh_collected () = { loops = []; magic_stmts = []; ghost_calls = [] }

let json_of_collected acc =
  [ ("loops", `List (List.rev acc.loops));
    ("statements", `List (List.rev acc.magic_stmts));
    ("ghost_calls", `List (List.rev acc.ghost_calls)) ]

let rec ident_of_direct_declarator = function
  | Cabs.DDecl_identifier (_, id) -> id
  | Cabs.DDecl_declarator (Cabs.Declarator (_, dd))
  | Cabs.DDecl_array (dd, _)
  | Cabs.DDecl_function (dd, _) -> ident_of_direct_declarator dd

let ident_of_declarator (Cabs.Declarator (_, dd)) = ident_of_direct_declarator dd

open Cabs  (* everything below is over the Cabs surface tree *)

let rec walk_statement acc (CabsStatement (sloc, attrs, stmt_)) =
  (* payload extraction at this node *)
  begin match stmt_, magic_of_attrs attrs with
  | _, [] -> ()
  | (CabsSwhile _ | CabsSdo _ | CabsSfor _), [pair] ->
    let CN_inv (inv_loc, conds) = parse_magic C_parser.loop_spec pair in
    acc.loops <- `Assoc [
      ("loc", json_of_loc sloc);
      ("kind", `String (match stmt_ with
        | CabsSwhile _ -> "while" | CabsSdo _ -> "do" | _ -> "for"));
      ("inv_loc", json_of_loc inv_loc);
      ("invariants", json_of_list json_of_condition conds)
    ] :: acc.loops
  | (CabsSwhile _ | CabsSdo _ | CabsSfor _), (loc1, _) :: _ ->
    export_error loc1
      "cn-spec-json: split magic comments on a loop are not supported \
       (one /*@ inv ... @*/ comment per loop)"
  | CabsSmarker _, pairs ->
    List.iter (fun ((mloc, _) as pair) ->
      let stmts = parse_magic C_parser.cn_statements pair in
      acc.magic_stmts <- `Assoc [
        ("loc", json_of_loc mloc);
        ("stmts", json_of_list json_of_cn_statement stmts)
      ] :: acc.magic_stmts) pairs
  | _, (loc1, _) :: _ ->
    export_error loc1
      "cn-spec-json: cerb::magic attribute in an unexpected statement position"
  end;
  (* exhaustive descent *)
  match stmt_ with
  | CabsSlabel (_, s) -> walk_statement acc s
  | CabsScase (e, s) -> walk_expression acc e; walk_statement acc s
  | CabsSdefault s -> walk_statement acc s
  | CabsSblock ss -> List.iter (walk_statement acc) ss
  | CabsSdecl decl -> walk_declaration acc decl
  | CabsSnull -> ()
  | CabsSexpr e -> walk_expression acc e
  | CabsSif (e, s1, s2_opt) ->
    walk_expression acc e; walk_statement acc s1;
    Option.iter (walk_statement acc) s2_opt
  | CabsSswitch (e, s) -> walk_expression acc e; walk_statement acc s
  | CabsSwhile (e, s) -> walk_expression acc e; walk_statement acc s
  | CabsSdo (e, s) -> walk_expression acc e; walk_statement acc s
  | CabsSfor (fc_opt, e2_opt, e3_opt, s) ->
    Option.iter (function
      | FC_expr e -> walk_expression acc e
      | FC_decl (_, decl) -> walk_declaration acc decl) fc_opt;
    Option.iter (walk_expression acc) e2_opt;
    Option.iter (walk_expression acc) e3_opt;
    walk_statement acc s
  | CabsSgoto _ -> ()
  | CabsScontinue -> ()
  | CabsSbreak -> ()
  | CabsSreturn e_opt -> Option.iter (walk_expression acc) e_opt
  | CabsSpar ss -> List.iter (walk_statement acc) ss
  | CabsSasm (_, _, _) -> ()
  | CabsScaseGNU (e1, e2, s) ->
    walk_expression acc e1; walk_expression acc e2; walk_statement acc s
  | CabsSmarker s -> walk_statement acc s

and walk_expression acc (CabsExpression (_, expr_)) =
  match expr_ with
  | CabsEident _ -> ()
  | CabsEconst _ -> ()
  | CabsEstring _ -> ()
  | CabsEgeneric (e, assocs) ->
    walk_expression acc e;
    List.iter (function
      | GA_type (ty, e) -> walk_type_name acc ty; walk_expression acc e
      | GA_default e -> walk_expression acc e) assocs
  | CabsEsubscript (e1, e2) -> walk_expression acc e1; walk_expression acc e2
  | CabsEcall (f, args, attrs_opt) ->
    walk_expression acc f;
    List.iter (walk_expression acc) args;
    Option.iter (fun attrs ->
      List.iter (fun ((mloc, _) as pair) ->
        let (ghost_exprs, ghost_idents) = parse_magic C_parser.cn_ghost_args pair in
        acc.ghost_calls <- `Assoc [
          ("loc", json_of_loc mloc);
          ("exprs", json_of_list json_of_cn_expr ghost_exprs);
          ("idents", json_of_list json_of_identifier ghost_idents)
        ] :: acc.ghost_calls) (magic_of_attrs attrs)) attrs_opt
  | CabsEmemberof (e, _) -> walk_expression acc e
  | CabsEmemberofptr (e, _) -> walk_expression acc e
  | CabsEpostincr e -> walk_expression acc e
  | CabsEpostdecr e -> walk_expression acc e
  | CabsEcompound (ty, inits) ->
    walk_type_name acc ty;
    List.iter (fun (desigs_opt, init) ->
      Option.iter (List.iter (walk_designator acc)) desigs_opt;
      walk_initializer acc init) inits
  | CabsEpreincr e -> walk_expression acc e
  | CabsEpredecr e -> walk_expression acc e
  | CabsEunary (_, e) -> walk_expression acc e
  | CabsEsizeof_expr e -> walk_expression acc e
  | CabsEsizeof_type ty -> walk_type_name acc ty
  | CabsEalignof ty -> walk_type_name acc ty
  | CabsEcast (ty, e) -> walk_type_name acc ty; walk_expression acc e
  | CabsEbinary (_, e1, e2) -> walk_expression acc e1; walk_expression acc e2
  | CabsEcond (e1, e2, e3) ->
    walk_expression acc e1; walk_expression acc e2; walk_expression acc e3
  | CabsEassign (_, e1, e2) -> walk_expression acc e1; walk_expression acc e2
  | CabsEcomma (e1, e2) -> walk_expression acc e1; walk_expression acc e2
  | CabsEassert e -> walk_expression acc e
  | CabsEoffsetof (ty, _) -> walk_type_name acc ty
  | CabsEva_start (e, _) -> walk_expression acc e
  | CabsEva_copy (e1, e2) -> walk_expression acc e1; walk_expression acc e2
  | CabsEva_arg (e, ty) -> walk_expression acc e; walk_type_name acc ty
  | CabsEva_end e -> walk_expression acc e
  | CabsEprint_type e -> walk_expression acc e
  | CabsEbmc_assume e -> walk_expression acc e
  | CabsEgcc_statement ss -> List.iter (walk_statement acc) ss
  | CabsEcondGNU (e1, e2) -> walk_expression acc e1; walk_expression acc e2
  | CabsEbuiltinGNU (GNUbuiltin_types_compatible_p (ty1, ty2)) ->
    walk_type_name acc ty1; walk_type_name acc ty2
  | CabsEbuiltinGNU (GNUbuiltin_choose_expr (e1, e2, e3)) ->
    walk_expression acc e1; walk_expression acc e2; walk_expression acc e3

and walk_declaration acc = function
  | Declaration_base (_, specifs, init_decls) ->
    walk_specifiers acc specifs;
    List.iter (fun (InitDecl (_, decltor, init_opt)) ->
      walk_declarator acc decltor;
      Option.iter (walk_initializer acc) init_opt) init_decls
  | Declaration_static_assert (Static_assert (e, _)) -> walk_expression acc e

and walk_specifiers acc specifs =
  List.iter (walk_type_specifier acc) specifs.type_specifiers;
  List.iter (walk_alignment_specifier acc) specifs.alignment_specifiers

and walk_type_specifier acc (TSpec (_, tspec_)) =
  match tspec_ with
  | TSpec_void | TSpec_char | TSpec_short | TSpec_int | TSpec_long
  | TSpec_float | TSpec_double | TSpec_signed | TSpec_unsigned
  | TSpec_Bool | TSpec_Complex | TSpec_name _ -> ()
  | TSpec_Atomic ty -> walk_type_name acc ty
  | TSpec_struct (_, _, sdecls_opt) | TSpec_union (_, _, sdecls_opt) ->
    Option.iter (List.iter (walk_struct_declaration acc)) sdecls_opt
  | TSpec_enum (_, enums_opt) ->
    Option.iter (List.iter (fun (_, e_opt) ->
      Option.iter (walk_expression acc) e_opt)) enums_opt
  | TSpec_typeof_expr e -> walk_expression acc e
  | TSpec_typeof_type ty -> walk_type_name acc ty

and walk_struct_declaration acc = function
  | Struct_declaration (_, tspecs, _, aligns, sdecltors) ->
    List.iter (walk_type_specifier acc) tspecs;
    List.iter (walk_alignment_specifier acc) aligns;
    List.iter (function
      | SDecl_simple decltor -> walk_declarator acc decltor
      | SDecl_bitfield (decltor_opt, e) ->
        Option.iter (walk_declarator acc) decltor_opt;
        walk_expression acc e) sdecltors
  | Struct_assert (Static_assert (e, _)) -> walk_expression acc e

and walk_alignment_specifier acc = function
  | AS_type ty -> walk_type_name acc ty
  | AS_expr e -> walk_expression acc e

and walk_declarator acc (Declarator (_, ddecl)) =
  walk_direct_declarator acc ddecl

and walk_direct_declarator acc = function
  | DDecl_identifier _ -> ()
  | DDecl_declarator decltor -> walk_declarator acc decltor
  | DDecl_array (ddecl, adecl) ->
    walk_direct_declarator acc ddecl; walk_array_declarator acc adecl
  | DDecl_function (ddecl, params) ->
    walk_direct_declarator acc ddecl; walk_parameter_type_list acc params

and walk_array_declarator acc (ADecl (_, _, _, size_opt)) =
  Option.iter (function
    | ADeclSize_expression e -> walk_expression acc e
    | ADeclSize_asterisk -> ()) size_opt

and walk_parameter_type_list acc (Params (params, _)) =
  List.iter (function
    | PDeclaration_decl (specifs, decltor) ->
      walk_specifiers acc specifs; walk_declarator acc decltor
    | PDeclaration_abs_decl (specifs, absdecl_opt) ->
      walk_specifiers acc specifs;
      Option.iter (walk_abstract_declarator acc) absdecl_opt) params

and walk_type_name acc (Type_name (tspecs, _, aligns, absdecl_opt)) =
  List.iter (walk_type_specifier acc) tspecs;
  List.iter (walk_alignment_specifier acc) aligns;
  Option.iter (walk_abstract_declarator acc) absdecl_opt

and walk_abstract_declarator acc = function
  | AbsDecl_pointer _ -> ()
  | AbsDecl_direct (_, dabs) -> walk_direct_abstract_declarator acc dabs

and walk_direct_abstract_declarator acc = function
  | DAbs_abs_declarator absdecl -> walk_abstract_declarator acc absdecl
  | DAbs_array (dabs_opt, adecl) ->
    Option.iter (walk_direct_abstract_declarator acc) dabs_opt;
    walk_array_declarator acc adecl
  | DAbs_function (dabs_opt, params) ->
    Option.iter (walk_direct_abstract_declarator acc) dabs_opt;
    walk_parameter_type_list acc params

and walk_initializer acc = function
  | Init_expr e -> walk_expression acc e
  | Init_list (_, inits) ->
    List.iter (fun (desigs_opt, init) ->
      Option.iter (List.iter (walk_designator acc)) desigs_opt;
      walk_initializer acc init) inits

and walk_designator acc = function
  | Desig_array e -> walk_expression acc e
  | Desig_member _ -> ()

(* === Entry point ========================================================== *)

let export_function (FunDef (floc, attrs, specifs, decltor, body)) =
  let acc = fresh_collected () in
  let spec = match magic_of_attrs attrs with
    | [] -> `Null
    | [pair] -> json_of_func_spec (parse_magic C_parser.fundef_spec pair)
    | (loc1, _) :: _ ->
      export_error loc1
        "cn-spec-json: split magic comments on a function definition are \
         not supported (one /*@ ... @*/ comment per function)"
  in
  walk_specifiers acc specifs;
  walk_declarator acc decltor;
  walk_statement acc body;
  let Symbol.Identifier (name_loc, name) = ident_of_declarator decltor in
  `Assoc ([
    ("name", `String name);
    ("name_loc", json_of_loc name_loc);
    ("def_loc", json_of_loc floc);
    ("spec", spec)
  ] @ json_of_collected acc)

let export ~filename (TUnit edecls) =
  try
    let stray = fresh_collected () in
    let toplevel = ref [] in    (* reversed *)
    let functions = ref [] in   (* reversed *)
    List.iter (function
      | EDecl_func fdef ->
        functions := export_function fdef :: !functions
      | EDecl_decl decl ->
        walk_declaration stray decl
      | EDecl_magic (loc, _) ->
        (* C_parser_driver.parse always re-parses toplevel magic comments
           via the cn_toplevel start symbol (c_parser_driver.ml:118-141);
           one surviving here means that contract broke. *)
        export_error loc
          "cn-spec-json: internal invariant violated — unparsed toplevel \
           magic comment survived the parser driver"
      | EDecl_funcCN f -> toplevel := json_of_cn_function f :: !toplevel
      | EDecl_lemmaCN l -> toplevel := json_of_cn_lemma l :: !toplevel
      | EDecl_predCN p -> toplevel := json_of_cn_predicate p :: !toplevel
      | EDecl_datatypeCN dt -> toplevel := json_of_cn_datatype dt :: !toplevel
      | EDecl_type_synCN ts -> toplevel := json_of_cn_type_synonym ts :: !toplevel
      | EDecl_fun_specCN s -> toplevel := json_of_cn_decl_spec s :: !toplevel
    ) edecls;
    Exception.except_return (`Assoc [
      ("cn_spec_json_version", `Int 1);
      ("file", `String filename);
      ("toplevel", `List (List.rev !toplevel));
      ("functions", `List (List.rev !functions));
      ("stray", `Assoc (json_of_collected stray))
    ])
  with Export_error (loc, cause) -> Exception.fail (loc, cause)
