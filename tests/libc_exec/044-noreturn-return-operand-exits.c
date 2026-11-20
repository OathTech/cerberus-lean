// A `return` with an operand inside a _Noreturn function, where the operand never returns:
// C17 6.7.4#8 makes the behaviour undefined only if the function RETURNS to its caller, and
// here control never comes back (g calls exit). gcc 13: exit status 3.
// Upstream (pristine c3ff8c53f) reports UB071_noreturn without evaluating the operand
// (translation.lem, the AilSreturn arm); the fork evaluates it first (contract D19, census W17).
#include <stdlib.h>
int g(void) { exit(3); return 0; }
_Noreturn int f(void) { return g(); }
int main(void) { f(); return 0; }
