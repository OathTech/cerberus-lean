int main(void) { [[cerb::byte]] typedef unsigned char byte; return _Generic((byte)0, unsigned char: 1, default: 0); }
