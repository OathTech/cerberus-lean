/* 116-bit mantissa: 1 + 2^-53 + 2^-113 is ABOVE the halfway point (sticky low bit), rounds up */
int main(void) { return 0x1.000000000000080000000000001p0 == 0x1.0000000000001p0; }
