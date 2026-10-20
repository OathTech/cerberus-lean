struct S { int a; union { int b; char c; }; };
int main(void){ struct S s = {1, 2}; return s.a + s.b*10; }
