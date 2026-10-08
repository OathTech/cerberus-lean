// PNVI arms witness a04 (follow-up F4; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: kill's Prov_symbolic arm
// (impl_mem.ml:1519-1553) through resolve_iota's `Single` case with a FAILING precondition
// (:919-924): r - a (diff_ptrval's mixed arm, `Double` case, :2048-2055) first collapses
// A(iota) = {b, a} to {a}; the free then resolves the collapsed iota, and precondition(a) fails
// with Free_out_of_bound (r is a + 16, :1526-1529). Without the collapse the `Double` iota would
// resolve to b and the free would succeed (a01) — the Single path is what the Error shows.
// Self-evidence: r == b is eq_ptrval's `_ -> false` case for (Prov_symbolic, Prov_some)
// (impl_mem.ml:1915-1916), hence the msum fork (:1917-1923); r is minted exactly as in a01.
// Expected under the switch: Error "MerrUndefinedFree Free_out_of_bound" in both executions.
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
    int d = (int)(r - a);
    int e = (r == b);
    free(r);
    return d + e;
  }
}
