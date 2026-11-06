/* control: handlers on exit() ran before the fix too. gcc: "m1", 4. */
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
int main(void) { atexit(h1); printf("m"); exit(4); }
