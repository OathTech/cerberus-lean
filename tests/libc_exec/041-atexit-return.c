// 041: returning from main does NOT run atexit handlers in either engine (both
// print only "main"), although ISO C 5.1.2.2.3 makes the return equivalent to
// exit(7), which would print "bye". A mirrored oracle behaviour (upstream
// candidate); pinned so a change on either side shows.
#include <stdio.h>
#include <stdlib.h>
void bye(void) { printf("bye\n"); }
int main(void) { atexit(bye); printf("main\n"); return 7; }
