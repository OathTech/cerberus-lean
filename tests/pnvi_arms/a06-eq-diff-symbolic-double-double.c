// PNVI arms witness a06 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md; the arc-end auditor's probe 2).
// Arms: eq_ptrval's (Prov_symbolic, Prov_symbolic) arm (impl_mem.ml:1905-1914) with two
// `Double` iotas (the `_ -> false` case), hence the msum "pointer equality" fork (:1917-1923);
// and diff_ptrval's (Prov_symbolic, Prov_symbolic) arm (:2063-2105) with the intersection
// `Double` and addr1 = addr2 (:2100-2102: zero, no collapse).
// Expected under the switch: two executions, Defined 1 and Defined 0.
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  int *r1 = (int *)i;
  int *r2 = (int *)i;
  return (r1 == r2) + 10 * (int)(r1 - r2);
}
