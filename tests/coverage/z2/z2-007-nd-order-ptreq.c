/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/nd/order_ptreq.c — the memory model's own eq_ptrval msum fork (impl_mem.ml:1877-1880), 2 traces both sides (Z2-N-01).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH row. */
/* Z2 probe (trace order from the memory model's own msum: eq_ptrval with
   differing provenance forks "using provenance"/"ignoring provenance",
   impl_mem.ml:1877-1880 / CerbMem.eqPtrval). Two adjacent objects whose
   one-past pointer coincides with the other's base: the fork yields 0 then 1
   (or 1 then 0). nolibc. */
int main(void) { int x, y; int *p = &x + 1; int *q = &y; int r = (p == q); return 10 + r; }
