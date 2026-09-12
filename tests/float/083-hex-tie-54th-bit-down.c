/* 1 + 2^-53: exact halfway between 1 and 1+2^-52; ties-to-even rounds DOWN to 1 (56-bit mantissa) */
int main(void) { return 0x1.00000000000008p0 == 1.0; }
