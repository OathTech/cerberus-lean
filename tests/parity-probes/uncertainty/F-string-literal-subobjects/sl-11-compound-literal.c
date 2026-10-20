struct S { char name[4]; int v; }; int main(void){ struct S s = (struct S){ "ab", 7 }; return s.name[1] + s.v; }
