/* Upstream-tray draft 47, `alignas_ok_control.c` — the control for alignas-001..003: `_Alignas(T)`
   with T complete. Unchanged by fork fix P2d-3: Specified(4) on every engine; gcc agrees. */
struct B { int x; };
struct A { _Alignas(struct B) char c; };
int main(void) { return sizeof(struct A); }
