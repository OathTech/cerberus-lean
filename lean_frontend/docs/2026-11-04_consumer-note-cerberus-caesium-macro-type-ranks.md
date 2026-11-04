# Consumer note for cerberus-caesium: the macro integer types get their implementation rank (2026-11-04)

From: the `fix/macro-type-ranks` worker [AGENT]. Occasion: your filing draft 05
(`docs/upstream-tray/05-cerberus-size-t-usual-arithmetic-conversion.md`, branch
`tray/size-t-usual-arithmetic-20261104`, commit `e416f83f4`) — the driver's Core comparing `size_t` against `int` at
32 bits, which blocked your libxml2 `xmlBufShrink` refinement — is the fork's own upstream-tray draft 20 (found
2026-09-03, never fixed), and [USER 2026-11-04] approved fixing it in the fork as a fork-ahead delta of the first kind
(the fork's own fix of an upstream mistake, filed upstream), both engines by generation. Your translation-side
localisation is merged into tray 20 with credit. Record `docs/2026-11-04_macro-type-ranks-record.md`; witness
`scripts/check_macro_type_ranks.sh` (ladder row 1).

Status: on branch `fix/macro-type-ranks`, fixed, witnessed on both engines, every moved row dispositioned with gcc
as the referee; Tier A green; the full battery and the merge are the orchestrator's. The behaviour below is what the
next re-pin that includes the branch carries.

## What changed, and what it is

`AilTypesAux.lt_integer_rank` and `eq_integer_rank` (`frontend/model/ail/ailTypesAux.lem`) now normalise both operands
through `Implementation.normalise_integerType` outside CHERI (`Size_t → Unsigned Long`, `Ptrdiff_t → Signed Long`,
`Wchar_t → Signed Int_`, `Intptr_t`/`Intmax_t → Long`, the `intN_t` families by width, an enum to its compatible type),
the ISO table has the two `long long` rows, and its catch-all is a loud `error` outside CHERI (C17 6.3.1.1#1, 7.19#2).
Everything downstream follows by generation: the Core translation's `usual_arithmetic_conversion_aux` now takes the
third bullet for (`size_t`, `int`) and converts the `int` operand to `size_t`; `integer_promotion` promotes `wchar_t`
to `int` and an enum to its compatible type. NOT taken: your proposed alternative (the typing's `Size_t`-wins arms
copied into the translation) — it fixes the `int` case but hard-codes a non-standard rule for `size_t` against
`long long`, where the normalised bullets now give the standard's `unsigned long long`.

## What changes for your clone's comparison with the driver

- Your witnesses `w24_size_t_int_equality` and `w25_size_t_int_inequality`: the driver now answers `Specified(0)` and
  `Specified(1)` (gcc 0 and 1) — expected to move from `DISAGREE/value` to agreement with the stepper's `RETURN 0 (u32)`
  / `RETURN 1 (u32)`. Your `(x > 0) + 2*(x + 0 == x) + 4*(x * 1 == x)` program answers 7 (gcc 7). The `xmlBufShrink`
  guard `len == 0` at `len = 2^32` is false in the driver's Core now, as in Caesium.
- The elaborated Core changes shape wherever a macro-typed operand met the `int` family: the `if
  all_values_representable_in('size_t', 'signed int') then conv_int('signed int', a) else conv_int('unsigned int', a)`
  conditionals become `conv_int('size_t', a)` (the shipped libc dump lost 247 of them, 89639 → 88739 lines; its pins
  and the Core-quotation libc pins were re-derived). Anything of yours that pattern-matches the old shape, or pins the
  libc dump or its digest, moves with it: `tests/libc/libc.core.sha256` `f8560811…` → `fae6ce64…`,
  `libc_inner_arg_temps.core.sha256` `06a1f84c…` → `45eaac23…`, `test/CoreQuote/core-quote-libc.sha256` `90d09e84…` →
  `dc09e554…`, `-inner-arg-temps` `b7e2711e…` → `4c9f5e69…`.
- The shipped C library behaves differently where its own `size_t` arithmetic was narrowed: `strcspn`, `strspn` and
  `strpbrk` with a multi-character set (their set-building loop `if (!BITOP(byteset, *c, |=)) break;` stopped after the
  first character, because `!` on a `size_t` was elaborated as `== 0` under the narrowed conversions), and two-way
  `strstr` (needles of length ≥ 5) no longer reads past the needle (`ip+1` with `ip = SIZE_MAX` was 2^32). If your
  libxml2 TUs call these, their behaviour under the driver moves to glibc's.
- Values at and beyond 2^32 and 32-bit wraparound in `size_t`/`ptrdiff_t`/`wchar_t`/enum arithmetic against `int`,
  `unsigned`, `char`, `short` and `long` partners, in both orders, every operator, every `op=`, `?:` and `!`: gcc's
  values now (the witness pins 104 programs; the matrix measured 483 — 196 wrong before, 0 after).

## What does NOT change (declared, filed, not fixed here)

- The Ail type checker's `usual_arithmetic_integer` keeps upstream's NON-STD `Size_t`-wins and `Intptr_t` arms (your
  RefinedC parity rests on them): `size_t op long long` is still TYPED `size_t` (gcc: `unsigned long long`), `intptr_t
  op unsigned long` typed `intptr_t`; the values agree at 64 bits, `_Generic` sees the difference. With a signed
  `intptr_t` operand against an unsigned 64-bit partner the sum is typed `intptr_t` but computed unsigned, so `intptr_t
  a = 5; unsigned long b = 2^64-6; a + b` is a false `UB036_exceptional_condition` on both engines (pristine too; gcc
  defined) — filed as a related finding in tray 20, pinned as a gap control in the witness.
- A negative value stored into a `wchar_t` object still crashes both engines at the store (report 62, the queued
  crash-to-refusal slice); `wchar_t` arithmetic itself is right now (done in `int`).
- CHERI keeps upstream's rank reading verbatim.
- The typing of a comparison (`int`) and the operands' types are unchanged on the Ail side, so your port of RefinedC's
  frontend (`AilToCoq.lean:738-748`) sees the same Ail as before; only the driver's Core moved.

## For your re-pin

Re-run your differential on the witness corpus after the re-pin; w24/w25 are expected to become agreements and your
declared difference B9 (`docs/2026-11-01_charter-alignment-campaign.md` §2.3) can close. If a `libxml2` TU of yours
exercises `strcspn`/`strspn`/`strpbrk`/`strstr`, expect its driver rows to move to glibc's values. The register
`scripts/upstream_oracle_differences.json` carries two new `shared-model-fix` rows (`libc_exec/015`, `/016`) for the
pristine lane; nothing else in the fork-vs-pristine inventory changed.
