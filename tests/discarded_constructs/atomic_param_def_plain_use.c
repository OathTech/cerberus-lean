int f(_Atomic int x) { return x + 1; } int main(void) { return f(0) - 1; }
