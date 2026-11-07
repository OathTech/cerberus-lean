# `printf("%*d", …)`: the `*` field width and precision are parsed but the tool dies with an uncaught `Failure("internal error: TODO: formatted.lem 6")`; `%n`, `%ls` and `%lc` die the same way

**Affected:** `frontend/model/formatted.lem` @ `c3ff8c53f`: `:113` and `:119` (the format parser accepts
`*` as `FW_asterisk` / `P_asterisk`), `:742` (`printf_aux`: `| Just FW_asterisk -> error "TODO:
formatted.lem 6"`), `:424`, `:585`, `:644` (the precision: `error "TODO: Formatted.convert, * prec"`,
`"TODO(2): …"`), `:253` (the commented-out `justify2`: `assert_false "TODO: FW_asterisk"`); and the three
conversion arms that are internal errors on a conforming call: `:697` (`| CS_n -> error "WIP:
Formatted.convert, CS_n"`), `:624` (`CS_s` with any length modifier: `error "WIP: Formatted.convert, CS_s
with length modifier"`), `:612` (`CS_c` with `l`: `error "NOT YET SUPPORTED: %lc"`). The shared model: the
OCaml backend and our Lean port fail identically.

## Description

C17 7.21.6.1#5: "a field width, or precision, or both, may be indicated by an asterisk. In this case, an
`int` argument supplies the field width or precision. The arguments specifying field width, or precision, or
both, shall appear (in that order) before the argument (if any) to be converted. A negative field width
argument is taken as a `-` flag followed by a positive field width. A negative precision argument is taken
as if the precision were omitted."

The format-string parser recognises the asterisk forms, but every consumer of them is an
`error`/`assert_false` placeholder: the argument is never consumed and the tool exits with an uncaught OCaml
exception instead of either formatting or reporting a diagnostic. The `%n` conversion (7.21.6.1#8 n), and
`%ls`/`%lc` (#7, the `l` modifier with `s` and `c`: a `wchar_t` array / a `wint_t` argument) are placeholders
of the same kind.

## Reproducers

`tests/noodle-probes/lib/lib_printf_star_width.c`:

```c
#include <stdio.h>
int main(void) { printf("[%*d]\n", 4, 9); return 0; }
```

```
$ cerberus --exec --batch lib_printf_star_width.c   # exit 125
internal error: TODO: formatted.lem 6
cerberus: internal error, uncaught exception:
          Failure("internal error: TODO: formatted.lem 6")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
```

(verbatim head, 2026-11-07, un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc; `%.*d`,
`%*.*f`, `%-*s`, `%.*s` die with `TODO: Formatted.convert, * prec`.)

```
$ gcc -std=c11 -O0 lib_printf_star_width.c && ./a.out
[   9]
```

(gcc 13.3.0; verbatim 2026-11-07.)

`%n` — `int main(void) { int n = 0; printf("ab%n\n", &n); printf("%d\n", n); return 0; }`:

```
internal error: WIP: Formatted.convert, CS_n
cerberus: internal error, uncaught exception:
          Failure("internal error: WIP: Formatted.convert, CS_n")
```

(gcc prints `ab` then `2`.) `%ls`/`%lc` — `wchar_t w[3]; w[0] = 97; w[1] = 98; w[2] = 0; printf("[%ls][%lc]\n",
w, 97);`:

```
internal error: WIP: Formatted.convert, CS_s with length modifier
cerberus: internal error, uncaught exception:
          Failure("internal error: WIP: Formatted.convert, CS_s with length modifier")
```

(gcc prints `[ab][a]`; `%lc` alone dies with `NOT YET SUPPORTED: %lc`. All verbatim 2026-11-07, @ `c3ff8c53f`.)

## Observed vs expected

- Observed: uncaught `Failure`, exit 125, on strictly conforming calls.
- Expected: `[   9]` (and the precision variants); `ab` / `2`; `[ab][a]` — or an explicit diagnostic.

## Impact

`%*d`/`%-*s`/`%.*s` are common in table-printing and logging code; every program using one dies at its
first such `printf` with an internal error rather than a verdict — the whole translation unit becomes
untestable, and the failure mode is a crash rather than a diagnostic. (`%n` and the wide conversions are
rarer; the failure mode is the same.)

## Proposed remedy

In `printf_aux`, when the parsed specification carries `FW_asterisk` / `P_asterisk`, take the next `(ctype,
pointer)` argument, check it is an `int` (else `UB153b_illtyped_argument_for_format`, like the other argument
checks; `UB153a_insufficient_arguments_for_format` without one), load it, and substitute: field width `w < 0`
→ set the `-` flag and use `-w`; precision `p < 0` → treat as omitted. Then continue with the numeric forms as
today; `convert` can take the resolved precision, which removes the three `* prec` placeholders.
`justify2`'s `assert_false` (:253) is inside a comment already. `scanf`'s `*` (assignment suppression) is a
different feature and unaffected. For `%n`, `%ls` and `%lc`: implement, or stop with an explicit
"not implemented" error whose text names the conversion.

## Fork status (2026-11-07, branch `fix/printf-refusals`, contract D16)

The `*` forms are FIXED in our fork's shared `formatted.lem` exactly as proposed (`load_star_argument`;
`convert` takes the resolved precision), both engines by generation; witness `scripts/check_printf_refusals.sh`
(28 `*` rows pinned to gcc 13's lines: every form of width and precision, negative, zero, with flags and
length modifiers, in `printf`, `fprintf`, `sprintf`, `snprintf`, `vprintf` and through a user `vsnprintf`
wrapper). A `*` argument that is an unspecified value is a declared refusal (the formatter does not guess a
width). `%n`, `%ls` and `%lc` are DECLARED REFUSALS with one attributed text each (`Formatted.convert:
refused - the %n conversion (C17 7.21.6.1#8 n: …) … (upstream-tray report 26, 2026-11-07)`), never a wrong
answer; their implementation is upstream's to do. The fork-ahead delta leaves when upstream absorbs the fix.

## Classification

**TRUE BUG** (crash on legal input). The placeholders are explicit `TODO`s, so the omission is known to the
authors; we report it because the consequence is an uncaught exception rather than a diagnostic, on an input
the parser itself accepts.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean port (record
`lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`, finding L5); both engines fail the same way (shared
`.lem`), gcc prints. Re-verified 2026-09-05 @ `b9aeedcb4` and 2026-11-07 @ `c3ff8c53f` on the un-forked
upstream binary + runtime, the fork's oracle and the Lean port (lines above verbatim); the `%n`/`%ls`/`%lc`
siblings from the true-bug audit of 2026-11-04 (§4 item 10). Localisation and this draft by Claude (Fable
5.1) under operator direction; the filed issue carries an AI-provenance note per the tray's policy.
