# Hexadecimal floating constants with a long mantissa and a subnormal value are off by one quantum: `str_fval` delegates to OCaml's `float_of_string`, which rounds twice (INHERITED from the OCaml runtime)

**Affected:** `memory/concrete/impl_mem.ml:2523-2524` (`let str_fval str = float_of_string str`,
the concrete memory model's reading of a C floating constant — reached from
`translation.lem:207-209`, `A.ConstantFloating (str, _)` → `Mem.str_fval str`) and
`util/cerb_floating.ml:8-16` (`Cerb_floating.of_string`, the Lem-level `Float.of_string`
target used by the defacto model): both delegate to the OCaml runtime's
`caml_float_of_string` → `caml_float_of_hex` (OCaml 5.4.0 `runtime/floats.c:286-372`).
No Cerberus source computes the value. Checked against `master` @ `b9aeedcb4`: the two
Cerberus files are the merge-base's.

## Description

C11 §6.4.4.2#3 (last sentence): "For hexadecimal floating constants when FLT_RADIX is a
power of 2, the result is correctly rounded." OCaml's `caml_float_of_hex` converts the
(up to 64-bit) integer mantissa to `double` (`floats.c:355`, a rounding to 53 bits) and
then scales it with `ldexp` (`:369`); when the result is SUBNORMAL, `ldexp` rounds a
second time, and on a tie of that second rounding the answer is one subnormal quantum
(2^-1074) away from the correctly rounded value. Normal-range results and decimal
constants (`strtod`) are unaffected. The full analysis and the runtime-side remedy are
in the OCaml-target draft [`ocaml/01-float-of-hex-double-rounding-subnormal.md`](ocaml/01-float-of-hex-double-rounding-subnormal.md).

## Reproducer

```c
int main(void) { return 0x8000000000000BFp-1082 == 0x1.0000000000002p-1023; }
```

The two literals denote the same binary64 value: `0x8000000000000BFp-1082 =
2^-1023 + (191/256)·2^-1074`, whose nearest representable neighbour is
`2^-1023 + 2^-1074 = 0x1.0000000000002p-1023` (bits `0x0008000000000001`).

Observed 2026-09-15 (fork oracle = upstream `b9aeedcb4` plus this project's fork-side
changes, none of which touch this path; command shape as in the tray README):

```
$ cerberus --nolibc --exec --batch --mode=exhaustive r5-hex-subnormal-double-rounding.c
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

Pristine upstream (`b9aeedcb4`, rebuilt from the git archive with its own OCaml 5.4.0
prefix — `docs/2026-09-06_independent-oracle-and-fork-pins.md`):

```
$ main.exe --runtime=… --nolibc --exec --batch --mode=exhaustive r5-hex-subnormal-double-rounding.c
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
Time spent: 0.024311 seconds
rc=0
```

Independent references: `gcc -std=c11 -O0` → exit **1**; Python 3
`float.fromhex('0x8000000000000BFp-1082') == float.fromhex('0x1.0000000000002p-1023')`
→ `True`; OCaml itself: `float_of_string "0x8000000000000BFp-1082" = float_of_string
"0x1.0000000000002p-1023"` → `false` (`%h`: `0x0.8p-1022` vs `0x0.8000000000001p-1022`).

## Observed vs expected

Expected `Specified(1)` (the constants are equal after correct rounding); observed
`Specified(0)`: Cerberus reads the first constant as `0x1p-1023`, one quantum low.
Mechanism (traced in the OCaml draft): `m = 0x8000000000000BF` (60 bits) → 53 bits rounds
DOWN at the `2^7` position (`191 → 128`), then `ldexp(·, -1082)` lands on an exact tie
`2^-1023 + 2^-1075` and ties-to-even lands on `2^-1023`; the exact value was above the tie.

## Impact

Minor: a hexadecimal constant with more than 53 significant bits AND a subnormal value AND
a 53-bit pre-rounding on a tie. But it is a silent conformance defect against §6.4.4.2#3
that Cerberus cannot see, since the runtime returns a value without any signal.

## Proposed remedy

Cerberus-side, two options: (a) wait for the OCaml runtime fix (the OCaml draft proposes
rounding once in the integer domain for subnormal results) — nothing to change in
Cerberus; or (b) parse hexadecimal floating constants in Cerberus itself: read the
mantissa and binary exponent exactly (Zarith), and round ONCE to binary64 (nearest,
ties-to-even, gradual underflow) — a small function, the same shape the project's Lean
port now uses. Option (b) also removes the dependence on the host `strtod` for decimal
constants if extended to them, which §6.4.4.2#3 does not require.

## Classification

**INHERITED / minor.** Not a Cerberus bug: no Cerberus source is involved in the
conversion, and Cerberus's use of `float_of_string` is the natural one. Recorded so that
the runtime dependency is visible to the Cerberus authors, and so that the pin in this
project's fork retires when the runtime is fixed.

## Provenance

Found 2026-09-12 by this project's differential battery for correctly rounded C floating
literals (record `lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` §D1
row 106; the fork's Lean port disagreed with the oracle on exactly this row, gcc and
Python agreed with the port). Admitted to the fork's ISO-fix register as **R5**
[USER 2026-09-15] (`lean_frontend/VALIDATION.md` §2); pinned Lean-right/oracle-wrong in
`tests/immaculate/nolibc/r5-hex-subnormal-double-rounding.c`. Localisation and this draft
by Claude (Fable 5.1) under operator direction; the filed issue carries an AI-provenance
note per the tray's policy (`INDEX.md`, "Provenance labeling policy").
