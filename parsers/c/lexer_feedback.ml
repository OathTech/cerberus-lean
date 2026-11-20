(* Created by Victor Gomes 2017-10-04 *)

(* Based on Jacques-Henri Jourdan and Francois Pottier TOPLAS 2017:
   "A simple, possibly correct LR parser for C11" *)

open Cerb_frontend

module IdSet = Set.Make(String)

exception KnR_declaration of Cerb_location.t

type context = IdSet.t

let cerb_builtin_types =
  [ "jmp_buf";        "sig_atomic_t";     "va_list";
    "ptrdiff_t";      "ptraddr_t";  "wchar_t";
    "int8_t";         "int16_t";        "int32_t";        "int64_t";          "int128_t";
    "uint8_t";        "uint16_t";       "uint32_t";       "uint64_t";         "uint128_t";
    "int_least8_t";   "int_least16_t";  "int_least32_t";  "int_least64_t";
    "uint_least8_t";  "uint_least16_t"; "uint_least32_t"; "uint_least64_t";
    "int_fast8_t";    "int_fast16_t";   "int_fast32_t";   "int_fast64_t";
    "uint_fast8_t";   "uint_fast16_t";  "uint_fast32_t";  "uint_fast64_t";
    "intptr_t";       "uintptr_t";
    "intmax_t";       "uintmax_t";
    "size_t";         "ssize_t";
    "FILE";
    "fpos_t";
    "cnd_t";
    "thrd_t";
    "tss_t";          "mtx_t";
    "once_flag";
    "time_t";         "timer_t";        "clock_t";        "clockid_t";
    "suseconds_t";
    "blkcnt_t";       "blksize_t";
    "dev_t";          "fsblkcnt_t";     "fsfilcnt_t";
    "gid_t";          "id_t";           "uid_t";          "pid_t";
    "key_t";          "mode_t";         "ino_t";          "nlink_t";
    "nlink_t";        "off_t";
    "pthread_attr_t"; "pthread_barrier_t"; "pthread_barrierattr_t";
    "pthread_cond_t"; "pthread_condattr_t"; "pthread_key_t";
    "pthread_mutex_t"; "pthread_mutexattr_t"; "pthread_once_t";
    "pthread_rwloc_t"; "pthread_rwlockattr_t"; "pthread_spinlock_t";
    "pthread_t";
    "trace_attr_t";   "trace_event_id_t";   "trace_event_set_t";
    "trace_id_t";
(* TODO(KKK): talk to victor *)
    "max_align_t"
  ]

let current =
  List.map (fun s -> "__cerbty_" ^ s) cerb_builtin_types
  |> IdSet.of_list
  |> ref

let declare_typedefname id =
  current := IdSet.add id !current

let declare_varname id =
  current := IdSet.remove id !current

let is_typedefname id =
  IdSet.mem id !current

let save_context () = !current

let restore_context ctxt =
  current := ctxt

type decl_sort =
  | DeclId
  | DeclFun of context
  | DeclFunIds of context * Symbol.identifier list
  | DeclPtr of Cabs.pointer_declarator
  | DeclOther
and declarator =
  { id:      string;
    sort:    decl_sort;
    direct:  Cabs.direct_declarator;
    (* FORK (2026-11-20, contract D19; census W5): does the declarator hold a K&R identifier list? `sort` loses
       it when a pointer, array or parenthesis wraps the function declarator (pointer_decl, array_decl,
       declarator_decl overwrite it), and create_function_definition then dropped the list silently. *)
    knr_ids: bool;
  }

let identifier decl = decl.id

let cabs_of_declarator d =
  match d.sort with
  | DeclPtr p -> Cabs.Declarator (Some p, d.direct)
  | _ -> Cabs.Declarator (None, d.direct)

let cabs_of_declarator_option = function
  | Some d -> Some (cabs_of_declarator d)
  | None -> None

let pointer_decl pdecl d =
  { d with sort=    DeclPtr pdecl;
  }

let identifier_decl attrs (Symbol.Identifier(_, str) as i) =
  { id=      str;
    sort=    DeclId;
    direct=  Cabs.DDecl_identifier (attrs, i);
    knr_ids= false;
  }

let declarator_decl d =
  { d with direct= Cabs.DDecl_declarator (cabs_of_declarator d);
           sort=   DeclOther;
  }

let array_decl arrdecl d =
  { d with direct= Cabs.DDecl_array (d.direct, arrdecl);
           sort=   DeclOther;
  }

let fun_decl ptys ctxt d =
  { d with direct= Cabs.DDecl_function (d.direct, ptys);
           sort=   DeclFun ctxt;
  }

let fun_ids_decl ids_opt ctxt d =
  { d with direct= Cabs.DDecl_function (d.direct, Params ([], false, Annot.no_attributes));
           sort=   DeclFunIds (ctxt, ids_opt);
           knr_ids= true;
  }

(* FORK (2026-11-20, contract D19; lean_frontend/docs/2026-11-20_attribute-preservation-record.md): the
   attribute specifier sequence after an array or a function declarator (c_parser.mly direct_declarator) is
   kept on that declarator part; upstream's action dropped it. *)
let add_declarator_attributes attrs d =
  let Annot.Attrs xs' = attrs in
  match d.direct with
  | Cabs.DDecl_array (dd, Cabs.ADecl (loc, Annot.Attrs xs, tquals, is_static, size_opt)) ->
      { d with direct= Cabs.DDecl_array (dd, Cabs.ADecl (loc, Annot.Attrs (xs @ xs'), tquals, is_static, size_opt)) }
  | Cabs.DDecl_function (dd, Cabs.Params (params, is_variadic, Annot.Attrs xs)) ->
      { d with direct= Cabs.DDecl_function (dd, Cabs.Params (params, is_variadic, Annot.Attrs (xs @ xs'))) }
  | Cabs.DDecl_identifier _ | Cabs.DDecl_declarator _ ->
      (* the two productions that call this build an array or a function declarator *)
      assert (xs' = []); d

(* FORK (2026-11-20, contract D19; pre-merge review F3): an attribute argument that is not a plain string
   literal (a nested balanced-token group, a prefixed string literal) is carried as its TOKENS: the tokens the
   lexer read between the argument's first and last character, each spelled as written, joined by single spaces.
   The parser reads the preprocessor's output (C_parser_driver.parse_from_string sets it here), so the tokens
   are those AFTER macro expansion; comments (cpp runs with -CC), cpp line markers and all layout are dropped,
   so one argument has one spelling whatever its layout. The grammar admits only string literals, commas and
   the three bracket pairs inside an argument (c_parser.mly balanced_token); any other character stops loudly.
   A parse that did not come through parse_from_string has no text and such an argument stops the parse. *)
let current_source : string option ref = ref None
let set_source str = current_source := Some str
let argument_tokens (text : string) : string =
  let n = String.length text in
  let toks = ref [] in
  let add t = toks := t :: !toks in
  let fail what = failwith ("Lexer_feedback.source_text: " ^ what ^ " in an attribute argument (contract D19)") in
  let is_ident c = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_' in
  (* the index after the string literal that opens at the quote at [i] *)
  let rec string_end i =
    if i >= n then fail "an unterminated string literal"
    else if text.[i] = '\\' then string_end (i + 2)
    else if text.[i] = '"' then i + 1
    else string_end (i + 1) in
  let rec line_end i = if i >= n || text.[i] = '\n' then i else line_end (i + 1) in
  let rec comment_end i =
    if i + 1 >= n then fail "an unterminated comment"
    else if text.[i] = '*' && text.[i + 1] = '/' then i + 2
    else comment_end (i + 1) in
  let rec go i at_line_start =
    if i < n then
      match text.[i] with
      | '\n' -> go (i + 1) true
      | ' ' | '\t' | '\r' | '\012' -> go (i + 1) at_line_start
      | '#' when at_line_start -> go (line_end i) true            (* a cpp line marker *)
      | '/' when i + 1 < n && text.[i + 1] = '*' -> go (comment_end (i + 2)) at_line_start
      | '/' when i + 1 < n && text.[i + 1] = '/' -> go (line_end i) at_line_start
      | '(' | ')' | '[' | ']' | '{' | '}' | ',' as c -> add (String.make 1 c); go (i + 1) false
      | ('<' | ':' | '%') when i + 1 < n
                               && List.mem (String.sub text i 2) ["<:"; ":>"; "<%"; "%>"] ->
          add (String.sub text i 2); go (i + 2) false                (* a digraph bracket, as spelled *)
      | '"' -> let e = string_end (i + 1) in add (String.sub text i (e - i)); go e false
      | c when is_ident c ->
          (* an encoding prefix: it is one token with the string literal that follows it *)
          let rec ident_end k = if k < n && is_ident text.[k] then ident_end (k + 1) else k in
          let k = ident_end i in
          if k < n && text.[k] = '"' then
            let e = string_end (k + 1) in add (String.sub text i (e - i)); go e false
          else fail ("the token '" ^ String.sub text i (k - i) ^ "'")
      | c -> fail ("the character '" ^ String.make 1 c ^ "'") in
  go 0 false;
  String.concat " " (List.rev !toks)
let source_text (startp : Lexing.position) (endp : Lexing.position) =
  match !current_source with
  | Some str when 0 <= startp.pos_cnum && startp.pos_cnum <= endp.pos_cnum
                  && endp.pos_cnum <= String.length str ->
      argument_tokens (String.sub str startp.pos_cnum (endp.pos_cnum - startp.pos_cnum))
  | _ ->
      failwith "Lexer_feedback.source_text: no source text for an attribute argument (contract D19)"

let reinstall_function_context d =
  match d.sort with
  | DeclFun ctxt -> restore_context ctxt; declare_varname d.id
  | _ -> ()

let create_function_definition loc attr_opt magic_opt specifs d stmt rev_dlist_opt =
  let xs = match attr_opt with
    | None ->
        []
    | Some z ->
        List.map (fun ((ns, id), args_opt) ->
          let open Annot in
          { attr_ns=   ns
          ; attr_id=   id
          ; attr_args= match args_opt with None -> [] | Some z -> z }
        ) (List.concat z) in
  let attrs =
    match magic_opt with
      | Some magic ->
          Annot.(combine_attributes magic (Attrs xs))
      | None ->
          Annot.Attrs xs in
  match d.sort, rev_dlist_opt with
  | DeclFunIds (_, ids), None ->
    let open Cabs in
    let signed_int_specifiers =
      { storage_classes= [];
        type_specifiers= [TSpec (Cerb_location.unknown, TSpec_int)];
        type_qualifiers= [];
        function_specifiers= [];
        alignment_specifiers= [];
        specifier_attributes= Annot.no_attributes;
      } in
    let params = List.map (fun id ->
        PDeclaration_decl (Annot.no_attributes, signed_int_specifiers,
                           Declarator (None,  DDecl_identifier (Annot.no_attributes, id)))
      ) ids in
    let direct_declarator =
      match d.direct with
      | DDecl_function (ddecl, Params (_, _, attrs)) -> DDecl_function (ddecl, Params (params, false, attrs))
      | _ -> assert false in
    let decl = Cabs.Declarator (None, direct_declarator) in
    Cabs.FunDef (loc, attrs, specifs, decl, stmt)
  | DeclFunIds (_, ids), Some rev_dlist ->
    raise (KnR_declaration loc)
  (* FORK (2026-11-20, contract D19; census W5, W6): upstream's catch-all below dropped, without a word, (W5) the
     identifier list and the declaration list of an old-style definition whose declarator is a pointer, an array
     or parenthesised (`int *f(a) int a; { ... }`: the body then failed on an undeclared `a`), and (W6) a
     declaration list written after a prototype (`int f(void) int x; { ... }`, a syntax error). Both stop as the
     plain old-style definition does. *)
  | _, Some _ ->
    raise (KnR_declaration loc)
  | _, None when d.knr_ids ->
    raise (KnR_declaration loc)
  | _, _ ->
    Cabs.FunDef (loc, attrs, specifs, cabs_of_declarator d, stmt)

