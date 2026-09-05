# `printf("%*d", …)`: the `*` field width is parsed but the tool dies with an uncaught `Failure("internal error: TODO: formatted.lem 6")`

**Affected:** `frontend/model/formatted.lem:113` and `:119` (the format
parser accepts `*` as `FW_asterisk` / `P_asterisk`), `:741-742`
(`printf_aux`: `| Just FW_asterisk -> error "TODO: formatted.lem 6"`),
`:253` (`justify2`: `assert_false "TODO: FW_asterisk"`), `:423-424` and
`:584-585` (precision `*`: `error "TODO: Formatted.convert, * prec"`).
Checked against `master` @ `b9aeedcb4`: `formatted.lem` differs from
master only by Lean-target `declare` lines outside the cited regions
(master's line numbers).

## Description

C11 §7.21.6.1#5: "a field width, or precision, or both, may be indicated
by an asterisk. In this case, an `int` argument supplies the field width
or precision. The arguments specifying field width, or precision, or
both, shall appear (in that order) before the argument (if any) to be
converted. A negative field width argument is taken as a `-` flag followed
by a positive field width. A negative precision argument is taken as if
the precision were omitted."

The format-string parser recognises the asterisk forms, but every
consumer of them is an `error`/`assert_false` placeholder: the argument
is never consumed and the tool exits with an uncaught OCaml exception
instead of either formatting or reporting a diagnostic.

## Reproducer

`tests/noodle-probes/lib/lib_printf_star_width.c`:

```c
#include <stdio.h>
int main(void) { printf("[%*d]\n", 4, 9); return 0; }
```

```
$ cerberus --exec --batch --mode=exhaustive lib_printf_star_width.c   # exit 125
internal error: TODO: formatted.lem 6
cerberus: internal error, uncaught exception:
          Failure("internal error: TODO: formatted.lem 6")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Formatted.printf_aux.(fun) in file "ocaml_frontend/generated/formatted.ml", line 830, characters 22-62
```

(verbatim head, 2026-09-05, un-forked upstream binary + runtime @
`b9aeedcb4`, shipped libc; the fork's oracle at `928aa1e76` fails
identically; our Lean port fail-stops with the mirrored text `PANIC …
TODO: formatted.lem 6`, exit 134.)

```
$ gcc -std=c11 -O0 lib_printf_star_width.c && ./a.out
[   9]
```

(gcc 13.3.0; verbatim 2026-09-05.)

## Observed vs expected

- Observed: uncaught `Failure`, exit 125, on a strictly-conforming call.
- Expected: `[   9]` (and, for `%.*d`/`%*.*d`, the precision variants).

## Impact

`%*d`/`%-*s`/`%.*s` are common in table-printing and logging code;
every program using one dies at its first such `printf` with an internal
error rather than a verdict — the whole translation unit becomes
untestable, and the failure mode is a crash rather than a diagnostic.

## Proposed remedy

In `printf_aux` (formatted.lem:735-742) and `convert` (:419-425,
:580-586), when the parsed specification carries `FW_asterisk` /
`P_asterisk`, take the next `(ctype, pointer)` argument, check it is an
`int` (else `UB153b_illtyped_argument_for_format`, like the other
argument checks), load it, and substitute: field width `w < 0` → set the
`-` flag and use `-w`; precision `p < 0` → treat as omitted. Then
continue with `FW_num`/`P_num` as today. `justify2`'s `assert_false`
(:253) becomes unreachable once the substitution happens before
justification. `scanf`'s `*` (assignment suppression) is a different
feature and unaffected.

## Classification

**TRUE BUG** (crash on legal input). The placeholders are explicit
`TODO`s, so the omission is known to the authors; we report it because
the consequence is an uncaught exception rather than a diagnostic, on an
input the parser itself accepts.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L5); both engines fail the same way (shared `.lem`), gcc prints.
Re-verified 2026-09-05 on the un-forked upstream binary + runtime @
`b9aeedcb4`, the fork's oracle and the Lean port (lines above verbatim).
Localisation and this draft by Claude (Fable 5.1) under operator
direction; the filed issue carries an AI-provenance note per the tray's
policy.
