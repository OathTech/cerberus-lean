(* Ail maximum-symbol-id fold — the desugar high-water mark feeding the
   arc-12 F-D fail-stop floor (util/cerb_fresh.ml set_desugar_hwm; design +
   soundness argument: lean_frontend/docs/2026-08-21_arc12-s0-floor-design.md
   §4.3).

   Returns the maximum symbol NUMBER occurring anywhere in a desugared Ail
   program (-1 if none), including:
     - every Symbol.sym in the tree (declarations, definitions, binders,
       labels incl. the freshify'd __cerb_continue AilSlabel syms, gotos,
       struct/union tags inside ctypes, typedef/inlined-label annotations,
       extern-idmap and typedef-attribute entries);
     - the desugar-drawn NAT ids that live in the tree without being wrapped
       in a Symbol (loop ids on AilSwhile/AilSdo + loop_attributes keys,
       marker ids on AilSmarker / Amarker / loop_attribute.marker_id, the
       per-function-definition marker int): a Symbol is not known to be
       constructed from these, but they are desugar-supply draws, so noting
       them only tightens the mark toward the true supply high water — never
       above it.

   Digest note: symbols of foreign digests reachable here are only the core
   stdlib ailname symbols (ids below the std.core parse budget, hence below
   any TU's first ambient id), so a digest-blind max is sound and never
   false-fires the floor's checks (design note §4.3).

   STYLE RULE (load-bearing): NO catch-all constructor arms anywhere in this
   file — a new constructor in any walked type must break this compile, not
   silently escape the fold. Fields deliberately not walked are bound with
   named-wildcard patterns in place.

   CN declarations (cn_functions/lemmata/predicates/datatypes/decl_specs)
   are refused LOUDLY when present: this fold does not cover the Cn ASTs,
   and the cerberus driver paths guarded by the floor never populate them.
   Fail-closed beats a silent hole. *)

open Cerb_frontend
open AilSyntax

let max_sym_program ((_main_opt : ail_identifier option), (sigma : 'a sigma))
    : int =
  let m = ref (-1) in
  let note n = if n > !m then m := n in
  let note_sym (Symbol.Symbol (_dig, n, _descr)) = note n in
  let note_opt f = function None -> () | Some x -> f x in

  (* ---- Ctype ---- *)
  let rec walk_ctype (Ctype.Ctype (annots, ct_)) =
    walk_annots annots;
    walk_ctype_ ct_

  and walk_ctype_ = function
    | Ctype.Void -> ()
    | Ctype.Basic _bty -> ()
    | Ctype.Array (ct, _n_opt) -> walk_ctype ct
    | Ctype.Function ((_q, ret_ct), params, _variadic) ->
        walk_ctype ret_ct;
        List.iter (fun (_q, ct, _reg) -> walk_ctype ct) params
    | Ctype.FunctionNoParams (_q, ret_ct) -> walk_ctype ret_ct
    | Ctype.Pointer (_q, ct) -> walk_ctype ct
    | Ctype.Atomic ct -> walk_ctype ct
    | Ctype.Struct tag -> note_sym tag
    | Ctype.Union tag -> note_sym tag
    | Ctype.Byte -> ()

  (* ---- Annot ---- *)
  and walk_annots annots = List.iter walk_annot annots

  and walk_annot = function
    | Annot.Astd _ -> ()
    | Annot.Aloc _ -> ()
    | Annot.Auid _ -> ()
    | Annot.Amarker id -> note id
    | Annot.Amarker_object_types id -> note id
    | Annot.Abmc (Annot.Abmc_id _) -> ()
    | Annot.Aattrs _attrs -> ()   (* attributes: identifier/string payloads only *)
    | Annot.Atypedef sym -> note_sym sym
    | Annot.Alabel la -> walk_label_annot la
    | Annot.Acerb (Annot.ACerb_with_address _) -> ()
    | Annot.Acerb Annot.ACerb_hidden -> ()
    | Annot.Avalue (Annot.Ainteger _) -> ()
    | Annot.Ainlined_label (_loc, sym, la) -> note_sym sym; walk_label_annot la
    | Annot.Astmt -> ()
    | Annot.Aexpr -> ()

  and walk_label_annot = function
    | Annot.LAloop id -> note id
    | Annot.LAloop_continue id -> note id
    | Annot.LAloop_break id -> note id
    | Annot.LAreturn -> ()
    | Annot.LAswitch -> ()
    | Annot.LAcase -> ()
    | Annot.LAdefault -> ()
    | Annot.LAactual_label -> ()
  in

  let walk_alignment = function
    | Ctype.AlignInteger _ -> ()
    | Ctype.AlignType ct -> walk_ctype ct
  in
  let walk_bindings bindings =
    List.iter
      (fun (sym, ((_loc, _dur, _reg), align_opt, _q, ct)) ->
        note_sym sym;
        note_opt walk_alignment align_opt;
        walk_ctype ct)
      bindings
  in

  (* ---- expressions / statements (mutually recursive) ---- *)
  let rec walk_expr (AnnotatedExpression (_a, annots, _loc, e_)) =
    walk_annots annots;
    walk_expr_ e_

  and walk_expr_ = function
    | AilEunary (_op, e) -> walk_expr e
    | AilEbinary (e1, _op, e2) -> walk_expr e1; walk_expr e2
    | AilEassign (e1, e2) -> walk_expr e1; walk_expr e2
    | AilEcompoundAssign (e1, _op, e2) -> walk_expr e1; walk_expr e2
    | AilEcond (e1, e2_opt, e3) ->
        walk_expr e1; note_opt walk_expr e2_opt; walk_expr e3
    | AilEcast (_q, ct, e) -> walk_ctype ct; walk_expr e
    | AilEcall (e, es) -> walk_expr e; List.iter walk_expr es
    | AilEassert e -> walk_expr e
    | AilEoffsetof (ct, _member_ident) -> walk_ctype ct
    | AilEgeneric (e, _idx_opt, gas) ->
        walk_expr e; List.iter walk_generic_association gas
    | AilEarray (_from_str, ct, e_opts) ->
        walk_ctype ct; List.iter (note_opt walk_expr) e_opts
    | AilEstruct (tag, members) ->
        note_sym tag;
        List.iter (fun (_member_ident, e_opt) -> note_opt walk_expr e_opt)
          members
    | AilEunion (tag, _member_ident, e_opt) ->
        note_sym tag; note_opt walk_expr e_opt
    | AilEcompound (_q, ct, e) -> walk_ctype ct; walk_expr e
    | AilEmemberof (e, _member_ident) -> walk_expr e
    | AilEmemberofptr (e, _member_ident) -> walk_expr e
    | AilEbuiltin _b -> ()
    | AilEstr _lit -> ()
    | AilEconst _c -> ()
    | AilEident sym -> note_sym sym
    | AilEsizeof (_q, ct) -> walk_ctype ct
    | AilEsizeof_expr e -> walk_expr e
    | AilEalignof (_q, ct) -> walk_ctype ct
    | AilEannot (ct, e) -> walk_ctype ct; walk_expr e
    | AilEva_start (e, sym) -> walk_expr e; note_sym sym
    | AilEva_arg (e, ct) -> walk_expr e; walk_ctype ct
    | AilEva_copy (e1, e2) -> walk_expr e1; walk_expr e2
    | AilEva_end e -> walk_expr e
    | AilEprint_type e -> walk_expr e
    | AilEbmc_assume e -> walk_expr e
    | AilEreg_load _reg -> ()
    | AilErvalue e -> walk_expr e
    | AilEarray_decay e -> walk_expr e
    | AilEfunction_decay e -> walk_expr e
    | AilEatomic e -> walk_expr e
    | AilEgcc_statement (bindings, stmts) ->
        walk_bindings bindings; List.iter walk_stmt stmts
    | AilEinvalid (ct, _reason) -> walk_ctype ct

  and walk_generic_association = function
    | AilGAtype (_q, ct, e) -> walk_ctype ct; walk_expr e
    | AilGAdefault e -> walk_expr e

  and walk_stmt { loc = _; desug_info = _; attrs = _attrs; node } =
    walk_stmt_ node

  and walk_stmt_ = function
    | AilSskip -> ()
    | AilSexpr e -> walk_expr e
    | AilSblock (bindings, stmts) ->
        walk_bindings bindings; List.iter walk_stmt stmts
    | AilSif (e, s1, s2) -> walk_expr e; walk_stmt s1; walk_stmt s2
    | AilSwhile (e, s, loop_id) -> walk_expr e; walk_stmt s; note loop_id
    | AilSdo (s, e, loop_id) -> walk_stmt s; walk_expr e; note loop_id
    | AilSbreak -> ()
    | AilScontinue -> ()
    | AilSreturnVoid -> ()
    | AilSreturn e -> walk_expr e
    | AilSswitch (e, s) -> walk_expr e; walk_stmt s
    | AilScase (_n, s) -> walk_stmt s
    | AilScase_rangeGNU (_n1, _n2, s) -> walk_stmt s
    | AilSdefault s -> walk_stmt s
    | AilSlabel (sym, s, la_opt) ->
        note_sym sym; walk_stmt s; note_opt walk_label_annot la_opt
    | AilSgoto sym -> note_sym sym
    | AilSdeclaration decls ->
        List.iter (fun (sym, e_opt) -> note_sym sym; note_opt walk_expr e_opt)
          decls
    | AilSpar stmts -> List.iter walk_stmt stmts
    | AilSreg_store (_reg, e) -> walk_expr e
    | AilSmarker (id, s) -> note id; walk_stmt s
  in

  let walk_declaration = function
    | Decl_object ((_dur, _reg), align_opt, _q, ct) ->
        note_opt walk_alignment align_opt; walk_ctype ct
    | Decl_function (_proto, (_q, ret_ct), params, _var, _inl, _noret) ->
        walk_ctype ret_ct;
        List.iter (fun (_q, ct, _reg) -> walk_ctype ct) params
  in
  let walk_tag_definition = function
    | Ctype.StructDef (members, fam_opt) ->
        List.iter
          (fun (_member_ident, (_attrs, align_opt, _q, ct)) ->
            note_opt walk_alignment align_opt; walk_ctype ct)
          members;
        note_opt
          (fun (Ctype.FlexibleArrayMember (_attrs, _ident, _q, ct)) ->
            walk_ctype ct)
          fam_opt
    | Ctype.UnionDef members ->
        List.iter
          (fun (_member_ident, (_attrs, align_opt, _q, ct)) ->
            note_opt walk_alignment align_opt; walk_ctype ct)
          members
  in

  (* ---- sigma ---- *)
  List.iter
    (fun (sym, (_loc, _attrs, decl)) -> note_sym sym; walk_declaration decl)
    sigma.declarations;
  List.iter
    (fun (sym, e) -> note_sym sym; walk_expr e)
    sigma.object_definitions;
  List.iter
    (fun (sym, (_loc, marker_id, _attrs, param_syms, body)) ->
      note_sym sym;
      note marker_id;
      List.iter note_sym param_syms;
      walk_stmt body)
    sigma.function_definitions;
  List.iter
    (fun (e, _strlit) -> walk_expr e)
    sigma.static_assertions;
  List.iter
    (fun (sym, (_loc, _attrs, tagdef)) ->
      note_sym sym; walk_tag_definition tagdef)
    sigma.tag_definitions;
  Pmap.fold
    (fun _ident (sym, _kind) () -> note_sym sym)
    sigma.extern_idmap ();
  Pmap.fold
    (fun sym _attrs () -> note_sym sym)
    sigma.typedef_attributes ();
  Pmap.fold
    (fun loop_id { Annot.marker_id; attributes = _; loc_condition = _;
                   loc_loop = _ } () ->
      note loop_id; note marker_id)
    sigma.loop_attributes ();
  Pmap.fold
    (fun (_ns, _ident) sym () -> note_sym sym)
    sigma.cn_idents ();
  (match sigma.cn_functions, sigma.cn_lemmata, sigma.cn_predicates,
         sigma.cn_datatypes, sigma.cn_decl_specs with
   | [], [], [], [], [] -> ()
   | _ ->
       (* fail-closed: this fold does not cover the Cn ASTs *)
       prerr_endline
         "CERB_FRESH_FLOOR_VIOLATION (unsupported): CN declarations present \
          — the desugar high-water fold (backend/common/ail_sym_hwm.ml) \
          does not cover Cn ASTs; refusing rather than under-approximate.";
       exit 70);
  !m
