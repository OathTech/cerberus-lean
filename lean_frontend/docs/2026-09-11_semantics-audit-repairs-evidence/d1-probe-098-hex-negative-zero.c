/* -0x0p0 is negative zero: the sign bit (LP64 little-endian, top bit of byte 7) is set (expect 1) */
int main(void) { union { double d; unsigned char b[8]; } u; u.d = -0x0p0; return u.b[7] >> 7; }
