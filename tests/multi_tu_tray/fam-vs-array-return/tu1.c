/* tests/multi_tu_tray/fam-vs-array-return — TU 1 of 2. Flexible array member `int a[]`
   here vs `int a[2]` in tu2.c: INCOMPATIBLE on all three engines (Cerberus keeps the FAM
   outside the member list, so the definitions differ in member COUNT); gcc links and
   runs it (7). Pinned as observed; the ISO question is upstream-tray draft 41. */
struct S { int n; int a[]; };
struct S mk(void) { struct S s; s.n = 7; return s; }
