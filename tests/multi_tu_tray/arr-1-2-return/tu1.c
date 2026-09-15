/* tests/multi_tu_tray/arr-1-2-return — TU 1 of 2. NEGATIVE: `int a[1]` here vs
   `int a[2]` in tu2.c — INCOMPATIBLE definitions (C11 §6.2.7#1 / §6.7.6.2#6); the
   value is RETURNED by value and member-selected in tu2.c. ../README.md. */
struct S { int a[1]; };
struct S mk(void) { struct S s; s.a[0] = 7; return s; }
