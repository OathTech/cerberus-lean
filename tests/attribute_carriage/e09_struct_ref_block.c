struct S { int m; }; int main(void) { struct [[m::mk("s")]] S y; y.m = 0; return y.m; }
