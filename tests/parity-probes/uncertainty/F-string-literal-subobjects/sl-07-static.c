struct S { char name[4]; int v; }; static struct S s = { "ab", 7 }; int main(void){ return s.name[1] + s.v; }
