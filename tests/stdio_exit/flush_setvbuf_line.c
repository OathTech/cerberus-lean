/* user-requested line buffering; the unterminated tail flushed at exit. gcc: "l1\nl2". */
#include <stdio.h>
int main(void) { static char buf[256]; setvbuf(stdout, buf, _IOLBF, sizeof buf); fputs("l1\n", stdout); fputs("l2", stdout); return 0; }
