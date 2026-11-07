/* tray 13 with adjacent members of one struct: UB_CERB002a at the memop. gcc 13: exit 1. Moved (pristine: Z.Overflow). */
#include <string.h>
int main(void) { struct { char a[4]; char b[4]; } s = {{1,2,3,4},{1,2,3,4}}; char *a = s.a; char *b = s.b; return memcmp(a, b, (size_t)-1); }
