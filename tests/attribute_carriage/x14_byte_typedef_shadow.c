typedef unsigned char B; int main(void) { typedef unsigned char B [[cerb::byte]]; return _Generic((B)0, unsigned char: 1, default: 0); }
