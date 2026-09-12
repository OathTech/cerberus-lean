/* 60-bit mantissa landing in the subnormal range: exact value 2^-1023 + 0.746 quanta; correct rounding gives 2^-1023 + 2^-1074 = 0x1.0000000000002p-1023 (expect 1) */
int main(void) { return 0x8000000000000BFp-1082 == 0x1.0000000000002p-1023; }
