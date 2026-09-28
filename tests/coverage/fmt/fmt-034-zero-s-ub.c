// fmt-034: the '0' flag on %s is UB157.
#include <stdio.h>
int main(void) { return printf("[%05s]\n", "ab"); }
