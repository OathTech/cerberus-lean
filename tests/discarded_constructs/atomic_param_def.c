int f(_Atomic int x) { typeof(x) y = 0; return _Generic(&y, _Atomic int *: 0, int *: 1, default: 2); } int main(void) { return f(0); }
