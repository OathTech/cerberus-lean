#include <stdio.h>

int main(void) { double x = 1e308; x = x * 10.0; x = x - x; printf("[%f]\n", x); return 0; }
