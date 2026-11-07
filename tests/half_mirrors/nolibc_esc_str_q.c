/* tray 10's string-literal form: the same decoder from translation.lem's string-literal arm. gcc 13:
   Specified(63). Pristine c3ff8c53f: the same uncaught Failure (rc 125). Fixed in the fork 2026-11-07. */
int main(void) { const char *s = "a\?b"; return s[1]; }
