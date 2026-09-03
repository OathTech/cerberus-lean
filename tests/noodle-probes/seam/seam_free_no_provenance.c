/* Corner (seam): free() of a pointer without provenance. impl_mem.ml:1470-
   1476 fails with MerrOther "attempted to kill with a pointer lacking a
   provenance" (a batch Error line, not UB); Lean's killM catch-all maps it to
   Free_non_matching = UB179a (CerbMem.lean:1920).
   oracle: Error {msg: "MerrOther ..."}   Lean: Undefined UB179a. */
#include <stdlib.h>
int main(void) { int *p = (int*)0x1234; free(p); return 3; }
