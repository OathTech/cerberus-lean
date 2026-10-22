open Symbol
open Cerb_pp_prelude
open Cerb_location

let to_string (Symbol (_, n, sd)) =
  match sd with
    | SD_Id str | SD_ObjectAddress str | SD_FunArgValue str ->
        str ^ "_" ^ string_of_int n
    | _ ->
        "a_" ^ string_of_int n

(* Fork transport check, upstream tray 65. Core's pretty-printer is used
   as an input format by the Lean libc loader. A source identifier can
   itself spell x_fav12, so the suffix below alone is not disjoint from
   bare source names. Track both sets while constructing one proc's doc;
   checking either insertion makes OCaml's evaluation order irrelevant. *)
type proc_print_names = {
  proc_name: string;
  bare_names: (string, unit) Hashtbl.t;
  argument_names: (string, unit) Hashtbl.t;
}

let current_proc_names : proc_print_names option ref = ref None

let check_proc_name sd name =
  match !current_proc_names with
  | None -> ()
  | Some names ->
      let record own other =
        if Hashtbl.mem other name then
          Cerb_debug.error ("Core printer symbol collision in procedure " ^
            names.proc_name ^ ": " ^ name ^ " (SD_FunArgValue versus bare name; upstream tray 65)");
        Hashtbl.replace own name ()
      in
      match sd with
      | SD_Id _ | SD_ObjectAddress _ -> record names.bare_names names.argument_names
      | SD_FunArgValue _ -> record names.argument_names names.bare_names
      | SD_None | SD_Return | SD_FunArg _ | SD_unnamed_tag _ | SD_CN_Id _ -> ()

let to_string_pretty ?(is_human=false) (Symbol (_, n, sd)) =
  let add_number name = name ^ "{" ^ string_of_int n ^ "}" in
  let maybe_add_number name =
   if !Cerb_debug.debug_level > 4 then
      add_number name
     else
      name
  in
  let name = match sd with
    | SD_Id str
    | SD_ObjectAddress str ->
        maybe_add_number str
    | SD_FunArgValue str ->
        (* Fork remedy, upstream tray 65: a parseable, numbered argument
           value name, distinct from its parameter object's bare name and
           from a_<n>/str_<n>. The per-proc check above refuses a bare C
           identifier that happens to have this spelling. Normal has no
           SD_FunArgValue; its printed output is unchanged. *)
        str ^ "_fav" ^ string_of_int n
    | SD_unnamed_tag loc ->
        if is_human then
          "(unnamed tag at " ^ Cerb_location.location_to_string loc ^ ")"
        else
          "__cerbty_unnamed_tag_" ^ string_of_int n
    | SD_CN_Id str ->
        (* (Printf.printf "SD_CN_Id: %s\n" str; *)
        str
        (* ) *)
    | _ ->
        "a_" ^ string_of_int n
  in
  check_proc_name sd name;
  name

let with_proc_symbol_check proc print =
  let names = {
    proc_name = to_string_pretty proc;
    bare_names = Hashtbl.create 32;
    argument_names = Hashtbl.create 16;
  } in
  let previous = !current_proc_names in
  current_proc_names := Some names;
  Fun.protect ~finally:(fun () -> current_proc_names := previous) print

(* enriched versions used by the CN backend *)
let to_string_pretty_cn ?(print_nums=false) (Symbol (_, n, sd) as s) =
  let add_number name = name ^ "{" ^ string_of_int n ^ "}" in
  let maybe_add_number name = 
      if print_nums then
        add_number name
      else
        name
  in
  let symbol_description = function
    | SD_None -> 
        to_string s
    | SD_unnamed_tag _ ->
        "__cerbty_unnamed_tag_" ^ string_of_int n
    | SD_Id name -> 
        name
    | SD_CN_Id name -> 
        name
    | SD_ObjectAddress name -> 
        "&" ^ name
    | SD_Return -> 
        "return"
    | SD_FunArgValue str ->
       str
    | SD_FunArg (_, i) ->
        "ARG" ^ string_of_int i
  in
  match sd with
  | SD_None -> to_string s
  | _ -> maybe_add_number (symbol_description sd)

(*
let to_string_latex (n, _) =
  "v" ^ "_" ^ "{" ^ string_of_int n ^ "}"

let to_string_id (n, _) = string_of_int n
*)


let pp_colour_identifier id =
  !^(Cerb_colour.ansi_format [Yellow] id)


let pp_prefix = function
  | PrefSource (_, syms) ->
      P.braces (P.separate_map P.dot (fun sym -> !^ (to_string_pretty sym)) syms)
  | PrefOther str ->
      P.braces (!^ str)
  | PrefStringLiteral _ ->
      P.braces (!^ "string literal")
  | PrefTemporaryLifetime _ ->
      P.braces (!^ "rvalue temporary")
  | PrefFunArg (_, _, n) ->
      P.braces (!^ ("arg" ^ string_of_int n))
  | PrefMalloc ->
      P.braces (!^ "malloc'd")
  | PrefCompoundLiteral _ ->
      P.braces (!^ "compound literal")


let pp_identifier ?(clever=false) (Symbol.Identifier (loc, str)) =
  begin if Cerb_debug.get_debug_level () >= 5 then
    pp_location ~clever loc ^^ P.space
  else
    P.empty
  end ^^ pp_colour_identifier str
