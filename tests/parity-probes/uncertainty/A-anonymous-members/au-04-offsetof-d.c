struct S { int a; union { int b; char c; }; int d; }; int main(void){ struct S s; return (int)((char*)&s.d - (char*)&s); }
