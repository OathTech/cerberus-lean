/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/nd/order2.c — 2-way enumeration order (Z2-N-01).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH row. */
/* Z2 probe (trace order, 2-way): one unsequenced pair. nolibc. */
int a = 0;
int f(void) { a = a * 10 + 1; return 0; }
int g(void) { a = a * 10 + 2; return 0; }
int main(void) { int r = f() + g(); return a + r; }
