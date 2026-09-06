let () =
  let open Discarded_failures in
  let f = match Sys.argv.(1) with
    | "unused_binding" -> unused_binding
    | "unused_argument" -> unused_argument
    | "projection" -> projection
    | "discarded_result" -> discarded_result
    | "callback" -> callback
    | "mapped_projection" -> mapped_projection
    | "required" -> required
    | "control" -> positive_control
    | _ -> failwith "unknown probe" in
  print_endline (string_of_int (f (Array.length Sys.argv - 2)))
