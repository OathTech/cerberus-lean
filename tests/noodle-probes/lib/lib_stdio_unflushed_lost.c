/* Corner: data written to stdout through the FILE buffer (fputs, no
   newline) must be flushed at normal termination (ISO C11 7.22.4.4p4,
   5.1.2.2.3). gcc prints "out"; both Cerberus engines print nothing. */
#include <stdio.h>
int main(void) { fputs("out", stdout); return 0; }
