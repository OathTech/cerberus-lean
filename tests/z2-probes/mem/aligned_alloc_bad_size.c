/* Z2 CONTROL (std.core:385-389 `undef(<<DUMMY(align_alloc)>>)` rendering):
   size not a multiple of align -> both engines report the DUMMY UB; pins the
   ub-name text and the Z-01 loc shape for a std.core-raised UB. libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(16, 8); return p != 0; }
