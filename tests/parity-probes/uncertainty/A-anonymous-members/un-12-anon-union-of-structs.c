struct S { int a; union { struct { int x; int y; } p; int q; }; int d; };
int main(void){ struct S s = {1, {{2, 3}}, 4}; return s.a + s.p.x*10 + s.p.y*100 + s.d*1000; }
