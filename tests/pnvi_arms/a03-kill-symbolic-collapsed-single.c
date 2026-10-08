// PNVI arms witness a03 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: kill's Prov_symbolic arm
// (impl_mem.ml:1519-1553) through resolve_iota's `Single` case (:919-925): the store through r
// (store's symbolic arm, :1771) first collapses A(iota) = {b, a} to {b}; the free then resolves
// the collapsed iota.
// Self-evidence: r == b is eq_ptrval's `_ -> false` case for (Prov_symbolic, Prov_some)
// (impl_mem.ml:1915-1916), hence the msum fork (:1917-1923): the TWO executions exclude r
// carrying b's provenance (that compares equal, one execution). Prov_some(a) would make the
// store out of bounds (UB), so the Defined results leave only Prov_symbolic.
// Expected under the switch: Defined 157 and Defined 57 (5 read back, then a[0] = 7: a alive).
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
    *r = 5;
    int v = *r;
    int e = (r == b);
    free(r);
    a[0] = 7;
    return e * 100 + v * 10 + a[0];
  }
}
