int g(void) { return 0; } _Noreturn int f(void) { return g(); } int main(void) { f(); return 0; }
