# `printf("%05d", -5)` prints `000-5`: the `0` flag pads in front of the sign and the `0x` prefix (and over an infinity); `%#.0f` drops the decimal point

**Affected:** `frontend/model/formatted.lem` @ `c3ff8c53f` `:223-236` (`justify`: `replicate d j ++ str` with
`j = #'0'` — the zeros go in front of the whole result, which already carries the sign from `expand` and the
`0x`/`0X` prefix of a `#` conversion; no infinity/NaN exception), `:201-205` (`expand`'s `#` arm for the
floating conversions: `(* TODO: not doing the right thing for now *) str`).

## Description

C17 7.21.6.1#6, flag `0`: "For d, i, o, u, x, X, a, A, e, E, f, F, g, and G conversions, leading zeros
(following any indication of sign or base) are used to pad to the field width rather than performing space
padding, except when converting an infinity or NaN." Flag `#`: "For a, A, e, E, f, F, g, and G conversions,
the result of converting a floating-point number always contains a decimal-point character, even if no
digits follow it."

`justify` prepends the zeros to the already signed/prefixed result, and `expand` leaves `%#f`'s result
untouched.

## Reproducer

```c
#include <stdio.h>
int main(void) {
  printf("[%05d][%+05d][% 05d][%#05x][%#08X][%010.3f]\n", -5, 5, 5, 255u, 255u, -3.14159);
  double inf = 1e308; inf = inf * 10.0;
  printf("[%010f][%#.0f][%#.0f]\n", inf, 3.0, -7.0);
  return 0;
}
```

```
$ cerberus --exec --batch pf_zero_hash.c
Defined {value: "Specified(0)", stdout: "[000-5][000+5][000 5][00xff][00000XFF][0000-3.142]\n[0000000inf][3][-7]\n", stderr: "", blocked: "false"}
```

(verbatim, 2026-11-07, un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc.)

```
$ gcc -std=c11 -w -O0 pf_zero_hash.c && ./a.out
[-0005][+0005][ 0005][0x0ff][0X0000FF][-00003.142]
[       inf][3.][-7.]
```

(gcc 13.3.0; verbatim 2026-11-07.)

## Observed vs expected

- Observed: `000-5`, `00xff`, `0000-3.142`, `0000000inf`, `3`.
- Expected: `-0005`, `0x0ff`, `-00003.142`, `       inf`, `3.`.

## Impact

`%05d`/`%08x`/`%010.3f` of a negative value or with `#` are common in table and hex-dump printing; the
output is silently wrong (the sign or base lands after the zeros), and the differential harness that compares
engines sees agreement.

## Proposed remedy

In `justify`, when the fill character is `0`, split a leading sign (`-`, `+`, space — the characters
`expand` can prepend) and, after it, a `0x`/`0X` base prefix, and insert the zeros between the prefix and the
digits; pad an infinity or NaN with spaces. In `expand`'s `#` arm for the floating conversions, append the
decimal point when the result has none and is a plain `[-]digits` (not an infinity or NaN).

## Related findings (not changed by the fork: upstream's judgement, filed for information)

- `printf("% u", 5u)` prints ` 5` (the space flag applied to an unsigned conversion; gcc prints `5` and warns);
  `printf("%+u", 5u)` is reported as `DUMMY(+ flag with unsigned conversion)` — 7.21.6.1#6 describes the two
  flags for signed conversions only and, unlike `#`/`0`, does not say "for other conversions, the behavior is
  undefined"; the two flags are treated differently from each other.
- `printf("%5%")` prints `    %` (7.21.6.1#8: "The complete conversion specification shall be %%"; gcc prints
  `%`) — the `CS_percent` arm's own TODO calls the modified forms undefined behaviour and pads anyway; the `*` form of
  the same shape (`%*%`) crashed with the `*` placeholder and is a declared refusal in the fork (report 26).
- `printf("%f", -0.0)` prints `0.000000` on both engines where gcc prints `-0.000000`: measured with
  `z * -1.0` (prints `-0.000000`) against `-z` and `0.0 - z` (print `0.000000`), the sign is lost by the
  negation / subtraction before the formatter sees the value — a floating-arithmetic question, not the
  formatter's (not filed here).

## Fork status (2026-11-07, branch `fix/printf-refusals`, contract D16)

The two defects are fixed in the shared `formatted.lem` (`justify`, `expand`), both engines by generation;
witness `scripts/check_printf_refusals.sh` (the `flags_zero`, `flags_hash`, `flags_hash_long`, `f_zero_pad`,
`f_hash`, `f_inf`, `width_int_min`, `width_llong_min`, `star_zero_flag` rows pinned to gcc's lines). The
related findings are kept as upstream has them and pinned to the fork's own lines (`space_u`,
`percent_width`, `plus_u_dummy`); `%*%` is the `star_percent` refusal row; the `-0.0` finding is filed apart as report 71.

## Classification

**TRUE BUG** (silently wrong output on conforming input; the standard's text is explicit and the file's own
commented-out `justify2` shows the sign handling was intended).

## Provenance

Found by the vicinity probe of the fix/printf-refusals slice (2026-11-07, a 162-program matrix over the fork
oracle, the un-forked upstream binary + runtime @ `c3ff8c53f`, the Lean port and gcc 13.3.0); both engines and
pristine agree before the fix. Localisation and this draft by Claude (Fable 5.1) under operator direction;
the filed issue carries an AI-provenance note per the tray's policy.
