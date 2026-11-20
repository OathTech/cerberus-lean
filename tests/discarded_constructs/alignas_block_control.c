int main(void) { char pad = 0; _Alignas(64) char a = 0; char pad2 = 0; _Alignas(64) char b = 0; return ((unsigned long)&a % 64 != 0) + ((unsigned long)&b % 64 != 0) + pad + pad2; }
