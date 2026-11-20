[[cerb::byte]] extern unsigned char e; unsigned char e; int main(void) { return _Generic(e, unsigned char: 0, default: 1); }
