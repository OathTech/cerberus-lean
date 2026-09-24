let run_tests () =
 let digest = String.make 16 '\000' in
 let linkage = Sc_library_link_controls.sc_library_link_checks digest in
 let attributed = Sc_link_attribution_controls.sc_attribution_checks digest (fun k v -> Pmap.add k v (Pmap.empty (fun _ _ -> 0))) in
 let globals = Sc_global_origin_controls.sc_global_origin_checks digest in
 let receipts = Sc_global_attribution_controls.sc_global_attribution_checks digest in
 let parameters = Sc_parameter_read_controls.sc_slot_read_checks digest in
 let checks = linkage @ attributed @ globals @ receipts @ parameters in
 List.iter (fun (name,ok) -> Printf.printf "%s: %b\n" name ok) checks;
 if List.length linkage <> 8 || List.length attributed <> 12 || List.length globals <> 10 || List.length receipts <> 16 || List.length parameters <> 12 || not (List.for_all snd checks) then exit 1
