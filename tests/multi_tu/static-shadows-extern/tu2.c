/* static-shadows-extern, TU 2: the external f and g; main sees these. */
int f(void) { return 2; }
int g = 200;
int from_tu1(void);
int main(void) { return f() + g + from_tu1() * 1000; }   /* 2 + 200 + 11000 */
