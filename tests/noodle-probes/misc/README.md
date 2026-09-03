# misc/ — assorted corners (nolibc; the two stdin probes in libc mode)

| Probe | Corner | Result | Integration |
|---|---|---|---|
| misc_unspec_in_condition.c | indeterminate value as controlling expression | oracle==Lean `UB_CERB004_unspecified__conditional` | exec UB_MATCH |
| misc_unspec_absorbed.c | `(x & 0) + 3` with x indeterminate | oracle==Lean **UB036_exceptional_condition** (gcc 3) — ODDITY O6: unspecified operand of signed + is classified as an exceptional condition rather than Unspecified | exec UB_MATCH; note for upstream |
| misc_unspec_struct_member.c | unwritten member of an addressed struct | oracle==Lean `Unspecified('signed int')` | exec MATCH; gcc SKIP_UNSPEC |
| misc_alignas.c | _Alignas on automatic array and member; residues only (6.7.5) | AGREE 3-way | exec MATCH, gate-worthy |
| misc_bitops_negative.c | bitwise ops on negative values (6.5.10-12) | AGREE 3-way | exec MATCH, gate-worthy |
| misc_negative_index_defined.c | negative subscript on interior pointer (6.5.6p8) | AGREE 3-way 11 | exec MATCH, gcc AGREE |
| misc_negative_index_ub.c | a[-1] out of bounds | AGREE `UB_CERB002a` | exec UB_MATCH |
| misc_main_recursion.c | recursive main | AGREE 3-way 4 | exec MATCH, gcc AGREE |
| misc_switch_long_long.c | switch on long long with >32-bit cases | AGREE 3-way 1 | exec MATCH, gcc AGREE |
| misc_max_align_t.c | sizeof/_Alignof(max_align_t) | oracle==Lean `8 8`; gcc `32 16` (long double impl, declared) | exec MATCH |
| misc_printf_p_null.c | %p of NULL | oracle==Lean `[NULL(void)]`; gcc `[(nil)]` (impl-defined) | exec MATCH |
| misc_getchar_empty_stdin.c | getchar on empty stdin -> EOF | oracle==Lean `Specified(1)` | libc_exec MATCH |
| misc_scanf_empty_stdin.c | scanf on empty stdin | BOTH `Error` unknown procedure `vscanf` (libc gap, ODDITY O5); message text differs by design (D3) | reporting-only (both-reject) |
