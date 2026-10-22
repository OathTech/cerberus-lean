import CerbStop
import Init.Data.String.Lemmas.Basic
import Init.Data.String.Lemmas.IsEmpty

/-! Diagnostic metadata for the hand-written producer seams. Source coordinates
are at the immutable revision below, not the generated fork's moving lines.
Historical diagnostic strings remain call-site data; their old line references
are not the attribution. There is no failure leaf or runtime metadata fallback
in this module. All pure callers retain their visible failwithI head.

[AGENT 2026-10-20] Keep citation construction separate from the operational
branches, so the migration changes only diagnostics and the declared channels.
-/
namespace CerbStopSites
open CerbStop

/-- A fixed nonempty prefix makes arbitrary diagnostic data safe to render,
without a second failure path or a default substituted for invalid metadata. -/
def appendText (s : NonemptyText) (t : String) : NonemptyText :=
  ⟨s.value ++ t, by
    apply String.isEmpty_eq_false_iff.mpr
    intro h
    exact (String.isEmpty_eq_false_iff.mp s.nonempty) (String.append_eq_empty_iff.mp h).1⟩

def refusal (boundary : Boundary) (item : Option String) (detail : String)
    (mover : NonemptyText) (see : NonemptyText) : Refusal :=
  { boundary, item, detail := appendText ⟨"Refused: ", by decide⟩ detail,
    mover, see := some see }

private def mirror (site : NonemptyText) (detail : String) (upstream : Upstream)
    (tray : Tray := .none) : UpstreamCrash :=
  { site, detail := appendText ⟨"Mirrored upstream failure: ", by decide⟩ detail, upstream, tray }

def invariant (site : NonemptyText) (detail : String) (see : NonemptyText) : Invariant :=
  { site, detail := appendText ⟨"Invariant failed: ", by decide⟩ detail, see }

private def memSource (first last : Nat) (lines : 0 < first ∧ first ≤ last)
    (text : String) : Upstream :=
  { repository := .cerberus, revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de", path := "memory/concrete/impl_mem.ml",
    first, last, text, revision_valid := by decide, path_valid := by decide, lines_valid := lines }

private def decodeSource (first last : Nat) (lines : 0 < first ∧ first ≤ last)
    (text : String) : Upstream :=
  { repository := .cerberus, revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de", path := "ocaml_frontend/decode.ml",
    first, last, text, revision_valid := by decide, path_valid := by decide, lines_valid := lines }

private def implSource (first last : Nat) (lines : 0 < first ∧ first ≤ last)
    (text : String) : Upstream :=
  { repository := .cerberus, revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de", path := "ocaml_frontend/ocaml_implementation.ml",
    first, last, text, revision_valid := by decide, path_valid := by decide, lines_valid := lines }

private def gccSource (first last : Nat) (lines : 0 < first ∧ first ≤ last)
    (text : String) : Upstream :=
  { repository := .cerberus, revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de", path := "ocaml_frontend/ocaml_gcc_builtins.ml",
    first, last, text, revision_valid := by decide, path_valid := by decide, lines_valid := lines }

private def locationSource (first last : Nat) (lines : 0 < first ∧ first ≤ last)
    (text : String) : Upstream :=
  { repository := .cerberus, revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de", path := "util/cerb_location.ml",
    first, last, text, revision_valid := by decide, path_valid := by decide, lines_valid := lines }

private def stepSource (first last : Nat) (lines : 0 < first ∧ first ≤ last)
    (text : String) : Upstream :=
  { repository := .cerberus, revision := "b9aeedcb4dd438763b0eef7f95ac19e93875d7de", path := "frontend/model/core_reduction.lem",
    first, last, text, revision_valid := by decide, path_valid := by decide, lines_valid := lines }

def targetPtrSize (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.targetPtrSize", by decide⟩ detail
    (memSource 1159 1163 (by decide) "let ptr_size = match (Ocaml_implementation.get ()).sizeof_pointer with\n            | None ->\n                failwith \"the concrete memory model requires a complete implementation\"\n            | Some z ->\n                z in")

def offsetsof (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.offsetsof", by decide⟩ detail
    (memSource 100 100 (by decide) "match Pmap.find tag_sym tagDefs with")

def sizeofVoid (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.sizeofVoid", by decide⟩ detail
    (memSource 134 135 (by decide) "| Void | Array (_, None) | Function _ | FunctionNoParams _ ->\n        assert false")

def sizeofIncompleteArray (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.sizeofIncompleteArray", by decide⟩ detail
    (memSource 134 135 (by decide) "| Void | Array (_, None) | Function _ | FunctionNoParams _ ->\n        assert false")

def sizeofFunction (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.sizeofFunction", by decide⟩ detail
    (memSource 134 135 (by decide) "| Void | Array (_, None) | Function _ | FunctionNoParams _ ->\n        assert false")

def sizeofInteger (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.sizeofInteger", by decide⟩ detail
    (memSource 136 141 (by decide) "| Basic (Integer ity) ->\n        begin match (Ocaml_implementation.get ()).sizeof_ity ity with\n          | Some n ->\n              of_int n\n          | None ->\n              failwith (\"the concrete memory model requires a complete implementation sizeof INTEGER => \" ^ String_core_ctype.string_of_ctype cty)")

def sizeofFloat (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.sizeofFloat", by decide⟩ detail
    (memSource 143 148 (by decide) "| Basic (Floating fty) ->\n        begin match (Ocaml_implementation.get ()).sizeof_fty fty with\n          | Some n ->\n              of_int n\n          | None ->\n              failwith \"the concrete memory model requires a complete implementation sizeof FLOAT\"")

def sizeofUnion (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.sizeofUnion", by decide⟩ detail
    (memSource 172 175 (by decide) "| Union tag_sym ->\n        begin match Pmap.find tag_sym (Tags.tagDefs ()) with\n          | _, StructDef _ ->\n              assert false")

def alignofVoid (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.alignofVoid", by decide⟩ detail
    (memSource 198 199 (by decide) "| Void ->\n        assert false")

def alignofFunction (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.alignofFunction", by decide⟩ detail
    (memSource 216 218 (by decide) "| Function _\n    | FunctionNoParams _ ->\n        assert false")

def alignofInteger (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.alignofInteger", by decide⟩ detail
    (memSource 200 205 (by decide) "| Basic (Integer ity) ->\n        begin match (Ocaml_implementation.get ()).alignof_ity ity with\n          | Some n ->\n              n\n          | None ->\n              failwith (\"the concrete memory model requires a complete implementation alignof INTEGER => \" ^ String_core_ctype.string_of_ctype cty)")

def alignofFloat (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.alignofFloat", by decide⟩ detail
    (memSource 207 212 (by decide) "| Basic (Floating fty) ->\n        begin match (Ocaml_implementation.get ()).alignof_fty fty with\n          | Some n ->\n              n\n          | None ->\n              failwith \"the concrete memory model requires a complete implementation alignof FLOATING\"")

def alignofStruct (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.alignofStruct", by decide⟩ detail
    (memSource 228 231 (by decide) "| Struct tag_sym ->\n        begin match Pmap.find tag_sym tagDefs with\n          | _, UnionDef _ ->\n              assert false")

def alignofUnion (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.alignofUnion", by decide⟩ detail
    (memSource 254 257 (by decide) "| Union tag_sym ->\n        begin match Pmap.find tag_sym (Tags.tagDefs ()) with\n          | _, StructDef _ ->\n              assert false")

def intToBytes (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.intToBytes", by decide⟩ detail
    (memSource 1105 1109 (by decide) "if not (min <= i && i <= max) || nbits > 128 then begin\n      Printf.printf \"failed: bytes_of_int(%s), i= %s, nbits= %d, [%s ... %s]\\n\"\n        (if is_signed then \"signed\" else \"unsigned\")\n        (Z.to_string i) nbits (Z.to_string min) (Z.to_string max);\n      assert false")

def bytesToIntEmpty (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.bytesToIntEmpty", by decide⟩ detail
    (memSource 742 743 (by decide) "| [] ->\n          assert false")

def bytesToIntOversize (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.bytesToIntOversize", by decide⟩ detail
    (memSource 744 745 (by decide) "| cs when L.length cs > 16 ->\n          assert false")

def splitBytesProv (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.splitBytesProv", by decide⟩ detail
    (memSource 432 434 (by decide) "let split_bytes = function\n      | [] ->\n          failwith \"Concrete.AbsByte.split_bytes: called on an empty list\"")

def serializeInteger (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.serializeInteger", by decide⟩ detail
    (memSource 136 141 (by decide) "| Basic (Integer ity) ->\n        begin match (Ocaml_implementation.get ()).sizeof_ity ity with\n          | Some n ->\n              of_int n\n          | None ->\n              failwith (\"the concrete memory model requires a complete implementation sizeof INTEGER => \" ^ String_core_ctype.string_of_ctype cty)")

def serializeFloat (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.serializeFloat", by decide⟩ detail
    (memSource 143 148 (by decide) "| Basic (Floating fty) ->\n        begin match (Ocaml_implementation.get ()).sizeof_fty fty with\n          | Some n ->\n              of_int n\n          | None ->\n              failwith \"the concrete memory model requires a complete implementation sizeof FLOAT\"")

def reconstructUnknownFunction (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.reconstructUnknownFunction", by decide⟩ detail
    (memSource 1009 1014 (by decide) "(* FIXME: This is wrong. A function pointer with the same id in different files might exist. *)\n                          begin match IntMap.find_opt n funptrmap with\n                            | Some (file_dig, name) ->\n                                MVpointer (ref_ty, PV(prov, PVfunction (Symbol.Symbol (file_dig, Z.to_int n, SD_Id name))))\n                            | None ->\n                                failwith (\"unknown function pointer: \" ^ Z.to_string n)")

def reconstructUnknownStruct (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.reconstructUnknownStruct", by decide⟩ detail
    (memSource 100 100 (by decide) "match Pmap.find tag_sym tagDefs with")

def reconstructEmptyUnion (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.reconstructEmptyUnion", by decide⟩ detail
    (memSource 1078 1093 (by decide) "else (match Pmap.find tag_sym (Tags.tagDefs ()) with\n            | _, UnionDef ((first_membr_def :: _) as membrs) ->\n                let (membr_ident, (_, _, _, membr_ty)) =\n                  match IntMap.find_opt addr unionmap with\n                    | None ->\n                        first_membr_def\n                    | Some membr ->\n                        match List.find_opt (fun z -> Symbol.instance_Basic_classes_Eq_Symbol_identifier_dict.isEqual_method (fst z) membr) membrs with\n                          | None ->\n                              assert false\n                          | Some membr_def ->\n                              membr_def in\n                let (taint, mval, _ ) = self membr_ty bs1 in\n                (taint, MVunion (tag_sym, membr_ident, mval), bs2)\n            | _ ->\n                assert false)")

def reconstructMissingMember (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.reconstructMissingMember", by decide⟩ detail
    (memSource 1085 1087 (by decide) "match List.find_opt (fun z -> Symbol.instance_Basic_classes_Eq_Symbol_identifier_dict.isEqual_method (fst z) membr) membrs with\n                          | None ->\n                              assert false")

def reconstructWrongUnion (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.reconstructWrongUnion", by decide⟩ detail
    (memSource 1092 1093 (by decide) "| _ ->\n                assert false)")

def reconstructUnsized (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.reconstructUnsized", by decide⟩ detail
    (memSource 943 948 (by decide) "| Void\n      | Array (_, None)\n      | Function _\n      | FunctionNoParams _ ->\n          (* ty must have a known size *)\n          assert false")

def typeofEmptyArray (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.typeofEmptyArray", by decide⟩ detail
    (memSource 1125 1127 (by decide) "| MVarray [] ->\n          (* ill-formed value *)\n          assert false")

def casePtrvalDevice (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.casePtrvalDevice", by decide⟩ detail
    (memSource 1808 1814 (by decide) "let case_ptrval pv fnull ffun fconc =\n    match pv with\n    | PV (_, PVnull ty) -> fnull ty\n    | PV (_, PVfunction f) -> ffun (Some f)\n    | PV (Prov_none, PVconcrete (_, addr)) -> fconc None addr\n    | PV (Prov_some i, PVconcrete (_, addr)) -> fconc (Some i) addr\n    | _ -> failwith \"case_ptrval\"")

def maxIvalIncomplete (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.maxIvalIncomplete", by decide⟩ detail
    (memSource 2401 2402 (by decide) "| None ->\n          failwith \"the concrete memory model requires a complete implementation MAX\"")

def maxIvalEnum (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.maxIvalEnum", by decide⟩ detail
    (memSource 2398 2399 (by decide) "| Enum _ ->\n                assert false (* handled above *)")

def minIvalIncomplete (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.minIvalIncomplete", by decide⟩ detail
    (memSource 2430 2431 (by decide) "| None ->\n                failwith \"the concrete memory model requires a complete implementation MIN\"")

def minIvalEnum (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.minIvalEnum", by decide⟩ detail
    (memSource 2434 2435 (by decide) "| Enum _ ->\n          assert false (* handled above *)")

def concurReadIval (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.concurReadIval", by decide⟩ detail
    (memSource 2361 2362 (by decide) "let concurRead_ival ity sym =\n    failwith \"TODO: concurRead_ival\"")

def integerDiv (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.integerDiv", by decide⟩ detail
    (memSource 1967 1967 (by decide) "return (IV (Prov_none, Z.div (Z.sub addr1 addr2) (sizeof diff_ty'))) in")

def integerRemTrunc (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.integerRemTrunc", by decide⟩ detail
    (memSource 2481 2482 (by decide) "| IntRem_t ->\n          IV (combine_prov prov1 prov2, Z.integerRem_t n1 n2)")

def integerRemFloor (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.integerRemFloor", by decide⟩ detail
    (memSource 2483 2484 (by decide) "| IntRem_f ->\n          IV (combine_prov prov1 prov2, Z.integerRem_f n1 n2)")

def negativeExponent (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.negativeExponent", by decide⟩ detail
    (memSource 2485 2490 (by decide) "| IntExp ->\n          (* NOTE: this operation doesn't exists in C, but is used in the elaboration of the\n             shift operators. And for these we want the provenance of the left operand to be\n             the one that is forwarded *)\n          (* TODO: fail properly when y is too big? *)\n          IV (Prov_none, Z.pow n1 (Z.to_int n2))")

def offsetofIval (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.offsetofIval", by decide⟩ detail
    (memSource 2193 2201 (by decide) "let offsetof_ival tagDefs tag_sym memb_ident =\n    let (xs, _) = offsetsof tagDefs tag_sym in\n    let pred (ident, _, _) =\n      ident_equal ident memb_ident in\n    match List.find_opt pred xs with\n      | Some (_, _, offset) ->\n          IV (Prov_none, offset)\n      | None ->\n          failwith \"Concrete.offsetof_ival: invalid memb_ident\"")

def arrayShiftNull (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.arrayShiftNull", by decide⟩ detail
    (memSource 2214 2217 (by decide) "| PVnull _ ->\n              (* TODO: this seems to be undefined in ISO C *)\n              (* NOTE: in C++, if offset = 0, this is defined and returns a PVnull *)\n              failwith (\"TODO(pure shift a null pointer should be undefined behaviour), offset:\" ^ Z.to_string offset)")

def arrayShiftFunction (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.arrayShiftFunction", by decide⟩ detail
    (memSource 2218 2219 (by decide) "| PVfunction _ ->\n              failwith \"Concrete.array_shift_ptrval, PVfunction\"")

def memberShiftFunction (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.memberShiftFunction", by decide⟩ detail
    (memSource 2239 2240 (by decide) "| PVfunction _ ->\n          failwith \"Concrete.member_shift_ptrval, PVfunction\"")

def bytefromint (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.bytefromint", by decide⟩ detail
    (memSource 2775 2776 (by decide) "let bytefromint (IV (_, intval) as ival) =\n    assert (Z.(leq (of_int 0) intval && leq intval (of_int 255)));")

def intfrombyte (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.intfrombyte", by decide⟩ detail
    (memSource 2779 2780 (by decide) "let intfrombyte (IV (_, intval) as ival) =\n    assert (Z.(leq (of_int 0) intval && leq intval (of_int 255)));")

def deriveCap (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.deriveCap", by decide⟩ detail
    (memSource 2175 2176 (by decide) "let derive_cap _ _ _ _ : integer_value =\n    assert false (* CHERI only *)")

def capAssignValue (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.capAssignValue", by decide⟩ detail
    (memSource 2178 2179 (by decide) "let cap_assign_value _ _ _ : integer_value =\n    assert false (* CHERI only *)")

def nullCap (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.nullCap", by decide⟩ detail
    (memSource 2184 2185 (by decide) "let null_cap _ : integer_value =\n    assert false (* CHERI only *)")

def ptrTIntValue (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.ptrTIntValue", by decide⟩ detail
    (memSource 2181 2182 (by decide) "let ptr_t_int_value _ =\n    assert false (* CHERI only *)")

def intrinsicType (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.intrinsicType", by decide⟩ detail
    (memSource 2187 2188 (by decide) "let get_intrinsic_type_spec _ =\n    assert false (* CHERI only *)")

def integerEmpty (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.integerEmpty", by decide⟩ detail
    (decodeSource 18 18 (by decide) "if str.[0] = '0' then")

def characterSlash (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.characterSlash", by decide⟩ detail
    (decodeSource 166 167 (by decide) "if String.length str = 1 then\n            failwith \"decode_character_constant, invalid constant: '\\\\'\"")

def characterHexEmpty (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.characterHexEmpty", by decide⟩ detail
    (decodeSource 171 171 (by decide) "failwith \"decode_character_constant, invalid constant: '\\\\x'\"")

def characterHexInvalid (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.characterHexInvalid", by decide⟩ detail
    (decodeSource 185 185 (by decide) "failwith (\"decode_character_constant, started like an hexa constant, but failed: \" ^ str)")

def characterOctalInvalid (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.characterOctalInvalid", by decide⟩ detail
    (decodeSource 197 197 (by decide) "failwith (\"decode_character_constant, started like an octal constant, but failed: \" ^ str)")

def characterEmpty (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.characterEmpty", by decide⟩ detail
    (decodeSource 163 163 (by decide) "failwith \"decode_character_constant: empty constant\"")

def characterInvalid (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbDecode.characterInvalid", by decide⟩ detail
    (decodeSource 199 199 (by decide) "failwith (\"decode_character_constant: invalid char constant ==> \" ^ str)")

def enumMissing (detail : String) : UpstreamCrash :=
  mirror ⟨"CerberusImpl.enumMissing", by decide⟩ detail
    (implSource 144 150 (by decide) "let typeof_enum tag_sym =\n    match List.find_opt (fun (z, _) -> Symbol.symbol_compare z tag_sym = 0) !registered_enums with\n      | None ->\n          failwith (\"Ocaml_implementation.typeof_enum: '\" ^\n                    Symbol.instance_Show_Show_Symbol_sym_dict.show_method tag_sym ^ \"' was not registered\")\n      | Some (_, z) ->\n          z")

def signedEnum (detail : String) : UpstreamCrash :=
  mirror ⟨"CerberusImpl.signedEnum", by decide⟩ detail
    (implSource 95 96 (by decide) "| Enum tag_sym ->\n          assert false")

def aliasMissing (detail : String) : UpstreamCrash :=
  mirror ⟨"CerberusImpl.aliasMissing", by decide⟩ detail
    (implSource 39 44 (by decide) "| IntN_t n ->\n          Option.get (type_alias_map.intN_t_alias n)\n      | Int_leastN_t n ->\n          Option.get (type_alias_map.int_leastN_t_alias n)\n      | Int_fastN_t n ->\n          Option.get (type_alias_map.int_fastN_t_alias n)")

def sizeofBase (detail : String) : UpstreamCrash :=
  mirror ⟨"CerberusImpl.sizeofBase", by decide⟩ detail
    (implSource 190 195 (by decide) "| IntN_t _\n            | Int_leastN_t _\n            | Int_fastN_t _\n            | Intmax_t\n            | Intptr_t ->\n                assert false")

def sizeofType (detail : String) : UpstreamCrash :=
  mirror ⟨"CerberusImpl.sizeofType", by decide⟩ detail
    (implSource 197 202 (by decide) "| Enum _\n      | Wchar_t\n      | Wint_t\n      | Size_t\n      | Ptrdiff_t ->\n          assert false")

def ctzZero (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbUtils.ctzZero", by decide⟩ detail
    (gccSource 5 5 (by decide) "assert (not (equal n zero));")

def bswap16Range (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbUtils.bswap16Range", by decide⟩ detail
    (gccSource 15 15 (by decide) "assert (equal zero (logand 0xffffffffffff0000L n));")

def bswap32Range (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbUtils.bswap32Range", by decide⟩ detail
    (gccSource 22 22 (by decide) "assert (equal zero (logand 0xffffffff00000000L n));")

def bswap64Overflow (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbUtils.bswap64Overflow", by decide⟩ detail
    (gccSource 30 30 (by decide) "let n = Z.to_int64 n in") (.draft 12 (by decide))

def outerBboxEmpty (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbLocation.outerBboxEmpty", by decide⟩ detail
    (locationSource 103 106 (by decide) "let outer_bbox xs =\n  let (b0, e0) = match xs with\n    | [] ->\n        assert false")

def simpleLocationEmpty (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbLocation.simpleLocationEmpty", by decide⟩ detail
    (locationSource 489 491 (by decide) "| Loc_regions (xs, _) ->\n     let (start_p, end_p) = List.hd xs in\n     Printf.sprintf \"<%s--%s>\" (string_of_pos start_p) (string_of_pos end_p)")

def floatParse (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbFloat.floatParse", by decide⟩ detail
    (memSource 2523 2524 (by decide) "let str_fval str =\n    float_of_string str")

def floatToInt (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbFloat.floatToInt", by decide⟩ detail
    (memSource 2554 2554 (by decide) "IV (Prov_none, Z.of_float fval)")

def stepSpawnEquality (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbStepInstances.stepSpawnEquality", by decide⟩ detail
    (stepSource 110 127 (by decide) "type core_step2 =\n  | Step_ccall2 of Mem_common.thread_id * core_runM thread_state\n  | Step_with_runstate2 of runstate_step_kind * core_runM thread_state\n  | Step_tau2 of string * Core_run.core_tau_step_kind * thread_state\n  \n  | Step_action_request2 of string * Loc.t * (* set Cmm.aid * set Cmm.aid * set Cmm.aid * *)\n                            Mem_common.thread_id *\n                            bool * (* is_unseq_with_ccall *)\n                            core_runM (action_request2 thread_state)\n  \n  | Step_blocked2\n  | Step_error2 of string\n  | Step_thread_done2 of Mem_common.thread_id * Core.value\n  | Step_done2 of Core.value\n  | Step_memop_request2 of Loc.t * Mem_common.memop * list Core.value * Mem_common.thread_id * bool(* is_unseq_with_ccall *) * (Core.value -> thread_state)\n  | Step_spawn_threads2 of (list Mem_common.thread_id -> thread_state) * list thread_state (* initial states for the children *)\n  | Step_fs2 of Mem_common.thread_id * thread_state * core_runM fs_oper_or_done\n  | Step_nd2 of list thread_state")

def cheriPointerHash (detail : String) : Invariant :=
  invariant ⟨"CerbMem.cheriPointerHash", by decide⟩ detail ⟨"The concrete build has no CHERI pointer-hash implementation.", by decide⟩

def enumReader (detail : String) : Invariant :=
  invariant ⟨"CerberusImpl.enumReader", by decide⟩ detail ⟨"Reader lifting must replace every applied enum_definitions site.", by decide⟩

def normaliseEnum (detail : String) : Invariant :=
  invariant ⟨"CerberusImpl.normaliseEnum", by decide⟩ detail ⟨"Layout callers resolve enumeration definitions before normalise_aliases.", by decide⟩

def boundedInteger (detail : String) : Invariant :=
  invariant ⟨"CerbUtils.boundedInteger", by decide⟩ detail ⟨"The live stepper rejects the random builtin; this unmodelled seam must not execute.", by decide⟩

def funMapCompare (detail : String) : Invariant :=
  invariant ⟨"CerbFunMapInstances.funMapCompare", by decide⟩ detail ⟨"CerbFunMapInstances.lean: the phantom value-comparison dictionary is never called.", by decide⟩

def scanHashFuel (detail : String) : Invariant :=
  invariant ⟨"CoreParser.scanHashFuel", by decide⟩ detail ⟨"CoreParser.scanHashCollisions: initial fuel is input length + 1; each scan step consumes input.", by decide⟩

def coreImplKey (detail : String) : Invariant :=
  invariant ⟨"Main.coreImplKey", by decide⟩ detail ⟨"Main.loadCoreImpl: every parsed implementation key must decode.", by decide⟩

def tagReader (detail : String) : Invariant :=
  invariant ⟨"CerbTags.tagReader", by decide⟩ detail ⟨"Reader lifting must replace every applied tagDefs site.", by decide⟩

def stepCcallEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepCcallEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepRunstateEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepRunstateEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepTauEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepTauEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepActionEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepActionEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepMemopEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepMemopEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepFsEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepFsEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepNdEquality (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepNdEquality", by decide⟩ detail ⟨"CerbStepInstances.lean: coarse constructor-level equality guard is not an OCaml structural-comparison mirror.", by decide⟩

def stepOrdering (detail : String) : Invariant :=
  invariant ⟨"CerbStepInstances.stepOrdering", by decide⟩ detail ⟨"CerbStepInstances.lean: the same-constructor ordering fallback is not a uniform functional-value crash.", by decide⟩

def allocatorAlignment (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.allocatorAlignment", by decide⟩ detail
    (memSource 1253 1253 (by decide) "let (q,m) = quomod z align in")

def allocateRequested (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.allocateRequested", by decide⟩ detail
    (memSource 1294 1295 (by decide) "| Some addr ->\n            failwith \"TODO: cerb::with_address() is yet implemented\"")

def killDeadStatic (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.killDeadStatic", by decide⟩ detail
    (memSource 1531 1532 (by decide) "else\n                failwith \"Concrete: FREE was called on a dead allocation\"")

def shiftFunction (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.shiftFunction", by decide⟩ detail
    (memSource 2253 2254 (by decide) "| PV (_, PVfunction _) ->\n          failwith \"Concrete.eff_array_shift_ptrval, PVfunction\"")

def memcmpByte (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.memcmpByte", by decide⟩ detail
    (memSource 2658 2659 (by decide) "| _ ->\n                assert false in")

def vaListIndex (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.vaListIndex", by decide⟩ detail
    (memSource 2760 2760 (by decide) "assert (n = 0); (* not sure what happens with n <> 0 *)")

def callIntrinsic (detail : String) : UpstreamCrash :=
  mirror ⟨"CerbMem.callIntrinsic", by decide⟩ detail
    (memSource 2190 2191 (by decide) "let call_intrinsic _ _ _ =\n    assert false (* CHERI only *)")

def storeResolvedAbsent (detail : String) : Invariant :=
  invariant ⟨"CerbMem.storeResolvedAbsent", by decide⟩ detail ⟨"resolveIota's successful precondition found the allocation; resolution changes only iotaMap.", by decide⟩

def shiftSymbolicPastArm (detail : String) : Invariant :=
  invariant ⟨"CerbMem.shiftSymbolicPastArm", by decide⟩ detail ⟨"The Prov_symbolic arm of effArrayShiftPtrval must match before the concrete bounds arms.", by decide⟩

end CerbStopSites
