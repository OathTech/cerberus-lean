/-
SpecLab.ListAppendHarness — arc-15 S3: the linked-list harness
templates (mechanism A instances over the SpecLab.ListAppend models).

THE R3 IDIOM TRIO (charter: "first non-trivial builder + walker +
comparator idiom"), as reusable template-composable C fragments:

  * BUILDER (`builderFragment`): the first real stream-driven HEAP
    constructor — walks the choice stream and builds a linked list
    node-by-node (u16le count prefix, i32le element codec), tail-link
    pointer threading so nodes land in stream order. malloc-backed
    (allocation closure: the std.core allocator proxies claim the C
    names under --nolibc — see SpecLab/ListAppend.lean header).
  * WALKER/SERIALIZER (in the bodies): walks the post-state list
    under a CAP GUARD (a list longer than capTotal — reachable only
    via broken/cyclic plants — returns the 253 overlong arm, keeping
    the harness total under EVERY target variant) and re-encodes it
    with the same wire codec the builder consumed.
  * COMPARATOR: the generic mismatch-index comparator (Form 1),
    unchanged from R1/R2 — S2-E2's concatenated-observation lesson
    carried forward (count prefix + elements in ONE index space).

TEARDOWN + THE LEAK CONJUNCT (live this rung): phase 4 frees the
result list by walking it — the healthy target REUSES every input
node (alloc/free balance, `ListAppend.alloc_free_balance`), so after
teardown the harness owns no heap. The exec-level observable (final
allocation map at the driver's baseline) is stated in
SpecLab/ListAppendFiles.lean; the wrong-link plant orphans
`xs.length - 1` nodes and is the leak lane's red witness.

VERDICT SPACE (Form 1, extended for the heap rung):
    0       agreement
    1 + i   first divergence at observation byte i   (i < 66)
    252     allocator refusal (model-side unreachable; totality arm)
    253     overlong walk (cap guard — cyclic/broken plants only)
    254     MALFORMED STREAM (prefix/capacity violation)
    255     expected[] length divergence (STRUCTURAL breaks land
            here: a diverging node count changes the observation
            LENGTH before any content index — the S3 probes' finding)

BUILDER/READBACK are UB-free by construction (S1 discipline): u32
reassembly in unsigned long, two's-complement into int via explicit
compare-and-subtract, readback via explicit + 2^32 re-encoding.

Targets cited verbatim (file + CN spec) per the S1 scoping rule; CN
magic comments ride along as ordinary comments (S0 probe (c)).
-/

import SpecLab.ListAppend

set_option autoImplicit false

namespace SpecLab
namespace ListAppend

/-- The allocation closure: direct extern declarations of the
Core-stdlib allocator proxies' C names (the cn_coverage
support-shim closure, sans shim TU — append.c does not use
cn_malloc). -/
def allocDecls : String :=
"void *malloc(unsigned long size);
void free(void *p);
"

/-- The verbatim target, with citation + the full CN block (healthy).
`split`/`main` from the same corpus file are out of scope this rung. -/
def appendTargetHealthy : String :=
"/* TARGET — verbatim from deps/cn/tests/cn/append.c
   (rems-project/cn, BSD-2-Clause; clean-room source per the
   2026-08-22 corpus ruling). The same file's `split` and `main` are
   not part of this rung. CN annotations ride along as ordinary
   comments (cabs-json filters magic comments — arc-15 S0 probe (c)). */

struct int_list {
  int head;
  struct int_list* tail;
};

/*@
datatype seq {
  Seq_Nil {},
  Seq_Cons {i32 head, datatype seq tail}
}

function [rec] (datatype seq) append(datatype seq xs, datatype seq ys) {
  match xs {
    Seq_Nil {} => {
      ys
    }
    Seq_Cons {head : h, tail : zs}  => {
      Seq_Cons {head: h, tail: append(zs, ys)}
    }
  }
}

predicate [rec] (datatype seq) IntList(pointer p) {
  if (is_null(p)) {
    return Seq_Nil{};
  } else {
    take H = RW<struct int_list>(p);
    take tl = IntList(H.tail);
    return (Seq_Cons { head: H.head, tail: tl });
  }
}
@*/

struct int_list* IntList_append(struct int_list* xs, struct int_list* ys)
/*@ requires take L1 = IntList(xs);
             take L2 = IntList(ys);
    ensures take L3 = IntList(return);
            L3 == append(L1, L2); @*/
{
  if (xs == 0) {
    /*@ unfold append(L1, L2); @*/
    return ys;
  } else {
    /*@ unfold append(L1, L2); @*/
    struct int_list *new_tail = IntList_append(xs->tail, ys);
    xs->tail = new_tail;
    return xs;
  }
}
"

/-- The WRONG-LINK plant target: `xs->tail = ys` — a link-structure
break (result `[xs0] ++ ys`; deeper xs nodes ORPHANED — the leak
lane's red witness). Blind at xs.length ≤ 1 (documented,
demonstrated). -/
def appendTargetLinkPlant : String :=
"/* TARGET — PLANT VARIANT (template-note §plant-test): IntList_append
   is deliberately BROKEN (wrong link: xs->tail = ys skips the
   recursion's result, orphaning every deeper xs node). A
   healthy-looking verdict from this program on xs.length >= 2 means
   the harness is vacuous — and the orphaned nodes are the leak
   observable's red witness. */

struct int_list {
  int head;
  struct int_list* tail;
};

struct int_list* IntList_append(struct int_list* xs, struct int_list* ys)
{
  if (xs == 0) {
    return ys;
  } else {
    struct int_list *new_tail = IntList_append(xs->tail, ys);
    xs->tail = ys; /* PLANT: wrong link (new_tail dropped) */
    return xs;
  }
}
"

/-- The WRONG-ELEMENT plant target: `xs->head ^ 1` — a content break
(every xs head's low bit flips; `^` keeps the plant UB-free at every
input, unlike `+ 1` at INT_MAX). Blind at xs = [] (documented,
demonstrated). -/
def appendTargetElemPlant : String :=
"/* TARGET — PLANT VARIANT (template-note §plant-test): IntList_append
   is deliberately BROKEN (element corruption: xs->head ^= 1 flips
   every xs head's low bit; XOR so the plant stays UB-free on every
   stream). A healthy-looking verdict from this program on xs != []
   means the harness is vacuous. */

struct int_list {
  int head;
  struct int_list* tail;
};

struct int_list* IntList_append(struct int_list* xs, struct int_list* ys)
{
  if (xs == 0) {
    return ys;
  } else {
    struct int_list *new_tail = IntList_append(xs->tail, ys);
    xs->head = xs->head ^ 1; /* PLANT: element corruption */
    xs->tail = new_tail;
    return xs;
  }
}
"

def header (form : String) : String :=
"/* SpecLab linked-list harness (" ++ form ++ ").
   Generated by SpecLab.mkHarness — do not edit by hand.
   Idiom lineage: golean three-phase harness (setup - call - test);
   see lean_frontend/speclab/README.md. */

"

/-- The shared `pre` tail: main opener + choices[] opener (block-scope
per S1-E4). -/
def preTail : String :=
"
int main(void)
{
  const unsigned char choices[] = { "

/-- The shared `mid`: close choices[], open expected[]. -/
def listMid : String :=
  " };\n  const unsigned char expected[] = { "

/-- Shared declarations + phase 0 (stream validity, two-list layout)
+ phase 1 (the BUILDER idiom fragment ×2). Used by every append-shaped
body below (template-composable fragment, the idiom-library point). -/
def buildPhases : String :=
"  struct int_list *xs;
  struct int_list *ys;
  struct int_list *r;
  struct int_list *p;
  struct int_list *t;
  struct int_list **link;
  unsigned char out[68]; /* max obs: append 2+4*16=66; build-only 4+4*16=68 */
  unsigned long i, j, m, n1, n2, off, obs;
  long v;
  /* phase 0 — stream validity (total on any splice):
     u16le(n1) ++ n1 x i32le ++ u16le(n2) ++ n2 x i32le; caps 8/8 */
  if (sizeof(choices) < 2u) { return 254; }
  n1 = (unsigned long)choices[0] + 256u * (unsigned long)choices[1];
  if (n1 > 8u) { return 254; }
  if (sizeof(choices) < 4u + 4u * n1) { return 254; }
  n2 = (unsigned long)choices[2u + 4u * n1]
     + 256u * (unsigned long)choices[3u + 4u * n1];
  if (n2 > 8u) { return 254; }
  if (sizeof(choices) != 4u + 4u * n1 + 4u * n2) { return 254; }
  /* phase 1 — BUILDER (idiom fragment): stream-driven list
     constructor — node-by-node malloc, tail-link threading, i32le
     element codec, two's-complement into int (UB-free) */
  xs = 0; link = &xs;
  for (i = 0u; i < n1; i++) {
    p = (struct int_list*)malloc(sizeof(struct int_list));
    if (p == 0) { return 252; }
    off = 2u + 4u * i;
    v = (long)((unsigned long)choices[off]
        + 256u * (unsigned long)choices[off + 1u]
        + 65536u * (unsigned long)choices[off + 2u]
        + 16777216u * (unsigned long)choices[off + 3u]);
    if (v >= 2147483648L) { v = v - 4294967296L; }
    p->head = (int)v;
    p->tail = 0;
    *link = p; link = &p->tail;
  }
  ys = 0; link = &ys;
  for (i = 0u; i < n2; i++) {
    p = (struct int_list*)malloc(sizeof(struct int_list));
    if (p == 0) { return 252; }
    off = 4u + 4u * n1 + 4u * i;
    v = (long)((unsigned long)choices[off]
        + 256u * (unsigned long)choices[off + 1u]
        + 65536u * (unsigned long)choices[off + 2u]
        + 16777216u * (unsigned long)choices[off + 3u]);
    if (v >= 2147483648L) { v = v - 4294967296L; }
    p->head = (int)v;
    p->tail = 0;
    *link = p; link = &p->tail;
  }
"

/-- Phase 3 (the WALKER/SERIALIZER idiom fragment): cap-guarded walk
of `r`, u16le(count) ++ i32le heads into out[]. -/
def walkSerialize : String :=
"  /* phase 3 — WALKER/SERIALIZER (idiom fragment): cap-guarded walk,
     re-encode with the builder's wire codec */
  m = 0u;
  for (p = r; p != 0 && m <= 16u; p = p->tail) { m = m + 1u; }
  if (m > 16u) { return 253; }
  out[0] = (unsigned char)(m % 256u);
  out[1] = (unsigned char)(m / 256u);
  j = 2u;
  for (p = r; p != 0; p = p->tail) {
    v = (long)p->head;
    if (v < 0) { v = v + 4294967296L; }
    out[j] = (unsigned char)(v % 256u);
    out[j + 1u] = (unsigned char)((v / 256u) % 256u);
    out[j + 2u] = (unsigned char)((v / 65536u) % 256u);
    out[j + 3u] = (unsigned char)((v / 16777216u) % 256u);
    j = j + 4u;
  }
"

/-- Phase 4 (teardown, result-walk form): frees the result list —
the healthy target reuses every node, so after this walk the harness
owns no heap. -/
def teardownResult : String :=
"  /* phase 4 — teardown: free the result list (leak-freedom: the
     healthy target reuses every node, so after this walk the harness
     owns no heap) */
  p = r;
  while (p != 0) { t = p->tail; free(p); p = t; }
"

/-- Phases 3-4 composed (the Form 1/Form 2 shape). -/
def walkSerializeTeardown : String := walkSerialize ++ teardownResult

/-- The Form 1 append `post`: build, call, walk/serialize, teardown,
mismatch-index comparator. -/
def appendBody : String :=
" };\n" ++ buildPhases ++
"  /* phase 2 — the call under test */
  r = IntList_append(xs, ys);
" ++ walkSerializeTeardown ++
"  /* phase 5 — verdict: generic mismatch-index comparator (Form 1) */
  obs = 2u + 4u * m;
  if (sizeof(expected) != obs) { return 255; }
  for (i = 0u; i < obs; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-- The Form 2 append `post` (the comparator-in-C vs
serialize-then-judge-in-Lean head-to-head, register S3): identical
phases 0-4; phase 5 PRINTS the observation (3-digit decimal + comma
per byte, `render3` mirror) — the JUDGE moves into the Lean statement
(stdout observable asserted against the pure prediction). Costs libc
mode; the trailing newline is load-bearing (S1-E1). -/
def appendForm2Body : String :=
" };\n" ++ buildPhases ++
"  /* phase 2 — the call under test */
  r = IntList_append(xs, ys);
" ++ walkSerializeTeardown ++
"  /* phase 5 — verdict channel: stdout serialization (Form 2).
     NOTE: the final newline is load-bearing — stdout is line-buffered
     and unflushed at exit (S1 register finding). */
  (void)expected;
  obs = 2u + 4u * m;
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
executable face, register S3): phases 0-1 build both lists, NO call —
the observation serializes xs then ys exactly as the builder consumed
them, so the healthy expected[] IS the choice stream (`expected =
choices`: the builder-walker round trip through the heap). Teardown
frees both lists. -/
def buildOnlyBody : String :=
" };\n" ++ buildPhases ++
"  /* phase 2 — NO call (builder-correctness instance) */
  /* phase 3 — serialize xs then ys with the wire codec */
  out[0] = (unsigned char)(n1 % 256u);
  out[1] = (unsigned char)(n1 / 256u);
  j = 2u;
  for (p = xs; p != 0; p = p->tail) {
    v = (long)p->head;
    if (v < 0) { v = v + 4294967296L; }
    out[j] = (unsigned char)(v % 256u);
    out[j + 1u] = (unsigned char)((v / 256u) % 256u);
    out[j + 2u] = (unsigned char)((v / 65536u) % 256u);
    out[j + 3u] = (unsigned char)((v / 16777216u) % 256u);
    j = j + 4u;
  }
  out[j] = (unsigned char)(n2 % 256u);
  out[j + 1u] = (unsigned char)(n2 / 256u);
  j = j + 2u;
  for (p = ys; p != 0; p = p->tail) {
    v = (long)p->head;
    if (v < 0) { v = v + 4294967296L; }
    out[j] = (unsigned char)(v % 256u);
    out[j + 1u] = (unsigned char)((v / 256u) % 256u);
    out[j + 2u] = (unsigned char)((v / 65536u) % 256u);
    out[j + 3u] = (unsigned char)((v / 16777216u) % 256u);
    j = j + 4u;
  }
  /* phase 4 — teardown: free both lists */
  p = xs;
  while (p != 0) { t = p->tail; free(p); p = t; }
  p = ys;
  while (p != 0) { t = p->tail; free(p); p = t; }
  /* phase 5 — verdict: generic mismatch-index comparator */
  obs = 4u + 4u * (n1 + n2);
  if (sizeof(expected) != obs) { return 255; }
  for (i = 0u; i < obs; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-- The POINTER-SELECTION `post` (the interior-pointer prototype,
register S3): stream = u8(k) ++ the two-list layout, `k < n1`
required; phase 2 walks the built xs to node k and hands the target
THE INTERIOR POINTER (pointer values never enter the stream — the
template note's path-selection rule, prototyped for R4). Teardown
frees the k prefix nodes first, then the result walk. -/
def appendAtBody : String :=
" };
  struct int_list *xs;
  struct int_list *ys;
  struct int_list *r;
  struct int_list *p;
  struct int_list *t;
  struct int_list **link;
  unsigned char out[66];
  unsigned long i, j, k, m, n1, n2, off, obs;
  long v;
  /* phase 0 — stream validity: u8(k) ++ u16le(n1) ++ n1 x i32le
     ++ u16le(n2) ++ n2 x i32le; k < n1; caps 8/8 */
  if (sizeof(choices) < 3u) { return 254; }
  k = (unsigned long)choices[0];
  n1 = (unsigned long)choices[1] + 256u * (unsigned long)choices[2];
  if (n1 > 8u) { return 254; }
  if (k >= n1) { return 254; }
  if (sizeof(choices) < 5u + 4u * n1) { return 254; }
  n2 = (unsigned long)choices[3u + 4u * n1]
     + 256u * (unsigned long)choices[4u + 4u * n1];
  if (n2 > 8u) { return 254; }
  if (sizeof(choices) != 5u + 4u * n1 + 4u * n2) { return 254; }
  /* phase 1 — BUILDER (idiom fragment, offsets shifted by the k
     prefix) */
  xs = 0; link = &xs;
  for (i = 0u; i < n1; i++) {
    p = (struct int_list*)malloc(sizeof(struct int_list));
    if (p == 0) { return 252; }
    off = 3u + 4u * i;
    v = (long)((unsigned long)choices[off]
        + 256u * (unsigned long)choices[off + 1u]
        + 65536u * (unsigned long)choices[off + 2u]
        + 16777216u * (unsigned long)choices[off + 3u]);
    if (v >= 2147483648L) { v = v - 4294967296L; }
    p->head = (int)v;
    p->tail = 0;
    *link = p; link = &p->tail;
  }
  ys = 0; link = &ys;
  for (i = 0u; i < n2; i++) {
    p = (struct int_list*)malloc(sizeof(struct int_list));
    if (p == 0) { return 252; }
    off = 5u + 4u * n1 + 4u * i;
    v = (long)((unsigned long)choices[off]
        + 256u * (unsigned long)choices[off + 1u]
        + 65536u * (unsigned long)choices[off + 2u]
        + 16777216u * (unsigned long)choices[off + 3u]);
    if (v >= 2147483648L) { v = v - 4294967296L; }
    p->head = (int)v;
    p->tail = 0;
    *link = p; link = &p->tail;
  }
  /* phase 2 — POINTER SELECTION: walk the built list to node k,
     hand the target the INTERIOR pointer */
  p = xs;
  for (i = 0u; i < k; i++) { p = p->tail; }
  r = IntList_append(p, ys);
" ++ walkSerialize ++
"  /* phase 4 — teardown: free the k prefix nodes, then the result
     walk (no node is reachable from both) */
  p = xs;
  for (i = 0u; i < k; i++) { t = p->tail; free(p); p = t; }
  p = r;
  while (p != 0) { t = p->tail; free(p); p = t; }
" ++
"  /* phase 5 — verdict: generic mismatch-index comparator */
  obs = 2u + 4u * m;
  if (sizeof(expected) != obs) { return 255; }
  for (i = 0u; i < obs; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-! ## Templates -/

/-- append Form 1 (the production AND pinned-statement template),
healthy target. -/
def appendTemplate : HarnessTemplate where
  pre := header "IntList_append Form 1: list builder, mismatch-index"
    ++ allocDecls ++ "\n" ++ appendTargetHealthy ++ preTail
  mid := listMid
  post := appendBody

/-- append Form 1, WRONG-LINK PLANT target. -/
def appendLinkPlantTemplate : HarnessTemplate where
  pre := header "IntList_append Form 1, WRONG-LINK PLANT"
    ++ allocDecls ++ "\n" ++ appendTargetLinkPlant ++ preTail
  mid := listMid
  post := appendBody

/-- append Form 1, WRONG-ELEMENT PLANT target. -/
def appendElemPlantTemplate : HarnessTemplate where
  pre := header "IntList_append Form 1, WRONG-ELEMENT PLANT"
    ++ allocDecls ++ "\n" ++ appendTargetElemPlant ++ preTail
  mid := listMid
  post := appendBody

/-- append Form 2 (stdout serialization; libc mode — the
serialize-then-judge contender). -/
def appendForm2Template : HarnessTemplate where
  pre := header "IntList_append Form 2: list builder, stdout serialization"
    ++ allocDecls ++ "int putchar(int c);\n\n"
    ++ appendTargetHealthy ++ preTail
  mid := listMid
  post := appendForm2Body

/-- Build-only (builder-correctness instance; healthy target text
included so the TU matches the append family's shape, though phase 2
never calls it). -/
def buildOnlyTemplate : HarnessTemplate where
  pre := header "list BUILD-ONLY: builder-walker round trip"
    ++ allocDecls ++ "\n" ++ appendTargetHealthy ++ preTail
  mid := listMid
  post := buildOnlyBody

/-- Pointer-selection prototype (interior-pointer argument). -/
def appendAtTemplate : HarnessTemplate where
  pre := header "IntList_append AT-K: pointer-selection prototype"
    ++ allocDecls ++ "\n" ++ appendTargetHealthy ++ preTail
  mid := listMid
  post := appendAtBody

/-! ## Rendered-harness constructors (expected[] always the PURE
    model image — computed at statement-construction time) -/

/-- append harness for a well-formed model. -/
def mkAppend (m : Input) : String :=
  mkHarness appendTemplate (encodeInput m) (expectedBytes m)

/-- append harness for a RAW stream (fuzz/malformed entry — the junk
expected splice on invalid streams; every splice is a DEFINED
program). -/
def mkAppendOfStream (s : Stream) : String :=
  mkHarness appendTemplate s (expectedOfStream s)

def mkAppendLinkPlant (m : Input) : String :=
  mkHarness appendLinkPlantTemplate (encodeInput m) (expectedBytes m)

def mkAppendElemPlant (m : Input) : String :=
  mkHarness appendElemPlantTemplate (encodeInput m) (expectedBytes m)

def mkAppendForm2 (m : Input) : String :=
  mkHarness appendForm2Template (encodeInput m) (expectedBytes m)

/-- Build-only harness: expected = the choice stream itself (the
builder-walker round trip made a program). -/
def mkBuildOnly (m : Input) : String :=
  mkHarness buildOnlyTemplate (encodeInput m) (encodeInput m)

/-- Pointer-selection harness at a well-formed (k, xs, ys). -/
def mkAppendAt (m : AtInput) : String :=
  mkHarness appendAtTemplate (encodeAtInput m) (atExpectedBytes m)

end ListAppend
end SpecLab
