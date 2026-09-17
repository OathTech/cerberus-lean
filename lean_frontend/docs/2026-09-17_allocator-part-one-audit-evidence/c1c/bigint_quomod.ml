let () =
  let s = Big_int.string_of_big_int and b = Big_int.big_int_of_int in
  List.iter (fun (a, m) -> let (q, r) = Big_int.quomod_big_int (b a) (b m) in
    Printf.printf "Big_int.quomod_big_int (%d) %d = (%s, %s)\n" a m (s q) (s r)) [(-1, 4); (-5, 4); (-1, 8); (7, -4); (-7, -4)]
