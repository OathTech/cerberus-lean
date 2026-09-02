/-
SpecLab.ByteArrHarness — arc-15 S2: the byte-blaster harness templates
(mechanism A instances over the SpecLab.ByteArr models).

ONE template family per target (Form 1, the S1-confirmed default:
expected-array + generic mismatch-index comparator), plus the plant
twins. R2 DELIBERATELY COLLAPSES the S1 production/kernel-instance
split: at this rung the TARGET itself loops, so a loop-free harness
buys nothing — the looped production template IS the pinned fixture
instance (register S2-E4). Block-scope const arrays throughout (the
S1-E4 finding: `globs = []`, the arc-7 tests/verify fixture shape).

VERDICT SPACE (the Form 1 mismatch-index comparator, extended):
    0       agreement
    1 + i   first divergence at observation byte i
    254     MALFORMED STREAM (prefix/capacity violation — the
            harness is total on every splice; callers own validity)
    255     expected[] length divergence
The malformed arm makes every rendered instance a DEFINED program for
ANY byte splice (harnesses-are-programs: no UB reachable from any
stream), and is itself differentially exercised (the --plant lane's
malformed twins).

OBSERVATION LAYOUT (memcpy): u16le(n) ++ dst[0..n) ++ src[0..n) — the
length prefix in the OBSERVATION keeps expected[] nonempty at n = 0
(S0 empty-initializer caveat closed by codec design, not by excluding
the case). getarr: ret ++ arr[0..10).

BUILDER/READBACK are UB-free by construction (S1 discipline): stream
bytes enter `char` via explicit compare-and-subtract two's-complement
conversion (never an implementation-defined narrowing), and leave via
explicit `+ 256` re-encoding — byte-level readback is exact, so
byte-equality in the comparator IS value-equality (the S1-E4 honesty
class).

Targets cited verbatim (file + CN spec) per the S1 scoping rule; CN
magic comments ride along as ordinary comments (S0 probe (c)).
-/

import SpecLab.ByteArr

set_option autoImplicit false

namespace SpecLab
namespace ByteArr

/-- The verbatim memcpy target, with citation + CN spec (healthy). -/
def memcpyTargetHealthy : String :=
"/* TARGET — verbatim from deps/cn/tests/cn/memcpy.c
   (rems-project/cn, BSD-2-Clause; clean-room source per the
   2026-08-22 corpus ruling). CN annotations ride along as ordinary
   comments (cabs-json filters magic comments — arc-15 S0 probe (c)). */

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
{
  int i;
  for (i = 0; i < n; i = i + 1)
  /*@ inv take dstInv = each (i32 j; 0i32 <= j && j < n)
                             {RW(array_shift(dst, j))};
          take srcInv = each (i32 j; 0i32 <= j && j < n)
                             {RW(array_shift(src, j))};
          srcInv == srcStart;
          each (i32 j; 0i32 <= j && j < i) {dstInv[j] == srcStart[j]};
          0i32 <= i;
          {dst} unchanged;
          {src} unchanged;
          {n} unchanged; @*/
  {
    /*@ focus RW<char>, (i32)i; @*/
    /*@ instantiate good<char>, (i32)i; @*/
    dst[i] = src[i];
  }
}
"

/-- The memcpy PLANT target: the OFF-BY-ONE plant (`i = 1` start —
dst[0] is never written and keeps the harness canary), loudly marked.
An array-shaped break: the mismatch index must point at dst byte 0
(observation byte 2, verdict 3). -/
def memcpyTargetPlant : String :=
"/* TARGET — PLANT VARIANT (template-note §plant-test): naive_memcpy
   is deliberately BROKEN (off-by-one: the copy loop starts at i = 1,
   so dst[0] keeps the harness canary). A healthy-looking verdict
   from this program means the harness is vacuous. */

void
naive_memcpy (char *dst, char *src, int n)
{
  int i;
  for (i = 1; i < n; i = i + 1) /* PLANT: off-by-one (i = 1) */
  {
    dst[i] = src[i];
  }
}
"

/-- The verbatim getarr target, with citation + CN spec (healthy). -/
def getarrTargetHealthy : String :=
"/* TARGET — verbatim from deps/cn/tests/cn/get_from_arr.c
   (rems-project/cn, BSD-2-Clause; clean-room source per the
   2026-08-22 corpus ruling; upstream header: \"originally made by
   minimising a problematic case from memcpy.c\"). NOTE the CN
   ensures is OWNERSHIP-ONLY — it does not constrain the return
   value; this harness's spec is strictly stronger (register S2-E3). */

char
get_from_arr (char *in_arr)
/*@ requires take IA = each (i32 j; 0i32 <= j && j < 10i32)
  {RW<char>(in_arr + j)};
    ensures take IA2 = each (i32 j; 0i32 <= j && j < 10i32)
  {RW<char>(in_arr + j)}; @*/
{
  char c;

  /*@ focus RW<char>, 4i32; @*/
  /*@ instantiate good<char>, 4i32; @*/
  c = in_arr[4];

  return c;
}
"

/-- The getarr PLANT target: the WRONG-INDEX plant (`in_arr[3]`). -/
def getarrTargetPlant : String :=
"/* TARGET — PLANT VARIANT (template-note §plant-test): get_from_arr
   is deliberately BROKEN (wrong index: reads in_arr[3], not
   in_arr[4]). A healthy-looking verdict from this program on inputs
   with in_arr[3] != in_arr[4] means the harness is vacuous. */

char
get_from_arr (char *in_arr)
{
  char c;

  c = in_arr[3]; /* PLANT: wrong index */

  return c;
}
"

def header (form : String) : String :=
"/* SpecLab byte-blaster harness (" ++ form ++ ").
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
def byteArrMid : String :=
  " };\n  const unsigned char expected[] = { "

/-- The memcpy `post`: closes expected[], then the three phases —
byte-blaster builder (stream → src verbatim; dst pre-filled with the
canary 42), the call under test at (ptr, len), the observation
(u16le(n) ++ dst ++ src readback) and the generic mismatch-index
comparator. -/
def memcpyBody : String :=
" };
  char src[16];
  char dst[16];
  unsigned char out[34];
  unsigned long i, n, obs;
  int v, w;
  /* phase 0 — stream validity (the harness is total on any splice):
     u16le length prefix, capacity 16 */
  if (sizeof(choices) < 2u) { return 254; }
  n = (unsigned long)choices[0] + 256u * (unsigned long)choices[1];
  if (n > 16u) { return 254; }
  if (sizeof(choices) != 2u + n) { return 254; }
  /* phase 1 — builder: byte-blast the stream into src (two's-
     complement into char, UB-free); canary-fill dst */
  for (i = 0u; i < n; i++) {
    v = (int)choices[2u + i]; if (v >= 128) { v = v - 256; }
    src[i] = (char)v;
  }
  for (i = 0u; i < 16u; i++) { dst[i] = 42; }
  /* phase 2 — the call under test: (ptr, len) */
  naive_memcpy(dst, src, (int)n);
  /* phase 3 — observation: u16le(n) ++ dst[0..n) ++ src[0..n);
     verdict — generic mismatch-index comparator (Form 1) */
  out[0] = (unsigned char)(n % 256u);
  out[1] = (unsigned char)(n / 256u);
  for (i = 0u; i < n; i++) {
    w = (int)dst[i]; if (w < 0) { w = w + 256; }
    out[2u + i] = (unsigned char)w;
  }
  for (i = 0u; i < n; i++) {
    w = (int)src[i]; if (w < 0) { w = w + 256; }
    out[2u + n + i] = (unsigned char)w;
  }
  obs = 2u + 2u * n;
  if (sizeof(expected) != obs) { return 255; }
  for (i = 0u; i < obs; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-- The getarr `post`: fixed 10-byte extent (no length prefix — the
identity codec), readback = return byte ++ the post-call array (the
read-only claim is CHECKED, not assumed). -/
def getarrBody : String :=
" };
  char arr[10];
  unsigned char out[11];
  unsigned long i;
  int v, w;
  /* phase 0 — stream validity: exactly the CN resource extent */
  if (sizeof(choices) != 10u) { return 254; }
  /* phase 1 — builder: byte-blast the stream into arr */
  for (i = 0u; i < 10u; i++) {
    v = (int)choices[i]; if (v >= 128) { v = v - 256; }
    arr[i] = (char)v;
  }
  /* phase 2 — the call under test (interior of the built array) */
  v = (int)get_from_arr(arr);
  if (v < 0) { v = v + 256; }
  /* phase 3 — observation: ret ++ arr[0..10);
     verdict — generic mismatch-index comparator (Form 1) */
  out[0] = (unsigned char)v;
  for (i = 0u; i < 10u; i++) {
    w = (int)arr[i]; if (w < 0) { w = w + 256; }
    out[1u + i] = (unsigned char)w;
  }
  if (sizeof(expected) != 11u) { return 255; }
  for (i = 0u; i < 11u; i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-- memcpy Form 1 (the production AND pinned-statement template),
healthy target. -/
def memcpyTemplate : HarnessTemplate where
  pre := header "memcpy Form 1: byte-blaster, mismatch-index"
    ++ memcpyTargetHealthy ++ preTail
  mid := byteArrMid
  post := memcpyBody

/-- memcpy Form 1, OFF-BY-ONE PLANT target. -/
def memcpyPlantTemplate : HarnessTemplate where
  pre := header "memcpy Form 1, OFF-BY-ONE PLANT"
    ++ memcpyTargetPlant ++ preTail
  mid := byteArrMid
  post := memcpyBody

/-- getarr Form 1, healthy target. -/
def getarrTemplate : HarnessTemplate where
  pre := header "get_from_arr Form 1: byte-blaster, mismatch-index"
    ++ getarrTargetHealthy ++ preTail
  mid := byteArrMid
  post := getarrBody

/-- getarr Form 1, WRONG-INDEX PLANT target. -/
def getarrPlantTemplate : HarnessTemplate where
  pre := header "get_from_arr Form 1, WRONG-INDEX PLANT"
    ++ getarrTargetPlant ++ preTail
  mid := byteArrMid
  post := getarrBody

/-! ## Rendered-harness constructors (expected[] always the PURE
    model image — computed at statement-construction time) -/

/-- memcpy harness for a well-formed model. -/
def mkMemcpy (bs : List UInt8) : String :=
  mkHarness memcpyTemplate (encodeInput bs) (expectedBytes bs)

/-- memcpy harness for a RAW stream (fuzz entry — callers own
`ValidStream`; malformed splices are DEFINED programs returning 254,
with the junk expected splice). -/
def mkMemcpyOfStream (s : Stream) : String :=
  mkHarness memcpyTemplate s (expectedOfStream s)

def mkMemcpyPlant (bs : List UInt8) : String :=
  mkHarness memcpyPlantTemplate (encodeInput bs) (expectedBytes bs)

/-- getarr harness for a well-formed model (identity codec: the
choices splice IS the model). -/
def mkGetarr (bs : List UInt8) : String :=
  mkHarness getarrTemplate bs (getarrExpected bs)

/-- getarr harness for a RAW stream (malformed extents return 254). -/
def mkGetarrOfStream (s : Stream) : String :=
  mkHarness getarrTemplate s (getarrExpectedOfStream s)

def mkGetarrPlant (bs : List UInt8) : String :=
  mkHarness getarrPlantTemplate bs (getarrExpected bs)

end ByteArr
end SpecLab
