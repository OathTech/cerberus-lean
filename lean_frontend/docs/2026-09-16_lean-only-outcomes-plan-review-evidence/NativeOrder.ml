(* Reduced Undefined payload; reproduce.py copies S0's generated Exception and
   State_exception modules and removes their unused `open Utils` only.
   All definitions are unchanged.
   The test callbacks never produce Stopped. *)
type 'a outcome = Defined of 'a | Undef | Error of string | Stopped of string

let bind u f = match u with
  | Defined x -> f x | Undef -> Undef | Error e -> Error e | Stopped s -> Stopped s

let sequence us = List.fold_right (fun u rest ->
  bind u (fun x -> bind rest (fun xs -> Defined (x :: xs)))) us (Defined [])

(* The existing exception_undef_mapM body, with the reduced payload above. *)
let old_map f xs = Exception.except_bind (Exception.except_mapM f xs)
  (fun us -> Exception.except_return (sequence us))

(* Stateless counterpart of the proposed direct collector. *)
let rec collect f = function
  | [] -> Exception.Result []
  | x :: xs -> match f x with
    | Exception.Exception e -> Exception.Exception e
    | Exception.Result (Stopped s) -> Exception.Result [Stopped s]
    | Exception.Result u -> match collect f xs with
      | Exception.Exception e -> Exception.Exception e
      | Exception.Result us -> Exception.Result (u :: us)

let proposed_map f xs = Exception.except_bind (collect f xs)
  (fun us -> Exception.except_return (sequence us))

let old_state_map f xs = State_exception.stExpect_bind
  (State_exception.stExpect_mapM f xs)
  (fun us -> State_exception.stExpect_return (sequence us))

let rec collect_state f xs st = match xs with
  | [] -> Exception.Result ([], st)
  | x :: xs -> match f x st with
    | Exception.Exception e -> Exception.Exception e
    | Exception.Result (Stopped s, st') -> Exception.Result ([Stopped s], st')
    | Exception.Result (u, st') -> match collect_state f xs st' with
      | Exception.Exception e -> Exception.Exception e
      | Exception.Result (us, st'') -> Exception.Result (u :: us, st'')

let proposed_state_map f xs = State_exception.stExpect_bind (collect_state f xs)
  (fun us -> State_exception.stExpect_return (sequence us))

let render = function
  | Exception.Exception e -> "typed exception: " ^ e
  | Exception.Result _ -> "result"

let capture thunk = try render (thunk ()) with Failure m -> "host failure: " ^ m

let () =
  let f x = if x = 0 then Exception.Exception "first" else failwith "second" in
  let before = capture (fun () -> old_map f [0; 1]) in
  let after = capture (fun () -> proposed_map f [0; 1]) in
  Printf.printf "No stops, host-failure control: old=%s; candidate=%s\n" before after;
  assert (before = "host failure: second");
  assert (after = "typed exception: first");
  let f_state x =
    if x = 0 then (fun _ -> Exception.Exception "first")
    else failwith "second" in
  let before_state = capture (fun () -> old_state_map f_state [0; 1] 0) in
  let after_state = capture (fun () -> proposed_state_map f_state [0; 1] 0) in
  Printf.printf "No stops, state-action construction: old=%s; candidate=%s\n"
    before_state after_state;
  assert (before_state = "host failure: second");
  assert (after_state = "typed exception: first");
  let trace = ref [] in
  let visit x = trace := !trace @ [x]; Exception.Result (Defined x) in
  ignore (old_map visit [0; 1; 2]);
  let old_trace = !trace in
  trace := [];
  ignore (proposed_map visit [0; 1; 2]);
  let new_trace = !trace in
  let show xs = String.concat "," (List.map string_of_int xs) in
  Printf.printf "No stops, callback trace: old=[%s]; candidate=[%s]\n"
    (show old_trace) (show new_trace);
  assert (old_trace <> new_trace);
  print_endline "PASS: value-level conservativity alone does not preserve native evaluation."
