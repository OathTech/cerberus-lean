# The harness statement template — worked example: tree rotation (R4)

Status: DRAFT worked-example section for the template note
(`notes/2026-08-22_harness-statement-template.md`); S5 folds it in.
Provenance: arc-15 S4 ([AGENT:arc15-laneA-S4], 2026-08-23). All
objects live in `lean_frontend/speclab/` (`SpecLab/TreeRot*.lean`)
and `tests/speclab/rotate_*`; lanes: `scripts/test_speclab_tree.sh`.

This is the template's REFERENCE INSTANCE: every element of the
design — model, codec, builder, path-selected interior pointer,
compiled-in expected array, plants, leak conjunct, parametric
statement family — appears once, in its intended place.

## 1. The target

Fresh C (the deps/cn corpus has no rotation; struct shape follows its
int-binary-tree reference, `tree_rev01.c`):

```c
struct node {
  int val;
  struct node *left;
  struct node *right;
};

struct node* rotate_right(struct node *t)
{
  struct node *l;
  if (t == 0) { return t; }
  if (t->left == 0) { return t; }
  l = t->left;
  t->left = l->right;
  l->right = t;
  return l;
}
```

The classic right rotation — `l` becomes the subtree root, the middle
subtree `l->right` transfers to `t` — total by construction: null or
left-less inputs return unchanged.

## 2. The pure model (the statement's vocabulary)

First-order inductive data and computable functions, nothing else:

```lean
inductive Tree | leaf | node (val : Int) (left right : Tree)
abbrev Path := List Bool          -- false = left, true = right

def rotateRight : Tree → Tree     -- the target's pure face
  | .node v (.node lv ll lr) r => .node lv ll (.node v lr r)
  | t => t                        -- identity off-shape, like the C

def applyAt (f : Tree → Tree) : Tree → Path → Tree   -- the locus walk
  | t, [] => f t
  | .leaf, _ :: _ => .leaf
  | .node v l r, false :: p => .node v (applyAt f l p) r
  | .node v l r, true  :: p => .node v l (applyAt f r p)

def rotateAt (t : Tree) (p : Path) : Tree := applyAt rotateRight t p
```

`rotateAt` is TOTAL — an off-shape path (walking into a leaf, or a
locus with no left child) changes nothing, exactly mirroring the C
below. `Wf` bounds realization only: ≤ 31 nodes, i32 vals, path ≤ 8.
Off-shape paths are inside `Wf` — live instances, not excluded ones.

## 3. The codec (the choice stream's grammar)

Pre-order presence bits, one byte per position, i32le vals; then the
path as a count byte and one 0/1 byte per step:

```
tree  ::=  0x00  |  0x01 val:i32le tree tree      (self-delimiting)
input ::=  tree  plen:u8  step^plen               (step ∈ {0, 1})
```

`decode : Stream → Input` is a fuel-indexed total function;
`decode ∘ encode = id` (Wf-conditioned) and `encode ∘ decode = id` on
accepted prefixes (canonicity — decoders REJECT non-canonical bytes)
are kernel lemmas. Per the free-generator reading, `decode` IS the
tree generator and the fuzz lane samples its input space directly.

## 4. The harness (three phases + verdict; the program family)

`mkHarness` splices `choices[] = encode(input)` and
`expected[] = encodeTree(rotateAt tree path)` — computed PURE-SIDE —
into the fixed template. The main (verbatim, from the pinned
instance; helpers `scan_tree`/`build_tree`/`serialize_tree`/
`free_tree` are the recursive builder/walker idiom trio, ~80 lines,
in the full listing):

```c
int main(void)
{
  unsigned char choices[] = { /* spliced: encode(input) */ };
  unsigned char expected[] = { /* spliced: encode(rotateAt tree path) */ };
  struct node *root;
  struct node **link;
  struct node *newsub;
  unsigned char out[200];
  unsigned long i, cnt, pos, bpos, plen, obs;
  long consumed, j;
  int err;
  /* phase 0 — stream validity (total on any splice; no allocation on
     malformed input): pre-order tree code ++ u8(plen) ++ path bytes */
  cnt = 0u;
  consumed = scan_tree(choices, sizeof(choices), 0u, &cnt);
  if (consumed < 0) { return 254; }
  pos = (unsigned long)consumed;
  if (pos >= sizeof(choices)) { return 254; }
  plen = (unsigned long)choices[pos];
  if (plen > 8u) { return 254; }
  if (sizeof(choices) != pos + 1u + plen) { return 254; }
  for (i = 0u; i < plen; i++) {
    if (choices[pos + 1u + i] > 1u) { return 254; }
  }
  /* phase 1 — build the tree from the stream */
  err = 0;
  bpos = 0u;
  root = build_tree(choices, &bpos, &err);
  if (err != 0) { return err; }
  /* phase 2 — POINTER SELECTION + the call under test: walk the
     built tree along the path; the target gets THE INTERIOR POINTER
     the walk arrives at, and the parent link takes the returned
     subtree root — exactly as a caller of rotate_right would. */
  link = &root;
  for (i = 0u; i < plen && *link != 0; i++) {
    if (choices[pos + 1u + i] == 1u) { link = &(*link)->right; }
    else { link = &(*link)->left; }
  }
  newsub = rotate_right(*link); /* sequenced-call rule (S4-E2) */
  *link = newsub;
  /* phase 3 — WALKER/SERIALIZER (cap-guarded) */
  cnt = 0u;
  j = serialize_tree(root, out, 0, &cnt);
  if (j < 0) { return 253; }
  /* phase 4 — teardown: free the post-state tree */
  free_tree(root);
  /* phase 5 — verdict: generic mismatch-index comparator (Form 1) */
  obs = (unsigned long)j;
  if (sizeof(expected) != obs) { return 255; }
  for (i = 0u; i < obs; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
```

Everything the design note promised is visible: choice resolved
before the program exists; pointer values never in the stream (the
walk manufactures the interior pointer); memory converted to
observables by the program (serialize), never asserted by the
statement; teardown enabling the leak conjunct; a TOTAL verdict space
(0 / 1+i / 252 alloc-refusal / 253 overlong-guard / 254 malformed /
255 length divergence) making every splice a defined program.

One measured C idiom is load-bearing: THE SEQUENCED-CALL RULE — a
deref-store of a call result (`*link = rotate_right(*link)`) is an
unsequenced pair that multiplies exhaustive-mode interleavings
(measured 3 executions per site; compounding, it took a 6-node
instance past a 120s oracle timeout). Call results land in plain
locals; simple-load member stores are fine, so the target stays
untouched.

## 5. The statements (what is actually claimed)

All statements are fuel-opsem-only, gate-enforced; `HarnessRunsTo f v`
= every enumerated outcome of the production driver run of `f` is
`Active (Specified v)`.

* Headline (finite sample form, labeled): ∀ m in the explicit pinned
  sample set, `HarnessRunsTo (rotateFileOf m) 0` — the post-state
  tree, read back through the walker, equals `rotateAt tree path`,
  remainder included, byte for byte.
* Stream face: the same over `encodeInput m`, interderivable by the
  kernel bridge (`rotate_sample_model_iff_stream`, via
  decode∘encode = id + canonicity).
* Path family: `RotatePathSampleStatement` — further pinned paths
  (root, depth-2) as verbatim instances; the path dimension is
  statement data.
* Builder correctness: `BuildOnlyStatement` — the no-call variant
  with `expected = choices`: the built heap serializes back to the
  stream (the free generator's soundness, as a runnable program).
* Leak conjunct: final allocation count = the driver baseline for
  every healthy instance (`rotateAt_size` — rotation is
  allocation-neutral — is the pure face).
* The parametric term `rotateMainParamDecl b0..b23` (one AST family,
  24 wire-byte parameters, 48 sites, expected[] structurally
  derived) makes the fixed-shape family-∀ (256²⁴ instances) the exec
  campaign's endpoint with zero further statement work.

The pinned shape is a depth-3 asymmetric tree with a genuine
transferred middle subtree at the locus:

```
      a                     a
     / \                   / \
    b   f    rotateAt     c   f
   / \       [left]      / \
  c   e      ======>   ...   b
   \                        / \
    d                      d   e
```

## 6. What the plants demonstrate

Two deliberately broken targets, both differentially red AND
logic-refutable, with disjoint failure signatures:

* WRONG-CHILD-SWAP (`t->left = t->right; t->right = l`): a content
  break with NO leak — verdict 7 (the locus val's first wire byte
  localizes the un-rotated node), final allocations = baseline.
* DROPPED-SUBTREE (`t->left = 0`): the transferred middle subtree is
  orphaned — verdict 255 (the observation LENGTH changes: structural
  breaks land in the length arm) and final allocations = baseline+1
  (the orphan), exactly as the pure layer predicts
  (`dropPlant_size`).

The pair shows why the leak conjunct earns its place: a verdict-only
family cannot tell a leak-free break from a leaking one. Blind spots
are documented and DEMONSTRATED green (swap at the self-similar locus
`(a (a L L) L)` where swap coincides with rotation; drop when the
middle subtree is already empty; both plants at off-shape loci), and
the kernel refutation schemas (`swapPlantClaim_refuted_of_run`,
`dropPlantClaim_refuted_of_run`, `dropPlantLeak_refutes_leakFree`)
turn the measured red facts into refutations of the healthy claims
once the parked exec equations land.

## 7. One statement-style lesson (the S4-E1 experiment)

"The rest of the tree is unchanged" can be stated two ways: as the
full-tree readback equality above, or as a locus/frame decomposition
(`rotateAt t p = replaceAt t p (rotateRight (subtreeAt t p))` plus
`subtreeAt (rotateAt t p) q = subtreeAt t q` for every diverging
`q`). Both are kernel lemmas; the STATEMENT uses the first. The
decomposition adds no strength (it is derivable), would drag
locus/path vocabulary into the statement, and belongs to the proof
layer — it is precisely the framing shape the Iris side will want,
proved once per model in pure land. Boring executable readback in
front; the decomposition waits in the back.
