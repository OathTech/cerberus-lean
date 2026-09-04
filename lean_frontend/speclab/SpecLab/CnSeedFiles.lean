/-
SpecLab.CnSeedFiles — arc-15 S5: the R5 swap FILE TERMS
(differential-lane data).

Assembly follows the S1 DivModFiles pattern (itself the arc-7 T1File
pattern): pinned parsed declarations (SpecLab/CnSeedCore.lean,
generated + drift-gated) + hand-pinned funinfo metadata, `globs`
empty (block-scope arrays, S1-E4), `main := some swapMainSym`.

HONESTY NOTE (statement data): each file value is the pinned oracle
Core dump's two procs + the REACHED std.core closure — the divmod 8
(shared pinned decls, drift-gated by the S1 CoreGateTest) plus
`ctype_width` (pinned in CnSeedCore, drift-gated here). The S5 drift gate (SLUnit.SeedGateTest)
re-parses the pinned dumps, byte-compares the generated module, pins
`swapMainParamDecl` back to all four swap dumps (incl. the
out-of-trio c = (2^64-1, 0)), and runs the assembled files through
`drive` at the pinned verdicts — plus the .c twins run through BOTH
pipelines by scripts/test_speclab_seed.sh.

THE LOOKUP FAMILY HAS NO FILE TERMS: parked on the CoreParser
enum-ctype gap (registered S5 finding; see the seed plan in
SLUnit/EmitCore.lean). Its differential lanes are green without a
pinned layer.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.CnSeed
import SpecLab.CnSeedHarness
import SpecLab.CnSeedCore
import SpecLab.DivModFiles

set_option autoImplicit false

namespace SpecLab

namespace CnSeed

open SpecLab.CnSeedCore

/-! ## File assembly -/

/-- Pointer-to-unsigned-long (the target signature's parameter
type). -/
def ulongPtr : ctype := mk_ctype_pointer no_qualifiers unsigned_long

/-- The std.core closure the swap harness's evaluation reaches: the
divmod 8 plus `ctype_width` (the u64 shift bound checks — discovered
by the fail-closed unknown-function error, the S3 discipline). -/
def seedStdlib : Fmap sym (generic_fun_map_decl Unit Unit) :=
  Lem_Map.fromList
    [(DivModCore.convLoadedIntSym, DivModCore.convLoadedIntDecl),
     (DivModCore.convIntSym, DivModCore.convIntDecl),
     (DivModCore.isReprIntegerSym, DivModCore.isReprIntegerDecl),
     (DivModCore.catchExceptionalSym, DivModCore.catchExceptionalDecl),
     (DivModCore.wrapISym, DivModCore.wrapIDecl),
     (DivModCore.paramsLengthSym, DivModCore.paramsLengthDecl),
     (DivModCore.paramsLengthAuxSym, DivModCore.paramsLengthAuxDecl),
     (DivModCore.paramsNthSym, DivModCore.paramsNthDecl),
     (ctypeWidthSym, ctypeWidthDecl)]

/-- funinfo: `void swap_pair(unsigned long*)`,
`signed int main(void)` — hand-pinned to the elaborated funinfo of
the pinned fixtures, checked behaviorally by the SeedGateTest exec
checks + the differential lanes (the T1File practice). -/
def swapFuninfo : Fmap sym (CerbLocation.Loc × attributes × ctype ×
    List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(swapPairSym, (CerbLocation.Loc.unknown, Attrs [], void,
      [((none : Option sym), ulongPtr)], false, true)),
     (swapMainSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      ([] : List (Option sym × ctype)), false, true))]

/-- impl0: the ONE implementation constant the swap evaluation
reaches — `<bits_in_byte> = 8`
(runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl:3;
`ctype_width` multiplies Ivsizeof by it). FIRST pinned family with a
nonempty impl0 map; hand-pinned (the tiny literal Def), checked
behaviorally by the SeedGateTest exec checks + both differential
pipelines (the funinfo practice). -/
def seedImpl : Fmap implementation_constant (generic_impl_decl Unit) :=
  Lem_Map.fromList
    [(Characters__bits_in_byte,
      (Def (BTy_object OTy_integer)
        (Pexpr [] () (PEval (Vobject (OVinteger
          (CerbMem.integerIval (8 : Int))))))
        : generic_impl_decl Unit))]

/-- Assemble a swap file (pre-conversion form) around a main + target
pair. -/
def swapFileU (mainDecl : generic_fun_map_decl Unit Unit)
    (targetDecl : generic_fun_map_decl Unit Unit) : file Unit :=
  { main := some swapMainSym
    calling_convention0 := Normal_callconv
    tagDefs := fmapEmpty
    stdlib := seedStdlib
    impl0 := seedImpl
    globs := []
    funs := Lem_Map.fromList
      [(swapPairSym, targetDecl), (swapMainSym, mainDecl)]
    extern := fmapEmpty
    funinfo := swapFuninfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- THE PARAMETRIC swap FILE: the healthy harness family, indexed by
the sixteen wire bytes (expected[] sites are derived — the parametric
term shares the parameters through the swap permutation). -/
def swapI16File [LemFuel] (b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14
    b15 : Int) : file core_run_annotation :=
  convert_file (swapFileU
    (swapMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13
      b14 b15)
    swapPairDecl)

/-- The LOST-UPDATE PLANT file (pinned verbatim; instance a). -/
def pairSwapPlantFile [LemFuel] : file core_run_annotation :=
  convert_file (swapFileU swapMainPlantDecl swapPairPlantDecl)

/-- File from a 16-byte wire vector (junk on other lengths — the
statements own their index sets). -/
def swapFileOfBytes [LemFuel] (bs : List UInt8) : file core_run_annotation :=
  match bs.map DivMod.byteToInt with
  | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14,
     b15] =>
    swapI16File b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15
  | _ => swapI16File 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

/-- MODEL-INDEXED file (the model-∀ face — wire bytes computed by the
pure encoder; total on ALL of PairInput, the full-domain rung). -/
def swapFileOf [LemFuel] (m : PairInput) : file core_run_annotation :=
  swapFileOfBytes (encodePair m)

/-- STREAM-INDEXED file (the stream-∀ face; junk on malformed
streams — callers own validity; the R2 decode-based style). -/
def swapFileOfStream [LemFuel] (s : Stream) : file core_run_annotation :=
  match decodePair s with
  | some (m, []) => swapFileOf m
  | _ => swapFileOfBytes []

end CnSeed
end SpecLab
