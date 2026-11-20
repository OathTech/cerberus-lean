typedef unsigned char [[cerb::byte]] B; int main(void) { return _Generic((B)0, unsigned char: 0, default: 1); }
