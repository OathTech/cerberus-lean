(* Passive diagnostic consumer of the real concrete primitives. See the WP0
   record for the deliberately smaller meaning of a receipt than a C action. *)
open Cerb_frontend
open Nondeterminism
open Ctype
open Mem_common
module M = Impl_mem
let step (ND f) st = f st
let loc = Cerb_location.other "wp0"
let iv n = M.integer_ival (Z.of_int n)
let uc = Ctype ([], Basic (Integer (Unsigned Ichar)))
let si = Ctype ([], Basic (Integer (Signed Int_)))
let bt = Ctype ([], Basic (Integer Bool))
let dt = Ctype ([], Basic (Floating (RealFloating Double)))
let pt = Ctype ([], Pointer (no_qualifiers, si))
let at = Ctype ([], Array (uc, Some (Z.of_int 4)))
let intv t n = M.integer_value_mval t (iv n)
let bv = intv (Unsigned Ichar)
let base = 65472
let ptr offset = M.concrete_ptrval Z.zero (Z.of_int (base + offset))
let last st = match M.serialise_mem_state (Digest.string "wp0") st with
  | `Assoc xs -> (match List.assoc "last_used" xs with `Int n -> string_of_int n | `Null -> "-" | _ -> assert false)
  | _ -> assert false
let opt f = function None -> "-" | Some x -> f x
let prov = function
  | Observed_no_provenance -> "none"
  | Observed_allocation_provenance n -> "alloc:" ^ Z.to_string n
  | Observed_symbolic_provenance n -> "symbolic:" ^ Z.to_string n
  | Observed_device_provenance -> "device"
let byte (Byte_view (p, off, v)) = prov p ^ "/" ^ opt Z.to_string off ^ "/" ^ opt Z.to_string v
let pv p = M.case_ptrval p (fun _ -> "null") (fun _ -> "function")
  (fun a n -> opt Z.to_string a ^ ":" ^ Z.to_string n)
let ty t = if t = uc then "uc" else if t = si then "int" else if t = bt then "bool"
  else if t = dt then "double" else if t = pt then "ptr" else if t = at then "array" else "UNKNOWN"
let rec value v = M.case_mem_value v
  (fun t -> "unspec:" ^ ty t)
  (fun _ _ -> "UNEXPECTED_CONCURRENT_READ")
  (fun t i -> (if t = Bool then "b:" else "i:") ^ M.case_integer_value i Z.to_string (fun () -> "unspec"))
  (fun _ f -> M.case_fval f (fun () -> "unspec-float") (fun f -> "f:" ^ Printf.sprintf "%Lu" (Int64.bits_of_float f)))
  (fun _ p -> "p:" ^ pv p)
  (fun vs -> "a:" ^ String.concat "," (List.map value vs))
  (fun _ _ -> "UNEXPECTED_STRUCT") (fun _ _ _ -> "UNEXPECTED_UNION")
let status = function
  | NDactive _ -> "active"
  | NDkilled (Undef0 (_, [Undefined.UB012_lvalue_read_trap_representation])) -> "trap"
  | NDkilled (Other (MerrOther "after")) -> "after"
  | NDkilled (Undef0 (l, [Undefined.UB064_modifying_const])) -> if l = loc then "readonly" else "BADLOC"
  | NDkilled (Undef0 (l, [Undefined.UB019_lvalue_not_an_object])) -> if l = loc then "null" else "BADLOC"
  | NDkilled _ -> "UNEXPECTED_KILL"
  | _ -> "UNEXPECTED_NODE"
let receipt name (Access_receipt (l, k, t, p, a, addr, bs, v, locking)) =
  Printf.printf "access %s %s %s %s %s %s %s %s %s %s\n" name
    (if l = loc then "loc" else "BADLOC") (if k = LoadAccess then "R" else "W")
    (opt (fun b -> if b then "1" else "0") locking) (ty t) (pv p) (opt Z.to_string a) (Z.to_string addr)
    (String.concat "," (List.map byte bs)) (value v)
let enable st = Option.get (M.begin_observing st)
let drain st = Option.get (M.take_observations st)
let require ok msg = if not ok then failwith msg
let run name m st =
  let plain, plain_st = step m (M.stop_observing st) in
  let action, observed_st = step m (enable st) in
  (* The actual entire native state and primitive result, not receipt-derived
     shadows. This equality is only used on primitive nodes without functions. *)
  require (plain = action && plain_st = M.stop_observing observed_st) (name ^ ": erasure");
  if name = "same-write" then require (M.stop_observing st = plain_st) "same-value control changed state";
  let rs, st = drain observed_st in
  let again, st = drain st in
  require (again = []) (name ^ ": drain");
  Printf.printf "node %s %s %s %d\n" name (status action) (last st) (List.length rs);
  List.iter (receipt name) rs;
  st
let setup () =
  let alloc = M.allocate_region 0 (Symbol.PrefOther "wp0") (iv 1) (iv 64) in
  let take m st = match step m st with NDactive p, st -> p, st | _ -> failwith "setup" in
  let p, st = take alloc (M.initial_mem_state (Z.of_int 65536)) in
  let q, st = take alloc st in
  require (pv p = "0:65472" && pv q = "1:65408") "allocation layout";
  st
let store t offset v = M.store loc t false (ptr offset) v
let load t offset = M.load loc t (ptr offset)
let scenarios st =
  let st = run "byte-write" (store uc 0 (bv 42)) st in
  let st = run "same-write" (store uc 0 (bv 42)) st in
  let st = run "byte-read" (load uc 0) st in
  let st = run "int-write" (store si 4 (intv (Signed Int_) 16909060)) st in
  let st = run "int-read" (load si 4) st in
  let st = run "byte-update" (store uc 5 (bv 170)) st in
  let st = run "updated-int" (load si 4) st in
  let st = run "ptr-write" (store pt 8 (M.pointer_mval si (ptr 4))) st in
  let st = run "ptr-read" (load pt 8) st in
  let st = run "float-write" (store dt 16 (M.floating_value_mval (RealFloating Double) (M.str_fval "-0.0"))) st in
  let st = run "float-read" (load dt 16) st in
  let st = run "array-write" (store at 24 (M.array_mval (List.map bv [1;2;3;4]))) st in
  let st = run "array-read" (load at 24) st in
  let st = run "unspec-write" (store si 4 (M.unspecified_mval si)) st in
  let st = run "unspec-read" (load si 4) st in
  let st = run "trap-byte" (store uc 0 (bv 2)) st in
  let st = run "trap-read" (load bt 0) st in
  let st = run "unspec-bool-write" (store bt 0 (M.unspecified_mval bt)) st in
  let st = run "unspec-bool-read" (load bt 0) st in
  let st = run "null-read" (M.load loc uc (M.null_ptrval uc)) st in
  let st = run "null-write" (M.store loc uc false (M.null_ptrval uc) (bv 1)) st in
  let q = M.concrete_ptrval Z.one (Z.of_int 65408) in
  let st = run "locking-write" (M.store loc uc true q (bv 7)) st in
  let st = run "readonly-write" (M.store loc uc false q (bv 8)) st in
  let st = run "readonly-read" (M.load loc uc q) st in
  let st = run "before-failure" (M.bind (load uc 24) (fun _ -> Nondeterminism.kill (Other (MerrOther "after")))) st in
  let st = run "two-before-failure" (M.bind (store uc 0 (bv 9)) (fun _ ->
    M.bind (load uc 24) (fun _ -> Nondeterminism.kill (Other (MerrOther "after"))))) st in
  require (M.take_observations (M.stop_observing st) = None) "disabled drain";
  let _, pending = step (store uc 0 (bv 42)) (enable st) in
  require (List.length (fst (drain (enable pending))) = 1) "enabling dropped prefix";
  st
(* Exercise every existing ND constructor through the existing liftND. Guards
   are retained as data, not solved or advertised as admitted executions. *)
let transport st =
  let cs = MC_eq (iv 1, iv 2) in
  let child n = M.bind (store uc 0 (bv n)) (fun _ -> M.return n) in
  let children = ["left", child 11; "right", child 12] in
  let cases = [NDactive 7; NDkilled (Other (MerrOther "after"));
    NDnd ("choice", children); NDguard ("guard", cs, child 11);
    NDbranch ("branch", cs, child 11, child 12); NDstep ("step", children)] in
  List.iter (fun node ->
    let m = M.bind (store uc 0 (bv 33)) (fun _ -> ND (fun s -> node, s)) in
    let lifted = Nondeterminism.liftND fst (fun (_, marker) s -> s, marker) Fun.id Fun.id m in
    let action, (out, marker) = step lifted (enable st, 99) in
    require (marker = 99) "lift changed enclosing state";
    let rs, out = drain out in
    require (List.length rs = 1) "lift lost completed prefix";
    let actual_byte n s = match step (load uc 0) (M.stop_observing s) with
      | NDactive (_, v), _ -> v = bv n
      | _ -> false in
    require (actual_byte 33 out && last out = "0") "lift lost returned memory state";
    let child_check n m =
      match step m (out, marker) with
      | NDactive v, (s, marker) ->
          require (v = n && marker = 99 && List.length (fst (drain s)) = 1 && actual_byte n s)
            "lift changed child"
      | _ -> failwith "lift child killed/dropped" in
    match node, action with
    | NDactive 7, NDactive 7 -> ()
    | NDkilled r, NDkilled r' -> require (r = r') "lift changed kill"
    | NDnd _, NDnd ("choice", [("left", l); ("right", r)])
    | NDstep _, NDstep ("step", [("left", l); ("right", r)]) -> child_check 11 l; child_check 12 r
    | NDguard _, NDguard ("guard", c, m) -> require (c = cs) "lift changed guard"; child_check 11 m
    | NDbranch _, NDbranch ("branch", c, l, r) -> require (c = cs) "lift changed branch"; child_check 11 l; child_check 12 r
    | _ -> failwith "lift changed node/alternatives/order"
  ) cases;
  print_endline "transport active killed nd guard branch step"
let () =
  Tags.set_tagDefs (Pmap.empty Symbol.symbol_compare);
  let st = scenarios (setup ()) in
  transport st;
  require (Array.length Sys.argv = 3) "usage: access_probe ITERATIONS on|off";
  let iterations = int_of_string Sys.argv.(1) in
  let enabled = match Sys.argv.(2) with "on" -> true | "off" -> false | _ -> failwith "bad mode" in
  require (iterations >= 0) "negative iterations";
  let s = ref (if enabled then st else M.stop_observing st) in
  for _ = 1 to iterations do
    let action, next = step (store uc 0 (bv 42)) !s in
    require (match action with NDactive _ -> true | _ -> false) "stream primitive failed";
    if enabled then begin
      let rs, next = drain next in
      require (List.length rs = 1) "stream must drain one receipt per primitive";
      s := next
    end else begin
      require (M.take_observations next = None) "disabled stream captured";
      s := next
    end
  done;
  let retained = match M.take_observations !s with None -> 0 | Some (xs, _) -> List.length xs in
  Printf.printf "stream %s %d %d\n" Sys.argv.(2) iterations retained
