#include <stdio.h>

int main(void) { double x = 1e308; x = x * 10.0; printf("[%f][%f][%10f][%-10f|][%010f]\n", x, -x, x, x, x); return 0; }
