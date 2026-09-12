/* 0x1p1024 overflows to +inf, which compares greater than the largest finite value */
int main(void) { double d = 0x1p1024; return d > 0x1.fffffffffffffp1023; }
