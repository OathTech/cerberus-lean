/* a call through &printf: the pointer names the library's printf too (M1c), ordered with the buffer. gcc: "bc\n". */
#include <stdio.h>
int main(void) { int (*p)(const char *, ...) = &printf; fputs("b", stdout); p("c\n"); return 0; }
