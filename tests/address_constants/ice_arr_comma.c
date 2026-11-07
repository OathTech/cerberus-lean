static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
static int a[(1, 3)]; int main(void) { return (int)(sizeof a / sizeof a[0]); }
