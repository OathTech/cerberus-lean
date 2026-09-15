/* tests/multi_tu_tray/arr-1-2-arg — TU 1 of 2. OBSERVED MODELLING LIMIT (../README.md):
   `int a[1]` here vs `int a[2]` in tu2.c, the value PASSED by value; in the default
   switch set no compatibility is consulted on the argument path and every engine
   completes Specified(7). Pinned as the oracle's behaviour, NOT as an endorsement. */
struct S { int a[1]; };
int get(struct S s) { return s.a[0]; }
