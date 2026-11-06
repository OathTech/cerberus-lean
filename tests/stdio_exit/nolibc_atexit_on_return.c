/* NOLIBC CONTROL: the tray 25 reproducer under --nolibc on both engines: no C library, atexit is an unknown procedure, the termination path is upstream's (symbol numbers projected). */
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); }
int main(void) { atexit(h1); atexit(h2); printf("m"); return 4; }
