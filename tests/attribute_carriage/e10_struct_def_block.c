int main(void) { struct [[m::mk("s")]] S { int m; } y; y.m = 0; return y.m; }
