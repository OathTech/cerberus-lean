/* FORK-PINNED (not gcc's line): `%5%` is an invalid conversion specification (7.21.6.1#8 "The complete conversion
   specification shall be %%", so undefined behaviour); upstream pads the `%` under its own TODO at the CS_percent arm
   (formatted.lem c3ff8c53f :728) and the fork keeps that reading (a case upstream left open: kept as-is); gcc prints `%`.
   Filed with upstream-tray report 70. The `*` form of the same shape (`%*%`) is the star_percent REFUSAL. */
#include <stdio.h>

int main(void) { printf("[%5%]\n"); return 0; }
