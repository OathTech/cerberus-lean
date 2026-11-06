/* NOLIBC CONTROL (the pre-merge review's P2-1, t23): the program DEFINES `exit` with external linkage (UB C17 7.1.3) in the library's shape `void (signed int)`, so the driver routes main's return through it; it RETURNS -- refused by the loud kill on both engines (never a second routing, never a `Unit` verdict). The mainline answered Specified(4). */
#include <stdio.h>
void exit(int c) { printf("myexit %d\n", c); }
int main(void) { printf("m\n"); return 4; }
