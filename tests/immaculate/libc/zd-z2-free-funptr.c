/* zero-discrepancy Z2 pin (2026-09-03; audit row Z-07 re-witness, tests/z2-probes/mem/free_funptr.c;
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). `free((void*)main)`: a function pointer stored
   through void* re-enters as a Prov_none CONCRETE pointer, so `kill` takes the Prov_none arm
   (impl_mem.ml:1472-1473 `MerrOther "attempted to kill with a pointer lacking a provenance"`) — the
   PVfunction arm (:1470-1471) is unreachable from C. Both engines: the same Error line (Z1's Z-07 mirror).
   Pinned MATCH (Error class). libc mode. */
/* Z2 probe (kill, function-pointer arm): impl_mem.ml:1470-1471 fails with
   MerrOther "attempted to kill with a function pointer" (batch Error line);
   CerbMem.killM maps PVfunction to Free_non_matching = UB179a (charter Z-07
   names only the Prov_none/device arms from the noodle). libc mode. */
#include <stdlib.h>
int main(void) { free((void*)main); return 3; }
