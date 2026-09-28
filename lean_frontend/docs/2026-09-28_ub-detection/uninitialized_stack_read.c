#include <stdio.h>

int main(void)
{
    volatile size_t i = 3;
    volatile unsigned char b[8];

    printf("value=%u\n", (unsigned)b[i]);
    return 0;
}
