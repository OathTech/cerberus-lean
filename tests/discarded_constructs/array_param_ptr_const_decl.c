int f(int * const a); int main(void) { return _Generic(f, int (*)(int * const): 1, int (*)(const int *): 2, default: 0); }
