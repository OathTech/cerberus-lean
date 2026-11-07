/* control: memcmp past the objects with a small n: UB_CERB002a on every engine before and after. gcc 13: exit 1. Unmoved. */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}, b[4] = {1,2,3,4}; return memcmp(a, b, 8); }
