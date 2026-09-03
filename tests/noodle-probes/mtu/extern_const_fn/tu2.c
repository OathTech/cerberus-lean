const int table[3] = {10, 20, 30};
static int dbl(int x) { return 2 * x; }
static int inc(int x) { return x + 1; }
int (*const ops[2])(int) = { inc, dbl };
const char *name(void) { return "zeta"; }
