int main(void) { static int y [[cerb::with_address("0x1000")]]; return (unsigned long)&y == 0x1000; }
