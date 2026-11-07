/* tray 13 with an int -1 converted to size_t at the call (SIZE_MAX). gcc 13: exit 1. Moved (pristine: Z.Overflow). */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}, b[4] = {1,2,3,4}; int n = -1; return memcmp(a, b, n); }
