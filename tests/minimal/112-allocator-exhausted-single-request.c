// Allocator exhausted regime by ONE request (upstream-tray draft 44; found by the pre-merge audit of the
// allocator-soundness slice, lean_frontend/docs/2026-09-17_allocator-part-one-audit-premerge.md M1, program
// `repro/w1-minus7.c`): the cursor is read as (uintptr_t)malloc(1); malloc_proxy (std.core:350) create()s an
// 8-byte argument temporary before alloc runs, so the cursor at alloc is a - 8, and a request of a - 7 bytes
// puts z = last_address - sz = -1 — the defect window -align/2 < z < 0 (IvMaxAlignment = 8).
// Pristine b9aeedcb4 (the truncating-division idiom over the Euclidean quomod, impl_mem.ml:1254) SUCCEEDS at
// address z + (z mod 8) = 6 — misaligned, ending above the cursor — and the program exits Specified(6).
// The fork (remedy 1) and Lean kill: Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}.
// Register row (shared-model-fix): scripts/upstream_oracle_differences.json "minimal/112-allocator-exhausted-single-request.c" (row 10 reads
// reviewed_difference). exec lane (test_exec.sh, scripts/exec_baseline.txt): CERB_SKIP — an oracle `Error {…}` line is an
// oracle-side non-comparison in that lane's taxonomy and Lean is not sampled there; fork = Lean (the same Error line) is
// evidenced by the three-engine report (test_upstream_oracle.py --with-lean) and the slice record.
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a; char *p; char *q;
  q = malloc(1);
  if (q == NULL) return 3;
  a = (uintptr_t)q;
  p = malloc((size_t)(a - 7));
  if (p == NULL) return 4;
  return (int)((uintptr_t)p & 0xff);
}
