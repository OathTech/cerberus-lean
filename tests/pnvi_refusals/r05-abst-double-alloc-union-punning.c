// PNVI arc S4 witness for refusal R-PNVI-05 (design record
// lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md §G.1 row R6, class (C)).
// Under --switches=PNVI_ae_udi an integer stored through a union member and read back as a
// pointer has bytes with no pointer provenance (`NotValidPtrProv`), so `abst`'s pointer arm
// asks find_overlaping for the address. &x + 1 == &y here (the condition below checks it),
// both allocations are exposed by the two casts, so the address has TWO candidates and
// upstream takes impl_mem.ml:1079-1082 — "(* FIXME/HACK(VICTOR): This is wrong, but when
// serialising the memory in the UI, I get this failwith. *)" `Prov_some alloc_id1`. The
// oracle runs through that arm (it answers); cerberus-lean REFUSES there (R-PNVI-05).
#include <stdint.h>
int y = 2, x = 1;
union u { uintptr_t i; int *p; };
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  union u v;
  v.i = i;
  int *r = v.p;
  return *r;
}
