# Consumer note for cerberus-sl: the macro integer types get their implementation rank (2026-11-04)

From: the `fix/macro-type-ranks` worker [AGENT]. Record `docs/2026-11-04_macro-type-ranks-record.md`; witness
`scripts/check_macro_type_ranks.sh` (ladder row 1); tray 20.

What moved, in one paragraph: the shared rank functions `AilTypesAux.lt_integer_rank`/`eq_integer_rank` normalise
their operands through the implementation's alias table outside CHERI (C17 6.3.1.1#1, 7.19#2), so `size_t`,
`ptrdiff_t`, `wchar_t`, `intptr_t`/`intmax_t` and enum operands have the rank of the type they alias; the usual
arithmetic conversions no longer narrow them to `unsigned int` against the `int` family (`(size_t)1 << 32 == 0` was 1,
`SIZE_MAX + 1` was 2^32, `!((size_t)1 << 57)` was 1 — all gcc's values now), `wchar_t` and enums promote to `int` /
their compatible type, and the elaborated Core loses every `if all_values_representable_in('size_t', 'signed int') then
… else …` conditional on a `size_t` operand (247 in the shipped libc).

What this means for a pin of the fork at or after this branch:

- Any Core text you quote or pin that contains such a conditional changes shape (`conv_int('size_t', a)` now). The
  libc dumps and the Core-quotation libc digests were re-derived (`tests/libc/libc.core.sha256` `f8560811…` →
  `fae6ce64…`; `core-quote-libc.sha256` `90d09e84…` → `dc09e554…`; the inner_arg_temps pair likewise).
- The shipped C library's `strcspn`/`strpbrk` (multi-character sets; `strspn`'s `&&` form was never affected) and
  two-way `strstr` (needles of length ≥ 5) behave as glibc's now; two `tests/libc_exec` rows moved (015, 016), both engines agreeing before and after.
- No seam, proof module, fuel form or reader signature of yours is affected: on the Lean side the four rank functions
  and `rank_operand` gained the two reader parameters by lem's lifting and their callers already held them; nothing
  hand-written changed; the failure-reach register has no new row (the new `error` site is outside the exec closure).
- The Ail typing moves for every non-`size_t` macro pair (`int + ptrdiff_t` is typed `long` now, `enum + unsigned
  long` `unsigned long`, `wchar_t + long` `long`; `wchar_t`/enums promote): the type checker's `usual_arithmetic_integer`
  uses the same rank functions after its NON-STD arms; a `size_t` pair keeps its old Ail type.
- Declared residuals, unchanged: the typing's NON-STD `Size_t`/`Intptr_t` arms (`size_t op long long` typed `size_t`;
  a false UB036 on `intptr_t` against an unsigned 64-bit partner), a negative value stored into a `wchar_t` object
  (report 62's crash), CHERI's rank reading.
