(* Source-location transport shared by Cabs JSON and the opt-in Core printer.
   This preserves the position observations of the existing Lean seam (source
   filename, line, column), all location constructors, and complete cursors.
   Preprocessor-internal Lexing offsets are not part of that seam. *)
let tag name args = `Assoc (("tag", `String name) :: args)
let tag0 name = `String name

let json_of_pos p =
  `Assoc [
    ("file", `String (Cerb_position.file p));
    ("line", `Int (Cerb_position.line p));
    ("col", `Int (Cerb_position.column p))
  ]

let json_of_cursor = function
  | Cerb_location.NoCursor -> tag0 "NoCursor"
  | Cerb_location.PointCursor p ->
    tag "PointCursor" [("pos", json_of_pos p)]
  | Cerb_location.RegionCursor (p1, p2) ->
    tag "RegionCursor" [("begin", json_of_pos p1); ("end", json_of_pos p2)]

let json_of_loc = function
  | Cerb_location.Loc_unknown -> tag0 "Loc_unknown"
  | Cerb_location.Loc_other s -> tag "Loc_other" [("str", `String s)]
  | Cerb_location.Loc_point p -> tag "Loc_point" [("pos", json_of_pos p)]
  | Cerb_location.Loc_region (p1, p2, cursor) ->
    tag "Loc_region" [
      ("begin", json_of_pos p1);
      ("end", json_of_pos p2);
      ("cursor", json_of_cursor cursor)
    ]
  | Cerb_location.Loc_regions (regions, cursor) ->
    tag "Loc_regions" [
      ("regions", `List (List.map (fun (p1, p2) ->
        `List [json_of_pos p1; json_of_pos p2]
      ) regions));
      ("cursor", json_of_cursor cursor)
    ]


let bad () = invalid_arg "Core source location: malformed payload"
let field key = function `Assoc xs -> (try List.assoc key xs with Not_found -> bad ()) | _ -> bad ()
let str = function `String s -> s | _ -> bad ()
let nat = function `Int n when n >= 0 -> n | _ -> bad ()
let tag_of = function `String s -> s | j -> str (field "tag" j)
let pos_of_json j =
  let file = str (field "file" j) and line = nat (field "line" j)
  and col = nat (field "col" j) in
  Cerb_position.from_lexing Lexing.{pos_fname=file; pos_lnum=line; pos_bol=0; pos_cnum=col-1}
let cursor_of_json j =
  let open Cerb_location in
  match tag_of j with
  | "NoCursor" -> NoCursor
  | "PointCursor" -> PointCursor (pos_of_json (field "pos" j))
  | "RegionCursor" -> RegionCursor (pos_of_json (field "begin" j), pos_of_json (field "end" j))
  | _ -> bad ()
let loc_of_json j =
  let open Cerb_location in
  match tag_of j with
  | "Loc_unknown" -> unknown
  | "Loc_other" -> other (str (field "str" j))
  | "Loc_point" -> point (pos_of_json (field "pos" j))
  | "Loc_region" -> region (pos_of_json (field "begin" j), pos_of_json (field "end" j)) (cursor_of_json (field "cursor" j))
  | "Loc_regions" ->
      let rs = match field "regions" j with
        | `List (_::_ as xs) -> List.map (function `List [a;b] -> pos_of_json a, pos_of_json b | _ -> bad ()) xs
        | _ -> bad () in
      regions rs (cursor_of_json (field "cursor" j))
  | _ -> bad ()

(* ASCII hex avoids Core STRING escaping ambiguities, including >>> in paths. *)
let hex s =
  let digits = "0123456789abcdef" in
  String.init (2 * String.length s) (fun i ->
    let byte = Char.code s.[i / 2] in digits.[if i mod 2 = 0 then byte lsr 4 else byte land 15])
let unhex s =
  let nibble = function
    | '0'..'9' as c -> Char.code c - Char.code '0'
    | 'a'..'f' as c -> 10 + Char.code c - Char.code 'a'
    | _ -> bad () in
  if String.length s mod 2 <> 0 then bad ();
  String.init (String.length s / 2) (fun i -> Char.chr (16 * nibble s.[2*i] + nibble s.[2*i+1]))
let encode locs direct =
  hex (Yojson.Basic.to_string (`List [
    `List (List.map json_of_loc locs);
    (match direct with None -> `Null | Some loc -> json_of_loc loc)]))
let decode s =
  match Yojson.Basic.from_string (unhex s) with
  | `List [`List xs; direct] ->
      List.map loc_of_json xs, (match direct with `Null -> None | j -> Some (loc_of_json j))
  | _ -> bad ()
