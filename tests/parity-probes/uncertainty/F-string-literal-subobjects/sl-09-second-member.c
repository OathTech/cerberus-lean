struct S { int v; char name[4]; }; int main(void){ struct S s = { 7, "ab" }; return s.name[1] + s.v; }
