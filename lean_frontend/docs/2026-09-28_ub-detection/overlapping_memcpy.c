#include <stdio.h>
#include <string.h>

int main(void)
{
    char b[32] = "abcdefghij";
    void *(*volatile copy)(void *, const void *, size_t) = memcpy;

    copy(b + 2, b, 10);
    printf("value=%c\n", b[0]);
    return 0;
}
