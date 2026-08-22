/-
SpecLab.DivModHarness — arc-15 S1: the divmod harness templates
(mechanism A instances over the SpecLab.DivMod model).

FOUR STATEMENT FORMS of the same property, built side by side for the
S1 spec-style experiment (charter: "where a rung admits more than one
spec style, build the contenders"):

  * Form 1 (template-note DEFAULT): expected-array + generic
    mismatch-index comparator, looped builder/encoder — the production
    i32 template. Verdict: `Specified(0)` / `Specified(1+i)` /
    `Specified(255)` on length divergence.
  * Form 1b (boolean verdict): identical harness, comparator returns
    `1` on any divergence — the legitimate-at-R1 boolean contender.
  * Form 2 (stdout serialization): identical phases 1-2; phase 3
    PRINTS the observation bytes (3-digit zero-padded decimal +
    comma, `putchar` only) and returns 0 — the statement asserts the
    stdout observable. Costs libc mode.
  * Form 1u-i8 (the KERNEL-INSTANCE template): i8 inputs (2-byte
    stream), i16le-encoded results (4-byte expected — exact, no
    mod-256 collision), fully UNROLLED loop-free body. This is the
    R1 concrete-walk surface: measured Core sizes (oracle --pp=core)
    are 823 lines for the i8 divmod instance vs 2866 for the looped
    i32 form vs 76/172 for the arc-7 t2/t5 slate fixtures — the
    loop-free i8 reduction is what keeps a kernel walk conceivable
    at this rung (spec register, S1).

PLANT TEMPLATES (template-note §plant-test, mandatory): same forms
with the `division` TARGET broken (`x * y` — the wrong-operator
plant); `mod` stays correct so the plant demonstrates a
mismatch-index verdict pointing INTO the quotient bytes.

Builders/encoders are UB-free by construction (harnesses-are-programs
doctrine): byte reassembly in `long` arithmetic, two's-complement
conversion via explicit compare-and-subtract (never an
implementation-defined narrowing of an out-of-range value), negative
results re-encoded via explicit `+ 2^k` before `%`/`/` (no
negative-operand `/`/`%` outside the targets themselves).

All templates cite the targets verbatim (file + CN spec) per the S1
scoping rule; the CN magic comments ride along as ordinary comments
(S0 probe (c): the cabs-json path filters them; zero residue).
-/

import SpecLab.DivMod

set_option autoImplicit false

namespace SpecLab
namespace DivMod

/-! ## The i8 kernel-instance sub-family (exact-width byte codecs) -/

/-- The i8 sub-family's well-formedness: operands in i8 range, y ≠ 0.
No INT_MIN / -1 corner here — division is at `int` width, and
(-128)/(-1) = 128 fits `int`. Honesty label: theorems over this
family quantify the i8 SUB-family of the CN targets' i32 domain. -/
def WfI8 (m : Input) : Prop :=
  -128 ≤ m.x ∧ m.x ≤ 127 ∧ -128 ≤ m.y ∧ m.y ≤ 127 ∧ m.y ≠ 0

instance (m : Input) : Decidable (WfI8 m) := by
  unfold WfI8; infer_instance

def wfI8b (m : Input) : Bool := decide (WfI8 m)

/-- Two's-complement byte of an i8. -/
def toByteI8 (n : Int) : UInt8 := UInt8.ofNat (n % 256).toNat

/-- Signed reading of a byte. -/
def ofByteI8 (b : UInt8) : Int :=
  if b.toNat < 128 then (b.toNat : Int) else (b.toNat : Int) - 256

theorem ofByteI8_toByteI8 (n : Int) (h1 : -128 ≤ n) (h2 : n ≤ 127) :
    ofByteI8 (toByteI8 n) = n := by
  have hval : (toByteI8 n).toNat = (n % 256).toNat := by
    simp only [toByteI8, UInt8.toNat_ofNat']
    omega
  unfold ofByteI8
  rw [hval]
  split <;> omega

/-- The i8 input stream: 2 bytes, x then y. -/
def encodeInputI8 (m : Input) : Stream := [toByteI8 m.x, toByteI8 m.y]

def decodeInputI8 : Codec.Dec Input
  | bx :: by' :: rest => some (⟨ofByteI8 bx, ofByteI8 by'⟩, rest)
  | _ => none

theorem decode_encode_inputI8 (m : Input) (h : WfI8 m) (rest : Stream) :
    decodeInputI8 (encodeInputI8 m ++ rest) = some (m, rest) := by
  obtain ⟨hx1, hx2, hy1, hy2, _⟩ := h
  simp [encodeInputI8, decodeInputI8, ofByteI8_toByteI8 m.x hx1 hx2,
    ofByteI8_toByteI8 m.y hy1 hy2]

/-- i16le two's-complement encoding of a result value (2 bytes —
exact for every value the i8 family can produce: q ∈ [-128, 128],
r ∈ (-128, 128)). -/
def toBytesI16 (n : Int) : Stream :=
  [UInt8.ofNat ((n % 65536).toNat % 256),
   UInt8.ofNat ((n % 65536).toNat / 256)]

/-- The i8 kernel instance's expected observation: 4 bytes,
i16le(quotient) ++ i16le(remainder). -/
def expectedBytesI8 (m : Input) : Stream :=
  toBytesI16 (modelDiv m) ++ toBytesI16 (modelMod m)

/-! ## The generic mismatch-index verdict, pure-side (the sweep's
    prediction function and the plant's expected index) -/

/-- The comparator's verdict, computed pure-side: `0` agreement,
`1 + i` first divergence, `255` length divergence — the Lean mirror
of the C comparator (used by the sweep runner to PREDICT verdicts;
the C comparator in the template is what the theorems observe). -/
def verdictOf (out expected : Stream) : Nat :=
  if out.length ≠ expected.length then 255
  else
    let rec firstDiff : List UInt8 → List UInt8 → Nat → Nat
      | [], _, _ => 0
      | _, [], _ => 0
      | o :: os, e :: es, i =>
        if o ≠ e then 1 + i else firstDiff os es (i + 1)
    firstDiff out expected 0

/-- The wrong-operator plant's model (`division` broken to `x * y`;
`mod` untouched). Plant samples are chosen small so `x * y` stays in
i32 range — the plant must be a broken-but-DEFINED program, not a UB
program. -/
def plantModelFn (m : Input) : Int × Int := (m.x * m.y, modelMod m)

/-- Predicted plant verdict (i32 form). -/
def plantVerdict (m : Input) : Nat :=
  verdictOf (encodeResult (plantModelFn m)) (expectedBytes m)

/-- Predicted plant verdict (i8 kernel form). -/
def plantVerdictI8 (m : Input) : Nat :=
  verdictOf (toBytesI16 (m.x * m.y) ++ toBytesI16 (modelMod m))
    (expectedBytesI8 m)

/-- Form 2's expected stdout: each observation byte as 3-digit
zero-padded decimal + comma (the C `put_byte` mirror). -/
def render3 (bs : List UInt8) : String :=
  String.join (bs.map fun b =>
    let n := b.toNat
    s!"{n / 100}{n / 10 % 10}{n % 10},")

/-! ## The C template text.
    Layout note: every template is three LITERAL parts consumed by
    `mkHarness` (the single trust point); the shared target/citation
    text is factored as string constants CONCATENATED into the parts
    — plain `++` of literals, no substitution of any kind. -/

/-- The verbatim targets, with citation + CN specs (division healthy). -/
def targetsHealthy : String :=
"/* TARGETS — verbatim from deps/cn/tests/cn/division.c and
   deps/cn/tests/cn/mod.c (rems-project/cn, BSD-2-Clause; clean-room
   source per the 2026-08-22 corpus ruling). CN annotations ride
   along as ordinary comments (cabs-json filters magic comments —
   arc-15 S0 probe (c)). */

int division (int x, int y)
/*@ requires y != 0i32;
    ensures return == x/y; @*/
{
    return x / y;
}

int mod (int x, int y)
/*@ requires y != 0i32;
    ensures return == x % y; @*/
{
    return x % y;
}
"

/-- The PLANT targets: `division` broken to the wrong operator
(`x * y`), loudly marked; `mod` untouched. -/
def targetsPlant : String :=
"/* TARGETS — PLANT VARIANT (template-note §plant-test): `division`
   is deliberately BROKEN (wrong operator, `*` for `/`); `mod` is the
   verbatim deps/cn/tests/cn/mod.c target. A healthy-looking verdict
   from this program means the harness is vacuous. */

int division (int x, int y)
/*@ requires y != 0i32;
    ensures return == x/y; @*/
{
    return x * y; /* PLANT: wrong operator */
}

int mod (int x, int y)
/*@ requires y != 0i32;
    ensures return == x % y; @*/
{
    return x % y;
}
"

def header (form : String) : String :=
"/* SpecLab divmod harness (" ++ form ++ ").
   Generated by SpecLab.mkHarness — do not edit by hand.
   Idiom lineage: golean three-phase harness (setup - call - test);
   see lean_frontend/speclab/README.md. */

"

/-- The `pre` part: header + targets + the choices[] opener. -/
def mkPre (form targets : String) : String :=
  header form ++ targets
    ++ "\nstatic const unsigned char choices[] = { "

/-- The `mid` part, shared by every form: close choices[], open
expected[]. -/
def divmodMid : String :=
  " };\nstatic const unsigned char expected[] = { "

/-- Looped i32 main, phases 1-3 (shared by Forms 1/1b/2): builder
(two i32le decodes from `choices[]`), the calls under test, the
observation encoding into `out[]`. UB-free by construction (see
header). Part of `post` — begins by closing the expected[]
initializer. -/
def i32Body : String :=
" };

int main(void)
{
  unsigned char out[8];
  unsigned long i;
  long acc;
  int x, y, q, r;
  /* phase 1 — builder: two i32le values from the choice stream */
  acc = 0L;
  for (i = 0u; i < 4u; i++) { acc = acc + ((long)choices[i] << (8u * i)); }
  if (acc >= 2147483648L) { x = (int)(acc - 4294967296L); } else { x = (int)acc; }
  acc = 0L;
  for (i = 0u; i < 4u; i++) { acc = acc + ((long)choices[4u + i] << (8u * i)); }
  if (acc >= 2147483648L) { y = (int)(acc - 4294967296L); } else { y = (int)acc; }
  /* phase 2 — the calls under test */
  q = division(x, y);
  r = mod(x, y);
  /* phase 3 — observation: i32le-encode both results */
  acc = (long)q; if (acc < 0L) { acc = acc + 4294967296L; }
  for (i = 0u; i < 4u; i++) { out[i] = (unsigned char)(acc % 256L); acc = acc / 256L; }
  acc = (long)r; if (acc < 0L) { acc = acc + 4294967296L; }
  for (i = 0u; i < 4u; i++) { out[4u + i] = (unsigned char)(acc % 256L); acc = acc / 256L; }
"

/-- Form 1 verdict: generic mismatch-index (0 / 1+i / 255). -/
def comparatorMismatchIndex : String :=
"  /* verdict — generic mismatch-index comparator (Form 1) */
  if (sizeof(choices) != 8u || sizeof(expected) != sizeof(out)) { return 255; }
  for (i = 0u; i < sizeof(expected); i++) {
    if (out[i] != expected[i]) { return (int)(1u + i); }
  }
  return 0;
}
"

/-- Form 1b verdict: boolean (0 agree / 1 any divergence). -/
def comparatorBoolean : String :=
"  /* verdict — boolean comparator (Form 1b contender) */
  if (sizeof(choices) != 8u || sizeof(expected) != sizeof(out)) { return 1; }
  for (i = 0u; i < sizeof(expected); i++) {
    if (out[i] != expected[i]) { return 1; }
  }
  return 0;
}
"

/-- Form 2 verdict channel: print the observation to stdout (3-digit
decimal + comma per byte, `render3` mirror), return 0. The
`(void)expected;` keeps the spliced expected[] (the claim, visible in
the program text) formally referenced.

The trailing `putchar('\n')` is LOAD-BEARING (S1 finding, spec
register): the cerberus libc's stdout is line-buffered with no flush
at exit — output not terminated by a newline never reaches the batch
`stdout` observable (both pipelines mirror this faithfully; the first
Form 2 run came back with EMPTY stdout on both sides). Form 2's
statement therefore asserts `render3(expected) ++ "\n"`. -/
def serializerStdout : String :=
"  /* verdict channel — stdout serialization (Form 2 contender).
     NOTE: the final newline is load-bearing — stdout is line-buffered
     and unflushed at exit; a newline-free serialization is UNOBSERVED. */
  (void)expected;
  for (i = 0u; i < sizeof(out); i++) {
    putchar((int)('0' + out[i] / 100u));
    putchar((int)('0' + out[i] / 10u % 10u));
    putchar((int)('0' + out[i] % 10u));
    putchar((int)',');
  }
  putchar((int)'\\n');
  return 0;
}
"

/-- Form 1 (mismatch-index), healthy targets. -/
def divmodForm1Template : HarnessTemplate where
  pre := mkPre "Form 1: expected-array + mismatch-index" targetsHealthy
  mid := divmodMid
  post := i32Body ++ comparatorMismatchIndex

/-- Form 1, PLANT targets (division broken to `*`). -/
def divmodForm1PlantTemplate : HarnessTemplate where
  pre := mkPre "Form 1, WRONG-OPERATOR PLANT" targetsPlant
  mid := divmodMid
  post := i32Body ++ comparatorMismatchIndex

/-- Form 1b (boolean verdict), healthy targets. -/
def divmodForm1bTemplate : HarnessTemplate where
  pre := mkPre "Form 1b: boolean verdict" targetsHealthy
  mid := divmodMid
  post := i32Body ++ comparatorBoolean

/-- Form 1b, PLANT targets (the boolean contender's plant: verdict 1,
index information gone — the comparison's vacuity-debuggability
datapoint). -/
def divmodForm1bPlantTemplate : HarnessTemplate where
  pre := mkPre "Form 1b, WRONG-OPERATOR PLANT" targetsPlant
  mid := divmodMid
  post := i32Body ++ comparatorBoolean

/-- Form 2 (stdout serialization), healthy targets. Libc mode. -/
def divmodForm2Template : HarnessTemplate where
  pre := "#include <stdio.h>\n\n"
    ++ mkPre "Form 2: stdout serialization" targetsHealthy
  mid := divmodMid
  post := i32Body ++ serializerStdout

/-- Form 2, PLANT targets. -/
def divmodForm2PlantTemplate : HarnessTemplate where
  pre := "#include <stdio.h>\n\n"
    ++ mkPre "Form 2, WRONG-OPERATOR PLANT" targetsPlant
  mid := divmodMid
  post := i32Body ++ serializerStdout

/-- The i8 kernel-instance `pre` tail + `mid`: BLOCK-SCOPE const
arrays (deliberate deviation from the template note's file-scope
`static` spelling, register-logged: block scope keeps the pinned
file's `globs` EMPTY, so the statement file term stays in the arc-7
slate shape — the drive prefix walks identically to the T1/T5 prefix
pattern). -/
def i8PreTail : String :=
"
int main(void)
{
  const unsigned char choices[2] = { "

def i8Mid : String :=
  " };\n  const unsigned char expected[4] = { "

/-- The i8 KERNEL-INSTANCE body: loop-free, straight-line — 2-byte
stream (i8 x, i8 y), 4-byte expected (i16le q, i16le r), unrolled
mismatch-index comparator. -/
def i8Body : String :=
" };
  int x, y, q, r;
  /* phase 1 — builder: two i8 values from the choice stream */
  x = (int)choices[0]; if (x >= 128) { x = x - 256; }
  y = (int)choices[1]; if (y >= 128) { y = y - 256; }
  /* phase 2 — the calls under test */
  q = division(x, y);
  r = mod(x, y);
  /* phase 3 — observation: i16le-encode both results;
     verdict — unrolled mismatch-index comparator */
  if (q < 0) { q = q + 65536; }
  if (r < 0) { r = r + 65536; }
  if (sizeof(choices) != 2u || sizeof(expected) != 4u) { return 255; }
  if ((unsigned char)(q % 256) != expected[0]) { return 1; }
  if ((unsigned char)(q / 256) != expected[1]) { return 2; }
  if ((unsigned char)(r % 256) != expected[2]) { return 3; }
  if ((unsigned char)(r / 256) != expected[3]) { return 4; }
  return 0;
}
"

/-- Form 1u-i8 (the kernel-instance template), healthy targets. -/
def divmodI8Template : HarnessTemplate where
  pre := header "Form 1u-i8: kernel instance, unrolled, i8 stream"
    ++ targetsHealthy ++ i8PreTail
  mid := i8Mid
  post := i8Body

/-- Form 1u-i8, PLANT targets. -/
def divmodI8PlantTemplate : HarnessTemplate where
  pre := header "Form 1u-i8, WRONG-OPERATOR PLANT"
    ++ targetsPlant ++ i8PreTail
  mid := i8Mid
  post := i8Body

/-! ## Rendered-harness constructors (emitter entry points; the
    expected[] argument is always the PURE model image — computed at
    statement-construction time, never by the C) -/

/-- Form 1 harness for a well-formed input. -/
def mkDivModForm1 (m : Input) : String :=
  mkHarness divmodForm1Template (encodeInput m) (expectedBytes m)

/-- Form 1 harness for a RAW STREAM (fuzz entry: expected computed
from the decoded model — callers own `ValidStream`). -/
def mkDivModForm1OfStream (s : Stream) : String :=
  mkHarness divmodForm1Template s (expectedOfStream s)

def mkDivModForm1Plant (m : Input) : String :=
  mkHarness divmodForm1PlantTemplate (encodeInput m) (expectedBytes m)

def mkDivModForm1b (m : Input) : String :=
  mkHarness divmodForm1bTemplate (encodeInput m) (expectedBytes m)

def mkDivModForm1bPlant (m : Input) : String :=
  mkHarness divmodForm1bPlantTemplate (encodeInput m) (expectedBytes m)

def mkDivModForm2 (m : Input) : String :=
  mkHarness divmodForm2Template (encodeInput m) (expectedBytes m)

def mkDivModForm2Plant (m : Input) : String :=
  mkHarness divmodForm2PlantTemplate (encodeInput m) (expectedBytes m)

def mkDivModI8 (m : Input) : String :=
  mkHarness divmodI8Template (encodeInputI8 m) (expectedBytesI8 m)

def mkDivModI8Plant (m : Input) : String :=
  mkHarness divmodI8PlantTemplate (encodeInputI8 m) (expectedBytesI8 m)

end DivMod
end SpecLab
