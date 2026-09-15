# Draft — OCaml runtime: `float_of_string` on a hexadecimal literal rounds twice when the result is subnormal (`caml_float_of_hex`: int64→double, then `ldexp`)

Target: `ocaml/ocaml` (runtime, `runtime/floats.c`). Drafted 2026-09-15;
NOT filed — filing is the operator's call (network + GitHub).
Classification: **TRUE BUG** (a correctly-rounded conversion is what the
code's own comment at `:340-343` sets out to produce — "round m to odd so
that the later rounding of m to FP produces the correct result" — and it
does so for every normal-range result; for a subnormal result a second
rounding follows the first and the answer is off by one quantum on ties).

**Affected:** `runtime/floats.c:286-372` (`caml_float_of_hex`) at OCaml
5.4.0, in particular

```c
  f = (double) (int64_t) m;          /* floats.c:355 — rounds m (≤ 64 bits) to 53 bits, ties-to-even */
  if (exp != 0) f = ldexp(f, exp);   /* floats.c:369 — exact for a normal result; ROUNDS AGAIN for a subnormal one */
```

reached from `caml_float_of_string` (`:376-425`) for every `0x…` literal.

## Description

`caml_float_of_hex` accumulates the hexadecimal mantissa in a 64-bit
integer `m` (excess digits beyond 64 bits are absorbed with round-to-odd,
`:342-345`, so that ONE subsequent rounding to 53 bits is correct), then
converts `m` to `double` (`:355`) — the rounding to 53 significant bits —
and finally scales by `ldexp` (`:369`). When the scaled result is a NORMAL
binary64 value the scaling is exact and the result is correctly rounded.
When the scaled result is SUBNORMAL, `ldexp` must round the 53-bit
significand a second time to the subnormal's shorter precision. Two
successive roundings are not one: when the first rounding lands exactly
on a tie of the second, ties-to-even can go the wrong way relative to the
exact value. The result differs from the correctly rounded value by one
subnormal quantum (2^-1074).

## Reproducer

OCaml one-liner (toplevel 5.4.0, observed 2026-09-15 in this project's switch):

```
$ ocaml
# float_of_string "0x8000000000000BFp-1082" = float_of_string "0x1.0000000000002p-1023";;
- : bool = false
# Printf.printf "%h\n" (float_of_string "0x8000000000000BFp-1082");;
0x0.8p-1022
# Printf.printf "%h\n" (float_of_string "0x1.0000000000002p-1023");;
0x0.8000000000001p-1022
```

(verbatim from `ocaml .tmp/r5.ml`, a three-line script printing the
comparison and the two `%h` forms: `false` / `0x0.8p-1022` /
`0x0.8000000000001p-1022`.)

The same value as a C program (the Cerberus C semantics, which uses
`float_of_string` for floating literals, is where we met it):

```c
int main(void) { return 0x8000000000000BFp-1082 == 0x1.0000000000002p-1023; }
```

`gcc -std=c11 -O0` → exit 1 (the two literals denote the same double);
Python 3 `float.fromhex('0x8000000000000BFp-1082') == float.fromhex('0x1.0000000000002p-1023')`
→ `True`, bits `0x0008000000000001`.

## Observed vs expected — the exact arithmetic

* The literal `0x8000000000000BFp-1082` is `(2^59 + 0xBF) · 2^-1082 = (2^59 + 191) · 2^-1082`
  `= 2^-1023 + 191 · 2^-1082`. The binary64 subnormal quantum is `2^-1074`, and
  `191 · 2^-1082 = (191/256) · 2^-1074 ≈ 0.746` quanta. So the exact value lies
  between `2^-1023` (bits `0x0008000000000000`) and `2^-1023 + 2^-1074`
  (`0x0008000000000001` = `0x1.0000000000002p-1023`), nearer the latter.
  **Expected** (IEEE 754-2019 §4.3.1 roundTiesToEven): `0x1.0000000000002p-1023`.
* **Observed**: `0x0.8p-1022` = `2^-1023`, one quantum low. Mechanism: `m =
  0x8000000000000BF` has 60 significant bits; `(double)(int64_t) m` keeps 53,
  i.e. rounds at the `2^7 = 128` position: `191 = 128 + 63`, `63 < 64` → down to
  `2^59 + 128`. Then `ldexp(·, -1082)` gives `2^-1023 + 128 · 2^-1082 = 2^-1023 + 2^-1075`
  — now EXACTLY halfway between the two subnormal neighbours; ties-to-even
  picks the even significand, `2^-1023`. The first rounding threw away the
  information (the `63`) that the exact value was ABOVE the tie.
* Scope: hexadecimal literals with more than 53 significant bits whose value is
  subnormal and whose 53-bit pre-rounding lands on a tie of the final
  precision. Normal-range results are unaffected (`ldexp` exact), and decimal
  literals take the C library's `strtod` (`:398-419`), which rounds once.

## Impact

Minor in breadth (a subnormal hexadecimal literal with a long mantissa is rare
in practice), but it is a wrong answer from a routine whose comment promises
correct rounding, and it is invisible: no exception, no flag, one quantum off.
It surfaced in a differential test between the Cerberus C semantics (OCaml,
using `float_of_string` for C floating constants) and a correctly rounded
reimplementation; C11 §6.4.4.2#3 requires hexadecimal floating constants to be
correctly rounded when `FLT_RADIX` is a power of 2, so a C front end built on
`float_of_string` inherits a conformance defect here.

## Proposed remedy

Round once. Two shapes, either sufficient:

1. **Pre-round in the integer domain when the result is subnormal.** After
   the mantissa loop, with `m` (≤ 64 bits, LSB already sticky-odd if digits
   were dropped) and `exp`: the leading bit of the result sits at
   `2^(exp + bitlength(m) − 1)`. If that is `≥ −1022` the result is normal and
   the present code is correct. Otherwise the result's quantum is `2^-1074`, so
   let `k = −1074 − exp` be the number of low bits of `m` below the quantum; if
   `k ≥ 1`, shift `m` right by `k` with ROUND-TO-NEAREST-EVEN on the shifted-out
   bits (guard bit + sticky, where the sticky includes the round-to-odd LSB),
   then `f = (double) m'` is exact (`m' < 2^52`) and `ldexp(f, −1074)` is exact.
   (For `k ≥ 64` the result is `0` or the smallest subnormal by the same rule.)
2. **Keep the sticky bit through to the target precision**: compute the result's
   target precision first (53, or `53 − (−1022 − E)` for a subnormal binade
   `E`), truncate `m` to THAT many significant bits with the same round-to-odd
   the loop already uses (so the LSB carries the sticky information), and only
   then convert and scale — the single int64→double conversion is then exact
   or rounds once at the right position.

Either way the excess-digit handling at `:342-345` stays as it is; only the
subnormal case gains a step.

## Classification

**TRUE BUG.** The routine's stated design (round-to-odd so that "the later
rounding of m to FP produces the correct result") is the standard one-rounding
scheme; it is complete for normal results and incomplete for subnormal ones,
where a second rounding occurs in `ldexp`.

## Provenance

Found 2026-09-12 by the Cerberus→Lean project's differential battery for
correctly rounded C floating literals (record
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` §D1, row
106): the Lean port's exact-rational conversion disagreed with the OCaml
oracle on this one row, gcc and Python agreed with the port, and the cause was
read in `floats.c` and confirmed by modelling the two steps in Python
(`math.ldexp(float(m), -1082)` reproduces `0x1p-1023` exactly). Localisation
and this draft by Claude (Fable 5.1) under operator direction; the filed issue
carries an AI-provenance note per the tray's policy (`../INDEX.md`,
"Provenance labeling policy").
