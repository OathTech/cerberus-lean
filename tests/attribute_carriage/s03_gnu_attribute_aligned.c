int g __attribute__((aligned(16))); int main(void) { return _Alignof(g) == 16; }
