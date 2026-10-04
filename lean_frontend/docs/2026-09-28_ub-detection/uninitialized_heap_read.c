#include <stdio.h>
#include <stdlib.h>

int main(void)
{
    volatile size_t i = 3;
    unsigned char *b = malloc(8);

    if (b == NULL)
        return 2;
    printf("value=%u\n", (unsigned)b[i]);
    free(b);
    return 0;
}
