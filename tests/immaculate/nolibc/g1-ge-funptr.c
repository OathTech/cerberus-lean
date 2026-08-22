// G1: relational compare of a function pointer. Upstream FAILs; Lean
// returns false silently (ptrAddr of a function pointer is none).
int f(void){ return 0; }
int g(void){ return 1; }
int main(void) {
  int (*a)(void) = f;
  int (*b)(void) = g;
  if (a >= b) return 1;
  return 0;
}
