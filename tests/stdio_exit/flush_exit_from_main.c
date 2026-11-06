/* exit() with buffered output: the library exit flushes (7.22.4.4#4). gcc: "x", 2. */
#include <stdio.h>
#include <stdlib.h>
int main(void) { fputs("x", stdout); exit(2); }
