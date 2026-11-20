int main(void) { [[cerb::with_address("0x1000")]] static int y; return (unsigned long)&y == 0x1000; }
