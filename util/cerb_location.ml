open Lexing

type cursor =
  | NoCursor
  | PointCursor of Cerb_position.t
  | RegionCursor of Cerb_position.t * Cerb_position.t

type t =
  | Loc_unknown
  | Loc_other of string
  | Loc_point of Cerb_position.t
    (* start, end, cursor *)
  | Loc_region of Cerb_position.t * Cerb_position.t * cursor
  | Loc_regions of (Cerb_position.t * Cerb_position.t) list * cursor


let unknown =
  Loc_unknown

let is_unknown_location = function
  | Loc_unknown -> true
  | _ -> false

let other str =
  Loc_other str

let point pos =
  Loc_point pos

let region (b, e) cur =
  Loc_region (b, e, cur)

let regions xs cur =
  match xs with
    | [] ->
        failwith "Cerb_location.region, xs must not be []"
    | _ ->
        (* TODO: need to sort the regions *)
        Loc_regions (xs, cur)

let with_cursor = function
  | Loc_unknown
  | Loc_other _
  | Loc_regions ([], NoCursor) ->
      Loc_unknown
  | Loc_point z
  | Loc_region (_, _, PointCursor z)
  | Loc_region (z, _, NoCursor)
  | Loc_regions (_, PointCursor z)
  | Loc_regions ((z,_)::_, NoCursor) ->
      Loc_point z
  | Loc_region (_, _, RegionCursor (b, e)) 
  | Loc_regions (_, RegionCursor (b, e)) ->
      Loc_region (b, e, NoCursor)


(* [with_cursor_from loc1 loc2] makes a new (region location) with the region from loc1
   and the cursor from loc2 if there is one, otherwise uses the beginning of loc2 as the cursor (if possible) *)
let with_cursor_from loc1 loc2 =
  let cursor = match loc2 with
    | Loc_unknown
    | Loc_other _ ->
        NoCursor
    | Loc_point z ->
        PointCursor z
    | Loc_region (start_p, end_p, NoCursor) ->
        RegionCursor (start_p, end_p)
    | Loc_region (_, _, cur) ->
        cur
    | Loc_regions (_, z) ->
        (* not putting a cursor because it seems arbitrary to use the first region *)
        z in
  match loc1 with
    | Loc_unknown ->
        begin match cursor with
          | NoCursor ->
              Loc_unknown
          | PointCursor pos ->
              Loc_point pos
          | RegionCursor (b, e) ->
            Loc_region (b, e, NoCursor)
        end
    | Loc_other str ->
        Loc_other str
    | Loc_point z ->
        Loc_region (z, z, cursor)
    | Loc_region (begin_loc, end_loc, _) ->
        Loc_region (begin_loc, end_loc, cursor)
    | Loc_regions (regions, _) ->
        Loc_regions (regions, cursor)

let from_main_file = function
  | Loc_unknown
  | Loc_other _
  | Loc_regions ([], _) -> false
  | Loc_point pos
  | Loc_region (pos, _, _)
  | Loc_regions ((pos,_)::_, _) ->
    let ext = Filename.extension (Cerb_position.file pos) in
    ext = ".c" || ext = ".core"


let outer_bbox xs =
  let (b0, e0) = match xs with
    | [] ->
        assert false
    | (b,e) :: _ ->
        (b,e) in
  let pos_lt pos1 pos2 =
    (* assuming pos_fname are the same *)
    if Cerb_position.line pos1 = Cerb_position.line pos2 then
      (Cerb_position.to_file_lexing pos1).pos_cnum < (Cerb_position.to_file_lexing pos2).pos_cnum
    else
      Cerb_position.line pos1 < Cerb_position.line pos2 in
  List.fold_left (fun (bAcc, eAcc) (b, e) ->
    ((if pos_lt b bAcc then b else bAcc), (if pos_lt e eAcc then eAcc else e))
  ) (b0, e0) xs


let bbox = function
  | [] ->
      `Other Loc_unknown
  | xs ->
      match begin
        List.fold_left (fun (def_loc, acc) loc ->
          match loc with
            | Loc_unknown ->
                (def_loc, acc)
            | Loc_other _ ->
                (loc, acc)
            | Loc_point pos ->
                (def_loc, (pos, pos) :: acc)
            | Loc_region (pos1, pos2, _) ->
                (* invariant from Loc_region is that pos1 <= pos2 *)
                (def_loc, (pos1, pos2) :: acc)
            | Loc_regions (xs, _) ->
                (def_loc, xs @ acc)
        ) (Loc_unknown, []) xs
      end with
        | (loc, []) ->
            `Other loc
        | (_, xs') ->
            let (b, e) = outer_bbox xs' in
            `Bbox (b, e)

let bbox_location xs =
  match (bbox xs) with
    | `Other loc -> loc
    | `Bbox (b, e) -> Loc_region (b, e, NoCursor)


let with_regions_and_cursor locs loc_opt =
  let cursor_opt = match loc_opt with
    | Some (Loc_point z) -> PointCursor z
    | Some (Loc_region (_, _, z))
    | Some (Loc_regions (_, z)) -> z
    | _ -> NoCursor
  in
  let pos_of_region = function
    | Loc_point p -> Some (p, p)
    | Loc_region (p1, p2, _) -> Some (p1, p2)
    | _ -> None
  in
  let rec the acc = function
    | Some x::xs -> the (x::acc) xs
    | [] -> Some acc
    | None::_ -> None
  in
  match the [] (List.map pos_of_region locs) with
  | Some regs -> Loc_regions (regs, cursor_opt)
  | None -> Loc_unknown


let to_cartesian_gen get_line loc =
  let point_of_pos pos = (get_line pos - 1, Cerb_position.column pos - 1) in
  match loc with
    | Loc_point p -> Some (point_of_pos p, point_of_pos p)
    | Loc_region (p1, p2, _) -> Some (point_of_pos p1, point_of_pos p2)
    | _ -> None
  

let to_cartesian_user = to_cartesian_gen Cerb_position.line
let to_cartesian_raw =
  to_cartesian_gen (fun pos -> (Cerb_position.to_file_lexing pos).pos_lnum)



let location_to_string ?(charon=false) loc =
  let string_of_pos ?(shrink=false) pos =
    if shrink || (charon && from_main_file loc) then
      Printf.sprintf "%d:%d" (Cerb_position.line pos) (Cerb_position.column pos)
    else
      Printf.sprintf "%s:%d:%d" (Cerb_position.file pos) (Cerb_position.line pos) (Cerb_position.column pos) in
  let shrink z =
    if charon && from_main_file loc then
      ""
    else
      z in
  match loc with
    | Loc_unknown ->
        "unknown location"
    | Loc_other str ->
        "other_location(" ^ str ^ ")"
    | Loc_point pos ->
        string_of_pos pos ^ ":"
    | Loc_region (pos1, pos2, pos_opt) ->
        string_of_pos pos1 ^ "-" ^
        begin if Cerb_position.file pos1 = Cerb_position.file pos2 then
          ""
        else
          shrink (Cerb_position.file pos2)
        end ^
        begin if (Cerb_position.line pos1) = (Cerb_position.line pos2) then
          ""
        else
          string_of_int (Cerb_position.line pos2) ^ ":"
        end ^
        string_of_int (Cerb_position.column pos2)
        ^ begin match pos_opt with
          | NoCursor -> ""
          | PointCursor pos -> " (cursor: " ^ string_of_pos ~shrink:true pos ^ ")"
          | RegionCursor (b, e) -> " (cursor: " ^ string_of_pos ~shrink:true b ^ " - " ^ string_of_pos ~shrink:true e ^ ")"
        end
    | Loc_regions (xs, _) ->
        let (pos1, pos2) = outer_bbox xs in
        string_of_pos pos1 ^ "-" ^
        begin if Cerb_position.file pos1 = Cerb_position.file pos2 then
          ""
        else
          shrink (Cerb_position.file pos2)
        end ^
        begin if Cerb_position.line pos1 = Cerb_position.line pos2 then
          ""
        else
          string_of_int (Cerb_position.line pos2) ^ ":"
        end ^
        string_of_int (Cerb_position.column pos2)



module P = PPrint
open Cerb_pp_prelude

let print_location loc =
  let print_lex pos =
    let f = Cerb_position.to_file_lexing pos in
    !^"RT.position"
    ^^^ P.dquotes !^(Cerb_position.file pos)
    ^^^ !^(string_of_int (Cerb_position.line pos))
    ^^^ !^(string_of_int f.pos_bol)
    ^^^ !^(string_of_int f.pos_cnum)
  in
  let print_cursor = function
    | NoCursor ->
        !^ "Cerb_location.NoCursor"
    | PointCursor pos ->
        !^ "Cerb_location.PointCursor" ^^^ P.parens (print_lex pos)
    | RegionCursor (b, e) ->
        !^ "Cerb_location.RegionCursor"
        ^^^ P.parens (print_lex b)
        ^^^ P.parens (print_lex e)
  in
  match loc with
    | Loc_unknown ->
        !^"Cerb_location.unknown"
    | Loc_other str ->
        !^ "Cerb_location.other" ^^ P.parens (P.dquotes !^ (String.escaped str))
    | Loc_point pos ->
        !^"Cerb_location.point" ^^^ P.parens (print_lex pos)
    | Loc_region (pos1, pos2, cur) ->
        !^"Cerb_location.region"
        ^^^ P.parens (print_lex pos1)
        ^^^ P.parens (print_lex pos2)
        ^^^ P.parens (print_cursor cur)
  | Loc_regions (xs, cur) ->
      let print_pair pp (x, y) = P.parens (pp x ^^ P.comma ^^^ pp y) in
      let print_list pp xs = P.brackets (P.separate_map (P.semi ^^ P.space) pp xs) in
      !^"Cerb_location.regions"
      ^^^ P.parens (print_list (print_pair print_lex) xs)
      ^^^ P.parens (print_cursor cur)

let to_json loc =
  let of_pos p =
    `Assoc [("line", `Int (Cerb_position.line p - 1));
            ("ch", `Int (Cerb_position.column p - 1))] in
  match loc with
    | Loc_unknown ->
        `Null
    | Loc_other _str ->
        `Null (* `String str *)
    | Loc_point p ->
        `Assoc [("begin", of_pos p); ("end", of_pos p)]
    | Loc_region (p1, p2, _) ->
        `Assoc [("begin", of_pos p1); ("end", of_pos p2)]
    | Loc_regions (xs, _) ->
        let (pos1, pos2) = outer_bbox xs in
        `Assoc [("begin", of_pos pos1); ("end", of_pos pos2)]


open Cerb_colour

let pp_location =
  let last_pos = ref Cerb_position.dummy in
  fun ?(clever = false) loc ->
  let string_of_pos p =
    let ret =
      if Cerb_position.file !last_pos <> Cerb_position.file p then
        Cerb_position.file p ^ ":" ^ string_of_int (Cerb_position.line p) ^ ":" ^ string_of_int (Cerb_position.column p - 1)
      else if Cerb_position.line !last_pos <> Cerb_position.line p then
        "line:" ^ string_of_int (Cerb_position.line p) ^ ":" ^ string_of_int (Cerb_position.column p - 1)
      else
        "col:" ^ string_of_int (Cerb_position.column p - 1) in
    begin if clever then last_pos := p end;
    ret in
  let aux_region start_p end_p cur =
    let mk_cursor_str () =
      match cur with
        | NoCursor -> ""
        | PointCursor cursor_p -> " " ^ string_of_pos cursor_p
        | RegionCursor (b, e) -> " " ^ string_of_pos b ^ " - " ^ string_of_pos e in
    if Cerb_position.file !last_pos = Cerb_position.file start_p &&
       Cerb_position.file start_p = Cerb_position.file end_p &&
       Cerb_position.line start_p = Cerb_position.line end_p
    then
      let start_p_str = string_of_pos start_p in
      P.angles (
        !^ (ansi_format ~err:true [Yellow] (start_p_str ^ " - " ^ string_of_int (Cerb_position.column end_p - 1)))
      ) ^^ !^ (ansi_format ~err:true [Yellow] (mk_cursor_str ()))
    else
      let start_p_str = string_of_pos start_p in
      let end_p_str   = string_of_pos end_p in
      P.angles (
        !^ (ansi_format ~err:true [Yellow] start_p_str) ^^ P.comma ^^^
        !^ (ansi_format ~err:true [Yellow] end_p_str)
      ) ^^ !^ (ansi_format ~err:true [Yellow] (mk_cursor_str ())) in
  match loc with
    | Loc_unknown ->
        P.angles !^ (ansi_format ~err:true [Yellow] "unknown location")
    | Loc_other str ->
        P.angles !^ (ansi_format ~err:true [Yellow] ("other location (" ^ str ^ ")"))
    | Loc_point pos ->
        let pos_str = string_of_pos pos in
        P.angles !^ (ansi_format ~err:true [Yellow] pos_str)
    | Loc_region (start_p, end_p, cur) ->
        aux_region start_p end_p cur
    | Loc_regions (xs, cur) ->
        let (start_p, end_p) = outer_bbox xs in
        aux_region start_p end_p cur


let string_of_pos pos =
  ansi_format ~err:true [Bold] (
    Printf.sprintf "%s:%d:%d:" (Cerb_position.file pos) (Cerb_position.line pos) (Cerb_position.column pos)
  )

let get_line n ic =
  seek_in ic 0;
  let rec aux = function
    | 1 -> input_line ic
    | n -> let _ = input_line ic in
           aux (n-1) in
  aux n


(* Try to get the part of a line in the file that contains the given column.
The column position is 0 based.
If the column is outside what's visible on the terminal we drop part of the
line and return a new position to display.
*)
let string_at_line fname lnum cpos =
  try
    if Sys.file_exists fname then
      let ic = open_in fname in
      let sub l start n =
        if start + n < String.length l then String.sub l start n
        else Printf.sprintf "(?error: Cerb_location.string_at_line with %S, %i-%i)"
               l start n
      in
      let l =
        let l_ = get_line lnum ic in
        match Cerb_util.terminal_size () with
          | None ->
              (None, l_)
          | Some (_, term_col) ->
              if cpos >= term_col then begin
                (* The cursor position is beyond the width of the terminal *)
                let mid = term_col / 2 in
                let start  = max 0 (cpos - mid) in
                let n = String.length l_ - start in
                ( Some (cpos - start + 5)
                , if n + 5 <= term_col then
                    "  ..." ^ sub l_ start n
                  else
                  try 
                    "  ..." ^ String.sub l_ start (term_col - 5 - 3) ^ "..." 
                  with _ -> ("OOPS: " ^ l_))
              end else if String.length l_ > term_col then
                (* The cursor is within the terminal width, but the line needs
                   to be truncated *)
                (None, sub l_ 0 (term_col - 3) ^ "...")
              else
                (None, l_) in
      close_in ic;
      Some l
    else
      None
  with
    End_of_file ->
      (* TODO *)
      None


let head_pos_of_location = function
  | Loc_unknown ->
      ( "unknown location "
      , "" )
  | Loc_other str ->
      ( "other location (" ^ str ^ ") "
      , "" )
  | Loc_point pos ->
      ( string_of_pos pos
      , let cpos = Cerb_position.column pos - 1 in
        match string_at_line (Cerb_position.file pos) (Cerb_position.line pos) cpos with
          | Some (cpos'_opt, l) ->
              let cpos = match cpos'_opt with
                | Some cpos' -> cpos'
                | None       -> cpos in
              l ^ "\n" ^
              ansi_format ~err:true [Bold; Green] (String.init (cpos + 1) (fun n -> if n < cpos then ' ' else '^'))
          | None ->
              "" )
  | Loc_region (start_p, end_p, cursor) ->
      ( string_of_pos start_p
      , let cpos1 = Cerb_position.column start_p - 1 in
        match string_at_line (Cerb_position.file start_p) (Cerb_position.line start_p) cpos1 with
          | Some (_, l) ->
              let cpos2 =
                if Cerb_position.line start_p = Cerb_position.line end_p then
                  Cerb_position.column end_p - 1
                else
                  String.length l in
              let cursor_n = match cursor with
                | PointCursor cursor_p
                | RegionCursor (cursor_p, _) ->
                    Cerb_position.column cursor_p - 1
                | NoCursor ->
                    cpos1 in
              l ^ "\n" ^
              ansi_format ~err:true [Bold; Green] (
                String.init ((max cursor_n cpos2) + 1)
                  (fun n -> if n = cursor_n then '^' else if n >= cpos1 && n < cpos2 then '~' else if n < String.length l && l.[n] = '\t' then '\t' else ' ')
              )
          | None ->
              "" )
  | Loc_regions (xs, cursor) ->
      let pos = match cursor with
        | NoCursor -> fst (List.hd xs)
        | PointCursor p
        | RegionCursor (p, _) -> p
      in
      ( string_of_pos pos
      , let cursor_p = Cerb_position.column pos - 1 in
        match string_at_line (Cerb_position.file pos) (Cerb_position.line pos) cursor_p with
        | Some (_, l) ->
          let ps = List.map (fun (s, e) -> (Cerb_position.column s - 1, Cerb_position.column e - 1)) xs in
          l ^ "\n" ^ ansi_format ~err:true [Bold; Green]
            (String.init (String.length l)
               (fun n -> if n = cursor_p then '^'
                         else if List.exists (fun (p1, p2) -> n >= p1 && n < p2) ps then '~'
                         else ' ')
            )
        | None -> "" )



let simple_location = 
  let string_of_pos pos =
    Printf.sprintf "%d:%d" (Cerb_position.line pos) (Cerb_position.column pos)
  in
  function
  | Loc_unknown -> 
     "<unknown location>"
  | Loc_other str ->
     "<other location: " ^ str ^ ">"
  | Loc_point pos -> 
     string_of_pos pos
  | Loc_region (start_p, end_p, _) ->
     Printf.sprintf "<%s--%s>" (string_of_pos start_p) (string_of_pos end_p)
  | Loc_regions (xs, _) ->
     let (start_p, end_p) = List.hd xs in
     Printf.sprintf "<%s--%s>" (string_of_pos start_p) (string_of_pos end_p)

let get_filename = function
  | Loc_unknown
  | Loc_regions ([], _) ->
      None
  | Loc_other _ ->
      Some "<internal>"
  | Loc_point pos 
  | Loc_region (pos, _, _)
  | Loc_regions ((pos, _) :: _, _) ->
      Some (Cerb_position.file pos)

let is_unknown = function
  | Loc_unknown -> true 
  | _ -> false

let is_other = function
  | Loc_other str -> Some str
  | _ -> None

(* FORK-AHEAD DELTA (quotation hygiene Q1, 2026-10-26; [USER 2026-10-21] ruling B of
   lean_frontend/docs/2026-10-20_core-quote-d5-rereview.md; upstream-tray draft 58,
   whose remedy this is). Pristine b9aeedcb4 looks `Filename.dirname path` up
   LITERALLY in the three keys `Cerb_runtime.in_runtime "libc/include"`, `"libcore"`,
   `"libcore/impls"` -- the runtime argument AS SPELLED plus the fixed suffix -- so any
   spelling that denotes a runtime library directory but differs from that key is
   classified NOT library: cpp's own `./`-prefixed header positions under a relative
   `--runtime`, an absolute label under a relative runtime, a relative label under an
   absolute one, a `#line` alias, a symlinked spelling; and the served UB location
   (core_eval.lem:602, core_run.lem:477/:782) moves with the spelling. The fork
   MIRRORS THE LEAN PORT'S RULE (lean_frontend/CerbLocation.lean
   `isLibraryPathSuffix`/`isLibraryLocation` + lean_frontend/Main.lean
   `refuseLibraryLocations`): the location is library iff
     (1) its directory ends with one of the three runtime-relative library
         suffixes (the port's pure seam test), AND
     (2) the directory's resolved real path is one of the resolved real paths of
         THIS run's three runtime library directories (the port's import-time guard,
         under which (1) implies (2) on every input the port serves).
   Hence the two engines classify every served input identically, in both
   directions ((1) alone would class a user file under a directory merely named
   `runtime/libcore` as library; (2) alone would class a foreign-named symlink to a
   library directory as library where the port's suffix test does not). (1) is tested
   first so that a path outside the library shape -- every user file, and
   `<internal>` for Loc_other -- never touches the filesystem. A directory that
   passes (1) but cannot be resolved is exactly the input the port REFUSES at import
   (Main.refuseLibraryLocations: "cannot resolve the source directory"); the oracle
   refuses too (Failure) -- WHEN THE LOCATION IS REACHED: the oracle classifies lazily
   at execution, so a plant in a function the program never calls is served by the
   oracle and refused by the port (a refinement in the tolerated direction; pre-merge
   review P3-1) -- never classifying by suffix alone. Paths resolve from the
   process working directory, as the port's do; no label is rewritten. Results are
   memoised per directory string: core_run.lem:782 tests the location of EVERY
   thread step, and the three runtime directories are resolved once (lazily, after
   `Cerb_runtime.specified_runtime` is set at the CLI). Witnesses:
   scripts/check_runtime_resolution.sh (the fixture-001 classifier probe and the
   `#line` agreement pins: `./`, unprefixed, absolute and `libcore` spellings all
   serve the same UB location on both engines). *)
let library_suffixes = ["runtime/libc/include"; "runtime/libcore"; "runtime/libcore/impls"]

(* lean_frontend/CerbLocation.lean isLibraryPathSuffix: `dir == d || dir.endsWith ("/" ++ d)`
   -- EXACTLY, equality included: a root-level directory `/runtime/libcore` ends with
   `/runtime/libcore` (the first version's strict `n > m` excluded it; pre-merge review
   P2-1, 2026-10-27; the witness's root-level plant pins it). *)
let has_library_suffix dir =
  List.exists (fun d -> String.equal dir d || String.ends_with ~suffix:("/" ^ d) dir)
    library_suffixes

let realpath_opt p = try Some (Unix.realpath p) with Unix.Unix_error _ -> None

(* the port's `exact` list (Main.refuseLibraryLocations): the three directories of
   util/cerb_runtime.ml's runtime, resolved; an unresolvable one is refused there too *)
let resolved_library_dirs = lazy (
  List.map (fun d ->
    let p = Cerb_runtime.in_runtime d in
    match realpath_opt p with
      | Some r -> r
      | None ->
          failwith ("Cerb_location.is_library_location: refused - cannot resolve this run's runtime library directory `" ^ p ^ "' (the fork classifies library locations by resolved directory, mirroring the Lean port's import guard; quotation hygiene Q1, 2026-10-26)"))
    ["libc/include"; "libcore"; "libcore/impls"])

let library_dir_cache : (string, bool) Hashtbl.t = Hashtbl.create 16

let is_library_location loc =
  match get_filename loc with
    | None ->
        false
    | Some path ->
        let dir = Filename.dirname path in
        if not (has_library_suffix dir) then
          false
        else
          match Hashtbl.find_opt library_dir_cache dir with
            | Some b -> b
            | None ->
                let b =
                  match realpath_opt dir with
                    | Some r -> List.mem r (Lazy.force resolved_library_dirs)
                    | None ->
                        failwith ("Cerb_location.is_library_location: refused - source location `" ^ path ^ "' names a directory with a runtime library suffix that cannot be resolved (`" ^ dir ^ "'); the fork classifies library locations by resolved directory, mirroring the Lean port's import guard, which refuses this input (quotation hygiene Q1, 2026-10-26)") in
                Hashtbl.replace library_dir_cache dir b;
                b



(* following simple_location *)
let line_numbers = function
  | Loc_unknown -> None
  | Loc_other _ -> None
  | Loc_point p -> Some (Cerb_position.line p, Cerb_position.line p)
  | Loc_region (p1, p2, _) -> Some (Cerb_position.line p1, Cerb_position.line p2)
  | Loc_regions ((p1,p2) :: _, _) -> Some (Cerb_position.line p1, Cerb_position.line p2)
  | Loc_regions ([], _) -> None
