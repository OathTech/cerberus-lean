int g; int main(void) { extern int g [[m::mk("s")]]; return g; }
