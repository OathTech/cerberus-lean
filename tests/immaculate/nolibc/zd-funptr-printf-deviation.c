/* Named-deviation register N1: %p of a function pointer converted to void*
   prints the same supply number (read back from its bytes). Pinned DIFF. */
#include <stdio.h>
int f(void) { return 1; }
int main(void) { int (*fp)(void) = f; printf("%p\n", (void*)fp); printf("%p\n", (void*)&f); return fp(); }
