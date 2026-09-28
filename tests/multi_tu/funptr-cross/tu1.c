/* funptr-cross, TU 1: a dispatch table of function pointers to functions of
   THIS TU (one of them static), and a higher-order function that calls a
   callback supplied by the OTHER TU. */
static int twice(int x) { return 2 * x; }
int inc(int x) { return x + 1; }
int (*table[2])(int) = { twice, inc };
int apply(int (*f)(int), int v) { return f(v); }
