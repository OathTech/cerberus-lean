/* Z2 probe (trace order, 2-way): one unsequenced pair. nolibc. */
int a = 0;
int f(void) { a = a * 10 + 1; return 0; }
int g(void) { a = a * 10 + 2; return 0; }
int main(void) { int r = f() + g(); return a + r; }
