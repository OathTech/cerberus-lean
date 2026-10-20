struct S { int a; union { int b; char c; }; int d; };
static struct S s = {1, 2, 3};
int main(void){ return s.a + s.b*10 + s.d*100; }
