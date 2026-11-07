static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
enum E { E0 = _Generic(1.0, int: 4, default: 3) }; int main(void) { return E0; }
