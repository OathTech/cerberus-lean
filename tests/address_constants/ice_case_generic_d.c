static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
int main(void) { switch (3) { case _Generic(1.0, int: 4, default: 3): return 3; default: return 0; } }
