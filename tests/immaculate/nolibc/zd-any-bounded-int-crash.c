/* Contract D4 (2026-09-28, served-surface audit P3-1): any_bounded_int is
   reachable by declaring the builtin, and BOTH engines fail it
   (core_reduction.lem:1012-1013 "TODO Core_reduction ==> any_bounded_int()").
   Pinned MATCH | L=CRASH: a return to a served value flips the row. */
int __any_bounded_int(int, int);
int main(void) { int x = __any_bounded_int(10, 20); return x; }
