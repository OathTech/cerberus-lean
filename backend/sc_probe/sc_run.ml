(* sc_run.exe — the OCaml engine of the SC S1a differential lane
   (scripts/test_sc_step.py; charter lean_frontend/docs/2026-09-29_sc-s1-charter.md §3.10).

   It runs the oracle's own C pipeline on ONE file exactly as backend/driver/main.ml's
   `--exec --batch` path does (cites inline), then drives the linked Core program through
   the shared-Lem SC step API (frontend/model/driver.lem, section "SC concurrency S1a")
   instead of `Driver.drive`: `Driver.sc_explore budget` (exhaustive, the runNDFuel order)
   or `Driver.sc_run budget Driver.sc_policy_first` (first alternative). Every completed
   outcome prints through the oracle's own batch printer
   (Driver_ocaml.string_of_batch_output, backend/common/driver_ocaml.ml), so verdict lines
   are byte-comparable with `cerberus --exec --batch --mode=exhaustive`; the SC-specific
   outcomes print their own records:
     SCExhausted {transitions: N, core_reductions: M}
     SCUnsupported {msg: "…"}      SCBlocked {}      SCNeedsChoice {}
     SCRunError {msg: "…"}
   Exit: main.ml runM's rule on Defined/Undefined/Error-only outputs (single Defined → 0,
   single kill → 1, several → 0); 3 whenever an SC-specific outcome is present (loud).

   Flags (positional parser; every `--` token must be one of these):
     --runtime=DIR   --nolibc   --sc-budget N (required)   --sc-first   -d N   --args "…"
   Mirrors: cpp command main.ml:38-52 (create_cpp_cmd defaults), core libraries :54-77,
   configuration :124-131, frontend :23-36, prelude :132-155, link :312-321, tag
   bookkeeping :324-326, driver state Driver_ocaml.batch_drive (driver_ocaml.ml:155-192). *)

open Cerb_frontend
open Cerb_backend
open Cerb_global
open Pipeline

let (>>=) = Exception.except_bind
let return = Exception.except_return

let usage () =
  prerr_endline "usage: sc_run.exe [--runtime=DIR] [--nolibc] --sc-budget N [--sc-first] [-d N] [--args \"A B\"] FILE.c";
  exit 2

(* main.ml:38-52 with its cmdliner defaults (:389-391 cpp_cmd; nostdinc/macros/undef/
   incl_dirs/incl_files empty); the concrete model is not CHERI. *)
let create_cpp_cmd nolibc =
  let cpp_cmd = "cc -std=c11 -E -CC -Werror -Wno-builtin-macro-redefined -nostdinc -undef -D__cerb__" in
  let libc_dirs = Cerb_runtime.[in_runtime "libc/include"; in_runtime "libc/include/posix"] in
  let incl_dirs = libc_dirs in
  let macros_def = if nolibc then [] else [("CERB_WITH_LIB", None)] in
  String.concat " " begin
    cpp_cmd ::
    List.map (function
        | (str1, None)      -> "-D" ^ str1
        | (str1, Some str2) -> "-D" ^ str1 ^ "=" ^ str2
      ) macros_def @
    List.map (fun str -> "-I" ^ str) incl_dirs @
    List.map (fun str -> "-include " ^ str) [Cerb_runtime.in_runtime "libc/include/builtins.h"]
  end

(* main.ml:54-77 (concrete model, default switches: lib "c") *)
let core_libraries incl =
  if not incl then [] else begin
    let lib_paths = [Cerb_runtime.in_runtime ~pkg:"cerberus" "libc"] in
    List.map (fun lib ->
        true, match List.fold_left (fun acc path ->
            match acc with
            | Some _ -> acc
            | None ->
              let file = path ^ "/lib" ^ lib ^ ".co" in
              if Sys.file_exists file then Some file else None
          ) None lib_paths with
        | Some f -> f
        | None -> failwith @@ "file lib" ^ lib ^ ".co not found"
      ) ["c"]
  end

(* main.ml:23-36 *)
let frontend (conf, io) ~is_lib filename core_std =
  if not (Sys.file_exists filename) then
    error ("The file `" ^ filename ^ "' doesn't exist.");
  if Filename.check_suffix filename ".co" || Filename.check_suffix filename ".o" then
    read_core_object (conf, io) ~is_lib core_std filename
  else if Filename.check_suffix filename ".c" then
    c_frontend_and_elaboration (conf, io) core_std ~filename >>= fun (_, _, core_file) ->
    core_passes (conf, io) ~filename core_file
  else
    Exception.fail (Cerb_location.unknown, Errors.UNSUPPORTED "The file extention is not supported")

(* driver_ocaml.ml:31-40, verbatim (not exported by driver_ocaml.mli; the oracle surface
   is left untouched — this probe sits outside the fork-drift SURFACES) *)
let string_of_driver_error = function
  | Driver.DErr_core_run err ->
      Pp_errors.string_of_core_run_cause err
  | Driver.DErr_memory err ->
      Mem_common.instance_Show_Show_Mem_common_mem_error_dict.Lem_pervasives.show_method err
  | Driver.DErr_concurrency str ->
      "Concurrency error: " ^ str
  | Driver.DErr_other str ->
      str

(* driver_ocaml.ml:162-181 (batch_drive's result classification), verbatim shape *)
let batch_of_active dres =
  let open Driver_ocaml in
  let exit =
    match dres.Driver.dres_core_value with
      | Core.Vloaded (Core.LVspecified (Core.OVinteger ival)) ->
          Impl_mem.case_integer_value ival
            (fun n  -> Specified n)
            (fun () -> OtherValue dres.Driver.dres_core_value)
      | Core.Vloaded (Core.LVunspecified ty) ->
          Unspecified ty
      | _ ->
          OtherValue dres.Driver.dres_core_value in
  Defined { exit; stdout= dres.Driver.dres_stdout; stderr= dres.Driver.dres_stderr; blocked= dres.Driver.dres_blocked }

let batch_of_killed dr_st reason =
  let open Driver_ocaml in
  let stderr = String.concat "" (Dlist.toList dr_st.Driver.core_state.Core_run.io.Core_run.stderr) in
  match reason with
    | Nondeterminism.Undef0 (_, []) -> Error { msg= "[empty UB, probably a cerberus BUG]"; stderr }
    | Nondeterminism.Undef0 (loc, ub::_) -> Undefined { ub; stderr; loc }
    | Nondeterminism.Error0 (_, msg) -> Error { msg; stderr }
    | Nondeterminism.Other dr_err -> Error { msg= string_of_driver_error dr_err; stderr }

(* The printed record of one sc_run_outcome: `Left batch` prints through the oracle's
   printer (batch verdict), `Right line` is an SC-specific record. *)
let record_of_outcome = function
  | Driver.SC_stopped cfg ->
      begin match cfg.Driver.sc_phase with
        | Driver.SC_final (Driver.SC_done dres) -> Either.Left (batch_of_active dres)
        | Driver.SC_final (Driver.SC_killed reason) -> Either.Left (batch_of_killed cfg.Driver.sc_state reason)
        | Driver.SC_final (Driver.SC_unsupported msg) -> Either.Right (Printf.sprintf "SCUnsupported {msg: \"%s\"}" (String.escaped msg))
        | Driver.SC_final Driver.SC_blocked -> Either.Right "SCBlocked {}"
        | _ -> Either.Right "SCRunError {msg: \"sc_run.exe: SC_stopped on a non-final configuration\"}"
      end
  | Driver.SC_exhausted cfg ->
      Either.Right (Printf.sprintf "SCExhausted {transitions: %d, core_reductions: %d}"
                      cfg.Driver.sc_transitions cfg.Driver.sc_core_reductions)
  | Driver.SC_needs_choice _ -> Either.Right "SCNeedsChoice {}"
  | Driver.SC_run_error (e, _) ->
      let msg = match e with
        | Driver.SC_bad_choice (i, n) -> Printf.sprintf "SC_bad_choice %d %d" i n
        | Driver.SC_choice_required -> "SC_choice_required"
        | Driver.SC_terminal -> "SC_terminal" in
      Either.Right (Printf.sprintf "SCRunError {msg: \"%s\"}" msg)

let () =
  let runtime = ref None and nolibc = ref false and budget = ref None and first = ref false
  and debug = ref 0 and args = ref [] and files = ref [] in
  let rec parse = function
    | [] -> ()
    | "--nolibc" :: rest -> nolibc := true; parse rest
    | "--sc-first" :: rest -> first := true; parse rest
    | "--sc-budget" :: n :: rest ->
        (match int_of_string_opt n with
         | Some b when b >= 0 -> budget := Some b
         | _ -> prerr_endline ("sc_run.exe: refused — --sc-budget " ^ n ^ ": not a non-negative decimal numeral"); exit 2);
        parse rest
    | "-d" :: n :: rest ->
        (match int_of_string_opt n with
         | Some d when d >= 0 -> debug := d
         | _ -> prerr_endline ("sc_run.exe: refused — -d " ^ n ^ ": not a non-negative decimal numeral"); exit 2);
        parse rest
    | "--args" :: s :: rest -> args := Str.split (Str.regexp "[ \t]+") s; parse rest  (* main.ml:111-113 *)
    | a :: rest when String.length a > 10 && String.sub a 0 10 = "--runtime=" ->
        runtime := Some (String.sub a 10 (String.length a - 10)); parse rest
    | a :: _ when String.length a >= 2 && String.sub a 0 2 = "--" ->
        prerr_endline ("sc_run.exe: refused — unknown flag " ^ a); usage ()
    | f :: rest -> files := f :: !files; parse rest in
  parse (List.tl (Array.to_list Sys.argv));
  let budget = match !budget with
    | Some b -> b
    | None -> prerr_endline "sc_run.exe: refused — --sc-budget N is required (no default budget numeral)"; exit 2 in
  let file = match !files with
    | [f] -> f
    | _ -> usage () in
  (* main.ml:105-106, :124-131 (batch exhaustive execution of one file, default switches) *)
  Cerb_debug.debug_level := !debug;
  Cerb_runtime.specified_runtime := !runtime;
  set_cerb_conf ~backend_name:"Driver" ~exec:true Exhaustive ~concurrency:false QuoteStd
    ~defacto:false ~permissive:false ~agnostic:false ~ignore_bitfields:false;
  let conf = { astprints= []; pprints= []; ppflags= []; ppouts= []; debug_level= !debug;
               typecheck_core= false; rewrite_core= false; sequentialise_core= false;
               cpp_cmd= create_cpp_cmd !nolibc; cpp_stderr= true; cpp_save= None;
               address_space_top= Driver_ocaml.address_space_top_default } in
  let io = Pipeline.default_io_helpers in
  let prelude =
    Switches.set [];
    load_core_stdlib () >>= fun core_stdlib ->
    load_core_impl core_stdlib "gcc_4.9.0_x86_64-apple-darwin10.8.0" >>= fun core_impl ->
    return (core_stdlib, core_impl) in
  let main core_std =
    Exception.except_foldlM (fun core_files (is_lib, f) ->
      frontend ~is_lib (conf, io) f core_std >>= fun core_file ->
      return (core_file::core_files)
    ) [] (core_libraries (not !nolibc) @ [(false, file)]) in
  let print_undef ub loc =
    print_string (Driver_ocaml.string_of_batch_output None ([], Driver_ocaml.Undefined { ub; stderr= ""; loc })) in
  match prelude >>= main >>= (function [] -> assert false | f::fs -> Core_linking.link (f::fs)) with
    (* main.ml:170-185 runM's front-end arms *)
    | Exception.Exception (loc, Errors.(DESUGAR (Desugar_UndefinedBehaviour ub))) -> print_undef ub loc; exit 1
    | Exception.Exception (loc, Errors.(AIL_TYPING (TypingError.TError_UndefinedBehaviour ub))) -> print_undef ub loc; exit 1
    | Exception.Exception err -> prerr_endline (Pp_errors.to_string err); exit 1
    | Exception.Result core_file ->
        Tags.reset_tagDefs ();
        Tags.set_tagDefs core_file.Core.tagDefs;
        let file = Core_run_aux.convert_file core_file in
        let initial_dr_st =
          Driver.initial_driver_state Driver_ocaml.address_space_top_default (Cerb_fresh.digest ()) file Sibylfs.fs_initial_state in
        let cfg = Driver.sc_start file ("cmdname" :: !args) initial_dr_st in
        let outcomes =
          if !first then [Driver.sc_run budget Driver.sc_policy_first cfg]
          else Driver.sc_explore budget cfg in
        let records = List.map record_of_outcome outcomes in
        let has_multiple = List.length records > 1 in
        List.iteri (fun i r ->
          match r with
            | Either.Left b ->
                print_string (Driver_ocaml.string_of_batch_output (if has_multiple then Some i else None) ([], b))
            | Either.Right line ->
                if has_multiple then Printf.printf "EXECUTION %d:\n" i;
                print_endline line
        ) records;
        let sc_specific = List.exists (function Either.Right _ -> true | _ -> false) records in
        let code =
          if sc_specific then 3
          else match records with
            | [Either.Left (Driver_ocaml.Defined _)] -> 0
            | [Either.Left (Driver_ocaml.Undefined _ | Driver_ocaml.Error _)] -> 1
            | _ -> 0 in
        exit code
