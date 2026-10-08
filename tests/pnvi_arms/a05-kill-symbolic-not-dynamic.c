// PNVI arms witness a05 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md; the arc-end auditor's probe 1).
// Arm: kill's Prov_symbolic arm (impl_mem.ml:1519-1553), its dynamic-check prefix (:1530-1537):
// r is symbolic (A(iota) = {y, x}, two adjacent exposed globals) but its address is not a
// dynamic base, so free fails with Free_non_matching before resolve_iota.
// Self-evidence: r == &y is eq_ptrval's `_ -> false` case for (Prov_symbolic, Prov_some)
// (impl_mem.ml:1915-1916), hence the msum fork (:1917-1923): the TWO executions exclude r
// carrying y's provenance (that compares equal, one execution). r is minted as in witness
// r06 and arm rows a06-a12.
// Expected under the switch: Undefined UB179a at the free, in both executions.
#include <stdlib.h>
#include <stdint.h>
int y = 2, x = 1;
int main(void) {
  uintptr_t i = (uintptr_t)(&x + 1);
  uintptr_t j = (uintptr_t)&y;
  if (i != j) return 1;
  int *r = (int *)i;
  (void)(r == &y);
  free(r);
  return 0;
}
