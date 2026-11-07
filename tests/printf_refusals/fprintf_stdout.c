#include <stdio.h>

int main(void) { fprintf(stdout, "[%*.*f]\n", 8, 2, 3.14159); return 0; }
