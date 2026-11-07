/* tray 13 with both pointers to the same object: the read runs out of bounds first. gcc 13: exit 0. Moved (pristine: Z.Overflow). */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}; char *b = a; return memcmp(a, b, (size_t)-1); }
