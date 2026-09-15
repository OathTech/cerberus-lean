/* tests/multi_tu_tray/fam-vs-array-return — TU 2 of 2. */
struct S { int n; int a[2]; };
struct S mk(void);
int main(void) { return mk().n; }
