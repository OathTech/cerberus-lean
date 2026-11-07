/* control: memcmp with n = 1 on equal bytes. gcc 13 and every engine: Specified(0). Unmoved. */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}; char b[4] = {1,2,3,4}; return memcmp(a, b, 1); }
