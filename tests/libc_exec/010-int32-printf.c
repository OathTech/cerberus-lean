/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/impl/int32_printf.c — printf %d of an int32_t (formatted.lem:417; Z2-I-01 header route).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing libc_exec MATCH row. */
/* Z2 probe (same site, formatted.lem:417 printf argument type check). libc. */
#include <stdint.h>
#include <stdio.h>
int main(void) { int32_t v = 7; printf("%d\n", v); return 0; }
