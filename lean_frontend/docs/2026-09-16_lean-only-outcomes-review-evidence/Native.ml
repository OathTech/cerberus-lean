module S = Outcomes_probe_stop
module U = Outcomes_probe_undefined
module N = Outcomes_probe_nd

let () =
  List.iter (fun stop ->
    assert (U.bind (U.Stopped stop) (fun (_ : int) -> failwith "continuation ran") = U.Stopped stop);
    assert (N.lift_reason (fun (_ : int) -> failwith "error mapper ran") (N.Stopped0 stop) = N.Stopped0 stop);
    assert (N.stopped_from_pure (U.Stopped stop) = Some (N.Stopped0 stop)))
    [S.Exhausted; S.FailStop "probe"; S.Unsupported (S.UF_filesystem, "open")];
  print_endline "PASS: all three stops survive bind, error-type lift, and channel conversion"

(* Exhaustive, so warning 8 cannot detect this discarded stop. *)
let swallowed = function
  | U.Defined n -> U.Defined (n + 1)
  | _ -> U.Error "legacy wildcard"

let () =
  assert (swallowed (U.Stopped S.Exhausted) = U.Error "legacy wildcard");
  print_endline "PASS: wildcard swallowing compiles with warning 8 fatal (negative control)"
