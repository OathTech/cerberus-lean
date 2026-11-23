// PNVI witness for refusal R-PNVI-08 (design record
// lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §G.1; correction in the arm-witness
// record lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md §4.3, review F1).
// Under --switches=PNVI_ae_udi the integer (uintptr_t)&s is one past z AND the start of s
// (both exposed; the condition below checks the adjacency), so p is a Prov_symbolic pointer
// with a `Double` iota. member_shift_ptrval (impl_mem.ml:2267-2286, via
// eff_member_shift_ptrval :2402) keeps that iota and moves the address with NO collapse, so
// &p->a and &p->b share the ambiguous iota at different addresses. diff_ptrval's
// (Prov_symbolic, Prov_symbolic) arm then reaches its `Double` result with addr1 <> addr2
// (impl_mem.ml:2100-2103): the oracle answers `Error` ("in `diff_ptrval` invariant of
// PNVI-ae-udi failed: ambiguous iotas with addr1 <> addr2"); cerberus-lean REFUSES there
// (R-PNVI-08). Default mode: Defined 1.
#include <stdint.h>
struct S { int a; int b; } s;
int z;
int main(void) {
  uintptr_t i = (uintptr_t)(&z + 1);
  uintptr_t j = (uintptr_t)&s;
  if (i != j) return 9;
  struct S *p = (struct S *)j;
  return (int)(&p->b - &p->a);
}
