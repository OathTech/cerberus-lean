(* Source-bearing Core is a transport format, not a new evaluator node.
   Check original -> print -> parse -> print with distinct annotation and
   direct locations, then retain those native files for Lean cross-reading. *)
open Cerb_frontend
open Core
let check name ok =
  Printf.printf "%s: %b\n%!" name ok; if not ok then exit 1
let render d =
  let b = Buffer.create 512 in PPrint.ToBuffer.pretty 1.0 100 b d; Buffer.contents b
let pos file line col =
  Cerb_position.from_lexing Lexing.{pos_fname=file;pos_lnum=line;pos_bol=0;pos_cnum=col-1}
let p = pos "source >>> \\\" λ.c" 7 13
let q = pos "other.c" 11 24
let locs = Cerb_location.[unknown; other "message >>> \\ λ"; point p;
  region (p,q) NoCursor; region (p,q) (PointCursor q);
  region (p,q) (RegionCursor (q,p));
  regions [(p,q);(q,p)] (RegionCursor (p,q))]
let annots = List.map (fun loc -> Annot.Aloc loc) locs
let pe body = Pexpr (annots, (), body)
let e body = Expr (annots, body)
let unit = Pexpr ([], (), PEval Vunit)
let bool = Pexpr ([], (), PEval (Vtrue))
let failure = pe (PEundef (Cerb_location.point q, Undefined.UB045a_division_by_zero))
let gap = pe (PEmodel_gap (Cerb_location.other "gap body", Model_gap_unspecified_atomic_order))
let action = e (Eaction (Paction (Pos, Action (Cerb_location.point p, (), SignalFence Cmm_csem.Seq_cst))))
let cases = [
  "all-locations", e (Epure gap);
  "lock-free-gap", e (Epure (pe (PEmodel_gap (Cerb_location.other "lock-free configuration", Model_gap_atomic_lock_free_configuration))));
  "unknown-direct", Expr ([],Epure (Pexpr ([],(),PEundef (Cerb_location.unknown, Undefined.UB045a_division_by_zero))));
  "nested-pure", e (Epure (pe (PEif (bool, failure, gap))));
  "list-nodes", e (Epure (pe (PEctor (Ccons, [gap; pe (PEctor (Ccons, [failure; Pexpr ([],(),PEctor (Cnil BTy_unit,[]))]))]))));
  "action-location", action;
  "sequence-shape", e (Esseq (Pattern ([],CaseBase (None,BTy_unit)), e (Eif (bool,action,e (Epure unit))), e (Epure failure)))
]
let write path text = let ch = open_out_bin path in output_string ch text;close_out ch
let parse path = Core_parser_driver.parse ([],Pmap.empty Stdlib.compare) path
let body = function
  | Exception.Result (Core_parser_util.Rfile (_,_,funs,_)) ->
      (match Pmap.bindings_list funs with [_, Proc (_,_,_,_,body)] -> body | _ -> failwith "unexpected declarations")
  | Exception.Exception err -> failwith (Pp_errors.to_string err)
  | _ -> failwith "not a program"
let () =
  Cerb_global.set_cerb_conf ~backend_name:"concrete" ~exec:false Cerb_global.Random
    ~concurrency:false Cerb_global.Basic ~defacto:false ~permissive:false
    ~agnostic:false ~ignore_bitfields:false;
  Cerb_colour.do_colour := false;
  let out = if Array.length Sys.argv > 1 then Some Sys.argv.(1) else None in
  let with_file name f =
    let path = match out with Some dir -> Filename.concat dir (name ^ ".core") | None -> Filename.temp_file "core-source-" ".core" in
    Fun.protect ~finally:(fun () -> if out=None then Sys.remove path) (fun () -> f path) in
  List.iter (fun (name, original) -> with_file name (fun path ->
    let text = render (Pp_core.WithSourceLocations.pp_expr original) in
    write path ("proc main(): eff unit := " ^ text ^ "\n");
    let reread = body (parse path) in
    check name (text = render (Pp_core.WithSourceLocations.pp_expr reread)))) cases;
  let payload locs direct = "<<<" ^ Cerb_location_json.encode locs direct ^ ">>>" in
  let negatives = [
    "odd-hex", "source_expr(<<<0>>>, pure(Unit))";
    "bad-hex", "source_expr(<<<zz>>>, pure(Unit))";
    "not-json", "source_expr(<<<ff>>>, pure(Unit))";
    "missing-direct", "source_expr(" ^ payload [] None ^ ", signal_fence(seq_cst))";
    "extra-direct", "source_expr(" ^ payload [] (Some Cerb_location.unknown) ^ ", pure(Unit))";
    "pexpr-missing-direct", "pure(source_pexpr(" ^ payload [] None ^ ", model_gap(pointer_atomic_fetch)))";
    "pexpr-extra-direct", "pure(source_pexpr(" ^ payload [] (Some Cerb_location.unknown) ^ ", Unit))"
  ] in
  List.iter (fun (name,text) -> with_file name (fun path ->
    write path ("proc main(): eff unit := " ^ text ^ "\n");
    check name (match parse path with Exception.Exception _ -> true | _ -> false))) negatives
