int f(void) { ; ; return 1; }
int g(void) { ; ; return 2; }
int main(void) { return f() + g() != 3; }
