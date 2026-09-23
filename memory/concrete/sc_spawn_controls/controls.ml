let () =
 let checks=Sc_spawn_controls.sc_spawn_checks (Digest.string "spawn-controls") in
 List.iter(fun(name,ok)->Printf.printf "%s: %b\n" name ok)checks;
 if List.length checks <> 11 || not(List.for_all snd checks)then exit 1
