/* Contract D2 (2026-09-28, test-depth map): a C program reading stdin reaches
   CerbFS.fs_read on fd 0, which refuses (the filesystem is refused in full).
   The oracle's SibylFS models an empty stdin (EOF, whatever the host feeds it:
   Specified(7)). Pinned DIFF | L=CRASH: a return to a served value flips it. */
#include <stdio.h>
int main(void) { int c = getchar(); return c == EOF ? 7 : 3; }
