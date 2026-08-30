int f(int n) { return n == 0 ? 0 : 1 + f(n - 1); }
int main(void) { return f(50000) == 50000 ? 42 : 1; }
