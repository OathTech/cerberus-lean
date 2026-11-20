typedef unsigned char byte [[cerb::byte]]; int main(void) { return _Generic((byte)0, unsigned char: 1, default: 0); }
