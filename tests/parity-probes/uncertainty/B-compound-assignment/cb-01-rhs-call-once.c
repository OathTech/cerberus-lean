static int n; static int g(void){ return ++n; }
int main(void){ int x = 0; x += g(); return n*10 + x; }
