struct big { char b[4096]; };
struct big gb;
int foo(struct big s, int x) { return s.b[x]; }
int main(void) { return foo(gb, 0) + foo(gb, 4096 - 1); }
