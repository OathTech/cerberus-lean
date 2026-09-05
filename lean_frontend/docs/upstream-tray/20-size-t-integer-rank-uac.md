# `size_t` has no integer conversion rank: usual arithmetic conversions with `int`/`char`/`short`/`unsigned int` compute at 32 bits

**Affected:** `frontend/model/ail/ailTypesAux.lem:460-546` (`lt_integer_rank`,
whose inner `lt_integer_rank_ISO` :461-529 enumerates the standard types
and ends in a catch-all `| _ -> (* TODO: this is probably wrong for macro
types *) false` :527-529); `frontend/model/translation.lem:1416-1478`
(`usual_arithmetic_conversion_aux`; the "unsigned operand of greater or
equal rank" branches :1453-1456 and the last-resort branches :1457-1477
that convert both operands to `make_corresponding_unsigned` of the SIGNED
operand's type). Checked against `master` @ `b9aeedcb4`: line numbers are
master's; our copies of both files differ from master only by
Lean-target `declare` lines outside the cited regions (region diff
empty, verified 2026-09-05).

## Description

Cerberus represents `size_t` as its own `integerType` constructor
(`Size_t`, `frontend/model/ctype.lem`), not as an alias of the
implementation's `unsigned long`. `lt_integer_rank_ISO` assigns ranks only
to `_Bool`, the `char`s, `short`, `int`, `long` (and by fall-through
`long long`); any pair involving a macro type — `Size_t`, `Ptrdiff_t`,
`Intptr_t`, … — hits the catch-all and is "not less than" in BOTH
directions, and `eq_integer_rank` does not hold either. In
`usual_arithmetic_conversion_aux` the pair (`size_t`, `int`) therefore
fails every rank-based branch and falls to the last resort: unless
`all_values_representable_in(size_t, int)` (false) both operands are
converted to `make_corresponding_unsigned(int)` = `unsigned int`. The
result is then re-wrapped in the (correctly typed) `size_t`, so the
truncation is invisible unless an operand value is ≥ 2^32. The elaborated
Core for `n + 1` with `size_t n` (`--pp=core`, verbatim 2026-09-05,
upstream binary):

```
Specified(wrapI_add('size_t', if all_values_representable_in('size_t',
  'signed int') then
    __conv_int__('signed int', a_519)
  else
    __conv_int__('unsigned int', a_519), if all_values_representable_in('size_t',
  'signed int') then
    __conv_int__('signed int', a_520)
  else
    __conv_int__('unsigned int', a_520)))
```

## Reproducer

`tests/noodle-probes/int/int_size_t_uac_rank.c` in our tree:

```c
#include <stddef.h>
#include <stdio.h>
int main(void) {
  size_t n = 5000000000; unsigned u = 1; char c = 1; short s = 1;
  printf("%llu %llu %llu ", (unsigned long long)(n + 1), (unsigned long long)(n * 2), (unsigned long long)(n / 2 + 1));
  printf("%llu %llu %llu ", (unsigned long long)(n + u), (unsigned long long)(u + n), (unsigned long long)(n + c));
  printf("%d %llu %llu\n", n == 705032704, (unsigned long long)(s + n), (unsigned long long)(1 + n));
  return 0;
}
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive int_size_t_uac_rank.c
Defined {value: "Specified(0)", stdout: "705032705 1410065408 352516353 5000000001 705032705 705032705 1 705032705 705032705\n", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`;
the OCaml Cerberus built from this repository at `928aa1e76` and our Lean
port print the identical line — the defect is in the shared `.lem`
model.)

```
$ gcc -std=c11 -O0 int_size_t_uac_rank.c && ./a.out
5000000001 10000000000 2500000001 5000000001 5000000001 5000000001 0 5000000001 5000000001
```

(gcc 13.3.0; verbatim 2026-09-05.)

## Observed vs expected

- Observed: `n + 1`, `n * 2`, `n / 2 + 1`, `u + n`, `n + c`, `s + n`,
  `1 + n` are computed after truncating `n` to 32 bits (`5000000000 mod
  2^32 = 705032704`); `n == 705032704` is TRUE, so control flow diverges
  from every conforming compiler. `n + u` (the `size_t` operand on the
  left) happens to be right.
- Expected: ISO C11 §6.3.1.1#1 gives `size_t` the rank of the unsigned
  integer type it is defined as (here `unsigned long`, rank > `int`), and
  §6.3.1.8#1 then converts the other operand to `size_t`: gcc's line.

Operand types we probed and did NOT see truncated: `uintptr_t`,
`unsigned long`, `long`, `ptrdiff_t`, `intptr_t`, `intmax_t`,
`int64_t`/`uint64_t` (several of these are typedef'd to standard types by
the shipped headers). We have not audited every operand order for the
remaining macro types; the catch-all governs all of them, so the same
shape may exist for e.g. (`int`, `ptrdiff_t`).

## Impact

`size_t` arithmetic mixed with `int`-family operands is ubiquitous
(`len + 1`, `i < n`, `n * sizeof(T)` with an `int` factor). The wrong
value appears only when an operand is ≥ 2^32, which is why no
differential test suite of small programs sees it — but comparisons make
it a control-flow difference, not just a value difference. Both memory
models are affected (the defect is in Ail typing / elaboration, upstream
of the memory interface).

## Proposed remedy

Give the macro types their implementation rank. The simplest form: in
`lt_integer_rank` normalise both operands through the implementation's
alias table before the ISO comparison (the same information
`ocaml_implementation.ml` already exposes as sizes/signedness — `Size_t`
→ `Unsigned Long`, `Ptrdiff_t` → `Signed Long`, `Intptr_t`/`Uintptr_t`
likewise, and the `IntN_t`/`Int_leastN_t`/`Int_fastN_t`/`Intmax_t` families
through `normalise_integerType`), so that the catch-all is unreachable for
any type the implementation defines. Equivalently, rank by
`sizeof_ity` with the standard's tie rules (§6.3.1.1#1: same rank for the
signed/unsigned pair; `long long` > `long` > `int` > `short` > `char`).
Either way the existing `(* TODO: this is probably wrong for macro
types *)` arm should become an `error` rather than `false`, so a future
unranked type fails loudly instead of silently converting to `unsigned
int`.

## Classification

**TRUE BUG.** The code's own comment says the catch-all is "probably
wrong for macro types"; §6.3.1.1 leaves no latitude (a typedef has the
rank of its type), and the observable consequence is a silently wrong
value and a wrong comparison on conforming, UB-free input.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port of Cerberus (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding U1): the Lean pipeline computes exactly what the OCaml oracle
computes here (both engines mirror the shared `.lem`), and native gcc is
the referee that disagrees. Re-verified 2026-09-05 on the un-forked
upstream binary and runtime @ `b9aeedcb4`, the fork's oracle and the Lean
port (lines above are verbatim from that run). Localisation and this
draft by Claude (Fable 5.1) under operator direction; per the tray's
provenance policy the filed issue carries an AI-provenance note.
