/* Contract enforcement, served-surface audit P1-1 (2026-09-28): converting a
   function pointer to an integer serves the function symbol's fresh-supply
   number, which differs between the engines (oracle 530, Lean 47 before the
   refusal). Pinned: a loud Lean refusal where the oracle answers. */
#include <stdint.h>
int f(void) { return 1; }
int main(void) { intptr_t x = (intptr_t)&f; return (int)(x & 0xfff); }
