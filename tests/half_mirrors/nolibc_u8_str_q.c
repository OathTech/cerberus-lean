/* tray 10 inside a u8 string literal. gcc 13: Specified(63). Pristine c3ff8c53f: rc 125. Moved. */
int main(void) { const char *s = u8"a\?b"; return s[1]; }
