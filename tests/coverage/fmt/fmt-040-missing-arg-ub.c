// fmt-040: fewer arguments than conversions: UB153a, after the first
// conversion has been formatted.
#include <stdio.h>
int main(void) { return printf("[%x %s]\n", 1u); }
