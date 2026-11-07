// fmt-015: %g likewise — Invalid_format UB until 2026-11-07, a declared
// REFUSAL on both engines since (contract D16, tray 68): CERB_SKIP in this lane.
#include <stdio.h>
int main(void) { return printf("%g", 0.5); }
