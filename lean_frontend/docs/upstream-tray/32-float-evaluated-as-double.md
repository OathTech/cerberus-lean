# `float` is represented, stored and evaluated as `double` (`sizeof(float) == 8`), while the shipped `<float.h>` declares `FLT_MANT_DIG 24`

**Affected:** `ocaml_frontend/ocaml_implementation.ml:206-208`
(`DefaultImpl.sizeof_fty`: `RealFloating Float -> Some 8 (* TODO:hack ==>
4 *)`); `memory/concrete/impl_mem.ml:1151-1156` (a `float` object is
stored as `Int64.bits_of_float fval` over `sizeof` bytes — the double's
bit pattern), `:982` (loaded back with `Int64.float_of_bits`), `:2529`
(`op_fval`: OCaml `float` = IEEE double arithmetic for every floating
type), `:2549` (`fvfromint`), `:2553` (`ivfromfloat`);
`runtime/libc/include/float.h:4` (`#define FLT_MANT_DIG 24`, and the
`FLT_MIN`/`FLT_MAX`/`FLT_EPSILON` family at :5-…). Checked against
`master` @ `b9aeedcb4`: all three files byte-identical (`impl_mem.ml`
through :2998).

## Description

The concrete model has ONE floating representation, OCaml's `float`
(IEEE binary64). Values of C type `float` are computed in it, converted
to it without rounding (`fvfromint`), and stored as its 8-byte bit
pattern with `sizeof(float) = 8`. The `TODO:hack ==> 4` comment shows
this is a known shortcut.

On its own this is a permitted implementation choice: C11 §6.2.5#10 only
requires "the set of values of the type `float` is a subset of the set of
values of the type `double`", so a `float` whose value set EQUALS
`double`'s is conforming, §6.3.1.5 then requires no rounding on the
conversions, and `sizeof(float)` is implementation-defined. What is NOT
conforming is the shipped `<float.h>`, which describes a different type:
`FLT_MANT_DIG 24` (§5.2.4.2.2#11 requires it to be the number of base-2
digits in the `float` significand — here 53), `FLT_MAX 3.40282347e+38F`
(the largest finite `float` here is `DBL_MAX`), `FLT_EPSILON`, `FLT_DIG`,
`FLT_MIN_EXP`/`FLT_MAX_EXP` likewise. A program that reasons about its
own `float` through `<float.h>` (`x + FLT_EPSILON != x`, `FLT_MANT_DIG`
loops, `ldexpf`/`frexpf` bounds) is told the wrong facts.

## Reproducer

`tests/noodle-probes/float/float_single_precision.c`:

```c
#include <stdio.h>
int main(void) {
  float a = 0.1f, b = 0.2f, c = 0.3f;
  float third = 1.0f / 3.0f;
  float big = 16777217;
  printf("%d ", a + b == c);                      /* 1 in float; 0 in double */
  printf("%d ", (int)((float)0.1 * 1e9));         /* 100000001 (float 0.1 promoted) */
  printf("%d ", (double)third * 3 == 1.0);        /* 0 */
  printf("%d ", (int)big);                        /* 16777216 */
  printf("%d ", (double)(float)0.1 == 0.1);       /* 0 */
  printf("%d ", 0.1 + 0.2 == 0.3);                /* 0 */
  printf("%d ", (float)1e10 == 1e10);             /* 1 exact */
  printf("%d\n", (int)((1.0f + 1e-8f) == 1.0f));  /* 1 */
  return 0;
}
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive float_single_precision.c
Defined {value: "Specified(0)", stdout: "0 100000000 1 16777217 1 0 1 0\n", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the fork's oracle at `928aa1e76` and our Lean port print the identical
line — our port mirrors the implementation table deliberately.)

```
$ gcc -std=c11 -O0 float_single_precision.c && ./a.out
1 100000001 0 16777216 0 0 1 1
```

(gcc 13.3.0, x86-64, `FLT_EVAL_METHOD 0`; verbatim 2026-09-05.)
`sizeof(float)`, `sizeof(1.0f)` and `sizeof(f + 1.0f)` are 8 on both
Cerberus engines (probe `float/float_constants.c`), 4 under gcc.

## Observed vs expected

- Observed: every `float` computation is exact to 53 bits; `(int)(float)
  16777217` is 16777217; `sizeof(float)` is 8; `<float.h>` says 24-bit
  significand.
- Expected: EITHER a 24-bit `float` (gcc's line) OR a `<float.h>` that
  describes the 53-bit `float` the implementation actually has
  (`FLT_MANT_DIG 53`, `FLT_MAX DBL_MAX`, …) and `sizeof(float)` consistent
  with the ABI the headers otherwise assume (`stdint.h`, `limits.h`).

## Impact

Numerical programs cannot be checked for single-precision rounding
behaviour at all (no rounding exists), and the test corpora can never see
a float-precision defect in either direction — every Cerberus-vs-Cerberus
comparison agrees by construction. The `<float.h>` inconsistency is the
part with a definite wrong answer: programs that compute with
`FLT_EPSILON`/`FLT_MANT_DIG`/`FLT_MAX` get values that do not describe the
type they are computing in.

## Proposed remedy

Either (preferred, medium effort): give `float` a binary32 arm — round
through a 32-bit representation in `fvfromint`, in `op_fval`'s result when
the C type is `float`, on store/load (`Int32.bits_of_float`), set
`sizeof_fty Float = 4`; the elaboration already threads the floating type
into `Fvfromint`/`Ivfromfloat`/arithmetic so the memory model has the
information. Or (stopgap, small): make `runtime/libc/include/float.h`
consistent with the model (`FLT_MANT_DIG 53`, `FLT_DIG 15`, `FLT_MIN_EXP
(-1021)`, `FLT_MAX_EXP 1024`, `FLT_MIN DBL_MIN`, `FLT_MAX DBL_MAX`,
`FLT_EPSILON DBL_EPSILON`) and document `sizeof(float) == 8` as the
implementation's choice, so the shipped headers and the model agree.

## Classification

**INTENDED GAP** (the `TODO:hack` is explicit and the choice is
permitted by §6.2.5#10) **with a TRUE BUG on the consistency side**: the
shipped `<float.h>` describes a `float` the implementation does not have
(§5.2.4.2.2). Our port mirrors the model and treats the gcc disagreement
on float-precision observers as a declared implementation-profile
difference, not as an error on either side.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding F1); both engines agree (shared implementation table), gcc
differs. The ISO analysis (permitted value set; the `<float.h>`
inconsistency as the actual defect) is from our design review of that
record. Re-verified 2026-09-05 on the un-forked upstream binary + runtime
@ `b9aeedcb4`, the fork's oracle and the Lean port (lines above verbatim).
Localisation and this draft by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's
policy.
