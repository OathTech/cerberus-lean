/* NOLIBC CONTROL (the review's t36): a program-defined `exit` of another return type, `int (int)`, is NOT routed: the mainline's answer, Specified(4) and "m\n", on both engines (before M3b the returned Specified(4) was routed again, forever). */
#include <stdio.h>
int exit(int c) { printf("e"); return c; }
int main(void) { printf("m\n"); return 4; }
