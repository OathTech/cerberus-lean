#include <stdio.h>

int main(void) { char b[4] = "QQQ"; int n = snprintf(b, 4, ""); printf("%d:%d\n", n, b[0]); return 0; }
