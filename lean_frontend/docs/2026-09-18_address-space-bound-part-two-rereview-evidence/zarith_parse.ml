let () = List.iter (fun s ->
  try Printf.printf "%S -> %s\n" s (Z.to_string (Z.of_string s))
  with Invalid_argument x -> Printf.printf "%S -> INVALID %s\n" s x
) ["6_4"; "6__4"; "64_"; "_64"]
