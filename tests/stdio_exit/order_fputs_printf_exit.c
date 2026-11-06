/* tray 24 reproducer 2: fputs, printf, exit(0). gcc: "out 5\n". */
#include <stdio.h>
#include <stdlib.h>
int main(void) { fputs("out", stdout); printf(" %d\n", 5); exit(0); }
