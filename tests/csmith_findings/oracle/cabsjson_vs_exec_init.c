struct S1 { int b; int c; };
struct S2 { int a; struct S1 t; };
static volatile struct S2 g[2] = {{1,{2,3}},{4,{5,6}}};
int main(void) { return g[1].t.c; }
