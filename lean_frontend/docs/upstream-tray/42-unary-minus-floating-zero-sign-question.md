# Question: unary minus on a floating ZERO yields +0 — `-x` is elaborated as `0.0 - x`, where IEEE 754 §5.5.1 / C11 Annex F negation gives −0

**Affected (for orientation):** `frontend/model/translation.lem:1525-1554` (the
`A.AilEunary A.Minus e` arm of the elaborator, "STD §6.5.3.3#3"): for a floating
`result_ty` the arm builds `zero_pe = Caux.mk_floating_value_pe Mem.zero_fval` and the
Core expression `Caux.mk_op_pe C.OpSub zero_pe e'` — the negation is a SUBTRACTION from
`+0.0`; `frontend/model/core_eval.lem:446` (`OpSub -> Mem_common.FloatSub`);
`memory/concrete/impl_mem.ml:2519` (`zero_fval` = `0.0`) and `:2529-2534` (`op_fval
FloatSub` = OCaml `(-.)`). Checked against `master` @ `b9aeedcb4`: the cited lines are
the merge-base's. Under IEEE 754 round-to-nearest, `(+0) − (+0) = +0`, whereas
`negate(+0) = −0` (IEEE 754-2019 §5.5.1: "negate(x) copies a floating-point operand x to
a destination in the same format, reversing the sign bit"); C11 Annex F.3 maps the unary
`-` operator to `negate` for IEC 60559 implementations. For every non-zero operand
`0 − x = −x` exactly, so only zeros are affected.

## Observation

Four probes read the sign bit of a `double` through a union (`u.b[7] >> 7`; LP64,
little-endian). Verbatim, 2026-09-15, three engines + gcc (`--nolibc --exec --batch
--mode=exhaustive`; fork oracle bin `89a899c5…` and its Lean port `e36af96d…` at
`arc/semantics-audit-repairs`; pristine = upstream `b9aeedcb4` built with upstream Lem;
`gcc -std=c11 -O0 -w`; full file
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-evidence/d4-negzero-three-engine.txt`):

```c
/* a: negate a zero VARIABLE */
int main(void) { union { double d; unsigned char b[8]; } u; double z = 0.0; u.d = -z; return u.b[7] >> 7; }
/* d: negate the (unsigned) literal 0x0p0 — the lexer yields the constant, `-` is unary minus in the AST */
int main(void) { union { double d; unsigned char b[8]; } u; u.d = -0x0p0; return u.b[7] >> 7; }
```
```
a: fork oracle  Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} rc=0
a: pristine     Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} rc=0
a: fork Lean    Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} rc=0
a: gcc exit=1
d: fork oracle  Defined {value: "Specified(0)", …} rc=0 / pristine Specified(0) rc=0 / fork Lean Specified(0) rc=0 / gcc exit=1
```

Controls (agreement everywhere — the sign machinery itself is fine):

```c
/* b: multiplication by -1.0 gives -0.0 on every engine */
int main(void) { union { double d; unsigned char b[8]; } u; u.d = 0.0 * -1.0; return u.b[7] >> 7; }
/* c: negating a non-zero value sets the sign bit on every engine */
int main(void) { union { double d; unsigned char b[8]; } u; u.d = -1.5; return (u.b[7] >> 7) | ((u.b[7] >> 5) & 2); }
```
```
b: fork oracle Specified(1) rc=0 / pristine Specified(1) rc=0 / fork Lean Specified(1) rc=0 / gcc exit=1
c: fork oracle Specified(1) rc=0 / pristine Specified(1) rc=0 / fork Lean Specified(1) rc=0 / gcc exit=1
```

So Cerberus has signed zeros (`0.0 * -1.0` is −0) and correct negation of non-zero values;
only `-(±0)` differs from IEEE negation, exactly as the `0.0 - x` elaboration predicts
(`-(−0)` would likewise give `+0 − (−0) = +0`, correct by coincidence).

## Question for upstream

C11 §6.5.3.3#3, verbatim (N1570): "The result of the unary - operator is the negative of
its (promoted) operand." Does the concrete memory model intend IEC 60559 (Annex F)
semantics for floating negation — in which case `-x` should be the sign-bit flip
(`negate`), not `0.0 - x` — or is the concrete model explicitly NOT an Annex F
implementation (it does not define `__STDC_IEC_559__`), so that `+0` is an acceptable
"negative of" `+0`? If the latter, the inconsistency with `0.0 * -1.0` (−0) and with every
mainstream compiler is worth a note in the model's documentation; if the former, the
elaboration is a one-arm fix.

## Impact

Minor. Observable only by inspecting the sign of a negated zero: `1.0 / -x` (±inf),
`signbit(-x)`, `copysign`, `printf("%f", -x)` (`-0.000000` vs `0.000000`), byte
inspection. No effect on comparisons (`-0.0 == 0.0`) or on non-zero arithmetic.

## Proposed remedy

If Annex F semantics are intended: elaborate floating unary minus to a dedicated negation
rather than `OpSub zero_pe e` — e.g. a `neg_fval` in the memory-model interface
(`Impl_mem`: `Float.neg`), or `mul_fval` by `-1.0`, or `OpSub` with a signed-zero-aware
rule (`0 − x` with `x = +0` → −0 is NOT what IEEE subtraction gives, so the operator must
change, not the operand). The integer half of the arm is unaffected (`0 − x` is exact
for integers, and the exceptional-condition wrapping there is deliberate).

## Classification

**UNCLEAR / QUESTION**, minor. Both fork engines and upstream AGREE with each other, so
this is not a fault of the Lean port; the fork makes NO change (the mirror rule:
`lean_frontend/VALIDATION.md` §0–§1 — an oracle-suspect row is correct under the rule
until the oracle moves). The probe programs are NOT lane files (the gcc second-oracle
lane would read them `DISAGREE`); they live in the evidence directory named above.

## Provenance

Found 2026-09-12 during the correctly-rounded-literal battery of the semantics-audit
repairs slice (record `lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md`
§D1 "Withdrawn row 098" — the drafted negative-zero literal row turned out to test unary
minus, not literal conversion, because the C lexer yields an unsigned constant), the
mechanism located 2026-09-15 in the elaborator arm cited above (charter §6 "Side finding
for D4"; §8 item 8 numbers it 42). Observed, localised and drafted by Claude (Fable 5.1)
[AGENT] under operator direction; the filed issue carries an AI-provenance note per the
tray's policy (`INDEX.md`, "Provenance labeling policy").
