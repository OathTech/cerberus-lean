static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
int main(void) { switch (3) { case _Generic(g, int: 3, default: 4): return 3; default: return 0; } }
