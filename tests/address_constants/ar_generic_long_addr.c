static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
static long l = _Generic(1, int: (long)&g, default: 2); int main(void) { return l != 0 ? 3 : 4; }
