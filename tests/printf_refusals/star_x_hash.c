#include <stdio.h>

int main(void) { printf("[%#*x][%#-*x][%*u][%*o]\n", 6, 255u, 6, 255u, 4, 5u, 4, 8u); return 0; }
