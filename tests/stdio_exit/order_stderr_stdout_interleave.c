/* two streams, each ordered within itself. gcc: stdout "o1po3\n", stderr "e1f2e3\n". */
#include <stdio.h>
int main(void) { fputs("e1", stderr); fprintf(stderr, "f%d", 2); fputs("e3\n", stderr); fputs("o1", stdout); printf("p"); fputs("o3\n", stdout); return 0; }
