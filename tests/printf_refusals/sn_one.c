#include <stdio.h>

int main(void) { char b[4] = "QQQ"; int n = snprintf(b, 1, "%d", 99); printf("%d:%d:%c\n", n, b[0], b[1]); return 0; }
