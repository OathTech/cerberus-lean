/* POSIX write(1, ..) is descriptor-level, past the FILE buffer, as on a real OS. gcc: "wbc\n". */
#include <stdio.h>
#include <unistd.h>
int main(void) { fputs("b", stdout); write(1, "w", 1); fputs("c\n", stdout); return 0; }
