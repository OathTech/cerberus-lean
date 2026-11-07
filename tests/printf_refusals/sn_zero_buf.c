#include <stdio.h>

int main(void) { char b[4] = "QQQ"; int n = snprintf(b, 0, "%s", "zzz"); printf("%d:%s\n", n, b); return 0; }
