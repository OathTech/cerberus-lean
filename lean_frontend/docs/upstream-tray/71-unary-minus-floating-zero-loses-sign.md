# `-z` with `z == 0.0` is `+0.0`: unary minus on a floating operand is elaborated as `0.0 - e`, so negating a zero (and the literal `-0.0`) loses the sign

**Affected:** `frontend/model/translation.lem` @ `c3ff8c53f`, the `A.AilEunary A.Minus e` arm (`(* STD §6.5.3.3#3 *)`):
for a floating `result_ty` it builds `Caux.mk_op_pe C.OpSub zero_pe (…)` with `zero_pe = Caux.mk_floating_value_pe
Mem.zero_fval` — the negation is the subtraction `0.0 - e`. The shared model: the OCaml backend and our Lean port
agree.

## Description

C17 6.5.3.3#3: "The result of the unary - operator is the negative of its (promoted) operand." For a floating operand
the negative of `x` is `x` with its sign reversed (IEC 60559 `negate`, Annex F.3 for an implementation that defines
`__STDC_IEC_559__`; for every other implementation the sign of a negated zero is the only observable, and every
compiler reverses it). `0.0 - x` is not the same operation: in round-to-nearest, `0.0 - 0.0` is `+0.0`, so `-z` for
`z == 0.0` yields `+0.0`, and the literal `-0.0` (the unary minus applied to the constant `0.0`) yields `+0.0` as well.
The sign of zero is observable through `printf("%f")` (`-0.000000`), through `copysign`/`signbit`, and through `1.0 / x`
(`-inf` vs `+inf`).

## Reproducer

```c
#include <stdio.h>
int main(void) { double z = 0.0; printf("[%f][%f][%f][%f]\n", -z, z * -1.0, 0.0 - z, -0.0); return 0; }
```

```
$ cerberus --exec --batch pf_negzero.c
Defined {value: "Specified(0)", stdout: "[0.000000][-0.000000][0.000000][0.000000]\n", stderr: "", blocked: "false"}
```

(verbatim, 2026-11-07, un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc; the fork's oracle and our Lean
port print the identical line.)

```
$ gcc -std=c11 -w -O0 pf_negzero.c && ./a.out
[-0.000000][-0.000000][0.000000][-0.000000]
```

(gcc 13.3.0; verbatim 2026-11-07.) The second cell (`z * -1.0`, a multiplication) keeps the sign on Cerberus too, and
the third (`0.0 - z`) is `+0.0` on both — the two cells isolate the defect to the elaboration of unary minus, not to
the formatter or to the floating-point runtime.

## Observed vs expected

- Observed: `-z` and `-0.0` print `0.000000`.
- Expected: `-0.000000` (a negative zero).

## Impact

A silently wrong value on conforming input. Programs that test the sign of a zero (`signbit`, `copysign`, division by
a signed zero), or print it, see `+0.0` where every conforming implementation gives `-0.0`; `-0.0` literals in tables
of constants are silently positive.

## Proposed remedy

Elaborate unary minus on a floating operand as a negation (a Core floating negate, or `Caux.mk_op_pe C.OpSub` on a
NEGATIVE zero — `-0.0 - x` equals `-x` for every `x` in round-to-nearest, zeros included); the integer arm is unaffected
(`0 - e` is exact there).

## Fork status (2026-11-07)

Not fixed in the fork: found by the fix/printf-refusals vicinity probe as a non-formatter sibling (the record's §3.3
row 20; the pre-merge review's P3-5 asked for this filing). `tests/coverage/fmt/fmt-005-f-negative-zero.c` carries the
shape (its `0.000000` cells where gcc prints `-0.000000`, both engines agreeing); a fix is a translation-layer slice with
its own witness and charter (TODO.md names it).

## Classification

**TRUE BUG** (silently wrong value on conforming input; the clause is explicit and the mechanism is a one-line
elaboration choice).

## Provenance

Found by the fix/printf-refusals vicinity matrix (2026-11-07; the `f_zero_neg` and `f_negzero_diag` probes), the
mechanism located in `translation.lem`'s `Minus` arm by reading; both engines and pristine agree. Localisation and this
draft by Claude (Fable 5.1) under operator direction; the filed issue carries an AI-provenance note per the tray's
policy.
