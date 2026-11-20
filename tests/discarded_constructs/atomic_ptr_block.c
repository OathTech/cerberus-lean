int main(void) { _Atomic int *p = 0; return _Generic(p, _Atomic int *: 1, default: 0); }
