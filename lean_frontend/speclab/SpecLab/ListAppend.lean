/-
SpecLab.ListAppend — arc-15 S3 (R3, the list rung — the first real
heap-structure builder): the linked-list target and its model layer.

TARGET (real external code, clean-room from deps/cn — BSD-2; the
tutorial-derived corpus is banned):

  * deps/cn/tests/cn/append.c — `IntList_append`, the R3 MUTATOR (the
    charter's named append family; the corpus's `split` and `main`
    from the same file are out of this rung's scope). CN spec,
    verbatim:

        struct int_list* IntList_append(struct int_list* xs, struct int_list* ys)
        /*@ requires take L1 = IntList(xs);
                     take L2 = IntList(ys);
            ensures take L3 = IntList(return);
                    L3 == append(L1, L2); @*/

    with the CN datatype/predicate block (quoted in full in the
    harness template, SpecLab/ListAppendHarness.lean):

        datatype seq { Seq_Nil {}, Seq_Cons {i32 head, datatype seq tail} }
        function [rec] (datatype seq) append(datatype seq xs, datatype seq ys)
        predicate [rec] (datatype seq) IntList(pointer p)

    SELECTION REASONING (corpus-first rule): the append/list corpus
    family is {append.c, list_rev01.c, reverse.c, mergesort*.c,
    split_case.c}; append.c is the charter-named primary mutator. The
    corpus has NO read-only list walker with functional content
    (list_rev01's List predicate returns only a length; reverse.c and
    mergesort are further mutators) — the read-only-walker slot of
    this rung is filled by the harness's own serializer/comparator
    walker (idiom-library C, not a corpus target); recorded in the
    spec register (S3).

ALLOCATION CLOSURE: append.c's own `main` builds nodes on the STACK;
our harness builds them on the HEAP so teardown/leak-freedom are
exercised. `cn_malloc`/`cn_free_sized` are NOT used by append.c, so no
shim TU is needed; the harness declares `void *malloc(unsigned long)`
/ `void free(void*)` directly — the same closure the cn_coverage
support shims use (tests/cn_coverage/support/cn_alloc_shim_ul.c,
attributed): the Core-stdlib allocator proxies claim the C names via
std.core ailnames (`malloc_proxy`/`free_proxy`), available under
--nolibc. The pinned statement layer carries those two proxy decls in
its stdlib closure.

PURE MODEL: `M = Input = (xs ys : List Int)`, elements in i32 range
(`DivMod.inI32` — the CN datatype's `i32 head`, modeled directly as
range-conditioned Int, the S1 style). `modelFn = xs ++ ys` — the CN
`append` function IS `List.append` (the P5 collapse finding of this
rung: the CN postcondition's functional content is definitionally the
model, proof register S3-P5). Codec: u16le-length-prefixed i32le
elements per list (`Codec.encodeArrayU16 DivMod.encodeI32LE`), two
lists in sequence. Observation: the RESULT list serialized with the
SAME array codec — `expectedBytes = encodeResult (modelFn m)` with
`encodeResult = the list codec` (observation layout = codec layout,
one vocabulary).

This file is STATEMENT SURFACE (scanned by
scripts/check_speclab_statements.sh): computable pure functions +
first-order data only.
-/

import SpecLab.Codec
import SpecLab.MkHarness
import SpecLab.DivModHarness

set_option autoImplicit false

namespace SpecLab
namespace ListAppend

open Codec

/-! ## Capacities and well-formedness -/

/-- Per-list node capacity (the template's builder cap). -/
def capN : Nat := 8

/-- Observation walk cap (`capN + capN`): the serializer's cap guard
bound — a post-state list longer than this (impossible for the healthy
target, reachable only via broken/cyclic plants) returns the overlong
arm 253. -/
def capTotal : Nat := 16

/-- The model: two i32 lists (the two IntList resources of the CN
spec). -/
structure Input where
  xs : List Int
  ys : List Int
  deriving Repr, DecidableEq

/-- Well-formedness: both lists fit the builder cap, every head in i32
range (the CN datatype's `i32 head`). WF HONESTY vs the CN spec
(S1-E3 shape): CN's `requires` is ownership-only — the capacity bounds
are OURS (closed-program realization must build the lists it
quantifies over: the registered concrete-N ceiling); the i32 range is
CN's own head type. -/
def Wf (m : Input) : Prop :=
  m.xs.length ≤ capN ∧ m.ys.length ≤ capN ∧
    (∀ a ∈ m.xs, DivMod.inI32 a) ∧ (∀ a ∈ m.ys, DivMod.inI32 a)

instance (m : Input) : Decidable (Wf m) := by
  unfold Wf DivMod.inI32; infer_instance

def wfb (m : Input) : Bool := decide (Wf m)

/-- `modelFn`: list append — literally the CN `append` function's
content (`Seq_Cons` chains = Lean lists). -/
def modelFn (m : Input) : List Int := m.xs ++ m.ys

/-! ## Codec (u16le count prefix + i32le elements, one per list) -/

/-- One list on the wire. -/
def encodeList (l : List Int) : Stream :=
  encodeArrayU16 DivMod.encodeI32LE l

def decodeList : Dec (List Int) := decodeArrayU16 DivMod.decodeI32LE

/-- `encode : M → Stream` — the choice stream: xs then ys. -/
def encodeInput (m : Input) : Stream :=
  encodeList m.xs ++ encodeList m.ys

/-- `decode : Stream → M` (self-delimiting sequence of the two list
codecs). -/
def decodeInput : Dec Input := fun s =>
  match decodeList s with
  | none => none
  | some (xs, s1) =>
    match decodeList s1 with
    | none => none
    | some (ys, s2) => some (⟨xs, ys⟩, s2)

/-- The observation codec = the input list codec (the result list,
serialized by the harness walker exactly as the builder consumed it —
one wire vocabulary). Nonempty for every model (u16le count prefix:
the S0 empty-initializer caveat closed by codec design, as at R2). -/
def encodeResult (l : List Int) : Stream := encodeList l

/-- The pure-side expected observation. -/
def expectedBytes (m : Input) : Stream := encodeResult (modelFn m)

/-- Malformed-splice junk expected (`u16le(0)`): nonempty by
construction. -/
def junkExpected : Stream := [0, 0]

/-! ## Round trip + canonicity (both codec laws, per the S1-E2 /
    Canonical-contract discipline) -/

/-- The i32 element round trip in membership form (what
`decode_encode_arrayU16_of` consumes; the range comes from `Wf`). -/
theorem elems_roundtrip (l : List Int) (h : ∀ a ∈ l, DivMod.inI32 a) :
    ∀ a ∈ l, ∀ rest : Stream,
      DivMod.decodeI32LE (DivMod.encodeI32LE a ++ rest) = some (a, rest) :=
  fun a ha rest => DivMod.decode_encode_i32le a (h a ha) rest

theorem decode_encode_list (l : List Int) (hlen : l.length ≤ capN)
    (hr : ∀ a ∈ l, DivMod.inI32 a) (rest : Stream) :
    decodeList (encodeList l ++ rest) = some (l, rest) := by
  have h65536 : l.length < 65536 := by unfold capN at hlen; omega
  exact decode_encode_arrayU16_of l (elems_roundtrip l hr) h65536 rest

theorem decode_encode_input (m : Input) (h : Wf m) (rest : Stream) :
    decodeInput (encodeInput m ++ rest) = some (m, rest) := by
  obtain ⟨h1, h2, hr1, hr2⟩ := h
  simp only [decodeInput, encodeInput, List.append_assoc,
    decode_encode_list m.xs h1 hr1 (encodeList m.ys ++ rest),
    decode_encode_list m.ys h2 hr2 rest]

/-- i32 element canonicity (unconditional — `Canonical` shape of the
S1 `encode_decode_i32le'`). -/
theorem canonical_i32le :
    Canonical DivMod.encodeI32LE DivMod.decodeI32LE :=
  fun s a rest h => DivMod.encode_decode_i32le' s rest a h

/-- List-codec canonicity, from the array layer. -/
theorem canonical_list : Canonical encodeList decodeList :=
  canonical_arrayU16 canonical_i32le

/-- Input canonicity: a fully consumed stream IS the encoding of its
decode (the bridge's model→stream half). -/
theorem encode_decode_input (s : Stream) (m : Input)
    (h : decodeInput s = some (m, [])) : s = encodeInput m := by
  cases hx : decodeList s with
  | none => simp [decodeInput, hx] at h
  | some p =>
    obtain ⟨xs, s1⟩ := p
    cases hy : decodeList s1 with
    | none => simp [decodeInput, hx, hy] at h
    | some q =>
      obtain ⟨ys, s2⟩ := q
      simp only [decodeInput, hx, hy, Option.some.injEq,
        Prod.mk.injEq] at h
      obtain ⟨hm, hs2⟩ := h
      rw [hs2] at hy
      have h1 := canonical_list s xs s1 hx
      have h2 := canonical_list s1 ys [] hy
      rw [h1, h2, ← hm]
      simp [encodeInput]

/- Decoded lists carry their Wf ranges? NO — deliberately not a
theorem: `decodeInput` accepts any u16 counts and any i32le images
(`ofU32` lands in i32 range by construction, counts up to 65535).
`ValidStream` therefore re-checks `Wf` operationally, exactly as at
R1/R2. -/

/-! ## Stream validity (operational form) and the model-∀ ↔ stream-∀
    bridge (the R1/R2 shape at the list rung) -/

def ValidStream (s : Stream) : Prop :=
  match decodeInput s with
  | some (m, []) => Wf m
  | _ => False

def validStreamb (s : Stream) : Bool :=
  match decodeInput s with
  | some (m, []) => wfb m
  | _ => false

def expectedOfStream (s : Stream) : Stream :=
  match decodeInput s with
  | some (m, []) => expectedBytes m
  | _ => junkExpected

/-- THE BRIDGE at R3: model-∀ and stream-∀ are interderivable —
costing exactly the two codec laws (conditional `RoundTrip` +
unconditional `Canonical`), now through a TWO-CODEC sequence. -/
theorem model_forall_iff_stream_forall (P : Stream → Stream → Prop) :
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

/-! ## Plant models (pure-side predicted verdicts).

TWO plants at R3 (the first structure rung wants both break classes):

  * WRONG-LINK (`xs->tail = ys` instead of `= new_tail`): a LINK
    break. Result `[xs₀] ++ ys` — the recursion still runs, but every
    deeper xs node is ORPHANED (unreachable from the result): the
    plant both breaks the observation AND leaks (`xs.length - 1`
    nodes escape the teardown walk), which is what arms the leak
    observable's red lane. Verdict signature: STRUCTURAL breaks land
    in the LENGTH arm (255) — the serialized count diverges before
    any content index can (measured in the S3 probes; register S3).
    BLIND SPOTS (documented, demonstrated as green twins): xs = []
    (else-branch never runs) and xs.length = 1 (`xs->tail = ys` IS
    correct for a singleton).
  * WRONG-ELEMENT (`xs->head = xs->head ^ 1` planted in the else
    branch): a CONTENT break — every xs head's low bit flips (XOR
    keeps the plant UB-free at every input, unlike `+ 1` at
    INT_MAX). Verdict 3 whenever xs ≠ [] (observation byte 2 =
    element 0's low byte). BLIND SPOT: xs = [].
-/

/-- The wrong-link plant's result model. -/
def linkSkipModel (m : Input) : List Int :=
  match m.xs with
  | [] => m.ys
  | x :: _ => x :: m.ys

/-- Predicted wrong-link verdict (`DivMod.verdictOf` — the shared
mismatch-index mirror). 255 for xs.length ≥ 2, 0 (blind) otherwise. -/
def linkPlantVerdict (m : Input) : Nat :=
  DivMod.verdictOf (encodeResult (linkSkipModel m)) (expectedBytes m)

/-- Orphaned-node count of the wrong-link plant (the leak
observable's pure face): every xs node except the first escapes the
teardown walk. -/
def linkPlantLeaked (m : Input) : Nat := m.xs.length - 1

/-- Low-bit flip on a two's-complement int (the C `^ 1` mirror; total,
range-preserving — evens up, odds down, including negatives). -/
def xorOne (x : Int) : Int := if x % 2 = 0 then x + 1 else x - 1

/-- The wrong-element plant's result model. -/
def elemPlantModel (m : Input) : List Int :=
  m.xs.map xorOne ++ m.ys

/-- Predicted wrong-element verdict: 3 for xs ≠ [], 0 (blind) at
xs = []. -/
def elemPlantVerdict (m : Input) : Nat :=
  DivMod.verdictOf (encodeResult (elemPlantModel m)) (expectedBytes m)

/-! ## The pointer-selection prototype's model (spec register S3:
    the interior-pointer idiom for R4 — choices select an INDEX, the
    harness walks its own built list and hands the target the interior
    pointer it arrives at; pointer values never enter the stream). -/

/-- Pointer-selection model: `(k, xs, ys)` with `k < xs.length`; the
target is called at node k, so the result seen from there is
`drop k xs ++ ys`. -/
structure AtInput where
  k : Nat
  xs : List Int
  ys : List Int
  deriving Repr, DecidableEq

def AtWf (m : AtInput) : Prop :=
  m.k < m.xs.length ∧ Wf ⟨m.xs, m.ys⟩ ∧ m.k < 256

instance (m : AtInput) : Decidable (AtWf m) := by
  unfold AtWf; infer_instance

def atWfb (m : AtInput) : Bool := decide (AtWf m)

def atModelFn (m : AtInput) : List Int := m.xs.drop m.k ++ m.ys

/-- Pointer-selection stream: u8 index prefix + the pair codec. -/
def encodeAtInput (m : AtInput) : Stream :=
  UInt8.ofNat m.k :: encodeInput ⟨m.xs, m.ys⟩

def atExpectedBytes (m : AtInput) : Stream :=
  encodeResult (atModelFn m)

/-! ## P5 pure-transport layer (proof register S3-P5): the CN
    postcondition's pure content -/

/-- CN `L3 == append(L1, L2)`, pure face: DEFINITIONAL — the model IS
the CN append (the R2 collapse finding again, now at a heap
structure: for a structure-building mutator whose contract is a pure
recursive function, the pure layer holds only codec + comparator
algebra; the property weight sits in the exec bridge). -/
theorem append_is_model (m : Input) : modelFn m = m.xs ++ m.ys := rfl

/-- Result length additivity (the serialized count byte's pure
face). -/
theorem modelFn_length (m : Input) :
    (modelFn m).length = m.xs.length + m.ys.length := by
  simp [modelFn]

/-- Wf models fit the observation walk cap (the 253 overlong arm is
unreachable on healthy instances). -/
theorem modelFn_fits (m : Input) (h : Wf m) :
    (modelFn m).length ≤ capTotal := by
  obtain ⟨h1, h2, -, -⟩ := h
  unfold capN at h1 h2
  simp only [modelFn_length]
  unfold capTotal
  omega

/-- Result elements stay in range (readback exactness: every head the
walker re-encodes is a canonical i32 image). -/
theorem modelFn_inRange (m : Input) (h : Wf m) :
    ∀ a ∈ modelFn m, DivMod.inI32 a := by
  obtain ⟨-, -, hr1, hr2⟩ := h
  intro a ha
  rcases List.mem_append.mp ha with h1 | h2
  · exact hr1 a h1
  · exact hr2 a h2

/-- THE LEAK CONJUNCT'S PURE FACE — allocation/free balance: the
harness allocates one node per input element and its teardown walk
frees one node per RESULT element; for the healthy target these
counts agree (append REUSES every node: nothing to leak, nothing to
double-free). The exec-level twin (final allocation map at the
driver's baseline) is stated in SpecLab/ListAppendFiles.lean and
checked executably by the gate exe. -/
theorem alloc_free_balance (m : Input) :
    m.xs.length + m.ys.length = (modelFn m).length := by
  simp [modelFn]

/-- The wrong-link plant UNBALANCES the walk: its result drops
`xs.length - 1` nodes from the teardown (the leak lane's pure
prediction). -/
theorem linkSkip_leaks (m : Input) (h : m.xs ≠ []) :
    m.xs.length + m.ys.length
      = (linkSkipModel m).length + linkPlantLeaked m := by
  match hm : m.xs with
  | [] => exact absurd hm h
  | x :: rest => simp [linkSkipModel, hm, linkPlantLeaked]; omega

/-- xorOne is range-preserving (the wrong-element plant is a DEFINED
program at every stream — the harnesses-are-programs floor under
which `^ 1` was chosen over `+ 1`). -/
theorem xorOne_inRange (x : Int) (h : DivMod.inI32 x) :
    DivMod.inI32 (xorOne x) := by
  unfold DivMod.inI32 DivMod.i32Min DivMod.i32Max at *
  unfold xorOne
  split <;> omega

/-- xorOne always flips the low wire byte — the wrong-element plant
can never hide behind the codec (verdict 3 is structurally forced for
xs ≠ []; the pure justification of the plant's predicted index). -/
theorem xorOne_ne (x : Int) : xorOne x ≠ x := by
  unfold xorOne
  split <;> omega

/-! ## Sample sets (the sweep's edge models, pure-side) -/

/-- Boundary heads: 0, ±1, i32 extremes, near-extremes, a mid ramp
seed. -/
def edgeHeads : List Int :=
  [0, 1, -1, 2147483647, -2147483648, 2147483646, -2147483647, 123456789]

/-- Content patterns at a given length: zeros, all −1, positive ramp,
boundary alternation, descending ramp (adjacent-value shapes). -/
def patterns (n : Nat) : List (List Int) :=
  [List.replicate n 0,
   List.replicate n (-1),
   (List.range n).map (fun i => Int.ofNat i + 1),
   (List.range n).map (fun i => edgeHeads.getD (i % 8) 0),
   (List.range n).map (fun i => Int.ofNat n - Int.ofNat i)]

/-- Length pairs: all of {0,1,2,3,8}² — empty/singleton boundaries,
the pinned statement shape (2,1), and the (8,8) capacity corner. -/
def lengthPairs : List (Nat × Nat) :=
  [0, 1, 2, 3, 8].flatMap (fun a => [0, 1, 2, 3, 8].map fun b => (a, b))

/-- The sweep sample set: 25 length pairs × 5 pattern pairings = 125
models (patterns applied to both lists — equal lengths give the
VALUE-ALIASING shape ys = xs, the aliasing-adjacent family the codec
can express; genuine pointer aliasing is not expressible by
construction — separate builders — recorded in the register). -/
def sweepSamples : List Input :=
  lengthPairs.flatMap fun (n1, n2) =>
    (patterns n1).zip (patterns n2) |>.map fun (xs, ys) => ⟨xs, ys⟩

/-- Pointer-selection differential samples (the prototype lane):
walk indexes at the front/middle/back of each shape. -/
def atSamples : List AtInput :=
  [⟨0, [1], []⟩, ⟨0, [5, 6], [7]⟩, ⟨1, [5, 6], [7]⟩,
   ⟨1, [1, 2, 3], [9]⟩, ⟨2, [1, 2, 3], [9]⟩,
   ⟨0, [-1, 0, 1], [2147483647, -2147483648]⟩,
   ⟨2, [-1, 0, 1], [2147483647, -2147483648]⟩,
   ⟨7, [1, 2, 3, 4, 5, 6, 7, 8], [9, 10]⟩,
   ⟨3, [0, 0, 0, 0], []⟩,
   ⟨1, [2147483647, 2147483646], [-2147483648]⟩]

end ListAppend
end SpecLab
