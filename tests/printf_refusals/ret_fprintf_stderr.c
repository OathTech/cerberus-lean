#include <stdio.h>

int main(void) { int r = fprintf(stderr, "[%*d]\n", 4, 9); printf("%d\n", r); return 0; }
