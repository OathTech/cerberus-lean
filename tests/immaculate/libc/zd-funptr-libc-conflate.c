/* Named-deviation register N1, libc-mode identity consequence (2026-09-29, bug hunt BUG-1):
   the oracle keys its funptrmap by symbol NUMBER alone (impl_mem.ml:1206, upstream FIXME :1044),
   and in libc mode a user function can draw the number of a libc static (__stdout_write, 1868),
   so the oracle calls g through stdout->write and reports UB041; Lean numbers from one supply and
   serves the ISO-correct Specified(1). Pinned DIFF with the Lean value; upstream tray 48. */
#include <stdio.h>
/* 1212 dummy globals: in the oracle's libc mode each consumes one symbol id, which moves g's
   id onto the id that the precompiled libc gives the static __stdout_write (1868). */
#define A(x) int x##0, x##1, x##2, x##3, x##4, x##5, x##6, x##7, x##8, x##9;
#define B(x) A(x##0) A(x##1) A(x##2) A(x##3) A(x##4) A(x##5) A(x##6) A(x##7) A(x##8) A(x##9)
#define C(x) B(x##0) B(x##1) B(x##2) B(x##3) B(x##4) B(x##5) B(x##6) B(x##7) B(x##8) B(x##9)
C(d) B(e) B(f) A(h) int k0, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;
int calls;
size_t g(FILE *f, const unsigned char *s, size_t l) { calls++; return l; }
int main(void) {
  size_t (*fp)(FILE *, const unsigned char *, size_t) = g;  /* storing fp registers g's id in the funptrmap */
  fputs("via fputs\n", stdout);   /* libc loads stdout->write from memory and calls it */
  fflush(stdout);
  return calls + (fp == g);
}
