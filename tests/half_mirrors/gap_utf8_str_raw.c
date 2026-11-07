/* gap: a raw non-ASCII byte in a string literal (tray 63) crashes both engines; gcc 13: 195. */
int main(void) { const char *s = "é"; return (unsigned char)s[0]; }
