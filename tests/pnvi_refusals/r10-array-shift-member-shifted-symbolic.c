// PNVI witness for refusal R-PNVI-10 (design record
// lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §G.1; correction in the arm-witness
// record lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md §4.3, review F1).
// Under --switches=PNVI_ae_udi the integer (uintptr_t)&s is one past z AND the start of s
// (both exposed; the condition below checks the adjacency), so p is a Prov_symbolic pointer
// with a `Double` iota. member_shift_ptrval (impl_mem.ml:2267-2286, via
// eff_member_shift_ptrval :2402) keeps that iota with NO collapse; the array shift
// &p->b - 1 then reaches eff_array_shift_ptrval's Prov_symbolic arm with a `Double` iota and
// a non-zero offset: the oracle prints its `id1= …, id2= … ==> addr= …` debug line and
// answers `Error` ("(PNVI-ae-uid) ambiguous non-zero array shift"); cerberus-lean REFUSES
// there (R-PNVI-10).
#include <stdint.h>
struct S { int a; int b; } s;
int z;
int main(void) {
  uintptr_t i = (uintptr_t)(&z + 1);
  uintptr_t j = (uintptr_t)&s;
  if (i != j) return 9;
  struct S *p = (struct S *)j;
  int *t = &p->b - 1;
  return t == &s.a;
}
