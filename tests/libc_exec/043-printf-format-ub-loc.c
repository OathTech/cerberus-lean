// 043: a printf-format UB (an int conversion given a double, UB153b) in libc mode is
// raised INSIDE the shipped library's vfprintf since fix/stdio-exit-flush (2026-11-06,
// contract D15: with the library linked, printf is the library's own, not the std.core
// proxy, so the format check runs in vfprintf at the builtin call, stdio.c) -- the oracle
// reports the library's location where it used to report the program's call; the Lean
// engine reports <unknown location> there (the libc Core text transport carries no
// locations, named deviation N4). The verdict and the UB id agree: LOC_ONLY, reviewed in
// dispositions.txt (the pre-merge review's P3-1). gcc prints a garbage number.
#include <stdio.h>
int main(void) { fputs("a", stdout); printf("%d\n", 1.5); return 0; }
