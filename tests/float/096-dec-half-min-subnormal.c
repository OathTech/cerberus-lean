/* half the smallest subnormal is 2.47032822920623272088...e-324: ...327e-324 is below it (rounds to 0), ...328e-324 above (rounds to 2^-1074) (expect 3) */
int main(void) { int a = 2.4703282292062327e-324 == 0.0; int b = 2.4703282292062328e-324 == 0x1p-1074; return a * 2 + b; }
