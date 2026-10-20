static int n; static int g(void){ n++; return 1; } int main(void){ (void)sizeof(g()); return n; }
