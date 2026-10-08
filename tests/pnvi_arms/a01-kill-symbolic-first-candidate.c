// PNVI arms witness a01 (follow-up F4 of the PNVI arc-end audit; record
// lean_frontend/docs/2026-10-08_pnvi-arm-witness-rows-record.md). Arm: kill's Prov_symbolic arm
// (impl_mem.ml:1519-1553, THIS tree) on a DYNAMIC kill (free), through resolve_iota's `Double`
// case (:926-929) where the FIRST candidate's precondition holds.
// Adjacency: malloc'd b is the last allocation when the inner block creates a[16] (alignment 1),
// so a + 16 == b (the allocator grows down, impl_mem.ml:1282-1305). Both are exposed by the
// integer casts, so (char *)i mints a Prov_symbolic iota with A(iota) = {b, a} (b has the lower
// id: find_overlaping's ascending fold, :796-875). free(r): is_dynamic(b's base) holds
// (:1530-1537), precondition(b) = `OK` (live, address = base), b is killed; a stays alive.
// Self-evidence: r == b is eq_ptrval's `_ -> false` case for (Prov_symbolic, Prov_some)
// (impl_mem.ml:1915-1916), hence the msum fork (:1917-1923): the TWO executions exclude r
// carrying b's provenance (that compares equal, one execution). Prov_some(a) would fail
// the free (Free_out_of_bound) and Prov_none would fail the kill, so the Defined results leave
// only Prov_symbolic.
// Expected under the switch: Defined 17 and Defined 7 (default mode: Error Free_out_of_bound —
// r carries a's provenance there).
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
    int e = (r == b);
    free(r);
    a[0] = 7;
    return e * 10 + a[0];
  }
}
