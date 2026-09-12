/* 1 + 2^-52 + 2^-53: halfway between an odd and an even significand; ties-to-even rounds UP */
int main(void) { return 0x1.00000000000018p0 == 0x1.0000000000002p0; }
