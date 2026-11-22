(* Scratch probe (scoping section 7): pristine cerberus-lib driven as RefinedC's
   cerb_wrapper.ml drives it -- set_cerb_conf, Ocaml_implementation.set
   HafniumImpl.impl, load stdlib and impl -- then elaborate, link and EXECUTE, as
   the driver's --exec --batch does.  usage: ocaml probe.ml <default|hafnium> f.c *)
#use "topfind";;
#require "cerberus-lib.mem.concrete";;
#require "cerberus-lib.backend_common";;
open Cerb_frontend
open Cerb_backend
open Pipeline
let (>>=) = Exception.except_bind
let return = Exception.except_return
let () =
  let profile = Sys.argv.(1) and filename = Sys.argv.(2) in
  let io = default_io_helpers in
  Cerb_global.set_cerb_conf ~backend_name:"Driver" ~exec:true Cerb_global.Exhaustive ~concurrency:false
    Cerb_global.QuoteStd ~defacto:false ~permissive:false ~agnostic:false ~ignore_bitfields:false;
  if profile = "hafnium" then Ocaml_implementation.(set (HafniumImpl.impl));
  Printf.printf "profile selected: %s\n%!" (Ocaml_implementation.get ()).name;
  let libc = Cerb_runtime.[in_runtime "libc/include"; in_runtime "libc/include/posix"] in
  let cpp_cmd = String.concat " " (["cc -std=c11 -E -CC -Werror -nostdinc -undef -D__cerb__"]
      @ List.map (fun d -> "-I" ^ d) libc @ ["-include " ^ Cerb_runtime.in_runtime "libc/include/builtins.h"]) in
  let conf = { debug_level = 0; pprints = []; astprints = []; ppflags = []; ppouts = [];
               typecheck_core = false; rewrite_core = false; sequentialise_core = false;
               cpp_cmd; cpp_stderr = true; cpp_save = None } in
  Switches.set [];
  let r =
    load_core_stdlib () >>= fun stdlib ->
    load_core_impl stdlib "gcc_4.9.0_x86_64-apple-darwin10.8.0" >>= fun impl ->
    c_frontend_and_elaboration (mk_elab_config ()) (conf, io) (stdlib, impl) ~filename >>= fun (_, _, core_file) ->
    core_passes (conf, io) ~filename core_file >>= fun core_file ->
    Core_linking.link [core_file] >>= fun core_file ->
    Tags.reset_tagDefs (); Tags.set_tagDefs core_file.Core.tagDefs;
    let driver_conf = Driver_ocaml.{ concurrency = false; exec_mode = Cerb_global.Exhaustive; fs_dump = false; trace = false } in
    interp_backend io core_file ~args:[] ~batch:`Batch ~fs:None ~driver_conf in
  match r with
  | Exception.Exception err -> prerr_endline (Pp_errors.to_string err); exit 1
  | Exception.Result (Either.Left (_, execs)) ->
      List.iter (fun e -> print_string (Driver_ocaml.string_of_batch_output None e)) execs
  | Exception.Result (Either.Right n) -> Printf.printf "exit %d\n" n
