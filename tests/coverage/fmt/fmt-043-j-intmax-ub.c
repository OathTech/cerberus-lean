// fmt-043: %jd with an intmax_t argument: the model's j predicate does not
// accept intmax_t after normalisation, so both engines report UB153b (a
// shared-model behaviour, recorded as observed, not endorsed).
#include <stdio.h>
#include <stdint.h>
int main(void) { return printf("[%jd]\n", (intmax_t)-7); }
