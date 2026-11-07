#include <stdio.h>

int main(void) { double x = 1e308; x = x * 10.0; printf("[%#f][%#.0f]\n", x, x); return 0; }
