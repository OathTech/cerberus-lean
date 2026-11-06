/* tray 24 reproducer 1: the last write is not newline-terminated; flushed at exit (C17 7.22.4.4#4). gcc: "out". */
#include <stdio.h>
int main(void) { fputs("out", stdout); return 0; }
