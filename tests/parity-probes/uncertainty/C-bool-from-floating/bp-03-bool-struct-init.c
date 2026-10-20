struct S { _Bool b; int x; }; int main(void){ struct S s = { 0.5, 3 }; return s.b*10 + s.x; }
