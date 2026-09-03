/* Corner (seam): free(p + 1) on a live malloc'd block. impl_mem.ml:1515-1549
   tests is_dynamic(addr) FIRST -> Free_non_matching -> UB179a; Lean's killM
   (CerbMem.lean:1905-1914) reaches `addr != alloc.base` first ->
   Free_out_of_bound, which mem_common.lem maps to a non-UB Other error.
   oracle: Undefined UB179a   Lean: Error {msg: "MerrUndefinedFree Free_out_of_bound"}. */
#include <stdlib.h>
int main(void) { char *p = malloc(8); free(p + 1); return 3; }
