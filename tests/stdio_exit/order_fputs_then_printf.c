/* tray 24 item 3 (M1c: with the library linked, printf is the library's own, not the std.core proxy): the proxy wrote past the FILE buffer. gcc: "bc\n". */
#include <stdio.h>
int main(void) { fputs("b", stdout); printf("c\n"); return 0; }
