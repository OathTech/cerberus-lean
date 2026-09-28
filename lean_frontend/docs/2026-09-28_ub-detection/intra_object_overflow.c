#include <stdio.h>
#include <string.h>

struct fields {
    unsigned char left[8];
    unsigned char right[8];
};

int main(void)
{
    volatile size_t i = 8;
    struct fields object;

    memset(&object, 0, sizeof(object));
    object.left[i] = 42;
    printf("right=%u\n", (unsigned)object.right[0]);
    return 0;
}
