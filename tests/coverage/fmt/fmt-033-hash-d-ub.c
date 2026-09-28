// fmt-033: the '#' flag on %d is UB157.
#include <stdio.h>
int main(void) { return printf("[%#d]\n", 5); }
