#include <stdio.h>

int main(void) { printf("[%*s][%-*s][%.*s][%*.*s][%-*.*s]\n", 5, "ab", 5, "ab", 2, "abcd", 6, 2, "abcd", 6, 2, "abcd"); return 0; }
