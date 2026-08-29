/-
SpecLab.DivMod — arc-15 S1 (R1, the scalar rung): the division/mod
target pair.

TARGETS (real external code, clean-room from deps/cn — BSD-2; the
tutorial-derived corpus is banned):

  * deps/cn/tests/cn/division.c — CN spec, verbatim:
        int division (int x, int y)
        /*@ requires y != 0i32;
            ensures return == x/y; @*/
        { return x / y; }
  * deps/cn/tests/cn/mod.c — CN spec, verbatim:
        int mod (int x, int y)
        /*@ requires y != 0i32;
            ensures return == x % y; @*/
        { return x % y; }

WELL-FORMEDNESS HONESTY NOTE: our `Wf` adds
`¬(x = INT_MIN ∧ y = -1)` beyond CN's `y != 0i32`. C11 6.5.5p6 makes
INT_MIN / -1 (quotient unrepresentable) undefined, and the same
clause covers `%`; the cerberus elaboration guards both with
`catch_exceptional_condition`. CN's spec as written does not state
this corner in `requires` (CN discharges it through its own UB
side-conditions); our closed-program observation form must exclude it
up front or the harness instance would be a UB program, which the
harnesses-are-programs doctrine forbids. Register entry: spec
register, S1.

PURE MODEL: C `/` truncates toward zero and `%` takes the dividend's
sign (C11 6.5.5p5-6) — exactly `Int.tdiv` / `Int.tmod`.

House style: computable pure functions + first-order data only.
-/

import SpecLab.Codec
import SpecLab.MkHarness

set_option autoImplicit false

namespace SpecLab
namespace DivMod

open Codec

/-! ## The i32 range (LP64 signed int; the T1 `intRange` shape) -/

def i32Min : Int := -2147483648
def i32Max : Int := 2147483647

def inI32 (n : Int) : Prop := i32Min ≤ n ∧ n ≤ i32Max

instance (n : Int) : Decidable (inI32 n) := by
  unfold inI32; infer_instance

/-! ## The model (first-order inductive data + computable functions) -/

/-- The model `M` of the template: one division/mod input pair. -/
structure Input where
  x : Int
  y : Int
  deriving Repr, DecidableEq

/-- Well-formedness: both operands in i32 range, `y ≠ 0` (CN's
`requires`), and not the INT_MIN / -1 overflow corner (see header). -/
def Wf (m : Input) : Prop :=
  inI32 m.x ∧ inI32 m.y ∧ m.y ≠ 0 ∧ ¬(m.x = i32Min ∧ m.y = -1)

instance (m : Input) : Decidable (Wf m) := by
  unfold Wf; infer_instance

/-- Executable well-formedness (for emitters/fuzz filters — same
proposition, by `decide`). -/
def wfb (m : Input) : Bool := decide (Wf m)

/-- `modelFn`, division face: C truncated division (C11 6.5.5p6). -/
def modelDiv (m : Input) : Int := m.x.tdiv m.y

/-- `modelFn`, mod face: C remainder, dividend's sign (C11 6.5.5p5-6). -/
def modelMod (m : Input) : Int := m.x.tmod m.y

/-- The pure behavioral spec `modelFn : M → M'` of the template. -/
def modelFn (m : Input) : Int × Int := (modelDiv m, modelMod m)

/-! ## The i32 codec (two's-complement u32 LE, built on the S0 scalar
    codecs) -/

/-- Two's-complement image of an integer in a u32 (the encoder's
value-to-wire step; total — the round trip below is range-guarded). -/
def toU32 (n : Int) : UInt32 := UInt32.ofNat (n % 4294967296).toNat

/-- Signed reading of a u32 (the decoder's wire-to-value step). -/
def ofU32 (u : UInt32) : Int :=
  if u.toNat < 2147483648 then (u.toNat : Int)
  else (u.toNat : Int) - 4294967296

def encodeI32LE (n : Int) : Stream := encodeU32LE (toU32 n)

def decodeI32LE : Dec Int := fun s =>
  match decodeU32LE s with
  | none => none
  | some (u, rest) => some (ofU32 u, rest)

theorem ofU32_toU32 (n : Int) (h : inI32 n) : ofU32 (toU32 n) = n := by
  obtain ⟨h1, h2⟩ := h
  unfold i32Min at h1
  unfold i32Max at h2
  have hval : (toU32 n).toNat = (n % 4294967296).toNat := by
    simp only [toU32, UInt32.toNat_ofNat']
    omega
  unfold ofU32
  rw [hval]
  split <;> omega

/-- Wire canonicity, the round trip's OTHER half: `toU32 ∘ ofU32 = id`
(no side condition — every u32 is a canonical wire image). Needed by
the model-∀ ↔ stream-∀ bridge, not by the S0 round-trip contract:
register-worthy finding (spec register, S1). -/
theorem toU32_ofU32 (u : UInt32) : toU32 (ofU32 u) = u := by
  have hu : u.toNat < 4294967296 := u.toNat_lt
  have : ((ofU32 u) % 4294967296).toNat = u.toNat := by
    simp only [ofU32]
    split <;> omega
  simp only [toU32, this, UInt32.ofNat_toNat]

theorem decode_encode_i32le (n : Int) (h : inI32 n) (rest : Stream) :
    decodeI32LE (encodeI32LE n ++ rest) = some (n, rest) := by
  simp only [decodeI32LE, encodeI32LE, decode_encode_u32le (toU32 n) rest,
    ofU32_toU32 n h]

/-- Encode-after-decode canonicity at the u16 wire level: a stream a
decode consumes IS the encoding of the decoded value. -/
theorem encode_decode_u16le (s rest : Stream) (u : UInt16)
    (h : decodeU16LE s = some (u, rest)) :
    s = encodeU16LE u ++ rest := by
  match s with
  | b0 :: b1 :: s' =>
    have hb0 := b0.toNat_lt
    have hb1 := b1.toNat_lt
    simp only [decodeU16LE, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨hu, hrest⟩ := h
    subst hrest
    have h16 : u.toNat = b0.toNat + 256 * b1.toNat := by
      rw [← hu]
      simp
      omega
    have hb0' : b0 = UInt8.ofNat (u.toNat % 256) := by
      apply UInt8.toNat_inj.mp
      simp
      omega
    have hb1' : b1 = UInt8.ofNat (u.toNat / 256) := by
      apply UInt8.toNat_inj.mp
      simp
      omega
    simp [encodeU16LE, hb0', hb1']
  | [] => simp [decodeU16LE] at h
  | [_] => simp [decodeU16LE] at h

/-- Encode-after-decode canonicity at the u32 wire level (composes the
u16 halves). -/
theorem encode_decode_u32le (s rest : Stream) (u : UInt32)
    (h : decodeU32LE s = some (u, rest)) :
    s = encodeU32LE u ++ rest := by
  cases h1 : decodeU16LE s with
  | none => simp [decodeU32LE, h1] at h
  | some p =>
    obtain ⟨lo, s1⟩ := p
    cases h2 : decodeU16LE s1 with
    | none => simp [decodeU32LE, h1, h2] at h
    | some q =>
      obtain ⟨hi, s2⟩ := q
      simp only [decodeU32LE, h1, h2, Option.some.injEq,
        Prod.mk.injEq] at h
      obtain ⟨hu, hrest⟩ := h
      rw [hrest] at h2
      have hlo' := lo.toNat_lt
      have hhi' := hi.toNat_lt
      have e1 := encode_decode_u16le s s1 lo h1
      have e2 := encode_decode_u16le s1 rest hi h2
      have hlo : u32lo u = lo := by
        apply UInt16.toNat_inj.mp
        rw [← hu]
        simp only [u32lo, UInt32.toNat_ofNat', UInt16.toNat_ofNat']
        omega
      have hhi : u32hi u = hi := by
        apply UInt16.toNat_inj.mp
        rw [← hu]
        simp only [u32hi, UInt32.toNat_ofNat', UInt16.toNat_ofNat']
        omega
      rw [e1, e2, encodeU32LE, hlo, hhi, List.append_assoc]

/-! ## Input/result codecs -/

/-- `encode : M → Stream` — 8 bytes, x then y, each i32-as-u32le. -/
def encodeInput (m : Input) : Stream :=
  encodeI32LE m.x ++ encodeI32LE m.y

def decodeInput : Dec Input := fun s =>
  match decodeI32LE s with
  | none => none
  | some (x, s1) =>
    match decodeI32LE s1 with
    | none => none
    | some (y, s2) => some (⟨x, y⟩, s2)

theorem decode_encode_input (m : Input) (h : Wf m) (rest : Stream) :
    decodeInput (encodeInput m ++ rest) = some (m, rest) := by
  obtain ⟨hx, hy, _, _⟩ := h
  simp only [decodeInput, encodeInput, List.append_assoc,
    decode_encode_i32le m.x hx (encodeI32LE m.y ++ rest),
    decode_encode_i32le m.y hy rest]

/-- `encodeResult` — 8 bytes, quotient then remainder. -/
def encodeResult (p : Int × Int) : Stream :=
  encodeI32LE p.1 ++ encodeI32LE p.2

/-- The pure-side expected observation: what the healthy harness's
`out[]` must hold — computed at statement-construction time (template
note, Form 1). -/
def expectedBytes (m : Input) : Stream := encodeResult (modelFn m)

/-! ## Stream validity (operational form) and the model-∀ ↔ stream-∀
    bridge — the S1 statement-style experiment's kernel content -/

/-- A valid choice stream, OPERATIONALLY: exactly 8 bytes decoding to a
well-formed input. (The alternative, definitionally-trivial form
`∃ m, Wf m ∧ s = encodeInput m` makes the bridge a tautology; this
form is what a fuzzer/replayer actually checks. Register entry
compares the two.) -/
def ValidStream (s : Stream) : Prop :=
  match decodeInput s with
  | some (m, []) => Wf m
  | _ => False

/-- Executable `ValidStream` (same proposition, boolean face — the
fuzz filter). -/
def validStreamb (s : Stream) : Bool :=
  match decodeInput s with
  | some (m, []) => wfb m
  | _ => false

/-- The expected bytes of a valid stream (junk value on invalid ones —
callers own validity, mirroring the codec side conditions). -/
def expectedOfStream (s : Stream) : Stream :=
  match decodeInput s with
  | some (m, []) => expectedBytes m
  | _ => []

/-- i32-layer canonicity, lifted from the u32 wire layer. -/
theorem encode_decode_i32le' (s rest : Stream) (x : Int)
    (h : decodeI32LE s = some (x, rest)) :
    s = encodeI32LE x ++ rest := by
  cases hu : decodeU32LE s with
  | none => simp [decodeI32LE, hu] at h
  | some p =>
    obtain ⟨u, s'⟩ := p
    simp only [decodeI32LE, hu, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨hx, hs⟩ := h
    rw [hs] at hu
    have e := encode_decode_u32le s rest u hu
    rw [e, encodeI32LE, ← hx, toU32_ofU32]

/-- Stream canonicity at the input codec: any stream `decodeInput`
fully consumes is the encoding of its decode. The bridge's
load-bearing half (see `toU32_ofU32`). -/
theorem encode_decode_input (s : Stream) (m : Input)
    (h : decodeInput s = some (m, [])) : s = encodeInput m := by
  cases hx : decodeI32LE s with
  | none => simp [decodeInput, hx] at h
  | some p =>
    obtain ⟨x, s1⟩ := p
    cases hy : decodeI32LE s1 with
    | none => simp [decodeInput, hx, hy] at h
    | some q =>
      obtain ⟨y, s2⟩ := q
      simp only [decodeInput, hx, hy, Option.some.injEq,
        Prod.mk.injEq] at h
      obtain ⟨hm, hs2⟩ := h
      rw [hs2] at hy
      have h1 := encode_decode_i32le' s s1 x hx
      have h2 := encode_decode_i32le' s1 [] y hy
      rw [h1, h2, ← hm]
      simp [encodeInput]

/-- THE BRIDGE (statement-style experiment, S1): for ANY harness
property `P` over rendered C text, the model-∀ headline and the
stream-∀ lemma are interderivable. `P` abstracts the exec predicate
(e.g. "both pipelines converge on Specified 0"); the two directions
cost exactly the two codec canonicity halves. -/
theorem model_forall_iff_stream_forall
    (P : Stream → Stream → Prop) :
    (∀ m : Input, Wf m → P (encodeInput m) (expectedBytes m)) ↔
    (∀ s : Stream, ValidStream s → P s (expectedOfStream s)) := by
  constructor
  · intro hm s hs
    unfold ValidStream at hs
    cases hdec : decodeInput s with
    | none => rw [hdec] at hs; cases hs
    | some p =>
      obtain ⟨m, rest⟩ := p
      rw [hdec] at hs
      cases rest with
      | cons _ _ => cases hs
      | nil =>
        have hcanon := encode_decode_input s m hdec
        have : expectedOfStream s = expectedBytes m := by
          unfold expectedOfStream; rw [hdec]
        rw [this, hcanon]
        exact hm m hs
  · intro hs m hm
    have hdec : decodeInput (encodeInput m ++ []) = some (m, []) :=
      decode_encode_input m hm []
    rw [List.append_nil] at hdec
    have hvalid : ValidStream (encodeInput m) := by
      unfold ValidStream; rw [hdec]; exact hm
    have hexp : expectedOfStream (encodeInput m) = expectedBytes m := by
      unfold expectedOfStream; rw [hdec]
    have := hs (encodeInput m) hvalid
    rwa [hexp] at this

/-! ## P5 pure-transport lemmas: the CN postconditions' pure content,
    proved once in pure land (proof register, S1) -/

/-- Reconstruction (the C11 6.5.5p6 invariant `(a/b)*b + a%b == a`):
the two CN `ensures` clauses cohere. -/
theorem divmod_reconstruction (m : Input) :
    m.y * modelDiv m + modelMod m = m.x :=
  Int.mul_tdiv_add_tmod m.x m.y

/-- Remainder bound: `|x % y| < |y|` (y ≠ 0). -/
theorem modelMod_bound (m : Input) (hy : m.y ≠ 0) :
    (modelMod m).natAbs < m.y.natAbs := by
  have habs : (modelMod m).natAbs = m.x.natAbs % m.y.natAbs := by
    simp [modelMod]
  have hb : 0 < m.y.natAbs := by omega
  rw [habs]
  exact Nat.mod_lt _ hb

/-- Quotient stays in i32 range on the Wf domain — the pure mirror of
the harness's UB-freedom at the division call (why Wf excludes
INT_MIN / -1). -/
theorem modelDiv_inRange (m : Input) (h : Wf m) : inI32 (modelDiv m) := by
  obtain ⟨⟨hx1, hx2⟩, ⟨hy1, hy2⟩, hy0, hcorner⟩ := h
  simp only [inI32, i32Min, i32Max] at *
  have hq : (modelDiv m).natAbs = m.x.natAbs / m.y.natAbs := by
    simp only [modelDiv, Int.natAbs_tdiv]
    rfl
  by_cases hb : 2 ≤ m.y.natAbs
  · -- |y| ≥ 2: |q| ≤ |x|/2 ≤ 2^30
    have hbound : (modelDiv m).natAbs ≤ 1073741824 := by
      rw [hq]
      calc m.x.natAbs / m.y.natAbs
          ≤ m.x.natAbs / 2 := Nat.div_le_div_left hb (by omega)
        _ ≤ 2147483648 / 2 := Nat.div_le_div_right (by omega)
        _ = 1073741824 := rfl
    omega
  · -- |y| = 1: y = 1 (exact) or y = -1 (INT_MIN excluded by Wf)
    have hy1' : m.y = 1 ∨ m.y = -1 := by omega
    rcases hy1' with h1 | h1
    · have : modelDiv m = m.x := by
        simp [modelDiv, h1, Int.tdiv_one]
      omega
    · have hxne : m.x ≠ -2147483648 := fun hx => hcorner ⟨hx, h1⟩
      have : (modelDiv m).natAbs = m.x.natAbs := by
        rw [hq, h1]
        simp
      omega

/-- Remainder stays in i32 range on the Wf domain. -/
theorem modelMod_inRange (m : Input) (h : Wf m) : inI32 (modelMod m) := by
  obtain ⟨⟨hx1, hx2⟩, ⟨hy1, hy2⟩, hy0, _⟩ := h
  have hb := modelMod_bound m hy0
  simp only [inI32, i32Min, i32Max] at *
  omega

/-! ## Sample sets (the finite explicit sets the R1 statements
    quantify over; edges per the S1 scoping: 0, ±1, maxima, sign
    boundaries) -/

/-- Edge operand values: 0, ±1, the i32 maxima and their neighbours,
the i8/i16 sign boundaries, and two mid-range composites. (13 values
→ 13×13 = 169 pairs → 155 Wf samples after dropping the 13 y = 0
rows and the INT_MIN / -1 corner.) -/
def edgeVals : List Int :=
  [0, 1, -1, 2, -2, 10, -10, 127, -128, 2147483647, -2147483648,
   -2147483647, 123456789]

/-- The edge sample set: the Wf cross product of `edgeVals` (dropping
y = 0 rows and the INT_MIN / -1 corner). -/
def edgeSamples : List Input :=
  (edgeVals.flatMap (fun x => edgeVals.map (fun y => Input.mk x y))).filter
    (fun m => wfb m)

end DivMod
end SpecLab
