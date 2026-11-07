/* gap: a universal character name in a string literal, the same crash on both engines; gcc 13: 240. */
int main(void) { const char *s = "\U0001F600"; return (unsigned char)s[0]; }
