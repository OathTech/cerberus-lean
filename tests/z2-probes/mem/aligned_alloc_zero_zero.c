/* Z2 probe: as aligned_alloc_zero.c but size 0 too: Lean's 0 tmod 0 = 0 passes
   the rem_t test and reaches alloc(0,0) where allocateRegion clamps align to 1
   (CerbMem.lean `alignN.toNat.max 1`, charter Z-13); the oracle raises
   Division_by_zero at the rem_t. libc mode. */
#include <stdlib.h>
int main(void) { void *p = aligned_alloc(0, 0); return p != 0; }
