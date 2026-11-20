int main(void) { typedef unsigned char byte [[cerb::byte]]; return _Generic((byte)0, unsigned char: 1, default: 0); }
