int main(void) { int x = 0; return __builtin_expect(x ? 2 : 3, 3); }
