/* tests/multi_tu_tray/arr-incomplete-ptr-return — TU 1 of 2. POSITIVE: member
   `int (*p)[]` here vs `int (*p)[2]` in tu2.c — compatible (§6.7.6.1#2 pointers to
   compatible types; §6.7.6.2#6 incomplete array vs sized array); the repaired
   are_compatible array arm decides this (finding 5 / draft 39). Value RETURNED, `.n`. */
struct S { int n; int (*p)[]; };
struct S mk(void) { struct S s; s.n = 7; s.p = 0; return s; }
