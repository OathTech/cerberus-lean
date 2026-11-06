/* a handler's buffered write is flushed after the handlers (7.22.4.4#4 follows #3). gcc: "head\ntail". */
#include <stdio.h>
#include <stdlib.h>
void h(void) { fputs("tail", stdout); }
int main(void) { atexit(h); fputs("head\n", stdout); return 0; }
