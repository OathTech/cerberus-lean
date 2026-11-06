/* reaching the } of main is return 0 (5.1.2.2.3): the handler runs, the buffer is flushed. gcc: "endh\n". */
#include <stdio.h>
#include <stdlib.h>
void h(void) { puts("h"); }
int main(void) { atexit(h); fputs("end", stdout); }
