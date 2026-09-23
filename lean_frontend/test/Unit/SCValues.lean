import CerbMem
import CerbSCValues
import Sc_reference

open Lem_Basic_classes

private def sint : ctype := .Ctype [] (.Basic (.Integer (.Signed .Int_)))
private def uint : ctype := .Ctype [] (.Basic (.Integer (.Unsigned .Int_)))
private def fty : floatingType := .RealFloating .Double
private def tag : sym := .Symbol "sc-value-control" 1 .SD_None
private def member : identifier := .Identifier (CerbLocation.other "SC value control") "member"
private def integer (n : Int) : CerbMem.MemValue := .MVinteger (.Signed .Int_) (.IV .Prov_none n)
private def floating (bits : UInt64) : CerbMem.MemValue := .MVfloating fty (.ofBits bits)
private def key := CerbMem.scValueKeyConcrete
private def pointer (p : CerbMem.PointerValue) : CerbMem.MemValue := .MVpointer sint p
private def set {α : Type} [SetType α] (xs : List α) : Pset α :=
  setFromListBy setElemCompare xs

private def rfAccepts (write read : sc_value_key) : Bool :=
  let (wi, table) := sc_intern_value write []
  let (ri, _) := sc_intern_value read table
  let location := SCRef_Loc_hol 0
  let thread := SCRef_Tid_hol 0
  let w := SCRef_Store 10 thread .SCRef_NA location (.SCRef_Cvalue_hol wi)
  let r := SCRef_Load 11 thread .SCRef_NA location (.SCRef_Cvalue_hol ri)
  let xo : sc_ref_pre_execution :=
    ⟨set [w,r], set [thread], fun _ => .SCRef_Non_Atomic, set [(w,r)], set [], set []⟩
  let xw : sc_ref_execution_witness :=
    ⟨set [(w,r)], set [], set [], set [], set []⟩
  sc_ref_well_formed_rf (xo,xw,[])

private def checks : List (String × Bool) := Id.run do
  let patterns : List UInt64 := [0, 0x8000000000000000, 0x3ff0000000000000, 0xbff0000000000000,
    0x7ff0000000000000, 0xfff0000000000000,
    0x7ff8000000000001, 0x7ff8000000000002, 0xfff8000000000001,
    0x7ff0000000000001, 0x7ff0000000000002, 0xfff0000000000001]
  let floats := patterns.map fun bits => (bits,key (floating bits))
  let nan := key (floating 0x7ff8000000000001)
  let otherNan := key (floating 0x7ff8000000000002)
  let zero := key (floating 0)
  let negativeZero := key (floating 0x8000000000000000)
  let p1 : CerbMem.PointerValue := .PV (.Prov_some 1) (.PVconcrete none 4096)
  let p2 : CerbMem.PointerValue := .PV (.Prov_some 2) (.PVconcrete none 4096)
  let nested : CerbMem.MemValue := .MVarray [
    .MVstruct tag [(member,sint,.MVunion tag member (floating 0x7ff8000000000001))], integer 7]
  let expected := SC_array_value [
    SC_struct_value tag [(member,sint,SC_union_value tag member nan)], key (integer 7)]
  let (token,table) := sc_intern_value nan []
  let (other,extended) := sc_intern_value otherNan table
  let (again,same) := sc_intern_value nan extended
  let (reverse0,reverse) := sc_intern_value otherNan []
  let (reverse1,_) := sc_intern_value nan reverse
  let annotated : ctype := .Ctype [.Auid "preserve-type-metadata"] (.Basic (.Integer (.Signed .Int_)))
  let located : identifier := .Identifier (CerbLocation.other "different source location") "member"
  let described : sym := .Symbol "sc-value-control" 1 (.SD_Id "different description")
  let metadataPairs : List (sc_value_key × sc_value_key) := [
    (key (.MVunspecified sint),key (.MVunspecified annotated)),
    (SC_pointer_value sint (SC_no_provenance,SC_function_pointer tag),
      SC_pointer_value sint (SC_no_provenance,SC_function_pointer described)),
    (SC_union_value tag member nan,SC_union_value tag located nan),
    (SC_pointer_value sint (SC_storage_provenance 1,SC_concrete_pointer none 4096),
      SC_pointer_value sint (SC_storage_provenance 1,SC_concrete_pointer (some member) 4096))]
  return [
    ("floating conversion retains all twelve exact bit words",
      floats.all fun (bits,k) => k == SC_floating_value fty bits.toInt64.toInt),
    ("floating logical equality agrees with all 144 bit comparisons",
      floats.all fun (a,ka) => floats.all fun (b,kb) => (ka == kb) == (a == b)),
    ("reference RF accepts identical NaN bit words", rfAccepts nan nan),
    ("reference RF rejects different NaN payload tokens", !(rfAccepts nan otherNan)),
    ("reference RF distinguishes opposite signed zero tokens", !(rfAccepts zero negativeZero)),
    ("reference RF accepts identical finite tokens",
      let finite := key (floating 0x3ff0000000000000); rfAccepts finite finite),
    ("integer key retains signed type and magnitude",
      key (integer (-7)) == SC_integer_value (.Signed .Int_) SC_no_provenance (-7)),
    ("equal integer numbers with different view types stay distinguishable",
      key (integer 7) != key (.MVinteger (.Unsigned .Int_) (.IV .Prov_none 7))),
    ("equal numeric pointer addresses retain distinct storage provenance", key (pointer p1) != key (pointer p2)),
    ("pointer key retains reference type", key (pointer p1) != key (.MVpointer uint p1)),
    ("null pointer retains its base type",
      key (pointer (.PV .Prov_none (.PVnull sint))) != key (pointer (.PV .Prov_none (.PVnull uint)))),
    ("function pointer identity is retained",
      key (pointer (.PV .Prov_none (.PVfunction tag))) ==
        SC_pointer_value sint (SC_no_provenance,SC_function_pointer tag)),
    ("unspecified type remains distinguishable", key (.MVunspecified sint) != key (.MVunspecified uint)),
    ("nested aggregate conversion retains tags members types and payloads", key nested == expected),
    ("key comparison retains type annotations symbol descriptions member locations and pointer tags",
      metadataPairs.all fun (a,b) => a != b),
    ("interner preserves all four metadata distinctions",
      metadataPairs.all fun (a,b) =>
        let (first,table) := sc_intern_value a []
        let (second,_) := sc_intern_value b table
        first != second),
    ("interning reuses an old token without changing the table",
      token == 0 && other == 1 && again == token && same == extended && same.length == 2),
    ("token numbering is candidate local rather than a C value",
      reverse0 == token && reverse1 == other && nan != otherNan)]

def main : IO Unit := do
  for (label,good) in checks do
    IO.println s!"{label}: {good}"
    unless good do throw (IO.userError label)
