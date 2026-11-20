int f(int a[volatile 1]); int f(int * volatile a) { return a[0]; } int main(void) { int b[1] = {0}; return f(b); }
