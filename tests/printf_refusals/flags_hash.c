#include <stdio.h>

int main(void) { printf("[%#x][%#X][%#o][%#x][%#o][%#5x][%#05x][%#-6x|][%#.4x][%#08X]\n", 255u, 255u, 8u, 0u, 0u, 255u, 255u, 255u, 255u, 255u); return 0; }
