/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/nd/order3.c — 6-way unsequenced enumeration ORDER identical (Z2-N-01).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH (6-verdict sequence) row. */
/* Z2 probe (CerbND vs smt2.ml runND — trace ORDER, not count): three
   unsequenced calls with distinct side effects give up to 6 interleavings,
   each with a DISTINCT return value (the digits of the call order). Batch
   mode prints executions in enumeration order; the order must match too.
   nolibc. */
int a = 0;
int f(void) { a = a * 10 + 1; return 1; }
int g(void) { a = a * 10 + 2; return 2; }
int h(void) { a = a * 10 + 3; return 3; }
int main(void) { int r = f() + g() + h(); return a + r; }
