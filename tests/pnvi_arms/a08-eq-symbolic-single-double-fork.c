// PNVI arms witness a08 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). The control of a07: eq_ptrval's
// (Prov_symbolic, Prov_symbolic) arm (impl_mem.ml:1905-1914) on a `Single` and a `Double` iota
// (the `_ -> false` case), hence the msum fork (:1917-1923). Expected under the switch: two
// executions, Defined 201 and Defined 200.
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  int *r1 = (int *)i;
  int *r2 = (int *)i;
  int v = *r1;
  int e = (r1 == r2);
  return v * 100 + e;
}
