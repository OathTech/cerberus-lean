/* tray 13's reproducer: memcmp with (size_t)-1 reads past the 4-byte objects, so the model's verdict is the
   checked per-byte load's UB_CERB002a_out_of_bound_load at the memcmp call. Pristine c3ff8c53f: uncaught
   Z.Overflow at `Z.to_int size_n` before any byte is read (rc 125). gcc 13 (no verdict for a UB program): exit 1.
   Fixed in the fork 2026-11-07 (impl_mem.ml memcmp counts on Z); pinned to the fork's Undefined line on both engines. */
#include <string.h>
int main(void) {
  char a[4] = {1,2,3,4};
  char b[4] = {1,2,3,4};
  return memcmp(a, b, (size_t)-1);
}
