static int g = 3; int f(void) { return 3; } enum { X = 3, TWO = 2 };
static int ga[3] = {1, 2, 3};
static long l = (long)&g - (long)&ga[0]; int main(void) { return l != 0 ? 3 : 4; }
