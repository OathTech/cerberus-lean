/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/impl/int32_compat.c — int32_t vs int are_compatible through the header typedef (Z2-I-01).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH row. */
/* Z2 probe (same site, are_compatible ailTypesAux.lem:792-796): int32_t* vs int*. */
#include <stdint.h>
int main(void) { int32_t x = 5; int *p = &x; return *p; }
