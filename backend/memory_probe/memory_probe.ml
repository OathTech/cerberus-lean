(* Direct calls to the production memory primitives; no Core evaluator or
   final-result projection can hide the state returned on a failed load. *)
open Cerb_frontend
open Nondeterminism
open Ctype
module M = Impl_mem

let step (ND f) st = f st
let active m st = match step m st with
  | NDactive v, st -> v, st
  | _ -> failwith "primitive setup did not return NDactive"
let last_used st = match M.serialise_mem_state (Digest.string "wp0") st with
  | `Assoc xs -> List.assoc "last_used" xs
  | _ -> failwith "missing concrete state diagnostic"

let () =
  Tags.set_tagDefs (Pmap.empty Symbol.symbol_compare);
  let loc = Cerb_location.other "wp0" in
  let bool_ty = Ctype ([], Basic (Integer Bool)) in
  let byte_ty = Ctype ([], Basic (Integer (Unsigned Ichar))) in
  let iv n = M.integer_ival (Z.of_int n) in
  let alloc ty = M.allocate_object 0 (Symbol.PrefOther "wp0") (iv 1) ty None None in
  let p, st = active (alloc bool_ty) (M.initial_mem_state (Z.of_int 65536)) in
  let q, st = active (alloc byte_ty) st in
  let byte n = M.integer_value_mval (Unsigned Ichar) (iv n) in
  let touch st = snd (active (M.store loc byte_ty false q (byte 0)) st) in
  let failures = ref 0 in
  let check name ok =
    Printf.printf "%s %s\n" (if ok then "PASS" else "FAIL") name;
    if not ok then incr failures in
  List.iter (fun n ->
    let s = match n with
      | None -> touch st
      | Some n -> touch (snd (active (M.store loc byte_ty false p (byte n)) st)) in
    if last_used s <> `Int 1 then failwith "setup last_used must be allocation 1";
    let action, after = step (M.load loc bool_ty p) s in
    let outcome = match action, n with
      | NDkilled (Undef0 (_, [Undefined.UB012_lvalue_read_trap_representation])), (None | Some 2) -> true
      | NDactive (_, v), Some n -> v = M.integer_value_mval Bool (iv n)
      | _ -> false in
    check ("Bool " ^ (match n with None -> "unspecified" | Some n -> string_of_int n))
      (outcome && last_used after = `Int 0)
  ) [Some 0; Some 1; Some 2; None];
  let s = touch st in
  check "rejected pointer retains input state" (match step (M.load loc bool_ty (M.null_ptrval bool_ty)) s with
    | NDkilled _, after -> last_used after = `Int 1
    | _ -> false);
  exit (if !failures = 0 then 0 else 1)
