let () =
 let checks=Sc_global_binding_controls.sc_global_binding_checks(Digest.string "global-bindings") in
 List.iter(fun(name,ok)->Printf.printf "%s: %b\n" name ok)checks;
 if List.length checks<>10 || not(List.for_all snd checks)then exit 1
