/* tests/multi_tu_tray/arr-2-2-return — TU 2 of 2. */
struct S { int a[2]; };
struct S mk(void);
int main(void) { return mk().a[0]; }
