/-
SpecLab.TreeRot — arc-15 S4 (R4, the tree rung — THE REFERENCE
INSTANCE of the harness statement template): binary-tree right
rotation at a path-selected node, and its model layer.

TARGET (FRESH AUTHORSHIP — the corpus reasoning, recorded):
deps/cn/tests/cn contains NO rotation target. The corpus's tree family
is {tree_rev01.c (struct tree_node {int v; left; right} + rev_tree, a
mirror mutator), tree16/* (16-ary tree, partial-map/datatype specs)} —
searched 2026-08-23, zero `rotate` hits. The R4 target
`rotate_right` is therefore written fresh for this rung (the
operator's own worked example from the design discussion); the struct
shape follows the corpus's int-binary-tree reference
(tree_rev01.c's {int; left; right}), renamed to the charter's
`struct node { int val; struct node *left; struct node *right; }`.
The full C listing lives in SpecLab/TreeRotHarness.lean.

THE ROTATION (the classic right rotation at t):

        t             l
       / \           / \
      l   r   ==>  ll   t
     / \               / \
    ll  lr            lr  r

Total: identity when t is null or t->left is null (off-shape). The
harness reaches t by walking a PATH through its own built tree and
hands the target THE INTERIOR POINTER it arrives at (the S3
pointer-selection prototype, promoted here to a statement family:
the path is part of the model and the choice stream).

PURE MODEL: `Tree` (leaf/node — first-order inductive), `Path = List
Bool` (false = left), `rotateAt : Tree → Path → Tree` TOTAL —
identity off-shape (walking into a leaf, or a locus with no left
child, changes nothing; mirrors the C exactly because every locus
operation fixes the null tree). `modelFn m = rotateAt m.tree m.path`.

CODEC (the operator's presence-bit sketch): pre-order, one presence
byte per position (0 = leaf, 1 = node) with i32le val after each 1 —
self-delimiting; then the path as u8(count) ++ one 0/1 byte per step.
Observation = the post-rotation tree re-encoded with the SAME tree
codec (one wire vocabulary).

House style: computable pure functions + first-order data only.
-/

import SpecLab.Codec
import SpecLab.MkHarness
import SpecLab.DivModHarness

set_option autoImplicit false

namespace SpecLab
namespace TreeRot

open Codec

/-! ## The model -/

/-- Binary tree with i32-modeled values (the CN-corpus int-binary-tree
shape, `tree_rev01.c` lineage). -/
inductive Tree where
  | leaf
  | node (val : Int) (left right : Tree)
  deriving Repr, DecidableEq

/-- Rotation-locus paths: `false` = left, `true` = right. -/
abbrev Path := List Bool

/-- Node count. -/
def Tree.size : Tree → Nat
  | .leaf => 0
  | .node _ l r => 1 + l.size + r.size

/-- All vals in i32 range (Bool mirror, decidable by construction). -/
def Tree.valsOk : Tree → Bool
  | .leaf => true
  | .node v l r => decide (DivMod.inI32 v) && l.valsOk && r.valsOk

/-- Pre-order val list (the parametric statement family's index — the
order the wire bytes appear in `encodeTree`). -/
def Tree.preorderVals : Tree → List Int
  | .leaf => []
  | .node v l r => v :: (l.preorderVals ++ r.preorderVals)

/-! ## Capacities and well-formedness -/

/-- Node capacity (the template's scan/serialize cap). -/
def capN : Nat := 31

/-- Path-step capacity. -/
def capP : Nat := 8

/-- The model: a tree and a rotation-locus path (the two IN-STREAM
dimensions of the harness family). -/
structure Input where
  tree : Tree
  path : Path
  deriving Repr, DecidableEq

/-- Well-formedness: the tree fits the builder cap, every val in i32
range, the path fits the path cap. WF HONESTY (S1-E3 shape): the
capacity bounds are OURS (closed-program realization must build the
trees it quantifies over — the registered concrete-N ceiling); the
i32 range is the struct's own `int val`. The path is NOT required to
be in-shape: off-shape paths are LIVE instances (rotation is
identity there — the model is total and the sweep exercises them). -/
def Wf (m : Input) : Prop :=
  m.tree.size ≤ capN ∧ m.tree.valsOk = true ∧ m.path.length ≤ capP

instance (m : Input) : Decidable (Wf m) := by
  unfold Wf; infer_instance

def wfb (m : Input) : Bool := decide (Wf m)

/-! ## Rotation (the pure spec) -/

/-- The right rotation at the root — the C target's pure face. Total:
identity off-shape (leaf, or no left child), exactly the target's two
guard returns. -/
def rotateRight : Tree → Tree
  | .node v (.node lv ll lr) r => .node lv ll (.node v lr r)
  | t => t

/-- Apply a locus operation at the end of a path — the pure face of
the harness's parent-link walk (`link = &(*link)->child…; *link =
f(*link)`). Total: walking into a leaf leaves the tree unchanged.
C-MIRROR NOTE: the C walk stops at a null link mid-path and applies
`f` to null; this equals `applyAt` exactly when `f leaf = leaf`,
which holds for the target and both plants (their `t == 0` guards —
witnessed by `rotateRight_leaf` and friends below). -/
def applyAt (f : Tree → Tree) : Tree → Path → Tree
  | t, [] => f t
  | .leaf, _ :: _ => .leaf
  | .node v l r, false :: p => .node v (applyAt f l p) r
  | .node v l r, true :: p => .node v l (applyAt f r p)

/-- `rotateAt`: THE R4 modelFn — right rotation at the path-selected
locus, total (identity off-shape). -/
def rotateAt (t : Tree) (p : Path) : Tree := applyAt rotateRight t p

@[simp] theorem applyAt_nil (f : Tree → Tree) (t : Tree) :
    applyAt f t [] = f t := by cases t <;> rfl

def modelFn (m : Input) : Tree := rotateAt m.tree m.path

theorem rotateRight_leaf : rotateRight .leaf = .leaf := rfl

/-! ## Codec — pre-order presence-bit tree code + path code -/

/-- `encodeTree`: pre-order — `0` for a leaf; `1 ++ i32le(val) ++
left ++ right` for a node. Self-delimiting; nonempty for every tree
(a lone leaf is `[0]` — the S0 empty-initializer caveat closed by
codec design). -/
def encodeTree : Tree → Stream
  | .leaf => [0]
  | .node v l r => 1 :: (DivMod.encodeI32LE v ++ (encodeTree l ++ encodeTree r))

/-- Fuel-indexed tree decoder (fuel bounds the DEPTH of the code —
the house fuel-totalization pattern; `decodeTree` below instantiates
fuel from the stream length, which `treeFuel_le_length` shows is
always enough for genuine encodings). Rejects presence bytes other
than 0/1 (canonicity: every accepted wire image is canonical). -/
def decodeTreeF : Nat → Dec Tree
  | 0, _ => none
  | _ + 1, [] => none
  | f + 1, b :: r =>
    if b = 0 then some (.leaf, r)
    else if b = 1 then
      match DivMod.decodeI32LE r with
      | none => none
      | some (v, s1) =>
        match decodeTreeF f s1 with
        | none => none
        | some (l, s2) =>
          match decodeTreeF f s2 with
          | none => none
          | some (rr, s3) => some (.node v l rr, s3)
    else none

def decodeTree : Dec Tree := fun s => decodeTreeF s.length s

/-- Path step bytes: one byte per step, `0`/`1` only. -/
def pathBytes (p : Path) : Stream :=
  p.map (fun b => if b then (1 : UInt8) else 0)

/-- Path code: u8 count prefix + step bytes. -/
def encodePath (p : Path) : Stream :=
  UInt8.ofNat p.length :: pathBytes p

/-- Count-indexed step decoder (rejects step bytes > 1 —
canonicity). -/
def decodePathSteps : Nat → Dec Path
  | 0, s => some ([], s)
  | _ + 1, [] => none
  | n + 1, b :: r =>
    if b = 0 then
      match decodePathSteps n r with
      | none => none
      | some (p, rest) => some (false :: p, rest)
    else if b = 1 then
      match decodePathSteps n r with
      | none => none
      | some (p, rest) => some (true :: p, rest)
    else none

def decodePath : Dec Path := fun s =>
  match s with
  | [] => none
  | n :: r => decodePathSteps n.toNat r

/-- `encode : M → Stream` — the choice stream: tree first (the
builder consumes it), then the path (the locus walk consumes it). -/
def encodeInput (m : Input) : Stream :=
  encodeTree m.tree ++ encodePath m.path

/-- `decode : Stream → M`. -/
def decodeInput : Dec Input := fun s =>
  match decodeTree s with
  | none => none
  | some (t, s1) =>
    match decodePath s1 with
    | none => none
    | some (p, s2) => some (⟨t, p⟩, s2)

/-- The observation codec = the tree codec (the result tree,
re-serialized by the harness walker exactly as the builder consumed
it — one wire vocabulary). -/
def encodeResult (t : Tree) : Stream := encodeTree t

/-- The pure-side expected observation. -/
def expectedBytes (m : Input) : Stream := encodeResult (modelFn m)

/-- Malformed-splice junk expected (a lone leaf): nonempty by
construction. -/
def junkExpected : Stream := [0]

/-! ## Round trip (decode ∘ encode = id) -/

/-- Depth fuel of a tree's encoding (what `decodeTreeF` needs). -/
def treeFuel : Tree → Nat
  | .leaf => 1
  | .node _ l r => 1 + max (treeFuel l) (treeFuel r)

theorem encodeI32LE_length (n : Int) : (DivMod.encodeI32LE n).length = 4 := by
  simp [DivMod.encodeI32LE, encodeU32LE, encodeU16LE]

theorem encodeTree_length (t : Tree) :
    (encodeTree t).length = 6 * t.size + 1 := by
  induction t with
  | leaf => rfl
  | node v l r ihl ihr =>
    simp only [encodeTree, Tree.size, List.length_cons, List.length_append,
      encodeI32LE_length, ihl, ihr]
    omega

theorem treeFuel_le_length (t : Tree) :
    treeFuel t ≤ (encodeTree t).length := by
  induction t with
  | leaf => simp [treeFuel, encodeTree]
  | node v l r ihl ihr =>
    simp only [treeFuel, encodeTree, List.length_cons, List.length_append,
      encodeI32LE_length]
    omega

/-- Fuel monotonicity (more fuel never changes an accepting run). -/
theorem decodeTreeF_mono (f : Nat) : ∀ (f' : Nat), f ≤ f' →
    ∀ (s : Stream) (t : Tree) (rest : Stream),
      decodeTreeF f s = some (t, rest) → decodeTreeF f' s = some (t, rest) := by
  induction f with
  | zero => intro f' _ s t rest h; simp [decodeTreeF] at h
  | succ fn ih =>
    intro f' hle s t rest h
    obtain ⟨fn', rfl⟩ : ∃ k, f' = k + 1 := ⟨f' - 1, by omega⟩
    have hfn : fn ≤ fn' := by omega
    match s with
    | [] => simp [decodeTreeF] at h
    | b :: r =>
      simp only [decodeTreeF] at h ⊢
      split at h
      next hb0 => rw [if_pos hb0]; exact h
      next hb0 =>
        rw [if_neg hb0]
        split at h
        next hb1 =>
          rw [if_pos hb1]
          split at h
          next => cases h
          next v s1 hd =>
            split at h
            next => cases h
            next l s2 hl =>
              simp only [ih fn' hfn s1 l s2 hl]
              split at h
              next => cases h
              next rr s3 hr =>
                simp only [ih fn' hfn s2 rr s3 hr]
                exact h
        next hb1 => cases h

/-- The fueled round trip: `treeFuel t` fuel decodes `encodeTree t`
back exactly, for in-range vals. -/
theorem decodeTreeF_encode (t : Tree) (hv : t.valsOk = true) :
    ∀ (f : Nat), treeFuel t ≤ f → ∀ (rest : Stream),
      decodeTreeF f (encodeTree t ++ rest) = some (t, rest) := by
  induction t with
  | leaf =>
    intro f hf rest
    obtain ⟨fn, rfl⟩ : ∃ k, f = k + 1 := ⟨f - 1, by unfold treeFuel at hf; omega⟩
    simp [encodeTree, decodeTreeF]
  | node v l r ihl ihr =>
    intro f hf rest
    obtain ⟨fn, rfl⟩ : ∃ k, f = k + 1 := ⟨f - 1, by unfold treeFuel at hf; omega⟩
    simp only [Tree.valsOk, Bool.and_eq_true, decide_eq_true_eq] at hv
    obtain ⟨⟨hvr, hvl'⟩, hvr'⟩ := hv
    have hfl : treeFuel l ≤ fn := by unfold treeFuel at hf; omega
    have hfr : treeFuel r ≤ fn := by unfold treeFuel at hf; omega
    simp only [encodeTree, List.cons_append, List.append_assoc, decodeTreeF,
      if_true]
    simp only
      [DivMod.decode_encode_i32le v hvr (encodeTree l ++ (encodeTree r ++ rest)),
      ihl hvl' fn hfl (encodeTree r ++ rest), ihr hvr' fn hfr rest]
    rw [if_neg (by decide)]

/-- decode ∘ encode = id at the tree layer (self-fuel form). -/
theorem decode_encode_tree (t : Tree) (hv : t.valsOk = true)
    (rest : Stream) :
    decodeTree (encodeTree t ++ rest) = some (t, rest) := by
  unfold decodeTree
  apply decodeTreeF_encode t hv
  calc treeFuel t ≤ (encodeTree t).length := treeFuel_le_length t
    _ ≤ (encodeTree t ++ rest).length := by simp

theorem decodePathSteps_encode (p : Path) : ∀ (rest : Stream),
    decodePathSteps p.length (pathBytes p ++ rest) = some (p, rest) := by
  induction p with
  | nil => intro rest; rfl
  | cons b bs ih =>
    intro rest
    have ih' := ih rest
    simp only [pathBytes] at ih' ⊢
    cases b <;> simp [decodePathSteps, ih']

theorem decode_encode_path (p : Path) (hlen : p.length ≤ capP)
    (rest : Stream) :
    decodePath (encodePath p ++ rest) = some (p, rest) := by
  have h256 : p.length < 256 := by unfold capP at hlen; omega
  have : (UInt8.ofNat p.length).toNat = p.length := by
    simp; omega
  simp [decodePath, encodePath, this, decodePathSteps_encode p rest]

theorem decode_encode_input (m : Input) (h : Wf m) (rest : Stream) :
    decodeInput (encodeInput m ++ rest) = some (m, rest) := by
  obtain ⟨_, hv, hp⟩ := h
  simp only [decodeInput, encodeInput, List.append_assoc,
    decode_encode_tree m.tree hv (encodePath m.path ++ rest),
    decode_encode_path m.path hp rest]

/-! ## Canonicity (encode ∘ decode = id on consumed prefixes — the
    bridge's model→stream half, the S1-E2 `Canonical` contract) -/

theorem encode_decodeTreeF (f : Nat) : ∀ (s : Stream) (t : Tree)
    (rest : Stream), decodeTreeF f s = some (t, rest) →
    s = encodeTree t ++ rest := by
  induction f with
  | zero => intro s t rest h; simp [decodeTreeF] at h
  | succ fn ih =>
    intro s t rest h
    match s with
    | [] => simp [decodeTreeF] at h
    | b :: r =>
      simp only [decodeTreeF] at h
      split at h
      next hb0 =>
        cases h
        simp [encodeTree, hb0]
      next hb0 =>
        split at h
        next hb1 =>
          split at h
          next => cases h
          next v s1 hd =>
            split at h
            next => cases h
            next l s2 hl =>
              split at h
              next => cases h
              next rr s3 hr =>
                cases h
                have e1 := DivMod.encode_decode_i32le' r s1 v hd
                have e2 := ih s1 l s2 hl
                have e3 := ih s2 rr _ hr
                simp [encodeTree, hb1, e1, e2, e3]
        next hb1 => cases h

/-- Tree-codec canonicity. -/
theorem canonical_tree : Canonical encodeTree decodeTree :=
  fun s t rest h => encode_decodeTreeF s.length s t rest h

theorem decodePathSteps_spec (n : Nat) : ∀ (s : Stream) (p : Path)
    (rest : Stream), decodePathSteps n s = some (p, rest) →
    p.length = n ∧ s = pathBytes p ++ rest := by
  induction n with
  | zero =>
    intro s p rest h
    obtain ⟨rfl, rfl⟩ : p = [] ∧ s = rest := by cases h; exact ⟨rfl, rfl⟩
    simp [pathBytes]
  | succ k ih =>
    intro s p rest h
    match s with
    | [] => simp [decodePathSteps] at h
    | b :: r =>
      simp only [decodePathSteps] at h
      split at h
      next hb0 =>
        split at h
        next => cases h
        next p' rest' hd =>
          cases h
          obtain ⟨hl, hs⟩ := ih r p' _ hd
          simp [pathBytes, hl, hb0, hs]
      next hb0 =>
        split at h
        next hb1 =>
          split at h
          next => cases h
          next p' rest' hd =>
            cases h
            obtain ⟨hl, hs⟩ := ih r p' _ hd
            simp [pathBytes, hl, hb1, hs]
        next hb1 => cases h

/-- Path-codec canonicity. -/
theorem canonical_path : Canonical encodePath decodePath := by
  intro s p rest h
  match s with
  | [] => simp [decodePath] at h
  | n :: r =>
    simp only [decodePath] at h
    obtain ⟨hl, hs⟩ := decodePathSteps_spec n.toNat r p rest h
    have hn : UInt8.ofNat p.length = n := by
      rw [hl]; exact UInt8.ofNat_toNat
    simp [encodePath, hs, hn]

/-- Input canonicity: a fully consumed stream IS the encoding of its
decode. -/
theorem encode_decode_input (s : Stream) (m : Input)
    (h : decodeInput s = some (m, [])) : s = encodeInput m := by
  cases hx : decodeTree s with
  | none => simp [decodeInput, hx] at h
  | some p =>
    obtain ⟨t, s1⟩ := p
    cases hy : decodePath s1 with
    | none => simp [decodeInput, hx, hy] at h
    | some q =>
      obtain ⟨pa, s2⟩ := q
      simp only [decodeInput, hx, hy, Option.some.injEq,
        Prod.mk.injEq] at h
      obtain ⟨hm, hs2⟩ := h
      rw [hs2] at hy
      have h1 := canonical_tree s t s1 hx
      have h2 := canonical_path s1 pa [] hy
      rw [h1, h2, ← hm]
      simp [encodeInput]

/-! ## Stream validity (operational form) and the model-∀ ↔ stream-∀
    bridge (the R1-R3 shape at the tree rung) -/

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

/-- THE BRIDGE at R4: model-∀ and stream-∀ are interderivable —
costing exactly the two codec laws (conditional `RoundTrip` +
unconditional `Canonical`), now through a RECURSIVE self-delimiting
code (the S1-S3 proof shape survived the tree unchanged). -/
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

TWO plants at R4 (the charter-named pair):

  * WRONG-CHILD-SWAP (`t->left = t->right; t->right = l` — the target
    swaps the locus's children instead of rotating): a CONTENT/
    STRUCTURE break with NO leak (every node stays reachable —
    demonstrated by the gate's baseline leak check on the swap-plant
    instance: a broken-but-leak-free target). BLIND SPOTS
    (documented, demonstrated as green twins): the self-similar locus
    `node a (node a X X') X` with X = X' — concretely
    `node a (node a L L) L`, where swap and rotation coincide — and
    every off-shape locus (both variants keep the `t == 0` /
    `t->left == 0` guards).
  * DROPPED-SUBTREE (`t->left = 0` instead of `t->left = l->right`):
    the rotation's transferred middle subtree `lr` is ORPHANED —
    breaks the observation (a diverging node count lands in the 255
    length arm whenever `lr ≠ leaf`) AND leaks exactly `lr.size`
    nodes: THE LEAK ARM'S RED WITNESS. BLIND SPOT: `lr = leaf`
    (dropping an already-null pointer is the healthy assignment).
-/

/-- The wrong-child-swap plant's locus operation (guards mirror the
target: identity on leaf and on no-left-child). -/
def swapPlantOp : Tree → Tree
  | .node v (.node lv ll lr) r => .node v r (.node lv ll lr)
  | t => t

/-- The dropped-subtree plant's locus operation (`t->left = 0`
drops `lr`). -/
def dropPlantOp : Tree → Tree
  | .node v (.node lv ll _) r => .node lv ll (.node v .leaf r)
  | t => t

theorem swapPlantOp_leaf : swapPlantOp .leaf = .leaf := rfl
theorem dropPlantOp_leaf : dropPlantOp .leaf = .leaf := rfl

def swapPlantModel (m : Input) : Tree := applyAt swapPlantOp m.tree m.path
def dropPlantModel (m : Input) : Tree := applyAt dropPlantOp m.tree m.path

/-- Predicted wrong-child-swap verdict (`DivMod.verdictOf` — the
shared mismatch-index mirror; 0 exactly on the documented blind
spots). -/
def swapPlantVerdict (m : Input) : Nat :=
  DivMod.verdictOf (encodeResult (swapPlantModel m)) (expectedBytes m)

/-- Predicted dropped-subtree verdict (255 length arm whenever the
dropped subtree is nonempty). -/
def dropPlantVerdict (m : Input) : Nat :=
  DivMod.verdictOf (encodeResult (dropPlantModel m)) (expectedBytes m)

/-- Size of the subtree the drop plant orphans: `lr` at the locus (0
off-shape). The leak observable's pure face. -/
def orphanedAt : Tree → Path → Nat
  | t, [] =>
    (match t with
     | .node _ (.node _ _ lr) _ => lr.size
     | _ => 0)
  | .leaf, _ :: _ => 0
  | .node _ l _, false :: p => orphanedAt l p
  | .node _ _ r, true :: p => orphanedAt r p

def dropPlantLeaked (m : Input) : Nat := orphanedAt m.tree m.path

/-! ## P5 pure-transport layer (proof register S4-P5) -/

/-- Rotation preserves the node count — ALLOCATION NEUTRALITY, the
leak conjunct's pure face: the healthy harness frees exactly what it
allocated because rotation neither creates nor orphans nodes. -/
theorem rotateRight_size (t : Tree) : (rotateRight t).size = t.size := by
  match t with
  | .leaf => rfl
  | .node v .leaf r => rfl
  | .node v (.node lv ll lr) r => simp [rotateRight, Tree.size]; omega

theorem applyAt_size (f : Tree → Tree)
    (hf : ∀ t, (f t).size = t.size) :
    ∀ (t : Tree) (p : Path), (applyAt f t p).size = t.size := by
  intro t p
  induction p generalizing t with
  | nil => rw [applyAt_nil]; exact hf t
  | cons b p ih =>
    match t, b with
    | .leaf, _ => rfl
    | .node v l r, false => simp [applyAt, Tree.size, ih l]
    | .node v l r, true => simp [applyAt, Tree.size, ih r]

theorem rotateAt_size (t : Tree) (p : Path) :
    (rotateAt t p).size = t.size :=
  applyAt_size rotateRight rotateRight_size t p

/-- The swap plant is ALSO size-preserving — broken but leak-free
(the gate demonstrates the pair: content break without leak vs
structure break with leak). -/
theorem swapPlantOp_size (t : Tree) : (swapPlantOp t).size = t.size := by
  match t with
  | .leaf => rfl
  | .node v .leaf r => rfl
  | .node v (.node lv ll lr) r => simp [swapPlantOp, Tree.size]; omega

theorem swapPlant_size (m : Input) :
    (swapPlantModel m).size = m.tree.size :=
  applyAt_size swapPlantOp swapPlantOp_size m.tree m.path

/-- The drop plant's size accounting: result size + orphaned count =
input size (the leak lane's pure prediction — the gate's measured
`baseline + 1` at the pinned instance is this theorem's instance at
`lr = node d leaf leaf`). -/
theorem dropPlant_size : ∀ (t : Tree) (p : Path),
    (applyAt dropPlantOp t p).size + orphanedAt t p = t.size := by
  intro t p
  induction p generalizing t with
  | nil =>
    match t with
    | .leaf => rfl
    | .node v .leaf r => rfl
    | .node v (.node lv ll lr) r =>
      simp [applyAt, dropPlantOp, orphanedAt, Tree.size]; omega
  | cons b p ih =>
    match t, b with
    | .leaf, _ => rfl
    | .node v l r, false => simp [applyAt, orphanedAt, Tree.size, ← ih l]; omega
    | .node v l r, true => simp [applyAt, orphanedAt, Tree.size, ← ih r]; omega

/-- Rotation permutes vals: range-ok is preserved (readback
exactness — every val the walker re-encodes is a canonical i32
image). -/
theorem rotateRight_valsOk (t : Tree) :
    (rotateRight t).valsOk = t.valsOk := by
  match t with
  | .leaf => rfl
  | .node v .leaf r => rfl
  | .node v (.node lv ll lr) r =>
    simp only [rotateRight, Tree.valsOk]
    generalize decide (DivMod.inI32 v) = a
    generalize decide (DivMod.inI32 lv) = b
    generalize Tree.valsOk ll = c
    generalize Tree.valsOk lr = d
    generalize Tree.valsOk r = e
    cases a <;> cases b <;> cases c <;> cases d <;> cases e <;> rfl

theorem applyAt_valsOk (f : Tree → Tree)
    (hf : ∀ t, (f t).valsOk = t.valsOk) :
    ∀ (t : Tree) (p : Path), (applyAt f t p).valsOk = t.valsOk := by
  intro t p
  induction p generalizing t with
  | nil => rw [applyAt_nil]; exact hf t
  | cons b p ih =>
    match t, b with
    | .leaf, _ => rfl
    | .node v l r, false => simp [applyAt, Tree.valsOk, ih l]
    | .node v l r, true => simp [applyAt, Tree.valsOk, ih r]

theorem rotateAt_valsOk (t : Tree) (p : Path) :
    (rotateAt t p).valsOk = t.valsOk :=
  applyAt_valsOk rotateRight rotateRight_valsOk t p

/-- Wf models' observations fit the harness's `out[]` (187 = the
31-node ceiling's encoding; the S3-E5 capacity-corner lesson made a
pure lemma — the sweep's 31-node sample exercises the bound live). -/
theorem expectedBytes_fits (m : Input) (h : Wf m) :
    (expectedBytes m).length ≤ 187 := by
  obtain ⟨hn, _, _⟩ := h
  unfold capN at hn
  simp only [expectedBytes, encodeResult, encodeTree_length, modelFn,
    rotateAt_size]
  omega

/-! ### The S4-E1 experiment: "rest of the tree unchanged", stated
    two ways.

Way 1 (THE STATEMENT, Form 1): full-tree readback equality — the
observation IS `encodeTree (rotateAt tree path)`, one index space,
no locus vocabulary (what the harness statements below the fold
use).

Way 2 (the decomposed reading): rotation = "the locus subtree is
rotated" + "the remainder is untouched", via `subtreeAt`/`replaceAt`.
Both directions are kernel lemmas HERE, in pure land — the register
entry (S4-E1) grades which reads better as a spec and where each
belongs. -/

/-- The subtree at a path (leaf off-shape — total). -/
def subtreeAt : Tree → Path → Tree
  | t, [] => t
  | .leaf, _ :: _ => .leaf
  | .node _ l _, false :: p => subtreeAt l p
  | .node _ _ r, true :: p => subtreeAt r p

/-- Replace the subtree at a path (identity off-shape — total). -/
def replaceAt : Tree → Path → Tree → Tree
  | _, [], s => s
  | .leaf, _ :: _, _ => .leaf
  | .node v l r, false :: p, s => .node v (replaceAt l p s) r
  | .node v l r, true :: p, s => .node v l (replaceAt r p s)

@[simp] theorem subtreeAt_nil (t : Tree) : subtreeAt t [] = t := by
  cases t <;> rfl

@[simp] theorem replaceAt_nil (t s : Tree) : replaceAt t [] s = s := by
  cases t <;> rfl

/-- DECOMPOSITION (way 2, half 1): rotation at a path IS "replace the
locus subtree by its rotation" — unconditional (off-shape both sides
are identity). -/
theorem applyAt_as_replace (f : Tree → Tree) : ∀ (t : Tree) (p : Path),
    applyAt f t p = replaceAt t p (f (subtreeAt t p)) := by
  intro t p
  induction p generalizing t with
  | nil => simp
  | cons b p ih =>
    match t, b with
    | .leaf, _ => rfl
    | .node v l r, false => simp [applyAt, subtreeAt, replaceAt, ih l]
    | .node v l r, true => simp [applyAt, subtreeAt, replaceAt, ih r]

theorem rotateAt_as_replace (t : Tree) (p : Path) :
    rotateAt t p = replaceAt t p (rotateRight (subtreeAt t p)) :=
  applyAt_as_replace rotateRight t p

/-- FRAME (way 2, half 2): every subtree on a path DIVERGING from the
rotation path is untouched — "the rest of the tree unchanged" as a
theorem about `subtreeAt`. -/
theorem applyAt_frame (f : Tree → Tree) :
    ∀ (p q : Path) (t : Tree), ¬ p <+: q → ¬ q <+: p →
      subtreeAt (applyAt f t p) q = subtreeAt t q := by
  intro p
  induction p with
  | nil => intro q t hpq _; exact absurd (List.nil_prefix) hpq
  | cons b p ih =>
    intro q t hpq hqp
    match q with
    | [] => exact absurd (List.nil_prefix) hqp
    | c :: q' =>
      match t with
      | .leaf =>
        cases b <;> simp [applyAt, subtreeAt]
      | .node v l r =>
        by_cases hbc : b = c
        · subst hbc
          have hpq' : ¬ p <+: q' := fun h => hpq (List.cons_prefix_cons.mpr ⟨rfl, h⟩)
          have hqp' : ¬ q' <+: p := fun h => hqp (List.cons_prefix_cons.mpr ⟨rfl, h⟩)
          cases b <;> simp [applyAt, subtreeAt, ih q' _ hpq' hqp']
        · cases b <;> cases c <;> simp_all [applyAt, subtreeAt]

theorem rotateAt_frame (p q : Path) (t : Tree)
    (h1 : ¬ p <+: q) (h2 : ¬ q <+: p) :
    subtreeAt (rotateAt t p) q = subtreeAt t q :=
  applyAt_frame rotateRight p q t h1 h2

/-! ## Sample sets (the sweep's edge models, pure-side) -/

/-- Boundary heads (the S3 edge set). -/
def edgeHeads : List Int :=
  [0, 1, -1, 2147483647, -2147483648, 2147483646, -2147483647, 123456789]

/-- Content patterns as pre-order index → val functions: zeros, all
−1, positive ramp, boundary alternation, descending ramp. -/
def patternFns : List (Nat → Int) :=
  [fun _ => 0, fun _ => -1, fun i => Int.ofNat i + 1,
   fun i => edgeHeads.getD (i % 8) 0, fun i => 31 - Int.ofNat i]

/-- Left spine of n nodes (vals by pre-order index from k). -/
def lspineT : Nat → Nat → (Nat → Int) → Tree
  | 0, _, _ => .leaf
  | n + 1, k, f => .node (f k) (lspineT n (k + 1) f) .leaf

/-- Right spine of n nodes. -/
def rspineT : Nat → Nat → (Nat → Int) → Tree
  | 0, _, _ => .leaf
  | n + 1, k, f => .node (f k) .leaf (rspineT n (k + 1) f)

/-- Complete tree of depth d (heap-indexed vals from k). -/
def completeT : Nat → Nat → (Nat → Int) → Tree
  | 0, _, _ => .leaf
  | d + 1, k, f =>
    .node (f k) (completeT d (2 * k + 1) f) (completeT d (2 * k + 2) f)

/-- Zig-zag chain of n nodes (alternating left/right). -/
def zigzagT : Nat → Bool → Nat → (Nat → Int) → Tree
  | 0, _, _, _ => .leaf
  | n + 1, goLeft, k, f =>
    if goLeft then .node (f k) (zigzagT n false (k + 1) f) .leaf
    else .node (f k) .leaf (zigzagT n true (k + 1) f)

/-- THE PINNED SHAPE (the worked example's depth-3 asymmetric tree —
the rotation locus at path [l] has a genuine transferred middle
subtree D):

          a
         / \
        b   f          rotateAt [l]:    a
       / \             the locus b     / \
      c   e            rotates to     c   f
       \                             / \
        d                           …   b
                                       / \
                                      d   e
-/
def pinnedShape (a b c d e f : Int) : Tree :=
  .node a
    (.node b (.node c .leaf (.node d .leaf .leaf)) (.node e .leaf .leaf))
    (.node f .leaf .leaf)

/-- The pinned rotation path (locus = the root's left child b). -/
def pinnedPath : Path := [false]

/-- Shape × path cases per content pattern: depths 0-4, degenerate
spines both ways, complete trees up to the 31-node capacity corner,
zig-zags, the pinned shape — with root paths, deep in-shape paths,
and OFF-SHAPE paths (walking into a leaf / past a leaf / rotating a
no-left-child locus: all identity, all live). -/
def shapePathCases (f : Nat → Int) : List Input :=
  [⟨.leaf, []⟩, ⟨.leaf, [false]⟩,
   ⟨.node (f 0) .leaf .leaf, []⟩, ⟨.node (f 0) .leaf .leaf, [true]⟩,
   ⟨lspineT 2 0 f, []⟩, ⟨lspineT 2 0 f, [false]⟩,
   ⟨lspineT 4 0 f, []⟩, ⟨lspineT 4 0 f, [false]⟩,
   ⟨lspineT 4 0 f, [false, false]⟩, ⟨lspineT 4 0 f, [true]⟩,
   ⟨rspineT 4 0 f, []⟩, ⟨rspineT 4 0 f, [true, true]⟩,
   ⟨rspineT 4 0 f, [true, true, true, true]⟩,
   ⟨completeT 2 0 f, []⟩, ⟨completeT 2 0 f, [false]⟩,
   ⟨completeT 2 0 f, [true]⟩,
   ⟨completeT 3 0 f, []⟩, ⟨completeT 3 0 f, [false, true]⟩,
   ⟨completeT 3 0 f, [true, false]⟩,
   ⟨completeT 4 0 f, []⟩, ⟨completeT 4 0 f, [false, false, false]⟩,
   ⟨completeT 5 0 f, []⟩,
   ⟨completeT 5 0 f, [false, false, false, false]⟩,
   ⟨zigzagT 4 true 0 f, []⟩, ⟨zigzagT 4 true 0 f, [false, true]⟩,
   ⟨pinnedShape (f 0) (f 1) (f 2) (f 3) (f 4) (f 5), [false]⟩,
   ⟨pinnedShape (f 0) (f 1) (f 2) (f 3) (f 4) (f 5), []⟩,
   ⟨pinnedShape (f 0) (f 1) (f 2) (f 3) (f 4) (f 5), [false, false]⟩,
   ⟨pinnedShape (f 0) (f 1) (f 2) (f 3) (f 4) (f 5), [true, true, true]⟩]

/-- The sweep sample set: 29 shape×path cases × 5 content patterns =
145 models (incl. two 31-node capacity-corner samples per pattern —
`completeT 5` = a full depth-4 tree = exactly `capN` nodes, with a
depth-4 rotation path). -/
def sweepSamples : List Input :=
  patternFns.flatMap shapePathCases

end TreeRot
end SpecLab
