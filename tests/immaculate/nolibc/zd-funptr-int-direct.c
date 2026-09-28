/* Named-deviation register N1 (2026-09-28): converting a function pointer to
   an integer serves the function symbol's fresh-supply number, which the
   engines do not share (oracle 530). Served rather than refused because libc's
   atexit round-trips function pointers through uintptr_t. Pinned DIFF with the
   Lean value; a change on either side's agreement flips the row. */
#include <stdint.h>
int f(void) { return 1; }
int main(void) { intptr_t x = (intptr_t)&f; return (int)(x & 0xfff); }
