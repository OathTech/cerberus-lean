int zero = 0; _Noreturn int f(void) { return 1 / zero; } int main(void) { f(); return 0; }
