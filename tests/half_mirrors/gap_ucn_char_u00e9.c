/* gap: a universal character name in a character constant crashes both engines in the decoder's catch-all (an uncaught Failure on the oracle, the mirrored UPSTREAM_CRASH stop on the Lean engine), before and after; gcc 13: 169 (the execution character set is UTF-8). The declared refusal is the crash-to-refusal item's (tray 63's site). */
int main(void) { int c = '\u00e9'; return c & 0xff; }
