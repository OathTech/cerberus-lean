#include <stdio.h>

int main(void) { int need = snprintf((char *)0, 0, "%s=%d", "key", 12345); char b[16]; snprintf(b, (size_t)need + 1, "%s=%d", "key", 12345); printf("%d:%s\n", need, b); return 0; }
