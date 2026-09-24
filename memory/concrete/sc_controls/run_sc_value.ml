(* Logical-key controls, not a complete C-to-Cmm reads-from adapter. *)
open Cerb_frontend
module M = Impl_mem
module V = Sc_value
module C = Sc_reference
module A = Sc_reference_aux
let z = Z.of_int
let iv n = M.integer_ival (z n)
let loc = Cerb_location.other "SC value control"
let ty ity = Ctype.Ctype ([], Ctype.Basic (Ctype.Integer ity))
let sint = ty (Ctype.Signed Ctype.Int_)
let uint = ty (Ctype.Unsigned Ctype.Int_)
let fty = Ctype.RealFloating Ctype.Double
let double = Ctype.Ctype ([], Ctype.Basic (Ctype.Floating fty))
let sym = Symbol.Symbol ("sc-value-control", 1, Symbol.SD_None)
let id = Symbol.Identifier (loc, "member")
let key value = match M.sc_value_key value with Some key -> key | None -> failwith "missing concrete value key"
let active (Nondeterminism.ND f) state = match f state with
  | Nondeterminism.NDactive value, state -> value,state
  | _ -> failwith "value control memory setup failed"
let float_bits bits =
  let u64 = ty (Ctype.Unsigned Ctype.LongLong) in
  let memory = M.initial_mem_state (z 65536) in
  let source,memory = active (M.allocate_object 0 (Symbol.PrefOther "bits") (iv 8) u64 None None) memory in
  let number = Z.of_int64 bits in
  let number = if Z.sign number < 0 then Z.add number (Z.shift_left Z.one 64) else number in
  let _,memory = active (M.store loc u64 false source
    (M.integer_value_mval (Ctype.Unsigned Ctype.LongLong) (M.integer_ival number))) memory in
  let destination,memory = active (M.allocate_object 0 (Symbol.PrefOther "float") (iv 8) double None None) memory in
  let _,memory = active (M.memcpy loc destination source (iv 8)) memory in
  snd (fst (active (M.load loc double destination) memory))
let int_value n = M.integer_value_mval (Ctype.Signed Ctype.Int_) (iv n)
let check label good = Printf.printf "%s: %b\n%!" label good; if not good then exit 1
let set xs = List.fold_left (fun acc x -> Pset.add x acc) (Pset.empty Stdlib.compare) xs
(* Action sets use the model's ID order, including across constructors. *)
let actions xs = Pset.from_list
  C.instance_Basic_classes_SetType_Sc_reference_action_dict.Lem_pervasives.setElemCompare_method xs
let relation xs = Pset.from_list (fun (a,b) (c,d) ->
  Stdlib.compare (C.sc_ref_aid_of a,C.sc_ref_aid_of b)
                 (C.sc_ref_aid_of c,C.sc_ref_aid_of d)) xs
let rf_accepts write read =
  let wi,table = V.sc_intern_value write [] in
  let ri,_ = V.sc_intern_value read table in
  let location = A.SCRef_Loc_hol 0 and thread = A.SCRef_Tid_hol 0 in
  let w = C.SCRef_Store (10, thread, C.SCRef_NA, location, A.SCRef_Cvalue_hol wi) in
  let r = C.SCRef_Load (11, thread, C.SCRef_NA, location, A.SCRef_Cvalue_hol ri) in
  let xo = {C.sc_ref_actions=actions [w;r]; sc_ref_threads=set [thread]; sc_ref_lk=(fun _ -> C.SCRef_Non_Atomic);
    sc_ref_sb=relation [w,r]; sc_ref_asw=relation []; sc_ref_dd=relation []} in
  let xw = {C.sc_ref_rf=relation [w,r]; sc_ref_mo=relation []; sc_ref_sc=relation []; sc_ref_lo=relation []; sc_ref_tot=relation []} in
  if not (C.sc_ref_well_formed_threads (xo,xw,[])) then failwith "malformed RF fixture";
  C.sc_ref_well_formed_rf (xo,xw,[])
let run_tests () =
  let patterns = [0L; 0x8000000000000000L; 0x3ff0000000000000L; 0xbff0000000000000L;
    0x7ff0000000000000L; 0xfff0000000000000L;
    0x7ff8000000000001L; 0x7ff8000000000002L; 0xfff8000000000001L;
    0x7ff0000000000001L; 0x7ff0000000000002L; 0xfff0000000000001L] in
  let floats = List.map (fun bits -> bits,key (float_bits bits)) patterns in
  check "floating conversion retains all twelve exact bit words"
    (List.for_all (fun (bits,k) -> k=V.SC_floating_value (fty,Z.of_int64 bits)) floats);
  check "floating logical equality agrees with all 144 bit comparisons"
    (List.for_all (fun (a,ka) -> List.for_all (fun (b,kb) -> (ka=kb)=(a=b)) floats) floats);
  let nan = key (float_bits 0x7ff8000000000001L) in
  let other_nan = key (float_bits 0x7ff8000000000002L) in
  let zero = key (float_bits 0L) and negative_zero = key (float_bits 0x8000000000000000L) in
  check "reference RF accepts identical NaN bit words" (rf_accepts nan nan);
  check "reference RF rejects different NaN payload tokens" (not (rf_accepts nan other_nan));
  check "reference RF distinguishes opposite signed zero tokens" (not (rf_accepts zero negative_zero));
  check "reference RF accepts identical finite tokens"
    (let finite = key (float_bits 0x3ff0000000000000L) in rf_accepts finite finite);
  check "integer key retains signed type and magnitude"
    (key (int_value (-7))=V.SC_integer_value (Ctype.Signed Ctype.Int_,V.SC_no_provenance,z (-7)));
  check "equal integer numbers with different view types stay distinguishable"
    (key (int_value 7)<>key (M.integer_value_mval (Ctype.Unsigned Ctype.Int_) (iv 7)));
  let p1 = M.concrete_ptrval (z 1) (z 4096) and p2 = M.concrete_ptrval (z 2) (z 4096) in
  let pv pointer = M.pointer_mval sint pointer in
  check "equal numeric pointer addresses retain distinct storage provenance" (key (pv p1)<>key (pv p2));
  check "pointer key retains reference type" (key (pv p1)<>key (M.pointer_mval uint p1));
  check "null pointer retains its base type"
    (key (pv (M.null_ptrval sint))<>key (pv (M.null_ptrval uint)));
  check "function pointer identity is retained"
    (key (pv (M.fun_ptrval sym))=V.SC_pointer_value (sint,(V.SC_no_provenance,V.SC_function_pointer sym)));
  check "unspecified type remains distinguishable"
    (key (M.unspecified_mval sint)<>key (M.unspecified_mval uint));
  let nested = M.array_mval [M.struct_mval sym [id,sint,M.union_mval sym id (float_bits 0x7ff8000000000001L)]; int_value 7] in
  let expected = V.SC_array_value [V.SC_struct_value (sym,[id,sint,V.SC_union_value (sym,id,nan)]); key (int_value 7)] in
  check "nested aggregate conversion retains tags members types and payloads" (key nested=expected);
  let annotated = Ctype.Ctype ([Annot.Auid "preserve-type-metadata"], Ctype.Basic (Ctype.Integer (Ctype.Signed Ctype.Int_))) in
  let located = Symbol.Identifier (Cerb_location.other "different source location", "member") in
  let described = Symbol.Symbol ("sc-value-control",1,Symbol.SD_Id "different description") in
  let metadata_pairs = [
    key (M.unspecified_mval sint),key (M.unspecified_mval annotated);
    V.SC_pointer_value (sint,(V.SC_no_provenance,V.SC_function_pointer sym)),
      V.SC_pointer_value (sint,(V.SC_no_provenance,V.SC_function_pointer described));
    V.SC_union_value (sym,id,nan),V.SC_union_value (sym,located,nan);
    V.SC_pointer_value (sint,(V.SC_storage_provenance (z 1),V.SC_concrete_pointer (None,z 4096))),
      V.SC_pointer_value (sint,(V.SC_storage_provenance (z 1),V.SC_concrete_pointer (Some id,z 4096)))] in
  check "key comparison retains type annotations symbol descriptions member locations and pointer tags"
    (List.for_all (fun (a,b) -> a<>b) metadata_pairs);
  check "interner preserves all four metadata distinctions"
    (List.for_all (fun (a,b) -> let first,table=V.sc_intern_value a [] in
      let second,_=V.sc_intern_value b table in first<>second) metadata_pairs);
  let token,table = V.sc_intern_value nan [] in
  let other,extended = V.sc_intern_value other_nan table in
  let again,same = V.sc_intern_value nan extended in
  check "interning reuses an old token without changing the table"
    (token=0 && other=1 && again=token && same=extended && List.length same=2);
  let reverse0,reverse = V.sc_intern_value other_nan [] in
  let reverse1,_ = V.sc_intern_value nan reverse in
  check "token numbering is candidate local rather than a C value"
    (reverse0=token && reverse1=other && nan<>other_nan)
