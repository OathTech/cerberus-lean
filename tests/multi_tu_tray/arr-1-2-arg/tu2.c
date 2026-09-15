/* tests/multi_tu_tray/arr-1-2-arg — TU 2 of 2. `main` passes its `struct S {int a[2];}`
   value to tu1.c's `get`, which reads offset 0 under its own definition. */
struct S { int a[2]; };
int get(struct S s);
int main(void) { struct S s; s.a[0] = 7; s.a[1] = 8; return get(s); }
