// PNVI arms witness a02 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: kill's Prov_symbolic arm
// (impl_mem.ml:1519-1553) through resolve_iota's `Double` case with BOTH preconditions failing
// (:930-935): b is freed first through its own pointer (dynamic_addrs keeps its base, :1473, so
// the dynamic check :1530-1537 still passes), so precondition(b) fails with Free_dead_allocation
// (:1521-1523) and precondition(a) with Free_out_of_bound (r is a + 16, :1526-1529);
// resolve_iota reports the SECOND failure — the order of the candidates is observable.
// Self-evidence: r == b is eq_ptrval's `_ -> false` case for (Prov_symbolic, Prov_some)
// (impl_mem.ml:1915-1916), hence the msum fork (:1917-1923): the TWO executions exclude r
// carrying b's provenance (that compares equal, one execution). r is minted exactly as in a01
// (the same prefix), where the kind is pinned.
// Expected under the switch: Error "MerrUndefinedFree Free_out_of_bound" in both executions
// (trying a before b would report b's Free_dead_allocation, i.e. UB179b).
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  char *b = malloc(16);
  if (!b) return 1;
  {
    char a[16];
    uintptr_t i = (uintptr_t)(a + 16);
    uintptr_t j = (uintptr_t)b;
    if (i != j) return 2;
    char *r = (char *)i;
    (void)(r == b);
    free(b);
    free(r);
    return 0;
  }
}
