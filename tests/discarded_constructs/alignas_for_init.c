int main(void) { char pad = 0; for (_Alignas(64) char c = 0; ; ) return ((unsigned long)&c % 64) != 0; return pad; }
