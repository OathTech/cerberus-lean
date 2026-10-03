/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-M-01, nolibc witness; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/mem/aligned_alloc_zero_nolibc.c — the same std.core:385 `size rem_t align`
   through the ailname redirect in --nolibc mode (the mode does not matter). Oracle: Division_by_zero
   exit 125. MIRRORED 2026-10-03 under [USER 2026-10-03] ("we don't innovate wrt Cerberus-upstream ...
   fall back to loudly rejecting (either as unsupported, or matching upstream)"): Lean's integerRem_t
   fail-stops on 0 as Z.rem raises -> both-crash MATCH | L=CRASH (docs/2026-10-03_total-arith-and-bookkeeping-record.md). */
extern void *aligned_alloc(unsigned long, unsigned long);
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
