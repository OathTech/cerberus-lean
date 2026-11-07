/* control: memcmp with n = 2^32 (inside OCaml's int): UB_CERB002a on every engine before and after. gcc 13: exit 1. Unmoved. */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}; char b[4] = {1,2,3,4}; return memcmp(a, b, ((size_t)1 << 32)); }
