/* tests/multi_tu_tray/arr-1-2-return — TU 2 of 2. `mk()` returns tu1.c's `struct S`;
   `.a[0]` is selected under THIS definition. Both fork engines reject at PEmemberof. */
struct S { int a[2]; };
struct S mk(void);
int main(void) { return mk().a[0]; }
