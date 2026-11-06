/* user-requested full buffering (7.21.5.6); flushed at exit. gcc: "f1\nf2". */
#include <stdio.h>
int main(void) { static char buf[256]; setvbuf(stdout, buf, _IOFBF, sizeof buf); fputs("f1\n", stdout); fputs("f2", stdout); return 0; }
