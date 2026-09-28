// fmt-037: %ld given an int: UB153b (the l predicate checks the argument type).
#include <stdio.h>
int main(void) { return printf("[%ld]\n", 5); }
