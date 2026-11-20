struct S { int m; }; struct [[m::mk("s")]] S g; int main(void) { return 0; }
