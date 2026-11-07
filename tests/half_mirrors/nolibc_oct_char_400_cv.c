/* declared: '\400' is a constraint violation (C17 6.4.4.4#9, out of range) that both engines and gcc -w accept as the wrapped value 0 (gcc -pedantic-errors rejects it); pinned to that line on both engines before and after. Unmoved. */
int main(void) { int c = '\400'; return c & 0xff; }
