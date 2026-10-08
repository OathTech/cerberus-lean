// PNVI arms witness a09 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md; cf. the arc-end auditor's
// probe 3). Arm: diff_ptrval's mixed arm (impl_mem.ml:2032-2058), BOTH patterns: (Prov_symbolic,
// Prov_some) at r - &x and (Prov_some, Prov_symbolic) at &y - s; each first takes the `Double`
// case (:2048-2055, collapse to the named allocation), then the `Single` case (:2039-2043).
// Expected under the switch: Defined 1013 (1, 0, 1, 0, + 3).
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
  int d3 = (int)(r - &x);
  int d4 = (int)(&y - s);
  return d1 * 1000 + d2 * 100 + d3 * 10 + d4 + 3;
}
