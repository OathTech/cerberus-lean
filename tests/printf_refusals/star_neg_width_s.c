#include <stdio.h>

int main(void) { printf("[%*s][%*.*s]\n", -5, "ab", -6, 2, "abcd"); return 0; }
