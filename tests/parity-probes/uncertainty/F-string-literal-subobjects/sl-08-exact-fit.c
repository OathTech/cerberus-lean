struct S { char name[2]; int v; }; int main(void){ struct S s = { "ab", 7 }; return s.name[1] + s.v; }
