static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
enum E { E0 = _Generic(1, int: 3, default: 4) }; int main(void) { return E0; }
