# CORRECTION for cerberus-caesium: `wchar_t` and `wint_t` do not have `int`'s rank (2026-11-14)

From: the `fix/wchar-rank` worker [AGENT]. This corrects the consumer note of 2026-11-04
(`2026-11-04_consumer-note-cerberus-caesium-macro-type-ranks.md`). Record `2026-11-14_wchar-rank-record.md`; witness
`scripts/check_macro_type_ranks.sh` (ladder row 1).

## What was wrong

The fix of 2026-11-04 (contract D14) gave every macro integer type the conversion rank of the type the implementation
aliases it to. For `wchar_t` and `wint_t` that was a mistake of the fork's: the alias table says `signed int` for
both, but the memory model gives `wchar_t` the unsigned range (`WCHAR_MAX` is 4294967295, `WCHAR_MIN` is 0) and
`wint_t` the range `[0, 2^31-1]`. That contradiction is upstream's and is open (upstream-tray report 62). With
`int`'s rank the two types promoted to `int` against those ranges, and the fork gave answers that neither un-forked
Cerberus nor a C compiler gives:

```c
#include <stdint.h>
int main(void) { return WCHAR_MAX > 0; }      /* fork 0;  un-forked Cerberus c3ff8c53f 1;  gcc 13 exits 1 */
int main(void) { return WINT_MIN > -1; }      /* fork 1;  un-forked Cerberus 0;            gcc 13 exits 0 */
```

Both fork engines agreed with each other, so no differential lane saw it.

## Which pins carry it

Every commit from `9b15a1f69` (the first defective commit, M1 of the 2026-11-04 slice) up to, and not including,
`0b10975b6` (M1 of `fix/wchar-rank`, the first fixed commit; should the branch be rebased before it lands, its M1
under the new hash, which the landing note names). The landings were fast-forwards, so every one of these is a
mainline commit a consumer can pin: the 59 commits `9b15a1f69`..`06afa3ef7` and, once this branch has landed, its
charter commit `6ae2434c9`. By landing, oldest first:

| mainline head after the landing | date | what landed |
|---|---|---|
| `9b15a1f69`, `5dd549e54`, `ab6295a01`, `bb6e8e9f9`, then `fc3961dc5` (the landing note) | 2026-11-04/05 | the macro-type-rank slice itself: DEFECTIVE FROM ITS FIRST COMMIT |
| `1e5f2cbca` | 2026-11-07 | program termination (D15) |
| `67cf74c09` | 2026-11-09 | the three oracle half-mirrors |
| `68470dc91` | 2026-11-09 | the constant-expression predicates (D17) |
| `03c8b4451` | 2026-11-09 | the formatter's refusals and fixes (D16) |
| `a5ff9d42e` | 2026-11-10 | the roadmap of 2026-11-10 |
| `300d78624` | 2026-11-14 | the lem TODO 54 re-pin |
| `06afa3ef7` | 2026-11-10 (commit date) | the reporting slice's documents |

and every commit between two of these heads. A pin before `9b15a1f69` never had the defect; it has upstream's
narrowing of `size_t` instead (the 2026-11-04 note). An earlier text of this note gave the range as starting at
`bb6e8e9f9`: that was three commits too short (pre-merge review F2).

## Which programs are affected at such a pin

A program is affected only if an operand of type `wchar_t` or `wint_t` takes part in an integer promotion or in the
usual arithmetic conversions. In C source that means: an object, parameter, member or cast of type `wchar_t`; a wide
character constant or an element of a wide string literal (`L'a'` has type `wchar_t`); `WCHAR_MIN`, `WCHAR_MAX`,
`WINT_MIN` or `WINT_MAX` from `<stdint.h>` (the shipped `<wchar.h>` declares `wint_t` as `short` and there is no
`__cerbty_wint_t`, so the two `WINT_*` macros are the only way to a `wint_t` operand). Nothing else: the defect and
its correction do not touch a program without any of these (none of the 40,020 measured programs without such an
operand moved, and nothing moved in the repository's corpora but the `wchar_t` witnesses). The shipped C library is
not affected (its Core dumps `tests/libc/libc.core` and
`libc_inner_arg_temps.core` are byte-identical before and after the correction; their pins did not move).

The measurement (54,329 one-expression programs over the limit macros and `wchar_t` objects): the correction moves
2,247 of them, every one with a `wchar_t` or `wint_t` operand; 483 were answers of the fork that differed from both
un-forked Cerberus and gcc.

## What the correction does, and what it deliberately does not

`wchar_t` and `wint_t` are taken out of the rank normalisation ([USER 2026-11-14] for both: the ruling named
`wchar_t`, the worker extended it to `wint_t` on a measurement, and the operator approved the extension as the same
defect and the same mechanism). Every rank comparison with one of them is un-forked Cerberus's again, exactly. What
follows for a whole program is narrower than "every program that mentions `wchar_t`", and is this: **a program whose
only macro-typed operands are `wchar_t`/`wint_t` prints `c3ff8c53f`'s line** (all 14,309 measured one-expression
programs of that shape, and those with one other macro-typed operand in the same two-operand expression). A program
that ALSO has an operand of another macro type keeps the 2026-11-04 rule for that operand, so it can differ from
un-forked Cerberus exactly as any `size_t` program does: `wchar_t x = 5; size_t sz = 3; int i = -3;` and
`(x+sz)+i` is 5 on the fork (gcc: 5) and 4294967301 un-forked, because `x+sz` has type `size_t` and `size_t + int`
is what the 2026-11-04 fix repairs (the pre-merge reviewer's counter-example, reproduced 2026-11-14). The other
macro types (`size_t`, `ptrdiff_t`, `intptr_t`, `uintptr_t`, `intmax_t`, `uintmax_t`, the exact-width families,
enums) keep the rule of 2026-11-04 unchanged: none of the 40,020 measured programs without a `wchar_t`/`wint_t`
operand moved.

This is a return to upstream's behaviour, defects included; it is not a repair of `wchar_t`. For your comparison of
the clone against the driver that means, for programs with a `wchar_t` operand:

- The Ail types are upstream's again: `wchar_t` is not promoted (`+w` has type `wchar_t`), and `wchar_t + long` is
  typed `wchar_t`'s way as before 2026-11-04 (`_Generic` code 7 where the standard says `long`). Your port of
  RefinedC's frontend types these pairs the same old way, so this difference from the 2026-11-04 note goes away.
- Arithmetic against the `int` family is narrowed to 32 bits again (`wchar_t w = 1; long l = 2^33; w + l` is 1), and
  upstream's false undefined-behaviour verdicts are back (`wchar_t w = 100000; (w - 200000) < 0` is `UB036`; gcc
  answers 1). 1,693 of the measured programs had gcc's answer between the two landings and have upstream's again.
- A negative value stored into a `wchar_t` object crashes both engines, before, during and after (report 62).

## Your present pin carries the defect

`deps/refinedc-lean/scripts/semantics-pin.env:26` reads `CERBERUS_LEAN_COMMIT="03c8b4451ff08830306d687e639f7dc57baf6827"`
(read 2026-11-14; your `scripts/certificate-pipeline.py` and `scripts/completion-target.py` take the pin from that
file). `03c8b4451` is the mainline head after the formatter landing of 2026-11-09, inside the range above
(`git merge-base --is-ancestor 9b15a1f69 03c8b4451` succeeds). So every certificate you state "with respect to
cerberus-lean" at that pin is with respect to a semantics that answers `WCHAR_MAX > 0` with 0.

What to check, in this order:

1. Whether any program you have certified or compared at a pin in the range has a `wchar_t` or `wint_t` operand in
   the sense of the section above: `wchar_t` in any declaration or cast, a wide character or string literal (`L'…'`,
   `L"…"`), `WCHAR_MIN`, `WCHAR_MAX`, `WINT_MIN`, `WINT_MAX`. The pre-merge reviewer's `grep -i` for `wchar_t`,
   `WCHAR_M` and `wint_t` over your `completion/` and `examples-consumer/` `*.c` found nothing (2026-11-14); that
   search did not cover wide literals or other directories, and the confirmation is yours.
2. If there is none: nothing you certified depends on the defect, and the correction changes no line of yours; a
   re-pin to `0b10975b6`'s landing or later is still due, because the pin's semantics is wrong on programs you have
   not written yet.
3. If there is one: re-run it at the new pin and compare against un-forked Cerberus, not against the fork's lines of
   2026-11-04 to 2026-11-14; its certificate at the old pin is about the defective behaviour.

Do not re-pin to any commit of the range.
