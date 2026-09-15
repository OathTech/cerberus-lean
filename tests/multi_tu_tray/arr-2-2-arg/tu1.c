/* tests/multi_tu_tray/arr-2-2-arg — TU 1 of 2. OBSERVED MODELLING LIMIT row
   (../README.md): the compatible twin of arr-1-2-arg — equal bounds, value PASSED by
   value; Specified(7) on every engine, but on this path no compatibility is consulted
   in the default switch set, so the MATCH pins the offset-0 read, not a consult. */
struct S { int a[2]; };
int get(struct S s) { return s.a[0]; }
