// tests/immaculate/nolibc GATING pin of the concrete allocator's EXHAUSTED regime (upstream-tray draft 44):
// the fork-vs-Lean twin of tests/minimal/112-allocator-exhausted-single-request.c (program body byte-identical).
// Charter: lean_frontend/docs/2026-09-17_charter-address-space-bound-part-two.md C0(a). Part one's record:
// lean_frontend/docs/2026-09-16_allocator-soundness-address-bound-record.md §M1 (the pre-merge audit's witness)
// and open item 3 (why this pin exists). The exec lane (scripts/test_exec.sh:553-558, scripts/exec_baseline.txt)
// records the tests/minimal twin CERB_SKIP — an oracle `Error {…}` line is an oracle-side non-comparison in that
// lane's taxonomy and Lean is never sampled — so before this row no fork-vs-Lean lane GATED "both engines kill".
// This lane tokenises the WHOLE Error payload on both sides (test_immaculate.sh `verdict`: ERR:{msg: "…"}) and
// pins status AND the Lean token in tests/immaculate/baseline.txt:
//   tray44-allocator-exhausted-single-request MATCH | L=ERR:{msg: "MerrOther "Concrete.allocator: failed (out of memory)""}
// Program: the cursor is read as (uintptr_t)malloc(1); malloc_proxy (std.core:350) create()s an 8-byte argument
// temporary before alloc runs, so the cursor at alloc is a - 8, and a request of a - 7 bytes puts
// z = last_address - sz = -1 — the defect window -align/2 < z < 0 (IvMaxAlignment = 8). Pristine b9aeedcb4
// (memory/concrete/impl_mem.ml:1254, the truncating-division idiom over the Euclidean quomod, :9) SUCCEEDS at
// address z + (z mod 8) = 6 — misaligned, ending above the cursor — and exits Specified(6). The fork (remedy 1,
// part one C1) and Lean kill: Error {msg: "MerrOther "Concrete.allocator: failed (out of memory)""}.
// Register row (shared-model-fix; LADDER Tier B row 10 reads reviewed_difference):
// scripts/upstream_oracle_differences.json "immaculate/nolibc/tray44-allocator-exhausted-single-request".
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
