int main(void) { struct [[m::mk("s")]] S; struct S { int m; }; struct S y; y.m = 0; return y.m; }
