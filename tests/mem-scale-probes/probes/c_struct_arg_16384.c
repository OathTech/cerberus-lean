struct big { char b[16384]; };
struct big gb;
int foo(struct big s, int x) { return s.b[x]; }
int main(void) { return foo(gb, 0) + foo(gb, 16384 - 1); }
