_Atomic int *p; int main(void) { return _Generic(p, _Atomic int *: 1, default: 0); }
