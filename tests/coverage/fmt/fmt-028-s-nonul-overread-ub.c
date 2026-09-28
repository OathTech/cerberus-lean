// fmt-028: %.4s on a 3-byte array with no NUL reads one byte past the object:
// out-of-bounds load.
#include <stdio.h>
int main(void) { char buf[3] = {'a','b','c'}; return printf("[%.4s]\n", buf); }
