int main(void) { return sizeof(int (*)(void) [[m::mk("s")]]) == 0; }
