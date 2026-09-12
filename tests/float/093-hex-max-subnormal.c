/* largest subnormal, hex vs decimal, and its order against DBL_MIN (expect 3) */
int main(void) { int a = 0x0.fffffffffffffp-1022 == 2.2250738585072009e-308; int b = 0x0.fffffffffffffp-1022 < 0x1p-1022; return a * 2 + b; }
