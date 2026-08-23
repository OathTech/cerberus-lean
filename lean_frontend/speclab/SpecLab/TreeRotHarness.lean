/-
SpecLab.TreeRotHarness — arc-15 S4: the tree-rotation harness
templates (mechanism A instances over the SpecLab.TreeRot models).
THE REFERENCE INSTANCE of the harness statement template — built to
be READ (this listing is quoted in the worked-example doc).

THE R4 IDIOM TRIO (the S3 builder/walker/comparator trio, extended
to trees as RECURSIVE helper procedures — the first speclab harness
with helper functions beyond the target):

  * scan_tree   — phase-0 stream validity WITHOUT allocation (a
                  recursive pre-order scan; malformed input never
                  allocates — the S3 validate-before-build
                  discipline, recursive form).
  * build_tree  — the BUILDER: stream-driven recursive pre-order
                  heap constructor (malloc per node, i32le val
                  two's-complement into int, UB-free).
  * serialize_tree — the WALKER/SERIALIZER: cap-guarded recursive
                  pre-order re-encoding of the post-state tree with
                  the builder's wire codec (the node budget keeps
                  every target variant total — a cycle-creating
                  target lands in the 253 arm, never a hang).
  * free_tree   — teardown: recursive free (runs only after the
                  serializer validated the reachable node budget).
  * COMPARATOR  — the generic mismatch-index comparator, unchanged
                  from R1-R3 (one index space over the whole
                  observation).

POINTER SELECTION AS STATEMENT FAMILY (the S3 `--at` prototype,
promoted): the PATH is part of the model and the choice stream; the
harness walks its own built tree along the path holding a PARENT
LINK (`struct node **link`) and calls the target on the interior
pointer it arrives at, storing the returned subtree root back
through the link — exactly as a caller of rotate_right would.
Pointer values never appear in the stream.

VERDICT SPACE (Form 1, the R3 space at tree scale):
    0       agreement
    1 + i   first divergence at observation byte i   (i < 196)
    252     allocator refusal (model-side unreachable; totality arm)
    253     overlong serialization (cap guard — cyclic plants only)
    254     MALFORMED STREAM (scan/path/length violation)
    255     expected[] length divergence (STRUCTURAL breaks land
            here: the dropped-subtree plant changes the node count)

ARRAY-CONST DEVIATION (documented per the S1-E4 register rule): the
spliced arrays are BLOCK-SCOPE (globs = [] preserved) but NOT
`const` this rung — the helper procedures take `unsigned char *`
parameters, and a const-qualified array would either violate the
pointer conversion or drag pointer-to-const qualifiers into the
hand-pinned funinfo for zero statement value. Nothing writes the
arrays (register S4-E).

Allocation closure: identical to R3 (the std.core allocator proxies
claim the C names under --nolibc; `ListAppend.allocDecls` reused —
idiom library, attributed).
-/

import SpecLab.TreeRot
import SpecLab.ListAppendHarness

set_option autoImplicit false

namespace SpecLab
namespace TreeRot

/-- The R4 target — FRESH AUTHORSHIP (no rotation exists in the
deps/cn corpus — the selection-reasoning note in SpecLab/TreeRot.lean;
struct shape per the corpus int-binary-tree reference,
tree_rev01.c). The classic right rotation, total off-shape. -/
def rotateTargetHealthy : String :=
"/* TARGET — fresh authorship for arc-15 R4 (the deps/cn corpus has no
   rotation; struct shape follows the corpus int-binary-tree
   reference, deps/cn/tests/cn/tree_rev01.c). CN-style contract, for
   the record (informal here — this rung's spec IS the harness
   statement):
     requires take T = Tree(t);
     ensures  take T2 = Tree(return); T2 == rotate_right_spec(T);

        t             l
       / \\           / \\
      l   r   ==>  ll   t
     / \\               / \\
    ll  lr            lr  r
*/

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
"

/-- The WRONG-CHILD-SWAP plant: the locus's children are swapped
instead of rotated — a content/structure break with NO leak (every
node stays reachable). Blind at the self-similar locus
`node a (node a L L) L` and at every off-shape locus (guards kept). -/
def rotateTargetSwapPlant : String :=
"/* TARGET — PLANT VARIANT (template-note §plant-test): rotate_right
   is deliberately BROKEN (child swap instead of rotation). All nodes
   stay reachable — this plant breaks the observation WITHOUT
   leaking (the leak lane's green contrast to the drop plant). */

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
  t->left = t->right; /* PLANT: child swap instead of rotation */
  t->right = l;
  return t;
}
"

/-- The DROPPED-SUBTREE plant: `t->left = 0` instead of
`t->left = l->right` — the rotation's transferred middle subtree is
ORPHANED: the observation breaks in the 255 length arm AND the
orphans survive teardown (THE LEAK ARM'S RED WITNESS). Blind when
the locus's `l->right` is already null. -/
def rotateTargetDropPlant : String :=
"/* TARGET — PLANT VARIANT (template-note §plant-test): rotate_right
   is deliberately BROKEN (the transferred middle subtree l->right is
   dropped instead of re-attached — its nodes are ORPHANED). A
   healthy-looking verdict on a nonempty middle subtree means the
   harness is vacuous — and the orphaned nodes are the leak
   observable's red witness. */

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
  t->left = 0; /* PLANT: l->right dropped (orphaned subtree) */
  l->right = t;
  return l;
}
"

/-- The R4 idiom-trio helper procedures (shared verbatim by every
template of the family — literal-independent, so they pin
identically across the parametric instances). -/
def helperFns : String :=
"
/* --- the R4 idiom trio: recursive tree helpers ------------------- */

/* phase 0 helper — stream validity: recursive pre-order scan of one
   tree encoding (NO allocation; malformed input never allocates).
   Returns bytes consumed, or -1 on malformed/over-capacity input;
   cnt accumulates the node count against the 31-node cap. */
static long scan_tree(unsigned char *c, unsigned long len,
                      unsigned long pos, unsigned long *cnt)
{
  long lsub, rsub;
  if (pos >= len) { return -1; }
  if (c[pos] == 0u) { return 1; }
  if (c[pos] != 1u) { return -1; }
  if (pos + 5u > len) { return -1; }
  *cnt = *cnt + 1u;
  if (*cnt > 31u) { return -1; }
  lsub = scan_tree(c, len, pos + 5u, cnt);
  if (lsub < 0) { return -1; }
  rsub = scan_tree(c, len, pos + 5u + (unsigned long)lsub, cnt);
  if (rsub < 0) { return -1; }
  return 5 + lsub + rsub;
}

/* phase 1 helper — BUILDER: stream-driven recursive pre-order heap
   constructor (runs only on scan-validated streams; the only
   remaining failure is allocator refusal — the 252 totality arm,
   model-side unreachable — reported through *err). i32le val,
   two's-complement into int, UB-free. */
static struct node *build_tree(unsigned char *c, unsigned long *pos,
                               int *err)
{
  struct node *t;
  struct node *lch;
  struct node *rch;
  unsigned long off;
  long v;
  if (*err != 0) { return 0; }
  if (c[*pos] == 0u) { *pos = *pos + 1u; return 0; }
  off = *pos + 1u;
  *pos = *pos + 5u;
  t = (struct node*)malloc(sizeof(struct node));
  if (t == 0) { *err = 252; return 0; }
  v = (long)((unsigned long)c[off]
      + 256u * (unsigned long)c[off + 1u]
      + 65536u * (unsigned long)c[off + 2u]
      + 16777216u * (unsigned long)c[off + 3u]);
  if (v >= 2147483648L) { v = v - 4294967296L; }
  t->val = (int)v;
  /* SEQUENCED-CALL RULE (register S4-E): call results land in plain
     locals before any member/deref store — a deref-store of a call
     result is an unsequenced pair that MULTIPLIES exhaustive-mode
     interleavings (measured: 3 executions per site; the S3 append
     harness complied by accident via its initializer style). */
  lch = build_tree(c, pos, err);
  t->left = lch;
  rch = build_tree(c, pos, err);
  t->right = rch;
  return t;
}

/* phase 3 helper — WALKER/SERIALIZER: cap-guarded recursive
   pre-order re-encoding of the post-state tree with the builder's
   wire codec. Returns the next write index, or -1 once the 31-node
   budget is exhausted (the 253 overlong arm — keeps every target
   variant total: a cycle-creating target cannot hang the harness).
   Write bound: at most 31 node records (5 bytes) + 32 leaf bytes =
   187 <= sizeof(out). */
static long serialize_tree(struct node *t, unsigned char *out,
                           long j, unsigned long *cnt)
{
  long v;
  if (t == 0) { out[j] = 0u; return j + 1; }
  *cnt = *cnt + 1u;
  if (*cnt > 31u) { return -1; }
  out[j] = 1u;
  v = (long)t->val;
  if (v < 0) { v = v + 4294967296L; }
  out[j + 1] = (unsigned char)((unsigned long)v % 256u);
  out[j + 2] = (unsigned char)(((unsigned long)v / 256u) % 256u);
  out[j + 3] = (unsigned char)(((unsigned long)v / 65536u) % 256u);
  out[j + 4] = (unsigned char)(((unsigned long)v / 16777216u) % 256u);
  j = serialize_tree(t->left, out, j + 5, cnt);
  if (j < 0) { return -1; }
  return serialize_tree(t->right, out, j, cnt);
}

/* phase 4 helper — teardown: recursive free of a serializer-validated
   tree (leak-freedom: rotation is allocation-neutral — the healthy
   post-state reaches every built node). */
static void free_tree(struct node *t)
{
  if (t == 0) { return; }
  free_tree(t->left);
  free_tree(t->right);
  free(t);
}
"

def treeHeader (form : String) : String :=
"/* SpecLab tree-rotation harness (" ++ form ++ ").
   Generated by SpecLab.mkHarness — do not edit by hand.
   Idiom lineage: golean three-phase harness (setup - call - test);
   see lean_frontend/speclab/README.md. */

"

/-- Main opener + choices[] opener (block-scope; the const deviation
is documented in the module header). -/
def treePreTail : String :=
"
int main(void)
{
  unsigned char choices[] = { "

def treeMid : String :=
  " };\n  unsigned char expected[] = { "

/-- Shared decls + phase 0 (stream validity: tree scan + path code)
+ phase 1 (build). Used by every body below. -/
def treePhases01 : String :=
"  struct node *root;
  struct node **link;
  struct node *newsub;
  unsigned char out[200]; /* max obs: rotate 187; build-only 196 */
  unsigned long i, cnt, pos, bpos, plen, obs;
  long consumed, j;
  int err;
  /* phase 0 — stream validity (total on any splice; no allocation on
     malformed input): pre-order tree code (scan_tree) ++ u8(plen) ++
     plen path bytes (each 0/1); caps: 31 nodes, 8 path steps. */
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
"

/-- Phase 2: the pointer-selection walk + the call under test. -/
def treeCallPhase : String :=
"  /* phase 2 — POINTER SELECTION + the call under test: walk the
     built tree along the path to the rotation locus; the target gets
     THE INTERIOR POINTER the walk arrives at (pointer values never
     appear in the stream), and the parent link takes the returned
     subtree root — exactly as a caller of rotate_right would. */
  link = &root;
  for (i = 0u; i < plen && *link != 0; i++) {
    if (choices[pos + 1u + i] == 1u) { link = &(*link)->right; }
    else { link = &(*link)->left; }
  }
  newsub = rotate_right(*link); /* sequenced-call rule (S4-E) */
  *link = newsub;
"

/-- Phases 3-4: serialize (cap-guarded) + teardown. -/
def treeSerializeTeardown : String :=
"  /* phase 3 — serialize the post-state tree (cap-guarded) */
  cnt = 0u;
  j = serialize_tree(root, out, 0, &cnt);
  if (j < 0) { return 253; }
  /* phase 4 — teardown: free the post-state tree */
  free_tree(root);
"

/-- Phase 5 (Form 1): the generic mismatch-index comparator. -/
def treeComparator : String :=
"  /* phase 5 — verdict: generic mismatch-index comparator (Form 1) */
  obs = (unsigned long)j;
  if (sizeof(expected) != obs) { return 255; }
  for (i = 0u; i < obs; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-- The Form 1 rotate `post`. -/
def rotateBody : String :=
  " };\n" ++ treePhases01 ++ treeCallPhase ++ treeSerializeTeardown
    ++ treeComparator

/-- The Form 2 rotate `post` (stdout serialization — the judge moves
into the Lean statement; libc mode; trailing newline load-bearing,
S1-E1). -/
def rotateForm2Body : String :=
  " };\n" ++ treePhases01 ++ treeCallPhase ++ treeSerializeTeardown ++
"  /* phase 5 — verdict channel: stdout serialization (Form 2).
     NOTE: the final newline is load-bearing — stdout is line-buffered
     and unflushed at exit (S1 register finding). */
  (void)expected;
  obs = (unsigned long)j;
  for (i = 0u; i < obs; i++) {
    putchar((int)('0' + out[i] / 100u));
    putchar((int)('0' + out[i] / 10u % 10u));
    putchar((int)('0' + out[i] % 10u));
    putchar((int)',');
  }
  putchar((int)'\\n');
  return 0;
}
"

/-- The BUILD-ONLY `post` (the builder-correctness statement's
executable face): phases 0-1 build, NO call — the observation
serializes the built tree and re-emits the path bytes verbatim, so
the healthy expected[] IS the choice stream (`expected = choices`:
the builder-walker round trip through the heap). -/
def buildOnlyBody : String :=
  " };\n" ++ treePhases01 ++
"  /* phase 2 — NO call (builder-correctness instance) */
  /* phase 3 — serialize the BUILT tree with the wire codec, then
     re-emit the path bytes verbatim: expected[] = choices[] */
  cnt = 0u;
  j = serialize_tree(root, out, 0, &cnt);
  if (j < 0) { return 253; }
  out[j] = (unsigned char)plen;
  for (i = 0u; i < plen; i++) {
    out[j + 1 + (long)i] = choices[pos + 1u + i];
  }
  j = j + 1 + (long)plen;
  /* phase 4 — teardown */
  free_tree(root);
" ++ treeComparator

/-! ## Templates -/

/-- rotate Form 1 (the production AND pinned-statement template),
healthy target. -/
def rotateTemplate : HarnessTemplate where
  pre := treeHeader "rotate_right Form 1: tree builder, path-selected locus, mismatch-index"
    ++ ListAppend.allocDecls ++ "\n" ++ rotateTargetHealthy ++ helperFns
    ++ treePreTail
  mid := treeMid
  post := rotateBody

/-- rotate Form 1, WRONG-CHILD-SWAP PLANT target. -/
def rotateSwapPlantTemplate : HarnessTemplate where
  pre := treeHeader "rotate_right Form 1, WRONG-CHILD-SWAP PLANT"
    ++ ListAppend.allocDecls ++ "\n" ++ rotateTargetSwapPlant ++ helperFns
    ++ treePreTail
  mid := treeMid
  post := rotateBody

/-- rotate Form 1, DROPPED-SUBTREE PLANT target (the leak arm's red
witness). -/
def rotateDropPlantTemplate : HarnessTemplate where
  pre := treeHeader "rotate_right Form 1, DROPPED-SUBTREE PLANT"
    ++ ListAppend.allocDecls ++ "\n" ++ rotateTargetDropPlant ++ helperFns
    ++ treePreTail
  mid := treeMid
  post := rotateBody

/-- rotate Form 2 (stdout serialization; libc mode). -/
def rotateForm2Template : HarnessTemplate where
  pre := treeHeader "rotate_right Form 2: tree builder, stdout serialization"
    ++ ListAppend.allocDecls ++ "int putchar(int c);\n\n"
    ++ rotateTargetHealthy ++ helperFns ++ treePreTail
  mid := treeMid
  post := rotateForm2Body

/-- Build-only (builder-correctness instance; healthy target text
included so the TU matches the family's shape, though phase 2 never
calls it). -/
def buildOnlyTemplate : HarnessTemplate where
  pre := treeHeader "tree BUILD-ONLY: builder-walker round trip"
    ++ ListAppend.allocDecls ++ "\n" ++ rotateTargetHealthy ++ helperFns
    ++ treePreTail
  mid := treeMid
  post := buildOnlyBody

/-! ## Rendered-harness constructors (expected[] always the PURE
    model image — computed at statement-construction time) -/

def mkRotate (m : Input) : String :=
  mkHarness rotateTemplate (encodeInput m) (expectedBytes m)

/-- rotate harness for a RAW stream (fuzz/malformed entry — junk
expected on invalid streams; every splice is a DEFINED program). -/
def mkRotateOfStream (s : Stream) : String :=
  mkHarness rotateTemplate s (expectedOfStream s)

def mkRotateSwapPlant (m : Input) : String :=
  mkHarness rotateSwapPlantTemplate (encodeInput m) (expectedBytes m)

def mkRotateDropPlant (m : Input) : String :=
  mkHarness rotateDropPlantTemplate (encodeInput m) (expectedBytes m)

def mkRotateForm2 (m : Input) : String :=
  mkHarness rotateForm2Template (encodeInput m) (expectedBytes m)

/-- Build-only harness: expected = the choice stream itself. -/
def mkBuildOnly (m : Input) : String :=
  mkHarness buildOnlyTemplate (encodeInput m) (encodeInput m)

end TreeRot
end SpecLab
