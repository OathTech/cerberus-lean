let run_tests () =
 let identity = Sc_action_identity_controls.sc_identity_checks () in
 let hb = Sc_hb_controls.sc_hb_checks () in
 List.iter (fun (name,ok) -> Printf.printf "%s: %b\n" name ok) (identity @ hb);
 if List.length identity <> 15 || List.length hb <> 17 ||
    not (List.for_all snd (identity @ hb)) then exit 1
