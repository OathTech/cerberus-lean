static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
static int a[_Generic(g, int: 3, default: 4)]; int main(void) { return (int)(sizeof a / sizeof a[0]); }
