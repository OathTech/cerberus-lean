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
import RelSem.Threaded
import SpecLab.DivMod
import SpecLab.DivModHarness
import SpecLab.DivModCore

set_option autoImplicit false

-- Arc-18 C4 (R6 homing): the threaded statement vocabulary lives
-- SEMANTICS-SIDE (relsemcore …/Threaded.lean — the exec-facing
-- RelSemCore lib of the root package, NOT the proof package). This
-- `open` brings exactly the three homed statement names; the
-- statement gates (scripts/check_speclab_statements.sh + the in-build
-- SpecLabAudit walk) allowlist exactly these — any other proof-layer-rooted
-- name remains banned. Provenance: the blessed arc-18 charter C4 +
-- contracts §6 R6 ([USER 2026-08-25] charter blessing).
open RelSem.Cerb (HarnessRunsToThr specifiedInt initial_driver_state_threaded)

namespace SpecLab

/-! (2026-08-27 KILL-LIST EXECUTION, operator-ratified: the finite
    sample-∀ / concrete statement Prop defs of this rung — the
    `*Sample*`/`*Plant*Claim`/`*Leak*` family with their pinned
    sample sets and the sample bridges — are DELETED: quantification
    by membership in a closed literal list is enumeration by
    construction, and their planned proof (the exec-equation
    campaign) is CANCELLED. The pure models, codec laws, the
    `model_forall_iff_stream_forall` bridges, the `fileOfStream_
    encode` program-term equalities, the family-∀ TARGET statements,
    and the file terms (test-lane data) all STAY. Record:
    lean_frontend/docs/2026-08-27_kill-list-execution.md.) -/
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

/-! ## The R1 exec statements (fuel opsem only)

    THREADED at arc-18 C4: the exec headline shape is the homed
    whole-program face `HarnessRunsToThr`
    (relsemcore …/Threaded.lean — the ambient `HarnessRunsTo`
    that lived here, arc-15 S1..arc-18 C3b, is REPLACED, not aliased:
    an alias would re-import the ambient initial state's
    `runEffectful` cone, which this threading removes). `specifiedInt`
    moved with it (one definition, one home). Every statement takes
    the fresh-symbol supply SEED as an explicit parameter — the
    ambient originals are the images at the ambient draw
    (`initial_driver_state_eq_threaded_ambient`). The statements
    deliberately do NOT ∀-quantify the seed: unrestricted ∀-seed
    claims are false for some program shapes (the arc-16 S4 T4
    hash-collision finding), and these statements' healthy faces are
    executable-validated, not yet kernel-proved — ∀-seed closure
    arrives only with proof (the family-∀ upgrades). -/

/-- THE R1 FAMILY-∀ STATEMENT (arc-18 C4 — the registered TARGET
shape; ∀-seed AND ∀ over the full well-formed i8 model domain, not
the pinned sample set). HONESTY LABEL: UNPROVED — the proof is the
whole-program drive-walk campaign, parked at the ground-mode
materialization frontier (the C4 record §3); the sample statements
remain the executable-validated faces meanwhile. Note the ∀-seed here
is part of the TARGET (a proof must establish it or weaken to a
guarded face per the T4-apartness pattern). -/
def DivModI8FamilyStatement : Prop :=
  ∀ (seed : Nat) (m : Input), WfI8 m →
    HarnessRunsToThr seed (divmodI8FileOf m) 0

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

end DivMod
end SpecLab
