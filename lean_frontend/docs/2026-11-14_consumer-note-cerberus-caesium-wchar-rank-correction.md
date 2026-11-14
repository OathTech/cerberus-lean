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

Every commit of `mdd/cerberus-lean` from `bb6e8e9f9` (the landing of 2026-11-04) up to, and not including, the
landing of `fix/wchar-rank`. A pin before `bb6e8e9f9` never had the defect; it has upstream's narrowing of `size_t`
instead (the 2026-11-04 note).

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

`wchar_t` and `wint_t` are taken out of the rank normalisation ([USER 2026-11-14]; `wint_t` by the same mechanism,
[AGENT 2026-11-14]). Every rank comparison with one of them is un-forked Cerberus's again, exactly, and so is every
answer: on all 14,309 measured programs with such an operand the fork prints `c3ff8c53f`'s line. The other macro
types (`size_t`, `ptrdiff_t`, `intptr_t`, `uintptr_t`, `intmax_t`, `uintmax_t`, the exact-width families, enums)
keep the rule of 2026-11-04 unchanged: none of the 40,020 measured programs without a `wchar_t`/`wint_t` operand
moved.

This is a return to upstream's behaviour, defects included; it is not a repair of `wchar_t`. For your comparison of
the clone against the driver that means, for programs with a `wchar_t` operand:

- The Ail types are upstream's again: `wchar_t` is not promoted (`+w` has type `wchar_t`), and `wchar_t + long` is
  typed `wchar_t`'s way as before 2026-11-04 (`_Generic` code 7 where the standard says `long`). Your port of
  RefinedC's frontend types these pairs the same old way, so this difference from the 2026-11-04 note goes away.
- Arithmetic against the `int` family is narrowed to 32 bits again (`wchar_t w = 1; long l = 2^33; w + l` is 1), and
  upstream's false undefined-behaviour verdicts are back (`wchar_t w = 100000; (w - 200000) < 0` is `UB036`; gcc
  answers 1). 1,693 of the measured programs had gcc's answer between the two landings and have upstream's again.
- A negative value stored into a `wchar_t` object crashes both engines, before, during and after (report 62).

If one of your certified programs uses `wchar_t`, re-run it at the new pin and compare against un-forked Cerberus,
not against the fork's lines of 2026-11-04 to 2026-11-14.
