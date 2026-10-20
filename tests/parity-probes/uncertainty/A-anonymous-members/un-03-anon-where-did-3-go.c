struct S { int a; union { int b; char c; }; int d; };
int main(void){ struct S s = {1, 2, 3}; return s.c*10 + s.d; }
