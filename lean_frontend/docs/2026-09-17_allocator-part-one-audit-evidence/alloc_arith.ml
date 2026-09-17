(* AUDITOR probe — the allocator arithmetic of memory/concrete/impl_mem.ml (== memory/vip/impl_mem.ml)
   copied verbatim, in BOTH forms: PRISTINE (b9aeedcb4 :1251-1256, the pre-fix body) and NEW (fork
   :1252-1263 after remedy 1).  Z.quomod = ediv_rem exactly as impl_mem.ml:9.  Output format is shared
   with the Lean probe (alloc_probe.lean) so the two can be diffed line by line. *)
module Z = struct include Z let quomod = ediv_rem end

let pristine last sz align =
  let open Z in
  let z = sub last sz in
  match (try Some (quomod z align) with Division_by_zero -> None) with
  | None -> "Division_by_zero"
  | Some (q, m) ->
    let z' = sub z (if q < zero then neg m else m) in
    if z' <= zero then Printf.sprintf "killed(out of memory) cursor'=%s" (to_string last)
    else Printf.sprintf "active addr=%s cursor'=%s" (to_string z') (to_string z')

let fixed last sz align =
  let open Z in
  let z = sub last sz in
  if z < zero then Printf.sprintf "killed(out of memory) cursor'=%s" (to_string last)
  else
    match (try Some (quomod z align) with Division_by_zero -> None) with
    | None -> "Division_by_zero"
    | Some (_, m) ->
      let z' = sub z m in
      if z' <= zero then Printf.sprintf "killed(out of memory) cursor'=%s" (to_string last)
      else Printf.sprintf "active addr=%s cursor'=%s" (to_string z') (to_string z')

let p70 = Z.pow (Z.of_int 2) 70
let p80 = Z.pow (Z.of_int 2) 80
let top = Z.of_string "281474976710655"   (* 0xFFFFFFFFFFFF = upstream's initial last_address *)
let i = Z.of_int
let states = [
  (* draft 44 *)            (i 3, i 4, i 4); (i 7, i 8, i 8); (i 2, i 4, i 4); (i 8, i 4, i 4);
  (* negative sz *)         (i 8, i (-4), i 4); (i 8, i (-1), i 1); (i 0, i (-5), i 4); (i (-3), i (-8), i 4);
  (* align = 1 *)           (i 8, i 4, i 1); (i 4, i 4, i 1); (i 5, i 4, i 1); (i 3, i 4, i 1);
  (* sz = 0 *)              (i 8, i 0, i 4); (i 0, i 0, i 4); (i 3, i 0, i 4); (i 16, i 0, i 16); (i 1, i 0, i 1);
  (* cursor == sz *)        (i 4, i 4, i 4); (i 16, i 16, i 8); (i 1, i 1, i 1);
  (* cursor = sz+align-1 *) (i 7, i 4, i 4); (i 11, i 4, i 8); (i 15, i 8, i 8);
  (* huge align *)          (i 100, i 4, p70); (p80, i 4, p70); (Z.add p70 (i 96), i 32, p70);
  (* align < 0 *)           (i 8, i 4, i (-4)); (i 7, i 4, i (-4)); (i 3, i 4, i (-4)); (i 9, i 4, i (-4)); (i (-5), i 4, i (-4));
  (* cursor < 0 *)          (i (-5), i 4, i 4); (i (-1), i 0, i 4);
  (* align = 0 *)           (i 8, i 4, i 0); (i 3, i 4, i 0); (i 4, i 4, i 0);
  (* upstream's bound *)    (top, Z.succ top, i 16); (top, Z.add top (i 7), i 16); (top, Z.add top (i 8), i 16);
                            (top, top, i 16); (top, i 16, i 16); (top, Z.add top (i 1), i 1);
]
let () =
  let (q, m) = Z.quomod (Z.of_int (-1)) (Z.of_int 4) in
  Printf.printf "ediv_rem (-1) 4 = (%s, %s)\n" (Z.to_string q) (Z.to_string m);
  let show (a, b) = Printf.sprintf "(%s, %s)" (Z.to_string a) (Z.to_string b) in
  Printf.printf "ediv_rem 7 (-4) = %s; ediv_rem (-7) (-4) = %s; ediv_rem (-7) 4 = %s\n"
    (show (Z.quomod (i 7) (i (-4)))) (show (Z.quomod (i (-7)) (i (-4)))) (show (Z.quomod (i (-7)) (i 4)));
  print_endline "## NEW (fork after remedy 1)";
  List.iter (fun (l, s, a) ->
    Printf.printf "last=%s sz=%s align=%s: %s\n" (Z.to_string l) (Z.to_string s) (Z.to_string a) (fixed l s a)) states;
  print_endline "## PRISTINE (b9aeedcb4, pre-fix)";
  List.iter (fun (l, s, a) ->
    Printf.printf "last=%s sz=%s align=%s: %s\n" (Z.to_string l) (Z.to_string s) (Z.to_string a) (pristine l s a)) states
