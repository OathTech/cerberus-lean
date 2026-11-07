/* control: a hexadecimal escape ends at the literal boundary ("\x41" "B"). gcc 13 and every engine: Specified(131). Unmoved. */
int main(void) { const char *s = "\x41" "B"; return s[0] + s[1]; }
