/* GAP CONTROL (contract D2): fopen is REFUSED by the Lean engine's filesystem seam; the oracle's in-memory filesystem opens the file and the unclosed stream's data is unobservable. Pinned: the oracle's line and the Lean refusal. */
#include <stdio.h>
int main(void) { FILE *f = fopen("probe.txt", "w"); if (!f) return 2; fputs("data", f); return 0; }
