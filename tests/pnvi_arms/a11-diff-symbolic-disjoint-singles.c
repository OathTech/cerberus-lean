// PNVI arms witness a11 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: diff_ptrval's
// (Prov_symbolic, Prov_symbolic) arm (impl_mem.ml:2063-2105), intersection `None` from two
// `Single` iotas naming different allocations (:2070-2074, :2092-2093: error_postcond); the
// iotas are collapsed to x and y by the mixed arm first. Expected under the switch: Undefined
// UB048 at r - s.
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  int *r = (int *)i;
  int *s = (int *)i;
  int d1 = (int)(r - &x);
  int d2 = (int)(&y - s);
  return (int)(r - s) + d1 + d2;
}
