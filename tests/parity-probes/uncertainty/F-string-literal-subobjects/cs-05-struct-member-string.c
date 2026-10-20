struct S { char name[4]; int v; }; int main(void){ struct S s = { "ab", 7 }; return s.name[1] + s.v + s.name[3]; }
