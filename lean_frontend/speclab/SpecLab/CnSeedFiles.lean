/-
SpecLab.CnSeedFiles — arc-15 S5: the R5 swap FILE TERMS and the
exec-level STATEMENTS.

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

STATEMENT DISCIPLINE: statement surface (gate-scanned) — fuel-opsem
vocabulary only.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.CnSeed
import SpecLab.CnSeedHarness
import SpecLab.CnSeedCore
import RelSem.Threaded
import SpecLab.DivModFiles

set_option autoImplicit false

-- Arc-18 C4 (R6 homing): the homed threaded statement vocabulary —
-- exactly these names are gate-allowlisted (see SpecLab/DivModFiles.lean).
open RelSem.Cerb (HarnessRunsToThr specifiedInt initial_driver_state_threaded)


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
def swapI16File (b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14
    b15 : Int) : file core_run_annotation :=
  convert_file (swapFileU
    (swapMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13
      b14 b15)
    swapPairDecl)

/-- The LOST-UPDATE PLANT file (pinned verbatim; instance a). -/
def pairSwapPlantFile : file core_run_annotation :=
  convert_file (swapFileU swapMainPlantDecl swapPairPlantDecl)

/-- File from a 16-byte wire vector (junk on other lengths — the
statements own their index sets). -/
def swapFileOfBytes (bs : List UInt8) : file core_run_annotation :=
  match bs.map DivMod.byteToInt with
  | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13, b14,
     b15] =>
    swapI16File b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14 b15
  | _ => swapI16File 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

/-- MODEL-INDEXED file (the model-∀ face — wire bytes computed by the
pure encoder; total on ALL of PairInput, the full-domain rung). -/
def swapFileOf (m : PairInput) : file core_run_annotation :=
  swapFileOfBytes (encodePair m)

/-- STREAM-INDEXED file (the stream-∀ face; junk on malformed
streams — callers own validity; the R2 decode-based style). -/
def swapFileOfStream (s : Stream) : file core_run_annotation :=
  match decodePair s with
  | some (m, []) => swapFileOf m
  | _ => swapFileOfBytes []

/-! ## The R5 exec statements (fuel opsem only; `HarnessRunsTo` is
    the R1 statement shape, reused verbatim) -/

/-- The R5 swap sample set (finite explicit quantification — LABEL:
four concrete pairs, not the family; the family-∀ (256^16 instances
via the parametric term) is the exec campaign's registered endpoint).
a/b/d = wire bytes 1..16 / 101..116 / 201..216; c = the out-of-trio
boundary pair (2^64−1, 0). -/
def swapSampleSet : List PairInput :=
  [⟨578437695752307201, 1157159078456920585⟩,
   ⟨7812454979559974501, 8391176362264587885⟩,
   ⟨15046472263367641801, 15625193646072255185⟩,
   ⟨18446744073709551615, 0⟩]

/-- THE R5 swap MODEL-∀ STATEMENT (finite sample form): every healthy
pinned instance runs to verdict 0 — the post-call pair reads back as
the swapped input, bytes for bytes (the CN ensures, checked). -/
def SwapSampleStatement (seed : Nat) : Prop :=
  ∀ m ∈ swapSampleSet, HarnessRunsToThr seed (swapFileOf m) 0

/-- The sample streams (full u64-pair codec). -/
def swapSampleStreams : List Stream := swapSampleSet.map encodePair

/-- THE R5 swap STREAM-∀ STATEMENT (finite sample form). -/
def SwapSampleStreamStatement (seed : Nat) : Prop :=
  ∀ s ∈ swapSampleStreams, HarnessRunsToThr seed (swapFileOfStream s) 0

/-- The swap plant's healthy-shaped claim — refuted by
`HarnessRunsTo pairSwapPlantFile 9` (the mismatch-index comparator
naming post-state cell 1's low byte: the lost update). -/
def SwapPlantHealthyClaim (seed : Nat) : Prop :=
  HarnessRunsToThr seed pairSwapPlantFile 0

/-- THE R5 FAMILY-∀ STATEMENT (arc-18 C4 — the registered TARGET
shape; ∀-seed AND the FULL u64-pair domain — the R5 model is Wf-free,
the S5 record's full-domain bridge). HONESTY LABEL: UNPROVED — proof
parked with the whole-program drive-walk campaign (the C4 record §4);
the sample statement remains the executable-validated face. -/
def SwapFamilyStatement : Prop :=
  ∀ (seed : Nat) (m : PairInput),
    HarnessRunsToThr seed (swapFileOf m) 0

/-- The family-∀ target yields the sample statement at every seed
(kernel-checked — the anti-vacuity link between target and
evidence). -/
theorem swap_sample_of_family (seed : Nat)
    (h : SwapFamilyStatement) : SwapSampleStatement seed :=
  fun m _ => h seed m

/-! ## The file-level bridge (kernel-checked): the stream face and
    the model face build THE SAME program — Wf-FREE at this rung
    (the full-domain novelty: no side conditions anywhere) -/

/-- The stream-indexed file at any encoded pair IS the model-indexed
file — no hypotheses (`decode ∘ encode = id` is unconditional for
the u64-pair codec). -/
theorem swapFileOfStream_encode (m : PairInput) :
    swapFileOfStream (encodePair m) = swapFileOf m := by
  unfold swapFileOfStream
  rw [show encodePair m = encodePair m ++ [] by simp,
    decode_encode_pair m []]

/-- THE R5 SAMPLE BRIDGE (kernel-checked): the model-∀ and stream-∀
sample statements are interderivable — with no per-member Wf lemmas
at all (contrast the S1/S2 bridges). -/
theorem swap_sample_model_iff_stream (seed : Nat) :
    SwapSampleStatement seed ↔ SwapSampleStreamStatement seed := by
  constructor
  · intro hm s hs
    unfold swapSampleStreams at hs
    obtain ⟨m, hmem, rfl⟩ := List.mem_map.mp hs
    rw [swapFileOfStream_encode m]
    exact hm m hmem
  · intro hs m hm
    have := hs (encodePair m) (List.mem_map.mpr ⟨m, hm, rfl⟩)
    rwa [swapFileOfStream_encode m] at this

end CnSeed
end SpecLab
