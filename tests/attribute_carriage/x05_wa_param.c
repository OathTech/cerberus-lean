int f(int x [[cerb::with_address("0x1000")]]) { return x; } int main(void) { return f(0); }
