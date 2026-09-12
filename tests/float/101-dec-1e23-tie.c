/* 1e23 is exactly halfway between two doubles; ties-to-even picks 0x1.52d02c7e14af6p76 = 99999999999999991611392 (expect 3) */
int main(void) { int a = 1e23 == 0x1.52d02c7e14af6p76; int b = 1e23 == 99999999999999991611392.0; return a * 2 + b; }
