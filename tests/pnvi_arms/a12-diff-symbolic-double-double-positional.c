// PNVI arms witness a12 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: diff_ptrval's
// (Prov_symbolic, Prov_symbolic) arm (impl_mem.ml:2063-2105), the `Double`/`Double` case with
// no positional match (:2081-2090): three adjacent exposed globals y > x > z give
// A(r) = {y, x} and A(s) = {x, z}; the intersection is computed POSITIONALLY (x1 = y1, x2 = y2),
// so the shared x is not found and the subtraction is error_postcond. MIRRORED, not judged
// ([USER 2026-10-03] no innovation vs upstream). Expected under the switch: Undefined UB048.
#include <stdint.h>
int y = 2, x = 1, z = 3;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  uintptr_t k = (uintptr_t)(&z + 1);
  uintptr_t l = (uintptr_t)&x;
  if (i != j || k != l) return 1;
  int *r = (int *)i;
  int *s = (int *)k;
  return (int)(r - s);
}
