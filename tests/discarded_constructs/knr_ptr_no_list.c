int g; int *f(a) { g = a; return &g; } int main(void) { return *f(1); }
