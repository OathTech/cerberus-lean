/-
SpecLab.ListAppendFiles — arc-15 S3: the R3 linked-list FILE TERMS and
the exec-level STATEMENTS (IntList_append), including THE LEAK
CONJUNCT (live this rung).

Assembly follows the S1/S2 pattern (arc-7 T1File lineage): pinned
parsed declarations (SpecLab/ListAppendCore.lean, generated +
drift-gated) + hand-pinned funinfo metadata, `main := some mainSym` —
with two R3 firsts: `tagDefs` NONEMPTY (`struct int_list`, the T4
slate precedent) and the std closure extended by the ALLOCATOR
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
TODAY with zero semantics-surface changes: `HarnessFinalAllocs f n`
below. What remains MISSING is the ORACLE-DIFFERENTIAL leg: the OCaml
driver prints no allocation census in batch mode, so the leak
conjunct is checked in-Lean (gate exe, executable) and stated
in-logic, but not oracle-compared — priced note in the S3 record
(an oracle `--batch` allocation-census switch, est. S, upstream/fork
filing candidate).

BASELINE HONESTY: a leak-free run's final map is NOT empty — the
driver's own ERRNO allocation (harness-independent, see
`driverBaseline`) remains. The conjunct is stated against that pinned
baseline; "leak-free" = final size equals the baseline, and the
wrong-link plant exceeds it by exactly `linkPlantLeaked` (the
orphaned nodes).

STATEMENT DISCIPLINE: statement surface (gate-scanned) — fuel-opsem
vocabulary only.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.ListAppend
import SpecLab.ListAppendHarness
import SpecLab.ListAppendCore
import RelSem.Threaded
import SpecLab.DivModFiles

set_option autoImplicit false

-- Arc-18 C4 (R6 homing): the homed threaded statement vocabulary —
-- exactly these names are gate-allowlisted (see SpecLab/DivModFiles.lean).
open RelSem.Cerb (HarnessRunsToThr specifiedInt initial_driver_state_threaded)


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
speclab families; the T4 slate precedent). -/
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

/-! ## The R3 exec statements (fuel opsem only; `HarnessRunsTo` is
    the R1 statement shape, reused verbatim from SpecLab.DivModFiles) -/

/-- The R3 sample set (finite explicit quantification — LABEL: four
concrete (2,1)-length models, not the family; the fixed-shape
family-∀ rides the parametric term as the priced follow-on). Wire
bytes: a = 1..12, b = 101..112, d = 201..212 (both maxima of each
byte's sign bit exercised), c = out-of-trio boundary bit patterns
(all-zeros, all-ones = -1, INT_MIN). -/
def sampleSet : List Input :=
  [⟨[67305985, 134678021], [202050057]⟩,
   ⟨[1751606885, 1818978921], [1886350957]⟩,
   ⟨[-859059511, -791687475], [-724315439]⟩,
   ⟨[0, -1], [-2147483648]⟩]

/-- THE R3 MODEL-∀ STATEMENT (finite sample form): every healthy
pinned instance runs to verdict 0 — the post-state list read back
through the walker equals `xs ++ ys` (the CN `L3 == append(L1, L2)`,
observed), with the frame content checked byte-for-byte through the
same observation. -/
def AppendSampleStatement (seed : Nat) : Prop :=
  ∀ m ∈ sampleSet, HarnessRunsToThr seed (appendFileOf m) 0

/-- The sample streams (full two-list codec). -/
def sampleStreams : List Stream := sampleSet.map encodeInput

/-- THE R3 STREAM-∀ STATEMENT (finite sample form). -/
def AppendSampleStreamStatement (seed : Nat) : Prop :=
  ∀ s ∈ sampleStreams, HarnessRunsToThr seed (appendFileOfStream s) 0

/-- THE BUILDER-CORRECTNESS STATEMENT (pinned instance): the
build-only harness — builder then walker, NO call — runs to verdict
0, i.e. the heap structure the builder constructs reads back as
exactly the encoded model (`expected = choices`). The pure mirror of
what the builder constructs is `decodeInput` itself (the
free-generator reading); this statement is the exec-level face of
that correspondence. Proof parked with the exec-equation campaign
(S1-P1); the gate exe checks it executably. -/
def BuildOnlyStatement (seed : Nat) : Prop :=
  HarnessRunsToThr seed appendBuildFile 0

/-- The wrong-link plant's healthy-shaped claim — refuted by
`HarnessRunsTo appendLinkPlantFile 255` (structural breaks land in
the length arm). -/
def AppendLinkPlantHealthyClaim (seed : Nat) : Prop :=
  HarnessRunsToThr seed appendLinkPlantFile 0

/-- The wrong-element plant's healthy-shaped claim — refuted by
`HarnessRunsTo appendElemPlantFile 3` (element 0's low wire byte). -/
def AppendElemPlantHealthyClaim (seed : Nat) : Prop :=
  HarnessRunsToThr seed appendElemPlantFile 0

/-! ## THE LEAK CONJUNCT (exec-level, live this rung) -/

/-- Final-allocation-count observable: every outcome of the
production runner leaves exactly `n` allocations in the final
memory state's allocation map. A single scalar fact about the final
state — no contents/shape vocabulary (the template note's sanctioned
leak form). -/
def HarnessFinalAllocs (seed : Nat) (f : file core_run_annotation)
    (n : Nat) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (drive f.tagDefs false f ["cmdname"])
        (initial_driver_state_threaded seed f CerbFS.fs_initial_state) →
    st'.layout_state.allocations.size = n

/-- The driver's own baseline, DISCOVERED EXECUTABLY at S3 and pinned
here: exactly 1 allocation — the driver's ERRNO object (Driver.lean
drive: "allocating and initialising errno", never freed by design).
The argv allocations do NOT appear for these harnesses: `main(void)`
has no (argc, argv) parameters, so `prepare_main_args`'s allocation
arm never fires. The gate exe (SLUnit.ListGateTest) re-checks this
number on every run — drift here means the driver's startup footprint
changed. -/
def driverBaseline : Nat := 1

/-- THE R3 LEAK STATEMENT (finite sample form): after teardown, every
healthy pinned instance's final allocation map is exactly the driver
baseline — the harness owns no heap; interpreter-only leak-freedom
(the [USER 2026-08-22] teardown conjunct, live). -/
def AppendSampleLeakStatement (seed : Nat) : Prop :=
  ∀ m ∈ sampleSet, HarnessFinalAllocs seed (appendFileOf m) driverBaseline

/-- The build-only instance's leak conjunct. -/
def BuildOnlyLeakStatement (seed : Nat) : Prop :=
  HarnessFinalAllocs seed appendBuildFile driverBaseline

/-- The wrong-link plant's leak face — the orphaned xs tail (1 node
at the pinned instance) survives teardown: final size = baseline +
1. Stating the EXACT leaked count (not mere disequality) keeps the
observable differential-grade. -/
def LinkPlantLeakClaim (seed : Nat) : Prop :=
  HarnessFinalAllocs seed appendLinkPlantFile (driverBaseline + 1)

/-! ## The file-level bridge (kernel-checked): the stream face and
    the model face build THE SAME program — through the full two-list
    codec -/

/-- On (2,1)-length in-range models, the stream-indexed file at the
encoded stream IS the model-indexed file. -/
theorem appendFileOfStream_encode (m : Input) (h : Wf m) :
    appendFileOfStream (encodeInput m) = appendFileOf m := by
  unfold appendFileOfStream
  rw [show encodeInput m = encodeInput m ++ [] by simp,
    decode_encode_input m h []]

/-- THE R3 SAMPLE BRIDGE (kernel-checked): the model-∀ and stream-∀
sample statements are interderivable. -/
theorem append_sample_model_iff_stream (seed : Nat) :
    AppendSampleStatement seed ↔ AppendSampleStreamStatement seed := by
  constructor
  · intro hm s hs
    unfold sampleStreams at hs
    obtain ⟨m, hmem, rfl⟩ := List.mem_map.mp hs
    have hwf : Wf m := by
      simp only [sampleSet, List.mem_cons, List.not_mem_nil,
        or_false] at hmem
      rcases hmem with rfl | rfl | rfl | rfl <;> decide
    rw [appendFileOfStream_encode m hwf]
    exact hm m hmem
  · intro hs m hm
    have hwf : Wf m := by
      simp only [sampleSet, List.mem_cons, List.not_mem_nil,
        or_false] at hm
      rcases hm with rfl | rfl | rfl | rfl <;> decide
    have := hs (encodeInput m)
      (List.mem_map.mpr ⟨m, hm, rfl⟩)
    rwa [appendFileOfStream_encode m hwf] at this

end ListAppend
end SpecLab
