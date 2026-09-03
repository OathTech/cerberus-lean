/* Corner (seam): free() of a Prov_device pointer succeeds upstream
   (impl_mem.ml:1474-1475 `PV (Prov_device, PVconcrete _) -> return ()`);
   Lean reports UB179a. oracle: Specified(3)   Lean: Undefined UB179a. */
#include <stdlib.h>
int main(void) { int *p = (int*)0xABC; free(p); return 3; }
