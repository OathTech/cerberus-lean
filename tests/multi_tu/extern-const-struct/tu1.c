/* extern-const-struct, TU 1: a const struct and a const array defined here. */
struct cfg { int w; int h; const char *name; };
const struct cfg config = { 3, 4, "grid" };
const int primes[4] = { 2, 3, 5, 7 };
