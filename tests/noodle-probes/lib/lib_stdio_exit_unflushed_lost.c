/* Corner: as lib_stdio_unflushed_lost.c but terminating via exit(0), which
   ISO C11 7.22.4.4p4 says flushes all open streams. gcc "out 5"; Cerberus " 5". */
#include <stdio.h>
#include <stdlib.h>
int main(void) { fputs("out", stdout); printf(" %d\n", 5); exit(0); }
