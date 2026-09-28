// fmt-013: %f given an int argument is UB153b (ill-typed argument).
#include <stdio.h>
int main(void) { return printf("[%f]\n", 1); }
