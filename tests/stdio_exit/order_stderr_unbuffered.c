/* stderr is unbuffered (7.21.3#7): fputs/fputc/fprintf appear in order; stdout separate. gcc: stdout "o\n", stderr "e1\nE2\n". */
#include <stdio.h>
int main(void) { fputs("e1\n", stderr); fputc(69, stderr); fprintf(stderr, "%d\n", 2); fputs("o\n", stdout); return 0; }
