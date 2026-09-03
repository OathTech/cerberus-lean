/* Z2 probe (trace order from the memory model's own msum: eq_ptrval with
   differing provenance forks "using provenance"/"ignoring provenance",
   impl_mem.ml:1877-1880 / CerbMem.eqPtrval). Two adjacent objects whose
   one-past pointer coincides with the other's base: the fork yields 0 then 1
   (or 1 then 0). nolibc. */
int main(void) { int x, y; int *p = &x + 1; int *q = &y; int r = (p == q); return 10 + r; }
