/* tray 25 reproducer: handlers on return from main, reverse order. gcc: "m21", 4. */
#include <stdlib.h>
#include <stdio.h>
void h1(void) { printf("1"); }
void h2(void) { printf("2"); }
int main(void) { atexit(h1); atexit(h2); printf("m"); return 4; }
