static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
static int a = sizeof(f()) - 1; int main(void) { return a; }
