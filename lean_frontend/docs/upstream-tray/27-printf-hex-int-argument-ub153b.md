# `printf("%x", 255)` — an `int` argument to `%x`/`%X`/`%o`/`%u` — is reported as `UB153b_illtyped_argument_for_format` although the value is representable in `unsigned int`

**Affected:** `frontend/model/formatted.lem:515-538` (`convert`,
`mk_diouxX_expected_and_conv is_signed`: with no length modifier the
expected-type predicate is `fun z -> z = default_ty`, i.e. exact type
equality with `unsigned int` for the unsigned conversions), `:547-572`
(the `CS_o`/`CS_u`/`CS_x`/`CS_X` arms call it with `false`), `:441-448`
(`is_illtyped` → `UB153b_illtyped_argument_for_format`). Checked against
`master` @ `b9aeedcb4`: `formatted.lem` differs from master only by
Lean-target `declare` lines outside the cited regions (master's line
numbers).

## Description

For `%o %u %x %X` the checker demands that the argument's type, after
`Implementation.normalise_ctype`, be exactly `unsigned int`; a
(promoted) `int` argument fails the test and the conversion is reported
as undefined behaviour. The strict letter of §7.21.6.1#9 ("If any
argument is not the correct type for the corresponding conversion
specification, the behavior is undefined") supports the check; but
§6.2.5#9 with footnote 31 — "the range of nonnegative values of a signed
integer type is a subrange of the corresponding unsigned integer type,
and the representation of the same value in each type is the same … The
same representation and alignment requirements are meant to imply
interchangeability as arguments to functions, return values from
functions, and members of unions" — is the rule every implementation and
every compiler's format checker (gcc `-Wformat` does not warn) rely on to
make `printf("%x", 255)` well-defined for a non-negative `int`. The
Cerberus checker already applies exactly this latitude elsewhere: `%hhd`
and `%hd` with `int` arguments are accepted (probe
`lib/lib_printf_int_formats.c`, all engines agree), and the signed
conversions accept any `int`.

## Reproducer

`tests/noodle-probes/lib/lib_printf_hex_int_arg.c`:

```c
#include <stdio.h>
int main(void) { printf("[%x][%X][%o]\n", 255, 255, 8); return 0; }
```

```
$ cerberus --exec --batch --mode=exhaustive lib_printf_hex_int_arg.c
Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<7:18--7:55>"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`,
shipped libc; the fork's oracle at `928aa1e76` and our Lean port print
the identical line.)

```
$ gcc -std=c11 -O0 lib_printf_hex_int_arg.c && ./a.out
[ff][FF][10]
```

(gcc 13.3.0; verbatim 2026-09-05.) Control: `printf("%u", -1)`
(`lib/lib_printf_uint_neg_arg.c`) is also UB153b on Cerberus — that one
is defensible (the value is NOT representable in `unsigned int`, so
footnote 31's premise fails), and gcc prints `4294967295` with a
`-Wformat` warning only for the constant.

## Observed vs expected

- Observed: UB153b for `%x`/`%X`/`%o` with a non-negative `int` argument.
- Expected: `[ff][FF][10]` — the argument's value is in the common
  subrange and interchangeable (§6.2.5#9, fn. 31).

## Impact

`printf("%x", some_int)` occurs in essentially every C program that
prints hexadecimal (flags, addresses cast to `int`, error codes); each
such program is reported as UB at its first `printf` and the rest of its
behaviour is never examined. For a UB-detection tool this is a
false-positive class on a very common idiom.

## Proposed remedy

In `mk_diouxX_expected_and_conv` accept the SIGNED counterpart of the
expected unsigned type (and the unsigned counterpart of a signed one) as
a type match, then decide by VALUE: if the loaded value is representable
in the conversion's type, convert and print; if it is not (e.g. `%u` with
`-1`, `%d` with `4000000000u`), keep the current
`UB153b_illtyped_argument_for_format` (or introduce a distinct code for
"same-representation argument, value not representable" if the two cases
should stay distinguishable). The same relaxation applies to the length-
modified forms (`%lx` with `long`, `%llx` with `long long`, `%zx` with
`ptrdiff_t`…) through `Implementation.is_signed_or_unsigned`, which the
code already uses for `l`/`ll`/`j` — i.e. those arms are ALREADY lenient
about signedness; only the no-modifier and `hh`/`h` arms demand the
exact type.

## Classification

**TRUE BUG (over-strict), with the caveat that the strictest reading of
§7.21.6.1#9 supports the current behaviour.** The inconsistency inside
the checker (the `l`/`ll`/`j` arms accept either signedness via
`is_signed_or_unsigned`, the default arm does not; `%hhd`/`%hd` accept
`int`) and the universal implementation practice via §6.2.5#9 fn. 31 make
the exact-type test on the default arm look like an omission rather than
a stance. Upstream may prefer to keep it as a strict-mode option.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L6); both engines agree (shared `.lem`), gcc prints. Re-verified
2026-09-05 on the un-forked upstream binary + runtime @ `b9aeedcb4`, the
fork's oracle and the Lean port (lines above verbatim). Localisation and
this draft by Claude (Fable 5.1) under operator direction; the filed
issue carries an AI-provenance note per the tray's policy.
