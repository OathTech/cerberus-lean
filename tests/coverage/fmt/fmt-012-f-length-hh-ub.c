// fmt-012: %hhf: a length modifier other than l on %f is UB158 (invalid length
// modifier) — formatted.lem's CS_f length check.
#include <stdio.h>
int main(void) { return printf("[%hhf]\n", 1.0); }
