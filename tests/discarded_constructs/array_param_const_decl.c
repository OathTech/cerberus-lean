int f(int a[const 1]); int main(void) { return _Generic(f, int (*)(int * const): 1, int (*)(const int *): 2, default: 0); }
