int g [[cerb::with_address("0x1000")]]; int main(void) { return (unsigned long)&g == 0x1000; }
