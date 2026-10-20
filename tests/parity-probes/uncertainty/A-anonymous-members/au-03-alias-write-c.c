struct S { int a; union { int b; unsigned char c; }; int d; }; int main(void){ struct S s; s.b = 0; s.c = 9; return s.b; }
