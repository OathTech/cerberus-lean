/-
SpecLab.CnSeed — arc-15 S5 (R5, the CN-seed rung): swap_pair +
lookup_size_shift, the first post-ladder CN corpus instantiations —
built to MEASURE how cheap a new target is once the R1-R4 library
exists (the amortization number is the deliverable; S5 record).

TARGETS (real external code, clean-room from deps/cn — BSD-2; the
tutorial-derived corpus is banned):

  * deps/cn/tests/cn/swap_pair.c — CN spec, verbatim:
        void swap_pair(unsigned long int *pair_p)
        /*@ requires
                take pairStart = each (i32 j; 0i32 <= j && j < 2i32)
                                      {RW(array_shift(pair_p, j))};
            ensures
                take pairEnd = each (i32 j; 0i32 <= j && j < 2i32)
                                    {RW(array_shift(pair_p, j))};
                pairEnd[0i32] == pairStart[1i32];
                pairEnd[1i32] == pairStart[0i32];
        @*/
    The FIRST corpus target whose `ensures` is a functional relation
    between pre- and post-STATE memory (the swap family the warm-up
    doctrine named). The file's own `/*@ trusted; @*/` main is
    replaced by the harness — the harness IS the closed program.
  * deps/cn/tests/cn/cn_inline.c `lookup_size_shift` — CN spec,
    verbatim:
        static inline int
        lookup_size_shift (enum size sz)
        /*@ cn_function lookup_size_shift_cn;
            ensures return == lookup_size_shift_cn(sz); @*/
    with `/*@ function (i32) lookup_size_shift_cn (u32 sz) @*/`.
    CN's `cn_function` binds the C function to an uninterpreted spec
    function DERIVED from the C body — literally the modelFn idea
    with the arrow reversed (we author `lookupSizeShift`
    independently and check it against execution; CN trusts its
    translation of the body). Comparison-record anchor (S5 doc).

WELL-FORMEDNESS HONESTY NOTES:
  * swap: `Wf` is VACUOUS — the first rung with a FULL model domain
    (every u64 pair is realizable; the 16-byte stream is total on its
    index space). CN's `requires` is ownership-only; ours is nothing.
  * lookup: `LWf` = 0 ≤ sz < 2^31. CN types the spec function's
    argument `u32`; our closed program builds the argument as a
    nonneg `int` and converts to `enum size` (probed identical on
    both pipelines up to 2^31-1, incl. non-enumerator values — the
    default arm is live). Values ≥ 2^31 are the harness's 254 arm
    (the int build would be implementation-defined).

PURE MODELS: swap is literally the pair swap; lookup mirrors the
switch (12/8/2/0). Both CN postconditions' functional content is
DEFINITIONAL on the model (`swap_post`, `lookup_is_model` — the
fourth and fifth collapse datapoints, proof register S5).

House style: computable pure functions + first-order data only.
-/

import SpecLab.Codec
import SpecLab.MkHarness
import SpecLab.DivMod
import SpecLab.ByteArr

set_option autoImplicit false

namespace SpecLab
namespace CnSeed

open Codec

/-! ## The swap_pair model (full domain — no Wf side conditions) -/

/-- The swap model `M`: one u64 pair (the CN resource's two cells). -/
structure PairInput where
  a : UInt64
  b : UInt64
  deriving Repr, DecidableEq

/-- `modelFn`, swap face: the CN postcondition as a pure function —
`pairEnd[0] == pairStart[1] ∧ pairEnd[1] == pairStart[0]`. -/
def swapModelFn (m : PairInput) : PairInput := ⟨m.b, m.a⟩

/-- The CN `ensures` clauses are DEFINITIONAL on the model (collapse
datapoint 4: both conjuncts are `rfl`). -/
theorem swap_post (m : PairInput) :
    (swapModelFn m).a = m.b ∧ (swapModelFn m).b = m.a := ⟨rfl, rfl⟩

/-- Swap is an involution (the pure-layer freebie CN would need a
second contract application for). -/
theorem swap_involutive (m : PairInput) :
    swapModelFn (swapModelFn m) = m := rfl

/-! ## The swap codec: two u64le values (S0 scalar codecs, reused —
    zero new codec definitions at this rung) -/

/-- `encode : M → Stream` — 16 bytes, a then b, u64le each. -/
def encodePair (m : PairInput) : Stream :=
  encodeU64LE m.a ++ encodeU64LE m.b

def decodePair : Dec PairInput := fun s =>
  match decodeU64LE s with
  | none => none
  | some (a, s1) =>
    match decodeU64LE s1 with
    | none => none
    | some (b, s2) => some (⟨a, b⟩, s2)

/-- Round trip — UNCONDITIONAL (u64 is exact on the wire; the first
rung whose input round trip carries no side condition). -/
theorem decode_encode_pair (m : PairInput) (rest : Stream) :
    decodePair (encodePair m ++ rest) = some (m, rest) := by
  simp only [decodePair, encodePair, List.append_assoc,
    decode_encode_u64le m.a (encodeU64LE m.b ++ rest),
    decode_encode_u64le m.b rest]

/-- Canonicity at the pair codec (from the S5 library additions
`canonical_u64le`). -/
theorem encode_decode_pair (s : Stream) (m : PairInput)
    (h : decodePair s = some (m, [])) : s = encodePair m := by
  cases ha : decodeU64LE s with
  | none => simp [decodePair, ha] at h
  | some p =>
    obtain ⟨a, s1⟩ := p
    cases hb : decodeU64LE s1 with
    | none => simp [decodePair, ha, hb] at h
    | some q =>
      obtain ⟨b, s2⟩ := q
      simp only [decodePair, ha, hb, Option.some.injEq,
        Prod.mk.injEq] at h
      obtain ⟨hm, hs2⟩ := h
      rw [hs2] at hb
      have h1 := canonical_u64le s a s1 ha
      have h2 := canonical_u64le s1 b [] hb
      rw [h1, h2, ← hm]
      simp [encodePair]

/-- The expected observation: the post-call pair, re-encoded with the
input's wire codec (one vocabulary end to end). -/
def expectedBytes (m : PairInput) : Stream := encodePair (swapModelFn m)

/-! ## Stream validity + the model-∀ ↔ stream-∀ bridge (Wf-free
    instance of the S1 bridge shape) -/

/-- A valid choice stream, operationally: exactly 16 bytes decoding to
a pair (no Wf conjunct — the domain is full). -/
def ValidStream (s : Stream) : Prop :=
  match decodePair s with
  | some (_, []) => True
  | _ => False

/-- Executable `ValidStream` (fuzz filter). -/
def validStreamb (s : Stream) : Bool :=
  match decodePair s with
  | some (_, []) => true
  | _ => false

/-- The malformed-stream junk splice: nonempty by construction (the
S0 empty-initializer caveat), used only where callers own validity. -/
def junkExpected : Stream := [0]

def expectedOfStream (s : Stream) : Stream :=
  match decodePair s with
  | some (m, []) => expectedBytes m
  | _ => junkExpected

/-- THE BRIDGE, Wf-free: with a full model domain the model side
carries no hypothesis at all. Costs exactly the two codec laws, as
S1-E2 priced. -/
theorem model_forall_iff_stream_forall (P : Stream → Stream → Prop) :
    (∀ m : PairInput, P (encodePair m) (expectedBytes m)) ↔
    (∀ s : Stream, ValidStream s → P s (expectedOfStream s)) := by
  constructor
  · intro hm s hs
    unfold ValidStream at hs
    cases hdec : decodePair s with
    | none => rw [hdec] at hs; cases hs
    | some p =>
      obtain ⟨m, rest⟩ := p
      rw [hdec] at hs
      cases rest with
      | cons _ _ => cases hs
      | nil =>
        have hcanon := encode_decode_pair s m hdec
        have : expectedOfStream s = expectedBytes m := by
          unfold expectedOfStream; rw [hdec]
        rw [this, hcanon]
        exact hm m
  · intro hs m
    have hdec : decodePair (encodePair m ++ []) = some (m, []) :=
      decode_encode_pair m []
    rw [List.append_nil] at hdec
    have hvalid : ValidStream (encodePair m) := by
      unfold ValidStream; rw [hdec]; trivial
    have hexp : expectedOfStream (encodePair m) = expectedBytes m := by
      unfold expectedOfStream; rw [hdec]
    have := hs (encodePair m) hvalid
    rwa [hexp] at this

/-! ## The swap plant model (lost update: `pair_p[1] = pair_p[0]`
    after the first store — both cells end holding b) -/

/-- The LOST-UPDATE plant's model: the classic tmp-discipline bug. -/
def swapPlantFn (m : PairInput) : PairInput := ⟨m.b, m.b⟩

/-- Predicted plant verdict (via the shared R1 comparator mirror):
first divergence between (b, b) and (b, a) — observation byte 8 + the
first differing byte of b vs a, i.e. 9 at the pinned instance. -/
def swapPlantVerdict (m : PairInput) : Nat :=
  DivMod.verdictOf (encodePair (swapPlantFn m)) (expectedBytes m)

/-- u64 wire encoding is injective (via the round trip). -/
theorem encodeU64LE_inj {x y : UInt64}
    (h : encodeU64LE x = encodeU64LE y) : x = y := by
  have hx := decode_encode_u64le x ([] : Stream)
  rw [h, decode_encode_u64le y ([] : Stream)] at hx
  injection hx with h1
  injection h1 with h2 _
  exact h2.symm

/-- The plant's blind spot is EXACTLY the diagonal: verdict 0 ⟺
a = b (the lost update is invisible iff the pair is degenerate) —
kernel-checked via the S2 idiom-library comparator law
`ByteArr.verdictOf_eq_zero_iff`, so the blind-spot set is not just
demonstrated but CHARACTERIZED (first rung with a closed-form
blind-spot theorem). -/
theorem swapPlant_blind_iff (m : PairInput) :
    swapPlantVerdict m = 0 ↔ m.a = m.b := by
  unfold swapPlantVerdict swapPlantFn expectedBytes swapModelFn
  rw [ByteArr.verdictOf_eq_zero_iff]
  simp only [encodePair]
  constructor
  · intro h
    exact (encodeU64LE_inj (List.append_cancel_left h)).symm
  · intro h
    rw [h]

/-! ## The lookup_size_shift model -/

/-- LP64 signed-int upper bound (the harness's build ceiling). -/
def lookupBound : Int := 2147483648

/-- Well-formedness: the sz values the closed program can build
(nonneg int; see header honesty note). -/
def LWf (sz : Int) : Prop := 0 ≤ sz ∧ sz < lookupBound

instance (sz : Int) : Decidable (LWf sz) := by
  unfold LWf; infer_instance

def lwfb (sz : Int) : Bool := decide (LWf sz)

/-- `modelFn`, lookup face: the pure mirror of the switch — OUR
independently-authored spelling of CN's `lookup_size_shift_cn`
(big = 0 ↦ 12, medium = 1 ↦ 8, small = 2 ↦ 2, default ↦ 0). -/
def lookupSizeShift (sz : Int) : Int :=
  if sz = 0 then 12 else if sz = 1 then 8 else if sz = 2 then 2 else 0

/-- The switch's arms as equations (collapse datapoint 5: the CN
postcondition `return == lookup_size_shift_cn(sz)` has no residual
content once the spec function is given a definition — all four arms
are `rfl`/`decide`). -/
theorem lookup_is_model :
    lookupSizeShift 0 = 12 ∧ lookupSizeShift 1 = 8 ∧
    lookupSizeShift 2 = 2 ∧ lookupSizeShift 77 = 0 := by decide

/-- Result bounds (every arm lands in [0, 12] — the harness's 1-byte
result observation is exact… stated at i32 width anyway). -/
theorem lookup_bounds (sz : Int) :
    0 ≤ lookupSizeShift sz ∧ lookupSizeShift sz ≤ 12 := by
  unfold lookupSizeShift
  split
  · omega
  · split
    · omega
    · split <;> omega

/-- The pure mirror of cn_inline.c's SECOND contract (`f`'s
`ensures return < 1000i32`): `3 * lookup(medium) + 5 * lookup(small)
= 34 < 1000`. CN discharges this through the cn_function binding; in
pure land it is one `decide`. -/
theorem f_model_lt_1000 :
    3 * lookupSizeShift 1 + 5 * lookupSizeShift 2 < 1000 := by decide

/-- Results stay in i32 range (the observation encoding's honesty). -/
theorem lookup_inRange (sz : Int) : DivMod.inI32 (lookupSizeShift sz) := by
  have := lookup_bounds sz
  unfold DivMod.inI32 DivMod.i32Min DivMod.i32Max
  omega

/-- The lookup expected observation: i32le of the result (the S1
scalar codec, reused). -/
def lookupExpected (sz : Int) : Stream :=
  DivMod.encodeI32LE (lookupSizeShift sz)

/-- The lookup choice stream: u32le of sz. -/
def encodeSz (sz : Int) : Stream :=
  encodeU32LE (UInt32.ofNat sz.toNat)

/-- The WRONG-CONSTANT plant model (`case medium: return 12` — the
copy-paste bug; every other arm intact). -/
def lookupPlantFn (sz : Int) : Int :=
  if sz = 1 then 12 else lookupSizeShift sz

/-- Predicted plant verdict: 1 at sz = 1 (result byte 0), 0 elsewhere
(the blind spots are every non-medium sz — documented + demonstrated
as green twins in the lane). -/
def lookupPlantVerdict (sz : Int) : Nat :=
  DivMod.verdictOf (DivMod.encodeI32LE (lookupPlantFn sz))
    (lookupExpected sz)

/-! ## Sample sets -/

/-- Swap edge values: 0, 1, byte/word/dword boundaries, 2^63, the
maxima, and a mixed-byte composite. 10 values → 100 pairs (all
swept). -/
def swapEdgeVals : List UInt64 :=
  [0, 1, 255, 256, 4294967295, 4294967296, 9223372036854775808,
   18446744073709551615, 1311768467463790320, 81985529216486895]

/-- The swap sweep set: the full cross product (no Wf filter — the
domain is full; includes the a = b diagonal, the plant's blind
spots). -/
def swapSamples : List PairInput :=
  swapEdgeVals.flatMap (fun a => swapEdgeVals.map (fun b => ⟨a, b⟩))

/-- Lookup sweep values: the three enumerators, the default-arm
neighbours, byte/word boundaries, and the int maxima region (probed
identical both pipelines). -/
def lookupSamples : List Int :=
  [0, 1, 2, 3, 4, 10, 77, 255, 256, 65536, 12345678, 2000000000,
   2147483647]

end CnSeed
end SpecLab
