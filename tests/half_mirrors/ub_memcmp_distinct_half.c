/* tray 13 at SIZE_MAX/2 (2^63-1, outside OCaml's 63-bit int): UB_CERB002a on both engines; the base oracle 1e5f2cbca died on Z.Overflow (pristine c3ff8c53f computed the size at 32 bits, tray 20, and answered the UB). gcc 13: exit 1 (a UB program). Moved. */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}; char b[4] = {1,2,3,4}; return memcmp(a, b, ((size_t)-1)/2); }
