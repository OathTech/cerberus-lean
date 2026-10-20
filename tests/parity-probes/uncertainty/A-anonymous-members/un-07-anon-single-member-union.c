struct S { int a; union { int b; }; int d; };
int main(void){ struct S s = {1, 2, 3}; return s.a + s.b*10 + s.d*100; }
