struct S { int a; union { int b; char c; }; int d; };
int main(void){ struct S s = {.d = 3, .b = 2, .a = 1}; return s.a + s.b*10 + s.d*100; }
