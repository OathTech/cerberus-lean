// fmt-036: %d given a long (no length modifier): UB153b.
#include <stdio.h>
int main(void) { return printf("[%d]\n", 5L); }
