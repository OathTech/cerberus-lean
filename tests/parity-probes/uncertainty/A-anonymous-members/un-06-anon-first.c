struct S { union { int b; char c; }; int d; };
int main(void){ struct S s = {2, 3}; return s.b*10 + s.d; }
