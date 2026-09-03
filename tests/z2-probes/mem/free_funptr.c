/* Z2 probe (kill, function-pointer arm): impl_mem.ml:1470-1471 fails with
   MerrOther "attempted to kill with a function pointer" (batch Error line);
   CerbMem.killM maps PVfunction to Free_non_matching = UB179a (charter Z-07
   names only the Prov_none/device arms from the noodle). libc mode. */
#include <stdlib.h>
int main(void) { free((void*)main); return 3; }
