/-
SpecLab.ListAppendFiles — arc-15 S3: the R3 linked-list FILE TERMS
(IntList_append; differential-lane data), including the allocation
baseline the leak-checking gate exe pins.

Assembly follows the S1/S2 pattern (arc-7 T1File lineage): pinned
parsed declarations (SpecLab/ListAppendCore.lean, generated +
drift-gated) + hand-pinned funinfo metadata, `main := some mainSym` —
with two R3 firsts: `tagDefs` NONEMPTY (`struct int_list`, the
t4_struct_member fixture precedent) and the std closure extended by the ALLOCATOR
PROXIES (malloc_proxy/free_proxy — the allocation closure; the
harness's extern malloc/free resolve to them by std.core ailname, and
the pinned dumps reference them by symbol as `Cfunction(malloc_proxy)`).

THE LEAK OBSERVABLE (design record, task item 2): the batch output
surface (`Defined {value, stdout, stderr, blocked}`) does NOT carry
allocation state — but the exec outcome itself does: `CerbND.runND`
returns the final `driver_state`, whose `layout_state :
CerbMem.MemState` carries the allocation map (`allocations :
Std.TreeMap Int Allocation`; `Kill` ERASES — CerbMem.lean kill path).
The template note's sanctioned form ("a single scalar fact about the
final state, no contents/shape vocabulary") is therefore stateable
TODAY with zero semantics-surface changes; the gate exe checks it
executably. What remains MISSING is the ORACLE-DIFFERENTIAL leg: the
OCaml driver prints no allocation census in batch mode, so the leak
check is in-Lean only, not oracle-compared (an oracle `--batch`
allocation-census switch is a priced upstream/fork filing candidate).

BASELINE HONESTY: a leak-free run's final map is NOT empty — the
driver's own ERRNO allocation (harness-independent, see
`driverBaseline`) remains. The conjunct is stated against that pinned
baseline; "leak-free" = final size equals the baseline, and the
wrong-link plant exceeds it by exactly the orphaned nodes.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.ListAppend
import SpecLab.ListAppendHarness
import SpecLab.ListAppendCore
import SpecLab.DivModFiles

set_option autoImplicit false

namespace SpecLab

namespace ListAppend

open SpecLab.ListAppendCore

/-! ## File assembly -/

/-- Pointer-to-struct-int_list (the target signature's type). -/
def intListPtr : ctype :=
  mk_ctype_pointer no_qualifiers (Ctype [] (Struct intListSym))

/-- Pointer-to-void (malloc's return / free's parameter). -/
def voidPtr : ctype := mk_ctype_pointer no_qualifiers void

/-- The `struct int_list` tag map (first nonempty `tagDefs` of the
speclab families; the t4_struct_member fixture precedent). -/
def intListTagDefs : Fmap sym (CerbLocation.Loc × tag_definition) :=
  Lem_Map.fromList
    [(intListSym, (CerbLocation.Loc.unknown, intListTagDef))]

/-- The R3 std closure: the divmod scalar closure (the SAME 8 pinned
decls, drift-gated at S1 — re-listed here because `Fmap` has no
toList) + the allocator proxies. -/
def listStdlib : Fmap sym (generic_fun_map_decl Unit Unit) :=
  Lem_Map.fromList
    [(DivModCore.convLoadedIntSym, DivModCore.convLoadedIntDecl),
     (DivModCore.convIntSym, DivModCore.convIntDecl),
     (DivModCore.isReprIntegerSym, DivModCore.isReprIntegerDecl),
     (DivModCore.catchExceptionalSym, DivModCore.catchExceptionalDecl),
     (DivModCore.wrapISym, DivModCore.wrapIDecl),
     (DivModCore.paramsLengthSym, DivModCore.paramsLengthDecl),
     (DivModCore.paramsLengthAuxSym, DivModCore.paramsLengthAuxDecl),
     (DivModCore.paramsNthSym, DivModCore.paramsNthDecl),
     (mallocProxySym, mallocProxyDecl),
     (freeProxySym, freeProxyDecl),
     (allValuesReprInSym, allValuesReprInDecl)]

/-- funinfo: `struct int_list* IntList_append(struct int_list*,
struct int_list*)`, `signed int main(void)`, and the allocator
proxies (`void* malloc(unsigned long)` / `void free(void*)` — the
harness's extern declarations, transferred to the proxy symbols by
core linking in the oracle's dump; the call protocol's
`are_compatible` checks validate these behaviorally in the gate exe +
both differential pipelines). -/
def appendFuninfo (targetSym : sym) : Fmap sym (CerbLocation.Loc ×
    attributes × ctype × List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(targetSym, (CerbLocation.Loc.unknown, Attrs [], intListPtr,
      [((none : Option sym), intListPtr), ((none : Option sym), intListPtr)],
      false, true)),
     (mallocProxySym, (CerbLocation.Loc.unknown, Attrs [], voidPtr,
      [((none : Option sym), unsigned_long)], false, true)),
     (freeProxySym, (CerbLocation.Loc.unknown, Attrs [], void,
      [((none : Option sym), voidPtr)], false, true)),
     (mainSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      ([] : List (Option sym × ctype)), false, true))]

/-- Assemble an append-family file (pre-conversion form) around a
main + target pair. -/
def appendFileU (targetSym : sym)
    (mainDecl : generic_fun_map_decl Unit Unit)
    (targetDecl : generic_fun_map_decl Unit Unit) : file Unit :=
  { main := some mainSym
    calling_convention0 := Normal_callconv
    tagDefs := intListTagDefs
    stdlib := listStdlib
    impl0 := fmapEmpty
    globs := []
    funs := Lem_Map.fromList
      [(targetSym, targetDecl), (mainSym, mainDecl)]
    extern := fmapEmpty
    funinfo := appendFuninfo targetSym
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- THE PARAMETRIC append FILE: the healthy (2,1)-length harness
family, indexed by the TWELVE element wire bytes (expected[] sites
are derived — the parametric term shares the parameters, the S2-E4
zip mechanism at 12 params / 24 sites). -/
def appendI12File (b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 : Int) :
    file core_run_annotation :=
  convert_file (appendFileU intListAppendSym
    (appendMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11)
    intListAppendDecl)

/-- The WRONG-LINK PLANT file (pinned verbatim; instance a). -/
def appendLinkPlantFile : file core_run_annotation :=
  convert_file (appendFileU intListAppendLinkPlantSym
    appendMainLinkPlantDecl intListAppendLinkPlantDecl)

/-- The WRONG-ELEMENT PLANT file (pinned verbatim; instance a). -/
def appendElemPlantFile : file core_run_annotation :=
  convert_file (appendFileU intListAppendElemPlantSym
    appendMainElemPlantDecl intListAppendElemPlantDecl)

/-- The BUILD-ONLY file (pinned verbatim; instance a) — the
builder-correctness statement's object. Its TU carries its own copy
of the target decl (different fresh numbering — the S3
symbol-numbering-coupling finding), never called. -/
def appendBuildFile : file core_run_annotation :=
  convert_file (appendFileU intListAppendBuildSym
    appendMainBuildDecl intListAppendBuildDecl)

/-- Byte-valued Int (the splice literal of a byte). -/
def byteToInt (b : UInt8) : Int := (b.toNat : Int)

/-- The twelve wire bytes of a (2,1)-length model (the parametric
file's index, computed by the pure element codec). -/
def wireBytes (m : Input) : List Int :=
  (m.xs.flatMap DivMod.encodeI32LE ++ m.ys.flatMap DivMod.encodeI32LE).map
    byteToInt

/-- MODEL-INDEXED append file (the model-∀ face; junk instance on
models outside the (2,1)-length family — statements own the shape via
their sample sets). -/
def appendFileOf (m : Input) : file core_run_annotation :=
  match m.xs, m.ys with
  | [_, _], [_] =>
    match wireBytes m with
    | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11] =>
      appendI12File b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11
    | _ => appendI12File 0 0 0 0 0 0 0 0 0 0 0 0
  | _, _ => appendI12File 0 0 0 0 0 0 0 0 0 0 0 0

/-- STREAM-INDEXED append file (the stream-∀ face): the full
two-list codec decodes the stream; junk on malformed/out-of-family
streams (callers own validity). -/
def appendFileOfStream (s : Stream) : file core_run_annotation :=
  match decodeInput s with
  | some (m, []) => appendFileOf m
  | _ => appendI12File 0 0 0 0 0 0 0 0 0 0 0 0

/-- The driver's own baseline, DISCOVERED EXECUTABLY at S3 and pinned
here: exactly 1 allocation — the driver's ERRNO object (Driver.lean
drive: "allocating and initialising errno", never freed by design).
The argv allocations do NOT appear for these harnesses: `main(void)`
has no (argc, argv) parameters, so `prepare_main_args`'s allocation
arm never fires. The gate exe (SLUnit.ListGateTest) re-checks this
number on every run — drift here means the driver's startup footprint
changed. -/
def driverBaseline : Nat := 1

end ListAppend
end SpecLab
