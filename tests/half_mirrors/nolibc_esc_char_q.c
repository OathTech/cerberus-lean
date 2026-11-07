/* tray 10's reproducer: the simple escape \? (C17 6.4.4.4#1, #4: the value of '?' = 63). gcc 13: Specified(63).
   Pristine c3ff8c53f: uncaught Failure("decode_character_constant, started like an octal constant, but failed:
   ?") (rc 125). Fixed in the fork 2026-11-07 (decode.ml: the "\\?" arm). --nolibc on both engines. */
int main(void) { char c = '\?'; return c; }
