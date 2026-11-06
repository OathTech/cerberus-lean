/* NOLIBC CONTROL (the review's t24): a program-defined `exit` of another arity, `void (void)`, is NOT routed (the funinfo shape test): the mainline's answer, Specified(4) and "m\n", on both engines. */
#include <stdio.h>
void exit(void) { printf("myexit\n"); }
int main(void) { printf("m\n"); return 4; }
