static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
static int a = (int)(long)&g - (int)(long)&g + 3; int main(void) { return a; }
