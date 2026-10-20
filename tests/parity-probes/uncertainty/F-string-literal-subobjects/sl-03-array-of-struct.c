struct S { char name[4]; int v; }; int main(void){ struct S t[2] = { {"ab", 1}, {"cd", 2} }; return t[1].name[0] + t[1].v; }
