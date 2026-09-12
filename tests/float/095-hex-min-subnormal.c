/* smallest subnormal 2^-1074 in hex and decimal; 5e-324 rounds to it; 8.5e-324 (1.72 quanta) rounds to 2 quanta (expect 7) */
int main(void) { int a = 0x1p-1074 == 4.9406564584124654e-324; int b = 5e-324 == 0x1p-1074; int c = 8.5e-324 == 0x1p-1073; return a * 4 + b * 2 + c; }
