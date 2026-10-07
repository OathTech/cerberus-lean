// PNVI arc S4 witness for refusal R-PNVI-06 (design record
// lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §G.1 row R8, class (A); the S3
// review's F2). Under --switches=PNVI_ae_udi the cast (int *)i of an address that is one
// past x AND the start of y (both exposed) mints a Prov_symbolic pointer (ptrfromint's
// DoubleAlloc arm, add_iota). memcpy's model (impl_mem.ml:2679-2690) shifts its pointer
// arguments with the PURE array_shift_ptrval, whose symbolic arm is
// `failwith "Concrete.array_shift_ptrval found a Prov_symbolic"` (impl_mem.ml:2254-2255):
// the oracle crashes; cerberus-lean REFUSES there (R-PNVI-06).
#include <string.h>
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  int *p = &x + 1;
  int *q = &y;
  uintptr_t i = (uintptr_t)p;
  uintptr_t j = (uintptr_t)q;
  if (i != j) return 1;
  int *r = (int *)i;
  int d = 0;
  memcpy(&d, r, sizeof d);
  return d;
}
