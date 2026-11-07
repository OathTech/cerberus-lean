// fmt-043: %jd with an intmax_t argument: until 2026-11-07 the model's j
// predicate compared the alias-normalised argument type (long) with the bare
// Intmax_t constructor, so both engines reported UB153b (recorded as observed,
// not endorsed). Since fix/printf-refusals (contract D16, upstream-tray report
// 69) the expected side is normalised too: both engines print [-7] = gcc.
#include <stdio.h>
#include <stdint.h>
int main(void) { return printf("[%jd]\n", (intmax_t)-7); }
