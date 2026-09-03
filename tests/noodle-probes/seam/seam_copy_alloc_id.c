/* Corner (seam): the RefinedC builtin __cerbvar_copy_alloc_id(ival, ptr)
   returns a pointer with ival's ADDRESS and provenance (impl_mem.ml:2766-2770:
   intfromptr(ptr) for its range check, then ptrfromint(ival)). Lean's
   CerbMem.copyAllocId returns ptr unchanged (CerbMem.lean:2547).
   oracle: Specified(2)   Lean: Specified(1). libc mode (stdint.h). */
#include <stdint.h>
int main(void) { int x = 1, y = 2; int *p = __cerbvar_copy_alloc_id((uintptr_t)&y, &x); return *p; }
