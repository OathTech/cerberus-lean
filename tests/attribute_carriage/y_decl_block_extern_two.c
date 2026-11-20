int g; int main(void) { [[cerb::with_address("0x1000", "0x2000")]] extern int g; return g; }
