// PNVI arc S4 witness for refusal R-PNVI-07 (design record
// lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §G.1 row R11, the Prov_symbolic
// half, class (A)). Under --switches=PNVI_ae_udi the integer i (one past x AND the start
// of y, both exposed) cast to a function pointer is a Prov_symbolic concrete pointer
// (ptrfromint's DoubleAlloc arm). Calling through it reaches case_ptrval's wildcard
// `| _ -> failwith "case_ptrval"` (impl_mem.ml:1858): the oracle crashes; cerberus-lean
// REFUSES there (R-PNVI-07). (Storing the pointer first would stop earlier, on both
// engines, at abst's default-path "unknown function pointer" failure.)
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  return ((int (*)(void))i)();
}
