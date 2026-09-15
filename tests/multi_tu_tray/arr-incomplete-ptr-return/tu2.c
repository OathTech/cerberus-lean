/* tests/multi_tu_tray/arr-incomplete-ptr-return — TU 2 of 2. */
struct S { int n; int (*p)[2]; };
struct S mk(void);
int main(void) { return mk().n; }
