/* tests/multi_tu_tray/arr-2-2-arg — TU 2 of 2. */
struct S { int a[2]; };
int get(struct S s);
int main(void) { struct S s; s.a[0] = 7; s.a[1] = 8; return get(s); }
