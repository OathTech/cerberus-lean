struct S { int a; union { int b; char c; }; int d; };
int main(void){ struct S s = {.c = 'x'}; return s.c; }
