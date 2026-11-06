/* tray 24 item 3 (M1b, the libc-mode printf macro): the proxy wrote past the FILE buffer. gcc: "bc\n". */
#include <stdio.h>
int main(void) { fputs("b", stdout); printf("c\n"); return 0; }
