int main(void) { int a = 2, b = 3; if (__builtin_expect(!!(a & b), 1)) return 7; return 9; }
