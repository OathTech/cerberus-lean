struct S { int a; union { int b; char c; }; int d; };
int main(void){ struct S s[2] = {{1, 2, 3}, {4, 5, 6}}; return s[0].d + s[1].a*10 + s[1].d*100; }
