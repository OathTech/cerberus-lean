/* an explicit fflush, then more buffered output, flushed at exit. gcc: "abc\nd". */
#include <stdio.h>
int main(void) { fputs("a", stdout); fflush(stdout); fputs("b", stdout); fputs("c\n", stdout); fputs("d", stdout); return 0; }
