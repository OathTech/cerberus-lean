open Cerb_frontend
open Ctype
let () = List.iter (fun (name, ity) -> Printf.printf "%s=%b\n" name (AilTypesAux.is_signed_ity ity)) ["signed32", Signed (IntN_t 32); "signed128", Signed (IntN_t 128); "unsigned128", Unsigned (IntN_t 128)]
