# `printf("%e", 3.5)` (and `%E`, `%g`, `%G`, `%a`, `%A`, `%F`, `%Lf`) is reported as `Invalid_format` undefined behaviour: the formatter parses only `%f` of the floating conversions and no `L` length modifier

**Affected:** `frontend/model/formatted.lem` @ `c3ff8c53f`: `:40` (`| CS_f (* | CS_F | CS_e | CS_E | CS_g |
CS_G | CS_a | CS_A *)` — the seven constructors commented out), `:143` (`conversionSpecifier` has `char #'f'`
only), `:32` and `:133` (`LM_L` and its parser arm commented out). The shared model: the OCaml backend and
our Lean port fail identically.

## Description

C17 7.21.6.1#8 defines the conversion specifiers `a`, `A`, `e`, `E`, `f`, `F`, `g` and `G` for a `double`
argument, and #7 the `L` length modifier for a `long double` argument of those conversions. The format
parser recognises `f` alone, so a format string carrying any of the other seven (or `L`) does not parse, and
`printf`/`vprintf`/`vsnprintf` report the whole call as `Invalid_format` — the verdict reserved by 7.21.6.1#9
for a malformed conversion specification — on a strictly conforming program.

## Reproducer

```c
#include <stdio.h>
int main(void) { printf("[%e]\n", 3.5); return 0; }
```

```
$ cerberus --exec --batch pf_e_only.c
Undefined {ub: "Invalid_format[[%e]
]", stderr: "", loc: "<2:18--2:39>"}
```

(verbatim, 2026-11-07, un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc; the `ub` text embeds the
format string's newline. The same line for `%E`, `%g`, `%G`, `%a`, `%A`, `%F` of a `double`, `%Lf`/`%Le` of a
`long double`, and `%le`; `%lf` and `%f` are the only floating forms that print.)

```
$ gcc -std=c11 -w -O0 pf_e_only.c && ./a.out
[3.500000e+00]
```

(gcc 13.3.0; verbatim 2026-11-07. `%g` → `3.5`, `%a` → `0x1p+0`, `%F` → `3.500000`, `%Lf` → `2.500000`.)

## Observed vs expected

- Observed: `Undefined {ub: "Invalid_format[…]"}` — a UB verdict on a conforming call.
- Expected: the conversion's text, or — if the conversions are not implemented — a diagnostic that says so
  rather than a UB verdict (the `%n` and `%*d` arms, by comparison, stop with an internal error).

## Impact

`%e`/`%g` are the usual way to print a `double` in test programs and scientific code; every such program is
reported as having undefined behaviour at its first floating `printf`, so the verdict cannot be told apart
from a real `Invalid_format` (a `%q`, a trailing `%`), and a differential harness that trusts the verdict
classifies conforming programs as UB.

## Proposed remedy

Parse the full specifier set (`CS_F | CS_e | CS_E | CS_g | CS_G | CS_a | CS_A` and `LM_L`, the commented-out
constructors) and either implement the conversions over the existing `format_string_of_float` path
(`%e`/`%E`/`%g`/`%G` are a few lines over OCaml's `Printf`; `%a`/`%A` the hexadecimal form; `L` needs a
`long double` argument model) or stop with an explicit "not implemented" error at the conversion stage, so a
conforming program never receives a UB verdict for it.

## Fork status (2026-11-07, branch `fix/printf-refusals`, contract D16)

Our fork parses the full syntax and REFUSES the unimplemented conversions at the conversion stage with one
attributed text per class (both engines, byte-identical): `Formatted.convert: refused - the %e conversion is
not implemented (C17 7.21.6.1#8: …) … the fork parses the conversion and refuses rather than decides
(upstream-tray report 68, 2026-11-07)`. A format the parser cannot parse at all stays `Invalid_format`. The
implementation of the seven conversions is queued (`lean_frontend/TODO.md`), not done: a refusal is the honest
interim. Witness: `scripts/check_printf_refusals.sh` (the `e_double`, `E_double`, `g_double`, `G_double`,
`a_double`, `A_double`, `F_double`, `Lf_ldouble`, `Le_ldouble`, `le_double`, `e_flags_width`, `sn_float_e` rows).

## Classification

**TRUE BUG** (a silently wrong verdict on valid C): the commented-out constructors show the omission is known;
we report it because the consequence is a UB verdict on a conforming program, not a diagnostic.

## Provenance

Found by the true-bug audit of the upstream tray at the merge-base bump (2026-11-04, §4 item 1, probes
`pf_e_only.c`, `pf_g_only.c`, `pf_a_only.c`, `pf_Lf_only.c`, `pf_float.c`), re-verified 2026-11-07 on the
un-forked upstream binary + runtime @ `c3ff8c53f`, the fork's oracle and the Lean port (identical lines).
Localisation and this draft by Claude (Fable 5.1) under operator direction; the filed issue carries an
AI-provenance note per the tray's policy.
