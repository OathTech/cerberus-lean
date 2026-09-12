/* f/F/l/L suffixes on exactly representable values (float == double for these, so gcc agrees) (expect 63) */
int main(void) { int a = 1.5f == 1.5; int b = 0.5F == 0.5; int c = 2.0l == 2.0; int d = 3.25L == 3.25; int e = 0x1.8p1f == 3.0; int g = 1e1F == 10.0; return a * 32 + b * 16 + c * 8 + d * 4 + e * 2 + g; }
