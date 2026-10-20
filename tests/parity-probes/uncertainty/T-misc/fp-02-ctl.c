static int g(void){ return 9; } int main(void){ int (*f)(void) = g; return f(); }
