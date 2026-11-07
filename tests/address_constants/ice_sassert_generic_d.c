static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
_Static_assert((_Generic(1.0, int: 4, default: 3)) == 3, "x"); int main(void) { return 3; }
