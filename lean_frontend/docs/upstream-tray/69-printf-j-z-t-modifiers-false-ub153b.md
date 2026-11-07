# `printf("%jd", (intmax_t)-7)` is reported as `UB153b_illtyped_argument_for_format`: the `j` modifier's argument test compares the argument's normalised type with the bare `Intmax_t` constructor (and `%zd`/`%tu` reject the corresponding signed/unsigned types)

**Affected:** `frontend/model/formatted.lem` @ `c3ff8c53f` `:530-535` (`convert`,
`mk_diouxX_expected_and_conv`): `| Just LM_j -> (Just (Implementation.is_signed_or_unsigned Ctype.Intmax_t),
Nothing)`, `| Just LM_z -> (Just (wrap_is_compatible Implementation.is_compatible_with_size_t), Nothing)`,
`| Just LM_t -> (Just (wrap_is_compatible Implementation.is_compatible_with_ptrdiff_t), Nothing)`;
`frontend/model/implementation.lem` `is_signed_or_unsigned` (normalises the ARGUMENT's type through
`normalise_ctype`, then compares base types), `ocaml_frontend/ocaml_implementation.ml:165-170` (the alias
table: `intmax_t_alias = Long`, `size_t_alias = Unsigned Long`, `ptrdiff_t_alias = Signed Long`);
`runtime/libc/include/stdint.h:39` (`typedef __cerbty_intmax_t intmax_t;`).

## Description

C17 7.21.6.1#7: `j` "specifies that a following d, i, o, u, x, or X conversion specifier applies to an
intmax_t or uintmax_t argument"; `z` to "a size_t or the corresponding signed integer type argument"; `t` to
"a ptrdiff_t or the corresponding unsigned integer type argument". The shipped `<stdint.h>` defines
`intmax_t` as `__cerbty_intmax_t`, the `Signed Intmax_t` constructor, which the implementation aliases to
`long`. The `%jd` argument test normalises the argument's type through that alias table — `intmax_t` becomes
`Signed Long` — but compares the result with the un-normalised `Intmax_t` base type, so the test never holds
for an `intmax_t` argument (nor for a `long` one): every `%jd`/`%ju`/`%ji`/`%jo`/`%jx`/`%jX` is UB153b. The
`z` and `t` tests use the width and ONE signedness (`is_compatible_with_size_t` requires an unsigned type,
`is_compatible_with_ptrdiff_t` a signed one), so `%zd` of a `long` (the signed type corresponding to `size_t`
on this LP64 implementation) and `%tu` of an `unsigned long` are UB153b too, where the standard names exactly
those types.

## Reproducer

```c
#include <stdio.h>
#include <stdint.h>
int main(void) { printf("[%jd]\n", (intmax_t)-7); return 0; }
```

```
$ cerberus --exec --batch pf_jd_only.c
Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<3:18--3:49>"}
```

(verbatim, 2026-11-07, un-forked upstream binary + runtime @ `c3ff8c53f`; the same line for `%ju` of a
`uintmax_t`, `%zd` of `-3L`, `%tu` of `3ul`.)

```
$ gcc -std=c11 -w -O0 pf_jd_only.c && ./a.out
[-7]
```

(gcc 13.3.0; verbatim 2026-11-07; `-Wformat` is silent on all four.)

## Observed vs expected

- Observed: `UB153b_illtyped_argument_for_format` on a strictly conforming call.
- Expected: `[-7]`.

## Impact

`%jd`/`%ju` with `intmax_t`/`uintmax_t` is the portable way to print the widest integer type (the `PRIdMAX`
family of `<inttypes.h>` expands to it); `%zd` of an `ssize_t`-shaped value is common. Each such program is
reported as UB. Unlike report 27 (the `%x`-of-`int` strict reading), this is not a signedness question: the
argument has exactly the type the standard names.

## Proposed remedy

Normalise the EXPECTED side as well: the `j`/`z`/`t` arms should accept an argument whose normalised type has
the base type the implementation aliases the macro type to (`Implementation.normalise_integerType
(Signed Intmax_t)` / `Size_t` / `Ptrdiff_t`), in either signedness for `z` and `t` as #7 names both — the
same shape as the `l`/`ll` arms. (The merge-base's `ailTypesAux.lem` rank functions, report 20, have the same
bare-constructor shape; the fix there is the same normalisation.)

## Fork status (2026-11-07, branch `fix/printf-refusals`, contract D16)

Fixed in the shared `formatted.lem` (`is_alias_base`: the expected side normalised, uniformly for `j`, `z`
and `t`; the laxity of upstream's `l`/`ll` arms — either signedness — kept); both engines by generation;
witness `scripts/check_printf_refusals.sh` (the `jd_intmax`, `ju_uintmax`, `ji_jo_jx_jX`, `jd_long_arg`,
`ld_intmax_arg`, `zd_long_arg`, `zu_ulong_arg`, `tu_ulong_arg`, `td_long_arg` rows pinned to gcc's lines;
`jd_llong_arg` and `zd_int_arg` stay UB153b: a different base type).

## Classification

**TRUE BUG** (a false UB verdict on a strictly conforming program; the code's own neighbouring arms show the
intended normalisation).

## Provenance

Found by the true-bug audit of the upstream tray at the merge-base bump (2026-11-04, §4 item 3, probes
`pf_jd_only.c`, `pf_ju_only.c`, `pf_z_signed_arg.c`, `pf_z_t_j.c`), re-verified 2026-11-07 on the un-forked
upstream binary + runtime @ `c3ff8c53f`, the fork's oracle and the Lean port (identical lines).
Localisation and this draft by Claude (Fable 5.1) under operator direction; the filed issue carries an
AI-provenance note per the tray's policy.
