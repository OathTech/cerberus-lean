/-
SpecLab.Codec — self-delimiting byte codecs, first cut (arc-15 S0).

The choice-stream substrate of the harness statement template
(notes/2026-08-22_harness-statement-template.md): pure `encode : M →
Stream` / `decode : Stream → M` pairs with kernel-checked
decode∘encode=id round-trip lemmas. `decode` here IS a free generator
in the generators-as-parsers sense (Goldstein & Pierce; Hypothesis's
byte-stream IR — design-lineage section of the template note); the
round-trip law is what converts stream-∀ statements to model-∀
headlines.

Design rules (S0):
  * Every decoder is SELF-DELIMITING: it consumes a prefix and returns
    the rest (`Dec α := Stream → Option (α × Stream)`), so codecs
    compose by sequencing and the round-trip contract `RoundTrip`
    composes with it.
  * Scalars are fixed-width little-endian; wider scalars compose from
    narrower ones (u32 = two u16, u64 = two u32) so each round-trip
    lemma leans on the previous one plus one omega-sized arithmetic
    step — no monolithic bit-blasting, no non-kernel proof methods.
  * Arrays are length-prefixed (u16 count), decoded by structural
    recursion on the count; the round-trip lemma is parametric in the
    element codec's round-trip proof.
  * Decoders use explicit `match`, not do-notation — the round-trip
    proofs then reduce by plain iota under `simp`, with no monad-bind
    lemma dependence.

All lemmas here are ordinary kernel-checked declarations (checked by
this package's plain `lake build`; see test/Unit/SpecLabTest.lean for
the executable sanity layer, which is a TEST, not a proof).
-/

set_option autoImplicit false

namespace SpecLab

/-- A choice stream: pure data, the statement-level transport of the
harness template. -/
abbrev Stream := List UInt8

namespace Codec

/-- A self-delimiting decoder: consumes a prefix, returns the value and
the unconsumed rest (`none` = underrun/malformed). -/
abbrev Dec (α : Type) := Stream → Option (α × Stream)

/-- The round-trip contract: decoding an encoding, in any right
context, yields exactly the value and the untouched context. Stated
with an arbitrary `rest` so it composes under sequencing. -/
def RoundTrip {α : Type} (enc : α → Stream) (dec : Dec α) : Prop :=
  ∀ (a : α) (rest : Stream), dec (enc a ++ rest) = some (a, rest)

/-! ## Scalars (fixed-width little-endian) -/

def encodeU8 (v : UInt8) : Stream := [v]

def decodeU8 : Dec UInt8
  | [] => none
  | b :: rest => some (b, rest)

theorem decode_encode_u8 : RoundTrip encodeU8 decodeU8 := by
  intro a rest; rfl

def encodeU16LE (v : UInt16) : Stream :=
  [UInt8.ofNat (v.toNat % 256), UInt8.ofNat (v.toNat / 256)]

def decodeU16LE : Dec UInt16
  | b0 :: b1 :: rest => some (UInt16.ofNat (b0.toNat + 256 * b1.toNat), rest)
  | _ => none

theorem decode_encode_u16le : RoundTrip encodeU16LE decodeU16LE := by
  intro v rest
  have hv : v.toNat < 65536 := v.toNat_lt
  have h0 : (UInt8.ofNat (v.toNat % 256)).toNat = v.toNat % 256 := by simp
  have h1 : (UInt8.ofNat (v.toNat / 256)).toNat = v.toNat / 256 := by
    simp; omega
  have hsum : v.toNat % 256 + 256 * (v.toNat / 256) = v.toNat := by omega
  simp [encodeU16LE, decodeU16LE, h0, h1, hsum, UInt16.ofNat_toNat]

/-- Low u16 half of a u32 (LE order: emitted first). -/
def u32lo (v : UInt32) : UInt16 := UInt16.ofNat (v.toNat % 65536)
/-- High u16 half of a u32. -/
def u32hi (v : UInt32) : UInt16 := UInt16.ofNat (v.toNat / 65536)

def encodeU32LE (v : UInt32) : Stream :=
  encodeU16LE (u32lo v) ++ encodeU16LE (u32hi v)

def decodeU32LE : Dec UInt32 := fun s =>
  match decodeU16LE s with
  | none => none
  | some (lo, s1) =>
    match decodeU16LE s1 with
    | none => none
    | some (hi, s2) => some (UInt32.ofNat (lo.toNat + 65536 * hi.toNat), s2)

theorem decode_encode_u32le : RoundTrip encodeU32LE decodeU32LE := by
  intro v rest
  have hv : v.toNat < 4294967296 := v.toNat_lt
  have hlo : (u32lo v).toNat = v.toNat % 65536 := by simp [u32lo]
  have hhi : (u32hi v).toNat = v.toNat / 65536 := by simp [u32hi]; omega
  have h1 := decode_encode_u16le (u32lo v) (encodeU16LE (u32hi v) ++ rest)
  have h2 := decode_encode_u16le (u32hi v) rest
  have hsum : v.toNat % 65536 + 65536 * (v.toNat / 65536) = v.toNat := by
    omega
  simp [encodeU32LE, decodeU32LE, List.append_assoc, h1, h2, hlo, hhi,
    hsum, UInt32.ofNat_toNat]

/-- Low u32 half of a u64 (LE order: emitted first). -/
def u64lo (v : UInt64) : UInt32 := UInt32.ofNat (v.toNat % 4294967296)
/-- High u32 half of a u64. -/
def u64hi (v : UInt64) : UInt32 := UInt32.ofNat (v.toNat / 4294967296)

def encodeU64LE (v : UInt64) : Stream :=
  encodeU32LE (u64lo v) ++ encodeU32LE (u64hi v)

def decodeU64LE : Dec UInt64 := fun s =>
  match decodeU32LE s with
  | none => none
  | some (lo, s1) =>
    match decodeU32LE s1 with
    | none => none
    | some (hi, s2) =>
      some (UInt64.ofNat (lo.toNat + 4294967296 * hi.toNat), s2)

theorem decode_encode_u64le : RoundTrip encodeU64LE decodeU64LE := by
  intro v rest
  have hv : v.toNat < 18446744073709551616 := v.toNat_lt
  have hlo : (u64lo v).toNat = v.toNat % 4294967296 := by simp [u64lo]
  have hhi : (u64hi v).toNat = v.toNat / 4294967296 := by simp [u64hi]; omega
  have h1 := decode_encode_u32le (u64lo v) (encodeU32LE (u64hi v) ++ rest)
  have h2 := decode_encode_u32le (u64hi v) rest
  have hsum : v.toNat % 4294967296 + 4294967296 * (v.toNat / 4294967296)
      = v.toNat := by omega
  simp [encodeU64LE, decodeU64LE, List.append_assoc, h1, h2, hlo, hhi,
    hsum, UInt64.ofNat_toNat]

/-! ## Length-prefixed arrays -/

/-- Concatenated element encodings (no count — the count travels in the
prefix; kept as its own function so the round-trip induction is over
the plain list structure). -/
def encodeElems {α : Type} (encA : α → Stream) : List α → Stream
  | [] => []
  | a :: as => encA a ++ encodeElems encA as

/-- Decode exactly `n` elements. Structural recursion on the count —
total by construction. -/
def decodeElems {α : Type} (decA : Dec α) : Nat → Dec (List α)
  | 0 => fun s => some ([], s)
  | n + 1 => fun s =>
    match decA s with
    | none => none
    | some (a, s1) =>
      match decodeElems decA n s1 with
      | none => none
      | some (as, s2) => some (a :: as, s2)

/-- Length-prefixed (u16 LE count) array encoding. Callers owe
`xs.length < 65536` for the round trip (see
`decode_encode_arrayU16`); larger corpora take a wider prefix codec
(add-when-needed). -/
def encodeArrayU16 {α : Type} (encA : α → Stream) (xs : List α) : Stream :=
  encodeU16LE (UInt16.ofNat xs.length) ++ encodeElems encA xs

def decodeArrayU16 {α : Type} (decA : Dec α) : Dec (List α) := fun s =>
  match decodeU16LE s with
  | none => none
  | some (n, s1) => decodeElems decA n.toNat s1

/-- Element-count round trip, parametric in the element codec's
round-trip proof. -/
theorem decodeElems_encodeElems {α : Type} {encA : α → Stream}
    {decA : Dec α} (hRT : RoundTrip encA decA) :
    ∀ (xs : List α) (rest : Stream),
      decodeElems decA xs.length (encodeElems encA xs ++ rest)
        = some (xs, rest) := by
  intro xs
  induction xs with
  | nil => intro rest; rfl
  | cons a as ih =>
    intro rest
    simp [encodeElems, decodeElems, List.append_assoc,
      hRT a (encodeElems encA as ++ rest), ih rest]

/-- Array round trip: decode∘encode = id for length-prefixed arrays,
given the element round trip and the u16-count bound. -/
theorem decode_encode_arrayU16 {α : Type} {encA : α → Stream}
    {decA : Dec α} (hRT : RoundTrip encA decA)
    (xs : List α) (hlen : xs.length < 65536) (rest : Stream) :
    decodeArrayU16 decA (encodeArrayU16 encA xs ++ rest)
      = some (xs, rest) := by
  have hn : (UInt16.ofNat xs.length).toNat = xs.length := by simp; omega
  simp [decodeArrayU16, encodeArrayU16, List.append_assoc,
    decode_encode_u16le (UInt16.ofNat xs.length) (encodeElems encA xs ++ rest),
    hn, decodeElems_encodeElems hRT xs rest]

/-! ## Canonicity (the round trip's OTHER half) — arc-15 S2.

The S1 register (S1-E2) measured that the model-∀ ↔ stream-∀ bridge
with the OPERATIONAL stream-validity form needs BOTH codec laws:
`decode∘encode = id` (the `RoundTrip` contract above) AND
`encode∘decode = id` on consumed prefixes. Its recommendation —
"codecs should ship BOTH laws from the start" — is adopted here:
`Canonical` is the second idiom-library law, with instances for the
S0 codecs the byte-blaster rung consumes. (The u16 canonicity proof
shape follows the S1 i32-layer proofs in SpecLab/DivMod.lean, which
predate this contract and stay as-is — churn isolation.) -/

/-- The canonicity contract: any stream a decoder consumes a prefix of
IS the encoding of the decoded value followed by the rest — every
accepted wire image is canonical. -/
def Canonical {α : Type} (enc : α → Stream) (dec : Dec α) : Prop :=
  ∀ (s : Stream) (a : α) (rest : Stream),
    dec s = some (a, rest) → s = enc a ++ rest

theorem canonical_u8 : Canonical encodeU8 decodeU8 := by
  intro s a rest h
  match s with
  | [] => simp [decodeU8] at h
  | b :: s' =>
    simp only [decodeU8, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨rfl, rfl⟩ := h
    rfl

theorem canonical_u16le : Canonical encodeU16LE decodeU16LE := by
  intro s a rest h
  match s with
  | b0 :: b1 :: s' =>
    have hb0 := b0.toNat_lt
    have hb1 := b1.toNat_lt
    simp only [decodeU16LE, Option.some.injEq, Prod.mk.injEq] at h
    obtain ⟨hu, hrest⟩ := h
    subst hrest
    have h16 : a.toNat = b0.toNat + 256 * b1.toNat := by
      rw [← hu]
      simp
      omega
    have hb0' : b0 = UInt8.ofNat (a.toNat % 256) := by
      apply UInt8.toNat_inj.mp
      simp
      omega
    have hb1' : b1 = UInt8.ofNat (a.toNat / 256) := by
      apply UInt8.toNat_inj.mp
      simp
      omega
    simp [encodeU16LE, hb0', hb1']
  | [] => simp [decodeU16LE] at h
  | [_] => simp [decodeU16LE] at h

/-- A count-decode yields exactly `n` elements. -/
theorem decodeElems_length {α : Type} {decA : Dec α} :
    ∀ (n : Nat) (s : Stream) (as : List α) (rest : Stream),
      decodeElems decA n s = some (as, rest) → as.length = n := by
  intro n
  induction n with
  | zero =>
    intro s as rest h
    simp only [decodeElems, Option.some.injEq, Prod.mk.injEq] at h
    rw [← h.1]
    rfl
  | succ k ih =>
    intro s as rest h
    cases hA : decA s with
    | none => simp [decodeElems, hA] at h
    | some p =>
      obtain ⟨a, s1⟩ := p
      cases hE : decodeElems decA k s1 with
      | none => simp [decodeElems, hA, hE] at h
      | some q =>
        obtain ⟨as', s2⟩ := q
        simp only [decodeElems, hA, hE, Option.some.injEq,
          Prod.mk.injEq] at h
        rw [← h.1]
        simp [ih s1 as' s2 hE]

/-- Element-layer canonicity, parametric in the element codec's
canonicity proof. -/
theorem encodeElems_decodeElems {α : Type} {encA : α → Stream}
    {decA : Dec α} (hC : Canonical encA decA) :
    ∀ (n : Nat) (s : Stream) (as : List α) (rest : Stream),
      decodeElems decA n s = some (as, rest) →
        s = encodeElems encA as ++ rest := by
  intro n
  induction n with
  | zero =>
    intro s as rest h
    simp only [decodeElems, Option.some.injEq, Prod.mk.injEq] at h
    rw [← h.1, ← h.2]
    rfl
  | succ k ih =>
    intro s as rest h
    cases hA : decA s with
    | none => simp [decodeElems, hA] at h
    | some p =>
      obtain ⟨a, s1⟩ := p
      cases hE : decodeElems decA k s1 with
      | none => simp [decodeElems, hA, hE] at h
      | some q =>
        obtain ⟨as', s2⟩ := q
        simp only [decodeElems, hA, hE, Option.some.injEq,
          Prod.mk.injEq] at h
        obtain ⟨has, hrest⟩ := h
        rw [← has, ← hrest, hC s a s1 hA, ih s1 as' s2 hE,
          encodeElems, List.append_assoc]

/-- Array-layer canonicity: a stream `decodeArrayU16` consumes is the
length-prefixed encoding of the decoded list. The count bound needs no
side condition — the u16 prefix carries it. -/
theorem canonical_arrayU16 {α : Type} {encA : α → Stream}
    {decA : Dec α} (hC : Canonical encA decA) :
    Canonical (encodeArrayU16 encA) (decodeArrayU16 decA) := by
  intro s as rest h
  simp only [decodeArrayU16] at h
  cases hp : decodeU16LE s with
  | none => rw [hp] at h; cases h
  | some p =>
    obtain ⟨n, s1⟩ := p
    rw [hp] at h
    have hlen := decodeElems_length n.toNat s1 as rest h
    have h1 := canonical_u16le s n s1 hp
    have h2 := encodeElems_decodeElems hC n.toNat s1 as rest h
    have hn : UInt16.ofNat as.length = n := by
      rw [hlen, UInt16.ofNat_toNat]
    rw [h1, h2, encodeArrayU16, hn, List.append_assoc]

/-- The byte-blaster identity: u8 element encoding is verbatim — the
concatenated element encodings ARE the bytes (the containment-note
"copy the stream verbatim" idiom, at the codec level). -/
theorem encodeElems_u8_id : ∀ bs : List UInt8,
    encodeElems encodeU8 bs = bs := by
  intro bs
  induction bs with
  | nil => rfl
  | cons b rest ih => simp [encodeElems, encodeU8, ih]

end Codec
end SpecLab
