/* Z2 probe: same escaping question for the stderr field. libc mode. */
#include <stdio.h>
int main(void) { fprintf(stderr, "E\b\a\xff|"); return 0; }
