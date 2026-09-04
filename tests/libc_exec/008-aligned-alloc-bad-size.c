/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/mem/aligned_alloc_bad_size.c — undef(<<DUMMY(align_alloc)>>) rendering + the std.core UB loc substitution (control for Z2-M-01).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing libc_exec (Undefined line agrees byte-for-byte) row. */
/* Z2 CONTROL (std.core:385-389 `undef(<<DUMMY(align_alloc)>>)` rendering):
   size not a multiple of align -> both engines report the DUMMY UB; pins the
   ub-name text and the Z-01 loc shape for a std.core-raised UB. libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(16, 8); return p != 0; }
