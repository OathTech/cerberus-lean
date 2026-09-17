// The self-checking variant of 112 (upstream-tray draft 44; pre-merge audit
// lean_frontend/docs/2026-09-17_allocator-part-one-audit-premerge.md M1, program `repro/w1-overlap.c`):
// exit = low byte of p, + 100 if the new object ENDS ABOVE the cursor at alloc time (a - 8: malloc_proxy's 8-byte
// argument temporary is the most recent live object — the new object overlaps it), + 50 if p is 8-aligned;
// 4 if malloc failed. Pristine b9aeedcb4: Specified(106) = address 6, overlapping, NOT 8-aligned — the full defect
// signature of draft 44 at upstream's own address-space bound. The fork (remedy 1) and Lean kill out of memory.
// Register row (shared-model-fix): scripts/upstream_oracle_differences.json "minimal/113-allocator-exhausted-single-request-overlap.c" (row 10 reads
// reviewed_difference). exec lane (test_exec.sh, scripts/exec_baseline.txt): CERB_SKIP — an oracle `Error {…}` line is an
// oracle-side non-comparison in that lane's taxonomy and Lean is not sampled there; fork = Lean (the same Error line) is
// evidenced by the three-engine report (test_upstream_oracle.py --with-lean) and the slice record.
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
