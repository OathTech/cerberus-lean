/* midpoint between DBL_MAX and 2^1024 is 1.79769313486231580793...e308: ...158e308 rounds down to DBL_MAX, ...159e308 rounds to +inf (expect 3) */
int main(void) { int a = 1.7976931348623158e308 == 0x1.fffffffffffffp1023; int b = 1.7976931348623159e308 > 0x1.fffffffffffffp1023; return a * 2 + b; }
