struct S0 { int p; };
struct S1 { long a; struct S0 inner; };
struct S2 { struct S1 s; int x; };
static struct S2 g = {{2L, {7}}, 1};
int main(void) { return g.x + g.s.inner.p; }
