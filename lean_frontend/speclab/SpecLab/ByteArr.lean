/-
SpecLab.ByteArr — arc-15 S2 (R2, the array/byte-blaster rung): the
array target pair and the byte-blaster model layer.

TARGETS (real external code, clean-room from deps/cn — BSD-2; the
tutorial-derived corpus is banned):

  * deps/cn/tests/cn/memcpy.c — the MUTATOR (the containment-side
    flagship: stream → buffer contents verbatim). CN spec, verbatim:

        void
        naive_memcpy (char *dst, char *src, int n)
        /*@ requires take dstStart = each (i32 j; 0i32 <= j && j < n)
                                          {RW(array_shift(dst, j))};
                     take srcStart = each (i32 j; 0i32 <= j && j < n)
                                          {RW(array_shift(src, j))};
            ensures take dstEnd = each (i32 j; 0i32 <= j && j < n)
                                       {RW(array_shift(dst, j))};
                    take srcEnd = each (i32 j; 0i32 <= j && j < n)
                                       {RW(array_shift(src, j))};
                    srcEnd == srcStart;
                    each (i32 k; 0i32 <= k && k < n) {dstEnd[k] == srcStart[k]};
        @*/

    (loop invariant elided here; quoted in full in the harness
    template, SpecLab/ByteArrHarness.lean).

  * deps/cn/tests/cn/get_from_arr.c — the READ-ONLY companion. CN
    spec, verbatim:

        char
        get_from_arr (char *in_arr)
        /*@ requires take IA = each (i32 j; 0i32 <= j && j < 10i32)
          {RW<char>(in_arr + j)};
            ensures take IA2 = each (i32 j; 0i32 <= j && j < 10i32)
          {RW<char>(in_arr + j)}; @*/

    SELECTION REASONING (corpus-first rule): deps/cn/tests/cn has no
    array sum/min/search-shaped walker — the only looped array target
    is naive_memcpy itself, and get_from_arr is the corpus's read-only
    array-access target ("originally made by minimising a problematic
    case from memcpy.c", its own header). Note its CN `ensures` is
    OWNERSHIP-ONLY — it does not constrain the returned value at all;
    our harness spec is strictly stronger (return == in_arr[4], and
    the array is unchanged). Register entry S2-E3.

WELL-FORMEDNESS HONESTY: memcpy's CN spec has NO `requires` beyond the
ownership resources; our closed-program `Wf` is a capacity bound
(`length ≤ 16` — the template's buffer capacity, the registered
concrete-N ceiling) plus the codec's implicit u16-count bound. getarr's
domain is exactly `length = 10` (the CN resource's own extent).

PURE MODEL: memcpy's `modelFn` is the identity pair (dst' = src,
src' = src). This is NOT vacuous-by-triviality: the property weight
sits in the exec bridge (the compiled loop must realize the identity
on the heap); the pure layer records that the CN postconditions'
functional content COLLAPSES INTO the model definition for a verbatim
copy — the P5 datapoint of this rung (proof register S2-P5).

This file is STATEMENT SURFACE (scanned by
scripts/check_speclab_statements.sh): computable pure functions +
first-order data only.
-/

import SpecLab.Codec
import SpecLab.MkHarness
import SpecLab.DivModHarness

set_option autoImplicit false

namespace SpecLab
namespace ByteArr

open Codec

/-! ## The memcpy model (byte-blaster: M = the buffer's bytes) -/

/-- The template's buffer capacity (src[16]/dst[16] in the C): the
concrete-N ceiling of this rung. -/
def cap : Nat := 16

/-- Well-formedness: the stream fits the template's buffers. -/
def Wf (bs : List UInt8) : Prop := bs.length ≤ cap

instance (bs : List UInt8) : Decidable (Wf bs) := by
  unfold Wf; infer_instance

def wfb (bs : List UInt8) : Bool := decide (Wf bs)

/-- `modelFn` (memcpy): post-state of (dst, src) — dst' = src (the CN
`each` clause), src' = src (the CN `srcEnd == srcStart` clause). -/
def modelFn (bs : List UInt8) : List UInt8 × List UInt8 := (bs, bs)

/-- `encode : M → Stream` — the byte-blaster input codec: u16le count
prefix + the bytes VERBATIM (`encodeElems encodeU8 = id`,
`Codec.encodeElems_u8_id`). -/
def encodeInput (bs : List UInt8) : Stream := encodeArrayU16 encodeU8 bs

def decodeInput : Dec (List UInt8) := decodeArrayU16 decodeU8

/-- The pure-side expected observation: `u16le(n) ++ dst' ++ src'`.
The length prefix inside the OBSERVATION is what keeps `expected[]`
nonempty at n = 0 (the S0 empty-initializer caveat: n = 0 renders as
`{ 0, 0 }`, valid C — length zero is a fully live instance, not a
special case). -/
def expectedBytes (bs : List UInt8) : Stream :=
  encodeU16LE (UInt16.ofNat bs.length) ++ (modelFn bs).1 ++ (modelFn bs).2

/-- The malformed-stream junk splice (`u16le(0)`): nonempty by
construction, used only where callers own validity. -/
def junkExpected : Stream := [0, 0]

theorem decode_encode_input (bs : List UInt8) (h : Wf bs)
    (rest : Stream) : decodeInput (encodeInput bs ++ rest)
      = some (bs, rest) := by
  have hlen : bs.length < 65536 := by
    have : bs.length ≤ 16 := h
    omega
  exact decode_encode_arrayU16 decode_encode_u8 bs hlen rest

theorem encode_decode_input (s : Stream) (bs : List UInt8)
    (h : decodeInput s = some (bs, [])) : s = encodeInput bs := by
  have := canonical_arrayU16 canonical_u8 s bs [] h
  simpa [encodeInput] using this

/-! ## Stream validity (operational form) and the model-∀ ↔ stream-∀
    bridge (the S1 shape, at the array rung) -/

def ValidStream (s : Stream) : Prop :=
  match decodeInput s with
  | some (bs, []) => Wf bs
  | _ => False

def validStreamb (s : Stream) : Bool :=
  match decodeInput s with
  | some (bs, []) => wfb bs
  | _ => false

def expectedOfStream (s : Stream) : Stream :=
  match decodeInput s with
  | some (bs, []) => expectedBytes bs
  | _ => junkExpected

/-- THE BRIDGE at R2: for any harness property `P` over (choices,
expected) streams, the model-∀ headline and the stream-∀ lemma are
interderivable — costing exactly the two codec laws (`RoundTrip` +
the S2 `Canonical` contract, per the S1-E2 recommendation). -/
theorem model_forall_iff_stream_forall (P : Stream → Stream → Prop) :
    (∀ bs : List UInt8, Wf bs → P (encodeInput bs) (expectedBytes bs)) ↔
    (∀ s : Stream, ValidStream s → P s (expectedOfStream s)) := by
  constructor
  · intro hm s hs
    unfold ValidStream at hs
    cases hdec : decodeInput s with
    | none => rw [hdec] at hs; cases hs
    | some p =>
      obtain ⟨bs, rest⟩ := p
      rw [hdec] at hs
      cases rest with
      | cons _ _ => cases hs
      | nil =>
        have hcanon := encode_decode_input s bs hdec
        have : expectedOfStream s = expectedBytes bs := by
          unfold expectedOfStream; rw [hdec]
        rw [this, hcanon]
        exact hm bs hs
  · intro hs bs hbs
    have hdec : decodeInput (encodeInput bs ++ []) = some (bs, []) :=
      decode_encode_input bs hbs []
    rw [List.append_nil] at hdec
    have hvalid : ValidStream (encodeInput bs) := by
      unfold ValidStream; rw [hdec]; exact hbs
    have hexp : expectedOfStream (encodeInput bs) = expectedBytes bs := by
      unfold expectedOfStream; rw [hdec]
    have := hs (encodeInput bs) hvalid
    rwa [hexp] at this

/-! ## The getarr model (read-only walker; fixed 10-byte extent) -/

/-- getarr well-formedness: exactly the CN resource extent. -/
def GWf (bs : List UInt8) : Prop := bs.length = 10

instance (bs : List UInt8) : Decidable (GWf bs) := by
  unfold GWf; infer_instance

def gwfb (bs : List UInt8) : Bool := decide (GWf bs)

/-- getarr `modelFn`: the returned byte (`in_arr[4]`). -/
def getarrModelFn (bs : List UInt8) : UInt8 := bs.getD 4 0

/-- getarr expected observation: returned byte ++ the post-call array
(read-only ⇒ the input bytes verbatim — the readback CHECKS the
read-only claim, it does not assume it). -/
def getarrExpected (bs : List UInt8) : Stream := getarrModelFn bs :: bs

/-- getarr stream validity: exactly 10 bytes (the stream IS the model
— the fixed-extent byte-blaster has an identity codec). -/
def GValidStream (s : Stream) : Prop := GWf s

def getarrExpectedOfStream (s : Stream) : Stream :=
  if s.length = 10 then getarrExpected s else [0]

/-- The getarr bridge is definitional (identity codec): recorded as a
theorem for the register's codec-cost comparison — zero codec laws
consumed. -/
theorem getarr_model_forall_iff_stream_forall
    (P : Stream → Stream → Prop) :
    (∀ bs : List UInt8, GWf bs → P bs (getarrExpected bs)) ↔
    (∀ s : Stream, GValidStream s → P s (getarrExpectedOfStream s)) := by
  constructor
  · intro hm s hs
    have h10 : s.length = 10 := hs
    have : getarrExpectedOfStream s = getarrExpected s := by
      unfold getarrExpectedOfStream; rw [if_pos h10]
    rw [this]
    exact hm s hs
  · intro hs bs hbs
    have h10 : bs.length = 10 := hbs
    have := hs bs hbs
    unfold getarrExpectedOfStream at this
    rwa [if_pos h10] at this

/-! ## Plant models (pure-side predicted red verdicts) -/

/-- The dst canary the template pre-fills (must survive readback at a
plant's skipped cell). -/
def canary : UInt8 := 42

/-- The memcpy OFF-BY-ONE plant (`for (i = 1; ...)`) leaves dst[0] at
the canary. Post-dst of the plant, per the model. -/
def plantDst (bs : List UInt8) : List UInt8 :=
  match bs with
  | [] => []
  | _ :: rest => canary :: rest

/-- The plant's observation. -/
def plantObs (bs : List UInt8) : Stream :=
  encodeU16LE (UInt16.ofNat bs.length) ++ plantDst bs ++ bs

/-- Predicted memcpy plant verdict (generic mismatch-index mirror,
reused from the R1 idiom layer). For n ≥ 1 with bs[0] ≠ canary this is
3 = 1 + (index of dst byte 0 in the observation). -/
def plantVerdict (bs : List UInt8) : Nat :=
  DivMod.verdictOf (plantObs bs) (expectedBytes bs)

/-- The getarr WRONG-INDEX plant reads `in_arr[3]`. -/
def getarrPlantObs (bs : List UInt8) : Stream := bs.getD 3 0 :: bs

/-- Predicted getarr plant verdict (1 whenever bs[3] ≠ bs[4]). -/
def getarrPlantVerdict (bs : List UInt8) : Nat :=
  DivMod.verdictOf (getarrPlantObs bs) (getarrExpected bs)

/-! ## P5 pure-transport layer: the CN postconditions' pure content
    (proof register S2-P5) -/

/-- CN `srcEnd == srcStart`, pure face: definitional for the verbatim
model. -/
theorem src_unchanged (bs : List UInt8) : (modelFn bs).2 = bs := rfl

/-- CN `each (k) {dstEnd[k] == srcStart[k]}`, pure face: likewise
definitional. The collapse of both postconditions into `rfl` is the
rung's P5 finding — for a byte-verbatim property the ENTIRE proof
weight lives in the exec bridge; pure land holds only the codec and
comparator algebra below. -/
theorem dst_copied (bs : List UInt8) (k : Nat) (_ : k < bs.length) :
    (modelFn bs).1.getD k 0 = bs.getD k 0 := rfl

theorem expectedBytes_length (bs : List UInt8) :
    (expectedBytes bs).length = 2 + 2 * bs.length := by
  simp [expectedBytes, modelFn, encodeU16LE]
  omega

theorem getarrExpected_length (bs : List UInt8) :
    (getarrExpected bs).length = 1 + bs.length := by
  simp [getarrExpected]
  omega

/-- The comparator's pure soundness+completeness (idiom-library law,
new at S2): the mismatch-index verdict is 0 EXACTLY on equal
observations. The anti-vacuity of every Form 1 statement, at the pure
level — a plant that alters any observation byte is guaranteed a
nonzero verdict. -/
theorem verdictOf_eq_zero_iff (out expected : List UInt8) :
    DivMod.verdictOf out expected = 0 ↔ out = expected := by
  unfold DivMod.verdictOf
  by_cases hlen : out.length = expected.length
  · rw [if_neg (by omega)]
    have key : ∀ (xs ys : List UInt8) (i : Nat), xs.length = ys.length →
        (DivMod.verdictOf.firstDiff xs ys i = 0 ↔ xs = ys) := by
      intro xs
      induction xs with
      | nil =>
        intro ys i hl
        cases ys with
        | nil => simp [DivMod.verdictOf.firstDiff]
        | cons y ys' => simp at hl
      | cons x xs' ih =>
        intro ys i hl
        cases ys with
        | nil => simp at hl
        | cons y ys' =>
          simp only [DivMod.verdictOf.firstDiff]
          by_cases hxy : x = y
          · rw [if_neg (by simp [hxy])]
            have := ih ys' (i + 1) (by simpa using hl)
            simpa [hxy] using this
          · rw [if_pos (by simpa using hxy)]
            constructor
            · intro h; omega
            · intro h
              cases h
              exact absurd rfl hxy
    exact key out expected 0 hlen
  · rw [if_pos (by omega)]
    constructor
    · intro h; omega
    · intro h
      cases h
      exact absurd rfl hlen

/-! ## The structured-face experiment (spec register S2-E1): does
    interpreting the buffer as STRUCTURE (here: u16 elements) buy the
    statement anything over verbatim bytes? -/

/-- A u16-structured reading of the same buffer family. -/
def bytesOfU16s (ws : List UInt16) : List UInt8 :=
  ws.flatMap encodeU16LE

/-- The structured element stream IS the byte stream (flatten). -/
theorem encodeElems_u16_flatten (ws : List UInt16) :
    encodeElems encodeU16LE ws = encodeElems encodeU8 (bytesOfU16s ws) := by
  rw [encodeElems_u8_id]
  induction ws with
  | nil => rfl
  | cons w rest ih => simp [encodeElems, bytesOfU16s, ih]

/-- The structured model-∀ is an INSTANCE of the byte model-∀ (the
image restriction — even lengths, canonical element boundaries): the
byte-blaster statement is strictly more general, and the structured
face adds decode layers without adding claim strength. The proof being
`fun ws hw => h _ hw` IS the register verdict. -/
theorem structured_forall_of_byte_forall (P : List UInt8 → Prop)
    (h : ∀ bs : List UInt8, Wf bs → P bs) :
    ∀ ws : List UInt16, Wf (bytesOfU16s ws) → P (bytesOfU16s ws) :=
  fun _ hw => h _ hw

/-! ## Sample sets (the sweep's edge streams, pure-side: boundary
    contents 0x00/0xFF, the canary value, ramps, alternation; every
    length 0..16 — empty-adjacent lengths and both capacity maxima
    included) -/

/-- Content patterns at a given length. -/
def patterns (n : Nat) : List (List UInt8) :=
  [List.replicate n 0,
   List.replicate n 255,
   List.replicate n 170,
   List.replicate n canary,
   (List.range n).map (fun i => UInt8.ofNat (i + 1)),
   (List.range n).map (fun i => UInt8.ofNat (n - i)),
   (List.range n).map (fun i => if i % 2 == 0 then 0 else 255),
   (List.range n).map (fun i => UInt8.ofNat ((i * 37 + 11) % 256))]

/-- The memcpy sweep sample set: 17 lengths × 8 patterns = 136 models
(at n = 0 the patterns coincide — kept, honestly redundant). -/
def sweepSamples : List (List UInt8) :=
  (List.range (cap + 1)).flatMap patterns

/-- The getarr sweep sample set: the 8 patterns at length 10 + 12
multiplicative ramps (all length 10; several with bs[3] = bs[4] — the
wrong-index plant's blind spot — kept HEALTHY-lane only). -/
def getarrSamples : List (List UInt8) :=
  patterns 10 ++
    ([3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 101, 251].map fun k =>
      (List.range 10).map (fun i => UInt8.ofNat ((i * k + k) % 256)))

end ByteArr
end SpecLab
