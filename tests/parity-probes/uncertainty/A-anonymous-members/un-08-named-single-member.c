struct S { int a; union { int b; } u; int d; };
int main(void){ struct S s = {1, 2, 3}; return s.a + s.u.b*10 + s.d*100; }
