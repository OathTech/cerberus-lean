// tests/immaculate/nolibc GATING pin — the self-checking variant of tray44-allocator-exhausted-single-request.c
// (upstream-tray draft 44): the fork-vs-Lean twin of tests/minimal/113-allocator-exhausted-single-request-overlap.c
// (program body byte-identical). Charter: lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md
// C0(a). Part one's record: lean_frontend/docs/2026-09-16_allocator-soundness-address-bound-record.md §M1 and open
// item 3. The exec lane records the tests/minimal twin CERB_SKIP (oracle `Error {…}` = oracle-side non-comparison,
// Lean never sampled; scripts/test_exec.sh:553-558); this lane tokenises the whole Error payload on both sides and
// pins status AND the Lean token in tests/immaculate/baseline.txt:
//   tray44-allocator-exhausted-single-request-overlap MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
// Program: exit = low byte of p, + 100 if the new object ENDS ABOVE the cursor at alloc time (a - 8: malloc_proxy's
// 8-byte argument temporary is the most recent live object — the new object overlaps it), + 50 if p is 8-aligned;
// 4 if malloc failed. Pristine b9aeedcb4: Specified(106) = address 6, overlapping, NOT 8-aligned — the full defect
// signature of draft 44 at upstream's own address-space bound. The fork (remedy 1, part one C1) and Lean kill out
// of memory. Register row (shared-model-fix; LADDER Tier B row 10 reads reviewed_difference):
// scripts/upstream_oracle_differences.json "immaculate/nolibc/tray44-allocator-exhausted-single-request-overlap".
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q; size_t sz;
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  sz = (size_t)(a - 7);
  p = malloc(sz);
  if (p == NULL) return 4;
  int low = (int)((uintptr_t)p & 0xff);
  int overlap = (uintptr_t)p + sz > a - 8;
  int aligned8 = (((uintptr_t)p) % 8) == 0;
  return low + (overlap ? 100 : 0) + (aligned8 ? 50 : 0);
}
