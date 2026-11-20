int main(void) { unsigned u = 4294967295u; return __builtin_expect(u + 1, 0) != 0; }
