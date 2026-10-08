// PNVI arms witness a10 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: diff_ptrval's mixed arm
// (impl_mem.ml:2032-2058): r - &x collapses r's iota to x (`Double` case), then &y - r takes
// the `Single` case with a NON-matching allocation (:2046-2047, error_postcond) — the
// collapse made observable. Expected under the switch: Undefined UB048 at &y - r.
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  int *r = (int *)i;
  int d1 = (int)(r - &x);
  int d2 = (int)(&y - r);
  return d1 + d2;
}
