/-
SpecLab.DivModFiles — arc-15 S1: the divmod i8 kernel-instance FILE
TERMS (differential-lane data).

Assembly follows the arc-7 T1File pattern (the parked reasoning-era
package's T1File module — tag park/reasoning-era-20260831 — attributed):
pinned parsed declarations (SpecLab/DivModCore.lean,
generated + drift-gated) + hand-pinned funinfo metadata, `globs`
empty (the kernel-instance template deliberately uses block-scope
arrays), `main := some mainSym` — the file the generated `drive`
consumes.

HONESTY NOTE (fixture data, mirroring T1File's): each file value is
the pinned oracle Core dump's three procs + the REACHED std.core
closure, not the whole linked pipeline file. The drift gate
(Unit.CoreGateTest) re-parses the pinned dumps, byte-compares the
generated module, pins `mainParamDecl` back to all four dumps, and
runs the assembled files through `drive` at the pinned verdicts
(0/0/0/0 healthy, 1 plant) — plus the .c twins run through BOTH
pipelines by scripts/test_speclab_divmod.sh.
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

end DivMod
end SpecLab
