int g; int main(void) { extern int g [[cerb::with_address("0x1000")]]; return g; }
