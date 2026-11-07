static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
_Static_assert((_Generic(&g, int *: 3, default: 4)) == 3, "x"); int main(void) { return 3; }
