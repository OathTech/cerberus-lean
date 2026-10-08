// PNVI arms witness a07 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arms: diff_ptrval's
// (Prov_symbolic, Prov_symbolic) arm (impl_mem.ml:2063-2105) with the intersection `Single`
// (:2094-2099: BOTH iotas collapse); then eq_ptrval's (Prov_symbolic, Prov_symbolic) arm
// (:1905-1914) on two `Single` iotas naming the same allocation (true, no fork). The load *r1
// first collapses r1's iota to y (load's symbolic arm, :1662). Without the subtraction r2 stays
// `Double` and the comparison forks (witness a08). Expected under the switch: Defined 201, ONE
// execution.
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  int *r1 = (int *)i;
  int *r2 = (int *)i;
  int v = *r1;
  int d = (int)(r1 - r2);
  int e = (r1 == r2);
  return v * 100 + d * 10 + e;
}
