/* fprintf(stdout) reaches the library vfprintf, which flushes the pending buffer first. gcc: "bc1\n". */
#include <stdio.h>
int main(void) { fputs("b", stdout); fprintf(stdout, "c%d\n", 1); return 0; }
