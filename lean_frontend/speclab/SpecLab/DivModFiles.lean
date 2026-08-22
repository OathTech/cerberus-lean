/-
SpecLab.DivModFiles — arc-15 S1: the divmod i8 kernel-instance FILE
TERMS and the R1 exec-level STATEMENTS.

Assembly follows the arc-7 T1File pattern (the relsem package's
T1File module, attributed): pinned parsed declarations (SpecLab/DivModCore.lean,
generated + drift-gated) + hand-pinned funinfo metadata, `globs`
empty (the kernel-instance template deliberately uses block-scope
arrays), `main := some mainSym` — the file the generated `drive`
consumes.

HONESTY NOTE (statement data, mirroring T1File's): each file value is
the pinned oracle Core dump's three procs + the REACHED std.core
closure, not the whole linked pipeline file. The drift gate
(Unit.CoreGateTest) re-parses the pinned dumps, byte-compares the
generated module, pins `mainParamDecl` back to all four dumps, and
runs the assembled files through `drive` at the pinned verdicts
(0/0/0/0 healthy, 1 plant) — plus the .c twins run through BOTH
pipelines by scripts/test_speclab_divmod.sh.

STATEMENT DISCIPLINE: this file is statement surface (gate-scanned).
Everything below is fuel-opsem vocabulary only: the generated `drive`
+ `CerbND.runND` + pinned first-order data. No relational/proof-layer
names.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.DivMod
import SpecLab.DivModHarness
import SpecLab.DivModCore

set_option autoImplicit false

namespace SpecLab
namespace DivMod

open SpecLab.DivModCore

/-! ## File assembly -/

/-- The std.core closure the harness's evaluation reaches. -/
def divmodStdlib : Fmap sym (generic_fun_map_decl Unit Unit) :=
  Lem_Map.fromList
    [(convLoadedIntSym, convLoadedIntDecl),
     (convIntSym, convIntDecl),
     (isReprIntegerSym, isReprIntegerDecl),
     (catchExceptionalSym, catchExceptionalDecl),
     (wrapISym, wrapIDecl),
     (paramsLengthSym, paramsLengthDecl),
     (paramsLengthAuxSym, paramsLengthAuxDecl),
     (paramsNthSym, paramsNthDecl)]

/-- funinfo: `signed int division(signed int, signed int)` (likewise
`mod`), `signed int main(void)` — hand-pinned to the elaborated
funinfo of the pinned fixtures, checked behaviorally by the
CoreGateTest exec checks + the differential lanes (the T1File
practice). -/
def divmodFuninfo : Fmap sym (CerbLocation.Loc × attributes × ctype ×
    List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(divisionSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      [((none : Option sym), signed_int), ((none : Option sym), signed_int)],
      false, true)),
     (modFnSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      [((none : Option sym), signed_int), ((none : Option sym), signed_int)],
      false, true)),
     (mainSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      ([] : List (Option sym × ctype)), false, true))]

/-- Assemble a divmod i8 file (pre-conversion form) around a main. -/
def divmodI8FileU (mainDecl : generic_fun_map_decl Unit Unit)
    (divDecl : generic_fun_map_decl Unit Unit)
    (modDecl : generic_fun_map_decl Unit Unit) : file Unit :=
  { main := some mainSym
    calling_convention0 := Normal_callconv
    tagDefs := fmapEmpty
    stdlib := divmodStdlib
    impl0 := fmapEmpty
    globs := []
    funs := Lem_Map.fromList
      [(divisionSym, divDecl), (modFnSym, modDecl), (mainSym, mainDecl)]
    extern := fmapEmpty
    funinfo := divmodFuninfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- THE PARAMETRIC KERNEL-INSTANCE FILE: the healthy divmod harness
family, indexed by the six spliced byte literals. -/
def divmodI8File (c0 c1 e0 e1 e2 e3 : Int) : file core_run_annotation :=
  convert_file
    (divmodI8FileU (mainParamDecl c0 c1 e0 e1 e2 e3) divisionDecl modFnDecl)

/-- The wrong-operator PLANT file (pinned verbatim; bytes (7,2)). -/
def divmodI8PlantFile : file core_run_annotation :=
  convert_file (divmodI8FileU mainPlantDecl divisionPlantDecl modFnPlantDecl)

/-- Byte-valued Int (the splice literal of a byte). -/
def byteToInt (b : UInt8) : Int := (b.toNat : Int)

/-- MODEL-INDEXED file: the healthy instance for a model input (the
model-∀ face — bytes computed by the pure encoders, expected by the
pure `modelFn`). -/
def divmodI8FileOf (m : Input) : file core_run_annotation :=
  divmodI8File
    (byteToInt (toByteI8 m.x)) (byteToInt (toByteI8 m.y))
    (byteToInt (i16b0 (modelDiv m))) (byteToInt (i16b1 (modelDiv m)))
    (byteToInt (i16b0 (modelMod m))) (byteToInt (i16b1 (modelMod m)))

/-- The expected observation of a raw i8 stream (empty on invalid —
callers own validity). -/
def expectedOfStreamI8 (s : Stream) : Stream :=
  match decodeInputI8 s with
  | some (m, []) => expectedBytesI8 m
  | _ => []

/-- STREAM-INDEXED file: the stream-∀ face. The fallback arm is junk
for malformed streams (callers own validity — mirroring the codec
side conditions). -/
def divmodI8FileOfStream (s : Stream) : file core_run_annotation :=
  match s, expectedOfStreamI8 s with
  | [c0, c1], [e0, e1, e2, e3] =>
    divmodI8File (byteToInt c0) (byteToInt c1)
      (byteToInt e0) (byteToInt e1) (byteToInt e2) (byteToInt e3)
  | _, _ => divmodI8File 0 1 0 0 0 0

/-! ## The R1 exec statements (fuel opsem only) -/

/-- A `Specified` integer driver value (local spelling — generated
vocabulary only). -/
def specifiedInt (n : Int) : value :=
  Vloaded (LVspecified (OVinteger (CerbMem.integerIval n)))

/-- THE EXEC HEADLINE SHAPE: every outcome the production runner
enumerates for the driver run of `f` (the Main.lean entry: `drive`
with the default `["cmdname"]` args on the default filesystem) is
`Active` with the given `Specified` verdict. -/
def HarnessRunsTo (f : file core_run_annotation) (verdict : Int) : Prop :=
  ∀ (out : nd_status driver_result driver_error driver_state)
    (tr : List String) (st' : driver_state),
    (out, tr, st') ∈
      CerbND.runND (drive f.tagDefs false f ["cmdname"])
        (initial_driver_state f CerbFS.fs_initial_state) →
    ∃ r : driver_result, out = Active r ∧
      r.dres_core_value = specifiedInt verdict

/-- The R1 sample set (the finite explicit set the S1 kernel
statements quantify over — LABEL: this is quantification over FOUR
concrete streams, not the i8 family; the family-∀ is the priced
follow-on). Includes the i16-edge (-128, -1) (quotient 128 needs the
second byte). -/
def sampleSet : List Input :=
  [⟨7, 2⟩, ⟨-5, 3⟩, ⟨-6, 3⟩, ⟨-128, -1⟩]

/-- THE R1 MODEL-∀ STATEMENT (finite sample form): for every model
input in the explicit sample set, the healthy harness instance runs
to verdict 0. -/
def DivModI8SampleStatement : Prop :=
  ∀ m ∈ sampleSet, HarnessRunsTo (divmodI8FileOf m) 0

/-- The sample streams (the stream-∀ face's index set). -/
def sampleStreams : List Stream := sampleSet.map encodeInputI8

/-- THE R1 STREAM-∀ STATEMENT (finite sample form): for every choice
stream in the explicit sample-stream set, the harness instance built
FROM THE STREAM runs to verdict 0. -/
def DivModI8SampleStreamStatement : Prop :=
  ∀ s ∈ sampleStreams, HarnessRunsTo (divmodI8FileOfStream s) 0

/-- The plant's healthy-shaped claim — the statement the plant must
REFUTE (its refutation face is `HarnessRunsTo divmodI8PlantFile 1`:
the mismatch-index comparator names the diverging byte). -/
def DivModI8PlantHealthyClaim : Prop :=
  HarnessRunsTo divmodI8PlantFile 0

/-! ## The file-level bridge (kernel-checked): the stream face and
    the model face build THE SAME program -/

/-- On well-formed inputs, the stream-indexed file at the encoded
stream IS the model-indexed file (`decode ∘ encode = id` at the file
level — the i8 analogue of `model_forall_iff_stream_forall`'s
load-bearing step). -/
theorem fileOfStream_encode (m : Input) (h : WfI8 m) :
    divmodI8FileOfStream (encodeInputI8 m) = divmodI8FileOf m := by
  obtain ⟨hx1, hx2, hy1, hy2, hy0⟩ := h
  simp only [divmodI8FileOfStream, encodeInputI8, expectedOfStreamI8,
    decodeInputI8, ofByteI8_toByteI8 m.x hx1 hx2,
    ofByteI8_toByteI8 m.y hy1 hy2, expectedBytesI8, toBytesI16,
    List.cons_append, List.nil_append, divmodI8FileOf]

/-- THE R1 SAMPLE BRIDGE (kernel-checked): the model-∀ and stream-∀
sample statements are interderivable. -/
theorem sample_model_iff_stream :
    DivModI8SampleStatement ↔ DivModI8SampleStreamStatement := by
  constructor
  · intro hm s hs
    unfold sampleStreams at hs
    obtain ⟨m, hmem, rfl⟩ := List.mem_map.mp hs
    have hwf : WfI8 m := by
      simp only [sampleSet, List.mem_cons, List.not_mem_nil,
        or_false] at hmem
      rcases hmem with rfl | rfl | rfl | rfl <;> decide
    rw [fileOfStream_encode m hwf]
    exact hm m hmem
  · intro hs m hm
    have hwf : WfI8 m := by
      simp only [sampleSet, List.mem_cons, List.not_mem_nil,
        or_false] at hm
      rcases hm with rfl | rfl | rfl | rfl <;> decide
    have := hs (encodeInputI8 m)
      (List.mem_map.mpr ⟨m, hm, rfl⟩)
    rwa [fileOfStream_encode m hwf] at this

end DivMod
end SpecLab
