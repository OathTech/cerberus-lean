/* fractional-only, integer-only, upper-case X/P, and (int) of a hex literal (expect 31) */
int main(void) { int a = 0x.8p1 == 1.0; int b = 0x10p-4 == 1.0; int c = 0X1P0 == 1.0; int d = 0X1.8P1 == 3.0; int e = (int)0x1.8p1; return a * 16 + b * 8 + c * 4 + d * 2 + (e == 3); }
